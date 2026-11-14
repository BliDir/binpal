-- Per-install use counters. Install ids are random UUIDs the app makes; rows
-- are deleted after two days by the scheduled cleanup.
CREATE TABLE usage (
  install_id TEXT NOT NULL,
  day TEXT NOT NULL,         -- YYYY-MM-DD in Japan
  kind TEXT NOT NULL,        -- 'identify' or 'report'
  count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (install_id, day, kind)
) WITHOUT ROWID;

-- AI spend per Japan day, for the daily budget switch.
CREATE TABLE spend (
  day TEXT PRIMARY KEY,
  micro_usd INTEGER NOT NULL DEFAULT 0,
  calls INTEGER NOT NULL DEFAULT 0
);

-- One row per photo-check request that reached the API: which on-device
-- labels needed help and what the answer was, to grow the alias table.
-- No photo, photo hash or install id. Kept 90 days.
CREATE TABLE ai_log (
  id INTEGER PRIMARY KEY,
  day TEXT NOT NULL,
  area_id TEXT NOT NULL,
  labels TEXT NOT NULL,      -- JSON array
  candidate_count INTEGER NOT NULL,
  source TEXT NOT NULL,      -- 'model' or 'cache'
  outcome TEXT NOT NULL,     -- 'item', 'category', or why there was no answer
  item_id TEXT,
  category TEXT,
  confidence REAL,
  model TEXT NOT NULL,
  input_tokens INTEGER NOT NULL,
  cache_write_tokens INTEGER NOT NULL,
  cache_read_tokens INTEGER NOT NULL,
  output_tokens INTEGER NOT NULL,
  micro_usd INTEGER NOT NULL,
  duration_ms INTEGER NOT NULL,
  app_version TEXT
);
CREATE INDEX ai_log_day ON ai_log (day);

-- "This looks wrong" reports, for the review queue (DAI-581).
CREATE TABLE reports (
  id INTEGER PRIMARY KEY,
  day TEXT NOT NULL,
  area_id TEXT NOT NULL,
  item_id TEXT,
  kind TEXT NOT NULL,
  note TEXT,
  app_version TEXT
);
