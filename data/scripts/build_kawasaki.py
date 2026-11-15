#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["beautifulsoup4>=4.12", "httpx>=0.27", "pypdf>=5", "pyyaml>=6"]
# ///
"""Build the Kawasaki bundle from the city's pages, Takatsu-ku first.

Usage:
    uv run data/scripts/build_kawasaki.py [--refresh] [--generated-at TIMESTAMP]

The build reads data/municipalities/14130/ (config.yaml, areas.tsv, towns.tsv,
items.tsv, notes.tsv), downloads each ward's 収集日一覧 page and the item list
into data/.cache/14130/ (ignored by git), and checks everything it can.

**It only writes bundle.json once `reuse_confirmed` is true in config.yaml.**
Kawasaki's site policy reserves all rights; until the city agrees to reuse
(DAI-589), the build stops after checking and prints what it would write.

Collection days come from the 収集日一覧 HTML tables: one row per town, one
column per collection, with cells such as 火曜・金曜 (weekly) or
第1・3回目 月曜 (the 1st and 3rd Monday of the month). Areas and readings come
from areas.tsv and towns.tsv (data/scripts/postal_towns.py). The city writes
ヶ where e-Stat writes ケ (梶ヶ谷, 梶ケ谷); they are matched as the same.

English item names, kana and notes come from items.tsv and notes.tsv, and the
build stops listing every item or note that has none.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sys
import unicodedata
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import yaml
from bs4 import BeautifulSoup

sys.path.insert(0, str(Path(__file__).resolve().parent))
import monitor

DATA_DIR = Path(__file__).resolve().parent.parent
MUNICIPALITY_DIR = DATA_DIR / "municipalities" / "14130"
CACHE_DIR = DATA_DIR / ".cache" / "14130"
JST = ZoneInfo("Asia/Tokyo")

WEEKDAYS = {"月": "mon", "火": "tue", "水": "wed", "木": "thu", "金": "fri", "土": "sat", "日": "sun"}
KANJI_DIGITS = "一二三四五六七八九十"
CHOME_KANA = ["いっ", "に", "さん", "よん", "ご", "ろく", "なな", "はっ", "きゅう", "じっ"]


class BuildError(Exception):
    """A source no longer has the shape the build expects, or something is untranslated."""


def nfkc(text: str) -> str:
    return unicodedata.normalize("NFKC", text)


def town_key(name: str) -> str:
    """梶ヶ谷 and 梶ケ谷 (and ヵ, カ) are the same town."""
    return nfkc(name).replace("ヶ", "ケ").replace("ヵ", "カ").replace(" ", "")


def read_tsv(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f, delimiter="\t", quoting=csv.QUOTE_NONE))


# --- Collection days ---------------------------------------------------------


def parse_cell(cell: str) -> dict:
    """火曜・金曜 -> weekly; 第1・3回目 月曜 -> monthly_nth_weekday."""
    text = nfkc(cell).replace(" ", "")
    monthly = re.fullmatch(r"第(\d(?:・\d)*)回目(.)曜", text)
    if monthly:
        weekday = WEEKDAYS.get(monthly.group(2))
        if weekday is None:
            raise BuildError(f"unknown weekday in {cell!r}")
        return {
            "type": "monthly_nth_weekday",
            "weekday": weekday,
            "nth": [int(n) for n in monthly.group(1).split("・")],
        }
    days = re.findall(r"(.)曜", text)
    if not days or re.sub(r"(.)曜|・", "", text) or any(d not in WEEKDAYS for d in days):
        raise BuildError(f"unexpected collection day {cell!r}")
    return {"type": "weekly", "weekdays": [WEEKDAYS[d] for d in days]}


def parse_schedule_page(raw: bytes, columns: dict) -> dict:
    """Each ward's table on a 収集日一覧 page, by the heading above it, and the page's date."""
    soup = BeautifulSoup(raw, "html.parser")
    text = nfkc(soup.get_text())
    updated = re.search(r"更新日[:：]\s*(\d{4})年(\d{1,2})月(\d{1,2})日", text)
    if not updated:
        raise BuildError("no 更新日 on the page")

    tables = {}
    for table in soup.find_all("table"):
        heading = table.find_previous(["h2", "h3", "h4"])
        name = nfkc(heading.get_text(strip=True)) if heading else ""
        header, *body = table.find_all("tr")
        cells = [nfkc(c.get_text(strip=True)).replace(" ", "") for c in header.find_all(["th", "td"])]
        if cells[:2] != ["", "町名"] or cells[2:] != list(columns):
            raise BuildError(f"{name}: unexpected table header {cells}")
        rows, kana = [], None
        for tr in body:
            values = [nfkc(c.get_text(strip=True)) for c in tr.find_all(["th", "td"])]
            if len(values) != len(cells):
                raise BuildError(f"{name}: unexpected table row {values}")
            kana = values[0] or kana
            rows.append(
                {
                    "kana": kana,
                    "town": values[1],
                    "schedule": {col: parse_cell(v) for col, v in zip(columns, values[2:], strict=True)},
                }
            )
        if not rows:
            raise BuildError(f"{name}: the collection-day table is empty")
        tables[name] = rows
    if not tables:
        raise BuildError("no collection-day table on the page")
    return {"updated": date(*map(int, updated.groups())).isoformat(), "tables": tables}


def area_entry(area: dict, town: dict) -> dict:
    entry = {"id": f"{area['ward']}-{area['s_area']}", "ward_id": area["ward"]}
    names = {"ja": town["ja"], "kana": town["kana"], "en": town["en"]}
    if area["chome"]:
        n = int(area["chome"])
        entry["names"] = {
            "ja": f"{town['ja']}{KANJI_DIGITS[n - 1]}丁目",
            "kana": f"{town['kana']}{CHOME_KANA[n - 1]}ちょうめ",
            "en": f"{town['en']} {n}-chome",
        }
        entry["town"] = names
        entry["chome"] = n
    else:
        entry["names"] = dict(names)
        entry["town"] = names
    codes = town.get("postal_codes", "").split()
    if codes:
        entry["postal_codes"] = codes
    return entry


def build_ward(ward: dict, page: dict, areas: list[dict], towns: list[dict], columns: dict) -> tuple:
    """Areas and calendars for one ward. Every area must be covered by exactly one row."""
    rows = page["tables"].get(ward["table"])
    if rows is None:
        raise BuildError(f"{ward['table']}: no table under that heading on {ward['page']}")
    ward_areas = [a for a in areas if a["ward"] == ward["id"]]
    town_by_key = {town_key(t["ja"]): t for t in towns if t["ward"] == ward["id"]}
    covered: dict[str, str] = {}
    calendars = []
    for row in rows:
        key = town_key(row["town"])
        matched = [a for a in ward_areas if town_key(a["town"]) == key]
        if not matched:
            raise BuildError(f"{row['town']}: no area for this town in areas.tsv")
        town = town_by_key.get(key)
        if town is None:
            raise BuildError(f"{row['town']}: no reading in towns.tsv")
        for area in matched:
            if area["s_area"] in covered:
                raise BuildError(
                    f"{row['town']}: area {area['s_area']} is already covered by {covered[area['s_area']]}"
                )
            covered[area["s_area"]] = row["town"]
        slug = re.sub(r"[^a-z0-9]", "", town["en"].lower())
        for column, group in columns.items():
            calendars.append(
                {
                    "id": f"{ward['slug']}-{slug}-{group['slug']}",
                    "categories": group["categories"],
                    "area_ids": [f"{a['ward']}-{a['s_area']}" for a in matched],
                    "pattern": row["schedule"][column],
                    "valid_from": page["updated"],
                    "source_url": ward["page"],
                }
            )
    uncovered = [f"{a['s_area']} {a['ja']}" for a in ward_areas if a["s_area"] not in covered]
    if uncovered:
        raise BuildError(f"{ward['names']['ja']}: no collection days for {uncovered}")
    town_of = {town_key(a["town"]): town_by_key[town_key(a["town"])] for a in ward_areas}
    entries = [area_entry(a, town_of[town_key(a["town"])]) for a in sorted(ward_areas, key=lambda a: a["s_area"])]
    return entries, calendars


def new_year_exceptions(config: dict) -> list[dict]:
    new_year = config["new_year"]
    return [
        {"date": f"{year}-{day}", "type": "no_collection", "note": new_year["note"]}
        for year in new_year["years"]
        for day in new_year["closed"]
    ]


# --- Items -------------------------------------------------------------------


def parse_item_list(raw: bytes) -> list[dict]:
    """Rows of the ごみの分別に迷ったら tables: item, 分別区分, note."""
    soup = BeautifulSoup(raw, "html.parser")
    items = []
    for table in soup.find_all("table"):
        for tr in table.find_all("tr"):
            cells = [nfkc(c.get_text(" ", strip=True)) for c in tr.find_all(["th", "td"])]
            if len(cells) != 3 or cells[1] == "分別区分":
                continue
            items.append({"ja": cells[0], "method": cells[1], "note": cells[2]})
    if not items:
        raise BuildError("no items on the item list page")
    return items


def item_id(ja: str) -> str:
    """Stable while the item's name is: a renamed item is a new item."""
    return "kawasaki-" + hashlib.sha256(ja.encode()).hexdigest()[:10]


