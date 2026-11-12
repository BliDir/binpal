#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "beautifulsoup4>=4.12", "httpx>=0.27", "jsonschema[format-nongpl]>=4.23", "pypdf>=5", "pytest>=8", "pyyaml>=6",
# ]
# ///
"""Tests for the Yokohama bundle build, against small fixture pages, and for the committed bundle.

Usage:
    uv run data/tests/test_build_yokohama.py
"""

from __future__ import annotations

import copy
import csv
import io
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import build_yokohama as build
import validate

NOTES = "燃えないごみ、スプレー缶、電池類は「燃やすごみ」と同じ日に収集します。小さな金属類は「缶・びん・ペットボトル」と同じ日に収集します。"
PAGE_URL = "https://city.example/aoba/a.html"
NEW_YEAR_URL = "https://city.example/nenmatsunenshi.html"

ROWS = [
    (
        "あ",
        "青葉台1・2丁目",
        ["なし", "燃やすごみ", "プラスチック資源", "なし", "缶・びん・ペットボトル", "燃やすごみ"],
    ),
    (
        "",
        "あざみ野南1～3丁目",
        ["燃やすごみ", "缶・びん・ペットボトル", "なし", "なし", "燃やすごみ", "プラスチック資源"],
    ),
    ("く", "黒須田町", ["燃やすごみ", "プラスチック資源", "なし", "缶・びん・ペットボトル", "燃やすごみ", "なし"]),
]


def schedule_page(
    rows=ROWS, notes=NOTES, time="収集日の朝８時までに出してください。", updated="2026年1月23日"
) -> bytes:
    body = "".join(
        f"<tr><td>{kana}</td><td>{town}</td>{''.join(f'<td>{c}</td>' for c in cells)}</tr>"
        for kana, town, cells in rows
    )
    return f"""<html><body><p>最終更新日 {updated}</p>
<table><tr><th>五十音</th><th>町名</th><th>月曜日</th><th>火曜日</th><th>水曜日</th><th>木曜日</th><th>金曜日</th><th>土曜日</th></tr>
{body}</table><ul><li>{notes}</li><li>{time}</li></ul></body></html>""".encode()


def new_year_page(last="令和9年1月3日(日)") -> bytes:
    return f"""<html><body><p>令和8年12月31日（木）から{last}まで、資源とごみの収集をお休みさせていただきます。</p>
<table><tr><td>12月30日（水）</td><td>通常の曜日どおり収集します</td></tr>
<tr><td>12月31日（木）</td><td>収集はお休みです</td></tr><tr><td>1月1日（金）</td><td>収集はお休みです</td></tr>
<tr><td>1月2日（土）</td><td>収集はお休みです</td></tr><tr><td>1月3日（日）</td><td>収集はお休みです</td></tr>
<tr><td>1月4日（月）</td><td>通常の曜日どおり収集します</td></tr></table></body></html>""".encode()


def items_csv(rows) -> bytes:
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["ID", "頭文字", "品目名", "小型家電回収対象", "出し方", "出し方のポイント"])
    writer.writerows(rows)
    return out.getvalue().encode("cp932")


