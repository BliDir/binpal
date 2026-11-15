"""End-to-end check of the Worker under `wrangler dev`, with local D1 and KV.

A mock server stands in for Workers AI, the Anthropic API and the data CDN
(serving the real Yokohama bundle), so this spends nothing and needs no
secrets or Cloudflare login. It checks the order of the two models (Workers
AI first, Anthropic as the fallback), the free Neuron ceiling, the Anthropic
budget switch, the answer cache, the per-install cap, the burst limit,
retries, reports, what is stored, the daily cleanup, and running without an
Anthropic key. Answer checks (an invented item id, refusals) are unit tests
in core/.

    cd api && python3 tests/e2e.py
"""

import base64
import hashlib
import json
import re
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

API = Path(__file__).resolve().parent.parent
# wrangler.toml without the [ai] binding, which `wrangler dev` can only run
# against Cloudflare. Written next to the real one so paths resolve the same.
TEST_CONFIG = API / ".wrangler-e2e.toml"
BUNDLE = API.parent / "data" / "municipalities" / "14100" / "bundle.json"
WORKERS_AI_MODEL = "@cf/qwen/qwen3.8-27b"

# Each Workers AI call: 1300 tokens in, 40 out, which is 65 Neurons on
# Qwen3.8 27B. A ceiling of 160 allows three calls: 0, 65, 130, then stop.
WORKERS_AI_USAGE = {"prompt_tokens": 1300, "completion_tokens": 40, "total_tokens": 1340}
DAILY_NEURONS = "160"

# Each Anthropic call: 1200 fresh + 2000 cached prompt tokens, 60 out, which
# is 170 micro-dollars on Haiku 5.5. The budget allows three calls: 0, 170,
# 340, then stop at 510.
ANTHROPIC_USAGE = {
    "input_tokens": 1200,
    "output_tokens": 60,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 2000,
}
BUDGET_USD = "0.0004"
CALLS_PER_INSTALL = "2"


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def jpeg(seed: int, width=512, height=384) -> bytes:
    """Headers of a baseline JPEG (all the Worker reads), made unique by seed."""
    app0 = b"\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"
    sof = b"\xff\xc0\x00\x0b\x08" + height.to_bytes(2, "big") + width.to_bytes(2, "big")
    sof += b"\x01\x01\x11\x00"
    com = b"\xff\xfe\x00\x06" + seed.to_bytes(4, "big")
    return b"\xff\xd8" + app0 + com + sof + b"\xff\xd9"


def first_candidate(text: str) -> str:
    return text.splitlines()[1][2:].split(":")[0]


REPO = "BliDir/binpal"
GITHUB_TOKEN = "test-github-token"


