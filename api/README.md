# BinPal API

The thin API for v2 features: the AI fallback for photo check (DAI-579) and "this looks wrong" reports (DAI-581). It is written in Rust and runs on Cloudflare Workers, beside the data CDN. It holds the Anthropic API key, so the key never ships in the app.

| Folder | Contents |
| -- | -- |
| `core/` | Request checks, the prompt, answer checks, cost and limits. Plain Rust, tested natively |
| `worker/` | Routes, D1 and KV storage, the CDN and Anthropic calls (workers-rs) |
| `migrations/` | D1 schema |
| `tests/e2e.py` | The Worker under `wrangler dev`, against a mock Anthropic API and CDN |

## Endpoints

No accounts. Requests carry a random install id that the app makes (a UUID, used only to count per-install limits), an area id and content. They never carry a location.

### `POST /v1/identify`

Called only when the phone couldn't identify a photo itself.

```json
{
  "install_id": "7d0b6f0e-3b9a-4c2e-9f57-2b6f2a1c9e10",
  "area_id": "14117-123002",
  "image": "<base64 JPEG, about 512 px on the long side>",
  "candidates": [
    {"item_id": "yokohama-10", "name_ja": "かさ(骨が金属製)", "name_en": "Umbrella (metal ribs)", "category": "kinzoku"}
  ],
  "labels": ["Umbrella"],
  "app_version": "1.1.0"
}
```

`candidates` are the top results of the app's local search (1–30). `labels` are the on-device image labels and recycling marks; they are logged for tuning and not sent to the model.

```json
{"answer": {"item_id": "yokohama-10", "category": "kinzoku", "confidence": 0.82}, "cached": false}
```

`answer` is `null` when the model couldn't tell. `item_id` is `null` when no candidate matched but the category is clear. Disposal instructions always come from the app's bundle, never from the model.

### `POST /v1/reports`

```json
{"install_id": "…", "area_id": "14117-123002", "item_id": "yokohama-10", "kind": "wrong_category", "note": "…", "app_version": "1.1.0"}
```

`kind` is `wrong_category`, `wrong_instructions`, `wrong_day`, `missing_item` or `other`. Returns `201 {"ok": true}`.

### `GET /v1/status`

`{"ai": "available"}`, or `{"ai": "paused"}` once today's budget is spent. While paused, the app shows on-device candidates and search only.

### Errors

`{"error": "<code>", "message": "…"}` with:

| Status | Code | Meaning |
| -- | -- | -- |
| 400 | `invalid_request` | Malformed request, a non-JPEG image, or bad ids |
| 400 | `unknown_area` | BinPal has no bundle for the area |
| 413 | `payload_too_large` | Body over 200 KB, image over 150 KB, or longer than 1024 px |
| 429 | `rate_limited` | More than 10 requests a minute from one install |
| 429 | `daily_limit` | The install's AI calls (20) or reports (10) for today are used |
| 503 | `ai_paused` | Today's AI budget is spent |
| 502 | `upstream_failed` | The model didn't answer (after one retry on 429, 5xx or 529) |

## Keeping AI calls few and small

| Ticket item | How |
| -- | -- |
| Cheapest capable model | `claude-haiku-5-5` (`ANTHROPIC_MODEL`), adaptive thinking at `effort: "low"` |
| Small requests | Only a resized JPEG (≤ 150 KB, ≤ 1024 px, checked from the JPEG header) and the app's candidates; everything larger is refused before any work |
| Short structured output | JSON schema output with `item_id`, `category` and `confidence`, `max_tokens` 1024 (room for low-effort thinking plus a ~30-token answer). The item must be one of the candidates and the category one of the bundle's, or it is dropped |
| Prompt caching | The instructions and the municipality's category guide (about 2,000 tokens for Yokohama, built only from the bundle) come first and end with a cache breakpoint. Only the photo and candidates vary |
| Response cache | Answers are kept in KV for 30 days, keyed by the photo's SHA-256, the area, the bundle version and the candidate ids. A repeated photo costs nothing, even while AI is paused |
| Limits | 10 requests a minute per install (Cloudflare rate limiting), 20 AI calls per install per day, and a global daily budget (`DAILY_BUDGET_USD`, $5 to start). Days are Japan days |
| Budget switch | Each call's cost is computed from its token usage and added to the day's spend. Once the budget is reached, `/v1/status` says `paused` and new photos get `ai_paused`, until midnight in Japan |
| Logging for tuning | `ai_log` records the on-device labels, the number of candidates, the answer, tokens and cost of each request. No photo, photo hash or install id |

