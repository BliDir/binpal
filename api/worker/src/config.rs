use binpal_api_core::ApiError;
use binpal_api_core::limits::{Allowance, parse_usd};
use worker::{Env, console_error};

/// Settings from `wrangler.toml` variables and the secret store.
pub struct Config {
    pub workers_ai_model: String,
    /// Set only by `tests/e2e.py`: send Workers AI requests to this mock
    /// instead of the `AI` binding, which `wrangler dev` can't run offline.
    pub workers_ai_test_url: Option<String>,
    pub anthropic_model: String,
    pub anthropic_base_url: String,
    /// None turns the Anthropic fallback off; Workers AI and reports still work.
    pub anthropic_api_key: Option<String>,
    pub cdn_base_url: String,
    pub allowance: Allowance,
}

fn var(env: &Env, name: &str) -> Result<String, ApiError> {
    env.var(name).map(|v| v.to_string()).map_err(|_| {
        console_error!("missing variable {name}");
        ApiError::internal()
    })
}

fn number<T: std::str::FromStr>(env: &Env, name: &str) -> Result<T, ApiError> {
    var(env, name)?.trim().parse().map_err(|_| {
        console_error!("variable {name} is not a whole number");
        ApiError::internal()
    })
}

impl Config {
    pub fn from_env(env: &Env) -> Result<Self, ApiError> {
        let budget = var(env, "DAILY_BUDGET_USD")?;
        Ok(Self {
            workers_ai_model: var(env, "WORKERS_AI_MODEL")?,
            workers_ai_test_url: env
                .var("WORKERS_AI_TEST_URL")
                .ok()
                .map(|v| v.to_string().trim_end_matches('/').to_string())
                .filter(|url| !url.is_empty()),
            anthropic_model: var(env, "ANTHROPIC_MODEL")?,
            anthropic_base_url: var(env, "ANTHROPIC_BASE_URL")?
                .trim_end_matches('/')
                .to_string(),
            anthropic_api_key: env
                .secret("ANTHROPIC_API_KEY")
                .ok()
                .map(|s| s.to_string())
                .filter(|key| !key.is_empty()),
            cdn_base_url: var(env, "CDN_BASE_URL")?.trim_end_matches('/').to_string(),
            allowance: Allowance {
                ai_calls_per_install: number(env, "AI_CALLS_PER_INSTALL_PER_DAY")?,
                reports_per_install: number(env, "REPORTS_PER_INSTALL_PER_DAY")?,
                daily_budget_micro_usd: parse_usd(&budget).ok_or_else(|| {
                    console_error!("DAILY_BUDGET_USD is not an amount: {budget}");
                    ApiError::internal()
                })?,
                workers_ai_daily_neurons: number(env, "WORKERS_AI_DAILY_NEURONS")?,
            },
        })
    }
}
