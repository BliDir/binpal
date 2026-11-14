//! The BinPal thin API: the AI fallback for photo check, and reports.
//!
//! `POST /v1/identify` is only called when the phone couldn't identify a
//! photo itself. Each request passes, in order: the size and format checks,
//! a per-install burst limit, a check that BinPal covers the area, the
//! answer cache (free), the daily budget switch, and the per-install daily
//! cap, before the model is called.

mod catalog;
mod config;
mod store;
mod upstream;

use base64::Engine;
use binpal_api_core::ApiError;
use binpal_api_core::answer::{Answer, Outcome, parse_response};
use binpal_api_core::cost::{Usage, micro_usd};
use binpal_api_core::keys::{answer_key, japan_day};
use binpal_api_core::prompt::request_body;
use binpal_api_core::request::{parse_identify, parse_report};
use serde::Serialize;
use worker::*;

use crate::config::Config;

const DAY_MILLIS: u64 = 86_400_000;

/// Answers are kept for 30 days; a new bundle version starts afresh.
const ANSWER_TTL_SECONDS: u64 = 30 * 86_400;

#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    Router::new()
        .get_async("/v1/status", |_, ctx| async move {
            respond(status(&ctx.env).await, 200)
        })
        .post_async("/v1/identify", |mut req, ctx| async move {
            respond(identify(&mut req, &ctx.env).await, 200)
        })
        .post_async("/v1/reports", |mut req, ctx| async move {
            respond(report(&mut req, &ctx.env).await, 201)
        })
        .run(req, env)
        .await
}

/// Daily: drop install counters after two days and log rows after 90.
#[event(scheduled)]
async fn scheduled(_event: ScheduledEvent, env: Env, _ctx: ScheduleContext) {
    let now = Date::now().as_millis();
    let result = async {
        let db = env.d1("DB").map_err(|_| ApiError::internal())?;
        store::clean_up(
            &db,
            &japan_day(now - 2 * DAY_MILLIS),
            &japan_day(now - 90 * DAY_MILLIS),
        )
        .await
    }
    .await;
    if let Err(e) = result {
        console_error!("cleanup failed: {}", e.message);
    }
}

fn respond<T: Serialize>(
    result: std::result::Result<T, ApiError>,
    ok_status: u16,
) -> Result<Response> {
    match result {
        Ok(body) => Ok(Response::from_json(&body)?.with_status(ok_status)),
        Err(e) => Ok(Response::from_json(&e)?.with_status(e.status)),
    }
}

fn binding<T>(result: Result<T>, name: &str) -> std::result::Result<T, ApiError> {
    result.map_err(|e| {
        console_error!("binding {name}: {e}");
        ApiError::internal()
    })
}

#[derive(Serialize)]
struct Status {
    /// "available", or "paused" once today's budget is spent; the app then
    /// stays on-device until the next Japan day.
    ai: &'static str,
}

fn ai_state(available: bool) -> &'static str {
    if available { "available" } else { "paused" }
}

async fn status(env: &Env) -> std::result::Result<Status, ApiError> {
    let config = Config::from_env(env)?;
    let db = binding(env.d1("DB"), "DB")?;
    let spent = store::spent(&db, &japan_day(Date::now().as_millis())).await?;
    Ok(Status {
        ai: ai_state(config.allowance.ai_available(spent)),
    })
}

/// Per-install burst limit (Cloudflare's rate limiting binding).
async fn burst_check(env: &Env, install_id: &str) -> std::result::Result<(), ApiError> {
    let limiter = binding(env.rate_limiter("BURST"), "BURST")?;
    let outcome = binding(limiter.limit(install_id.to_string()).await, "BURST")?;
    if outcome.success {
        Ok(())
    } else {
        Err(ApiError::rate_limited())
    }
}

async fn read_body(req: &mut Request) -> std::result::Result<Vec<u8>, ApiError> {
    req.bytes()
        .await
        .map_err(|_| ApiError::invalid("Could not read the body"))
}

#[derive(Serialize)]
struct Identified {
    /// None when the model couldn't tell; the app keeps its on-device
    /// candidates and search.
    answer: Option<Answer>,
    cached: bool,
}

