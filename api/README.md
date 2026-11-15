# BinPal API

The thin API for v2 features: the AI fallback for photo check (DAI-579) and "this looks wrong" reports (DAI-581). It is written in Rust and runs on Cloudflare Workers, beside the data CDN.

Photos the phone couldn't identify go to **Workers AI first**, free up to Cloudflare's daily allowance, through a binding with no API key. **Anthropic is the fallback** when Workers AI fails, can't tell, or is used up for the day. The fallback is off unless an Anthropic key is set; the key stays in Cloudflare's secret store and never ships in the app.

| Folder | Contents |
| -- | -- |
| `core/` | Request checks, the prompt, answer checks, cost and limits. Plain Rust, tested natively |
| `worker/` | Routes, D1 and KV storage, the CDN, Workers AI and Anthropic calls (workers-rs) |
| `migrations/` | D1 schema |
| `tests/e2e.py` | The Worker under `wrangler dev`, against a mock Workers AI, Anthropic API, CDN and GitHub |

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

`answer` is `null` when the models couldn't tell. `item_id` is `null` when no candidate matched but the category is clear. Disposal instructions always come from the app's bundle, never from the model.

### `POST /v1/reports`

```json
{"install_id": "…", "area_id": "14117-123002", "item_id": "yokohama-10", "kind": "wrong_category", "note": "…", "app_version": "1.1.0"}
```

`kind` is `wrong_category`, `wrong_instructions`, `wrong_day`, `missing_item` or `other`. The first two need an `item_id`, and `wrong_day` needs a `date` (`YYYY-MM-DD` in Japan). Returns `201 {"ok": true}` once the report is stored; it reaches the review queue within five minutes (below).

## Review queue

Reports are filed as issues in `BliDir/binpal` (`GITHUB_REPO`), the same GitHub Issues the rule monitor opens, by a cron every five minutes (`src/queue.rs`; the wording is in `core/src/review.rs`). Storing and filing are separate, so the app never waits for GitHub, and a run that fails (GitHub or the CDN down) is retried on the next one.

* **One issue per thing**: an item in its municipality (whatever area or kind the reports come from), a collection date in an area, or a kind of report in an area. The first report opens the issue, later ones add a comment while it is open, and after a reviewer closes it the next report opens a new one.
* **Labels**: `user-report` on every issue. `priority` once the issue has 3 reports, or its area has had 3 reports in 30 days.
* **Contents**: the item's names and current category with its official source, or the area and date, the municipality and bundle version, and a table of the reports (day received, kind, area, date, app version, comment). Never an install id.
* **Comments are public**: the repository is public, and the app says so next to the comment field. Comments are shown as sent on one line, with mentions, links, images and HTML turned off.

Filing needs the `GITHUB_TOKEN` secret (below). Without it, reports are stored and wait.

### `GET /v1/status`

`{"ai": "available"}`, or `{"ai": "paused"}` when neither model can take a call: today's free Workers AI Neurons are used (until 00:00 UTC, 09:00 in Japan) and the Anthropic budget is spent or there is no key. While paused, the app shows on-device candidates and search only.

### Errors

`{"error": "<code>", "message": "…"}` with:

| Status | Code | Meaning |
| -- | -- | -- |
| 400 | `invalid_request` | Malformed request, a non-JPEG image, or bad ids |
| 400 | `unknown_area` | BinPal has no bundle for the area |
| 413 | `payload_too_large` | Body over 200 KB, image over 150 KB, or longer than 1024 px |
| 429 | `rate_limited` | More than 10 requests a minute from one install |
| 429 | `daily_limit` | The install's AI calls (20) or reports (10) for today are used |
| 503 | `ai_paused` | Neither model can take a call today |
| 502 | `upstream_failed` | The models didn't answer (Anthropic is retried once on 429, 5xx or 529) |

## Which model answers

For each photo not in the answer cache:

1. **Workers AI** (`WORKERS_AI_MODEL`, `@cf/qwen/qwen3.8-27b`) while today's Neurons are under `WORKERS_AI_DAILY_NEURONS` (9,000, under Cloudflare's free 10,000, so a Workers Paid account is never billed for overage). Neurons are counted from each response's token usage at the model's published rates; if Cloudflare still says the allowance is used, Workers AI is off until 00:00 UTC.
2. **Anthropic** (`ANTHROPIC_MODEL`, `claude-haiku-5-5`) when Workers AI failed, had no usable answer, or is used up, if `ANTHROPIC_API_KEY` is set and today's spend is under `DAILY_BUDGET_USD` ($1, per Japan day).

