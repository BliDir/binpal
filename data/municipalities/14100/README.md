# Yokohama City (14100)

The bundle for Yokohama, built by `data/scripts/build_yokohama.py`. Aoba-ku (14117) is the only ward so far.

| File | Contents | Edited by |
| -- | -- | -- |
| `bundle.json` | The built bundle, one rule, area or calendar per line | the build |
| `config.yaml` | Municipality, categories, how the city's 出し方 column maps to categories, wards and their pages | hand |
| `areas.tsv` | Every e-Stat small area per ward (code, name, town, chome) | `build_yokohama.py areas` |
| `towns.tsv` | Reading and romanised name of each town | hand |
| `items.tsv` | Reading, English name and aliases for each item in the city's list | hand or LLM, then reviewed |
| `notes.tsv` | English for each distinct 出し方のポイント text | hand or LLM, then reviewed |

## Where the data comes from

| Data | Source | How |
| -- | -- | -- |
| Items, their category and notes (Japanese) | [ごみと資源物の出し方一覧表](https://www.city.yokohama.lg.jp/kurashi/sumai-kurashi/gomi-recycle/gomi/dashikata.html) (CSV, 3,413 items, February 2026) | Copied as is |
| Collection days | The ward's [収集曜日 pages](https://www.city.yokohama.lg.jp/kurashi/sumai-kurashi/gomi-recycle/gomi/shushuyobi/aoba/index.html) | Parsed from the tables; no LLM involved |
| New Year closure | [年末年始の収集日程](https://www.city.yokohama.lg.jp/kurashi/sumai-kurashi/gomi-recycle/gomi/nenmatsunenshi.html) | Parsed from the page |
| Area codes and names | e-Stat 2020 census small-area boundary data | `areas.tsv` |
| Category descriptions | The city's page for each category | Summarised by hand in `config.yaml` |
| English names, kana readings, English notes | Not published by the city in a form that can be joined to the list | Translated with an LLM into `items.tsv` and `notes.tsv` |

All of these pages are in `data/sources.yaml`, so the rule monitor opens an issue when one changes. A changed `yokohama-item-list` usually means a new CSV.

## Rebuilding

```sh
uv run data/scripts/build_yokohama.py --refresh
uv run data/scripts/validate.py data/municipalities/14100/bundle.json
uv run data/tests/test_build_yokohama.py
```

Without `--refresh` the build reuses the downloads in `data/.cache/14100/`. The build stops, listing what to fix, when:

* the CSV has an item, 出し方 value or note that has no translation yet, or an item was renamed (add or check the row in `items.tsv`, `notes.tsv` or `config.yaml`);
* a table row names a town or chome that is not in `areas.tsv`, or an area in `areas.tsv` has no row;
* a town's reading in `towns.tsv` does not start with the 五十音 heading the page lists it under;
* a page no longer has the sentences the build relies on (the 8 a.m. deadline, which categories share a day, the New Year date range).

After a rebuild from a fresh download, set `items.verified_at` in `config.yaml` to that day. Merging the changed `bundle.json` to `main` publishes it; the publisher assigns the real `bundle_version` and `generated_at`, so the values in the committed file are placeholders.

## Adding a ward

1. Download the ward's small-area boundary data from e-Stat (2020 census, shapefile) and append its areas: `uv run data/scripts/build_yokohama.py areas <ward id> <zip> >> data/municipalities/14100/areas.tsv`.
2. Add the ward and its 収集曜日 pages to `wards` in `config.yaml`, and the pages to `data/sources.yaml`.
3. Add the ward's towns to `towns.tsv`. The build checks each reading against the page's 五十音 headings.
4. Rebuild. Fix any town the pages spell differently from e-Stat with `town_aliases`.

## The other 17 wards

Yokohama is the launch area, and all 18 wards share the item list, categories and New Year schedule already in the bundle. What differs per ward is the collection-day pages. All 126 of them were downloaded and run through the same parser on 12 November 2026:

| Ward | Code | Pages | Table rows | e-Stat areas | Areas whose schedule splits inside the area |
| -- | -- | -- | -- | -- | -- |
| 青葉区 Aoba | 14117 | 6 | 47 | 85 | 0 (built) |
| 都筑区 Tsuzuki | 14118 | 8 | 51 | 97 | 0 |
| 旭区 Asahi | 14112 | 6 | 61 | 77 | 0, plus 11 exception rows |
| 磯子区 Isogo | 14107 | 9 | 76 | 78 | 2 |
| 南区 Minami | 14105 | 8 | 67 | 153 | 4 |
| 西区 Nishi | 14103 | 6 | 43 | 69 | 4 |
| 保土ケ谷区 Hodogaya | 14106 | 6 | 55 | 66 | 4 |
| 緑区 Midori | 14113 | 5 | 30 | 64 | 5 |
| 港北区 Kohoku | 14109 | 7 | 54 | 108 | 6 |
| 瀬谷区 Seya | 14114 | 6 | 39 | 60 | 6 |
| 戸塚区 Totsuka | 14110 | 5 | 42 | 52 | 6 |
| 鶴見区 Tsurumi | 14101 | 7 | 74 | 131 | 7 |
| 栄区 Sakae | 14115 | 5 | 42 | 60 | 11 |
| 金沢区 Kanazawa | 14108 | 7 | 52 | 103 | 18 |
| 中区 Naka | 14104 | 12 | 141 | 259 | 19 |
| 神奈川区 Kanagawa | 14102 | 12 | 121 | 130 | 20 |
| 港南区 Konan | 14111 | 5 | 41 | 85 | 22 |
| 泉区 Izumi | 14116 | 6 | 52 | 70 | 26 |
| **Total** | | **126** | **1,088** | **1,747** | **160 (9%)** |

What the survey found:

* **Every ward uses the same table** and the same three collection groups (燃やすごみ, プラスチック資源, 缶・びん・ペットボトル), so the parser needs no per-ward logic.
* **Granularity is town and chōme for 91% of areas.** Aoba and Tsuzuki are entirely at that level.
* **In the other 9%, the schedule changes inside a chōme.** Those rows are written by address range (入江1丁目1~28番地), by landmark (岩井町【JR線路より西側】), or as "一部". An e-Stat area is the smallest unit a bundle calendar can target, so these 160 areas cannot be given one schedule today. They need either a schema change (several schedules per area, with the app asking which applies) or to be shown as "check your collection point".
* **Spelling differs from e-Stat in small ways** the build must normalise or alias: ヶ and ケ (霞ヶ丘 / 霞ケ丘), 〜 and ~, and a town named without its chōme where e-Stat has them.
* **Two pages break the parser's checks**: one Tsurumi page (`tagyou.html`) lacks the sentence about which categories share a day, and one Minami row says only to contact the office.
* Readings and romanised names are needed for about 720 more towns in `towns.tsv`.

So Tsuzuki can be added with the steps under "Adding a ward" as they are. The remaining wards need the split-area decision first.

## Things to know

* **Review status.** Japanese text is the city's own. The 3,413 English names and readings and the 788 English notes were machine-translated and have not been reviewed by a person. `verified_at` records when the Japanese was last taken from the source, not a human check of the English.
* **Licence.** The item list is in the city's open data catalogue under CC BY 4.0, and the bundle carries the credit that licence asks for. Collection-day tables fall under the site policy's "numerical data and simple tables", which are free to use. Details are in [Launch area, sources and licences](../../README.md#launch-area-sources-and-licences).
* **Areas that share a name.** e-Stat splits 市ケ尾町, 荏田町, 奈良町 and 鴨志田町 into several small areas without chome numbers. Each is its own area in the bundle, because the boundary lookup returns that code, so those names appear more than once. They have the same collection days.
* **Calendar start dates** are the page's 最終更新日. The pages do not say when a schedule took effect.
* **Rule start dates** are the CSV's publication date, taken from its file name.
* **Old and new battery rules.** A few notes in the CSV still carry the wording from before 1 December 2025 next to the new rule. The Japanese is copied unchanged; the English gives only the current rule.
* **Postal codes** are not filled in.
* **Used paper and cloth** (古紙, 古布) have no calendar: neighbourhood groups collect them on their own dates.
