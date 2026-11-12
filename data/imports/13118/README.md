# Arakawa standard open-data pilot (13118)

Future-rollout importer example for DAI-563. **Not enabled in the publisher or app.** The output is a schema-valid candidate bundle with all 223 published sorting items and one pilot area, 南千住一丁目 (Minamisenju 1-chome, `13118-001001`). This is not a full Arakawa service rollout.

| File | Purpose |
| -- | -- |
| `config.yaml` | CKAN package/resource selection, reviewed source digest, date policy and category mapping |
| `source/package.json` | Official CKAN response captured on 12 November 2026 |
| `source/sorting.csv` | Original downloaded CP932 CSV bytes, preserved unchanged |
| `items.tsv` | Agent-prepared English names, readings, aliases and complete instructions, bound to source-row digests |
| `base.json` | Municipality, categories, attribution, real pilot area and separately checked calendar facts |
| `bundle.json` | Deterministic output of the generic importer |
| `REVIEW.md` | Source checks, known gaps and release review status |

## Sources and licences

- Sorting: Tokyo CKAN package [`t131181d0000000014`](https://catalog.data.metro.tokyo.lg.jp/dataset/t131181d0000000014), resource `69a49f19-fc49-4a75-8c77-8b6f983bcb53`. It explicitly states conformance to the Digital Agency’s municipal standard open dataset. The CSV comes from [Arakawa’s official site](https://www.city.arakawa.tokyo.jp/documents/23112/131181_garbage_separation.csv). The package states **CC BY 4.0**; attribution credits Arakawa and identifies the added translations, readings and search terms.
- Format: [Digital Agency municipal standard open datasets](https://www.digital.go.jp/resources/open_data/municipal-standard-data-set-test), definition C, ゴミの分別方法一覧.
- Collection: [official waste/plastic collection page](https://www.city.arakawa.tokyo.jp/a025/recycle/shuushuubi/syusyubi.html), checked 12 November 2026. Minamisenju 1-chome shares the row 南千住一・六丁目: burnable Monday/Thursday, non-burnable first/third Friday, plastics Wednesday; put out by 08:00. These numerical schedule facts are transcribed into `base.json`, with their source URL. No CC licence is asserted for the surrounding website prose; its general website terms remain a release-review item.
- Area: [e-Stat 2020 census small-area boundaries](https://www.e-stat.go.jp/gis/statmap-search/data?dlserveyId=A002005212020&code=13118&coordSys=1&format=shape&downloadType=5), record `PREF=13, CITY=118, S_AREA=001001`, name 南千住一丁目. Credit follows [e-Stat terms](https://www.e-stat.go.jp/terms-of-use).

## Rebuild and refresh

```sh
uv run data/scripts/import_standard.py data/imports/13118
uv run data/scripts/validate.py data/imports/13118/bundle.json
uv run data/tests/test_import_standard.py
```

Add `--refresh` to resolve the resource through CKAN and verify fresh download bytes against the configured digest. It does not update translations or approve changed data automatically. Builds are offline by default. CI rebuilds and compares the output with the committed bundle.

## Coverage and dates

The standard sorting dataset contains no calendars. Three regular collection patterns for Minamisenju 1-chome come from the official page. The single `resources` category is deliberately left without a calendar: the [ward’s recycling page](https://www.city.arakawa.tokyo.jp/a025/recycle/shuushuubi/minami_1_std.html) has different dates by street block and by recyclable material. A single chome-wide date would be wrong. Bulky, not-collected and other disposal routes also have no ordinary collection calendar.

There are no holiday exceptions in this pilot. Neither a Tokyo boundary package nor full ward area/calendar coverage is included. These are rollout work, not data inferred by the importer.

The catalog’s resource timestamp is 24 March 2025, while the downloaded content includes newer plastics categories. Metadata is not treated as proof of an effective date. `valid_from` is the observation baseline **2026-11-12**; historical rules cannot be inferred. `generated_at` and `bundle_version` are deterministic placeholders. `verified_at` is provisionally the agent’s source-check date; the schema’s person-verification requirement is **not yet satisfied for release**. A human reviewer must verify the rules and set the date before publishing.
