#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["httpx>=0.27", "jsonschema[format-nongpl]>=4.23"]
# ///
"""Publish changed bundles and boundary packages, and the manifest, to the CDN.

Usage:
    uv run data/scripts/publish.py [--dry-run] [--prefix PREFIX] [--root DIR]

Reads every data/municipalities/<id>/bundle.json and compares it with the
bundle the live manifest points to. A bundle whose content changed gets the
next bundle_version and is uploaded to /bundles/<id>/<version>.json; one that
did not change is left alone. data/boundaries/<prefecture>.json is handled
the same way, under /boundaries/<prefecture>/<version>.json. The manifest is
written last, and only if every other upload succeeded.

Nothing is uploaded unless every file, and the new manifest, is valid.

    --dry-run   show what would be published, upload nothing
    --prefix    publish under this key prefix instead of the CDN root, for
                trying the publisher out (for example _smoke/publish/)
    --root      use a local directory instead of R2

Needs R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY and R2_BUCKET
unless --root is given. With CDN_BASE_URL set, new bundles are fetched back
through the CDN and their checksums compared.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate

DATA_DIR = Path(__file__).resolve().parent.parent
MUNICIPALITIES_DIR = DATA_DIR / "municipalities"
BOUNDARIES_DIR = DATA_DIR / "boundaries"
CDN_PUT = DATA_DIR / "scripts" / "cdn_put.sh"
SCHEMA_VERSION = 1  # the bundle and boundary schema this publisher writes
MANIFEST_KEY = "manifest.json"
# Set by the publisher on every publish, so they do not count as a content change.
STAMPED = ("bundle_version", "version", "generated_at")
JST = ZoneInfo("Asia/Tokyo")


class PublishError(Exception):
    """Something is invalid or inconsistent. Nothing has been uploaded when this is raised by plan()."""


class DirStore:
    """A local directory laid out like the CDN, for tests and --root."""

    def __init__(self, root: Path):
        self.root = root

    def get(self, key: str) -> bytes | None:
        path = self.root / key
        return path.read_bytes() if path.is_file() else None

    def put(self, key: str, data: bytes, cache: str) -> None:
        path = self.root / key
        if cache == "immutable" and path.exists():
            raise PublishError(f"refusing to overwrite immutable object {key}")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)


class R2Store:
    """The R2 bucket. Reads straight from the bucket, not the CDN, so nothing is stale."""

    def __init__(self):
        for name in ("R2_ACCOUNT_ID", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_BUCKET"):
            if not os.environ.get(name):
                raise PublishError(f"{name} is not set")
        self.bucket = os.environ["R2_BUCKET"]
        self.endpoint = (
            os.environ.get("R2_ENDPOINT") or f"https://{os.environ['R2_ACCOUNT_ID']}.r2.cloudflarestorage.com"
        )
        self.env = os.environ | {
            "AWS_ACCESS_KEY_ID": os.environ["R2_ACCESS_KEY_ID"],
            "AWS_SECRET_ACCESS_KEY": os.environ["R2_SECRET_ACCESS_KEY"],
            "AWS_DEFAULT_REGION": "auto",
            "AWS_REQUEST_CHECKSUM_CALCULATION": "when_required",
            "AWS_RESPONSE_CHECKSUM_VALIDATION": "when_required",
        }

    def get(self, key: str) -> bytes | None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "object"
            command = ["aws", "s3api", "get-object", "--endpoint-url", self.endpoint]
            command += ["--bucket", self.bucket, "--key", key, str(out)]
            result = subprocess.run(command, env=self.env, capture_output=True, text=True, check=False)
            if result.returncode == 0:
                return out.read_bytes()
            if "NoSuchKey" in result.stderr or "(404)" in result.stderr:
                return None
            raise PublishError(f"could not read {key} from R2: {result.stderr.strip()}")

    def put(self, key: str, data: bytes, cache: str) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "object.json"
            path.write_bytes(data)
            command = [str(CDN_PUT), str(path), key, cache]
            result = subprocess.run(command, env=self.env, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise PublishError(f"upload of {key} failed: {(result.stderr or result.stdout).strip()}")


@dataclass
class Plan:
    manifest: dict | None = None  # None when nothing changed
    uploads: list[tuple[str, bytes]] = field(default_factory=list)  # (path, bytes), everything but the manifest
    lines: list[str] = field(default_factory=list)  # one human-readable line per bundle or package


def content(bundle: dict) -> dict:
    return {k: v for k, v in bundle.items() if k not in STAMPED}


def encode(document: dict) -> bytes:
    return json.dumps(document, ensure_ascii=False, separators=(",", ":")).encode()


def load_local(directory: Path) -> dict[str, dict]:
    """Every municipality's committed bundle, by id."""
    bundles = {}
    for path in sorted(directory.glob("*/bundle.json")):
        bundle = json.loads(path.read_text(encoding="utf-8"))
        folder = path.parent.name
        if bundle.get("municipality", {}).get("id") != folder:
            raise PublishError(f"{path}: municipality id does not match its folder {folder}")
        bundles[folder] = bundle
    return bundles