CSV_ROWS = [
    ("1", "あ", "アイスピック", "", "小さな金属類", "尖った部分は新聞紙等で包む"),
    ("2", "あ", "アイロン(プラスチック製)", "◎", "燃やすごみ", ""),
    ("3", "し", "新聞", "", "古紙（新聞）", "折込ちらしも一緒に"),
    (
        "4",
        "あ",
        "足拭きマット",
        "",
        "燃やすごみ",
        '50cm以上は粗大ごみへ。\r\n詳しくは<a href="https://city.example/">市ホームページ</a>へ。',
    ),
]
ITEMS = [
    {"id": "1", "ja": "アイスピック", "kana": "あいすぴっく", "en": "Ice pick", "aliases": ""},
    {
        "id": "2",
        "ja": "アイロン(プラスチック製)",
        "kana": "あいろん ぷらすちっくせい",
        "en": "Clothes iron (plastic)",
        "aliases": "iron; flat iron",
    },
    {"id": "3", "ja": "新聞", "kana": "しんぶん", "en": "Newspaper", "aliases": ""},
    {"id": "4", "ja": "足拭きマット", "kana": "あしふきまっと", "en": "Bath mat", "aliases": ""},
]
NOTE_ROWS = [
    {"ja": "尖った部分は新聞紙等で包む", "en": "Wrap sharp parts in newspaper or similar."},
    {"ja": "折込ちらしも一緒に", "en": "Put out together with newspaper inserts."},
    {
        "ja": "50cm以上は粗大ごみへ。詳しくは市ホームページへ。",
        "en": "Items 50 cm or longer are Bulky waste. See the city website.",
    },
]
AREAS = [
    {"ward": "14117", "s_area": "100001", "ja": "青葉台一丁目", "town": "青葉台", "chome": "1"},
    {"ward": "14117", "s_area": "100002", "ja": "青葉台二丁目", "town": "青葉台", "chome": "2"},
    {"ward": "14117", "s_area": "147001", "ja": "あざみ野南一丁目", "town": "あざみ野南", "chome": "1"},
    {"ward": "14117", "s_area": "147002", "ja": "あざみ野南二丁目", "town": "あざみ野南", "chome": "2"},
    {"ward": "14117", "s_area": "147003", "ja": "あざみ野南三丁目", "town": "あざみ野南", "chome": "3"},
    {"ward": "14117", "s_area": "141100", "ja": "黒須田", "town": "黒須田", "chome": ""},
]
TOWNS = [
    {"ward": "14117", "ja": "青葉台", "kana": "あおばだい", "en": "Aobadai"},
    {"ward": "14117", "ja": "あざみ野南", "kana": "あざみのみなみ", "en": "Azaminominami"},
    {"ward": "14117", "ja": "黒須田", "kana": "くろすだ", "en": "Kurosuda"},
]


@pytest.fixture(scope="module")
def real():
    return build.load_inputs()


@pytest.fixture
def config(real):
    config = copy.deepcopy(real[0])
    config["wards"][0]["pages"] = [PAGE_URL]
    config["exceptions"]["new_year"]["url"] = NEW_YEAR_URL
    return config


def sources(**overrides) -> dict:
    base = {
        PAGE_URL: schedule_page(),
        NEW_YEAR_URL: new_year_page(),
        "items.csv": items_csv(CSV_ROWS),
        "items.csv.url": "https://city.example/dashikata.files/0141_20260209.csv",
    }
    return base | overrides


def make(config, **overrides) -> dict:
    return build.build(config, AREAS, TOWNS, ITEMS, NOTE_ROWS, sources(**overrides), "2026-11-12T09:00:00+09:00")


def test_fixture_build_is_a_valid_bundle(config):
    bundle = make(config)
    assert validate.validate_bundle(bundle) == []
    assert json.loads(build.dump_bundle(bundle)) == bundle


def test_rows_become_areas_and_one_calendar_per_group(config):
    bundle = make(config)
    assert [a["id"] for a in bundle["areas"]] == [
        "14117-100001",
        "14117-100002",
        "14117-141100",
        "14117-147001",
        "14117-147002",
        "14117-147003",
    ]
    first = bundle["areas"][0]
    assert first["names"] == {"ja": "青葉台一丁目", "kana": "あおばだいいっちょうめ", "en": "Aobadai 1-chome"}
    assert first["town"]["ja"] == "青葉台" and first["chome"] == 1
    assert "chome" not in bundle["areas"][2] and bundle["areas"][2]["names"]["ja"] == "黒須田"

    calendars = {c["id"]: c for c in bundle["calendars"]}
    assert len(calendars) == 9
    burnable = calendars["aoba-aobadai-1-2-moyasu"]
    assert burnable["categories"] == ["moyasu", "moenai", "spray", "denchi"]
    assert burnable["area_ids"] == ["14117-100001", "14117-100002"]
    assert burnable["pattern"] == {"type": "weekly", "weekdays": ["tue", "sat"]}
    assert burnable["put_out_by"] == "08:00" and burnable["valid_from"] == "2026-01-23"
    assert burnable["source_url"] == PAGE_URL
    assert calendars["aoba-aobadai-1-2-kan-bin-pet"]["categories"] == ["kan-bin-pet", "kinzoku"]
    assert calendars["aoba-azaminominami-1-2-3-plastic"]["pattern"]["weekdays"] == ["sat"]
    assert calendars["aoba-kurosuda-moyasu"]["area_ids"] == ["14117-141100"]