def build_rules(items: list[dict], config: dict, translations: list[dict], notes: list[dict], valid_from: str) -> list:
    by_ja = {t["ja"]: t for t in translations}
    note_en = {n["ja"]: n["en"] for n in notes}
    categories = {c["id"]: c for c in config["categories"]}
    methods = {nfkc(k): v for k, v in config["methods"].items()}
    problems, rules = [], []
    for item in items:
        method = methods.get(item["method"])
        translation = by_ja.get(item["ja"])
        if method is None:
            problems.append(f"{item['ja']}: add 分別区分 {item['method']!r} to methods in config.yaml")
        if translation is None:
            problems.append(f"{item['ja']}: add it to items.tsv")
        if item["note"] and item["note"] not in note_en:
            problems.append(f"{item['ja']}: add the note {item['note']!r} to notes.tsv")
        if method is None or translation is None or (item["note"] and item["note"] not in note_en):
            continue
        ja, en = [], []
        if "lead" in method:
            ja.append(method["lead"]["ja"])
            en.append(method["lead"]["en"])
        if item["note"]:
            ja.append(item["note"].rstrip("。") + "。")
            en.append(note_en[item["note"]])
        if not ja:
            default = categories[method["category"]]["default"]
            ja.append(default["ja"])
            en.append(default["en"])
        rules.append(
            {
                "item_id": item_id(item["ja"]),
                "names": {"ja": item["ja"], "kana": translation["kana"], "en": translation["en"]},
                "aliases": [a.strip() for a in translation.get("aliases", "").split(";") if a.strip()],
                "category": method["category"],
                "instructions": {"ja": "".join(ja), "en": " ".join(en)},
                "valid_from": valid_from,
                "source_url": config["items"]["page_url"],
                "verified_at": config["items"]["verified_at"],
            }
        )
    if problems:
        shown = "\n  ".join(problems[:40])
        raise BuildError(f"{len(problems)} items need attention:\n  {shown}")
    return rules