class Mock:
    """Workers AI, the Anthropic API, the CDN and GitHub's issues API."""

    def __init__(self):
        bundle_bytes = BUNDLE.read_bytes()
        bundle = json.loads(bundle_bytes)
        self.files = {
            "/bundles/14100/3.json": bundle_bytes,
            "/manifest.json": json.dumps(
                {
                    "schema_version": 1,
                    "municipalities": [
                        {
                            "id": "14100",
                            "names": bundle["municipality"]["names"],
                            "ward_ids": ["14117"],
                            "area_ids": [a["id"] for a in bundle["areas"]],
                            "bundles": [
                                {
                                    "schema_version": 1,
                                    "bundle_version": 3,
                                    "path": "/bundles/14100/3.json",
                                }
                            ],
                        }
                    ],
                }
            ).encode(),
        }
        self.workers_ai = []  # input of each Workers AI call
        self.anthropic = []  # (headers, body) of each /v1/messages request
        # Workers AI: "answer", "unknown" (can't tell), "error", or
        # "allowance" (Cloudflare's free allocation is used up).
        self.workers_ai_mode = "answer"
        self.fail_next = 0  # answer this many Anthropic calls with 529 first
        # Questions: "answer" (cite the first candidate), "wrong_category" (cite it
        # but name another category), "invented" (cite an id that isn't a
        # candidate) or "not_covered".
        self.ask_mode = "answer"
        self.issues = {}  # number -> {"title", "body", "labels", "state", "comments"}
        self.github_calls = []  # (method, path, authorization header)

    def ask_output(self, user):
        first = re.search(r"^- ([a-z0-9-]+): ", user, re.MULTILINE).group(1)
        return {
            "answer": {"covered": True, "item_ids": [first], "answer": "Yes. Put it out as Bulky waste."},
            "wrong_category": {"covered": True, "item_ids": [first], "answer": "Put it out as Burnable."},
            "invented": {"covered": True, "item_ids": ["yokohama-999999"], "answer": "Burnable."},
            "not_covered": {"covered": False, "item_ids": [], "answer": ""},
        }[self.ask_mode]

    def workers_ai_output(self, body):
        user = body["messages"][1]["content"]
        if isinstance(user, str):  # a question, not a photo
            content = json.dumps(self.ask_output(user))
        else:
            candidates = user[1]["text"]
            item = first_candidate(candidates) if self.workers_ai_mode == "answer" else None
            content = json.dumps({"item_id": item, "category": None, "confidence": 0.74})
        return {
            "id": "chatcmpl-mock",
            "object": "chat.completion",
            "created": 0,
            "model": WORKERS_AI_MODEL,
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": content, "refusal": None},
                    "finish_reason": "stop",
                    "logprobs": None,
                }
            ],
            "usage": WORKERS_AI_USAGE,
        }

    def anthropic_message(self, body):
        item = first_candidate(body["messages"][0]["content"][1]["text"])
        text = json.dumps({"item_id": item, "category": "moyasu", "confidence": 0.82})
        return {
            "id": "msg_mock",
            "type": "message",
            "role": "assistant",
            "model": body["model"],
            "content": [
                {"type": "thinking", "thinking": "", "signature": "sig"},
                {"type": "text", "text": text},
            ],
            "stop_reason": "end_turn",
            "usage": ANTHROPIC_USAGE,
        }

    def github(self, method, path, headers, body):
        """Returns (status, response) for a GitHub issues API call, or None."""
        prefix = f"/repos/{REPO}/issues"
        if not path.startswith(prefix):
            return None
        self.github_calls.append((method, path, headers.get("authorization")))
        if headers.get("authorization") != f"Bearer {GITHUB_TOKEN}" or not headers.get("user-agent"):
            return 401, {"message": "Bad credentials"}
        parts = path[len(prefix) :].strip("/").split("/")
        if method == "POST" and parts == [""]:
            number = 101 + len(self.issues)
            self.issues[number] = {**body, "state": "open", "comments": []}
            return 201, {"number": number}
        issue = self.issues.get(int(parts[0])) if parts[0].isdigit() else None
        if issue is None:
            return 404, {"message": "Not Found"}
        if method == "GET" and len(parts) == 1:
            return 200, {"number": int(parts[0]), "state": issue["state"]}
        if method == "POST" and parts[1:] == ["comments"]:
            issue["comments"].append(body["body"])
            return 201, {"id": 1}
        if method == "POST" and parts[1:] == ["labels"]:
            issue["labels"] = issue["labels"] + body["labels"]
            return 200, [{"name": n} for n in issue["labels"]]
        return 404, {"message": "Not Found"}

    def serve(self, port):
        mock = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def send(self, status, body: bytes):
                self.send_response(status)
                self.send_header("content-type", "application/json")
                self.send_header("content-length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_GET(self):
                handled = mock.github("GET", self.path, self.headers, None)
                if handled:
                    return self.send(handled[0], json.dumps(handled[1]).encode())
                found = mock.files.get(self.path)
                self.send(200 if found else 404, found or b"{}")

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers["content-length"])))
                handled = mock.github("POST", self.path, self.headers, body)
                if handled:
                    return self.send(handled[0], json.dumps(handled[1]).encode())
                if self.path == f"/ai/run/{WORKERS_AI_MODEL}":
                    mock.workers_ai.append(body)
                    if mock.workers_ai_mode == "error":
                        return self.send(500, b"InferenceUpstreamError: model failed")
                    if mock.workers_ai_mode == "allowance":
                        message = b"4006: you have used up your daily free allocation of 10,000 neurons"
                        return self.send(429, message)
                    return self.send(200, json.dumps(mock.workers_ai_output(body)).encode())
                mock.anthropic.append((dict(self.headers), body))
                if mock.fail_next:
                    mock.fail_next -= 1
                    error = {"type": "error", "error": {"type": "overloaded_error", "message": "x"}}
                    return self.send(529, json.dumps(error).encode())
                self.send(200, json.dumps(mock.anthropic_message(body)).encode())

        server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        return server


