use binpal_api_core::ApiError;
use binpal_api_core::limits::{Allowance, parse_usd};
use worker::{Env, console_error};

/// Settings from `wrangler.toml` variables and the secret store.
pub struct Config {
    pub model: String,
    pub anthropic_base_url: String,
    pub anthropic_api_key: String,
    pub cdn_base_url: String,
    pub allowance: Allowance,
}

fn var(env: &Env, name: &str) -> Result<String, ApiError> {
    env.var(name).map(|v| v.to_string()).map_err(|_| {
        console_error!("missing variable {name}");
        ApiError::internal()
    })
}

fn number(env: &Env, name: &str) -> Result<u32, ApiError> {
    var(env, name)?.trim().parse().map_err(|_| {
        console_error!("variable {name} is not a whole number");
        ApiError::internal()
    })
}

impl Config {
    pub fn from_env(env: &Env) -> Result<Self, ApiError> {
        let budget = var(env, "DAILY_BUDGET_USD")?;
        Ok(Self {
            model: var(env, "ANTHROPIC_MODEL")?,
            anthropic_base_url: var(env, "ANTHROPIC_BASE_URL")?
                .trim_end_matches('/')
                .to_string(),
            anthropic_api_key: env
                .secret("ANTHROPIC_API_KEY")
                .map(|s| s.to_string())
                .map_err(|_| {
                    console_error!("missing secret ANTHROPIC_API_KEY");
                    ApiError::internal()
                })?,
            cdn_base_url: var(env, "CDN_BASE_URL")?.trim_end_matches('/').to_string(),
            allowance: Allowance {
                ai_calls_per_install: number(env, "AI_CALLS_PER_INSTALL_PER_DAY")?,
                reports_per_install: number(env, "REPORTS_PER_INSTALL_PER_DAY")?,
                daily_budget_micro_usd: parse_usd(&budget).ok_or_else(|| {
                    console_error!("DAILY_BUDGET_USD is not an amount: {budget}");
                    ApiError::internal()
                })?,
            },
        })
    }
}