def load_boundaries(directory: Path) -> dict[str, dict]:
    """Every committed boundary package, by prefecture code."""
    packages = {}
    for path in sorted(directory.glob("*.json")):
        package = json.loads(path.read_text(encoding="utf-8"))
        if package.get("prefecture_code") != path.stem:
            raise PublishError(f"{path}: prefecture_code does not match its file name {path.stem}")
        packages[path.stem] = package
    return packages


def bundle_ref(path: str, data: bytes, version: int, published_at: str) -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "bundle_version": version,
        "path": path,
        "sha256": hashlib.sha256(data).hexdigest(),
        "size_bytes": len(data),
        "published_at": published_at,
    }


def next_version(document: dict, start: int, path_of, stamp: str, get, now: str) -> tuple[int, str, bytes, bool]:
    """The first free version from `start`: its number, path, bytes, and whether they still need uploading."""
    version = start
    while True:
        path = path_of(version)
        leftover = get(path.lstrip("/"))  # from a run that uploaded files but never reached the manifest
        if leftover is None:
            return version, path, encode(document | {stamp: version, "generated_at": now}), True
        if content(json.loads(leftover)) == content(document):
            return version, path, leftover, False
        version += 1


def plan(local: dict[str, dict], get, now: str, boundaries: dict[str, dict] | None = None) -> Plan:
    """Work out what to publish. `get(key)` reads an object from the store, or returns None."""
    boundaries = boundaries or {}
    errors = [f"{mid}: {e}" for mid, bundle in local.items() for e in validate.validate_bundle(bundle)]
    errors += [
        f"boundaries {c}: {e}" for c, package in boundaries.items() for e in validate.validate_boundaries(package)
    ]
    if errors:
        raise PublishError("invalid files, nothing published:\n  " + "\n  ".join(errors))

    raw_manifest = get(MANIFEST_KEY)
    manifest = json.loads(raw_manifest) if raw_manifest else {"municipalities": []}
    entries = {m["id"]: m for m in manifest["municipalities"]}
    result = Plan()
    staged: dict[str, bytes] = {}  # every new file the manifest will point to, for the final check

    for mid, bundle in sorted(local.items()):
        entry = entries.get(mid)
        refs = entry["bundles"] if entry else []
        current = next((r for r in refs if r["schema_version"] == SCHEMA_VERSION), None)
        if current:
            published = get(current["path"].lstrip("/"))
            if published is None:
                raise PublishError(f"{mid}: the manifest points to {current['path']}, which is missing")
            if content(json.loads(published)) == content(bundle):
                result.lines.append(f"{mid}: unchanged, stays at version {current['bundle_version']}")
                continue

        start = current["bundle_version"] + 1 if current else 1
        version, path, data, upload = next_version(
            bundle, start, lambda v, mid=mid: f"/bundles/{mid}/{v}.json", "bundle_version", get, now
        )
        if upload:
            result.uploads.append((path, data))
        staged[path] = data

        new_entry = {"id": mid, "names": bundle["municipality"]["names"]}
        if bundle.get("wards"):
            new_entry["ward_ids"] = [w["id"] for w in bundle["wards"]]
        new_entry["area_ids"] = [a["id"] for a in bundle["areas"]]
        others = [r for r in refs if r["schema_version"] != SCHEMA_VERSION]
        new_entry["bundles"] = sorted(
            [bundle_ref(path, data, version, now), *others], key=lambda r: r["schema_version"], reverse=True
        )
        entries[mid] = new_entry
        was = f"was {current['bundle_version']}" if current else "first publish"
        result.lines.append(f"{mid}: version {version} ({was}), {len(data):,} bytes")

    boundary_refs = {b["prefecture_code"]: b for b in manifest.get("boundaries", [])}
    for code, package in sorted(boundaries.items()):
        current = boundary_refs.get(code)
        if current:
            published = get(current["path"].lstrip("/"))
            if published is None:
                raise PublishError(f"boundaries {code}: the manifest points to {current['path']}, which is missing")
            if content(json.loads(published)) == content(package):
                result.lines.append(f"boundaries {code}: unchanged, stays at version {current['version']}")
                continue
        start = current["version"] + 1 if current else 1
        version, path, data, upload = next_version(
            package, start, lambda v, code=code: f"/boundaries/{code}/{v}.json", "version", get, now
        )
        if upload:
            result.uploads.append((path, data))
        staged[path] = data
        boundary_refs[code] = {
            "prefecture_code": code,
            "schema_version": SCHEMA_VERSION,
            "version": version,
            "path": path,
            "bbox": package["bbox"],
            "sha256": hashlib.sha256(data).hexdigest(),
            "size_bytes": len(data),
            "published_at": now,
        }
        was = f"was {current['version']}" if current else "first publish"
        result.lines.append(f"boundaries {code}: version {version} ({was}), {len(data):,} bytes")

    if not staged:
        return result

    result.manifest = {
        "schema_version": 1,
        "generated_at": now,
        "municipalities": [entries[mid] for mid in sorted(entries)],
    }
    if boundary_refs:
        result.manifest["boundaries"] = [boundary_refs[code] for code in sorted(boundary_refs)]
    # Check the manifest against the exact bytes it will point to, before anything is uploaded.
    with tempfile.TemporaryDirectory() as tmp:
        refs = [r for entry in result.manifest["municipalities"] for r in entry["bundles"]]
        for ref in [*refs, *result.manifest.get("boundaries", [])]:
            data = staged.get(ref["path"]) or get(ref["path"].lstrip("/"))
            if data is None:
                raise PublishError(f"{ref['path']} is in the manifest but missing")
            target = Path(tmp) / ref["path"].lstrip("/")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        errors = validate.validate_manifest(result.manifest, Path(tmp))
    if errors:
        raise PublishError("the new manifest is invalid, nothing published:\n  " + "\n  ".join(errors))
    return result


