#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["httpx>=0.27", "jsonschema[format-nongpl]>=4.23", "pytest>=8"]
# ///
"""Tests for the bundle publisher, publishing into a temporary directory.

Usage:
    uv run data/tests/test_publish.py
"""

from __future__ import annotations

import copy
import hashlib
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import publish
import validate

EXAMPLE = Path(__file__).resolve().parent.parent / "schema" / "examples" / "bundles" / "14100" / "1.json"
FIRST = "2026-11-12T09:00:00+09:00"
LATER = "2026-11-13T09:00:00+09:00"


def yokohama() -> dict:
    return json.loads(EXAMPLE.read_text(encoding="utf-8"))


def setagaya() -> dict:
    """A second municipality without wards, made from the example."""
    bundle = yokohama()
    rename = {a["id"]: f"13112-{a['id'].split('-')[1]}" for a in bundle["areas"]}
    bundle["municipality"] |= {"id": "13112", "prefecture_code": "13"}
    bundle["municipality"]["names"] = {"ja": "世田谷区", "kana": "せたがやく", "en": "Setagaya City"}
    del bundle["wards"]
    for area in bundle["areas"]:
        area["id"] = rename[area["id"]]
        del area["ward_id"]
    for group in (bundle["calendars"], bundle["exceptions"]):
        for item in group:
            if "area_ids" in item:
                item["area_ids"] = [rename[a] for a in item["area_ids"]]
    assert validate.validate_bundle(bundle) == []
    return bundle


def run(store: publish.DirStore, local: dict, now: str = FIRST) -> publish.Plan:
    result = publish.plan(local, store.get, now)
    publish.publish(result, store.put)
    return result


def manifest(store: publish.DirStore) -> dict:
    return json.loads(store.get("manifest.json"))


def files(root: Path) -> list[str]:
    return sorted(str(p.relative_to(root)) for p in root.rglob("*") if p.is_file())


@pytest.fixture
def store(tmp_path):
    return publish.DirStore(tmp_path)


def test_first_publish_writes_version_1_and_a_valid_manifest(store, tmp_path):
    result = run(store, {"14100": yokohama(), "13112": setagaya()})
    assert files(tmp_path) == ["bundles/13112/1.json", "bundles/14100/1.json", "manifest.json"]
    assert [path for path, _ in result.uploads] == ["/bundles/13112/1.json", "/bundles/14100/1.json"]
    assert validate.validate_manifest(manifest(store), tmp_path) == []

    entry = {m["id"]: m for m in manifest(store)["municipalities"]}["14100"]
    data = store.get("bundles/14100/1.json")
    assert entry["bundles"] == [
        {
            "schema_version": 1,
            "bundle_version": 1,
            "path": "/bundles/14100/1.json",
            "sha256": hashlib.sha256(data).hexdigest(),
            "size_bytes": len(data),
            "published_at": FIRST,
        }
    ]
    assert entry["ward_ids"] == ["14117", "14104"] and len(entry["area_ids"]) == 4
    assert "ward_ids" not in {m["id"]: m for m in manifest(store)["municipalities"]}["13112"]
    published = json.loads(data)
    assert published["bundle_version"] == 1 and published["generated_at"] == FIRST


def test_unchanged_bundles_publish_nothing(store, tmp_path):
    local = {"14100": yokohama(), "13112": setagaya()}
    run(store, local)
    before = {name: (tmp_path / name).read_bytes() for name in files(tmp_path)}

    result = run(store, local, LATER)
    assert result.manifest is None and result.uploads == []
    assert {name: (tmp_path / name).read_bytes() for name in files(tmp_path)} == before
    assert result.lines == ["13112: unchanged, stays at version 1", "14100: unchanged, stays at version 1"]


def test_version_and_timestamp_in_the_committed_file_are_not_a_change(store):
    run(store, {"14100": yokohama()})
    restamped = yokohama() | {"bundle_version": 7, "generated_at": LATER}
    assert run(store, {"14100": restamped}, LATER).manifest is None


