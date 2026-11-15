//! Size limits and the daily allowances.

/// Largest request body accepted, before decoding.
pub const MAX_BODY_BYTES: usize = 200_000;

/// Largest photo accepted. The app sends about 512 px JPEGs well under
/// 100 KB; this leaves room without letting full-size photos through.
pub const MAX_IMAGE_BYTES: usize = 150_000;

/// Longest side of an accepted photo, in pixels.
pub const MAX_IMAGE_SIDE: u16 = 1024;

/// Candidate rules per photo. The app sends its top ~20.
pub const MAX_CANDIDATES: usize = 30;

/// On-device labels and recognised marks per photo, kept for tuning.
pub const MAX_LABELS: usize = 20;

pub const MAX_NAME_CHARS: usize = 100;
pub const MAX_LABEL_CHARS: usize = 64;
pub const MAX_NOTE_CHARS: usize = 500;

/// Allowances read from the Worker's variables.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Allowance {
    /// AI calls per install per day. Cached answers don't count.
    pub ai_calls_per_install: u32,
    /// Reports per install per day.
    pub reports_per_install: u32,
    /// Questions per install per day. Cached answers don't count.
    pub questions_per_install: u32,
    /// Spend on the Anthropic fallback per Japan day, across all installs, in
    /// millionths of a dollar.
    pub daily_budget_micro_usd: u64,
    /// Workers AI Neurons per UTC day. Kept under Cloudflare's free 10,000 so
    /// an account on Workers Paid is never billed for overage.
    pub workers_ai_daily_neurons: u64,
}

impl Allowance {
    /// Whether today's Anthropic spend leaves room for another call. Once the
    /// budget is reached the fallback stays off until the next Japan day.
    pub fn anthropic_available(&self, spent_today_micro_usd: u64) -> bool {
        spent_today_micro_usd < self.daily_budget_micro_usd
    }

    /// Whether today's free Workers AI Neurons have room for another call.
    pub fn workers_ai_available(&self, neurons_today: u64) -> bool {
        neurons_today < self.workers_ai_daily_neurons
    }
}

/// Dollars as millionths, from a variable such as `"5"` or `"2.50"`.
pub fn parse_usd(text: &str) -> Option<u64> {
    let dollars: f64 = text.trim().parse().ok()?;
    (dollars.is_finite() && dollars >= 0.0).then(|| (dollars * 1_000_000.0).round() as u64)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn each_model_stops_at_its_daily_limit() {
        let allowance = Allowance {
            ai_calls_per_install: 20,
            reports_per_install: 10,
            questions_per_install: 20,
            daily_budget_micro_usd: 5_000_000,
            workers_ai_daily_neurons: 9_000,
        };
        assert!(allowance.anthropic_available(0));
        assert!(allowance.anthropic_available(4_999_999));
        assert!(!allowance.anthropic_available(5_000_000));
        assert!(allowance.workers_ai_available(8_999));
        assert!(!allowance.workers_ai_available(9_000));
    }

    #[test]
    fn dollars_from_variables() {
        assert_eq!(parse_usd("5"), Some(5_000_000));
        assert_eq!(parse_usd(" 2.50 "), Some(2_500_000));
        assert_eq!(parse_usd("0"), Some(0));
        assert_eq!(parse_usd("-1"), None);
        assert_eq!(parse_usd("five"), None);
    }
}
