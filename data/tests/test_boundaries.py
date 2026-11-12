#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["jsonschema[format-nongpl]>=4.23", "pytest>=8"]
# ///
"""Tests for the boundary lookup and the committed Kanagawa package.

Usage:
    uv run data/tests/test_boundaries.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import locate
import validate

DATA_DIR = Path(__file__).resolve().parent.parent
KANAGAWA = DATA_DIR / "boundaries" / "14.json"

# Known addresses with the coordinates the Geospatial Information Authority of Japan's address search
# (msearch.gsi.go.jp) returned for them on 12 November 2026: (address, lat, lon, municipality, area name, area id).
# The geocoder is independent of the e-Stat boundaries the package is built from.
ADDRESSES = [
    ("横浜市青葉区市ケ尾町31-4", 35.553493, 139.536621, "横浜市青葉区", "市ケ尾町", "14117-088001"),
    ("横浜市青葉区青葉台一丁目7", 35.543270, 139.517105, "横浜市青葉区", "青葉台一丁目", "14117-100001"),
    ("横浜市青葉区あざみ野二丁目1", 35.568253, 139.553345, "横浜市青葉区", "あざみ野二丁目", "14117-123002"),
    ("横浜市青葉区美しが丘一丁目1", 35.578224, 139.559586, "横浜市青葉区", "美しが丘一丁目", "14117-071001"),
    ("横浜市青葉区藤が丘二丁目5", 35.543583, 139.527344, "横浜市青葉区", "藤が丘二丁目", "14117-090002"),
    ("横浜市青葉区奈良町700", 35.564674, 139.487976, "横浜市青葉区", "奈良町", "14117-104002"),
    ("横浜市青葉区鉄町1614", 35.567417, 139.521179, "横浜市青葉区", "鉄町", "14117-115000"),
    ("横浜市青葉区荏田西一丁目3", 35.555271, 139.548279, "横浜市青葉区", "荏田西一丁目", "14117-080001"),
    ("横浜市中区本町六丁目50", 35.450195, 139.634903, "横浜市中区", "本町六丁目", "14104-019006"),
    ("横浜市中区日本大通1", 35.447697, 139.642593, "横浜市中区", "日本大通", "14104-001000"),
    ("横浜市西区高島二丁目16", 35.465988, 139.623001, "横浜市西区", "高島二丁目", "14103-032002"),
    ("横浜市港北区篠原町2937", 35.506004, 139.616486, "横浜市港北区", "篠原町", "14109-008001"),
    ("横浜市都筑区茅ケ崎中央32", 35.544849, 139.570541, "横浜市都筑区", "茅ケ崎中央", "14118-030000"),
    ("川崎市川崎区駅前本町26", 35.530125, 139.697968, "川崎市川崎区", "駅前本町", "14131-101000"),
    ("川崎市中原区小杉町三丁目245", 35.575970, 139.656281, "川崎市中原区", "小杉町三丁目", "14133-301003"),
    ("鎌倉市長谷四丁目2", 35.316383, 139.535599, "鎌倉市", "長谷四丁目", "14204-039004"),
    ("鎌倉市雪ノ下二丁目1", 35.324554, 139.554749, "鎌倉市", "雪ノ下二丁目", "14204-006002"),
    ("小田原市城内6", 35.250816, 139.154068, "小田原市", "城内", "14206-016000"),
    ("藤沢市朝日町1", 35.339535, 139.491074, "藤沢市", "朝日町", "14205-001000"),
    ("横須賀市小川町11", 35.281387, 139.672134, "横須賀市", "小川町", "14201-009000"),
    ("相模原市中央区中央二丁目11", 35.571362, 139.373276, "相模原市中央区", "中央二丁目", "14152-012002"),
    ("足柄下郡箱根町湯本256", 35.231880, 139.105835, "箱根町", "湯本", "14382-011001"),
]


@pytest.fixture(scope="module")
def document():
    return json.loads(KANAGAWA.read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def kanagawa(document):
    return locate.Package(document)


def test_committed_package_is_valid(document):
    assert validate.validate_boundaries(document) == []


@pytest.mark.parametrize(("address", "lat", "lon", "municipality", "name", "area_id"), ADDRESSES)
def test_known_addresses_land_in_their_town(kanagawa, document, address, lat, lon, municipality, name, area_id):
    found = kanagawa.locate(lat, lon)["area"]
    assert found == {"id": area_id, "name": name}
    assert document["municipalities"][area_id.split("-")[0]]["ja"] == municipality


def test_package_has_every_area_of_the_yokohama_bundle(kanagawa):
    bundle = json.loads((DATA_DIR / "municipalities" / "14100" / "bundle.json").read_text(encoding="utf-8"))
    in_package = {a["id"]: a["name"] for a in kanagawa.areas}
    for area in bundle["areas"]:
        assert in_package.get(area["id"]) in (area["names"]["ja"], area["town"]["ja"]), area["id"]


def test_a_point_near_a_border_reports_the_neighbour(kanagawa):
    # あざみ野二丁目1 is 48 m from あざみ野一丁目.
    result = kanagawa.locate(35.568253, 139.553345, near=50)
    assert result["area"]["name"] == "あざみ野二丁目" and 40 < result["border_m"] < 55
    assert [n["name"] for n in result["nearby"]] == ["あざみ野一丁目"]
    assert kanagawa.locate(35.568253, 139.553345, near=20)["nearby"] == []


def test_a_point_outside_the_prefecture_is_in_no_area(kanagawa):
    tokyo_station = kanagawa.locate(35.681236, 139.767125)
    assert tokyo_station == {"area": None, "border_m": None, "nearby": []}


def square(scale: float = 0.001) -> dict:
    """Two unit squares side by side sharing the arc between them, and a third with a hole."""
    return {
        "topology": {
            "transform": {"scale": [scale, scale], "translate": [139.0, 35.0]},
            "arcs": [
                [[10, 0], [0, 10]],  # the shared edge, bottom to top
                [[10, 10], [-10, 0], [0, -10], [10, 0]],  # rest of the left square
                [[10, 0], [10, 0], [0, 10], [-10, 0]],  # rest of the right square
                [[30, 0], [30, 0], [0, 30], [-30, 0], [0, -30]],  # big square
                [[40, 10], [10, 0], [0, 10], [-10, 0], [0, -10]],  # its hole
            ],
            "objects": {
                "areas": {
                    "geometries": [
                        {"type": "Polygon", "id": "99999-000001", "properties": {"name": "left"}, "arcs": [[0, 1]]},
                        {"type": "Polygon", "id": "99999-000002", "properties": {"name": "right"}, "arcs": [[2, -1]]},
                        {
                            "type": "MultiPolygon",
                            "id": "99999-000003",
                            "properties": {"name": "ring"},
                            "arcs": [[[3], [4]]],
                        },
                    ]
                }
            },
        }
    }


def test_shared_arcs_holes_and_reversed_arcs():
    package = locate.Package(square())

    def at(x: float, y: float) -> str | None:
        return (package.locate(35.0 + y * 0.001, 139.0 + x * 0.001, near=0)["area"] or {}).get("name")

    assert at(5, 5) == "left"
    assert at(15, 5) == "right"
    assert at(35, 5) == "ring"
    assert at(45, 15) is None  # inside the hole
    assert at(25, 5) is None  # the gap between the squares and the ring

    near = package.locate(35.005, 139.0099, near=50)
    assert near["area"]["name"] == "left" and near["nearby"][0]["name"] == "right"
    assert near["nearby"][0]["distance_m"] == pytest.approx(near["border_m"], abs=0.2) and near["border_m"] < 12


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q", *sys.argv[1:]]))
