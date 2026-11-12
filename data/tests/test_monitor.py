#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["beautifulsoup4>=4.12", "httpx>=0.27", "pypdf>=5", "pyyaml>=6", "pytest>=8"]
# ///
"""Tests for the rule monitor, against fixture sources served by a fake transport.

Usage:
    uv run data/tests/test_monitor.py
"""

from __future__ import annotations

import sys
from datetime import date, timedelta
from pathlib import Path

import httpx
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import monitor

TODAY = date(2026, 11, 11)
PAGE_URL = "https://city.example/gomi/days.html"
PDF_URL = "https://city.example/gomi/guide.pdf"
CKAN_URL = "https://data.example/api/3/action/package_show?id=gomi"
FILE_URL = "https://data.example/files/gomi.csv"


def page(days: str = "火曜日・土曜日", updated: str = "2026年1月23日") -> bytes:
    return f"""<html><head><meta charset="UTF-8"><script>var a = 1;</script></head><body>
<nav><a href="/">ホーム</a></nav>
<div id="main">
  <h1>収集曜日</h1>
  <p id="update">最終更新日 {updated}</p>
  <table>
    <tr><th>町名</th><th>燃やすごみ</th></tr>
    <tr><td>青葉台1・2丁目</td><td>{days}</td></tr>
  </table>
  <p>収集日の朝8時までに<a href="/dasu">出して</a>ください。</p>
</div>
<footer>横浜市役所</footer>
</body></html>""".encode()


def pdf(text: str) -> bytes:
    """A minimal one-page PDF showing `text` (ASCII only)."""
    stream = f"BT /F1 12 Tf 72 720 Td ({text}) Tj ET".encode()
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
        b"<< /Length %d >>\nstream\n%s\nendstream" % (len(stream), stream),
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    out, offsets = b"%PDF-1.4\n", []
    for i, obj in enumerate(objects, 1):
        offsets.append(len(out))
        out += b"%d 0 obj\n%s\nendobj\n" % (i, obj)
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1)
    out += b"".join(b"%010d 00000 n \n" % o for o in offsets)
    out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objects) + 1, xref)
    return out


def ckan(modified: str) -> dict:
    resource = {"id": "r1", "name": "gomi.csv", "format": "CSV", "url": FILE_URL, "last_modified": modified}
    return {"success": True, "result": {"resources": [resource]}}


HTML = monitor.Source(id="days", type="html", url=PAGE_URL, title="収集曜日", selector="#main")
PDF = monitor.Source(id="guide", type="pdf", url=PDF_URL, title="Guide")
CKAN = monitor.Source(id="open-data", type="ckan", url=CKAN_URL, title="Open data", formats=["CSV"])


class Site:
    """Fixture web server: maps URLs to a body, a JSON document or an HTTP status."""

    def __init__(self, **routes):
        self.routes = routes
        self.requests: list[httpx.Request] = []
        self.fetcher = monitor.Fetcher(httpx.Client(transport=httpx.MockTransport(self.handle)), delay=0)

    def handle(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        reply = self.routes[str(request.url)]
        if isinstance(reply, int):
            return httpx.Response(reply)
        if isinstance(reply, dict):
            return httpx.Response(200, json=reply)
        return httpx.Response(200, content=reply)

    def urls(self) -> list[str]:
        return [str(r.url) for r in self.requests]


def check(site: Site, tmp_path: Path, *sources: monitor.Source, today: date = TODAY) -> list[monitor.Issue]:
    return monitor.run(list(sources), tmp_path, site.fetcher, today)


def test_first_run_stores_a_baseline_without_an_issue(tmp_path):
    site = Site(**{PAGE_URL: page()})
    assert check(site, tmp_path, HTML) == []
    text = (tmp_path / "days.txt").read_text()
    assert "青葉台1・2丁目 | 火曜日・土曜日" in text
    assert "収集日の朝8時までに出してください。" in text
    for noise in ("ホーム", "横浜市役所", "var a", "最終更新日"):
        assert noise not in text


def test_changed_source_opens_exactly_one_issue_and_unchanged_run_none(tmp_path):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)
    assert check(site, tmp_path, HTML) == []

    site.routes[PAGE_URL] = page(days="月曜日・金曜日")
    issues = check(site, tmp_path, HTML)
    assert [i.title for i in issues] == ["Rule source changed: days"]
    assert PAGE_URL in issues[0].body
    assert "-青葉台1・2丁目 | 火曜日・土曜日" in issues[0].body
    assert "+青葉台1・2丁目 | 月曜日・金曜日" in issues[0].body

    assert check(site, tmp_path, HTML) == []