def test_changing_one_municipality_leaves_the_other_untouched(store, tmp_path):
    run(store, {"14100": yokohama(), "13112": setagaya()})
    before = {m["id"]: m for m in manifest(store)["municipalities"]}

    changed = yokohama()
    changed["rules"][0]["instructions"]["en"] = "Rinse it first."
    result = run(store, {"14100": changed, "13112": setagaya()}, LATER)

    assert [path for path, _ in result.uploads] == ["/bundles/14100/2.json"]
    assert files(tmp_path) == ["bundles/13112/1.json", "bundles/14100/1.json", "bundles/14100/2.json", "manifest.json"]
    after = {m["id"]: m for m in manifest(store)["municipalities"]}
    assert after["13112"] == before["13112"]
    assert after["14100"]["bundles"][0]["bundle_version"] == 2
    assert after["14100"]["bundles"][0]["published_at"] == LATER
    assert json.loads(store.get("bundles/14100/2.json"))["rules"][0]["instructions"]["en"] == "Rinse it first."
    assert (
        json.loads(store.get("bundles/14100/1.json"))["bundle_version"] == 1
    )  # old version stays for cached manifests
    assert validate.validate_manifest(manifest(store), tmp_path) == []


def test_an_invalid_bundle_publishes_nothing_even_for_valid_ones(store, tmp_path):
    run(store, {"14100": yokohama(), "13112": setagaya()})
    before = {name: (tmp_path / name).read_bytes() for name in files(tmp_path)}

    good = yokohama()
    good["rules"][0]["instructions"]["en"] = "Rinse it first."
    bad = setagaya()
    bad["rules"][0]["category"] = "no-such-category"
    with pytest.raises(publish.PublishError, match="13112: .*unknown category 'no-such-category'"):
        run(store, {"14100": good, "13112": bad}, LATER)
    assert {name: (tmp_path / name).read_bytes() for name in files(tmp_path)} == before


def test_a_bundle_that_breaks_the_schema_publishes_nothing(store, tmp_path):
    bad = yokohama()
    del bad["rules"][0]["verified_at"]
    with pytest.raises(publish.PublishError, match="verified_at"):
        run(store, {"14100": bad})
    assert files(tmp_path) == []


def test_manifest_is_not_written_when_a_bundle_upload_fails(store, tmp_path):
    result = publish.plan({"14100": yokohama(), "13112": setagaya()}, store.get, FIRST)

    def failing_put(key, data, cache):
        if key == "bundles/14100/1.json":
            raise publish.PublishError("upload failed")
        store.put(key, data, cache)

    with pytest.raises(publish.PublishError, match="upload failed"):
        publish.publish(result, failing_put)
    assert files(tmp_path) == ["bundles/13112/1.json"]

    # The next run reuses the bundle that did get uploaded and finishes the job.
    retry = run(store, {"14100": yokohama(), "13112": setagaya()}, LATER)
    assert [path for path, _ in retry.uploads] == ["/bundles/14100/1.json"]
    assert json.loads(store.get("bundles/13112/1.json"))["generated_at"] == FIRST
    assert validate.validate_manifest(manifest(store), tmp_path) == []


def test_a_leftover_file_with_other_content_is_skipped_not_overwritten(store, tmp_path):
    run(store, {"14100": yokohama()})
    stale = yokohama() | {"bundle_version": 2}
    stale["rules"][0]["instructions"]["en"] = "An abandoned edit."
    store.put("bundles/14100/2.json", publish.encode(stale), "immutable")

    changed = yokohama()
    changed["rules"][0]["instructions"]["en"] = "Rinse it first."
    result = run(store, {"14100": changed}, LATER)
    assert [path for path, _ in result.uploads] == ["/bundles/14100/3.json"]
    assert manifest(store)["municipalities"][0]["bundles"][0]["bundle_version"] == 3
    assert json.loads(store.get("bundles/14100/2.json"))["rules"][0]["instructions"]["en"] == "An abandoned edit."


