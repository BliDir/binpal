//! The BinPal thin API: the AI fallback for photo check, and reports.
//!
//! `POST /v1/identify` is only called when the phone couldn't identify a
//! photo itself. Each request passes, in order: the size and format checks,
//! a per-install burst limit, a check that BinPal covers the area, the
//! answer cache (free), and the per-install daily cap. Then Workers AI
//! answers, free while the day's Neurons last; Anthropic is the fallback
//! when Workers AI fails, can't tell, or is used up, within its daily budget.
//!
//! `POST /v1/reports` stores "this looks wrong" reports; every five minutes
//! they are filed in the review queue (`queue.rs`).

mod catalog;
mod config;
mod github;
mod queue;
mod store;
mod upstream;
mod workers_ai;

use base64::Engine;
use binpal_api_core::ApiError;
use binpal_api_core::answer::{Answer, Outcome, parse_response, parse_workers_ai};
use binpal_api_core::catalog::CategoryGuide;
use binpal_api_core::cost::{micro_usd, neurons};
use binpal_api_core::keys::{answer_key, japan_day, utc_day};
use binpal_api_core::prompt::{request_body, workers_ai_body};
use binpal_api_core::request::{Identify, parse_identify, parse_report};
use serde::Serialize;
use worker::*;

use crate::config::Config;
use crate::store::CallLog;

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

/// The daily cleanup cron in `wrangler.toml`; every other trigger files
/// reports.
const CLEANUP_CRON: &str = "0 18 * * *";

#[event(scheduled)]
async fn scheduled(event: ScheduledEvent, env: Env, _ctx: ScheduleContext) {
    if event.cron() == CLEANUP_CRON {
        clean_up(&env).await;
    } else if let Err(e) = queue::file_reports(&env).await {
        console_error!("filing reports failed: {}", e.message);
    }
}

/// Daily: drop install counters after two days, and log rows and Neuron
/// totals after 90.
async fn clean_up(env: &Env) {
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

/// Which models can take a call right now.
struct Open {
    workers_ai: bool,
    anthropic: bool,
}

async fn open_models(
    config: &Config,
    db: &D1Database,
    now: u64,
) -> std::result::Result<Open, ApiError> {
    let allowance = &config.allowance;
    let anthropic = config.anthropic_api_key.is_some()
        && allowance.anthropic_available(store::spent(db, &japan_day(now)).await?);
    Ok(Open {
        workers_ai: allowance.workers_ai_available(store::neurons_used(db, &utc_day(now)).await?),
        anthropic,
    })
}

#[derive(Serialize)]
struct Status {
    /// "available", or "paused" when neither model can take a call: today's
    /// free Workers AI Neurons are used and the Anthropic budget is spent (or
    /// there is no key). The app then stays on-device.
    ai: &'static str,
}

async fn status(env: &Env) -> std::result::Result<Status, ApiError> {
    let config = Config::from_env(env)?;
    let db = binding(env.d1("DB"), "DB")?;
    let open = open_models(&config, &db, Date::now().as_millis()).await?;
    Ok(Status {
        ai: if open.workers_ai || open.anthropic {
            "available"
        } else {
            "paused"
        },
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
    /// None when the models couldn't tell; the app keeps its on-device
    /// candidates and search.
    answer: Option<Answer>,
    cached: bool,
}

/// A log row for this request with no tokens or cost yet.
fn log_row<'a>(
    request: &'a Identify,
    day: &'a str,
    source: &'a str,
    model: &'a str,
    outcome: &'a Outcome,
) -> CallLog<'a> {
    let answer = match outcome {
        Outcome::Answered(answer) => Some(answer),
        Outcome::NoAnswer(_) => None,
    };
    CallLog {
        day,
        area_id: &request.area_id,
        labels: &request.labels,
        candidate_count: request.candidates.len(),
        source,
        model,
        fallback: None,
        outcome: outcome.label(),
        item_id: answer.and_then(|a| a.item_id.as_deref()),
        category: answer.and_then(|a| a.category.as_deref()),
        confidence: answer.map(|a| a.confidence),
        input_tokens: 0,
        cache_write_tokens: 0,
        cache_read_tokens: 0,
        output_tokens: 0,
        neurons: 0,
        micro_usd: 0,
        duration_ms: 0,
        app_version: request.app_version.as_deref(),
    }
}

/// Everything a model call needs.
struct Call<'a> {
    env: &'a Env,
    config: &'a Config,
    db: &'a D1Database,
    request: &'a Identify,
    guide: &'a CategoryGuide,
    image: &'a str,
    day: &'a str,
    utc_day: &'a str,
}