def test_last_updated_date_alone_opens_no_issue(tmp_path):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)
    before = (tmp_path / "days.txt").read_text()
    site.routes[PAGE_URL] = page(updated="2026年11月10日")
    assert check(site, tmp_path, HTML) == []
    assert (tmp_path / "days.txt").read_text() == before


def test_source_ignore_patterns_drop_lines(tmp_path):
    source = monitor.Source(
        id="days", type="html", url=PAGE_URL, title="t", selector="#main", ignore=[monitor.re.compile("朝8時")]
    )
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, source)
    assert "朝8時" not in (tmp_path / "days.txt").read_text()


def test_fetch_failure_is_reported_once_after_three_runs(tmp_path):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)

    site.routes[PAGE_URL] = 503
    assert check(site, tmp_path, HTML) == []
    assert check(site, tmp_path, HTML) == []
    issues = check(site, tmp_path, HTML)
    assert [i.title for i in issues] == ["Rule source unreachable: days"]
    assert "503" in issues[0].body
    assert check(site, tmp_path, HTML) == []
    assert check(site, tmp_path, HTML) == []

    # A good run resets the count, and the unchanged page opens nothing.
    site.routes[PAGE_URL] = page()
    assert check(site, tmp_path, HTML) == []
    site.routes[PAGE_URL] = 503
    assert check(site, tmp_path, HTML) == []
    assert check(site, tmp_path, HTML) == []
    assert len(check(site, tmp_path, HTML)) == 1


def test_missing_selector_counts_as_a_failure_and_keeps_the_snapshot(tmp_path):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)
    before = (tmp_path / "days.txt").read_text()

    site.routes[PAGE_URL] = b"<html><body><div id='redesigned'>new layout</div></body></html>"
    assert check(site, tmp_path, HTML) == []
    assert (tmp_path / "days.txt").read_text() == before
    check(site, tmp_path, HTML)
    issues = check(site, tmp_path, HTML)
    assert [i.title for i in issues] == ["Rule source unreachable: days"]
    assert "matched nothing" in issues[0].body


def test_one_failing_source_does_not_stop_the_others(tmp_path):
    site = Site(**{PAGE_URL: 500, PDF_URL: pdf("Burnable: Tuesday")})
    assert check(site, tmp_path, HTML, PDF) == []
    assert (tmp_path / "guide.txt").exists()


def test_pdf_text_change_opens_an_issue(tmp_path):
    site = Site(**{PDF_URL: pdf("Burnable: Tuesday")})
    check(site, tmp_path, PDF)
    assert "Burnable: Tuesday" in (tmp_path / "guide.txt").read_text()
    assert check(site, tmp_path, PDF) == []

    site.routes[PDF_URL] = pdf("Burnable: Friday")
    issues = check(site, tmp_path, PDF)
    assert [i.title for i in issues] == ["Rule source changed: guide"]
    assert "+Burnable: Friday" in issues[0].body


def test_ckan_downloads_only_when_last_modified_moves(tmp_path):
    site = Site(**{CKAN_URL: ckan("2026-04-01T00:00:00"), FILE_URL: b"item,category\ncan,cans\n"})
    assert check(site, tmp_path, CKAN) == []
    assert site.urls() == [CKAN_URL, FILE_URL]

    site.requests.clear()
    assert check(site, tmp_path, CKAN) == []
    assert site.urls() == [CKAN_URL]

    # Re-uploaded with the same bytes: downloaded again, but nothing to report.
    site.requests.clear()
    site.routes[CKAN_URL] = ckan("2026-05-01T00:00:00")
    assert check(site, tmp_path, CKAN) == []
    assert site.urls() == [CKAN_URL, FILE_URL]

    site.routes[CKAN_URL] = ckan("2026-06-01T00:00:00")
    site.routes[FILE_URL] = b"item,category\ncan,metal\n"
    issues = check(site, tmp_path, CKAN)
    assert [i.title for i in issues] == ["Rule source changed: open-data"]


