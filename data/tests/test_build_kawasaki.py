#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "beautifulsoup4>=4.12", "httpx>=0.27", "jsonschema[format-nongpl]>=4.23", "pypdf>=5", "pytest>=8", "pyyaml>=6",
# ]
# ///
"""Tests for the Kawasaki bundle build, against fixture pages written for these tests.

The fixtures have the shape of the city's pages but made-up towns' days, so no
city content is copied (Kawasaki's site policy, DAI-589).

Usage:
    uv run data/tests/test_build_kawasaki.py
"""

from __future__ import annotations

import copy
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import build_kawasaki as build
import validate

PAGE_URL = "https://city.example/takatsu-miyamae.html"
ITEMS_URL = "https://city.example/items.html"
HEADER = "<tr><th></th><th>町名</th><th>普通ごみ</th><th>空き缶<br>ペットボトル<br>空きびん<br>使用済み乾電池</th><th>ミックスペーパー</th><th>プラスチック資源</th><th>粗大ごみ<br>小物金属</th></tr>"


def schedule_page(takatsu_rows=None, updated="2026年4月1日") -> bytes:
    takatsu_rows = takatsu_rows or [
        ("か", "梶ヶ谷", "火曜・金曜", "水曜", "月曜", "木曜", "第1・3回目　月曜"),
        ("す", "末長", "月曜・木曜", "金曜", "火曜", "土曜", "第2・4回目　水曜"),
    ]

    def table(rows):
        body = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in row) + "</tr>" for row in rows)
        return f"<table>{HEADER}{body}</table>"

    return f"""<html><body><div id="mol_contents"><p>更新日：{updated}</p>
<h2>高津区</h2>{table(takatsu_rows)}
<h2>宮前区</h2>{table([("か", "梶ヶ谷", "水曜・土曜", "火曜", "木曜", "月曜", "第1・3回目 金曜")])}
</div></body></html>""".encode()


def item_page(rows=None) -> bytes:
    rows = rows or [
        ("アイロン", "小物金属", ""),
        ("アイロン台", "小物金属または粗大ごみ", "最長辺が30cm以上なら粗大ごみ"),
        ("油（食用）", "普通ごみ", "布にしみこませる"),
    ]
    body = "".join(f"<tr><td>{a}</td><td>{b}</td><td>{c}</td></tr>" for a, b, c in rows)
    return f"<html><body><table><tr><th>あ品目</th><th>分別区分</th><th>出し方のポイント</th></tr>{body}</table></body></html>".encode()


AREAS = [
    {"ward": "14134", "s_area": "415001", "ja": "梶ケ谷一丁目", "town": "梶ケ谷", "chome": "1"},
    {"ward": "14134", "s_area": "415002", "ja": "梶ケ谷二丁目", "town": "梶ケ谷", "chome": "2"},
    {"ward": "14134", "s_area": "416001", "ja": "末長一丁目", "town": "末長", "chome": "1"},
    {"ward": "14136", "s_area": "509000", "ja": "梶ケ谷", "town": "梶ケ谷", "chome": ""},
]
TOWNS = [
    {"ward": "14134", "ja": "梶ケ谷", "kana": "かじがや", "en": "Kajigaya", "postal_codes": "2130015"},
    {"ward": "14134", "ja": "末長", "kana": "すえなが", "en": "Suenaga", "postal_codes": "2130013"},
    {"ward": "14136", "ja": "梶ケ谷", "kana": "かじがや", "en": "Kajigaya", "postal_codes": "2160034"},
]
TRANSLATIONS = [
    {"ja": "アイロン", "kana": "あいろん", "en": "Clothes iron", "aliases": "iron"},
    {"ja": "アイロン台", "kana": "あいろんだい", "en": "Ironing board", "aliases": ""},
    {"ja": "油(食用)", "kana": "あぶら", "en": "Cooking oil", "aliases": "oil"},
]
NOTES = [
    {"ja": "最長辺が30cm以上なら粗大ごみ", "en": "Bulky waste if 30 cm or longer."},
    {"ja": "布にしみこませる", "en": "Soak it up with cloth."},
]


@pytest.fixture
def config():
    real, *_ = build.load_inputs()
    config = copy.deepcopy(real)
    config["wards"][0]["page"] = PAGE_URL
    config["items"]["page_url"] = ITEMS_URL
    config["items"]["verified_at"] = "2026-11-15"
    return config


def make(config, page=None, items=None, translations=TRANSLATIONS, notes=NOTES) -> dict:
    sources = {PAGE_URL: page or schedule_page(), ITEMS_URL: items or item_page()}
    return build.build(config, AREAS, TOWNS, translations, notes, sources, "2026-11-15T09:00:00+09:00")


@pytest.mark.parametrize(
    ("cell", "pattern"),
    [
        ("火曜・金曜", {"type": "weekly", "weekdays": ["tue", "fri"]}),
        ("水曜", {"type": "weekly", "weekdays": ["wed"]}),
        ("第1・3回目　月曜", {"type": "monthly_nth_weekday", "weekday": "mon", "nth": [1, 3]}),
        ("第2・4回目 金曜", {"type": "monthly_nth_weekday", "weekday": "fri", "nth": [2, 4]}),
    ],
)
def test_cells_become_patterns(cell, pattern):
    assert build.parse_cell(cell) == pattern