class Api:
    def __init__(self, port):
        self.base = f"http://127.0.0.1:{port}"

    def call(self, method, path, body=None):
        data = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(
            self.base + path,
            data=data,
            method=method,
            headers={"content-type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.status, json.loads(response.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read() or b"{}")

    def status(self):
        return self.call("GET", "/v1/status")[1].get("ai")

    def identify(self, install, photo: bytes, area="14117-123002"):
        return self.call(
            "POST",
            "/v1/identify",
            {
                "install_id": install,
                "area_id": area,
                "image": base64.b64encode(photo).decode(),
                "candidates": [
                    {
                        "item_id": "yokohama-10",
                        "name_ja": "かさ(骨が金属製)",
                        "name_en": "Umbrella (metal ribs)",
                        "category": "kinzoku",
                    },
                    {
                        "item_id": "yokohama-11",
                        "name_ja": "かさ(骨がプラスチック製)",
                        "name_en": "Umbrella (plastic ribs)",
                        "category": "moyasu",
                    },
                ],
                "labels": ["Umbrella"],
                "app_version": "1.1.0",
            },
        )

    def send_report(self, install, **fields):
        return self.call("POST", "/v1/reports", {"install_id": install, "app_version": "1.1.0", **fields})

    def file_reports(self):
        """Runs the five-minute cron that files reports in the review queue."""
        urllib.request.urlopen(self.base + "/__scheduled?cron=*/5+*+*+*+*", timeout=60).read()

    def ask(self, install, question="Can I throw out an old antenna?", area="14117-068001", candidates=None):
        return self.call(
            "POST",
            "/v1/ask",
            {
                "install_id": install,
                "area_id": area,
                "question": question,
                "candidates": candidates
                if candidates is not None
                else [
                    {
                        "item_id": "yokohama-11",
                        "name_ja": "アンテナ",
                        "name_en": "Antenna",
                        "category": "sodai",
                        "instructions_en": "Put out as Bulky waste.",
                    },
                    {"item_id": "yokohama-1", "name_ja": "アイスピック", "name_en": "Ice pick", "category": "kinzoku"},
                ],
                "app_version": "1.1.0",
            },
        )

    def report(self, install, kind="wrong_category"):
        return self.call(
            "POST",
            "/v1/reports",
            {
                "install_id": install,
                "area_id": "14117-123002",
                "item_id": "yokohama-10",
                "kind": kind,
                "note": "Metal ribs go to small metal items",
                "app_version": "1.1.0",
            },
        )


class Dev:
    """`wrangler dev` on a fresh local store with the given variables."""

    def __init__(self, upstream, variables):
        self.dir = tempfile.TemporaryDirectory()
        self.persist = self.dir.name
        subprocess.run(
            [
                "npx",
                "wrangler",
                "d1",
                "migrations",
                "apply",
                "binpal-api",
                "--config",
                str(TEST_CONFIG),
                "--local",
                "--persist-to",
                self.persist,
            ],
            cwd=API,
            check=True,
            capture_output=True,
        )
        port = free_port()
        variables = {
            "CDN_BASE_URL": upstream,
            "ANTHROPIC_BASE_URL": upstream,
            "WORKERS_AI_TEST_URL": upstream,
            **variables,
        }
        command = [
            "npx",
            "wrangler",
            "dev",
            "--config",
            str(TEST_CONFIG),
            "--port",
            str(port),
            "--ip",
            "127.0.0.1",
            "--persist-to",
            self.persist,
            "--show-interactive-dev-session=false",
            "--test-scheduled",
        ]
        for name, value in variables.items():
            command += ["--var", f"{name}:{value}"]
        self.process = subprocess.Popen(command, cwd=API, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        self.log = []
        threading.Thread(target=lambda: self.log.extend(self.process.stdout), daemon=True).start()
        self.api = Api(port)
        for _ in range(600):
            try:
                if self.api.call("GET", "/v1/status")[0] == 200:
                    return
            except OSError:
                pass
            time.sleep(0.5)
        self.stop()
        print("".join(self.log))
        sys.exit("wrangler dev did not start")

    def d1(self, sql):
        out = subprocess.run(
            [
                "npx",
                "wrangler",
                "d1",
                "execute",
                "binpal-api",
                "--config",
                str(TEST_CONFIG),
                "--local",
                "--persist-to",
                self.persist,
                "--json",
                "--command",
                sql,
            ],
            cwd=API,
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        return json.loads(out)[0]["results"]

    def stop(self):
        self.process.terminate()
        self.process.wait(timeout=30)
        self.dir.cleanup()


failures = []


def check(name, condition, detail=""):
    print(("ok   " if condition else "FAIL ") + name + (f"  ({detail})" if not condition else ""))
    if not condition:
        failures.append(name)


def with_fallback(mock, upstream):
    """Workers AI first, Anthropic as the fallback."""
    print("Workers AI with the Anthropic fallback")
    dev = Dev(
        upstream,
        {
            "ANTHROPIC_API_KEY": "test-key",
            "WORKERS_AI_DAILY_NEURONS": DAILY_NEURONS,
            "DAILY_BUDGET_USD": BUDGET_USD,
            "AI_CALLS_PER_INSTALL_PER_DAY": CALLS_PER_INSTALL,
        },
    )
    api = dev.api
    try:
        one, two, three = (str(uuid.uuid4()) for _ in range(3))
        check("status: AI available", api.status() == "available")

        status, body = api.identify(one, jpeg(1))
        check(
            "Workers AI answers first",
            status == 200
            and body["answer"]["item_id"] == "yokohama-10"
            and body["answer"]["category"] == "kinzoku"
            and len(mock.workers_ai) == 1
            and not mock.anthropic,
            body,
        )
        sent = mock.workers_ai[-1]
        user = sent["messages"][1]["content"]
        check(
            "Workers AI gets the photo, candidates and a short guide, with thinking off",
            user[0]["image_url"]["url"].startswith("data:image/jpeg;base64,/9j/")
            and "yokohama-10" in user[1]["text"]
            and "Category guide for Yokohama City" in sent["messages"][0]["content"]
            and "Collected twice a week" not in sent["messages"][0]["content"]
            and sent["chat_template_kwargs"] == {"enable_thinking": False}
            and sent["response_format"]["type"] == "json_schema"
            and "labels" not in json.dumps(sent),
            json.dumps(sent)[:300],
        )

        status, body = api.identify(one, jpeg(1))
        check(
            "the same photo again comes from the cache",
            status == 200 and body["cached"] is True and len(mock.workers_ai) == 1,
            body,
        )

        mock.workers_ai_mode = "unknown"
        status, body = api.identify(one, jpeg(2))
        check(
            "when Workers AI can't tell, Anthropic is asked",
            status == 200
            and body["answer"]["item_id"] == "yokohama-10"
            and len(mock.workers_ai) == 2
            and len(mock.anthropic) == 1,
            body,
        )
        headers, sent = mock.anthropic[-1]
        check(
            "Anthropic gets the key, API version, cached guide and JSON schema",
            headers.get("x-api-key") == "test-key"
            and headers.get("anthropic-version") == "2026-10-21"
            and sent["model"] == "claude-haiku-5-5"
            and sent["system"][1]["cache_control"] == {"type": "ephemeral"}
            and "Collected twice a week" in sent["system"][1]["text"]
            and sent["output_config"]["format"]["type"] == "json_schema"
            and "temperature" not in sent,
            json.dumps(sent)[:300],
        )

        status, body = api.identify(one, jpeg(3))
        check(
            "a third AI call for one install hits the daily cap, before any model",
            status == 429 and body["error"] == "daily_limit" and len(mock.workers_ai) == 2,
            body,
        )

        mock.workers_ai_mode = "error"
        status, body = api.identify(two, jpeg(4))
        check(
            "when Workers AI fails, Anthropic is asked",
            status == 200 and len(mock.workers_ai) == 3 and len(mock.anthropic) == 2,
            body,
        )

        mock.workers_ai_mode = "answer"
        status, body = api.identify(two, jpeg(5))
        check(
            "Workers AI answers again",
            status == 200 and len(mock.workers_ai) == 4 and len(mock.anthropic) == 2,
            body,
        )

        mock.fail_next = 1
        status, body = api.identify(three, jpeg(6))
        check(
            "past the Neuron ceiling, Workers AI is skipped for Anthropic",
            status == 200 and len(mock.workers_ai) == 4,
            body,
        )
        check("an overloaded Anthropic API is retried once", len(mock.anthropic) == 4)

        check("with both used up, status says paused", api.status() == "paused")
        status, body = api.identify(three, jpeg(7))
        check(
            "and new photos are refused without calling either model",
            status == 503 and body["error"] == "ai_paused" and len(mock.workers_ai) == 4 and len(mock.anthropic) == 4,
            body,
        )
        status, body = api.identify(three, jpeg(1))
        check(
            "cached answers are still served while paused",
            status == 200 and body["cached"] is True,
            body,
        )

        four = str(uuid.uuid4())
        status, body = api.identify(four, jpeg(8, 4032, 3024))
        check("a full-size photo is refused", status == 413, body)
        status, body = api.identify(four, b"\x89PNG\r\n\x1a\n" + b"0" * 100)
        check("a PNG is refused", status == 400 and body["error"] == "invalid_request", body)
        status, body = api.identify(four, jpeg(9), area="13112-001001")
        check(
            "an area BinPal doesn't cover is refused",
            status == 400 and body["error"] == "unknown_area",
            body,
        )

        burst = str(uuid.uuid4())
        codes = [api.identify(burst, jpeg(10), area="13112-001001")[0] for _ in range(12)]
        check(
            "more than 10 requests a minute from one install are limited",
            codes.count(429) >= 1 and codes[0] == 400,
            codes,
        )

        status, body = api.report(two)
        check("a report is stored", (status, body) == (201, {"ok": True}), body)
        status, body = api.report(two, kind="spam")
        check("a report of an unknown kind is refused", status == 400, body)

        neurons = dev.d1("SELECT neurons, calls FROM neurons")
        check("Neurons are counted per call", neurons == [{"neurons": 195, "calls": 3}], neurons)
        spend = dev.d1("SELECT micro_usd, calls FROM spend")
        check("Anthropic spend is recorded per call", spend == [{"micro_usd": 510, "calls": 3}], spend)
        logged = dev.d1("SELECT source, fallback, outcome, labels FROM ai_log ORDER BY id")
        check(
            "each answer is logged with its source, and why Anthropic was asked",
            [(r["source"], r["fallback"]) for r in logged]
            == [
                ("workers_ai", None),
                ("cache", None),
                ("workers_ai", None),
                ("anthropic", "unknown"),
                ("anthropic", "error"),
                ("workers_ai", None),
                ("anthropic", "allowance"),
                ("cache", None),
            ]
            and logged[0]["labels"] == '["Umbrella"]',
            logged,
        )
        stored = json.dumps(dev.d1("SELECT * FROM ai_log") + dev.d1("SELECT * FROM reports"))
        check(
            "no install id or photo hash in the log or reports",
            one not in stored and two not in stored and hashlib.sha256(jpeg(1)).hexdigest() not in stored,
        )

        dev.d1("INSERT INTO usage VALUES ('" + one + "', '2020-01-01', 'identify', 1)")
        dev.d1(
            "INSERT INTO ai_log (day, area_id, labels, candidate_count, source, model,"
            " outcome, input_tokens, cache_write_tokens, cache_read_tokens, output_tokens,"
            " neurons, micro_usd, duration_ms) VALUES ('2020-01-01', '14117-123002', '[]',"
            " 2, 'workers_ai', 'x', 'item', 0, 0, 0, 0, 0, 0, 0)"
        )
        urllib.request.urlopen(api.base + "/__scheduled?cron=0+18+*+*+*", timeout=60).read()
        old = dev.d1(
            "SELECT (SELECT count(*) FROM usage WHERE day < '2021-01-01') AS usage,"
            " (SELECT count(*) FROM ai_log WHERE day < '2021-01-01') AS log,"
            " (SELECT count(*) FROM usage) AS today"
        )
        check(
            "the daily cleanup drops old counters and log rows, keeping today's",
            old[0]["usage"] == 0 and old[0]["log"] == 0 and old[0]["today"] > 0,
            old,
        )
    finally:
        dev.stop()


def without_key(mock, upstream):
    """No Anthropic key: Workers AI only, and everything else still works."""
    print("\nWorkers AI only, no Anthropic key")
    mock.workers_ai_mode = "answer"
    anthropic_calls = len(mock.anthropic)
    dev = Dev(upstream, {"WORKERS_AI_DAILY_NEURONS": DAILY_NEURONS})
    api = dev.api
    try:
        install = str(uuid.uuid4())
        check("status works without a key", api.status() == "available")
        status, body = api.identify(install, jpeg(20))
        check("Workers AI answers", status == 200 and body["answer"] is not None, body)

        mock.workers_ai_mode = "error"
        status, body = api.identify(install, jpeg(21))
        check(
            "a Workers AI failure with no fallback is a 502",
            status == 502 and body["error"] == "upstream_failed",
            body,
        )

        mock.workers_ai_mode = "allowance"
        status, body = api.identify(str(uuid.uuid4()), jpeg(22))
        check(
            "when Cloudflare says the allowance is used, there is no answer",
            status == 200 and body["answer"] is None,
            body,
        )
        check("and AI is paused for the rest of the day", api.status() == "paused")
        check("Anthropic was never called", len(mock.anthropic) == anthropic_calls)

        status, body = api.report(install)
        check("reports work without a key", status == 201, body)

        github_calls = len(mock.github_calls)
        api.file_reports()
        unfiled = dev.d1("SELECT count(*) AS n FROM reports WHERE issue_number IS NULL")
        check(
            "without a GitHub token, reports are kept unfiled and GitHub isn't called",
            len(mock.github_calls) == github_calls and unfiled[0]["n"] > 0,
            unfiled,
        )
    finally:
        dev.stop()


def questions(mock, upstream):
    """Plain-language questions, answered only from the candidates."""
    print("\nQuestions")
    mock.workers_ai_mode = "answer"
    dev = Dev(upstream, {"QUESTIONS_PER_INSTALL_PER_DAY": "4"})
    api = dev.api
    try:
        one, two = str(uuid.uuid4()), str(uuid.uuid4())
        calls = len(mock.workers_ai)
        status, body = api.ask(one)
        check(
            "a question is answered from the cited candidate",
            status == 200
            and body["answer"]
            == {"covered": True, "item_ids": ["yokohama-11"], "text": "Yes. Put it out as Bulky waste."}
            and body["cached"] is False,
            body,
        )
        sent = mock.workers_ai[-1]["messages"][1]["content"]
        check(
            "the model gets the question and the candidates' rules",
            "Question: Can I throw out an old antenna?" in sent and "Put out as Bulky waste." in sent,
            sent,
        )
        status, body = api.ask(two, question="can I throw out an OLD  antenna?")
        check(
            "the same question again is answered from the cache",
            status == 200 and body["cached"] is True and len(mock.workers_ai) == calls + 1,
            body,
        )

        mock.ask_mode = "wrong_category"
        status, body = api.ask(one, question="Is an antenna burnable?")
        check(
            "a sentence naming another category is dropped; the citation stays",
            status == 200 and body["answer"] == {"covered": True, "item_ids": ["yokohama-11"], "text": None},
            body,
        )
        mock.ask_mode = "invented"
        status, body = api.ask(one, question="What about a tent?")
        check(
            "a rule the app didn't send can't be cited",
            status == 200 and body["answer"] == {"covered": False, "item_ids": [], "text": None},
            body,
        )
        mock.ask_mode = "not_covered"
        status, body = api.ask(one, question="When does the recycling centre open?")
        check("not covered says so", status == 200 and body["answer"]["covered"] is False, body)
        status, body = api.ask(one, question="One more question?")
        check("the install's daily questions are capped", status == 429 and body["error"] == "daily_limit", body)
        mock.ask_mode = "answer"

        status, body = api.ask(two, candidates=[])
        check("a question needs candidates", status == 400, body)
        status, body = api.ask(two, area="13112-001001")
        check("an area BinPal doesn't cover is refused", status == 400 and body["error"] == "unknown_area", body)

        logged = dev.d1("SELECT kind, source, outcome, item_id, category FROM ai_log ORDER BY id")
        check(
            "questions are logged as questions, with the cited rule",
            [(r["kind"], r["source"], r["outcome"]) for r in logged]
            == [
                ("question", "workers_ai", "answered"),
                ("question", "cache", "answered"),
                ("question", "workers_ai", "cited"),
                ("question", "workers_ai", "not_covered"),
                ("question", "workers_ai", "not_covered"),
            ]
            and logged[0]["item_id"] == "yokohama-11"
            and logged[0]["category"] == "sodai",
            logged,
        )
        stored = json.dumps(dev.d1("SELECT * FROM ai_log"), ensure_ascii=False)
        check("the question itself is never stored", "antenna" not in stored.lower() and "tent" not in stored)
    finally:
        dev.stop()


def review_queue(mock, upstream):
    """Reports filed as GitHub issues, grouped, with priority."""
    print("\nReports in the review queue")
    dev = Dev(upstream, {"GITHUB_TOKEN": GITHUB_TOKEN, "GITHUB_API_URL": upstream})
    api = dev.api
    try:
        installs = [str(uuid.uuid4()) for _ in range(8)]
        area = "14117-068001"  # Katsuradai 1-chome, Aoba Ward
        item = {"area_id": area, "item_id": "yokohama-11"}  # Antenna
        sent = [
            api.send_report(installs[0], kind="wrong_category", note="Antennas go out as metal", **item),
            api.send_report(installs[1], kind="wrong_instructions", **{**item, "area_id": "14117-071003"}),
            api.send_report(installs[2], kind="wrong_day", area_id=area, date="2026-11-11"),
            api.send_report(
                installs[3],
                kind="missing_item",
                area_id="14117-071003",
                note="ハンガー @octocat https://spam.example | <b>x</b>",
            ),
        ]
        check("reports are accepted", [s[0] for s in sent] == [201] * 4, sent)
        status, body = api.send_report(installs[4], kind="wrong_day", area_id=area)
        check("a wrong-day report needs a date", status == 400, body)
        status, body = api.send_report(installs[4], kind="wrong_category", area_id=area)
        check("a wrong-category report needs an item", status == 400, body)
        check("nothing reaches GitHub before the cron runs", not mock.github_calls)

        api.file_reports()
        by_title = {i["title"]: (n, i) for n, i in mock.issues.items()}
        item_title = "User report: アンテナ / Antenna (yokohama-11)"
        day_title = "User report: collection day 2026-11-11 in 桂台一丁目, 青葉区 (14117-068001)"
        check(
            "one issue per item, collection day and area report, all labelled",
            set(by_title)
            == {item_title, day_title, "User report: missing item in 美しが丘三丁目, 青葉区 (14117-071003)"}
            and all(i["labels"] == ["user-report"] for i in mock.issues.values()),
            list(by_title),
        )
        number, issue = by_title.get(item_title, (None, {"body": ""}))
        check(
            "reports about one item from two areas share its issue",
            issue["body"].count("| Wrong category |") == 1
            and issue["body"].count("| Wrong instructions |") == 1
            and "now in 粗大ごみ / Bulky waste" in issue["body"],
            issue["body"],
        )
        missing = next((i["body"] for i in mock.issues.values() if "missing item" in i["title"]), "")
        check(
            "comments are published without mentions, links or HTML",
            "ハンガー" in missing
            and "@octocat" not in missing
            and "https://spam" not in missing
            and "<b>" not in missing,
            missing,
        )
        public = json.dumps(mock.issues, ensure_ascii=False)
        check("no install id reaches GitHub", not any(i in public for i in installs))
        filed = dev.d1("SELECT count(*) AS n FROM reports WHERE issue_number IS NULL")
        check("every report is marked as filed", filed[0]["n"] == 0, filed)

        calls = len(mock.github_calls)
        api.file_reports()
        check("a run with nothing new doesn't call GitHub", len(mock.github_calls) == calls)

        api.send_report(installs[5], kind="wrong_category", **item)
        api.file_reports()
        issue = mock.issues.get(number, {"comments": [], "labels": []})
        check(
            "a third report comments on the open issue and makes it a priority",
            len(mock.issues) == 3
            and issue["comments"][-1:] != []
            and issue["comments"][-1].startswith("1 more report, 3 in total")
            and "priority" in issue["labels"],
            issue,
        )

        issue["state"] = "closed"
        api.send_report(installs[6], kind="wrong_category", **item)
        api.file_reports()
        check(
            "after a reviewer closes it, the next report opens a new issue",
            len(mock.issues) == 4 and mock.issues.get(104, {}).get("title") == item_title,
            [i["title"] for i in mock.issues.values()],
        )

        api.send_report(installs[7], kind="other", area_id=area, note="Third report from this area")
        api.file_reports()
        newest = mock.issues.get(max(mock.issues), {})
        check(
            "three reports from one area in 30 days make its new issues a priority",
            newest.get("title", "").startswith("User report: other in 桂台一丁目")
            and "priority" in newest.get("labels", []),
            newest,
        )
    finally:
        dev.stop()


def write_test_config():
    config = (API / "wrangler.toml").read_text()
    without_ai = config.replace('[ai]\nbinding = "AI"\n', "")
    assert without_ai != config, "wrangler.toml has no [ai] binding to remove"
    TEST_CONFIG.write_text(without_ai)


def main():
    write_test_config()
    try:
        run()
    finally:
        TEST_CONFIG.unlink(missing_ok=True)


def run():
    mock = Mock()
    port = free_port()
    mock.serve(port)
    upstream = f"http://127.0.0.1:{port}"
    with_fallback(mock, upstream)
    without_key(mock, upstream)
    questions(mock, upstream)
    review_queue(mock, upstream)
    print()
    print(f"{len(failures)} failed" if failures else "all checks passed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
