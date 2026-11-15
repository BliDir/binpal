//! What the app sends, and the checks every request passes before anything
//! costs money. Requests carry an install id (a random UUID the app makes, to
//! count per-install limits), an area id and content; never a location.

use base64::Engine;
use serde::{Deserialize, Serialize};

use crate::error::ApiError;
use crate::jpeg;
use crate::limits::*;

/// A rule from the app's local search that the photo might show.
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct Candidate {
    pub item_id: String,
    pub name_ja: String,
    pub name_en: String,
    /// The bundle's category id for the item.
    pub category: String,
}

#[derive(Debug, Deserialize)]
struct IdentifyBody {
    install_id: String,
    area_id: String,
    /// Base64 JPEG.
    image: String,
    candidates: Vec<Candidate>,
    /// On-device image labels and recognised recycling marks, for tuning the
    /// alias table. Not sent to the model.
    #[serde(default)]
    labels: Vec<String>,
    #[serde(default)]
    app_version: Option<String>,
}

/// A checked photo-check request.
#[derive(Debug, Clone)]
pub struct Identify {
    pub install_id: String,
    pub area_id: String,
    pub image: Vec<u8>,
    pub candidates: Vec<Candidate>,
    pub labels: Vec<String>,
    pub app_version: Option<String>,
}

pub fn parse_identify(body: &[u8]) -> Result<Identify, ApiError> {
    if body.len() > MAX_BODY_BYTES {
        return Err(ApiError::too_large("Request is too large"));
    }
    let raw: IdentifyBody =
        serde_json::from_slice(body).map_err(|e| ApiError::invalid(format!("Bad JSON: {e}")))?;
    check_install_id(&raw.install_id)?;
    check_area_id(&raw.area_id)?;

    let image = base64::engine::general_purpose::STANDARD
        .decode(raw.image.as_bytes())
        .map_err(|_| ApiError::invalid("image is not base64"))?;
    if image.len() > MAX_IMAGE_BYTES {
        return Err(ApiError::too_large(format!(
            "image is {} bytes; resize it to about 512 px (at most {MAX_IMAGE_BYTES} bytes)",
            image.len()
        )));
    }
    let (width, height) =
        jpeg::dimensions(&image).ok_or_else(|| ApiError::invalid("image is not a JPEG"))?;
    if width.max(height) > MAX_IMAGE_SIDE {
        return Err(ApiError::too_large(format!(
            "image is {width}x{height}; the longest side may be at most {MAX_IMAGE_SIDE} px"
        )));
    }

    if raw.candidates.is_empty() || raw.candidates.len() > MAX_CANDIDATES {
        return Err(ApiError::invalid(format!(
            "send 1 to {MAX_CANDIDATES} candidates"
        )));
    }
    for c in &raw.candidates {
        check_slug("item_id", &c.item_id)?;
        check_slug("category", &c.category)?;
        check_text("name_ja", &c.name_ja, MAX_NAME_CHARS)?;
        check_text("name_en", &c.name_en, MAX_NAME_CHARS)?;
    }
    if raw.labels.len() > MAX_LABELS {
        return Err(ApiError::invalid(format!(
            "send at most {MAX_LABELS} labels"
        )));
    }
    for label in &raw.labels {
        check_text("label", label, MAX_LABEL_CHARS)?;
    }
    if let Some(version) = &raw.app_version {
        check_text("app_version", version, 32)?;
    }

    Ok(Identify {
        install_id: raw.install_id.to_ascii_lowercase(),
        area_id: raw.area_id,
        image,
        candidates: raw.candidates,
        labels: raw.labels,
        app_version: raw.app_version,
    })
}

/// What a report says is wrong.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ReportKind {
    WrongCategory,
    WrongInstructions,
    WrongDay,
    MissingItem,
    Other,
}

impl ReportKind {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::WrongCategory => "wrong_category",
            Self::WrongInstructions => "wrong_instructions",
            Self::WrongDay => "wrong_day",
            Self::MissingItem => "missing_item",
            Self::Other => "other",
        }
    }
}

/// "This looks wrong" from the app.
#[derive(Debug, Clone, Deserialize)]
pub struct Report {
    pub install_id: String,
    pub area_id: String,
    #[serde(default)]
    pub item_id: Option<String>,
    pub kind: ReportKind,
    #[serde(default)]
    pub note: Option<String>,
    #[serde(default)]
    pub app_version: Option<String>,
}

pub fn parse_report(body: &[u8]) -> Result<Report, ApiError> {
    if body.len() > 4_000 {
        return Err(ApiError::too_large("Report is too large"));
    }
    let mut report: Report =
        serde_json::from_slice(body).map_err(|e| ApiError::invalid(format!("Bad JSON: {e}")))?;
    check_install_id(&report.install_id)?;
    check_area_id(&report.area_id)?;
    if let Some(item) = &report.item_id {
        check_slug("item_id", item)?;
    }
    if let Some(note) = &report.note {
        check_text("note", note, MAX_NOTE_CHARS)?;
    }
    if let Some(version) = &report.app_version {
        check_text("app_version", version, 32)?;
    }
    report.install_id = report.install_id.to_ascii_lowercase();
    Ok(report)
}

