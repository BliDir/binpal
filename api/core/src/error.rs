use serde::Serialize;

/// An error the app can act on: an HTTP status and a stable code.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ApiError {
    #[serde(skip)]
    pub status: u16,
    #[serde(rename = "error")]
    pub code: &'static str,
    pub message: String,
}

impl ApiError {
    pub fn new(status: u16, code: &'static str, message: impl Into<String>) -> Self {
        Self {
            status,
            code,
            message: message.into(),
        }
    }

    pub fn invalid(message: impl Into<String>) -> Self {
        Self::new(400, "invalid_request", message)
    }

    pub fn too_large(message: impl Into<String>) -> Self {
        Self::new(413, "payload_too_large", message)
    }

    pub fn unknown_area() -> Self {
        Self::new(400, "unknown_area", "BinPal has no data for this area")
    }

    /// Too many requests in a short time; the app should wait a minute.
    pub fn rate_limited() -> Self {
        Self::new(
            429,
            "rate_limited",
            "Too many requests, try again in a minute",
        )
    }

    /// This install has used today's allowance.
    pub fn daily_limit() -> Self {
        Self::new(
            429,
            "daily_limit",
            "Daily limit reached, try again tomorrow",
        )
    }

    /// Today's AI budget is spent: the app should use on-device results only.
    pub fn ai_paused() -> Self {
        Self::new(503, "ai_paused", "AI is paused for today")
    }

    pub fn upstream() -> Self {
        Self::new(502, "upstream_failed", "The AI service did not answer")
    }

    pub fn internal() -> Self {
        Self::new(500, "internal", "Something went wrong")
    }
}