/// Workers AI's answer, or why there isn't one ("error" when the call failed).
async fn ask_workers_ai(call: &Call<'_>) -> std::result::Result<Outcome, ApiError> {
    let started = Date::now().as_millis();
    let config = call.config;
    let input = workers_ai_body(call.guide, call.image, &call.request.candidates);
    let output = match workers_ai::run(call.env, config, &input).await {
        Ok(output) => output,
        Err(workers_ai::Failure::AllowanceUsed) => {
            // Cloudflare counted more than we did: stop for the rest of the day.
            let limit = config.allowance.workers_ai_daily_neurons;
            store::add_neurons(call.db, call.utc_day, limit).await?;
            return Ok(Outcome::NoAnswer("allowance"));
        }
        Err(workers_ai::Failure::Other(message)) => {
            console_error!("Workers AI: {message}");
            return Ok(Outcome::NoAnswer("error"));
        }
    };
    let (outcome, usage) = match parse_workers_ai(&output, &call.request.candidates, call.guide) {
        Ok(parsed) => parsed,
        Err(e) => {
            console_error!("{e}");
            return Ok(Outcome::NoAnswer("error"));
        }
    };
    let used = neurons(&config.workers_ai_model, &usage);
    store::add_neurons(call.db, call.utc_day, used).await?;
    let mut log = log_row(
        call.request,
        call.day,
        "workers_ai",
        &config.workers_ai_model,
        &outcome,
    );
    log.input_tokens = usage.prompt_tokens;
    log.output_tokens = usage.completion_tokens;
    log.neurons = used;
    log.duration_ms = Date::now().as_millis() - started;
    store::log_call(call.db, &log).await?;
    Ok(outcome)
}

/// Anthropic's answer; `fallback` is why Workers AI didn't answer.
async fn ask_anthropic(
    call: &Call<'_>,
    api_key: &str,
    fallback: &str,
) -> std::result::Result<Outcome, ApiError> {
    let started = Date::now().as_millis();
    let config = call.config;
    let body = request_body(
        &config.anthropic_model,
        call.guide,
        call.image,
        &call.request.candidates,
    );
    let response = upstream::messages(config, api_key, &body).await?;
    let (outcome, usage) = parse_response(&response, &call.request.candidates, call.guide)
        .map_err(|e| {
            console_error!("{e}");
            ApiError::upstream()
        })?;
    let cost = micro_usd(&config.anthropic_model, &usage);
    store::add_spend(call.db, call.day, cost).await?;
    let mut log = log_row(
        call.request,
        call.day,
        "anthropic",
        &config.anthropic_model,
        &outcome,
    );
    log.fallback = Some(fallback);
    log.input_tokens = usage.input_tokens;
    log.cache_write_tokens = usage.cache_creation_input_tokens;
    log.cache_read_tokens = usage.cache_read_input_tokens;
    log.output_tokens = usage.output_tokens;
    log.micro_usd = cost;
    log.duration_ms = Date::now().as_millis() - started;
    store::log_call(call.db, &log).await?;
    Ok(outcome)
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
        let mut log = log_row(&request, &day, "cache", "", &outcome);
        log.duration_ms = Date::now().as_millis() - started;
        store::log_call(&db, &log).await?;
        return Ok(Identified {
            answer: Some(answer),
            cached: true,
        });
    }

    let open = open_models(&config, &db, started).await?;
    if !open.workers_ai && !open.anthropic {
        return Err(ApiError::ai_paused());
    }
    let used = store::count_use(&db, &request.install_id, &day, "identify").await?;
    if used > config.allowance.ai_calls_per_install {
        return Err(ApiError::daily_limit());
    }

    let guide = catalog::guide(&kv, &config, &home).await?;
    let image = base64::engine::general_purpose::STANDARD.encode(&request.image);
    let utc = utc_day(started);
    let call = Call {
        env,
        config: &config,
        db: &db,
        request: &request,
        guide: &guide,
        image: &image,
        day: &day,
        utc_day: &utc,
    };

    let mut outcome = if open.workers_ai {
        ask_workers_ai(&call).await?
    } else {
        Outcome::NoAnswer("allowance")
    };
    if let (Outcome::NoAnswer(reason), true, Some(api_key)) =
        (&outcome, open.anthropic, &config.anthropic_api_key)
    {
        outcome = ask_anthropic(&call, api_key, reason).await?;
    }

    match outcome {
        Outcome::Answered(answer) => {
            let put = kv.put(&key, &answer).map_err(|_| ApiError::internal())?;
            if let Err(e) = put.expiration_ttl(ANSWER_TTL_SECONDS).execute().await {
                // The answer is still good; only the next identical photo pays again.
                console_error!("KV: {e}");
            }
            Ok(Identified {
                answer: Some(answer),
                cached: false,
            })
        }
        // Workers AI failed and there was no fallback to ask.
        Outcome::NoAnswer("error") => Err(ApiError::upstream()),
        Outcome::NoAnswer(_) => Ok(Identified {
            answer: None,
            cached: false,
        }),
    }
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
            date: report.date.as_deref(),
            kind: report.kind.as_str(),
            note: report.note.as_deref(),
            app_version: report.app_version.as_deref(),
        },
    )
    .await?;
    Ok(Reported { ok: true })
}