# --- Bundle ------------------------------------------------------------------


def build(config: dict, areas, towns, translations, notes, sources: dict, generated_at: str) -> dict:
    """Assemble the bundle. `sources` holds the downloaded pages by URL."""
    columns = config["schedule_columns"]
    all_areas, calendars, valid_from = [], [], None
    for ward in config["wards"]:
        page = parse_schedule_page(sources[ward["page"]], columns)
        valid_from = valid_from or page["updated"]
        ward_areas, ward_calendars = build_ward(ward, page, areas, towns, columns)
        all_areas += ward_areas
        calendars += ward_calendars
    items = parse_item_list(sources[config["items"]["page_url"]])
    rules = build_rules(items, config, translations, notes, valid_from)
    return {
        "schema_version": 1,
        "bundle_version": config["bundle_version"],
        "generated_at": generated_at,
        "municipality": config["municipality"],
        "attribution": config["attribution"],
        "wards": [{k: w[k] for k in ("id", "names", "contact") if k in w} for w in config["wards"]],
        "areas": all_areas,
        "categories": [{k: v for k, v in c.items() if k != "default"} for c in config["categories"]],
        "rules": rules,
        "calendars": calendars,
        "exceptions": new_year_exceptions(config),
    }


def load_inputs(directory: Path = MUNICIPALITY_DIR) -> tuple:
    config = yaml.safe_load((directory / "config.yaml").read_text(encoding="utf-8"))
    return (
        config,
        read_tsv(directory / "areas.tsv"),
        read_tsv(directory / "towns.tsv"),
        read_tsv(directory / "items.tsv"),
        read_tsv(directory / "notes.tsv"),
    )


def cached(url: str, fetcher: monitor.Fetcher, refresh: bool) -> bytes:
    path = CACHE_DIR / (hashlib.sha256(url.encode()).hexdigest()[:16] + ".html")
    if refresh or not path.exists():
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        print(f"fetch {url}")
        path.write_bytes(fetcher.get(url).content)
    return path.read_bytes()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--refresh", action="store_true", help="download the pages again")
    parser.add_argument("--generated-at", help="RFC 3339 timestamp for the bundle (default: now)")
    args = parser.parse_args()

    config, areas, towns, translations, notes = load_inputs()
    if not areas or not towns:
        print("FAIL areas.tsv and towns.tsv are missing; run data/scripts/postal_towns.py 14130 first")
        return 1
    fetcher = monitor.Fetcher()
    try:
        urls = [w["page"] for w in config["wards"]] + [config["items"]["page_url"]]
        sources = {url: cached(url, fetcher, args.refresh) for url in urls}
        generated_at = args.generated_at or datetime.now(JST).replace(microsecond=0).isoformat()
        bundle = build(config, areas, towns, translations, notes, sources, generated_at)
    except BuildError as e:
        print(f"FAIL {e}")
        return 1

    summary = (
        f"{len(bundle['areas'])} areas, {len(bundle['rules'])} rules, "
        f"{len(bundle['calendars'])} calendars, {len(bundle['exceptions'])} exceptions"
    )
    if not config.get("reuse_confirmed"):
        print(f"checked: {summary}. Not written: Kawasaki hasn't agreed to reuse yet (DAI-589).")
        return 0
    import build_yokohama  # shares the one-line-per-entry layout

    out = MUNICIPALITY_DIR / "bundle.json"
    out.write_text(build_yokohama.dump_bundle(bundle), encoding="utf-8")
    print(f"wrote {out.relative_to(DATA_DIR.parent)}: {summary}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