def test_requests_identify_the_monitor(tmp_path):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)
    assert site.requests[0].headers["user-agent"] == monitor.USER_AGENT
    assert "github.com/BliDir/binpal" in monitor.USER_AGENT


def test_fetcher_waits_between_requests(monkeypatch):
    slept = []
    monkeypatch.setattr(monitor.time, "sleep", slept.append)
    site = Site(**{PAGE_URL: page()})
    site.fetcher.delay = 2.0
    site.fetcher.get(PAGE_URL)
    site.fetcher.get(PAGE_URL)
    assert len(slept) == 1 and 1.5 < slept[0] <= 2.0


def state(tmp_path: Path) -> dict:
    return monitor.json.loads((tmp_path / "state.json").read_text())


def test_heartbeat_changes_state_only_every_30_days(tmp_path):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)
    assert state(tmp_path)["heartbeat"] == TODAY.isoformat()
    first = (tmp_path / "state.json").read_bytes()

    check(site, tmp_path, HTML, today=TODAY + timedelta(days=29))
    assert (tmp_path / "state.json").read_bytes() == first

    later = TODAY + timedelta(days=30)
    check(site, tmp_path, HTML, today=later)
    assert state(tmp_path)["heartbeat"] == later.isoformat()


def test_only_leaves_other_sources_alone(tmp_path):
    site = Site(**{PAGE_URL: page(), PDF_URL: pdf("Burnable: Tuesday")})
    monitor.run([HTML, PDF], tmp_path, site.fetcher, TODAY, only={"guide"})
    assert site.urls() == [PDF_URL]
    assert not (tmp_path / "days.txt").exists()


def test_long_diff_is_cut_to_fit_an_issue():
    old = "".join(f"line {i}\n" for i in range(20_000))
    new = "".join(f"row {i}\n" for i in range(20_000))
    issue = monitor.change_issue(HTML, old, new, TODAY)
    assert len(issue.body) < 65_536
    assert "cut short" in issue.body


def test_open_issues_comments_when_the_issue_is_already_open(monkeypatch):
    calls = []

    def fake_gh(*args, stdin=None):
        calls.append(args)
        if args[:2] == ("issue", "list"):
            return '[{"number": 7, "title": "Rule source changed: days"}]'
        return "https://github.com/BliDir/binpal/issues/8\n"

    monkeypatch.setattr(monitor, "gh", fake_gh)
    monitor.open_issues([monitor.Issue("Rule source changed: days", "a"), monitor.Issue("Rule source changed: x", "b")])
    assert [c[:2] for c in calls] == [("label", "create"), ("issue", "list"), ("issue", "comment"), ("issue", "create")]
    assert calls[2][2] == "7"


def write_sources(tmp_path: Path, text: str) -> Path:
    path = tmp_path / "sources.yaml"
    path.write_text(text)
    return path


@pytest.mark.parametrize(
    ("entry", "message"),
    [
        ("{id: a, type: html, url: 'https://x.example', title: t}", "need a selector"),
        ("{id: A b, type: pdf, url: 'https://x.example', title: t}", "lowercase slug"),
        ("{id: a, type: rss, url: 'https://x.example', title: t}", "type must be"),
        ("{id: a, type: pdf, url: 'ftp://x.example', title: t}", "http"),
        ("{id: a, type: pdf, url: 'https://x.example'}", "title is required"),
        ("{id: a, type: pdf, url: 'https://x.example', title: t, selecter: x}", "unknown keys"),
    ],
)
def test_bad_sources_are_rejected(tmp_path, entry, message):
    with pytest.raises(monitor.SourceError, match=message):
        monitor.load_sources(write_sources(tmp_path, f"sources:\n  - {entry}\n"))


def test_duplicate_ids_are_rejected(tmp_path):
    entry = "  - {id: a, type: pdf, url: 'https://x.example', title: t}\n"
    with pytest.raises(monitor.SourceError, match="duplicate id"):
        monitor.load_sources(write_sources(tmp_path, "sources:\n" + entry + entry))


def test_repo_sources_file_is_valid_and_has_a_snapshot_for_every_source():
    sources = monitor.load_sources(monitor.DATA_DIR / "sources.yaml")
    assert sources
    for source in sources:
        assert (monitor.DATA_DIR / "snapshots" / f"{source.id}.txt").is_file(), source.id


NEWS = monitor.Source(id="news", type="news", url=PAGE_URL, title="News", selector="#main")


