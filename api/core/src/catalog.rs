//! The municipality behind an area and its categories, read from the same
//! manifest and bundles the app downloads from the CDN.

use serde::{Deserialize, Serialize};

/// Bundle schema versions this API can read.
const SUPPORTED_BUNDLE_SCHEMAS: [u64; 1] = [1];

/// Where an area's data is: its municipality and current bundle.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct AreaHome {
    pub municipality_id: String,
    pub bundle_version: u64,
    pub bundle_path: String,
}

#[derive(Deserialize)]
struct Manifest {
    municipalities: Vec<ManifestMunicipality>,
}

#[derive(Deserialize)]
struct ManifestMunicipality {
    id: String,
    area_ids: Vec<String>,
    bundles: Vec<ManifestBundle>,
}

#[derive(Deserialize)]
struct ManifestBundle {
    schema_version: u64,
    bundle_version: u64,
    path: String,
}

/// The municipality that covers `area_id`, or None when BinPal has no
/// bundle for it, so requests for unknown areas cost nothing.
pub fn find_area(manifest_json: &[u8], area_id: &str) -> Result<Option<AreaHome>, String> {
    let manifest: Manifest =
        serde_json::from_slice(manifest_json).map_err(|e| format!("manifest: {e}"))?;
    Ok(manifest
        .municipalities
        .into_iter()
        .filter(|m| m.area_ids.iter().any(|a| a == area_id))
        .find_map(|m| {
            let bundle = m
                .bundles
                .into_iter()
                .find(|b| SUPPORTED_BUNDLE_SCHEMAS.contains(&b.schema_version))?;
            Some(AreaHome {
                municipality_id: m.id,
                bundle_version: bundle.bundle_version,
                bundle_path: bundle.path,
            })
        }))
}

/// One of a municipality's categories, as the model sees it.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct Category {
    pub id: String,
    pub name_ja: String,
    pub name_en: String,
    pub description_en: Option<String>,
}

/// A municipality's categories: the stable, cacheable part of every prompt
/// for its areas.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct CategoryGuide {
    pub municipality_id: String,
    pub bundle_version: u64,
    pub name_en: String,
    pub categories: Vec<Category>,
}

impl CategoryGuide {
    pub fn has(&self, category_id: &str) -> bool {
        self.categories.iter().any(|c| c.id == category_id)
    }
}

#[derive(Deserialize)]
struct Bundle {
    bundle_version: u64,
    municipality: BundleMunicipality,
    categories: Vec<BundleCategory>,
}

#[derive(Deserialize)]
struct BundleMunicipality {
    id: String,
    names: Names,
}

#[derive(Deserialize)]
struct BundleCategory {
    id: String,
    names: Names,
    #[serde(default)]
    description: Option<Texts>,
}

#[derive(Deserialize)]
struct Names {
    ja: String,
    en: String,
}

#[derive(Deserialize)]
struct Texts {
    en: Option<String>,
}

/// The category guide from a bundle. Only categories are kept; rules stay in
/// the app, which sends the candidates.
pub fn category_guide(bundle_json: &[u8]) -> Result<CategoryGuide, String> {
    let bundle: Bundle = serde_json::from_slice(bundle_json).map_err(|e| format!("bundle: {e}"))?;
    Ok(CategoryGuide {
        municipality_id: bundle.municipality.id,
        bundle_version: bundle.bundle_version,
        name_en: bundle.municipality.names.en,
        categories: bundle
            .categories
            .into_iter()
            .map(|c| Category {
                id: c.id,
                name_ja: c.names.ja,
                name_en: c.names.en,
                description_en: c.description.and_then(|d| d.en),
            })
            .collect(),
    })
}

/// A name in Japanese and English.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct Name {
    pub ja: String,
    pub en: String,
}

/// What a report is about, in words a reviewer can check against the
/// official source.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct ReportSubject {
    pub municipality_id: String,
    pub municipality: Name,
    pub bundle_version: u64,
    pub ward: Option<Name>,
    /// None when the bundle no longer has the area.
    pub area: Option<Name>,
    pub item: Option<ReportedItem>,
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct ReportedItem {
    pub name: Name,
    pub category: Name,
    pub source_url: String,
}

#[derive(Deserialize)]
struct SubjectBundle {
    bundle_version: u64,
    municipality: BundleMunicipality,
    #[serde(default)]
    wards: Vec<SubjectWard>,
    areas: Vec<SubjectArea>,
    categories: Vec<BundleCategory>,
    rules: Vec<SubjectRule>,
}

#[derive(Deserialize)]
struct SubjectWard {
    id: String,
    names: Names,
}

#[derive(Deserialize)]
struct SubjectArea {
    id: String,
    #[serde(default)]
    ward_id: Option<String>,
    names: Names,
}

