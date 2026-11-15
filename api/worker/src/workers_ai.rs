//! The Workers AI call, through the `AI` binding: no API key, and free up to
//! the daily Neuron allowance.

use std::time::Duration;

use futures_util::future::{Either, select};
use serde_json::Value;
use worker::{Delay, Env, Fetch, Headers, Method, Request, RequestInit, wasm_bindgen::JsValue};

use crate::config::Config;

const TIMEOUT: Duration = Duration::from_secs(20);

/// Why Workers AI gave no output.
pub enum Failure {
    /// Cloudflare says the day's free allocation is used up.
    AllowanceUsed,
    Other(String),
}

/// Whether an error says the daily free allocation is used. Cloudflare
/// documents that further calls "fail with an error" but not its code, so
/// this matches on the wording.
fn allowance_error(message: &str) -> bool {
    let message = message.to_ascii_lowercase();
    message.contains("4006") || message.contains("free allocation") || message.contains("neurons")
}

/// Runs the chat model on `input` and returns its output as JSON.
pub async fn run(env: &Env, config: &Config, input: &Value) -> Result<Value, Failure> {
    let call = Box::pin(async {
        match &config.workers_ai_test_url {
            Some(url) => run_mock(url, &config.workers_ai_model, input).await,
            None => {
                let ai = env.ai("AI").map_err(|e| e.to_string())?;
                ai.run::<_, Value>(&config.workers_ai_model, input)
                    .await
                    .map_err(|e| e.to_string())
            }
        }
    });
    match select(call, Box::pin(Delay::from(TIMEOUT))).await {
        Either::Left((Ok(output), _)) => Ok(output),
        Either::Left((Err(message), _)) if allowance_error(&message) => Err(Failure::AllowanceUsed),
        Either::Left((Err(message), _)) => Err(Failure::Other(message)),
        Either::Right(_) => Err(Failure::Other(format!("timed out after {TIMEOUT:?}"))),
    }
}

/// The test stand-in: POSTs the input as JSON and reads the output back, as
/// the binding would.
async fn run_mock(url: &str, model: &str, input: &Value) -> Result<Value, String> {
    let headers = Headers::new();
    headers
        .set("content-type", "application/json")
        .map_err(|e| e.to_string())?;
    let mut init = RequestInit::new();
    init.with_method(Method::Post)
        .with_headers(headers)
        .with_body(Some(JsValue::from_str(&input.to_string())));
    let request = Request::new_with_init(&format!("{url}/ai/run/{model}"), &init)
        .map_err(|e| e.to_string())?;
    let mut response = Fetch::Request(request)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let text = response.text().await.map_err(|e| e.to_string())?;
    if response.status_code() != 200 {
        return Err(text);
    }
    serde_json::from_str(&text).map_err(|e| e.to_string())
}
