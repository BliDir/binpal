#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["beautifulsoup4>=4.12", "httpx>=0.27", "pypdf>=5", "pyyaml>=6", "jsonschema[format-nongpl]>=4.23"]
# ///
"""Import a Digital Agency standard waste-sorting CSV into a municipality bundle.

Usage: uv run data/scripts/import_standard.py data/imports/13118 [--refresh]

By default builds offline from committed source snapshots. --refresh resolves the
configured CKAN package/resource and downloads it. Changed source bytes require
explicit review of the digest and translations before a new bundle can be built.
Areas, calendars and exceptions come from base.json, never from sorting data.
"""

from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import io
import json
import re
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
import monitor
import validate
from build_yokohama import dump_bundle

COLUMNS = [
    "全国地方公共団体コード",
    "ID",
    "地方公共団体名",
    "ゴミの品目",
    "分別区分",
    "注意点",
    "料金種別",
    "料金",
    "料金備考",
    "備考",
]


class ImportError(Exception):
    """Source data or curated mappings need review; no bundle was written."""


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def row_digest(row: dict) -> str:
    return digest(json.dumps(row, ensure_ascii=False, sort_keys=True).encode())


def parse_csv(raw: bytes, municipality: dict) -> list[dict]:
    for encoding in ("utf-8-sig", "cp932"):
        try:
            text = raw.decode(encoding)
            break
        except UnicodeDecodeError:
            continue
    else:
        raise ImportError("CSV must be UTF-8 or CP932")
    reader = csv.DictReader(io.StringIO(text, newline=""))
    if reader.fieldnames != COLUMNS:
        raise ImportError(f"unexpected standard CSV columns: {reader.fieldnames}")
    rows, seen = [], set()
    for line, row in enumerate(reader, 2):
        if None in row or any(value is None for value in row.values()):
            raise ImportError(f"CSV line {line}: wrong number of cells")
        code = row["全国地方公共団体コード"]
        if not re.fullmatch(r"[0-9]{6}", code) or code[:5] != municipality["id"]:
            raise ImportError(f"CSV line {line}: wrong municipality code {code!r}")
        check = 11 - sum(int(n) * w for n, w in zip(code[:5], (6, 5, 4, 3, 2), strict=True)) % 11
        check %= 10
        if int(code[-1]) != check or row["地方公共団体名"] != municipality["names"]["ja"]:
            raise ImportError(f"CSV line {line}: municipality name or check digit mismatch")
        item_id = row["ID"]
        if not item_id or item_id in seen or not row["ゴミの品目"] or not row["分別区分"]:
            raise ImportError(f"CSV line {line}: empty field or duplicate ID {item_id!r}")
        seen.add(item_id)
        rows.append(row)
    if not rows:
        raise ImportError("empty sorting dataset")
    return sorted(rows, key=lambda r: r["ID"])


def resource_metadata(reply: dict, config: dict) -> dict:
    if not isinstance(reply, dict) or reply.get("success") is not True or not isinstance(reply.get("result"), dict):
        raise ImportError("CKAN did not return a package")
    package = reply["result"]
    if package.get("name") != config["package"]:
        raise ImportError("unexpected CKAN package")
    if package.get("license_id") != config["license_id"]:
        raise ImportError("dataset licence changed; review attribution before importing")
    resources = [r for r in package.get("resources", []) if r.get("id") == config["resource"]]
    if len(resources) != 1 or resources[0].get("format", "").upper() != "CSV":
        raise ImportError("configured CKAN CSV resource is missing or ambiguous")
    resource = resources[0]
    if not resource.get("url", "").startswith("https://"):
        raise ImportError("resource URL must use HTTPS")
    return resource


def read_translations(path: Path) -> dict[str, dict]:
    with path.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f, delimiter="\t", quoting=csv.QUOTE_NONE))
    translations = {}
    for row in rows:
        if not row.get("id") or row["id"] in translations:
            raise ImportError("duplicate or missing translation ID")
        translations[row["id"]] = row
    return translations