async fn identify(req: &mut Request, env: &Env) -> std::result::Result<Identified, ApiError> {
    let started = Date::now().as_millis();
    let config = Config::from_env(env)?;
    let request = parse_identify(&read_body(req).await?)?;
    burst_check(env, &request.install_id).await?;

    let kv = binding(env.kv("CACHE"), "CACHE")?;
    let home = catalog::area_home(&kv, &config, &request.area_id)
        .await?
        .ok_or_else(ApiError::unknown_area)?;
    let day = japan_day(started);
    let db = binding(env.d1("DB"), "DB")?;
    let mut log = store::CallLog {
        day: &day,
        area_id: &request.area_id,
        labels: &request.labels,
        candidate_count: request.candidates.len(),
        source: "cache",
        outcome: "item",
        item_id: None,
        category: None,
        confidence: None,
        model: &config.model,
        usage: Usage::default(),
        micro_usd: 0,
        duration_ms: 0,
        app_version: request.app_version.as_deref(),
    };

    // The same photo of the same item set: answer from the cache for free.
    let key = answer_key(
        &request.image,
        &request.area_id,
        home.bundle_version,
        &request.candidates,
    );
    let cached = kv.get(&key).json::<Answer>().await.map_err(|e| {
        console_error!("KV: {e}");
        ApiError::internal()
    })?;
    if let Some(answer) = cached {
        let outcome = Outcome::Answered(answer.clone());
        log.outcome = outcome.label();
        log.item_id = answer.item_id.as_deref();
        log.category = answer.category.as_deref();
        log.confidence = Some(answer.confidence);
        log.duration_ms = Date::now().as_millis() - started;
        store::log_call(&db, &log).await?;
        return Ok(Identified {
            answer: Some(answer),
            cached: true,
        });
    }

    if !config
        .allowance
        .ai_available(store::spent(&db, &day).await?)
    {
        return Err(ApiError::ai_paused());
    }
    let used = store::count_use(&db, &request.install_id, &day, "identify").await?;
    if used > config.allowance.ai_calls_per_install {
        return Err(ApiError::daily_limit());
    }

    let guide = catalog::guide(&kv, &config, &home).await?;
    let image = base64::engine::general_purpose::STANDARD.encode(&request.image);
    let body = request_body(&config.model, &guide, &image, &request.candidates);
    let response = upstream::messages(&config, &body).await?;
    let (outcome, usage) = parse_response(&response, &request.candidates, &guide).map_err(|e| {
        console_error!("{e}");
        ApiError::upstream()
    })?;

    let cost = micro_usd(&config.model, &usage);
    store::add_spend(&db, &day, cost).await?;
    let answer = match &outcome {
        Outcome::Answered(answer) => Some(answer.clone()),
        Outcome::NoAnswer(_) => None,
    };
    log.source = "model";
    log.outcome = outcome.label();
    log.item_id = answer.as_ref().and_then(|a| a.item_id.as_deref());
    log.category = answer.as_ref().and_then(|a| a.category.as_deref());
    log.confidence = answer.as_ref().map(|a| a.confidence);
    log.usage = usage;
    log.micro_usd = cost;
    log.duration_ms = Date::now().as_millis() - started;
    store::log_call(&db, &log).await?;

    if let Some(answer) = &answer {
        let put = kv.put(&key, answer).map_err(|_| ApiError::internal())?;
        if let Err(e) = put.expiration_ttl(ANSWER_TTL_SECONDS).execute().await {
            // The answer is still good; only the next identical photo pays again.
            console_error!("KV: {e}");
        }
    }
    Ok(Identified {
        answer,
        cached: false,
    })
}

#[derive(Serialize)]
struct Reported {
    ok: bool,
}

async fn report(req: &mut Request, env: &Env) -> std::result::Result<Reported, ApiError> {
    let config = Config::from_env(env)?;
    let report = parse_report(&read_body(req).await?)?;
    burst_check(env, &report.install_id).await?;
    let kv = binding(env.kv("CACHE"), "CACHE")?;
    if catalog::area_home(&kv, &config, &report.area_id)
        .await?
        .is_none()
    {
        return Err(ApiError::unknown_area());
    }
    let day = japan_day(Date::now().as_millis());
    let db = binding(env.d1("DB"), "DB")?;
    if store::count_use(&db, &report.install_id, &day, "report").await?
        > config.allowance.reports_per_install
    {
        return Err(ApiError::daily_limit());
    }
    store::add_report(
        &db,
        &store::ReportRow {
            day: &day,
            area_id: &report.area_id,
            item_id: report.item_id.as_deref(),
            kind: report.kind.as_str(),
            note: report.note.as_deref(),
            app_version: report.app_version.as_deref(),
        },
    )
    .await?;
    Ok(Reported { ok: true })
}
