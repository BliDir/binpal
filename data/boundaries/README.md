# Boundary packages

Town and chōme boundaries the app uses to find the user's area from a GPS position, on the device. One file per prefecture.

| Prefecture | File | Areas | Size | Compressed (gzip) |
| -- | -- | -- | -- | -- |
| Kanagawa (14) | `14.json` | 5,090 in 58 municipalities and wards | 1.97 MB | 628 KB |

The CDN compresses the file in transit, so the compressed figure is what a phone downloads.

## Format

`data/schema/boundaries.v1.schema.json`. A small envelope around standard [TopoJSON](https://github.com/topojson/topojson-specification):

```json
{
  "schema_version": 1,
  "prefecture_code": "14",
  "version": 1,
  "generated_at": "2026-11-12T12:00:00+09:00",
  "attribution": [{ "text": { "ja": "…", "en": "…" }, "license": "…", "url": "…" }],
  "bbox": [138.915472, 35.128712, 139.796502, 35.673035],
  "municipalities": { "14117": { "ja": "横浜市青葉区" } },
  "topology": {
    "type": "Topology",
    "transform": { "scale": [], "translate": [] },
    "objects": { "areas": { "type": "GeometryCollection", "geometries": [
      { "type": "Polygon", "id": "14117-100001", "properties": { "name": "青葉台一丁目" }, "arcs": [[0, -5]] }
    ] } },
    "arcs": [[[367591, 395250], [-11471, -37176]]]
  }
}
```

* **`id`** of each area is the bundle's area ID: ward or municipality code, a hyphen, and e-Stat's 6-digit `S_AREA`. A lookup returns an ID a bundle already uses, with no mapping table.
* **`municipalities`** names the 5-digit code in front of the hyphen, so the app can say where the user is even when no bundle covers that place yet.
* **`bbox`** is west, south, east, north. The manifest repeats it, so the app can pick the right prefecture's package before it has any boundaries.
* **Coordinates** are longitude and latitude in JGD2000, which is within GPS error of WGS 84.
* **Arcs** are integers on a grid (about 0.1 m), each point stored as the step from the one before. A border between two areas is stored once and used by both, so neighbours meet exactly: there are no gaps or overlaps between them.

## Looking a position up

`data/scripts/locate.py` is the reference the app's Dart code should follow. It uses only arithmetic:

1. Decode each arc: running sum of the steps, times `scale`, plus `translate`.
2. Build each area's rings by joining its arcs; index `~i` (negative) means arc `i` walked backwards.
3. Skip areas whose bounding box is not near the point.
4. The point is inside an area when a ray from it crosses that area's rings an odd number of times. Counting every ring together handles holes and multi-part areas.
5. For DAI-569's "near a boundary" case, measure the distance to the edges of neighbouring areas and list those within 50 m.

```sh
uv run data/scripts/locate.py 35.568253 139.553345
```

```json
{
  "area": { "id": "14117-123002", "name": "あざみ野二丁目" },
  "border_m": 47.9,
  "nearby": [{ "id": "14117-123001", "name": "あざみ野一丁目", "distance_m": 47.9 }]
}
```

## Building

```sh
uv run data/scripts/build_boundaries.py 14            # Kanagawa; add --refresh to download again
uv run data/scripts/validate.py data/boundaries/14.json
uv run data/tests/test_boundaries.py
```

The build downloads the prefecture's 2020 census small-area boundaries from e-Stat, merges areas that come in several pieces, drops water-surface areas, simplifies borders with a tolerance of about 5.5 m, and writes the package. It then looks up 5,000 random points in the package and in the unsimplified polygons, and fails if any border moved more than 15 m. For Kanagawa, 17 of the 5,000 points changed area, the furthest 3.1 m from a border.

Merging a changed package to `main` publishes it to `/boundaries/<prefecture>/<version>.json` and lists it under `boundaries` in the manifest (see [Publishing](../README.md#publishing)). The publisher sets `version` and `generated_at`.

Any other prefecture builds the same way; only Kanagawa is committed because it is the only one with a bundle.

## Checks

* **22 known addresses** across Yokohama, Kawasaki, Kamakura, Odawara, Fujisawa, Yokosuka, Sagamihara and Hakone each land in the correct ward and town or chōme. Their coordinates come from the Geospatial Information Authority of Japan's address search, which is independent of the boundary data. They are in `data/tests/test_boundaries.py`.
* Every area in the Yokohama bundle is in the package under the same ID and name.

## Sources and licence

| Source | Used for | Terms |
| -- | -- | -- |
| e-Stat, 令和2年国勢調査 町丁・字等別境界データ (Statistics Bureau, Ministry of Internal Affairs and Communications) | All boundaries, area names and codes | [e-Stat terms of use](https://www.e-stat.go.jp/terms-of-use): free to copy, adapt and redistribute, including commercially, with the source credited and a note that the data was processed. Compatible with CC BY 4.0 |
| GSI address search (国土地理院) | Coordinates of the 22 test addresses only; not in the package | [GSI content terms](https://www.gsi.go.jp/kikakuchousei/kikakuchousei40182.html) |

The credit the app must show is in each package's `attribution`: 「政府統計の総合窓口(e-Stat)」の令和2年国勢調査 町丁・字等別境界データを加工して作成。

**MLIT's N03 administrative boundaries are not used.** The small areas tile each municipality completely and carry its code, so the municipality is simply the first five digits of the area found. That leaves one source and one licence instead of two, and no risk of the two datasets disagreeing along a border.

## Things to know

* Boundaries are as of the 2020 census. A town renumbered since then keeps its 2020 shape and code until the next census data is built.
* Two tiny unnamed slivers (`S_AREA` 000000) are kept with an empty name so the municipality is still found there.
* A position on open water or outside the prefecture is in no area.