def build(base: dict, rows: list[dict], translations: dict, config: dict, resource: dict) -> dict:
    bundle = copy.deepcopy(base)
    if bundle.get("rules"):
        raise ImportError("base.json must not contain sorting rules")
    categories = {c["id"]: c for c in bundle["categories"]}
    if set(translations) != {r["ID"] for r in rows}:
        raise ImportError("translation IDs do not match dataset IDs; review added/removed items")
    rules = []
    for row in rows:
        item = translations[row["ID"]]
        if item.get("source_sha256") != row_digest(row):
            raise ImportError(f"{row['ID']}: source changed; review translation and update its digest")
        if item.get("ja") != row["ゴミの品目"]:
            raise ImportError(f"{row['ID']}: Japanese item name mismatch")
        if any(not item.get(k, "").strip() for k in ("kana", "en", "instructions_en")):
            raise ImportError(f"{row['ID']}: missing English or kana translation")
        category = config["categories"].get(row["分別区分"])
        if category not in categories:
            raise ImportError(f"{row['ID']}: unmapped category {row['分別区分']!r}")
        # Preserve all standard fields, including ambiguous fees, without inventing a currency or unit.
        instructions = [f"分別区分: {row['分別区分']}"]
        instructions += [f"{k}: {row[k]}" for k in COLUMNS[5:] if row[k]]
        slug = f"{base['municipality']['id']}-{row['ID'].lower()}"
        if not re.fullmatch(r"[a-z0-9]+(?:[_-][a-z0-9]+)*", slug) or len(slug) > 64:
            raise ImportError(f"{row['ID']}: cannot form a stable bundle ID")
        rules.append(
            {
                "item_id": slug,
                "names": {"ja": row["ゴミの品目"], "kana": item["kana"], "en": item["en"]},
                "aliases": sorted({a.strip() for a in item.get("aliases", "").split(";") if a.strip()}),
                "category": category,
                "instructions": {"ja": "\n".join(instructions), "en": item["instructions_en"]},
                "valid_from": config["valid_from"],
                "source_url": resource["url"],
                "verified_at": config["verified_at"],
            }
        )
    bundle["rules"] = rules
    errors = validate.validate_bundle(bundle)
    if errors:
        raise ImportError("invalid imported bundle:\n" + "\n".join(errors))
    return bundle


def run(directory: Path, refresh: bool = False, fetcher: monitor.Fetcher | None = None) -> dict:
    config = yaml.safe_load((directory / "config.yaml").read_text(encoding="utf-8"))
    base = json.loads((directory / "base.json").read_text(encoding="utf-8"))
    source_dir = directory / "source"
    if refresh:
        fetcher = fetcher or monitor.Fetcher()
        endpoint = config["catalog_api"]
        if not endpoint.startswith("https://"):
            raise ImportError("catalog_api must use HTTPS")
        reply = fetcher.get(f"{endpoint.rstrip('/')}/package_show?id={config['package']}").json()
        resource = resource_metadata(reply, config)
        raw = fetcher.get(resource["url"]).content
        # Refresh never overwrites reviewed snapshots or the existing bundle on failure.
    else:
        reply = json.loads((source_dir / "package.json").read_text(encoding="utf-8"))
        resource = resource_metadata(reply, config)
        raw = (source_dir / "sorting.csv").read_bytes()
    if digest(raw) != config["source_sha256"]:
        raise ImportError(f"sorting CSV changed (sha256 {digest(raw)}); review source and translations first")
    rows = parse_csv(raw, base["municipality"])
    bundle = build(base, rows, read_translations(directory / "items.tsv"), config, resource)
    if refresh:
        source_dir.mkdir(parents=True, exist_ok=True)
        (source_dir / "package.json").write_text(
            json.dumps(reply, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        (source_dir / "sorting.csv").write_bytes(raw)
    (directory / "bundle.json").write_text(dump_bundle(bundle), encoding="utf-8")
    return bundle


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()
    try:
        bundle = run(args.directory, args.refresh)
    except (ImportError, *monitor.SOURCE_FAILURES, yaml.YAMLError, csv.Error) as e:
        print(f"FAIL {e}")
        return 1
    print(f"wrote {args.directory / 'bundle.json'}: {len(bundle['rules'])} rules, {len(bundle['calendars'])} calendars")
    return 0


if __name__ == "__main__":
    sys.exit(main())
