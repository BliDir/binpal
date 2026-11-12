#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["httpx>=0.27", "pyshp>=2.3", "shapely>=2.0", "topojson>=1.9"]
# ///
"""Build a prefecture's boundary package from e-Stat small-area boundary data.

Usage:
    uv run data/scripts/build_boundaries.py PREFECTURE [--refresh] [--tolerance DEGREES]

Downloads the 2020 census small-area boundaries (町丁・字等別境界データ) for the
prefecture into data/.cache/boundaries/, merges the parts of each area,
simplifies the shared borders once so neighbours still meet exactly, and
writes data/boundaries/<prefecture>.json as TopoJSON inside a small envelope.

Area IDs are municipality or ward code + "-" + S_AREA, the same as in bundles.
Water-surface areas (HCODE 8154) are left out.

After writing, the package is read back with locate.py and compared with the
unsimplified polygons at random points; the build fails if simplification
moved a border by more than a few metres.
"""

from __future__ import annotations

import argparse
import io
import json
import random
import sys
import zipfile
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import httpx
import shapefile
import topojson
from shapely import STRtree, make_valid
from shapely.geometry import Point, shape
from shapely.ops import unary_union

sys.path.insert(0, str(Path(__file__).resolve().parent))
import locate

DATA_DIR = Path(__file__).resolve().parent.parent
CACHE_DIR = DATA_DIR / ".cache" / "boundaries"
OUT_DIR = DATA_DIR / "boundaries"
USER_AGENT = "BinPalDataBuild/1.0 (+https://github.com/BliDir/binpal)"
ESTAT_URL = (
    "https://www.e-stat.go.jp/gis/statmap-search/data"
    "?dlserveyId=A002005212020&code={prefecture}&coordSys=1&format=shape&downloadType=5"
)
LAND = 8101  # HCODE of ordinary areas; 8154 is water surface
# About 5.5 m. Borders mostly follow roads and rivers, so this is well inside GPS error.
TOLERANCE_DEGREES = 0.00005
QUANTIZATION = 1e6  # grid steps across the prefecture: about 0.1 m
CHECK_POINTS = 5000
MAX_SHIFT_METRES = 15.0  # a border may not move further than this
ATTRIBUTION = [
    {
        "text": {
            "ja": "「政府統計の総合窓口(e-Stat)」の令和2年国勢調査 町丁・字等別境界データを加工して作成。",
            "en": "Derived from the 2020 Population Census small-area boundary data on e-Stat, "
            "the portal site of official statistics of Japan.",
        },
        "license": "LicenseRef-e-Stat-Terms-of-Use",
        "url": "https://www.e-stat.go.jp/terms-of-use",
    }
]


class BuildError(Exception):
    pass


def download(prefecture: str, refresh: bool) -> Path:
    path = CACHE_DIR / f"{prefecture}.zip"
    if refresh or not path.exists():
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        url = ESTAT_URL.format(prefecture=prefecture)
        print(f"fetch {url}")
        response = httpx.get(url, headers={"User-Agent": USER_AGENT}, timeout=120, follow_redirects=True)
        response.raise_for_status()
        path.write_bytes(response.content)
    return path


def read_areas(archive: Path, prefecture: str) -> tuple[dict, dict, dict]:
    """Polygons by area id, area names by id, and municipality names by code."""
    with zipfile.ZipFile(archive) as z:
        parts = {name.rsplit(".", 1)[1]: io.BytesIO(z.read(name)) for name in z.namelist() if "." in name}
    reader = shapefile.Reader(shp=parts["shp"], shx=parts["shx"], dbf=parts["dbf"], encoding="cp932")
    pieces, names, municipalities = {}, {}, {}
    for item in reader.shapeRecords():
        record = item.record
        if record["PREF"] != prefecture:
            raise BuildError(f"record for prefecture {record['PREF']} in the {prefecture} download")
        if record["HCODE"] != LAND:
            continue
        code = record["PREF"] + record["CITY"]
        area_id = f"{code}-{record['S_AREA']}"
        pieces.setdefault(area_id, []).append(make_valid(shape(item.shape.__geo_interface__)))
        names[area_id] = record["S_NAME"]
        municipalities[code] = record["CITY_NAME"]
    if not pieces:
        raise BuildError("no areas in the download")
    return {i: unary_union(p) for i, p in pieces.items()}, names, municipalities