Both models get the same instructions, category guide and candidates, and both answers pass the same checks: the item must be one of the candidates and the category one of the bundle's, or it is dropped.

## Keeping AI calls few and small

| Ticket item | How |
| -- | -- |
| Cheapest capable model | Workers AI first, free within the daily allowance, with thinking off. Anthropic's `claude-haiku-5-5` as the fallback, with adaptive thinking at `effort: "low"` |
| Small requests | Only a resized JPEG (≤ 150 KB, ≤ 1024 px, checked from the JPEG header) and the app's candidates; everything larger is refused before any work. Workers AI gets the category guide without descriptions (about 250 tokens instead of 2,000), since every input token counts against the allowance |
| Short structured output | A JSON schema with `item_id`, `category` and `confidence`; 256 output tokens on Workers AI, 1024 on Anthropic (room for low-effort thinking plus a ~30-token answer) |
| Prompt caching | For Anthropic, the instructions and the municipality's full category guide (about 2,000 tokens for Yokohama, built only from the bundle) come first and end with a cache breakpoint. Only the photo and candidates vary |
| Response cache | Answers from either model are kept in KV for 30 days, keyed by the photo's SHA-256, the area, the bundle version and the candidate ids. A repeated photo costs nothing, even while AI is paused |
| Limits | 10 requests a minute per install (Cloudflare rate limiting), 20 AI calls per install per Japan day, the Workers AI Neuron ceiling, and the Anthropic daily budget |
| Budget switch | Each Anthropic call's cost is computed from its token usage and added to the day's spend. Once both models are used up, `/v1/status` says `paused` and new photos get `ai_paused` |
| Logging for tuning | `ai_log` has one row per cached answer or model call: the on-device labels, the number of candidates, which model answered, why Anthropic was asked (`fallback`), the answer, tokens, Neurons and cost. No photo, photo hash or install id |

Unknown model names are counted at the highest listed rates (Neurons for Workers AI, dollars for Anthropic), so switching models can't overrun the allowance or the budget unnoticed.

### Cost per call (estimate)

On Workers AI, a photo with its candidates and the short guide is about 1,300 input tokens and 40 output, about **65 Neurons**, so the free allowance covers roughly **140 photos a day at $0**. The image's token count isn't documented, so this is an estimate; `ai_log.neurons` has the real figure once deployed.

On Anthropic, a call is about **$0.0002 with a warm prompt cache** and $0.0005 cold, so the $1 budget covers roughly 2,000–5,000 fallback calls a day. Without a key the fallback costs nothing and doesn't run.

## Privacy

* Photos are sent to Workers AI, and to the Anthropic API only as the fallback, for identification. The API never stores them; the response cache stores only the photo's hash, with the answer.
* Cloudflare says Workers AI keeps inputs and outputs only as long as needed to answer, and doesn't train on them (Workers AI data usage page; the Qwen model page lists zero data retention). Anthropic's commercial terms don't use API inputs for training by default.
* Install ids are kept only in the per-day counters, which a daily cron (03:00 in Japan) deletes after two days.
* `ai_log` rows are deleted after 90 days. Reports keep no install id; their comments are published in the public review queue.
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

`tests/e2e.py` starts a mock Workers AI, Anthropic API, CDN and GitHub issues API (serving the real Yokohama bundle) and runs `wrangler dev` against them with local D1 and KV, a small Neuron ceiling and a tiny budget. It checks that Workers AI answers first; that Anthropic is asked when Workers AI can't tell, fails, or is used up; the answer cache, the per-install cap, the budget switch, the burst limit, the retry, reports, what is stored, and the daily cleanup. A second run without an Anthropic key or GitHub token checks that Workers AI, status and reports still work, and that reports wait unfiled. A third files reports in a mock GitHub: grouping, comments, priority, a new issue after one is closed, and what is published. It spends nothing and needs no secrets or Cloudflare login.