An unknown model name in `ANTHROPIC_MODEL` is costed at the highest list price, so switching models can't overspend the budget unnoticed.

### Cost per call (estimate)

A 512×384 photo is about 260 tokens, 20 candidates about 600, and the cached system prompt about 2,000–2,500. At Haiku 5.5 prices ($0.10 / $0.50 per million tokens, cache reads 0.1×, cache writes 1.25×), that is about **$0.0002 per call with a warm cache** and about $0.0005 when the cache is cold. $5 a day covers roughly 10,000–25,000 calls. These are estimates; the real figures come from `ai_log` once deployed (below).

## Privacy

* Photos are forwarded to the Anthropic API for identification and never stored by the API. The response cache stores only the photo's hash, with the answer.
* Install ids are kept only in the per-day counters, which a daily cron (03:00 in Japan) deletes after two days.
* `ai_log` rows are deleted after 90 days. Reports keep no install id.
* Logs on failure contain the HTTP status and the error type, never the request.

## Local development

Needs Rust via rustup (with the `wasm32-unknown-unknown` target), `worker-build` and Node.

```sh
rustup target add wasm32-unknown-unknown
cargo install worker-build@0.9.0 --locked
cd api && npm ci

cargo test -p binpal-api-core        # unit tests
python3 tests/e2e.py                 # the Worker under wrangler dev, with mocks
```

If Homebrew's Rust is also installed, put `~/.cargo/bin` first in `PATH`, or the build uses a `rustc` without the Wasm target.

`tests/e2e.py` starts a mock Anthropic API and CDN (serving the real Yokohama bundle), runs `wrangler dev` against them with local D1 and KV and a tiny budget, and checks the answer cache, the per-install cap, the budget switch, the burst limit, the retry, reports, what is stored, and the daily cleanup. It spends nothing and needs no secrets.

To try the real model locally, put `ANTHROPIC_API_KEY=…` in `api/.dev.vars` (ignored by git) and run `npm run dev`.

## Deploying (owner steps)

These need the Cloudflare account that hosts the CDN.

```sh
cd api
npx wrangler login
npx wrangler d1 create binpal-api              # put the database_id in wrangler.toml
npx wrangler kv namespace create CACHE         # put the id in wrangler.toml
npx wrangler d1 migrations apply binpal-api --remote
npx wrangler secret put ANTHROPIC_API_KEY      # paste the key; it goes to Cloudflare's secret store
npm run deploy
```

Then:

* **Custom domain:** Workers → binpal-api → Settings → Domains & Routes → add `api.<your-domain>`, so the app doesn't depend on the `workers.dev` name.
* **Anthropic spend limit:** set a monthly limit for the key's workspace in the Claude Console as a backstop to the daily budget.
* **Check:** `curl https://api.<your-domain>/v1/status` returns `{"ai":"available"}`.

The install id is made by the app, so someone could rotate it to get past the per-install limits; the global daily budget caps what that can cost. An IP-based WAF rate limiting rule on the API's hostname adds a second layer if needed.

## Measuring

Average cost per AI call, and AI calls per install that used photo AI, per day. The API never sees installs that didn't need AI, so calls per *active* user needs the app's own count of active installs alongside.

```sh
npx wrangler d1 execute binpal-api --remote --command "
  SELECT day, calls, micro_usd / 1e6 AS usd, micro_usd / calls AS micro_usd_per_call
  FROM spend ORDER BY day DESC LIMIT 14"

# Over-limit attempts also count up, so cap each install at the daily limit (20).
npx wrangler d1 execute binpal-api --remote --command "
  SELECT day, count(*) AS installs, sum(min(count, 20)) * 1.0 / count(*) AS calls_per_install
  FROM usage WHERE kind = 'identify' GROUP BY day ORDER BY day DESC"
```

`usage` only keeps two days, so record calls per install from the second query as it goes. Response times and cache hits are in `ai_log` (`duration_ms`, `source`).
