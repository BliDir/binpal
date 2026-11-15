//! The review queue's GitHub Issues, through the REST API with a
//! fine-grained token that can only read and write this repository's issues.

use binpal_api_core::ApiError;
use serde_json::{Value, json};
use worker::{Fetch, Headers, Method, Request, RequestInit, console_error, wasm_bindgen::JsValue};

pub struct GitHub<'a> {
    pub api_url: &'a str,
    pub repo: &'a str,
    pub token: &'a str,
}

impl GitHub<'_> {
    async fn call(
        &self,
        method: Method,
        path: &str,
        body: Option<Value>,
    ) -> Result<Value, ApiError> {
        let url = format!("{}/repos/{}{path}", self.api_url, self.repo);
        let headers = Headers::new();
        for (name, value) in [
            ("accept", "application/vnd.github+json"),
            ("authorization", &format!("Bearer {}", self.token)),
            ("x-github-api-version", "2022-11-28"),
            // GitHub refuses requests without one.
            ("user-agent", "binpal-api"),
            ("content-type", "application/json"),
        ] {
            headers.set(name, value).map_err(|_| ApiError::internal())?;
        }
        let mut init = RequestInit::new();
        init.with_method(method).with_headers(headers);
        if let Some(body) = body {
            init.with_body(Some(JsValue::from_str(&body.to_string())));
        }
        let request = Request::new_with_init(&url, &init).map_err(|_| ApiError::internal())?;
        let mut response = Fetch::Request(request).send().await.map_err(|e| {
            console_error!("GitHub {path}: {e}");
            ApiError::upstream()
        })?;
        let status = response.status_code();
        if !(200..300).contains(&status) {
            console_error!("GitHub {path} returned {status}");
            return Err(ApiError::upstream());
        }
        response.json().await.map_err(|_| ApiError::upstream())
    }

    /// Opens an issue and returns its number.
    pub async fn create_issue(
        &self,
        title: &str,
        body: &str,
        labels: &[&str],
    ) -> Result<u64, ApiError> {
        let created = self
            .call(
                Method::Post,
                "/issues",
                Some(json!({"title": title, "body": body, "labels": labels})),
            )
            .await?;
        created["number"].as_u64().ok_or_else(ApiError::upstream)
    }

    pub async fn comment(&self, number: u64, body: &str) -> Result<(), ApiError> {
        self.call(
            Method::Post,
            &format!("/issues/{number}/comments"),
            Some(json!({"body": body})),
        )
        .await
        .map(|_| ())
    }

    pub async fn add_labels(&self, number: u64, labels: &[&str]) -> Result<(), ApiError> {
        self.call(
            Method::Post,
            &format!("/issues/{number}/labels"),
            Some(json!({"labels": labels})),
        )
        .await
        .map(|_| ())
    }

    /// Whether the issue is still open: a reviewer closes it once handled,
    /// and new reports then start a new issue.
    pub async fn is_open(&self, number: u64) -> Result<bool, ApiError> {
        let issue = self
            .call(Method::Get, &format!("/issues/{number}"), None)
            .await?;
        Ok(issue["state"] == "open")
    }
}