def test_news_match_opens_issue_on_first_run_and_only_for_new_entries(tmp_path):
    site = Site(
        **{
            PAGE_URL: """<meta charset="UTF-8"><div id="main"><ul>
      <li><a href="/rules">4月からごみの収集曜日を変更します</a></li>
      <li><a href="/park">公園が新しくなります</a></li>
      <li><a href="/sort">ごみの分別方法</a></li></ul></div>""".encode()
        }
    )
    issues = check(site, tmp_path, NEWS)
    assert len(issues) == 1
    assert "https://city.example/rules" in issues[0].body
    assert "公園" not in issues[0].body
    assert check(site, tmp_path, NEWS) == []
    site.routes[PAGE_URL] = b'<div id="main"><ul></ul></div>'
    assert check(site, tmp_path, NEWS) == []


def test_llm_cosmetic_skips_issue_but_updates_snapshot(tmp_path, capsys):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)
    site.routes[PAGE_URL] = page(days="毎週火曜日・土曜日")

    class Cosmetic:
        def summarize(self, source, old, new):
            assert "毎週" not in old and "毎週" in new
            return monitor.Summary("Wording only", "cosmetic", "Not stated", True)

    assert monitor.run([HTML], tmp_path, site.fetcher, TODAY, summarizer=Cosmetic()) == []
    assert "毎週" in (tmp_path / "days.txt").read_text()
    assert "cosmetic days" in capsys.readouterr().out


def test_llm_failure_keeps_alert(tmp_path):
    site = Site(**{PAGE_URL: page()})
    check(site, tmp_path, HTML)
    site.routes[PAGE_URL] = page(days="水曜日")

    class Broken:
        def summarize(self, *args):
            raise monitor.SourceError("unavailable")

    issues = monitor.run([HTML], tmp_path, site.fetcher, TODAY, summarizer=Broken())
    assert len(issues) == 1
    assert "LLM unavailable" in issues[0].body
    assert "+青葉台" in issues[0].body


def test_summary_above_raw_diff():
    summary = monitor.Summary("Collection changes to Friday", "schedule", "2027-04-01", False)
    issue = monitor.change_issue(HTML, "Tuesday", "Friday", TODAY, summary)
    assert issue.body.index(summary.summary) < issue.body.index("````diff")
    assert "**Effective date:** 2027-04-01" in issue.body


@pytest.mark.parametrize("failure", [429, 503, 404, "invalid", "truncated"])
def test_gemini_falls_back_and_validates_response(monkeypatch, failure):
    monkeypatch.setattr(monitor.time, "sleep", lambda _: None)
    requests = []
    result = {"summary": "Days changed", "change_type": "schedule", "effective_date": "Not stated", "cosmetic": False}

    def handle(request):
        requests.append(request)
        if "gemini-3.5" in str(request.url):
            if isinstance(failure, int):
                return httpx.Response(failure)
            return httpx.Response(
                200,
                json={
                    "candidates": [
                        {
                            "finishReason": "MAX_TOKENS" if failure == "truncated" else "STOP",
                            "content": {"parts": [{"text": "{}"}]},
                        }
                    ]
                },
            )
        return httpx.Response(
            200,
            json={
                "candidates": [
                    {
                        "finishReason": "STOP",
                        "content": {"parts": [{"text": monitor.json.dumps(result)}]},
                    }
                ]
            },
        )

    llm = monitor.Summarizer("test-secret", httpx.Client(transport=httpx.MockTransport(handle)))
    summary = llm.summarize(HTML, "Tuesday", "Friday")
    assert summary.change_type == "schedule"
    assert "gemini-2.5-flash-lite" in str(requests[-1].url)
    assert requests[-1].headers["x-goog-api-key"] == "test-secret"
    assert "test-secret" not in str(requests[-1].url)
    payload = monitor.json.loads(requests[-1].content)
    assert "Tuesday" in payload["contents"][0]["parts"][0]["text"]


def test_both_models_failing_raises_safe_error(monkeypatch):
    monkeypatch.setattr(monitor.time, "sleep", lambda _: None)
    client = httpx.Client(transport=httpx.MockTransport(lambda _: httpx.Response(403)))
    with pytest.raises(monitor.SourceError, match="both Gemini"):
        monitor.Summarizer("secret", client).summarize(HTML, "a", "b")


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q", *sys.argv[1:]]))
