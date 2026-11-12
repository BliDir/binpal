# Data pipeline

Everything that turns municipal pages and files into the bundles the app downloads.

| Path | Contents |
| -- | -- |
| `sources.yaml` | The pages, PDFs and open datasets the data comes from |
| `snapshots/` | Last seen text of every source, written by the rule monitor |
| `schema/` | Bundle and manifest JSON Schemas with examples ([README](schema/README.md)) |
| `municipalities/` | One folder per municipality: its config, translation tables and built bundle ([Yokohama](municipalities/14100/README.md)) |
| `cdn/` | How bundles are hosted on Cloudflare R2 ([README](cdn/README.md)) |
| `scripts/` | `monitor.py`, `build_yokohama.py`, `publish.py`, `validate.py`, `cdn_put.sh` |
| `tests/` | Tests for the scripts |

## Rule monitor

Municipalities change sorting rules and collection days without notice. `.github/workflows/rule-monitor.yml` runs `scripts/monitor.py` once a day (06:17 in Japan) to notice.

For each source in `sources.yaml` it:

1. fetches the page or file, at most one request every 2 seconds, with the User-Agent `BinPalRuleMonitor/1.0 (+https://github.com/BliDir/binpal)`;
2. reduces it to plain text: for HTML, the content under the source's CSS `selector`, without scripts, navigation, headers and footers, and one line per table row; for PDFs, the extracted text; for CKAN datasets, each file's name and SHA-256 (a file is only downloaded again when its last-modified date moves);
3. drops lines that change on their own, such as `最終更新日 …`, plus any line matching the source's `ignore` patterns;
4. compares the result with `snapshots/<id>.txt`.

| Outcome | What happens |
| -- | -- |
| Same text | Nothing |
| Different text | Gemini summarizes the change and effective date above the raw diff. The updated snapshot is committed to `main`, including cosmetic-only changes, which are logged without an issue. Other changes open an issue **Rule source changed: `<id>`** is opened with the diff. If that issue is still open from an earlier change, the new diff is added as a comment |
| No snapshot yet (rule sources) | The snapshot is committed as the baseline, with no issue |
| Fetch or parse failure | Counted in `snapshots/state.json`. On the 3rd run in a row an issue **Rule source unreachable: `<id>`** is opened, once. A selector that no longer matches anything counts as a failure, so a redesigned page is not mistaken for a rule change |

Issues carry the `rule-monitor` label. If the API key is missing, both models fail, or a response is invalid, the monitor keeps the alert with an explicit unavailable summary instead of suppressing it.

### Gemini setup

Add the repository Actions secret `GEMINI_API_KEY`:

```sh
gh secret set GEMINI_API_KEY --repo BliDir/binpal
```

The workflow passes it to the monitor through the environment. The default primary model is `gemini-3.5-flash-lite`; the fallback is `gemini-2.5-flash-lite`. Override them with `GEMINI_MODEL` and `GEMINI_FALLBACK_MODEL` when running locally. The key is sent in an HTTP header and never logged. Local runs without a key still fetch sources and print raw-diff alerts.

Each changed source sends its complete old/new normalized text for a structured summary, change type, effective date and cosmetic classification. Uncertain classifications keep the issue. Requests are spaced at least 6.1 seconds apart; a 429 or server error receives one retry after a short backoff, then the fallback is tried. Large inputs or project token quotas can still exhaust rate limits; both-model failure preserves the alert. No model calls are made for unchanged sources or initial rule-page baselines.

### Ward announcements

Sources with `type: news` scan links in their content selector. An entry must contain both a waste-related term (such as ごみ, 資源 or 分別) and a change term (such as 変更, 新しく or 4月から). The snapshot stores matching entries and their absolute announcement URLs. Newly matching entries open an issue even on the first run; removals and reordering do not. The initial configured feed is the Aoba ward news list. This checks announcement headlines/list entries, not the body of every linked article; add other ward feeds as coverage expands.

GitHub disables scheduled workflows in a public repo after 60 days without activity. The monitor rewrites the `heartbeat` date in `snapshots/state.json` every 30 days, so there is a commit even when no source changes.

### Adding a source

Add an entry to `sources.yaml` (the fields are described at the top of the file), then create its baseline and check that the text is the content you expect:

```sh
uv run data/scripts/monitor.py --only <id>
cat data/snapshots/<id>.txt
```

Commit the entry and the snapshot together. If the snapshot contains lines that will change on their own (dates, counters, "related pages" lists), remove them with `strip` or `ignore` and delete the snapshot to regenerate it.

### Running by hand

```sh
uv run data/scripts/monitor.py        # check everything, print the issues it would open
uv run data/tests/test_monitor.py     # tests, against fixture sources
gh workflow run rule-monitor.yml      # run on GitHub, opening real issues
```

## Publishing

`.github/workflows/publish.yml` runs `scripts/publish.py` whenever a `municipalities/<id>/bundle.json` changes on `main`, or when started by hand. It publishes the committed bundles; it does not rebuild them from the municipal sites, so what goes out is exactly what was reviewed in the pull request.

For each municipality it compares the committed bundle with the one the live manifest points to, ignoring `bundle_version` and `generated_at`:

| Bundle | What happens |
| -- | -- |
| Same content | Nothing. Its manifest entry, version and file are left as they are |
| Different content, or not published yet | It gets the next `bundle_version`, is uploaded to `/bundles/<id>/<version>.json`, and its manifest entry is replaced |

Then `manifest.json` is uploaded, last. Older bundle files are never overwritten or deleted, so an app holding a manifest from a minute ago can still download what it lists.

Nothing is uploaded unless every bundle in the repo passes `validate.py` and the new manifest matches the exact bytes it will point to. If an upload fails part way, the old manifest stays in place and the next run picks up the bundles that did arrive. After uploading, each new bundle is fetched back through the CDN and its checksum compared.

The version counter is the live manifest, read straight from the bucket. Nothing is committed back to the repo.

```sh
gh workflow run publish.yml -f dry_run=true               # show what would be published
gh workflow run publish.yml -f prefix=_smoke/publish/     # publish a full copy under a test prefix
gh workflow run publish.yml                               # publish for real
uv run data/scripts/publish.py --root /tmp/cdn            # publish into a local folder
uv run data/tests/test_publish.py
```
