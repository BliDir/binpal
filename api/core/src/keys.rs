//! Day boundaries and cache keys.

use sha2::{Digest, Sha256};

use crate::request::Candidate;

/// The date in Japan (UTC+9, no daylight saving) as `YYYY-MM-DD`. Daily
/// limits and the budget reset at midnight there, where the users are.
pub fn japan_day(unix_millis: u64) -> String {
    let days = (unix_millis / 1000 + 9 * 3600) / 86_400;
    let (y, m, d) = civil_from_days(days as i64);
    format!("{y:04}-{m:02}-{d:02}")
}

/// Days since 1970-01-01 to a calendar date (Howard Hinnant's algorithm).
fn civil_from_days(z: i64) -> (i64, u32, u32) {
    let z = z + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = (doy - (153 * mp + 2) / 5 + 1) as u32;
    let m = if mp < 10 { mp + 3 } else { mp - 9 } as u32;
    let y = yoe + era * 400 + i64::from(m <= 2);
    (y, m, d)
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

/// Where an answer is cached: the same photo, area, candidates and bundle
/// version get the same answer without calling the model again. The photo is
/// only hashed; it is never stored.
pub fn answer_key(
    image: &[u8],
    area_id: &str,
    bundle_version: u64,
    candidates: &[Candidate],
) -> String {
    let mut ids: Vec<&str> = candidates.iter().map(|c| c.item_id.as_str()).collect();
    ids.sort_unstable();
    let candidates_hash = Sha256::digest(ids.join("\n").as_bytes());
    format!(
        "answer:v1:{}:{area_id}:{bundle_version}:{}",
        hex(&Sha256::digest(image)),
        &hex(&candidates_hash)[..16]
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn days_change_at_midnight_in_japan() {
        // 2026-11-13T14:59:59Z is 23:59:59 in Japan; a second later it is the 14th.
        assert_eq!(japan_day(1_794_581_999_000), "2026-11-13");
        assert_eq!(japan_day(1_794_582_000_000), "2026-11-14");
        assert_eq!(japan_day(0), "1970-01-01");
        // Leap day.
        assert_eq!(japan_day(1_709_164_800_000), "2024-02-29");
    }

    fn candidate(id: &str) -> Candidate {
        Candidate {
            item_id: id.into(),
            name_ja: String::new(),
            name_en: String::new(),
            category: "moyasu".into(),
        }
    }

    #[test]
    fn the_answer_key_ignores_candidate_order() {
        let a = answer_key(
            b"photo",
            "14117-001001",
            3,
            &[candidate("a"), candidate("b")],
        );
        let b = answer_key(
            b"photo",
            "14117-001001",
            3,
            &[candidate("b"), candidate("a")],
        );
        assert_eq!(a, b);
        assert_ne!(
            a,
            answer_key(
                b"photo",
                "14117-001001",
                4,
                &[candidate("a"), candidate("b")]
            )
        );
        assert_ne!(
            a,
            answer_key(
                b"other",
                "14117-001001",
                3,
                &[candidate("a"), candidate("b")]
            )
        );
        assert!(a.starts_with("answer:v1:"));
    }
}
