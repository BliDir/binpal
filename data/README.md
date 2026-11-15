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

**Launch area: Yokohama City, all 18 wards; Kawasaki City next (below).** One city means one set of sorting rules and one item list; only the collection-day pages differ per ward. Aoba-ku is built and published. The state of the other 17 is in the [Yokohama README](municipalities/14100/README.md#the-other-17-wards). Arakawa (Tokyo) exists as an unpublished pilot of the standard open-data importer.

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

### Kawasaki (next: Takatsu-ku first)

**Scope (DAI-588, 15 November 2026): Kawasaki City (14130), Takatsu-ku first for Kajigaya (梶ヶ谷), then the other six wards.** As in Yokohama, one city means one set of sorting rules; only collection days differ by area. Ward codes, checked against the Kanagawa boundary package: 川崎区 14131, 幸区 14132, 中原区 14133, **高津区 14134**, 多摩区 14135, **宮前区 14136**, 麻生区 14137 (670 e-Stat areas; 73 in Takatsu, 88 in Miyamae). Takatsu and Miyamae share one collection office (宮前生活環境事業所, 044-866-9131) and one calendar.

What the city's pages say:

* **Categories**: 普通ごみ (twice a week); weekly 空き缶・ペットボトル (one bag), 空きびん, 使用済み乾電池 (collected with cans), ミックスペーパー and プラスチック資源; 小物金属 (twice a month); 粗大ごみ (booked, fee). プラスチック資源 (products and packaging in one bag) has been citywide since April 2026, on the old プラスチック製容器包装 day. Rechargeable batteries go out with 小物金属, insulated in a clear bag with a note, **since November 2025** (令和7年11月).
* **Days**: public holidays are collection days. **New Year**: collection every day but Sunday up to 31 December, again from 4 January, so none on 1–3 January. 小物金属 and 粗大ごみ run on the 1st and 3rd (or 2nd and 4th) **occurrence of a weekday** in the month, not week: the bundle's `monthly_nth_weekday`.
* **Kajigaya is two places.** 梶ヶ谷 is a town in both Takatsu-ku (e-Stat 梶ケ谷一丁目 to 六丁目, 14134-415001 to 006) and Miyamae-ku (梶ケ谷, 14136-509000), with different days: Takatsu has 普通ごみ Tue/Fri, cans and bottles Wed, ミックスペーパー Mon, プラスチック資源 Thu, 小物金属 1st/3rd Mon; Miyamae has Mon/Thu, Tue, Wed, Sat, 1st/3rd Fri. The area picker and GPS lookup must keep the ward. e-Stat writes ケ where the city writes ヶ, so the build needs a town alias, as Yokohama has.
* **Item list**: no open data. The web page ごみの分別に迷ったら lists 248 items (Yokohama's CSV has 3,413), many as "A or B" by size or material (小物金属または粗大ごみ for 49 items), which the bundle needs as separate rules. The city's app has over 10,000 items but publishes them nowhere else.

| What | Source | Applies to | Type | Granularity |
| -- | -- | -- | -- | -- |
| Categories | [川崎市のごみの分類](https://www.city.kawasaki.jp/kurashi/category/261-1-10-3-0-0-0-0-0-0.html) | All wards | HTML | City-wide |
| Sorting rules by item | [ごみの分別に迷ったら](https://www.city.kawasaki.jp/kurashi/category/261-1-10-2-0-0-0-0-0-0.html) | All wards | HTML tables by kana | 248 items |
| Collection days | 収集日一覧 per pair of wards: [川崎区](https://www.city.kawasaki.jp/300/page/0000012570.html), [幸区・中原区](https://www.city.kawasaki.jp/300/page/0000012568.html), [**高津区・宮前区**](https://www.city.kawasaki.jp/300/page/0000012561.html), [多摩区・麻生区](https://www.city.kawasaki.jp/300/page/0000012577.html) | Per ward | HTML tables | Town (255 rows across 7 wards) |
| Calendar booklet, New Year rule | Each 収集日一覧 page links a one-page PDF (for 高津区・宮前区, `takatsumiyamae(R8).pdf`; a Filipino edition exists) | Per pair of wards | PDF, **images only** | Same days as the HTML, grouped by schedule |
| プラスチック資源, rechargeable batteries | [プラスチック資源](https://www.city.kawasaki.jp/300/page/0000154533.html), [充電式電池](https://www.city.kawasaki.jp/300/page/0000176397.html) | All wards | HTML | City-wide |
| Not collected | [市で収集しないもの](https://www.city.kawasaki.jp/kurashi/category/261-1-10-8-0-0-0-0-0-0.html) | All wards | HTML | City-wide |
| Bulky items | [粗大ごみ](https://www.city.kawasaki.jp/kurashi/category/261-1-10-11-0-0-0-0-0-0.html); 粗大ごみ受付センター 0570-044-530 / 044-930-5300, online any time, phone Mon–Sat 8:00–16:45, book 3 days ahead | All wards | HTML | Booked, on the 小物金属 days |
| Offices | [生活環境事業所一覧](https://www.city.kawasaki.jp/300/page/0000005226.html) | Per ward | HTML | One office per ward or pair |
| Announcements | [収集状況について](https://www.city.kawasaki.jp/kurashi/category/261-1-7-0-0-0-0-0-0-0.html) | City | HTML list | |
| Area codes, names and boundaries | e-Stat 2020 census small-area boundary data, already in `boundaries/14.json` | Kanagawa | Shapefile | Town and chōme |

All the HTML sources are in `sources.yaml` (article pages under `#mol_contents`, category listings under `ul.category_end`), **paused** until the terms below are confirmed: an unpaused source commits a snapshot of the page's text to this public repository every day. The calendar PDF is not listed: it has no text layer, so the monitor can't compare it; the HTML tables carry the same days, and the New Year rule is read from it by hand.

Terms, as read on 15 November 2026:

| Source | Terms | What that means for BinPal |
| -- | -- | -- |
| Every page and PDF on www.city.kawasaki.jp | The [site policy](https://www.city.kawasaki.jp/main/site_policy/0000000027.html) reserves all rights to the city, forbids copying or reuse without permission beyond private copying and quotation, and asks anyone who wants to republish to contact the page's office first, on condition the content is not altered. There is no open-data licence and no exemption for simple tables, unlike Yokohama | **Nothing from Kawasaki ships until the city agrees (DAI-589).** Collection weekdays per town are facts, but the item list's wording and BinPal's translations of it would be reproduction and alteration. Ask 環境局生活環境部収集計画課 (044-200-2583, 30syusyu@city.kawasaki.jp) for permission to use the collection days and item list, translated, with credit. Linking is free and needs no request |
| e-Stat boundary data | As for Yokohama: compatible with CC BY 4.0 | Already in the Kanagawa boundary package |

**Building** (DAI-590): `uv run data/scripts/build_kawasaki.py` reads `municipalities/14130/` (`config.yaml`, with `areas.tsv` and `towns.tsv` from DAI-591, and `items.tsv` and `notes.tsv` for translations) and the city's pages, downloaded into `data/.cache/14130/`, which git ignores. It parses each ward's 収集日一覧 table (weekly cells such as 火曜・金曜, and 第1・3回目 月曜 as `monthly_nth_weekday` for 小物金属), matches towns to e-Stat areas with ヶ and ケ treated alike, closes 1–3 January every year, and maps the item list's 分別区分 through `methods`. **It writes `bundle.json` only when `reuse_confirmed` is true in `config.yaml`**; until DAI-589 is settled it checks everything and prints what it would write. `config.yaml` holds only BinPal's own wording (category descriptions, leads) and mappings, and the tests use fixture pages with made-up days, so nothing of the city's is in the repo.

Checked by hand against the official 高津区・宮前区 calendar (`takatsumiyamae(R8).pdf`, an image) on 15 November 2026: the parser's days for 梶ヶ谷 (Takatsu-ku), 北野川 and 末長 match it. Before the first real build: map the remaining 分別区分 texts (the build lists them; most are "A or B" combinations), check each lead's size limits against the items' notes, and write `items.tsv` and `notes.tsv`.

**Towns with split schedules.** Kawasaki publishes collection days per town, so most of its areas need no decision: a town row applies to every e-Stat area of that town in that ward, and the two chōme-range rows in Saiwai-ku (小倉1～5丁目, 古市場1・2丁目) to those chōme. The one split inside an area is 河原町団地 in Saiwai-ku, by building number; it waits for the decision on split areas in DAI-559, as Yokohama's do. **Takatsu-ku and Miyamae-ku have no splits**, so Kajigaya does not depend on that decision.

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

Issues carry the `rule-monitor` label. Reports from the app ("this looks wrong") land in the same queue with the `user-report` label, and `priority` once several people report the same thing or area; see `api/README.md`. If the API key is missing, both models fail, or a response is invalid, the monitor keeps the alert with an explicit unavailable summary instead of suppressing it.

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

A source whose terms don't yet allow storing its text gets `paused: "<why>"`. It is validated with the others but not fetched and has no snapshot. Remove `paused` once the terms allow it, then create the baseline as above.

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
