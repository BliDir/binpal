#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["jsonschema[format-nongpl]>=4.23"]
# ///
"""Validate BinPal bundles and manifests.

Usage:
    uv run data/scripts/validate.py FILE [FILE ...] [--root DIR]

Each FILE is a bundle or a manifest (detected by its top-level keys).
For a manifest, bundle paths are resolved against --root (default: the
manifest's own directory), and each referenced bundle is validated and
checked against its manifest entry.

Exits 0 when every file is valid, 1 otherwise.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker
from referencing import Registry, Resource

SCHEMA_DIR = Path(__file__).resolve().parent.parent / "schema"
SUPPORTED_SCHEMA_VERSIONS = {1}


def load_registry() -> Registry:
    registry = Registry()
    for path in SCHEMA_DIR.glob("*.schema.json"):
        resource = Resource.from_contents(json.loads(path.read_text()))
        # Register under both the canonical $id and the bare file name,
        # so relative $refs between schema files resolve offline.
        registry = registry.with_resource(resource.id(), resource)
        registry = registry.with_resource(path.name, resource)
    return registry


REGISTRY = load_registry()


def validator_for(name: str) -> Draft202012Validator:
    schema = REGISTRY.get_or_retrieve(name).value.contents
    return Draft202012Validator(schema, registry=REGISTRY, format_checker=FormatChecker())


def schema_errors(doc: dict, schema_name: str) -> list[str]:
    errors = sorted(validator_for(schema_name).iter_errors(doc), key=lambda e: list(e.path))
    return [f"{'/'.join(map(str, e.path)) or '(root)'}: {e.message}" for e in errors]


def check_range(where: str, obj: dict, errors: list[str]) -> None:
    if "valid_to" in obj and date.fromisoformat(obj["valid_to"]) < date.fromisoformat(obj["valid_from"]):
        errors.append(f"{where}: valid_to {obj['valid_to']} is before valid_from {obj['valid_from']}")


def duplicates(values) -> list:
    seen, dupes = set(), []
    for v in values:
        if v in seen and v not in dupes:
            dupes.append(v)
        seen.add(v)
    return dupes


def bundle_errors(doc: dict) -> list[str]:
    """Checks JSON Schema cannot express: uniqueness, references, date ranges."""
    errors: list[str] = []
    muni = doc["municipality"]["id"]

    area_ids = [a["id"] for a in doc["areas"]]
    category_ids = [c["id"] for c in doc["categories"]]
    calendar_ids = [c["id"] for c in doc["calendars"]]
    for label, ids in (("area", area_ids), ("category", category_ids), ("calendar", calendar_ids)):
        for d in duplicates(ids):
            errors.append(f"duplicate {label} id {d!r}")

    areas, categories = set(area_ids), set(category_ids)
    for a in area_ids:
        if not a.startswith(muni + "-"):
            errors.append(f"area {a!r} does not belong to municipality {muni}")

    by_item = defaultdict(list)
    for i, rule in enumerate(doc["rules"]):
        where = f"rules/{i} ({rule['item_id']})"
        if rule["category"] not in categories:
            errors.append(f"{where}: unknown category {rule['category']!r}")
        check_range(where, rule, errors)
        by_item[rule["item_id"]].append(rule)

    # Versions of one item must not overlap, or the app cannot pick one.
    for item_id, versions in by_item.items():
        versions.sort(key=lambda r: r["valid_from"])
        for prev, cur in zip(versions, versions[1:]):
            if "valid_to" not in prev or prev["valid_to"] >= cur["valid_from"]:
                errors.append(
                    f"rule {item_id!r}: version from {prev['valid_from']} overlaps version from {cur['valid_from']}"
                )

    for i, cal in enumerate(doc["calendars"]):
        where = f"calendars/{i} ({cal['id']})"
        if cal["category"] not in categories:
            errors.append(f"{where}: unknown category {cal['category']!r}")
        for a in cal["area_ids"]:
            if a not in areas:
                errors.append(f"{where}: unknown area {a!r}")
        check_range(where, cal, errors)

    for i, exc in enumerate(doc["exceptions"]):
        where = f"exceptions/{i} ({exc['date']})"
        for c in exc.get("categories", []):
            if c not in categories:
                errors.append(f"{where}: unknown category {c!r}")
        for a in exc.get("area_ids", []):
            if a not in areas:
                errors.append(f"{where}: unknown area {a!r}")

    return errors


def validate_bundle(doc: dict) -> list[str]:
    errors = schema_errors(doc, "bundle.v1.schema.json")
    return errors or bundle_errors(doc)


def validate_manifest(doc: dict, root: Path) -> list[str]:
    errors = schema_errors(doc, "manifest.v1.schema.json")
    if errors:
        return errors

    for d in duplicates(m["id"] for m in doc["municipalities"]):
        errors.append(f"duplicate municipality id {d!r}")

    for m in doc["municipalities"]:
        mid = m["id"]
        versions = [b["schema_version"] for b in m["bundles"]]
        if versions != sorted(set(versions), reverse=True):
            errors.append(f"{mid}: bundles must have distinct schema_version, highest first")
        for a in m["area_ids"]:
            if not a.startswith(mid + "-"):
                errors.append(f"{mid}: area {a!r} does not belong to this municipality")

        for ref in m["bundles"]:
            where = f"{mid} bundle {ref['path']}"
            file = root / ref["path"].lstrip("/")
            if not file.is_file():
                errors.append(f"{where}: file not found under {root}")
                continue
            raw = file.read_bytes()
            if hashlib.sha256(raw).hexdigest() != ref["sha256"]:
                errors.append(f"{where}: sha256 does not match file")
            if len(raw) != ref["size_bytes"]:
                errors.append(f"{where}: size_bytes {ref['size_bytes']} != actual {len(raw)}")
            if ref["schema_version"] not in SUPPORTED_SCHEMA_VERSIONS:
                continue  # A newer schema than this validator knows; checksum checked above.

            bundle = json.loads(raw)
            errors += [f"{where}: {e}" for e in validate_bundle(bundle)]
            if bundle.get("municipality", {}).get("id") != mid:
                errors.append(f"{where}: municipality id does not match manifest entry")
            if bundle.get("bundle_version") != ref["bundle_version"]:
                errors.append(f"{where}: bundle_version does not match manifest entry")
            if bundle.get("schema_version") != ref["schema_version"]:
                errors.append(f"{where}: schema_version does not match manifest entry")
            if sorted(a["id"] for a in bundle.get("areas", [])) != sorted(m["area_ids"]):
                errors.append(f"{where}: area ids differ from manifest area_ids")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--root", type=Path, help="CDN root for resolving manifest bundle paths")
    args = parser.parse_args()

    failed = False
    for path in args.files:
        try:
            doc = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as e:
            print(f"FAIL {path}: {e}")
            failed = True
            continue

        if isinstance(doc, dict) and "municipalities" in doc:
            kind, errors = "manifest", validate_manifest(doc, args.root or path.parent)
        else:
            kind, errors = "bundle", validate_bundle(doc)

        if errors:
            failed = True
            print(f"FAIL {path} ({kind})")
            for e in errors:
                print(f"  - {e}")
        else:
            print(f"ok   {path} ({kind})")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
