//! Turning "this looks wrong" reports into issues in the review queue: the
//! same GitHub Issues the rule monitor opens (`data/scripts/monitor.py`).
//!
//! Reports about the same thing share one issue: an item (in its
//! municipality), a collection date in an area, or a kind of report in an
//! area. Issues carry [`LABEL`], and [`PRIORITY_LABEL`] once one thing or one
//! area has had [`PRIORITY_REPORTS`] reports.
//!
//! The repository is public. Issues hold only what the report says and the
//! bundle's names for it: never an install id. Comments are published as
//! sent, with mentions, links and HTML defused.

use crate::catalog::{Name, ReportSubject};

pub const LABEL: &str = "user-report";
pub const PRIORITY_LABEL: &str = "priority";

/// Reports about one thing, or in one area within [`AREA_WINDOW_DAYS`], that
/// make it a priority.
pub const PRIORITY_REPORTS: u64 = 3;
pub const AREA_WINDOW_DAYS: u64 = 30;

/// A stored report waiting to be filed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Queued {
    pub id: i64,
    /// The Japan day it was received, `YYYY-MM-DD`.
    pub day: String,
    pub area_id: String,
    pub item_id: Option<String>,
    pub date: Option<String>,
    pub kind: String,
    pub note: Option<String>,
    pub app_version: Option<String>,
}

/// Which issue a report belongs to.
pub fn group_key(municipality_id: &str, report: &Queued) -> String {
    match (&report.item_id, report.kind.as_str(), &report.date) {
        (Some(item), _, _) => format!("item:{municipality_id}:{item}"),
        (None, "wrong_day", Some(date)) => format!("day:{}:{date}", report.area_id),
        _ => format!("area:{}:{}", report.area_id, report.kind),
    }
}

fn kind_label(kind: &str) -> &'static str {
    match kind {
        "wrong_category" => "Wrong category",
        "wrong_instructions" => "Wrong instructions",
        "wrong_day" => "Wrong collection day",
        "missing_item" => "Missing item",
        _ => "Other",
    }
}

fn both(name: &Name) -> String {
    if name.ja == name.en {
        name.ja.clone()
    } else {
        format!("{} / {}", name.ja, name.en)
    }
}

/// "桂台一丁目, 青葉区" for the title; the area id when the bundle no longer
/// has it.
fn short_place(subject: &ReportSubject, area_id: &str) -> String {
    match (&subject.area, &subject.ward) {
        (Some(area), Some(ward)) => format!("{}, {} ({area_id})", area.ja, ward.ja),
        (Some(area), None) => format!("{} ({area_id})", area.ja),
        _ => area_id.to_string(),
    }
}

fn full_place(subject: &ReportSubject, area_id: &str) -> String {
    let area = subject
        .area
        .as_ref()
        .map_or_else(|| "not in the current bundle".to_string(), both);
    match &subject.ward {
        Some(ward) => format!("{area}, {} (`{area_id}`)", both(ward)),
        None => format!("{area} (`{area_id}`)"),
    }
}

/// The issue title for a group, from its first report.
pub fn title(subject: &ReportSubject, first: &Queued) -> String {
    match (&first.item_id, first.kind.as_str(), &first.date) {
        (Some(id), _, _) => match &subject.item {
            Some(item) => format!("User report: {} ({id})", both(&item.name)),
            None => format!("User report: item {id}"),
        },
        (None, "wrong_day", Some(date)) => format!(
            "User report: collection day {date} in {}",
            short_place(subject, &first.area_id)
        ),
        (None, kind, _) => format!(
            "User report: {} in {}",
            kind_label(kind).to_lowercase(),
            short_place(subject, &first.area_id)
        ),
    }
}