/// A UUID: 8-4-4-4-12 hex digits.
fn check_install_id(id: &str) -> Result<(), ApiError> {
    let groups: Vec<&str> = id.split('-').collect();
    let ok = groups.iter().map(|g| g.len()).eq([8, 4, 4, 4, 12])
        && groups
            .iter()
            .all(|g| g.bytes().all(|b| b.is_ascii_hexdigit()));
    ok.then_some(())
        .ok_or_else(|| ApiError::invalid("install_id must be a UUID"))
}

/// Ward or municipality code, a hyphen, and the 6-digit e-Stat small area.
fn check_area_id(id: &str) -> Result<(), ApiError> {
    let ok = id.len() == 12
        && id.bytes().enumerate().all(|(i, b)| {
            if i == 5 {
                b == b'-'
            } else {
                b.is_ascii_digit()
            }
        });
    ok.then_some(())
        .ok_or_else(|| ApiError::invalid("area_id must look like 14117-001001"))
}

/// Bundle ids: lowercase letters, digits and hyphens.
fn check_slug(field: &str, id: &str) -> Result<(), ApiError> {
    let ok = (1..=64).contains(&id.len())
        && id
            .bytes()
            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-');
    ok.then_some(())
        .ok_or_else(|| ApiError::invalid(format!("{field} must be a bundle id")))
}

fn check_text(field: &str, text: &str, max_chars: usize) -> Result<(), ApiError> {
    if text.chars().count() > max_chars {
        return Err(ApiError::invalid(format!(
            "{field} may be at most {max_chars} characters"
        )));
    }
    if text.chars().any(|c| c.is_control() && c != '\n') {
        return Err(ApiError::invalid(format!("{field} has control characters")));
    }
    Ok(())
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::jpeg::tests::jpeg;
    use serde_json::json;

    pub(crate) const INSTALL: &str = "7d0b6f0e-3b9a-4c2e-9f57-2b6f2a1c9e10";

    pub(crate) fn candidate(item_id: &str, category: &str) -> serde_json::Value {
        json!({"item_id": item_id, "name_ja": "かさ", "name_en": "Umbrella", "category": category})
    }

    fn body(image: &[u8], candidates: serde_json::Value) -> Vec<u8> {
        serde_json::to_vec(&json!({
            "install_id": INSTALL,
            "area_id": "14117-123002",
            "image": base64::engine::general_purpose::STANDARD.encode(image),
            "candidates": candidates,
            "labels": ["Umbrella", "PET"],
            "app_version": "1.0.0",
        }))
        .unwrap()
    }

    #[test]
    fn accepts_a_small_photo_with_candidates() {
        let request = parse_identify(&body(
            &jpeg(512, 384),
            json!([candidate("yokohama-10", "kinzoku")]),
        ))
        .unwrap();
        assert_eq!(request.area_id, "14117-123002");
        assert_eq!(request.candidates[0].item_id, "yokohama-10");
        assert_eq!(request.labels, ["Umbrella", "PET"]);
    }

    #[test]
    fn rejects_large_or_wrong_images() {
        let one = json!([candidate("yokohama-10", "kinzoku")]);
        let big = parse_identify(&body(&jpeg(4032, 3024), one.clone())).unwrap_err();
        assert_eq!(big.code, "payload_too_large");

        let mut heavy = jpeg(512, 384);
        heavy.resize(MAX_IMAGE_BYTES + 1, 0);
        assert_eq!(
            parse_identify(&body(&heavy, one.clone()))
                .unwrap_err()
                .status,
            413
        );

        let png = parse_identify(&body(b"\x89PNG\r\n\x1a\n", one)).unwrap_err();
        assert_eq!(png.code, "invalid_request");

        let huge = vec![b' '; MAX_BODY_BYTES + 1];
        assert_eq!(parse_identify(&huge).unwrap_err().status, 413);
    }

    #[test]
    fn rejects_too_many_or_odd_candidates() {
        let many: Vec<_> = (0..=MAX_CANDIDATES)
            .map(|i| candidate(&format!("yokohama-{i}"), "moyasu"))
            .collect();
        assert!(parse_identify(&body(&jpeg(512, 384), json!(many))).is_err());
        assert!(parse_identify(&body(&jpeg(512, 384), json!([]))).is_err());
        assert!(
            parse_identify(&body(
                &jpeg(512, 384),
                json!([candidate("Yokohama 10", "moyasu")])
            ))
            .is_err()
        );
    }

    #[test]
    fn ids_must_be_well_formed() {
        assert!(check_install_id(INSTALL).is_ok());
        assert!(check_install_id("not-a-uuid").is_err());
        assert!(check_area_id("14117-001001").is_ok());
        assert!(check_area_id("14117001001").is_err());
        assert!(check_area_id("35.56,139.55").is_err());
    }

    #[test]
    fn reads_reports() {
        let report = parse_report(
            br#"{"install_id":"7D0B6F0E-3B9A-4C2E-9F57-2B6F2A1C9E10","area_id":"14117-001001",
                "item_id":"yokohama-10","kind":"wrong_category","note":"Metal ribs go to small metal"}"#,
        )
        .unwrap();
        assert_eq!(report.kind, ReportKind::WrongCategory);
        assert_eq!(report.install_id, INSTALL);

        let unknown_kind = parse_report(
            br#"{"install_id":"7d0b6f0e-3b9a-4c2e-9f57-2b6f2a1c9e10","area_id":"14117-001001","kind":"spam"}"#,
        );
        assert!(unknown_kind.is_err());
    }
}