def test_municipalities_no_longer_in_the_repo_stay_in_the_manifest(store, tmp_path):
    run(store, {"14100": yokohama(), "13112": setagaya()})
    changed = yokohama()
    changed["rules"][0]["instructions"]["en"] = "Rinse it first."
    run(store, {"14100": changed}, LATER)
    assert [m["id"] for m in manifest(store)["municipalities"]] == ["13112", "14100"]
    assert validate.validate_manifest(manifest(store), tmp_path) == []


def test_other_schema_versions_stay_listed_highest_first(store):
    run(store, {"14100": yokohama()})
    document = manifest(store)
    v2 = copy.deepcopy(document["municipalities"][0]["bundles"][0]) | {
        "schema_version": 2,
        "path": "/bundles/14100/v2/1.json",
    }
    document["municipalities"][0]["bundles"].insert(0, v2)
    store.put("manifest.json", publish.encode(document), "short")
    store.put("bundles/14100/v2/1.json", store.get("bundles/14100/1.json"), "immutable")

    changed = yokohama()
    changed["rules"][0]["instructions"]["en"] = "Rinse it first."
    result = publish.plan({"14100": changed}, store.get, LATER)
    refs = result.manifest["municipalities"][0]["bundles"]
    assert [(r["schema_version"], r["bundle_version"]) for r in refs] == [(2, 1), (1, 2)]


def test_missing_published_bundle_is_an_error(store, tmp_path):
    run(store, {"14100": yokohama()})
    (tmp_path / "bundles/14100/1.json").unlink()
    with pytest.raises(publish.PublishError, match="which is missing"):
        run(store, {"14100": yokohama()}, LATER)


def test_folder_must_match_the_municipality_id(tmp_path):
    folder = tmp_path / "13112"
    folder.mkdir()
    (folder / "bundle.json").write_text(json.dumps(yokohama()), encoding="utf-8")
    with pytest.raises(publish.PublishError, match="does not match its folder 13112"):
        publish.load_local(tmp_path)


def test_command_line_dry_run_then_publish_under_a_prefix(tmp_path, monkeypatch, capsys):
    source, root = tmp_path / "municipalities", tmp_path / "cdn"
    (source / "14100").mkdir(parents=True)
    (source / "14100" / "bundle.json").write_text(json.dumps(yokohama()), encoding="utf-8")
    base = ["publish.py", "--root", str(root), "--municipalities", str(source), "--prefix", "_smoke/publish"]
    base += ["--boundaries", str(tmp_path / "no-boundaries")]
    monkeypatch.delenv("GITHUB_STEP_SUMMARY", raising=False)

    monkeypatch.setattr(sys, "argv", [*base, "--dry-run"])
    assert publish.main() == 0
    assert "Dry run under _smoke/publish/: nothing uploaded" in capsys.readouterr().out
    assert not root.exists()

    monkeypatch.setattr(sys, "argv", base)
    assert publish.main() == 0
    assert "14100: version 1 (first publish)" in capsys.readouterr().out
    assert files(root) == ["_smoke/publish/bundles/14100/1.json", "_smoke/publish/manifest.json"]
    assert (
        validate.validate_manifest(
            json.loads((root / "_smoke/publish/manifest.json").read_bytes()), root / "_smoke/publish"
        )
        == []
    )

    assert publish.main() == 0
    assert "Nothing to publish under _smoke/publish/" in capsys.readouterr().out


def kanagawa() -> dict:
    """A one-square boundary package."""
    arcs = [[[0, 0], [999, 0], [0, 999], [-999, 0], [0, -999]]]
    area = {"type": "Polygon", "id": "14117-100001", "properties": {"name": "青葉台一丁目"}, "arcs": [[0]]}
    return {
        "schema_version": 1,
        "prefecture_code": "14",
        "version": 1,
        "generated_at": FIRST,
        "attribution": [{"text": {"ja": "出典", "en": "Source"}, "license": "LicenseRef-Test"}],
        "bbox": [139.5, 35.5, 139.6, 35.6],
        "municipalities": {"14117": {"ja": "横浜市青葉区"}},
        "topology": {
            "type": "Topology",
            "transform": {"scale": [0.0001, 0.0001], "translate": [139.5, 35.5]},
            "objects": {"areas": {"type": "GeometryCollection", "geometries": [area]}},
            "arcs": arcs,
        },
    }