/// The issue body: what the reports are about, then the reports.
pub fn issue_body(subject: &ReportSubject, first: &Queued, reports: &[Queued]) -> String {
    let mut lines = vec![
        "Reported from the BinPal app. Check it against the official source, then fix the \
         bundle if it is wrong."
            .to_string(),
        String::new(),
    ];
    if let Some(id) = &first.item_id {
        match &subject.item {
            Some(item) => {
                lines.push(format!(
                    "**Item:** {} (`{id}`), now in {}",
                    both(&item.name),
                    both(&item.category)
                ));
                lines.push(format!("**Source:** {}", item.source_url));
            }
            None => lines.push(format!("**Item:** `{id}`, not in the current bundle")),
        }
    } else {
        if let Some(date) = &first.date {
            lines.push(format!("**Collection date:** {date}"));
        }
        lines.push(format!("**Area:** {}", full_place(subject, &first.area_id)));
    }
    lines.push(format!(
        "**Municipality:** {} (`{}`), bundle {}",
        both(&subject.municipality),
        subject.municipality_id,
        subject.bundle_version
    ));
    lines.push(String::new());
    lines.push("### Reports".to_string());
    lines.push(String::new());
    lines.push(table(reports));
    lines.push(String::new());
    lines.push(
        "_Comments are written by people using the app and shown as sent, with mentions and \
         links turned off._"
            .to_string(),
    );
    lines.join("\n")
}

/// A comment adding later reports to an open issue.
pub fn comment_body(reports: &[Queued], total: u64) -> String {
    let more = match reports.len() {
        1 => "1 more report".to_string(),
        n => format!("{n} more reports"),
    };
    format!("{more}, {total} in total:\n\n{}", table(reports))
}

fn table(reports: &[Queued]) -> String {
    let mut rows = vec![
        "| Received | Report | Area | Date | App | Comment |".to_string(),
        "| -- | -- | -- | -- | -- | -- |".to_string(),
    ];
    for r in reports {
        rows.push(format!(
            "| {} | {} | `{}` | {} | {} | {} |",
            r.day,
            kind_label(&r.kind),
            r.area_id,
            r.date.as_deref().unwrap_or(""),
            r.app_version.as_deref().map(cell).unwrap_or_default(),
            r.note.as_deref().map(cell).unwrap_or_default(),
        ));
    }
    rows.join("\n")
}

