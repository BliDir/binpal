# Bundle schema

The data contract between the back office and the app. The publisher writes these files to the CDN; the app reads them. Neither side talks to the other directly, so this folder is the only thing they share.

| File | Describes |
| -- | -- |
| `manifest.v1.schema.json` | `/manifest.json`: covered areas and the latest bundle per municipality, and the latest boundary package per prefecture |
| `bundle.v1.schema.json` | `/bundles/{municipality_id}/{bundle_version}.json`: wards, areas, categories, rules, calendars, exceptions |
| `boundaries.v1.schema.json` | `/boundaries/{prefecture_code}/{version}.json`: town and chōme boundaries for on-device lookup ([details](../boundaries/README.md)) |
| `common.v1.schema.json` | Shared types (IDs, dates, localised text, the common category set) |
| `examples/` | A hand-written manifest and Yokohama bundle laid out like the CDN |

All schemas use JSON Schema draft 2020-12.

> **The example data is mostly illustrative. Do not ship it.** The Aoba-ku collection days (青葉台1・2丁目, あざみ野3丁目) match the [city's collection-day page](https://www.city.yokohama.lg.jp/kurashi/sumai-kurashi/gomi-recycle/gomi/shushuyobi/aoba/a-u.html) as last updated on 23 January 2026, including that 燃えないごみ, スプレー缶 and 電池類 go out with 燃やすごみ and 小さな金属類 with 缶・びん・ペットボトル. Everything else, including area codes, Naka-ku days, item rules and the New Year exceptions, was written to exercise the schema.

## Validate

```sh
uv run data/scripts/validate.py data/schema/examples/manifest.json
```

Pass a manifest to validate it and every bundle it points to (paths resolve against the manifest's folder, or `--root`). Pass a bundle to validate just that bundle. Besides the JSON Schema, the script checks what a schema cannot express:

* IDs are unique, and every category and area a rule, calendar or exception references exists.
* Areas belong to the bundle's municipality.
* `valid_to` is not before `valid_from`, and versions of the same `item_id` do not overlap.
* A manifest's `sha256`, `size_bytes`, `bundle_version` and `area_ids` match the bundle file.

## Identifiers

| ID | Format | Example |
| -- | -- | -- |
| Municipality | 5-digit local government code | `14100` (Yokohama City), `13112` (Setagaya) |
| Ward | 5-digit code of a designated city's ward | `14117` (Aoba-ku, Yokohama) |
| Area | Ward code (designated cities) or municipality code (elsewhere) + `-` + 6-digit e-Stat small-area code; together the 11-digit e-Stat `KEY_CODE` | `14117-001001` |
| Category, calendar, item | Lowercase slug, stable across bundle versions | `moyasu`, `pet-bottle` |

Area IDs come straight from the boundary data (e-Stat uses the ward code where there is one), so the on-device point-in-polygon lookup returns an ID the bundle already uses.

## Wards

A designated city (政令指定都市) such as Yokohama has one set of sorting rules for the whole city, but its boundary data is split by ward. Its bundle is published under the city code (`/bundles/14100/…`) and lists its `wards`; each area has a `ward_id`, and its ID starts with that ward code. The manifest lists the same `ward_ids`, so the app can map a detected area to its city.

Tokyo's special wards (Setagaya and so on) are municipalities in their own right: their bundles have no `wards`, and area IDs start with the municipality code.

## Conventions

* **Dates** are `YYYY-MM-DD` in Japan time. `valid_from` and `valid_to` are both **inclusive**; no `valid_to` means open-ended.
* **Text** shown to users is an object keyed by language. `ja` and `en` are required; other BCP 47 tags may be added. `names` also requires `kana` (hiragana or katakana reading) for search.
* **Categories** are the municipality's own (Yokohama's 燃やすごみ, プラスチック資源, …). A category can have no calendar, for example Yokohama's 古紙・古布, which neighbourhood groups collect. Each maps to one value of the common set, which drives icons and colours: `burnable`, `non_burnable`, `plastic`, `paper`, `cans_bottles`, `pet_bottles`, `resources`, `hazardous`, `bulky`, `not_collected`, `other`.
* **Rule versions:** an announced change is published early as a second rule with the same `item_id` and a later `valid_from`. The app shows the version whose range contains today.
* **Attribution** lists licence credits (for example CC BY 4.0) the app must display for this bundle.

## Collection days

For an area, category and date, there is a collection when:

1. a calendar lists both the category and the area, the date is inside its validity range, and its pattern matches the date, **and** no `no_collection` exception matches; **or**
2. an `extra_collection` exception matches.

An exception matches when its date is equal, and its `categories` and `area_ids` either include the category and area or are omitted (omitted means all). `extra_collection` must list its categories. A moved collection is a `no_collection` on the old date plus an `extra_collection` on the new one.

A calendar lists every category that shares its pattern, so "燃えないごみ goes out with 燃やすごみ" is one calendar, not two.

Patterns:

* `weekly`: every week on the listed `weekdays`.
* `monthly_nth_weekday`: the `nth` occurrences of `weekday` in each calendar month. Days 1–7 hold the 1st occurrence, 8–14 the 2nd, and so on up to the 5th. For mixed weekdays (1st Monday and 3rd Thursday), use two calendars.

## Versioning policy

Every manifest and bundle carries an integer `schema_version`: the **major** version of the schema it follows. Schema files are named by it (`bundle.v1.schema.json`).

**Compatible changes stay on the same version.** Adding an optional field, a new pattern `type`, a new exception `type` or a new language is compatible. Edit the `v1` schema files in place. Apps must therefore:

* ignore fields they do not know;
* skip a calendar whose pattern `type` they do not know, or an exception whose `type` they do not know, rather than fail the whole bundle;
* treat an unknown common category as `other`.

The publisher validates strictly (`additionalProperties: false`), so typos are caught before upload even though apps read leniently.

**Breaking changes bump the version.** Removing or renaming a field, making an optional field required, or changing a field's meaning. For a bump to 2:

1. Add `bundle.v2.schema.json` (and `common.v2` if needed) beside v1; do not delete v1.
2. The publisher writes both formats: v1 at `/bundles/{id}/{n}.json`, v2 at `/bundles/{id}/v2/{n}.json`.
3. The manifest lists both under the municipality's `bundles`, highest `schema_version` first. Each app takes the first entry it supports.
4. Stop publishing v1 only after the app versions that read it are retired (for example by a forced-update prompt).

**The manifest is the one fixed point.** Old apps always fetch `/manifest.json`, so its v1 shape only gets compatible changes. A breaking manifest change would go to a new path (`/v2/manifest.json`), with the old one kept up to date until old apps are retired.

`bundle_version` is separate: it is a per-municipality counter that goes up by one on every publish, whatever the schema version. The app compares it with its cached copy and verifies `sha256` after download.
