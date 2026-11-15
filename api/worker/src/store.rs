//! D1: per-install counters, the daily spend, the tuning log and reports.
//! Photos are never written anywhere. Install ids are kept only in the
//! counters, which the daily cleanup removes after two days.

use binpal_api_core::ApiError;
use worker::{D1Database, console_error, query};

fn db_error(e: worker::Error) -> ApiError {
    console_error!("D1: {e}");
    ApiError::internal()
}

/// Counts one more use of `kind` by this install today and returns the new
/// count. A single statement, so concurrent requests can't both slip under
/// the limit.
pub async fn count_use(
    db: &D1Database,
    install_id: &str,
    day: &str,
    kind: &str,
) -> Result<u32, ApiError> {
    let count: Option<f64> = query!(
        db,
        "INSERT INTO usage (install_id, day, kind, count) VALUES (?1, ?2, ?3, 1)
         ON CONFLICT (install_id, day, kind) DO UPDATE SET count = count + 1
         RETURNING count",
        install_id,
        day,
        kind,
    )
    .map_err(db_error)?
    .first(Some("count"))
    .await
    .map_err(db_error)?;
    Ok(count.unwrap_or(0.0) as u32)
}

/// AI spend so far today, in millionths of a dollar.
pub async fn spent(db: &D1Database, day: &str) -> Result<u64, ApiError> {
    let spent: Option<f64> = query!(db, "SELECT micro_usd FROM spend WHERE day = ?1", day)
        .map_err(db_error)?
        .first(Some("micro_usd"))
        .await
        .map_err(db_error)?;
    Ok(spent.unwrap_or(0.0) as u64)
}

pub async fn add_spend(db: &D1Database, day: &str, micro_usd: u64) -> Result<(), ApiError> {
    query!(
        db,
        "INSERT INTO spend (day, micro_usd, calls) VALUES (?1, ?2, 1)
         ON CONFLICT (day) DO UPDATE SET micro_usd = micro_usd + excluded.micro_usd,
         calls = calls + 1",
        day,
        micro_usd as f64,
    )
    .map_err(db_error)?
    .run()
    .await
    .map_err(db_error)?;
    Ok(())
}

/// Workers AI Neurons used so far on a UTC day.
pub async fn neurons_used(db: &D1Database, utc_day: &str) -> Result<u64, ApiError> {
    let used: Option<f64> = query!(db, "SELECT neurons FROM neurons WHERE day = ?1", utc_day)
        .map_err(db_error)?
        .first(Some("neurons"))
        .await
        .map_err(db_error)?;
    Ok(used.unwrap_or(0.0) as u64)
}

pub async fn add_neurons(db: &D1Database, utc_day: &str, neurons: u64) -> Result<(), ApiError> {
    query!(
        db,
        "INSERT INTO neurons (day, neurons, calls) VALUES (?1, ?2, 1)
         ON CONFLICT (day) DO UPDATE SET neurons = neurons + excluded.neurons,
         calls = calls + 1",
        utc_day,
        neurons as f64,
    )
    .map_err(db_error)?
    .run()
    .await
    .map_err(db_error)?;
    Ok(())
}

/// One answer from the cache or one model call, for tuning the alias table
/// and measuring cost: which on-device labels needed AI and what came back.
/// No photo, no photo hash and no install id.
pub struct CallLog<'a> {
    pub day: &'a str,
    pub area_id: &'a str,
    pub labels: &'a [String],
    pub candidate_count: usize,
    /// 'cache', 'workers_ai' or 'anthropic'.
    pub source: &'a str,
    pub model: &'a str,
    /// For an Anthropic call: why Workers AI didn't answer.
    pub fallback: Option<&'a str>,
    pub outcome: &'a str,
    pub item_id: Option<&'a str>,
    pub category: Option<&'a str>,
    pub confidence: Option<f64>,
    pub input_tokens: u64,
    pub cache_write_tokens: u64,
    pub cache_read_tokens: u64,
    pub output_tokens: u64,
    pub neurons: u64,
    pub micro_usd: u64,
    pub duration_ms: u64,
    pub app_version: Option<&'a str>,
}

pub async fn log_call(db: &D1Database, log: &CallLog<'_>) -> Result<(), ApiError> {
    let labels = serde_json::to_string(log.labels).unwrap_or_default();
    query!(
        db,
        "INSERT INTO ai_log (day, area_id, labels, candidate_count, source, model, fallback,
         outcome, item_id, category, confidence, input_tokens, cache_write_tokens,
         cache_read_tokens, output_tokens, neurons, micro_usd, duration_ms, app_version)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17,
         ?18, ?19)",
        log.day,
        log.area_id,
        labels,
        log.candidate_count as f64,
        log.source,
        log.model,
        log.fallback,
        log.outcome,
        log.item_id,
        log.category,
        log.confidence,
        log.input_tokens as f64,
        log.cache_write_tokens as f64,
        log.cache_read_tokens as f64,
        log.output_tokens as f64,
        log.neurons as f64,
        log.micro_usd as f64,
        log.duration_ms as f64,
        log.app_version,
    )
    .map_err(db_error)?
    .run()
    .await
    .map_err(db_error)?;
    Ok(())
}

pub struct ReportRow<'a> {
    pub day: &'a str,
    pub area_id: &'a str,
    pub item_id: Option<&'a str>,
    pub kind: &'a str,
    pub note: Option<&'a str>,
    pub app_version: Option<&'a str>,
}

pub async fn add_report(db: &D1Database, report: &ReportRow<'_>) -> Result<(), ApiError> {
    query!(
        db,
        "INSERT INTO reports (day, area_id, item_id, kind, note, app_version)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        report.day,
        report.area_id,
        report.item_id,
        report.kind,
        report.note,
        report.app_version,
    )
    .map_err(db_error)?
    .run()
    .await
    .map_err(db_error)?;
    Ok(())
}

/// Drops counters older than `keep_usage_from` and log rows and Neuron
/// totals older than `keep_log_from` (both `YYYY-MM-DD`).
pub async fn clean_up(
    db: &D1Database,
    keep_usage_from: &str,
    keep_log_from: &str,
) -> Result<(), ApiError> {
    let statements = vec![
        query!(db, "DELETE FROM usage WHERE day < ?1", keep_usage_from).map_err(db_error)?,
        query!(db, "DELETE FROM ai_log WHERE day < ?1", keep_log_from).map_err(db_error)?,
        query!(db, "DELETE FROM neurons WHERE day < ?1", keep_log_from).map_err(db_error)?,
    ];
    db.batch(statements).await.map_err(db_error)?;
    Ok(())
}
