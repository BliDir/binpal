//! Reading the CDN's manifest and bundles, with results kept in KV so most
//! requests touch neither.

use binpal_api_core::ApiError;
use binpal_api_core::catalog::{AreaHome, CategoryGuide, category_guide, find_area};
use worker::{CfProperties, Fetch, KvStore, Method, Request, RequestInit, console_error};

use crate::config::Config;

const HOUR: u64 = 3600;

fn failed(what: &str, e: impl std::fmt::Display) -> ApiError {
    console_error!("{what}: {e}");
    ApiError::internal()
}

/// GETs a CDN path. The manifest is cached at the edge for five minutes, as
/// the app sees it; bundles never change once published.
async fn get(config: &Config, path: &str, edge_ttl: i32) -> Result<Vec<u8>, ApiError> {
    let mut init = RequestInit::new();
    init.with_method(Method::Get)
        .with_cf_properties(CfProperties {
            cache_ttl: Some(edge_ttl),
            cache_everything: Some(true),
            ..CfProperties::default()
        });
    let url = format!("{}{path}", config.cdn_base_url);
    let request = Request::new_with_init(&url, &init).map_err(|e| failed(&url, e))?;
    let mut response = Fetch::Request(request)
        .send()
        .await
        .map_err(|e| failed(&url, e))?;
    if response.status_code() != 200 {
        return Err(failed(&url, response.status_code()));
    }
    response.bytes().await.map_err(|e| failed(&url, e))
}

/// The municipality and bundle for an area, or None if BinPal doesn't cover
/// it. Both answers are kept in KV for an hour.
pub async fn area_home(
    kv: &KvStore,
    config: &Config,
    area_id: &str,
) -> Result<Option<AreaHome>, ApiError> {
    let key = format!("area:v1:{area_id}");
    if let Some(found) = kv
        .get(&key)
        .json::<Option<AreaHome>>()
        .await
        .map_err(|e| failed("KV", e))?
    {
        return Ok(found);
    }
    let manifest = get(config, "/manifest.json", 300).await?;
    let found = find_area(&manifest, area_id).map_err(|e| failed("manifest", e))?;
    kv.put(&key, &found)
        .map_err(|e| failed("KV", e))?
        .expiration_ttl(HOUR)
        .execute()
        .await
        .map_err(|e| failed("KV", e))?;
    Ok(found)
}

/// The category guide for a bundle. Bundles are immutable, so it is kept for
/// 30 days; only the first request after a publish reads the bundle.
pub async fn guide(
    kv: &KvStore,
    config: &Config,
    home: &AreaHome,
) -> Result<CategoryGuide, ApiError> {
    let key = format!("guide:v1:{}:{}", home.municipality_id, home.bundle_version);
    if let Some(guide) = kv
        .get(&key)
        .json::<CategoryGuide>()
        .await
        .map_err(|e| failed("KV", e))?
    {
        return Ok(guide);
    }
    let bundle = get(config, &home.bundle_path, 86_400).await?;
    let guide = category_guide(&bundle).map_err(|e| failed(&home.bundle_path, e))?;
    kv.put(&key, &guide)
        .map_err(|e| failed("KV", e))?
        .expiration_ttl(30 * 24 * HOUR)
        .execute()
        .await
        .map_err(|e| failed("KV", e))?;
    Ok(guide)
}