#[derive(Deserialize)]
struct SubjectRule {
    item_id: String,
    names: Names,
    category: String,
    valid_from: String,
    #[serde(default)]
    valid_to: Option<String>,
    source_url: String,
}

fn name(n: &Names) -> Name {
    Name {
        ja: n.ja.clone(),
        en: n.en.clone(),
    }
}

/// The area, its ward and the item a report names, from the bundle. The
/// item is the rule valid on `on` (`YYYY-MM-DD`), or its latest version.
pub fn report_subject(
    bundle_json: &[u8],
    area_id: &str,
    item_id: Option<&str>,
    on: &str,
) -> Result<ReportSubject, String> {
    let bundle: SubjectBundle =
        serde_json::from_slice(bundle_json).map_err(|e| format!("bundle: {e}"))?;
    let area = bundle.areas.iter().find(|a| a.id == area_id);
    let ward = area
        .and_then(|a| a.ward_id.as_deref())
        .and_then(|w| bundle.wards.iter().find(|ward| ward.id == w));
    let item = item_id.and_then(|id| {
        let versions: Vec<&SubjectRule> = bundle.rules.iter().filter(|r| r.item_id == id).collect();
        let rule = versions
            .iter()
            .find(|r| {
                r.valid_from.as_str() <= on && r.valid_to.as_deref().is_none_or(|to| to >= on)
            })
            .or_else(|| {
                versions
                    .iter()
                    .max_by(|a, b| a.valid_from.cmp(&b.valid_from))
            })?;
        let category = bundle.categories.iter().find(|c| c.id == rule.category)?;
        Some(ReportedItem {
            name: name(&rule.names),
            category: name(&category.names),
            source_url: rule.source_url.clone(),
        })
    });
    Ok(ReportSubject {
        municipality_id: bundle.municipality.id.clone(),
        municipality: name(&bundle.municipality.names),
        bundle_version: bundle.bundle_version,
        ward: ward.map(|w| name(&w.names)),
        area: area.map(|a| name(&a.names)),
        item,
    })
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;

    /// The published Yokohama bundle in the data folder.
    pub(crate) fn yokohama() -> CategoryGuide {
        let bytes = std::fs::read("../../data/municipalities/14100/bundle.json").unwrap();
        category_guide(&bytes).unwrap()
    }

    #[test]
    fn finds_the_municipality_of_an_area() {
        let manifest = r#"{"schema_version":1,"municipalities":[{"id":"14100",
            "names":{"ja":"横浜市","kana":"よこはまし","en":"Yokohama City"},"ward_ids":["14117"],
            "area_ids":["14117-001001","14117-123002"],
            "bundles":[{"schema_version":2,"bundle_version":9,"path":"/bundles/14100/v2/9.json"},
                       {"schema_version":1,"bundle_version":3,"path":"/bundles/14100/3.json"}]}]}"#;
        assert_eq!(
            find_area(manifest.as_bytes(), "14117-123002").unwrap(),
            Some(AreaHome {
                municipality_id: "14100".into(),
                bundle_version: 3,
                bundle_path: "/bundles/14100/3.json".into(),
            })
        );
        assert_eq!(
            find_area(manifest.as_bytes(), "13112-001001").unwrap(),
            None
        );
        assert!(find_area(b"{}", "14117-123002").is_err());
    }

    #[test]
    fn names_what_a_report_is_about() {
        let bytes = std::fs::read("../../data/municipalities/14100/bundle.json").unwrap();
        let subject =
            report_subject(&bytes, "14117-068001", Some("yokohama-11"), "2026-11-15").unwrap();
        assert_eq!(subject.municipality.en, "Yokohama City");
        assert_eq!(subject.ward.unwrap().ja, "青葉区");
        assert_eq!(subject.area.unwrap().en, "Katsuradai 1-chome");
        let item = subject.item.unwrap();
        assert_eq!(item.name.en, "Antenna");
        assert_eq!(item.category.en, "Bulky waste");
        assert!(item.source_url.starts_with("https://"));

        let unknown = report_subject(&bytes, "14117-999999", Some("nope"), "2026-11-15").unwrap();
        assert_eq!((unknown.area, unknown.item), (None, None));
    }

    #[test]
    fn reads_the_categories_of_a_bundle() {
        let guide = yokohama();
        assert_eq!(guide.municipality_id, "14100");
        assert_eq!(guide.name_en, "Yokohama City");
        assert_eq!(guide.categories.len(), 12);
        assert!(guide.has("kan-bin-pet"));
        assert!(!guide.has("pet-bottle"));
        assert_eq!(guide.categories[0].name_en, "Burnable");
    }
}
