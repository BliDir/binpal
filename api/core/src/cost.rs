//! What a call cost, from the token usage the API reports, for the daily
//! budget and the cost-per-call figures.

use serde::{Deserialize, Serialize};

/// Token counts from a Messages API response. `input_tokens` is the part of
/// the prompt that was neither written to nor read from the cache.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Deserialize, Serialize)]
pub struct Usage {
    #[serde(default)]
    pub input_tokens: u64,
    #[serde(default)]
    pub output_tokens: u64,
    #[serde(default, deserialize_with = "zero_if_null")]
    pub cache_creation_input_tokens: u64,
    #[serde(default, deserialize_with = "zero_if_null")]
    pub cache_read_input_tokens: u64,
}

fn zero_if_null<'de, D: serde::Deserializer<'de>>(d: D) -> Result<u64, D::Error> {
    Ok(Option::<u64>::deserialize(d)?.unwrap_or(0))
}

impl Usage {
    pub fn prompt_tokens(&self) -> u64 {
        self.input_tokens + self.cache_creation_input_tokens + self.cache_read_input_tokens
    }
}

/// Dollars per million input and output tokens.
struct Rates {
    input: f64,
    output: f64,
}

/// Claude API list prices (November 2026). Cache writes (5-minute) cost
/// 1.25x input and cache reads 0.1x on these models.
fn rates(model: &str, prompt_tokens: u64) -> Rates {
    match model {
        // Haiku 5.5 has a second rate card above 100K prompt tokens.
        "claude-haiku-5-5" if prompt_tokens > 100_000 => Rates {
            input: 0.50,
            output: 2.50,
        },
        "claude-haiku-5-5" => Rates {
            input: 0.10,
            output: 0.50,
        },
        "claude-sonnet-5-5" => Rates {
            input: 2.00,
            output: 10.00,
        },
        // Unknown model: count it at the most expensive rates, so a model
        // change can't spend past the budget unnoticed.
        _ => Rates {
            input: 10.00,
            output: 50.00,
        },
    }
}

/// The call's cost in millionths of a dollar, rounded up.
pub fn micro_usd(model: &str, usage: &Usage) -> u64 {
    let r = rates(model, usage.prompt_tokens());
    // $ per million tokens is the same number as micro-dollars per token.
    let cost = usage.input_tokens as f64 * r.input
        + usage.cache_creation_input_tokens as f64 * r.input * 1.25
        + usage.cache_read_input_tokens as f64 * r.input * 0.1
        + usage.output_tokens as f64 * r.output;
    cost.ceil() as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_typical_photo_with_a_warm_cache() {
        // ~1.2K tokens of photo and candidates, ~2K cached system prompt.
        let usage = Usage {
            input_tokens: 1200,
            output_tokens: 60,
            cache_creation_input_tokens: 0,
            cache_read_input_tokens: 2000,
        };
        // 1200 x 0.1 + 2000 x 0.01 + 60 x 0.5 = 120 + 20 + 30
        assert_eq!(micro_usd("claude-haiku-5-5", &usage), 170);
    }

    #[test]
    fn writing_the_cache_costs_a_quarter_more() {
        let usage = Usage {
            input_tokens: 1200,
            output_tokens: 60,
            cache_creation_input_tokens: 2000,
            cache_read_input_tokens: 0,
        };
        // 120 + 2000 x 0.125 + 30
        assert_eq!(micro_usd("claude-haiku-5-5", &usage), 400);
    }

    #[test]
    fn unknown_models_are_counted_high() {
        let usage = Usage {
            input_tokens: 1000,
            output_tokens: 100,
            ..Usage::default()
        };
        assert_eq!(micro_usd("claude-haiku-5-5", &usage), 150);
        assert_eq!(micro_usd("claude-something-new", &usage), 15_000);
    }

    #[test]
    fn missing_cache_fields_count_as_zero() {
        let usage: Usage = serde_json::from_str(
            r#"{"input_tokens": 5, "output_tokens": 1, "cache_read_input_tokens": null}"#,
        )
        .unwrap();
        assert_eq!(usage.cache_read_input_tokens, 0);
        assert_eq!(usage.cache_creation_input_tokens, 0);
    }
}