/// User text made safe for one table cell in a public issue: one line, no
/// table breaks, and no mentions, links, images or HTML.
fn cell(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    for c in text.trim().chars() {
        match c {
            '\n' | '\r' | '\t' => out.push(' '),
            '|' => out.push_str("\\|"),
            // A zero-width space stops @name from notifying anyone.
            '@' => out.push_str("@\u{200B}"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '[' | ']' | '!' | '`' | '*' | '_' | '#' | '\\' => {
                out.push('\\');
                out.push(c);
            }
            _ => out.push(c),
        }
    }
    // Bare URLs are linked by GitHub; break the scheme so they aren't.
    out.replace("://", ":\u{200B}//")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::catalog::ReportedItem;

    fn name(ja: &str, en: &str) -> Name {
        Name {
            ja: ja.into(),
            en: en.into(),
        }
    }

    fn subject(item: bool) -> ReportSubject {
        ReportSubject {
            municipality_id: "14100".into(),
            municipality: name("横浜市", "Yokohama City"),
            bundle_version: 3,
            ward: Some(name("青葉区", "Aoba Ward")),
            area: Some(name("桂台一丁目", "Katsuradai 1-chome")),
            item: item.then(|| ReportedItem {
                name: name("アンテナ", "Antenna"),
                category: name("粗大ごみ", "Bulky waste"),
                source_url: "https://www.city.yokohama.lg.jp/x".into(),
            }),
        }
    }

    fn report(kind: &str, item: Option<&str>, date: Option<&str>) -> Queued {
        Queued {
            id: 1,
            day: "2026-11-15".into(),
            area_id: "14117-068001".into(),
            item_id: item.map(Into::into),
            date: date.map(Into::into),
            kind: kind.into(),
            note: None,
            app_version: Some("1.1.0".into()),
        }
    }

    #[test]
    fn groups_by_item_date_or_area() {
        let category = report("wrong_category", Some("yokohama-11"), None);
        let mut instructions = report("wrong_instructions", Some("yokohama-11"), None);
        instructions.area_id = "14117-001001".into();
        assert_eq!(group_key("14100", &category), "item:14100:yokohama-11");
        // The same item from another area and about something else: one issue.
        assert_eq!(
            group_key("14100", &instructions),
            group_key("14100", &category)
        );

        let day = report("wrong_day", None, Some("2026-11-11"));
        assert_eq!(group_key("14100", &day), "day:14117-068001:2026-11-11");
        assert_ne!(
            group_key("14100", &day),
            group_key("14100", &report("wrong_day", None, Some("2026-11-12")))
        );
        assert_eq!(
            group_key("14100", &report("missing_item", None, None)),
            "area:14117-068001:missing_item"
        );
    }

    #[test]
    fn titles_name_the_thing_in_both_languages() {
        assert_eq!(
            title(
                &subject(true),
                &report("wrong_category", Some("yokohama-11"), None)
            ),
            "User report: アンテナ / Antenna (yokohama-11)"
        );
        assert_eq!(
            title(
                &subject(false),
                &report("wrong_category", Some("gone"), None)
            ),
            "User report: item gone"
        );
        assert_eq!(
            title(
                &subject(false),
                &report("wrong_day", None, Some("2026-11-11"))
            ),
            "User report: collection day 2026-11-11 in 桂台一丁目, 青葉区 (14117-068001)"
        );
        assert_eq!(
            title(&subject(false), &report("missing_item", None, None)),
            "User report: missing item in 桂台一丁目, 青葉区 (14117-068001)"
        );
    }

    #[test]
    fn the_body_says_what_to_check_and_lists_the_reports() {
        let first = report("wrong_category", Some("yokohama-11"), None);
        let body = issue_body(&subject(true), &first, std::slice::from_ref(&first));
        assert!(body.contains(
            "**Item:** アンテナ / Antenna (`yokohama-11`), now in 粗大ごみ / Bulky waste"
        ));
        assert!(body.contains("**Source:** https://www.city.yokohama.lg.jp/x"));
        assert!(body.contains("**Municipality:** 横浜市 / Yokohama City (`14100`), bundle 3"));
        assert!(body.contains("| 2026-11-15 | Wrong category | `14117-068001` |  | 1.1.0 |  |"));

        let day = report("wrong_day", None, Some("2026-11-11"));
        let body = issue_body(&subject(false), &day, std::slice::from_ref(&day));
        assert!(body.contains("**Collection date:** 2026-11-11"));
        assert!(body.contains(
            "**Area:** 桂台一丁目 / Katsuradai 1-chome, 青葉区 / Aoba Ward (`14117-068001`)"
        ));
    }

    #[test]
    fn later_reports_are_a_comment() {
        let r = report("wrong_category", Some("yokohama-11"), None);
        assert!(
            comment_body(std::slice::from_ref(&r), 2).starts_with("1 more report, 2 in total:")
        );
        assert!(comment_body(&[r.clone(), r], 4).starts_with("2 more reports, 4 in total:"));
    }

    #[test]
    fn comments_cannot_mention_link_or_break_the_table() {
        let cleaned =
            cell("Ask @octocat | see [this](https://evil.example) <img src=x>\n![x](y) `code` #1");
        assert!(!cleaned.contains("@octocat"));
        assert!(!cleaned.contains("https://"));
        assert!(!cleaned.contains("<img"));
        assert!(!cleaned.contains('\n'));
        assert!(!cleaned.contains(" | "));
        // Escaped brackets: Markdown makes no link or image of them.
        assert!(cleaned.contains("see \\[this\\]("));
        assert!(cleaned.contains("\\!\\[x\\]("));
        assert_eq!(
            cell("  燃えないごみの日は水曜日です  "),
            "燃えないごみの日は水曜日です"
        );
    }
}
