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


class Mock:
    """Workers AI, the Anthropic API and the CDN."""

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

    def workers_ai_output(self, body):
        candidates = body["messages"][1]["content"][1]["text"]
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
                found = mock.files.get(self.path)
                self.send(200 if found else 404, found or b"{}")

            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers["content-length"])))
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
    print()
    print(f"{len(failures)} failed" if failures else "all checks passed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
