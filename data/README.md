# Data pipeline

Everything that turns municipal pages and files into the bundles the app downloads.

| Path | Contents |
| -- | -- |
| `sources.yaml` | The pages, PDFs and open datasets the data comes from |
| `snapshots/` | Last seen text of every source, written by the rule monitor |
| `schema/` | Bundle and manifest JSON Schemas with examples ([README](schema/README.md)) |
| `boundaries/` | Town and chōme boundaries per prefecture, for finding the user's area from GPS ([README](boundaries/README.md)) |
| `imports/` | Future-rollout standard open-data pilots; excluded from publishing ([Arakawa](imports/13118/README.md)) |
| `municipalities/` | One folder per municipality: its config, translation tables and built bundle ([Yokohama](municipalities/14100/README.md)) |
| `cdn/` | How bundles are hosted on Cloudflare R2 ([README](cdn/README.md)) |
| `scripts/` | `monitor.py`, `build_yokohama.py`, `build_boundaries.py`, `locate.py`, `publish.py`, `validate.py`, `cdn_put.sh` |
| `tests/` | Tests for the scripts |

## Launch area, sources and licences

**Launch area: Yokohama City, all 18 wards.** One city means one set of sorting rules and one item list; only the collection-day pages differ per ward. Aoba-ku is built and published. The state of the other 17 is in the [Yokohama README](municipalities/14100/README.md#the-other-17-wards). Arakawa (Tokyo) exists as an unpublished pilot of the standard open-data importer.

Every source below is in `sources.yaml` with its type, URL and content selector, and is checked daily by the rule monitor.

| What | Source | Applies to | Type | Granularity |
| -- | -- | -- | -- | -- |
| Sorting rules by item | ごみと資源物の出し方一覧表, on the [Yokohama open data portal](https://data.city.yokohama.lg.jp/dataset/shigen_dashikata) and the [ごみの分別を調べる page](https://www.city.yokohama.lg.jp/kurashi/sumai-kurashi/gomi-recycle/gomi/dashikata.html) | All wards | CSV (CKAN) | 3,413 items |
| How to put out each category | The city's page per category (燃やすごみ, プラスチック資源, …) | All wards | HTML | 11 pages |
| Collection days | Each ward's 収集曜日 pages, grouped by the town's first kana | Per ward | HTML tables | Town and chōme; inside a chōme for 9% of areas |
| New Year schedule | 年末年始の資源とごみの収集日程 | All wards | HTML | City-wide dates |
| Bulky items | 粗大ごみ | All wards | HTML | City-wide; booked collection, no calendar |
| Announcements | The city's ごみ・リサイクル news list and each ward's news list | City and ward | HTML | |
| Area codes, names and boundaries | e-Stat 2020 census small-area boundary data | Kanagawa | Shapefile | Town and chōme |

Licence and terms, as read on 12 November 2026:

| Source | Terms | What that means for BinPal |
| -- | -- | -- |
| Item list (all Yokohama wards) | Published by 資源循環局 in the city's open data catalogue, whose [terms](https://data.city.yokohama.lg.jp/terms.html) license content under **CC BY 4.0** unless stated otherwise | Free to adapt and redistribute, including commercially. Credit the title and 神奈川県横浜市, name the licence, and say the work was modified. Do not present the modified data as the city's own. The bundle's `attribution` carries this credit, and the app must show it |
| Collection-day pages, New Year page (all Yokohama wards) | The city's [site policy](https://www.city.yokohama.lg.jp/aboutweb/sitepolicy.html) reserves copyright on pages but states that numerical data and simple tables are not subject to copyright and are free to use | Weekdays per town and holiday dates are used as facts. The pages' prose is not copied |
| Category pages (all Yokohama wards) | Same site policy; no Creative Commons mark on these pages | Used only as the reference for the short category descriptions BinPal writes itself in `config.yaml`. Not copied, and their text is kept only in the monitor's snapshots |
| e-Stat boundary data | [e-Stat terms of use](https://www.e-stat.go.jp/terms-of-use), compatible with CC BY 4.0 | Free to adapt and redistribute, including commercially, with the source credited and a note that the data was processed. The credit is in each bundle and boundary package |
| Arakawa item list (pilot) | CC BY 4.0, recorded in [its README](imports/13118/README.md) | Not published |

The terms are the same for every Yokohama ward, because all 18 wards' pages are on the city's site under the one policy.

BinPal's English names, kana readings and English notes are its own additions and are not covered by the city's licence; the attribution says so.

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

## Standard open-data importer

`import_standard.py` reads the Digital Agency standard CSV layout for **ゴミの分別方法一覧** (item-definition C: 全国地方公共団体コード, ID, 地方公共団体名, ゴミの品目, 分別区分, 注意点, 料金種別, 料金, 料金備考, 備考). Other layouts are rejected explicitly. Municipality-specific mappings, English text and schedules live with each dataset; the importer contains no Arakawa-specific item or category rules.

```sh
uv run data/scripts/import_standard.py data/imports/13118           # offline, reproducible
uv run data/scripts/import_standard.py data/imports/13118 --refresh # resolve CSV through CKAN
uv run data/scripts/validate.py data/imports/13118/bundle.json
uv run data/tests/test_import_standard.py
```

A configured CKAN `package_show` endpoint resolves a pinned resource ID, verifies its CSV format and expected licence, then downloads the resource URL. The default run uses committed `source/package.json` and `source/sorting.csv`; `--refresh` requires their reviewed CSV digest to remain unchanged. If a download changes, the importer reports the new digest and leaves existing snapshots and bundle untouched. Download the candidate to a separate path, review its changes, then update the source snapshot, `config.yaml` digest and affected translations together before rebuilding.

`items.tsv` binds every translation to the complete source row with a SHA-256 digest, including category, caution and fee fields. Missing, added, removed or changed rows stop the build for review; a renamed item cannot silently retain its old translation. The Japanese instructions preserve all nonempty source fields. English names, kana, aliases and complete English instructions are curated independently of the build; it never calls an LLM. `valid_from` is configured explicitly, since catalog timestamps need not be effective dates.

`base.json` supplies municipality details, source credits, categories, real e-Stat area IDs, calendars and exceptions from separately checked municipal pages. The importer replaces only its empty rules array and validates the complete bundle before writing. Check the source licence and include attribution when adding a municipality. Do not infer schedules from item categories.

To reuse it, create another dataset directory with `config.yaml`, `base.json`, `items.tsv` and the two source snapshots. Set the CKAN API root, package name, resource UUID, expected licence and CSV digest; map every published category to a category in `base.json`. TSV columns are `id`, `ja`, `kana`, `en`, `aliases` (semicolon separated), `source_sha256` and `instructions_en`. `row_digest` in the importer computes the digest from the parsed Japanese row; it is independent of CSV encoding and column line endings. Validate and review the resulting rules, translations and calendar coverage before moving a candidate under `municipalities/` for publishing.

The first pilot is [Arakawa](imports/13118/README.md), whose catalog explicitly identifies its dataset as conforming to the Digital Agency standard and licenses it CC BY 4.0. It is a future-rollout artifact and is not published by merging this importer. Yokohama continues to use its existing official-page pipeline.

## Publishing

`.github/workflows/publish.yml` runs `scripts/publish.py` whenever a `municipalities/<id>/bundle.json` or a `boundaries/<prefecture>.json` changes on `main`, or when started by hand. It publishes the committed bundles; it does not rebuild them from the municipal sites, so what goes out is exactly what was reviewed in the pull request.

For each municipality it compares the committed bundle with the one the live manifest points to, ignoring `bundle_version` and `generated_at`:

| Bundle | What happens |
| -- | -- |
| Same content | Nothing. Its manifest entry, version and file are left as they are |
| Different content, or not published yet | It gets the next `bundle_version`, is uploaded to `/bundles/<id>/<version>.json`, and its manifest entry is replaced |

Boundary packages work the same way, under `/boundaries/<prefecture>/<version>.json`, and are listed under `boundaries` in the manifest.

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