@pytest.mark.parametrize(
    ("label", "expected"),
    [
        ("青葉台1・2丁目", ("青葉台", [1, 2])),
        ("あざみ野南1~4丁目", ("あざみ野南", [1, 2, 3, 4])),
        ("あざみ野1・4丁目", ("あざみ野", [1, 4])),
        ("あざみ野3丁目", ("あざみ野", [3])),
        ("恩田町", ("恩田町", None)),
    ],
)
def test_row_labels(label, expected):
    assert build.split_row_label(label) == expected


def test_an_area_missing_from_the_pages_stops_the_build(config):
    with pytest.raises(build.BuildError, match="no collection days found for .*黒須田"):
        make(config, **{PAGE_URL: schedule_page(ROWS[:2])})


def test_a_row_with_no_matching_area_stops_the_build(config):
    rows = [*ROWS, ("", "あざみ野南4丁目", ROWS[1][2])]
    with pytest.raises(build.BuildError, match=r"no area for chome \[4\]"):
        make(config, **{PAGE_URL: schedule_page(rows)})


def test_a_town_reading_that_disagrees_with_the_page_stops_the_build(config):
    rows = [ROWS[0], ROWS[1], ("こ", "黒須田町", ROWS[2][2])]
    with pytest.raises(build.BuildError, match="is not under 'こ'"):
        make(config, **{PAGE_URL: schedule_page(rows)})


@pytest.mark.parametrize(
    ("page", "message"),
    [
        (
            schedule_page(notes="小さな金属類は「缶・びん・ペットボトル」と同じ日に収集します。"),
            "go out with 燃やすごみ",
        ),
        (schedule_page(time=""), "what time"),
        (schedule_page([("あ", "青葉台1・2丁目", ["古紙", *ROWS[0][2][1:]])]), "unknown collection '古紙'"),
        (
            schedule_page([("あ", "青葉台1・2丁目", ["なし", "燃やすごみ", "なし", "なし", "なし", "燃やすごみ"])]),
            "no collection day",
        ),
    ],
)
def test_a_page_that_changed_shape_stops_the_build(config, page, message):
    with pytest.raises(build.BuildError, match=message):
        make(config, **{PAGE_URL: page})


def test_new_year_dates_become_exceptions(config):
    exceptions = make(config)["exceptions"]
    assert [e["date"] for e in exceptions] == ["2026-12-31", "2027-01-01", "2027-01-02", "2027-01-03"]
    assert {e["type"] for e in exceptions} == {"no_collection"}
    assert exceptions[0]["source_url"] == NEW_YEAR_URL and "categories" not in exceptions[0]


def test_new_year_range_must_agree_with_the_table():
    with pytest.raises(build.BuildError, match="lists 4 closed days but the range has 5"):
        build.parse_new_year(new_year_page(last="令和9年1月4日(月)"))


