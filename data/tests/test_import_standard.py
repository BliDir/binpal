#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["beautifulsoup4>=4.12", "httpx>=0.27", "pypdf>=5", "pyyaml>=6", "jsonschema[format-nongpl]>=4.23", "pytest>=8"]
# ///
"""Offline importer tests, including the complete committed Arakawa dataset."""

from __future__ import annotations

import csv
import io
import json
import shutil
import sys
from pathlib import Path

import httpx
import pytest
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import import_standard as importer
import monitor
import publish
import validate

PILOT = Path(__file__).resolve().parent.parent / "imports" / "13118"


def inputs():
    config = yaml.safe_load((PILOT / "config.yaml").read_text())
    base = json.loads((PILOT / "base.json").read_text())
    raw = (PILOT / "source" / "sorting.csv").read_bytes()
    rows = importer.parse_csv(raw, base["municipality"])
    translations = importer.read_translations(PILOT / "items.tsv")
    package = json.loads((PILOT / "source" / "package.json").read_text())
    resource = importer.resource_metadata(package, config)
    return config, base, rows, translations, package, resource


def encode(rows, encoding="utf-8-sig"):
    out = io.StringIO(newline="")
    writer = csv.DictWriter(out, fieldnames=importer.COLUMNS)
    writer.writeheader()
    writer.writerows(rows)
    return out.getvalue().encode(encoding)


def test_complete_pilot_rebuilds_offline_and_preserves_all_japanese_fields(tmp_path):
    directory = tmp_path / "pilot"
    shutil.copytree(PILOT, directory)
    bundle = importer.run(directory)
    assert validate.validate_bundle(bundle) == []
    assert json.loads((PILOT / "bundle.json").read_text()) == bundle
    config, base, rows, *_ = inputs()
    assert len(bundle["rules"]) == len(rows) == 223
    assert bundle["areas"] == base["areas"]
    assert bundle["calendars"] == base["calendars"]
    assert bundle["exceptions"] == base["exceptions"]
    for row, rule in zip(rows, bundle["rules"], strict=True):
        assert rule["names"]["ja"] == row["ゴミの品目"]
        assert rule["category"] == config["categories"][row["分別区分"]]
        for key in importer.COLUMNS[5:]:
            if row[key]:
                assert f"{key}: {row[key]}" in rule["instructions"]["ja"]
    by_id = {r["item_id"]: r for r in bundle["rules"]}
    assert by_id["13118-131181s00058"]["names"]["en"] == "Butane gas cartridge"
    assert "Do not puncture" in by_id["13118-131181s00058"]["instructions"]["en"]
    assert "Insulate both terminals" in by_id["13118-131181s00168"]["instructions"]["en"]
    assert "syringe needle" in by_id["13118-131181s00016"]["aliases"]


@pytest.mark.parametrize("encoding", ["utf-8-sig", "utf-8", "cp932"])
def test_standard_csv_encodings_and_quoted_fields(encoding):
    _, base, rows, *_ = inputs()
    row = rows[0] | {"注意点": 'Comma, quote " and\nnew line'}
    assert importer.parse_csv(encode([row], encoding), base["municipality"]) == [row]


def test_importer_reuses_standard_format_for_a_different_municipality():
    config, base, rows, translations, _, resource = inputs()
    base["municipality"] = {
        "id": "14100",
        "prefecture_code": "14",
        "names": {"ja": "横浜市", "kana": "ヨコハマシ", "en": "Yokohama City"},
    }
    base["areas"][0]["id"] = "14100-001001"
    base["calendars"] = []
    row = rows[0] | {"全国地方公共団体コード": "141003", "地方公共団体名": "横浜市", "ID": "A001"}
    parsed = importer.parse_csv(encode([row]), base["municipality"])
    translation = translations[rows[0]["ID"]] | {"source_sha256": importer.row_digest(row)}
    bundle = importer.build(base, parsed, {"A001": translation}, config, resource)
    assert bundle["rules"][0]["item_id"] == "14100-a001"


@pytest.mark.parametrize("change", ["code", "check_digit", "name", "duplicate", "empty_item", "empty_id", "empty"])
def test_invalid_sources_fail_before_build(change):
    _, base, rows, *_ = inputs()
    rows = rows[:1]
    if change == "code":
        rows[0]["全国地方公共団体コード"] = "141003"
    elif change == "check_digit":
        rows[0]["全国地方公共団体コード"] = "131180"
    elif change == "name":
        rows[0]["地方公共団体名"] = "別の市"
    elif change == "duplicate":
        rows.append(rows[0])
    elif change == "empty_item":
        rows[0]["ゴミの品目"] = ""
    elif change == "empty_id":
        rows[0]["ID"] = ""
    else:
        rows = []
    with pytest.raises(importer.ImportError):
        importer.parse_csv(encode(rows), base["municipality"])