def test_boundaries_are_published_and_listed_in_the_manifest(store, tmp_path):
    result = publish.plan({"14100": yokohama()}, store.get, FIRST, {"14": kanagawa()})
    publish.publish(result, store.put)
    assert files(tmp_path) == ["boundaries/14/1.json", "bundles/14100/1.json", "manifest.json"]
    data = store.get("boundaries/14/1.json")
    assert manifest(store)["boundaries"] == [
        {
            "prefecture_code": "14",
            "schema_version": 1,
            "version": 1,
            "path": "/boundaries/14/1.json",
            "bbox": [139.5, 35.5, 139.6, 35.6],
            "sha256": hashlib.sha256(data).hexdigest(),
            "size_bytes": len(data),
            "published_at": FIRST,
        }
    ]
    assert validate.validate_manifest(manifest(store), tmp_path) == []


def test_adding_boundaries_later_leaves_bundles_untouched_and_the_reverse(store, tmp_path):
    run(store, {"14100": yokohama()})
    before = manifest(store)["municipalities"]
    assert "boundaries" not in manifest(store)

    added = publish.plan({"14100": yokohama()}, store.get, LATER, {"14": kanagawa()})
    publish.publish(added, store.put)
    assert [path for path, _ in added.uploads] == ["/boundaries/14/1.json"]
    assert manifest(store)["municipalities"] == before
    assert added.lines[0] == "14100: unchanged, stays at version 1"
    assert added.lines[1].startswith("boundaries 14: version 1 (first publish), ")

    again = publish.plan({"14100": yokohama()}, store.get, LATER, {"14": kanagawa() | {"version": 9}})
    assert again.manifest is None and again.uploads == []

    changed = yokohama()
    changed["rules"][0]["instructions"]["en"] = "Rinse it first."
    bundle_only = publish.plan({"14100": changed}, store.get, LATER, {"14": kanagawa()})
    publish.publish(bundle_only, store.put)
    assert [path for path, _ in bundle_only.uploads] == ["/bundles/14100/2.json"]
    assert manifest(store)["boundaries"][0]["version"] == 1
    assert validate.validate_manifest(manifest(store), tmp_path) == []


def test_changed_boundaries_get_the_next_version(store):
    publish.publish(publish.plan({"14100": yokohama()}, store.get, FIRST, {"14": kanagawa()}), store.put)
    moved = kanagawa()
    moved["topology"]["arcs"][0][1] = [998, 0]
    result = publish.plan({"14100": yokohama()}, store.get, LATER, {"14": moved})
    publish.publish(result, store.put)
    assert [path for path, _ in result.uploads] == ["/boundaries/14/2.json"]
    assert manifest(store)["boundaries"][0]["version"] == 2
    assert json.loads(store.get("boundaries/14/2.json"))["version"] == 2


def test_invalid_boundaries_publish_nothing(store, tmp_path):
    bad = kanagawa()
    bad["topology"]["objects"]["areas"]["geometries"][0]["arcs"] = [[5]]
    with pytest.raises(publish.PublishError, match="boundaries 14: .*arc that does not exist"):
        publish.plan({"14100": yokohama()}, store.get, FIRST, {"14": bad})
    assert files(tmp_path) == []


def test_boundary_file_name_must_match_the_prefecture(tmp_path):
    (tmp_path / "13.json").write_text(json.dumps(kanagawa()), encoding="utf-8")
    with pytest.raises(publish.PublishError, match="does not match its file name 13"):
        publish.load_boundaries(tmp_path)


def test_the_repo_files_would_publish_cleanly(tmp_path):
    store = publish.DirStore(tmp_path)
    local, boundaries = publish.load_local(publish.MUNICIPALITIES_DIR), publish.load_boundaries(publish.BOUNDARIES_DIR)
    result = publish.plan(local, store.get, FIRST, boundaries)
    publish.publish(result, store.put)
    assert sorted(result.manifest) == ["boundaries", "generated_at", "municipalities", "schema_version"]
    assert validate.validate_manifest(manifest(store), tmp_path) == []


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q", *sys.argv[1:]]))