def publish(result: Plan, put) -> None:
    """Upload bundles and boundary packages, then the manifest. A failed upload leaves the old manifest in place."""
    for path, data in result.uploads:
        put(path.lstrip("/"), data, "immutable")
    if result.manifest is not None:
        put(MANIFEST_KEY, encode(result.manifest), "short")


def verify_cdn(base_url: str, prefix: str, uploads: list[tuple[str, bytes]]) -> list[str]:
    """Fetch each new bundle through the CDN and compare checksums."""
    problems = []
    for path, data in uploads:
        url = f"{base_url.rstrip('/')}/{prefix}{path.lstrip('/')}"
        for attempt in range(5):
            try:
                response = httpx.get(url, timeout=30, follow_redirects=True)
                if response.status_code == 200 and response.content == data:
                    break
                problem = f"{url}: HTTP {response.status_code}, checksum {'matches' if response.content == data else 'differs'}"
            except httpx.HTTPError as e:
                problem = f"{url}: {e}"
            time.sleep(3 * (attempt + 1))
        else:
            problems.append(problem)
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--prefix", default="", help="key prefix, for example _smoke/publish/")
    parser.add_argument("--root", type=Path, help="publish into this directory instead of R2")
    parser.add_argument("--municipalities", type=Path, default=MUNICIPALITIES_DIR, help=argparse.SUPPRESS)
    parser.add_argument("--boundaries", type=Path, default=BOUNDARIES_DIR, help=argparse.SUPPRESS)
    args = parser.parse_args()
    prefix = args.prefix.strip("/") + "/" if args.prefix.strip("/") else ""

    try:
        store = DirStore(args.root) if args.root else R2Store()
        local = load_local(args.municipalities)
        if not local:
            raise PublishError(f"no bundles under {args.municipalities}")
        now = datetime.now(JST).replace(microsecond=0).isoformat()
        result = plan(local, lambda key: store.get(prefix + key), now, load_boundaries(args.boundaries))
        if not args.dry_run:
            publish(result, lambda key, data, cache: store.put(prefix + key, data, cache))
    except PublishError as e:
        print(f"FAIL {e}")
        return 1

    target = f"under {prefix}" if prefix else "at the CDN root"
    if args.dry_run:
        headline = f"Dry run {target}: nothing uploaded"
    elif result.manifest is None:
        headline = f"Nothing to publish {target}"
    else:
        headline = f"Published {target}: {len(result.uploads)} file(s), then the manifest"
    summary = [headline, "", *(f"- {line}" for line in result.lines)]

    status = 0
    base_url = os.environ.get("CDN_BASE_URL")
    if base_url and not args.root and not args.dry_run and result.uploads:
        problems = verify_cdn(base_url, prefix, result.uploads)
        summary += (
            ["", *(f"- CDN check failed: {p}" for p in problems)] if problems else ["", "CDN check: new files match."]
        )
        status = 1 if problems else 0

    print("\n".join(summary))
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as f:
            f.write("### Bundle publisher\n\n" + "\n".join(summary) + "\n")
    return status


if __name__ == "__main__":
    sys.exit(main())
