#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["beautifulsoup4>=4.12", "httpx>=0.27", "pypdf>=5", "pyyaml>=6"]
# ///
"""Build the Yokohama bundle from the city's pages and item list.

Usage:
    uv run data/scripts/build_yokohama.py [--refresh] [--generated-at TIMESTAMP]
    uv run data/scripts/build_yokohama.py areas WARD_ID ESTAT_ZIP

The build reads data/municipalities/14100/ (config.yaml, areas.tsv, towns.tsv,
items.tsv, notes.tsv), downloads the collection-day pages, the New Year page
and the item list CSV into data/.cache/14100/, and writes bundle.json.
Downloads are reused on later runs; --refresh fetches them again.

Everything in Japanese is copied from the sources. English and kana come from
items.tsv and notes.tsv, and the build stops if an item or note has no entry
there or an item was renamed since it was translated.

`areas` prints areas.tsv rows for one ward from an e-Stat small-area boundary
download (shapefile zip, 2020 census).
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import struct
import sys
import unicodedata
import zipfile
from datetime import date, datetime, timedelta
from pathlib import Path
from urllib.parse import urljoin
from zoneinfo import ZoneInfo

import yaml
from bs4 import BeautifulSoup

sys.path.insert(0, str(Path(__file__).resolve().parent))
import monitor

DATA_DIR = Path(__file__).resolve().parent.parent
MUNICIPALITY_DIR = DATA_DIR / "municipalities" / "14100"
CACHE_DIR = DATA_DIR / ".cache" / "14100"
JST = ZoneInfo("Asia/Tokyo")

WEEKDAYS = {
    "月曜日": "mon",
    "火曜日": "tue",
    "水曜日": "wed",
    "木曜日": "thu",
    "金曜日": "fri",
    "土曜日": "sat",
    "日曜日": "sun",
}
KANJI_DIGITS = "一二三四五六七八九十"
CHOME_KANA = ["いっ", "に", "さん", "よん", "ご", "ろく", "なな", "はっ", "きゅう", "じっ"]
# Voiced and small kana folded to the plain one, the way a 五十音 index groups them.
SEION = str.maketrans(
    "がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ", "かきくけこさしすせそたちつてとはひふへほはひふへほ"
)
SMALL_APPLIANCE_MARK = "◎"


class BuildError(Exception):
    """A source no longer has the shape the build expects, or a translation is missing."""


def nfkc(text: str) -> str:
    return unicodedata.normalize("NFKC", text)


def read_tsv(path: Path) -> list[dict]:
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f, delimiter="\t", quoting=csv.QUOTE_NONE))


def cached(url: str, name: str, fetcher: monitor.Fetcher, refresh: bool) -> bytes:
    path = CACHE_DIR / name
    if refresh or not path.exists():
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        print(f"fetch {url}")
        path.write_bytes(fetcher.get(url).content)
    return path.read_bytes()


# --- Collection days ---------------------------------------------------------


def parse_schedule_page(raw: bytes, groups: dict) -> dict:
    """Read one ward page: its date, put-out time and one entry per table row."""
    soup = BeautifulSoup(raw, "html.parser")
    text = nfkc(soup.get_text())

    updated = re.search(r"最終更新日\s*(\d{4})年(\d{1,2})月(\d{1,2})日", text)
    if not updated:
        raise BuildError("no 最終更新日 on the page")
    put_out = re.search(r"収集日の朝(\d{1,2})時までに", text)
    if not put_out:
        raise BuildError("the page no longer says what time to put waste out by")
    for label, group in groups.items():
        if "note" in group and nfkc(group["note"]) not in text:
            raise BuildError(f"the page no longer says which categories go out with {label}")

    table = next((t for t in soup.find_all("table") if "町名" in t.get_text()), None)
    if table is None:
        raise BuildError("no collection-day table on the page")
    header, *body = table.find_all("tr")
    columns = [nfkc(c.get_text(strip=True)) for c in header.find_all(["th", "td"])]
    if columns[:2] != ["五十音", "町名"] or any(c not in WEEKDAYS for c in columns[2:]):
        raise BuildError(f"unexpected table header {columns}")
    days = [WEEKDAYS[c] for c in columns[2:]]

    rows, kana = [], None
    for tr in body:
        cells = [nfkc(c.get_text(strip=True)) for c in tr.find_all(["th", "td"])]
        if len(cells) == len(columns):  # the first cell names the 五十音 group, or is empty within one
            kana, cells = cells[0] or kana, cells[1:]
        if len(cells) != len(columns) - 1 or kana is None:
            raise BuildError(f"unexpected table row {cells}")
        schedule = {}
        for day, cell in zip(days, cells[1:], strict=True):
            if cell == "なし":
                continue
            if cell not in groups:
                raise BuildError(f"{cells[0]}: unknown collection {cell!r}")
            schedule.setdefault(cell, []).append(day)
        missing = set(groups) - set(schedule)
        if missing:
            raise BuildError(f"{cells[0]}: no collection day for {sorted(missing)}")
        rows.append({"kana": kana, "label": cells[0], "schedule": schedule})
    if not rows:
        raise BuildError("the collection-day table is empty")
    return {
        "updated": date(*map(int, updated.groups())).isoformat(),
        "put_out_by": f"{int(put_out.group(1)):02d}:00",
        "rows": rows,
    }


def split_row_label(label: str) -> tuple[str, list[int] | None]:
    """青葉台1・2丁目 -> (青葉台, [1, 2]); あざみ野南1~4丁目 -> (あざみ野南, [1, 2, 3, 4]); 恩田町 -> (恩田町, None)."""
    match = re.fullmatch(r"(.+?)(\d+(?:[・~]\d+)*)丁目", label)
    if not match:
        return label, None
    chome: list[int] = []
    for part in match.group(2).split("・"):
        first, _, last = part.partition("~")
        chome.extend(range(int(first), int(last or first) + 1))
    return match.group(1), chome


def row_areas(label: str, ward_areas: list[dict], aliases: dict) -> list[dict]:
    """The areas of a ward that one table row covers."""
    town, chome = split_row_label(label)
    town = aliases.get(town, town)
    in_town = [a for a in ward_areas if a["town"] == town]
    if not in_town:
        raise BuildError(f"{label}: no area for town {town!r} in areas.tsv")
    if chome is None:
        if any(a["chome"] for a in in_town):
            raise BuildError(f"{label}: the town has chome in areas.tsv but the row names none")
        return in_town
    by_chome = {int(a["chome"]): a for a in in_town if a["chome"]}
    missing = [c for c in chome if c not in by_chome]
    if missing:
        raise BuildError(f"{label}: no area for chome {missing} in areas.tsv")
    return [by_chome[c] for c in chome]


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
    else:
        entry["names"] = dict(names)
    entry["town"] = names
    if area["chome"]:
        entry["chome"] = int(area["chome"])
    return entry


def build_ward(ward: dict, pages: list[tuple[str, dict]], areas: list[dict], towns: list[dict], groups: dict) -> tuple:
    """Areas and calendars for one ward from its parsed collection-day pages."""
    ward_areas = [a for a in areas if a["ward"] == ward["id"]]
    town_by_ja = {t["ja"]: t for t in towns if t["ward"] == ward["id"]}
    aliases = ward.get("town_aliases", {})
    covered: dict[str, str] = {}
    calendars = []
    for url, page in pages:
        for row in page["rows"]:
            matched = row_areas(row["label"], ward_areas, aliases)
            town = town_by_ja.get(matched[0]["town"])
            if town is None:
                raise BuildError(f"{row['label']}: town {matched[0]['town']!r} has no reading in towns.tsv")
            if town["kana"][0].translate(SEION) != row["kana"].translate(SEION):
                raise BuildError(f"{row['label']}: reading {town['kana']!r} is not under {row['kana']!r} on the page")
            for area in matched:
                if area["s_area"] in covered:
                    raise BuildError(
                        f"{row['label']}: area {area['s_area']} is already covered by {covered[area['s_area']]}"
                    )
                covered[area["s_area"]] = row["label"]
            _, chome = split_row_label(row["label"])
            slug = re.sub(r"[^a-z0-9]", "", town["en"].lower()) + "".join(f"-{c}" for c in chome or [])
            for label, group in groups.items():
                calendars.append(
                    {
                        "id": f"{ward['slug']}-{slug}-{group['slug']}",
                        "categories": group["categories"],
                        "area_ids": [f"{a['ward']}-{a['s_area']}" for a in matched],
                        "pattern": {"type": "weekly", "weekdays": row["schedule"][label]},
                        "put_out_by": page["put_out_by"],
                        "valid_from": page["updated"],
                        "source_url": url,
                    }
                )
    uncovered = [f"{a['s_area']} {a['ja']}" for a in ward_areas if a["s_area"] not in covered]
    if uncovered:
        raise BuildError(f"{ward['names']['ja']}: no collection days found for {uncovered}")
    entries = [area_entry(a, town_by_ja[a["town"]]) for a in sorted(ward_areas, key=lambda a: a["s_area"])]
    return entries, calendars


def parse_new_year(raw: bytes) -> list[str]:
    """Dates with no collection, from the sentence that gives the holiday range."""
    text = nfkc(BeautifulSoup(raw, "html.parser").get_text())
    day = r"令和(\d+)年(\d+)月(\d+)日\(.\)"
    match = re.search(day + "から" + day + "まで、資源とごみの収集をお休み", text)
    if not match:
        raise BuildError("the New Year page no longer gives the no-collection range")
    y1, m1, d1, y2, m2, d2 = map(int, match.groups())
    first, last = date(2018 + y1, m1, d1), date(2018 + y2, m2, d2)
    if not first <= last <= first + timedelta(days=14):
        raise BuildError(f"implausible New Year range {first} to {last}")
    closed = len(re.findall(r"\d+月\d+日\(.\)\s*収集はお休みです", text))
    days = (last - first).days + 1
    if closed != days:
        raise BuildError(f"the New Year table lists {closed} closed days but the range has {days}")
    return [(first + timedelta(days=i)).isoformat() for i in range(days)]


# --- Items -------------------------------------------------------------------


def find_csv_url(raw: bytes, page_url: str) -> str:
    links = [
        a["href"] for a in BeautifulSoup(raw, "html.parser").find_all("a", href=True) if a["href"].endswith(".csv")
    ]
    if len(links) != 1:
        raise BuildError(f"expected one CSV link on {page_url}, found {len(links)}")
    return urljoin(page_url, links[0])


def csv_date(url: str) -> str:
    """The item list's publication date, from its file name (…_20260209.csv)."""
    match = re.search(r"_(\d{4})(\d{2})(\d{2})\.csv$", url)
    if not match:
        raise BuildError(f"no date in the CSV file name {url}")
    return date(*map(int, match.groups())).isoformat()


