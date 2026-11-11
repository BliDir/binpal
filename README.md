# BinPal

Fast, light Flutter app that tells people in Japan how to sort garbage and when to put it out, with first-class support for foreign residents.

| Folder | Contents |
| -- | -- |
| `app/` | Flutter app |
| `data/` | sources.yaml, JSON Schemas, snapshots, extraction and publisher scripts |
| `api/` | Thin API (v2) |
| `.github/workflows/` | CI, rule monitor, publisher |

## CI

Each folder has its own workflow, run on pull requests that touch it:

| Workflow | Runs on | Checks |
| -- | -- | -- |
| `app.yml` | `app/**` | format, analyze, tests |
| `data.yml` | `data/**` | ruff, shellcheck, schema and example validation, script tests |
| `rule-monitor.yml` | daily schedule | watches the sources for rule changes ([details](data/README.md#rule-monitor)) |

## License

Code is released under the [MIT License](LICENSE). Municipal data in published bundles keeps its source's terms; each bundle lists the credits it requires.