@pytest.mark.parametrize(
    "raw", [b"ID,name\n1,x\n", b"\xff\xff", (",".join(importer.COLUMNS) + "\n131181,one\n").encode()]
)
def test_unexpected_columns_encoding_and_ragged_rows_fail(raw):
    _, base, *_ = inputs()
    with pytest.raises(importer.ImportError):
        importer.parse_csv(raw, base["municipality"])


@pytest.mark.parametrize("change", ["new", "missing", "renamed", "note", "fee", "category", "no_english", "no_kana"])
def test_translation_and_mapping_drift_never_silently_uses_stale_text(change):
    config, base, rows, translations, _, resource = inputs()
    first = rows[0]
    if change == "new":
        translations["unused"] = translations[first["ID"]]
    elif change == "missing":
        translations.pop(first["ID"])
    elif change in {"renamed", "note", "fee"}:
        key = {"renamed": "ゴミの品目", "note": "備考", "fee": "料金"}[change]
        first[key] += " changed"
    elif change == "category":
        config["categories"].pop(first["分別区分"])
    else:
        translations[first["ID"]]["en" if change == "no_english" else "kana"] = ""
    with pytest.raises(importer.ImportError):
        importer.build(base, rows, translations, config, resource)


@pytest.mark.parametrize("change", ["failure", "package", "licence", "resource", "format", "url"])
def test_catalog_metadata_must_match_the_reviewed_resource(change):
    config, _, _, _, package, _ = inputs()
    p = package["result"]
    if change == "failure":
        package["success"] = False
    elif change == "package":
        p["name"] = "wrong"
    elif change == "licence":
        p["license_id"] = "All rights reserved"
    else:
        resource = p["resources"][0]
        resource[{"resource": "id", "format": "format", "url": "url"}[change]] = "wrong"
    with pytest.raises(importer.ImportError):
        importer.resource_metadata(package, config)


def test_live_refresh_resolves_csv_through_ckan(tmp_path):
    shutil.copytree(PILOT, tmp_path / "pilot")
    directory = tmp_path / "pilot"
    config, _, _, _, package, resource = inputs()
    urls = []

    def handle(request):
        urls.append(str(request.url))
        if request.url.path.endswith("package_show"):
            assert request.url.params["id"] == config["package"]
            return httpx.Response(200, json=package)
        assert str(request.url) == resource["url"]
        return httpx.Response(200, content=(PILOT / "source" / "sorting.csv").read_bytes())

    fetcher = monitor.Fetcher(httpx.Client(transport=httpx.MockTransport(handle)), delay=0)
    importer.run(directory, refresh=True, fetcher=fetcher)
    assert len(urls) == 2


def test_refresh_source_changes_preserve_reviewed_bundle_and_snapshots(tmp_path):
    shutil.copytree(PILOT, tmp_path / "pilot")
    directory = tmp_path / "pilot"
    *_, package, _ = inputs()
    before = {p.relative_to(directory): p.read_bytes() for p in directory.rglob("*") if p.is_file()}

    def handle(request):
        if request.url.path.endswith("package_show"):
            return httpx.Response(200, json=package)
        return httpx.Response(200, content=b"changed CSV")

    fetcher = monitor.Fetcher(httpx.Client(transport=httpx.MockTransport(handle)), delay=0)
    with pytest.raises(importer.ImportError, match="sorting CSV changed"):
        importer.run(directory, refresh=True, fetcher=fetcher)
    assert before == {p.relative_to(directory): p.read_bytes() for p in directory.rglob("*") if p.is_file()}


def test_schema_invalid_base_and_duplicate_translation_fail(tmp_path):
    config, base, rows, translations, _, resource = inputs()
    base["calendars"][0]["categories"] = ["unknown"]
    with pytest.raises(importer.ImportError, match="invalid imported bundle"):
        importer.build(base, rows, translations, config, resource)
    path = tmp_path / "items.tsv"
    path.write_text("id\ten\n1\tx\n1\ty\n")
    with pytest.raises(importer.ImportError, match="duplicate"):
        importer.read_translations(path)


def test_future_rollout_pilot_is_not_in_publisher_input():
    assert "13118" not in publish.load_local(publish.MUNICIPALITIES_DIR)


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q", *sys.argv[1:]]))