def clean_note(note: str) -> str:
    """A 出し方のポイント cell as plain text on one line."""
    note = re.sub(r"<[^>]+>", "", note)
    return re.sub(r"\s*[\r\n]+\s*", "", note).strip()


def sentence(text: str) -> str:
    return text if text.endswith(("。", ")", "!")) else text + "。"


def build_rules(raw: bytes, config: dict, items: list[dict], notes: list[dict], valid_from: str) -> list[dict]:
    rows = list(csv.DictReader(io.StringIO(raw.decode("cp932"))))
    expected = ["ID", "頭文字", "品目名", "小型家電回収対象", "出し方", "出し方のポイント"]
    if not rows or list(rows[0]) != expected:
        raise BuildError(f"unexpected CSV columns {list(rows[0]) if rows else []}")
    item_by_id = {i["id"]: i for i in items}
    note_en = {n["ja"]: n["en"] for n in notes}
    categories = {c["id"]: c for c in config["categories"]}
    methods = {nfkc(k): v for k, v in config["methods"].items()}
    appliance = config["items"]["small_appliance_note"]

    problems, rules = [], []
    for row in sorted(rows, key=lambda r: int(r["ID"])):
        item = item_by_id.get(row["ID"])
        method = methods.get(nfkc(row["出し方"]))
        note = clean_note(row["出し方のポイント"])
        if item is None:
            problems.append(f"item {row['ID']} {row['品目名']}: add it to items.tsv")
        elif item["ja"] != row["品目名"]:
            problems.append(f"item {row['ID']}: renamed from {item['ja']!r} to {row['品目名']!r}; check items.tsv")
        if method is None:
            problems.append(f"item {row['ID']}: add 出し方 {row['出し方']!r} to methods in config.yaml")
        if note and note not in note_en:
            problems.append(f"item {row['ID']}: add the note {note!r} to notes.tsv")
        if row["小型家電回収対象"] not in ("", SMALL_APPLIANCE_MARK):
            problems.append(f"item {row['ID']}: unexpected 小型家電回収対象 {row['小型家電回収対象']!r}")
        if problems:
            continue

        ja, en = [], []
        if "lead" in method:
            ja.append(method["lead"]["ja"])
            en.append(method["lead"]["en"])
        if note:
            ja.append(sentence(note))
            en.append(note_en[note])
        if not ja:
            default = categories[method["category"]]["default"]
            ja.append(default["ja"])
            en.append(default["en"])
        if row["小型家電回収対象"]:
            ja.append(appliance["ja"])
            en.append(appliance["en"])
        rules.append(
            {
                "item_id": f"yokohama-{int(row['ID'])}",
                "names": {"ja": row["品目名"], "kana": item["kana"], "en": item["en"]},
                "aliases": [a.strip() for a in item["aliases"].split(";") if a.strip()],
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


def build(config: dict, areas, towns, items, notes, sources: dict, generated_at: str) -> dict:
    """Assemble the bundle. `sources` holds the downloaded bytes by name."""
    groups = config["schedule_groups"]
    all_areas, calendars = [], []
    for ward in config["wards"]:
        pages = [(url, parse_schedule_page(sources[url], groups)) for url in ward["pages"]]
        ward_areas, ward_calendars = build_ward(ward, pages, areas, towns, groups)
        all_areas += ward_areas
        calendars += ward_calendars

    new_year = config["exceptions"]["new_year"]
    exceptions = [
        {"date": d, "type": "no_collection", "note": new_year["note"], "source_url": new_year["url"]}
        for d in parse_new_year(sources[new_year["url"]])
    ]
    rules = build_rules(sources["items.csv"], config, items, notes, csv_date(sources["items.csv.url"]))
    return {
        "schema_version": 1,
        "bundle_version": config["bundle_version"],
        "generated_at": generated_at,
        "municipality": config["municipality"],
        "attribution": config["attribution"],
        "wards": [{"id": w["id"], "names": w["names"]} for w in config["wards"]],
        "areas": all_areas,
        "categories": [{k: v for k, v in c.items() if k != "default"} for c in config["categories"]],
        "rules": rules,
        "calendars": calendars,
        "exceptions": exceptions,
    }


def dump_bundle(bundle: dict) -> str:
    """JSON with one list item per line, so a changed rule is a one-line diff."""
    lines = []
    for key, value in bundle.items():
        if isinstance(value, list):
            items = ",\n".join("    " + json.dumps(v, ensure_ascii=False) for v in value)
            lines.append(f"  {json.dumps(key)}: [\n{items}\n  ]")
        else:
            lines.append(f"  {json.dumps(key)}: {json.dumps(value, ensure_ascii=False)}")
    return "{\n" + ",\n".join(lines) + "\n}\n"


def load_inputs(directory: Path = MUNICIPALITY_DIR) -> tuple:
    config = yaml.safe_load((directory / "config.yaml").read_text(encoding="utf-8"))
    return config, *(read_tsv(directory / f"{name}.tsv") for name in ("areas", "towns", "items", "notes"))


def estat_areas(ward_id: str, archive: Path) -> list[list[str]]:
    """areas.tsv rows from an e-Stat boundary zip: one per small area, named as e-Stat names it."""
    with zipfile.ZipFile(archive) as z:
        raw = z.read(next(n for n in z.namelist() if n.endswith(".dbf")))
    count, header_len, record_len = struct.unpack("<IHH", raw[4:12])
    fields, offset = [], 32
    while raw[offset] != 0x0D:
        fields.append((raw[offset : offset + 11].split(b"\0")[0].decode(), raw[offset + 16]))
        offset += 32
    seen = {}
    for i in range(count):
        record, pos, row = raw[header_len + i * record_len : header_len + (i + 1) * record_len], 1, {}
        for name, length in fields:
            row[name] = record[pos : pos + length].decode("cp932").strip()
            pos += length
        if row["PREF"] + row["CITY"] == ward_id:
            seen[row["S_AREA"]] = row["S_NAME"]
    out = []
    for s_area, name in sorted(seen.items()):
        match = re.fullmatch(rf"(.+?)([{KANJI_DIGITS}])丁目", name)
        town, chome = (match.group(1), str(KANJI_DIGITS.index(match.group(2)) + 1)) if match else (name, "")
        out.append([ward_id, s_area, name, town, chome])
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", nargs="*", help="omit to build; or: areas WARD_ID ESTAT_ZIP")
    parser.add_argument("--refresh", action="store_true", help="download the sources again")
    parser.add_argument("--generated-at", help="RFC 3339 timestamp for the bundle (default: now)")
    args = parser.parse_args()

    if args.command[:1] == ["areas"] and len(args.command) == 3:
        for row in estat_areas(args.command[1], Path(args.command[2])):
            print("\t".join(row))
        return 0
    if args.command:
        parser.error("unknown command")

    config, areas, towns, items, notes = load_inputs()
    fetcher = monitor.Fetcher()
    sources = {}
    try:
        for ward in config["wards"]:
            for url in ward["pages"]:
                name = f"{ward['slug']}-{url.rsplit('/', 1)[1]}"
                sources[url] = cached(url, name, fetcher, args.refresh)
        new_year_url = config["exceptions"]["new_year"]["url"]
        sources[new_year_url] = cached(new_year_url, "new-year.html", fetcher, args.refresh)
        page_url = config["items"]["page_url"]
        csv_url = find_csv_url(cached(page_url, "items-page.html", fetcher, args.refresh), page_url)
        sources["items.csv.url"] = csv_url
        sources["items.csv"] = cached(csv_url, csv_url.rsplit("/", 1)[1], fetcher, args.refresh)

        generated_at = args.generated_at or datetime.now(JST).replace(microsecond=0).isoformat()
        bundle = build(config, areas, towns, items, notes, sources, generated_at)
    except BuildError as e:
        print(f"FAIL {e}")
        return 1

    out = MUNICIPALITY_DIR / "bundle.json"
    out.write_text(dump_bundle(bundle), encoding="utf-8")
    print(
        f"wrote {out.relative_to(DATA_DIR.parent)}: {len(bundle['areas'])} areas, {len(bundle['rules'])} rules, "
        f"{len(bundle['calendars'])} calendars, {len(bundle['exceptions'])} exceptions"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