The `AI` binding only runs against Cloudflare, so the test uses a copy of `wrangler.toml` without it (`.wrangler-e2e.toml`, deleted afterwards) and points `WORKERS_AI_TEST_URL` at the mock. That variable is never set in production.

To try the real models locally, run `npx wrangler login`, put `ANTHROPIC_API_KEY=…` in `api/.dev.vars` (ignored by git) if you want the fallback, and run `npm run dev`. Workers AI calls then use your account's allowance.

## Deploying (owner steps)

These need the Cloudflare account that hosts the CDN.

```sh
cd api
npx wrangler login
npx wrangler d1 create binpal-api              # put the database_id in wrangler.toml
npx wrangler kv namespace create CACHE         # put the id in wrangler.toml
npx wrangler d1 migrations apply binpal-api --remote
npx wrangler secret put ANTHROPIC_API_KEY      # optional: turns on the Anthropic fallback
npx wrangler secret put GITHUB_TOKEN           # files reports in the review queue
npm run deploy
```

Workers AI needs no setup: the `AI` binding in `wrangler.toml` connects it.

`GITHUB_TOKEN` is a fine-grained personal access token (GitHub → Settings → Developer settings → Fine-grained tokens) with access to `BliDir/binpal` only and the **Issues: Read and write** permission. Paste it when `wrangler secret put` asks, never into a file.

### Continuous deploy

After the first deploy, every push to `main` that changes `api/` deploys automatically: the `Deploy` job in `.github/workflows/api.yml` runs after lint, tests and e2e pass, applies new D1 migrations, deploys, and checks `/v1/status`. Pushes that change only the Yokohama bundle or the workflow run the checks without deploying. A manual run of the workflow on `main` always deploys.

It needs two repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
| -- | -- |
| `CLOUDFLARE_ACCOUNT_ID` | The account id from `npx wrangler whoami` |
| `CLOUDFLARE_API_TOKEN` | A token from My Profile → API Tokens, made from the **Edit Cloudflare Workers** template with **D1: Edit** added, scoped to this account and the `blidir.fun` zone |

The `ANTHROPIC_API_KEY` secret lives in Cloudflare, not GitHub, and a deploy keeps it.

Then:

* **First real photo:** Cloudflare's docs don't confirm that `@cf/qwen/qwen3.8-27b` accepts a base64 data URL or honours the JSON schema. Send one real photo and check `ai_log` for a `workers_ai` row with an answer. If Workers AI only ever errors, Anthropic still answers, but the free path isn't working.
* **Custom domain:** `wrangler.toml` serves the Worker on `api.blidir.fun`, and the deploy creates its DNS record and certificate. The `blidir.fun` zone must be in the same Cloudflare account.
* **Anthropic spend limit:** if you set the key, set a monthly limit for its workspace in the Claude Console as a backstop to the daily budget.
* **Check:** `curl https://api.blidir.fun/v1/status` returns `{"ai":"available"}`.

The install id is made by the app, so someone could rotate it to get past the per-install limits; the Neuron ceiling and the Anthropic budget cap what that can cost. An IP-based WAF rate limiting rule on the API's hostname adds a second layer if needed.

## Measuring

Which model answered and what it cost, per day; Workers AI Neurons per UTC day; and AI calls per install that used photo AI. The API never sees installs that didn't need AI, so calls per *active* user needs the app's own count of active installs alongside.

```sh
npx wrangler d1 execute binpal-api --remote --command "
  SELECT day, source, fallback, count(*) AS calls, avg(neurons) AS neurons_per_call,
         avg(micro_usd) AS micro_usd_per_call, avg(duration_ms) AS ms
  FROM ai_log GROUP BY day, source, fallback ORDER BY day DESC"

npx wrangler d1 execute binpal-api --remote --command "
  SELECT day, neurons, calls FROM neurons ORDER BY day DESC LIMIT 14"

# Over-limit attempts also count up, so cap each install at the daily limit (20).
npx wrangler d1 execute binpal-api --remote --command "
  SELECT day, count(*) AS installs, sum(min(count, 20)) * 1.0 / count(*) AS calls_per_install
  FROM usage WHERE kind = 'identify' GROUP BY day ORDER BY day DESC"
```

`usage` only keeps two days, so record calls per install from the last query as it goes. Response times and cache hits are in `ai_log` (`duration_ms`, `source`).