@pytest.mark.parametrize("cell", ["", "なし", "隔週水曜", "第1週 月曜"])
def test_unexpected_cells_stop_the_build(cell):
    with pytest.raises(build.BuildError):
        build.parse_cell(cell)


def test_fixture_build_is_a_valid_bundle(config):
    bundle = make(config)
    assert validate.validate_bundle(bundle) == []


def test_kajigaya_in_takatsu_gets_its_days_and_postal_code(config):
    bundle = make(config)
    kajigaya = [a for a in bundle["areas"] if a["town"]["ja"] == "梶ケ谷"]
    # Only Takatsu-ku is built so far; Miyamae-ku's 梶ケ谷 is not in the bundle.
    assert [a["id"] for a in kajigaya] == ["14134-415001", "14134-415002"]
    assert kajigaya[0]["names"] == {"ja": "梶ケ谷一丁目", "kana": "かじがやいっちょうめ", "en": "Kajigaya 1-chome"}
    assert kajigaya[0]["postal_codes"] == ["2130015"]
    by_id = {c["id"]: c for c in bundle["calendars"]}
    assert by_id["takatsu-kajigaya-futsu"]["pattern"] == {"type": "weekly", "weekdays": ["tue", "fri"]}
    assert by_id["takatsu-kajigaya-kan-bin"]["categories"] == ["kan-pet", "bin", "denchi"]
    assert by_id["takatsu-kajigaya-komono"]["pattern"] == {
        "type": "monthly_nth_weekday",
        "weekday": "mon",
        "nth": [1, 3],
    }
    assert by_id["takatsu-kajigaya-futsu"]["area_ids"] == ["14134-415001", "14134-415002"]
    assert by_id["takatsu-kajigaya-futsu"]["valid_from"] == "2026-04-01"


def test_bulky_waste_has_no_calendar(config):
    bundle = make(config)
    assert not any("sodai" in c["categories"] for c in bundle["calendars"])
    assert "sodai" in {c["id"] for c in bundle["categories"]}


def test_new_year_closes_the_first_three_days(config):
    bundle = make(config)
    assert [e["date"] for e in bundle["exceptions"]] == [
        "2027-01-01",
        "2027-01-02",
        "2027-01-03",
        "2028-01-01",
        "2028-01-02",
        "2028-01-03",
    ]
    assert all(e["type"] == "no_collection" and "categories" not in e for e in bundle["exceptions"])


def test_an_area_with_no_row_stops_the_build(config):
    page = schedule_page([("か", "梶ヶ谷", "火曜・金曜", "水曜", "月曜", "木曜", "第1・3回目 月曜")])
    with pytest.raises(build.BuildError, match="no collection days for .*416001 末長一丁目"):
        make(config, page=page)


def test_a_row_for_an_unknown_town_stops_the_build(config):
    rows = [
        ("か", "梶ヶ谷", "火曜・金曜", "水曜", "月曜", "木曜", "第1・3回目 月曜"),
        ("す", "末長", "月曜・木曜", "金曜", "火曜", "土曜", "第2・4回目 水曜"),
        ("た", "架空町", "月曜・木曜", "金曜", "火曜", "土曜", "第2・4回目 水曜"),
    ]
    with pytest.raises(build.BuildError, match="架空町: no area"):
        make(config, page=schedule_page(rows))


def test_a_changed_table_stops_the_build(config):
    page = schedule_page().replace("ミックスペーパー".encode(), "古紙".encode())
    with pytest.raises(build.BuildError, match="unexpected table header"):
        make(config, page=page)


def test_items_take_their_category_lead_and_note(config):
    rules = {r["names"]["en"]: r for r in make(config)["rules"]}
    board = rules["Ironing board"]
    assert board["category"] == "komono"
    assert board["instructions"]["ja"].startswith("一番長い辺が30cm未満なら小物金属")
    assert board["instructions"]["en"].endswith("Bulky waste if 30 cm or longer.")
    assert rules["Clothes iron"]["instructions"]["en"] == "Put out as Small metal items."
    assert rules["Clothes iron"]["aliases"] == ["iron"]
    assert rules["Clothes iron"]["item_id"] == build.item_id("アイロン")
    assert rules["Clothes iron"]["verified_at"] == "2026-11-15"


def test_untranslated_or_unmapped_items_are_listed(config):
    items = item_page([("アイロン", "小物金属", ""), ("鍋", "鍋の日", ""), ("新品", "普通ごみ", "新しい注意書き")])
    with pytest.raises(build.BuildError) as e:
        make(config, items=items)
    message = str(e.value)
    assert "鍋: add 分別区分 '鍋の日' to methods" in message
    assert "鍋: add it to items.tsv" in message
    assert "新品: add the note '新しい注意書き' to notes.tsv" in message


def test_nothing_is_written_until_reuse_is_confirmed():
    config, *_ = build.load_inputs()
    assert config["reuse_confirmed"] is False
    assert not (build.MUNICIPALITY_DIR / "bundle.json").exists()


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))
