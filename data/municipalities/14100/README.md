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

After a rebuild from a fresh download, set `items.verified_at` in `config.yaml` to that day and raise `bundle_version`.

## Adding a ward

1. Download the ward's small-area boundary data from e-Stat (2020 census, shapefile) and append its areas: `uv run data/scripts/build_yokohama.py areas <ward id> <zip> >> data/municipalities/14100/areas.tsv`.
2. Add the ward and its 収集曜日 pages to `wards` in `config.yaml`, and the pages to `data/sources.yaml`.
3. Add the ward's towns to `towns.tsv`. The build checks each reading against the page's 五十音 headings.
4. Rebuild. Fix any town the pages spell differently from e-Stat with `town_aliases`.

## Things to know

* **Review status.** Japanese text is the city's own. The 3,413 English names and readings and the 788 English notes were machine-translated and have not been reviewed by a person. `verified_at` records when the Japanese was last taken from the source, not a human check of the English.
* **Licence.** The city's site policy reserves copyright on its pages and allows reuse only where a page carries a Creative Commons mark; it treats "numerical data and simple tables" as free to use. The item list page carries no such mark, so permission to redistribute the item notes should be confirmed with the city before release.
* **Areas that share a name.** e-Stat splits 市ケ尾町, 荏田町, 奈良町 and 鴨志田町 into several small areas without chome numbers. Each is its own area in the bundle, because the boundary lookup returns that code, so those names appear more than once. They have the same collection days.
* **Calendar start dates** are the page's 最終更新日. The pages do not say when a schedule took effect.
* **Rule start dates** are the CSV's publication date, taken from its file name.
* **Old and new battery rules.** A few notes in the CSV still carry the wording from before 1 December 2025 next to the new rule. The Japanese is copied unchanged; the English gives only the current rule.
* **Postal codes** are not filled in.
* **Used paper and cloth** (古紙, 古布) have no calendar: neighbourhood groups collect them on their own dates.