def simplify(polygons: dict, names: dict, tolerance: float) -> dict:
    """TopoJSON of the areas: shared borders are stored, and simplified, once."""
    ids = sorted(polygons)
    topology = topojson.Topology([polygons[i] for i in ids], prequantize=QUANTIZATION, topology=True)
    result = topology.toposimplify(tolerance, prevent_oversimplify=True).to_dict()
    geometries = result["objects"].pop("data")["geometries"]
    if len(geometries) != len(ids):
        raise BuildError("simplification dropped an area")
    for area_id, geometry in zip(ids, geometries, strict=True):
        if geometry.get("type") not in ("Polygon", "MultiPolygon"):
            raise BuildError(f"{area_id}: simplified to {geometry.get('type')}")
        geometry["id"] = area_id
        geometry["properties"] = {"name": names[area_id]}
    return {
        "type": "Topology",
        "transform": {k: [float(v) for v in result["transform"][k]] for k in ("scale", "translate")},
        "objects": {"areas": {"type": "GeometryCollection", "geometries": geometries}},
        "arcs": result["arcs"],
    }


def check(document: dict, polygons: dict) -> str:
    """Compare lookups in the package with the original polygons at random points."""
    package = locate.Package(document)
    ids = sorted(polygons)
    originals = [polygons[i] for i in ids]
    tree = STRtree(originals)
    west, south, east, north = document["bbox"]
    rng = random.Random(561)
    tested = wrong = 0
    worst = 0.0
    while tested < CHECK_POINTS:
        lon, lat = rng.uniform(west, east), rng.uniform(south, north)
        point = Point(lon, lat)
        truth = [ids[i] for i in tree.query(point, predicate="intersects")]
        if not truth:
            continue  # sea, or another prefecture
        tested += 1
        found = package.locate(lat, lon, near=0)["area"]
        if found and found["id"] in truth:
            continue
        wrong += 1
        # How far the point is from the border it was on the wrong side of.
        degrees = originals[ids.index(truth[0])].boundary.distance(point)
        worst = max(worst, degrees * locate.METRES_PER_DEGREE)
    if worst > MAX_SHIFT_METRES:
        raise BuildError(f"simplification moved a border by {worst:.1f} m (limit {MAX_SHIFT_METRES} m)")
    return f"{wrong} of {tested} random points changed area, the furthest {worst:.1f} m from a border"


def build(prefecture: str, archive: Path, tolerance: float, generated_at: str) -> tuple[dict, str]:
    polygons, names, municipalities = read_areas(archive, prefecture)
    topology = simplify(polygons, names, tolerance)
    bounds = unary_union([p.envelope for p in polygons.values()]).bounds
    document = {
        "schema_version": 1,
        "prefecture_code": prefecture,
        "version": 1,
        "generated_at": generated_at,
        "attribution": ATTRIBUTION,
        "bbox": [round(v, 6) for v in bounds],
        "municipalities": {code: {"ja": name} for code, name in sorted(municipalities.items())},
        "topology": topology,
    }
    return document, check(document, polygons)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("prefecture", help="2-digit prefecture code, for example 14 for Kanagawa")
    parser.add_argument("--refresh", action="store_true", help="download the source again")
    parser.add_argument("--tolerance", type=float, default=TOLERANCE_DEGREES)
    parser.add_argument("--generated-at", help="RFC 3339 timestamp for the package (default: now)")
    args = parser.parse_args()

    generated_at = args.generated_at or datetime.now(ZoneInfo("Asia/Tokyo")).replace(microsecond=0).isoformat()
    try:
        document, report = build(args.prefecture, download(args.prefecture, args.refresh), args.tolerance, generated_at)
    except BuildError as e:
        print(f"FAIL {e}")
        return 1
    out = OUT_DIR / f"{args.prefecture}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(document, ensure_ascii=False, separators=(",", ":"))
    out.write_text(data + "\n", encoding="utf-8")
    areas = document["topology"]["objects"]["areas"]["geometries"]
    points = sum(len(arc) for arc in document["topology"]["arcs"])
    print(
        f"wrote {out.relative_to(DATA_DIR.parent)}: {len(areas)} areas in {len(document['municipalities'])} "
        f"municipalities, {points:,} points, {len(data.encode()):,} bytes"
    )
    print(f"check: {report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
