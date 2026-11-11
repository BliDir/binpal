# Data pipeline

Everything that turns municipal pages and files into the bundles the app downloads.

| Path | Contents |
| -- | -- |
| `sources.yaml` | The pages, PDFs and open datasets the data comes from |
| `snapshots/` | Last seen text of every source, written by the rule monitor |
| `schema/` | Bundle and manifest JSON Schemas with examples ([README](schema/README.md)) |
| `cdn/` | How bundles are hosted on Cloudflare R2 ([README](cdn/README.md)) |
| `scripts/` | `monitor.py`, `validate.py`, `cdn_put.sh` |
| `tests/` | Tests for the scripts |

## Rule monitor

Municipalities change sorting rules and collection days without notice. `.github/workflows/rule-monitor.yml` runs `scripts/monitor.py` once a day (06:17 in Japan) to notice.

For each source in `sources.yaml` it:

1. fetches the page or file, at most one request every 2 seconds, with the User-Agent `BinPalRuleMonitor/1.0 (+https://github.com/BliDir/binpal)`;
2. reduces it to plain text: for HTML, the content under the source's CSS `selector`, without scripts, navigation, headers and footers, and one line per table row; for PDFs, the extracted text; for CKAN datasets, each file's name and SHA-256 (a file is only downloaded again when its last-modified date moves);
3. drops lines that change on their own, such as `最終更新日 …`, plus any line matching the source's `ignore` patterns;
4. compares the result with `snapshots/<id>.txt`.

| Outcome | What happens |
| -- | -- |
| Same text | Nothing |
| Different text | The snapshot is committed to `main` and an issue **Rule source changed: `<id>`** is opened with the diff. If that issue is still open from an earlier change, the new diff is added as a comment |
| No snapshot yet | The snapshot is committed as the baseline, with no issue |
| Fetch or parse failure | Counted in `snapshots/state.json`. On the 3rd run in a row an issue **Rule source unreachable: `<id>`** is opened, once. A selector that no longer matches anything counts as a failure, so a redesigned page is not mistaken for a rule change |

Issues carry the `rule-monitor` label.

GitHub disables scheduled workflows in a public repo after 60 days without activity. The monitor rewrites the `heartbeat` date in `snapshots/state.json` every 30 days, so there is a commit even when no source changes.

### Adding a source

Add an entry to `sources.yaml` (the fields are described at the top of the file), then create its baseline and check that the text is the content you expect:

```sh
uv run data/scripts/monitor.py --only <id>
cat data/snapshots/<id>.txt
```

Commit the entry and the snapshot together. If the snapshot contains lines that will change on their own (dates, counters, "related pages" lists), remove them with `strip` or `ignore` and delete the snapshot to regenerate it.

### Running by hand

```sh
uv run data/scripts/monitor.py        # check everything, print the issues it would open
uv run data/tests/test_monitor.py     # tests, against fixture sources
gh workflow run rule-monitor.yml      # run on GitHub, opening real issues
```
