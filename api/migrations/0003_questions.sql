-- Plain-language questions (DAI-580) share the AI log with photo check.
-- Question rows log the candidate count and the cited rule, never the
-- question itself.
ALTER TABLE ai_log ADD COLUMN kind TEXT NOT NULL DEFAULT 'photo'; -- 'photo' or 'question'