def test_rules_copy_the_csv_and_add_translations(config):
    rules = {r["item_id"]: r for r in make(config)["rules"]}
    pick = rules["yokohama-1"]
    assert pick["names"] == {"ja": "アイスピック", "kana": "あいすぴっく", "en": "Ice pick"}
    assert pick["category"] == "kinzoku" and pick["aliases"] == []
    assert pick["instructions"] == {
        "ja": "尖った部分は新聞紙等で包む。",
        "en": "Wrap sharp parts in newspaper or similar.",
    }
    assert pick["valid_from"] == "2026-02-09"
    assert pick["source_url"] == config["items"]["page_url"] and pick["verified_at"] == config["items"]["verified_at"]

    iron = rules["yokohama-2"]  # no note: the category's default, plus the small-appliance sentence
    assert iron["aliases"] == ["iron", "flat iron"]
    assert iron["instructions"]["ja"].startswith("燃やすごみとして出してください。区役所などの小型家電回収ボックス")
    assert iron["instructions"]["en"].startswith("Put out as Burnable. Can also go in a small-appliance collection box")

    paper = rules["yokohama-3"]  # full-width brackets in the CSV; the paper type opens the instructions
    assert paper["category"] == "koshi"
    assert paper["instructions"]["ja"] == "古紙「新聞」として出してください。折込ちらしも一緒に。"
    assert paper["instructions"]["en"] == "Put out as Used paper (newspapers). Put out together with newspaper inserts."

    mat = rules["yokohama-4"]  # link markup and the line break are dropped
    assert mat["instructions"]["ja"] == "50cm以上は粗大ごみへ。詳しくは市ホームページへ。"


@pytest.mark.parametrize(
    ("row", "message"),
    [
        (("9", "あ", "アンテナ", "", "粗大ごみ", ""), "item 9 アンテナ: add it to items.tsv"),
        (("1", "あ", "アイスピック(金属製)", "", "小さな金属類", ""), "item 1: renamed"),
        (("1", "あ", "アイスピック", "", "新しい分別", ""), "add 出し方 '新しい分別'"),
        (("1", "あ", "アイスピック", "", "小さな金属類", "新しい注意"), "add the note '新しい注意'"),
    ],
)
def test_untranslated_or_changed_items_stop_the_build(config, row, message):
    with pytest.raises(build.BuildError, match=message):
        make(config, **{"items.csv": items_csv([row])})


def test_csv_link_and_date():
    page = b'<a href="dashikata.files/0141_20260209.csv">list</a><a href="/other.pdf">pdf</a>'
    url = build.find_csv_url(page, "https://city.example/gomi/dashikata.html")
    assert url == "https://city.example/gomi/dashikata.files/0141_20260209.csv"
    assert build.csv_date(url) == "2026-02-09"
    with pytest.raises(build.BuildError, match="expected one CSV link"):
        build.find_csv_url(b"<a href='/a.html'>none</a>", "https://city.example/")


# --- The committed bundle ---


@pytest.fixture(scope="module")
def bundle():
    return json.loads((build.MUNICIPALITY_DIR / "bundle.json").read_text(encoding="utf-8"))


def test_committed_bundle_is_valid(bundle):
    assert validate.validate_bundle(bundle) == []


def test_committed_bundle_covers_every_area_with_every_collected_category(bundle, real):
    config, areas, *_ = real
    assert sorted(a["id"] for a in bundle["areas"]) == sorted(f"{a['ward']}-{a['s_area']}" for a in areas)
    collected = {c for g in config["schedule_groups"].values() for c in g["categories"]}
    for area in bundle["areas"]:
        mine = [c for c in bundle["calendars"] if area["id"] in c["area_ids"]]
        assert sorted(c for cal in mine for c in cal["categories"]) == sorted(collected), area["id"]


def test_committed_bundle_matches_the_translation_tables(bundle, real):
    config, _, _, items, _ = real
    by_id = {f"yokohama-{i['id']}": i for i in items}
    assert len(bundle["rules"]) == len(items)
    for rule in bundle["rules"]:
        item = by_id[rule["item_id"]]
        assert (rule["names"]["ja"], rule["names"]["kana"], rule["names"]["en"]) == (
            item["ja"],
            item["kana"],
            item["en"],
        )
        assert rule["source_url"] and rule["verified_at"] == config["items"]["verified_at"]


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q", *sys.argv[1:]]))
