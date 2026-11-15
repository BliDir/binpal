-- "This looks wrong" reports go to the review queue (DAI-581): a collection
-- date for wrong-day reports, and the GitHub issue each report was filed on.
ALTER TABLE reports ADD COLUMN date TEXT;          -- YYYY-MM-DD in Japan
ALTER TABLE reports ADD COLUMN issue_number INTEGER; -- null until filed

CREATE INDEX reports_unfiled ON reports (id) WHERE issue_number IS NULL;
CREATE INDEX reports_area_day ON reports (area_id, day);

-- One row per group of reports about the same thing (see core/src/review.rs)
-- and the issue they share. A closed issue gets a new one on the next report.
CREATE TABLE report_issues (
  group_key TEXT PRIMARY KEY,
  issue_number INTEGER NOT NULL,
  reports INTEGER NOT NULL,
  priority INTEGER NOT NULL DEFAULT 0
);
