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

### Aoba-ku, checked against the published package

Checked on 12 November 2026 against the file the CDN serves, `https://data.blidir.fun/boundaries/14/1.json` (1,973,976 bytes; about 658 KB as downloaded with compression; SHA-256 `24a610f7…f148d4`, matching the manifest).

* The package has exactly the 85 Aoba-ku areas of the Yokohama bundle, with the same IDs and names.
* 45 addresses, in 45 different areas and 36 of the ward's 45 towns, each resolve to the correct town and chōme. All are in 横浜市青葉区 (code 14117). "To border" is how far the point is from the edge of its area.

| Address | Latitude, longitude (GSI) | Area found | Area ID | To border | Correct |
| -- | -- | -- | -- | -- | -- |
| 青葉区市ケ尾町31-4 | 35.553493, 139.536621 | 市ケ尾町 | `14117-088001` | 167 m | ✓ |
| 青葉区青葉台一丁目7 | 35.543270, 139.517105 | 青葉台一丁目 | `14117-100001` | 60 m | ✓ |
| 青葉区あざみ野二丁目1 | 35.568253, 139.553345 | あざみ野二丁目 | `14117-123002` | 48 m | ✓ |
| 青葉区美しが丘一丁目1 | 35.578224, 139.559586 | 美しが丘一丁目 | `14117-071001` | 24 m | ✓ |
| 青葉区藤が丘二丁目5 | 35.543583, 139.527344 | 藤が丘二丁目 | `14117-090002` | 79 m | ✓ |
| 青葉区奈良町700 | 35.564674, 139.487976 | 奈良町 | `14117-104002` | 20 m | ✓ |
| 青葉区鉄町1614 | 35.567417, 139.521179 | 鉄町 | `14117-115000` | 350 m | ✓ |
| 青葉区荏田西一丁目3 | 35.555271, 139.548279 | 荏田西一丁目 | `14117-080001` | 112 m | ✓ |
| 青葉区青葉台二丁目1 | 35.542065, 139.515961 | 青葉台二丁目 | `14117-100002` | 43 m | ✓ |
| 青葉区桂台一丁目1 | 35.548618, 139.508286 | 桂台一丁目 | `14117-068001` | 34 m | ✓ |
| 青葉区桂台二丁目1 | 35.547371, 139.503021 | 桂台二丁目 | `14117-068002` | 52 m | ✓ |
| 青葉区美しが丘二丁目1 | 35.578423, 139.560272 | 美しが丘二丁目 | `14117-071002` | 42 m | ✓ |
| 青葉区美しが丘五丁目1 | 35.578064, 139.553833 | 美しが丘五丁目 | `14117-071005` | 25 m | ✓ |
| 青葉区美しが丘西一丁目1 | 35.587925, 139.541397 | 美しが丘西一丁目 | `14117-144001` | 34 m | ✓ |
| 青葉区荏田北一丁目1 | 35.559006, 139.550888 | 荏田北一丁目 | `14117-077001` | 21 m | ✓ |
| 青葉区荏子田二丁目1 | 35.578720, 139.537506 | 荏子田二丁目 | `14117-085002` | 27 m | ✓ |
| 青葉区あざみ野一丁目1 | 35.569466, 139.553375 | あざみ野一丁目 | `14117-123001` | 50 m | ✓ |
| 青葉区あざみ野南二丁目1 | 35.562141, 139.552521 | あざみ野南二丁目 | `14117-147002` | 46 m | ✓ |
| 青葉区新石川一丁目1 | 35.566254, 139.554153 | 新石川一丁目 | `14117-128001` | 31 m | ✓ |
| 青葉区新石川三丁目1 | 35.577030, 139.559097 | 新石川三丁目 | `14117-128003` | 40 m | ✓ |
| 青葉区すすき野二丁目1 | 35.574314, 139.528625 | すすき野二丁目 | `14117-120002` | 25 m | ✓ |
| 青葉区たちばな台一丁目1 | 35.553341, 139.515167 | たちばな台一丁目 | `14117-111001` | 50 m | ✓ |
| 青葉区藤が丘一丁目1 | 35.549046, 139.533264 | 藤が丘一丁目 | `14117-090001` | 42 m | ✓ |
| 青葉区あかね台二丁目1 | 35.539455, 139.488251 | あかね台二丁目 | `14117-142002` | 27 m | ✓ |
| 青葉区奈良一丁目1 | 35.557789, 139.485779 | 奈良一丁目 | `14117-149001` | 33 m | ✓ |
| 青葉区奈良四丁目1 | 35.558041, 139.481735 | 奈良四丁目 | `14117-149004` | 103 m | ✓ |
| 青葉区桜台1 | 35.550430, 139.519226 | 桜台 | `14117-099000` | 26 m | ✓ |
| 青葉区もえぎ野1 | 35.545010, 139.524963 | もえぎ野 | `14117-107000` | 35 m | ✓ |
| 青葉区榎が丘1 | 35.541214, 139.516006 | 榎が丘 | `14117-097000` | 47 m | ✓ |
| 青葉区松風台1 | 35.543671, 139.510559 | 松風台 | `14117-098000` | 86 m | ✓ |
| 青葉区つつじが丘1 | 35.542110, 139.520279 | つつじが丘 | `14117-094000` | 31 m | ✓ |
| 青葉区しらとり台1 | 35.539627, 139.516495 | しらとり台 | `14117-095000` | 18 m | ✓ |
| 青葉区千草台1 | 35.542133, 139.531738 | 千草台 | `14117-093000` | 15 m | ✓ |
| 青葉区若草台1 | 35.551975, 139.506989 | 若草台 | `14117-102000` | 40 m | ✓ |
| 青葉区みたけ台1 | 35.551716, 139.522217 | みたけ台 | `14117-109000` | 33 m | ✓ |
| 青葉区柿の木台1 | 35.547234, 139.526398 | 柿の木台 | `14117-108000` | 50 m | ✓ |
| 青葉区梅が丘1 | 35.538673, 139.523148 | 梅が丘 | `14117-092000` | 34 m | ✓ |
| 青葉区さつきが丘1 | 35.534779, 139.520676 | さつきが丘 | `14117-118000` | 44 m | ✓ |
| 青葉区すみよし台1 | 35.549744, 139.491196 | すみよし台 | `14117-127000` | 17 m | ✓ |
| 青葉区もみの木台1 | 35.571091, 139.530029 | もみの木台 | `14117-119000` | 22 m | ✓ |
| 青葉区田奈町50 | 35.539795, 139.500092 | 田奈町 | `14117-103000` | 60 m | ✓ |
| 青葉区黒須田1 | 35.564014, 139.532425 | 黒須田 | `14117-141100` | 18 m | ✓ |
| 青葉区緑山2100 | 35.568390, 139.483948 | 緑山 | `14117-105000` | 124 m | ✓ |
| 青葉区下谷本町50 | 35.549496, 139.536514 | 下谷本町 | `14117-089000` | 103 m | ✓ |
| 青葉区荏田西三丁目1 | 35.550934, 139.547592 | 荏田西三丁目 | `14117-080003` | 3 m | ✓ |

For the ward's other nine towns (恩田町, 鴨志田町, 寺家町, 大場町, 元石川町, 上谷本町, 荏田町, 成合町, みすずが丘) the geocoder returns only a town-level point, so they are not counted as addresses. Each of those points also falls in the right town.

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
