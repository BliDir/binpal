"""End-to-end check of the Worker under `wrangler dev`, with local D1 and KV.

A mock server stands in for both the Anthropic API and the data CDN (serving
the real Yokohama bundle), so this spends nothing and needs no secrets. It
checks the cost controls the ticket asks to verify: the answer cache, the
per-install daily cap, the daily budget switch and the burst limit, plus
retries, reports, and what is stored. Answer checks (an invented item
id, refusals) are unit tests in core/.

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
BUNDLE = API.parent / "data" / "municipalities" / "14100" / "bundle.json"

# Each mocked call: 1200 fresh + 2000 cached prompt tokens, 60 out, which is
# 170 micro-dollars on Haiku 5.5. The budget allows two calls, not three.
BUDGET_USD = "0.0004"
CALLS_PER_INSTALL = "2"
USAGE = {
    "input_tokens": 1200,
    "output_tokens": 60,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 2000,
}


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


class Mock:
    """The Anthropic API and the CDN."""

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
        self.calls = []  # (headers, body) of each /v1/messages request
        self.fail_next = 0  # answer this many calls with 529 first

    def answer(self, body):
        candidates = body["messages"][0]["content"][1]["text"].splitlines()[1:]
        first = candidates[0][2:].split(":")[0]
        text = json.dumps({"item_id": first, "category": "moyasu", "confidence": 0.82})
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
            "usage": USAGE,
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
                mock.calls.append((dict(self.headers), body))
                if mock.fail_next:
                    mock.fail_next -= 1
                    error = {"type": "error", "error": {"type": "overloaded_error", "message": "x"}}
                    return self.send(529, json.dumps(error).encode())
                self.send(200, json.dumps(mock.answer(body)).encode())

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

    def identify(self, install, photo: bytes, area="14117-123002", **extra):
        body = {
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
        }
        body.update(extra)
        return self.call("POST", "/v1/identify", body)


def d1(persist, sql):
    out = subprocess.run(
        [
            "npx",
            "wrangler",
            "d1",
            "execute",
            "binpal-api",
            "--local",
            "--persist-to",
            persist,
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


def main():
    failures = []

    def check(name, condition, detail=""):
        print(("ok   " if condition else "FAIL ") + name + (f"  ({detail})" if not condition else ""))
        if not condition:
            failures.append(name)

    mock = Mock()
    mock_port, api_port = free_port(), free_port()
    mock.serve(mock_port)
    upstream = f"http://127.0.0.1:{mock_port}"

    with tempfile.TemporaryDirectory() as persist:
        subprocess.run(
            ["npx", "wrangler", "d1", "migrations", "apply", "binpal-api", "--local", "--persist-to", persist],
            cwd=API,
            check=True,
            capture_output=True,
        )
        variables = {
            "ANTHROPIC_BASE_URL": upstream,
            "CDN_BASE_URL": upstream,
            "ANTHROPIC_API_KEY": "test-key",
            "DAILY_BUDGET_USD": BUDGET_USD,
            "AI_CALLS_PER_INSTALL_PER_DAY": CALLS_PER_INSTALL,
        }
        command = [
            "npx",
            "wrangler",
            "dev",
            "--port",
            str(api_port),
            "--ip",
            "127.0.0.1",
            "--persist-to",
            persist,
            "--show-interactive-dev-session=false",
            "--test-scheduled",
        ]
        for name, value in variables.items():
            command += ["--var", f"{name}:{value}"]
        dev = subprocess.Popen(command, cwd=API, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        log = []
        threading.Thread(target=lambda: log.extend(dev.stdout), daemon=True).start()
        api = Api(api_port)
        try:
            for _ in range(600):
                try:
                    if api.call("GET", "/v1/status")[0] == 200:
                        break
                except OSError:
                    pass
                time.sleep(0.5)
            else:
                print("".join(log))
                sys.exit("wrangler dev did not start")

            one, two, three, four = (str(uuid.uuid4()) for _ in range(4))

            status, body = api.call("GET", "/v1/status")
            check("status: AI available", (status, body) == (200, {"ai": "available"}), body)

            status, body = api.identify(one, jpeg(1))
            check(
                "a photo is answered by the model",
                status == 200
                and body["answer"]["item_id"] == "yokohama-10"
                and body["answer"]["category"] == "kinzoku"
                and body["cached"] is False,
                body,
            )
            headers, sent = mock.calls[-1]
            check(
                "the key and API version are sent",
                headers.get("x-api-key") == "test-key" and headers.get("anthropic-version") == "2026-10-21",
                headers,
            )
            check(
                "the request is Haiku with a cached system prompt and JSON output",
                sent["model"] == "claude-haiku-5-5"
                and sent["system"][1]["cache_control"] == {"type": "ephemeral"}
                and "Category guide for Yokohama City" in sent["system"][1]["text"]
                and sent["output_config"]["format"]["type"] == "json_schema"
                and sent["output_config"]["effort"] == "low"
                and "temperature" not in sent,
                json.dumps(sent)[:300],
            )
            check(
                "only the photo and candidates are in the user turn",
                [b["type"] for b in sent["messages"][0]["content"]] == ["image", "text"]
                and "Umbrella" not in json.dumps(sent["system"])
                and "labels" not in json.dumps(sent),
            )

            status, body = api.identify(one, jpeg(1))
            check(
                "the same photo again comes from the cache",
                status == 200 and body["cached"] is True and len(mock.calls) == 1,
                body,
            )

            mock.fail_next = 1
            status, body = api.identify(one, jpeg(2))
            check(
                "an overloaded API is retried once",
                status == 200 and body["cached"] is False and len(mock.calls) == 3,
                body,
            )

            status, body = api.identify(one, jpeg(3))
            check(
                "a third AI call for one install hits the daily cap",
                status == 429 and body["error"] == "daily_limit" and len(mock.calls) == 3,
                body,
            )

            status, body = api.identify(two, jpeg(4))
            check("another install can still ask", status == 200, body)

            status, body = api.call("GET", "/v1/status")
            check("once the budget is spent, status says paused", body == {"ai": "paused"}, body)
            status, body = api.identify(three, jpeg(5))
            check(
                "and new photos are refused without calling the model",
                status == 503 and body["error"] == "ai_paused" and len(mock.calls) == 4,
                body,
            )
            status, body = api.identify(three, jpeg(1))
            check("cached answers are still served while paused", status == 200 and body["cached"] is True, body)

            status, body = api.identify(four, jpeg(6, 4032, 3024))
            check("a full-size photo is refused", status == 413, body)
            status, body = api.identify(four, b"\x89PNG\r\n\x1a\n" + b"0" * 100)
            check("a PNG is refused", status == 400 and body["error"] == "invalid_request", body)
            status, body = api.identify(four, jpeg(7), area="13112-001001")
            check("an area BinPal doesn't cover is refused", status == 400 and body["error"] == "unknown_area", body)

            burst = str(uuid.uuid4())
            codes = [api.identify(burst, jpeg(8), area="13112-001001")[0] for _ in range(12)]
            check(
                "more than 10 requests a minute from one install are limited",
                codes.count(429) >= 1 and codes[0] == 400,
                codes,
            )

            report = {
                "install_id": two,
                "area_id": "14117-123002",
                "item_id": "yokohama-10",
                "kind": "wrong_category",
                "note": "Metal ribs go to small metal items",
                "app_version": "1.1.0",
            }
            status, body = api.call("POST", "/v1/reports", report)
            check("a report is stored", (status, body) == (201, {"ok": True}), body)
            status, body = api.call("POST", "/v1/reports", {**report, "kind": "spam"})
            check("a report of an unknown kind is refused", status == 400, body)

            spend = d1(persist, "SELECT micro_usd, calls FROM spend")
            check("spend is recorded per call", spend == [{"micro_usd": 510, "calls": 3}], spend)
            logged = d1(persist, "SELECT source, outcome, labels FROM ai_log ORDER BY id")
            check(
                "each answered request is logged for tuning",
                [r["source"] for r in logged] == ["model", "cache", "model", "model", "cache"]
                and logged[0]["labels"] == '["Umbrella"]',
                logged,
            )
            stored = json.dumps(d1(persist, "SELECT * FROM ai_log") + d1(persist, "SELECT * FROM reports"))
            photo_hash = hashlib.sha256(jpeg(1)).hexdigest()
            check(
                "no install id or photo hash in the log or reports",
                one not in stored and two not in stored and photo_hash not in stored,
            )
            reports = d1(persist, "SELECT kind, item_id FROM reports")
            check("the report row", reports == [{"kind": "wrong_category", "item_id": "yokohama-10"}], reports)

            d1(persist, "INSERT INTO usage VALUES ('" + one + "', '2020-01-01', 'identify', 1)")
            d1(
                persist,
                "INSERT INTO ai_log (day, area_id, labels, candidate_count, source,"
                " outcome, model, input_tokens, cache_write_tokens, cache_read_tokens,"
                " output_tokens, micro_usd, duration_ms)"
                " VALUES ('2020-01-01', '14117-123002', '[]', 2, 'model', 'item',"
                " 'claude-haiku-5-5', 0, 0, 0, 0, 0, 0)",
            )
            urllib.request.urlopen(api.base + "/__scheduled?cron=0+18+*+*+*", timeout=60).read()
            old = d1(
                persist,
                "SELECT (SELECT count(*) FROM usage WHERE day < '2021-01-01') AS usage,"
                " (SELECT count(*) FROM ai_log WHERE day < '2021-01-01') AS log,"
                " (SELECT count(*) FROM usage) AS today",
            )
            check(
                "the daily cleanup drops old counters and log rows, keeping today's",
                old[0]["usage"] == 0 and old[0]["log"] == 0 and old[0]["today"] > 0,
                old,
            )
        finally:
            dev.terminate()
            dev.wait(timeout=30)

    print()
    print(f"{len(failures)} failed" if failures else "all checks passed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
