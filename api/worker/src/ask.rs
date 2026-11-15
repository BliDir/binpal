//! `POST /v1/ask`: a plain-language question about the area's rules.
//!
//! The same path as a photo, with its own daily cap per install: the size
//! checks, the burst limit, the area check, the answer cache (free), then
//! Workers AI and the Anthropic fallback within the shared allowance and
//! budget. Answers are checked against the candidates the app sent
//! (`binpal_api_core::qa`). The question itself is never stored or logged.

use binpal_api_core::ApiError;
use binpal_api_core::catalog::CategoryGuide;
use binpal_api_core::cost::{micro_usd, neurons};
use binpal_api_core::keys::{japan_day, utc_day};
use binpal_api_core::qa::{
    Ask, QaAnswer, QaOutcome, ask_key, ask_request_body, ask_workers_ai_body, parse_ask,
    parse_ask_response, parse_ask_workers_ai,
};
use serde::Serialize;
use worker::{Date, Env, Request, console_error};

use crate::config::Config;
use crate::store::{self, CallLog};
use crate::{ANSWER_TTL_SECONDS, binding, burst_check, catalog, open_models, read_body};
use crate::{upstream, workers_ai};

#[derive(Serialize)]
pub struct Asked {
    answer: QaAnswer,
    cached: bool,
}

fn log_row<'a>(
    ask: &'a Ask,
    day: &'a str,
    source: &'a str,
    model: &'a str,
    outcome: &'a QaOutcome,
) -> CallLog<'a> {
    let first = match outcome {
        QaOutcome::Answered(answer) => answer
            .item_ids
            .first()
            .and_then(|id| ask.candidates.iter().find(|c| &c.item_id == id)),
        QaOutcome::Failed(_) => None,
    };
    CallLog {
        kind: "question",
        day,
        area_id: &ask.area_id,
        labels: &[],
        candidate_count: ask.candidates.len(),
        source,
        model,
        fallback: None,
        outcome: outcome.label(),
        item_id: first.map(|c| c.item_id.as_str()),
        category: first.map(|c| c.category.as_str()),
        confidence: None,
        input_tokens: 0,
        cache_write_tokens: 0,
        cache_read_tokens: 0,
        output_tokens: 0,
        neurons: 0,
        micro_usd: 0,
        duration_ms: 0,
        app_version: ask.app_version.as_deref(),
    }
}

struct Call<'a> {
    env: &'a Env,
    config: &'a Config,
    db: &'a worker::D1Database,
    ask: &'a Ask,
    guide: &'a CategoryGuide,
    day: &'a str,
    utc_day: &'a str,
}

async fn ask_workers_ai(call: &Call<'_>) -> Result<QaOutcome, ApiError> {
    let started = Date::now().as_millis();
    let config = call.config;
    let input = ask_workers_ai_body(call.guide, call.ask);
    let output = match workers_ai::run(call.env, config, &input).await {
        Ok(output) => output,
        Err(workers_ai::Failure::AllowanceUsed) => {
            let limit = config.allowance.workers_ai_daily_neurons;
            store::add_neurons(call.db, call.utc_day, limit).await?;
            return Ok(QaOutcome::Failed("allowance"));
        }
        Err(workers_ai::Failure::Other(message)) => {
            console_error!("Workers AI: {message}");
            return Ok(QaOutcome::Failed("error"));
        }
    };
    let (outcome, usage) = match parse_ask_workers_ai(&output, call.ask, call.guide) {
        Ok(parsed) => parsed,
        Err(e) => {
            console_error!("{e}");
            return Ok(QaOutcome::Failed("error"));
        }
    };
    let used = neurons(&config.workers_ai_model, &usage);
    store::add_neurons(call.db, call.utc_day, used).await?;
    let mut log = log_row(
        call.ask,
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

async fn ask_anthropic(
    call: &Call<'_>,
    api_key: &str,
    fallback: &str,
) -> Result<QaOutcome, ApiError> {
    let started = Date::now().as_millis();
    let config = call.config;
    let body = ask_request_body(&config.anthropic_model, call.guide, call.ask);
    let response = upstream::messages(config, api_key, &body).await?;
    let (outcome, usage) = parse_ask_response(&response, call.ask, call.guide).map_err(|e| {
        console_error!("{e}");
        ApiError::upstream()
    })?;
    let cost = micro_usd(&config.anthropic_model, &usage);
    store::add_spend(call.db, call.day, cost).await?;
    let mut log = log_row(
        call.ask,
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

pub async fn ask(req: &mut Request, env: &Env) -> Result<Asked, ApiError> {
    let started = Date::now().as_millis();
    let config = Config::from_env(env)?;
    let ask = parse_ask(&read_body(req).await?)?;
    burst_check(env, &ask.install_id).await?;

    let kv = binding(env.kv("CACHE"), "CACHE")?;
    let home = catalog::area_home(&kv, &config, &ask.area_id)
        .await?
        .ok_or_else(ApiError::unknown_area)?;
    let day = japan_day(started);
    let db = binding(env.d1("DB"), "DB")?;

    let key = ask_key(&ask, &home.municipality_id, home.bundle_version);
    let cached = kv.get(&key).json::<QaAnswer>().await.map_err(|e| {
        console_error!("KV: {e}");
        ApiError::internal()
    })?;
    if let Some(answer) = cached {
        let outcome = QaOutcome::Answered(answer.clone());
        let mut log = log_row(&ask, &day, "cache", "", &outcome);
        log.duration_ms = Date::now().as_millis() - started;
        store::log_call(&db, &log).await?;
        return Ok(Asked {
            answer,
            cached: true,
        });
    }

    let open = open_models(&config, &db, started).await?;
    if !open.workers_ai && !open.anthropic {
        return Err(ApiError::ai_paused());
    }
    let used = store::count_use(&db, &ask.install_id, &day, "question").await?;
    if used > config.allowance.questions_per_install {
        return Err(ApiError::daily_limit());
    }

    let guide = catalog::guide(&kv, &config, &home).await?;
    let utc = utc_day(started);
    let call = Call {
        env,
        config: &config,
        db: &db,
        ask: &ask,
        guide: &guide,
        day: &day,
        utc_day: &utc,
    };
    let mut outcome = if open.workers_ai {
        ask_workers_ai(&call).await?
    } else {
        QaOutcome::Failed("allowance")
    };
    if let (QaOutcome::Failed(reason), true, Some(api_key)) =
        (&outcome, open.anthropic, &config.anthropic_api_key)
    {
        outcome = ask_anthropic(&call, api_key, reason).await?;
    }

    match outcome {
        QaOutcome::Answered(answer) => {
            let put = kv.put(&key, &answer).map_err(|_| ApiError::internal())?;
            if let Err(e) = put.expiration_ttl(ANSWER_TTL_SECONDS).execute().await {
                console_error!("KV: {e}");
            }
            Ok(Asked {
                answer,
                cached: false,
            })
        }
        // The app still has its cited-rule search and the official contact.
        QaOutcome::Failed(_) => Err(ApiError::upstream()),
    }
}
