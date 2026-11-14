//! The Messages API call. Raw HTTP: there is no official Anthropic SDK for
//! Rust.

use std::time::Duration;

use binpal_api_core::ApiError;
use binpal_api_core::prompt::ANTHROPIC_VERSION;
use futures_util::future::{Either, select};
use worker::{
    AbortController, Delay, Fetch, Headers, Method, Request, RequestInit, console_error,
    wasm_bindgen::JsValue,
};

use crate::config::Config;

/// The app waits for this answer next to its on-device results; past this
/// it is better to give up.
const TIMEOUT: Duration = Duration::from_secs(20);

/// Statuses worth one retry: rate limited, overloaded, or a server error.
fn retryable(status: u16) -> bool {
    matches!(status, 429 | 500 | 502 | 503 | 504 | 529)
}

/// POSTs `body` to `/v1/messages` and returns the response body. Retries
/// once on a retryable status. Logs only the status and the API's error
/// type, never the request, which holds the photo.
pub async fn messages(config: &Config, body: &serde_json::Value) -> Result<Vec<u8>, ApiError> {
    let body = body.to_string();
    let url = format!("{}/v1/messages", config.anthropic_base_url);
    for attempt in 0..2 {
        if attempt > 0 {
            Delay::from(Duration::from_millis(500)).await;
        }
        let headers = Headers::new();
        for (name, value) in [
            ("content-type", "application/json"),
            ("x-api-key", config.anthropic_api_key.as_str()),
            ("anthropic-version", ANTHROPIC_VERSION),
        ] {
            headers.set(name, value).map_err(|_| ApiError::internal())?;
        }
        let mut init = RequestInit::new();
        init.with_method(Method::Post)
            .with_headers(headers)
            .with_body(Some(JsValue::from_str(&body)));
        let request = Request::new_with_init(&url, &init).map_err(|_| ApiError::internal())?;

        let controller = AbortController::default();
        let signal = controller.signal();
        let fetch = Fetch::Request(request);
        let send = Box::pin(fetch.send_with_signal(&signal));
        let timer = Box::pin(Delay::from(TIMEOUT));
        let mut response = match select(send, timer).await {
            Either::Left((Ok(response), _)) => response,
            Either::Left((Err(e), _)) => {
                console_error!("Messages API request failed: {e}");
                continue;
            }
            Either::Right(_) => {
                controller.abort();
                console_error!("Messages API timed out after {TIMEOUT:?}");
                return Err(ApiError::upstream());
            }
        };
        let status = response.status_code();
        let bytes = response.bytes().await.map_err(|_| ApiError::upstream())?;
        if status == 200 {
            return Ok(bytes);
        }
        let error_type = serde_json::from_slice::<serde_json::Value>(&bytes)
            .ok()
            .and_then(|v| v["error"]["type"].as_str().map(String::from))
            .unwrap_or_default();
        console_error!("Messages API returned {status} {error_type}");
        if !retryable(status) {
            break;
        }
    }
    Err(ApiError::upstream())
}
