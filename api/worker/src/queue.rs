//! Files stored reports in the review queue, every five minutes.
//!
//! Reports about the same thing go on one issue (`binpal_api_core::review`):
//! a new issue for the first, a comment for later ones while it is open, and
//! a new issue again once a reviewer has closed it. A group that fails (the
//! CDN or GitHub down) stays unfiled and is tried again on the next run.

use std::collections::BTreeMap;

use binpal_api_core::ApiError;
use binpal_api_core::catalog::{AreaHome, report_subject};
use binpal_api_core::keys::japan_day;
use binpal_api_core::review::{
    AREA_WINDOW_DAYS, LABEL, PRIORITY_LABEL, PRIORITY_REPORTS, Queued, comment_body, group_key,
    issue_body, title,
};
use worker::{Date, Env, console_error, console_log};

use crate::config::Config;
use crate::github::GitHub;
use crate::{catalog, store};

/// Reports filed per run; more wait for the next one.
const BATCH: u32 = 50;

const DAY_MILLIS: u64 = 86_400_000;

pub async fn file_reports(env: &Env) -> Result<(), ApiError> {
    let config = Config::from_env(env)?;
    let Some(token) = config.github_token.as_deref() else {
        return Ok(());
    };
    let github = GitHub {
        api_url: &config.github_api_url,
        repo: &config.github_repo,
        token,
    };
    let db = env.d1("DB").map_err(|_| ApiError::internal())?;
    let kv = env.kv("CACHE").map_err(|_| ApiError::internal())?;

    let reports = store::unfiled_reports(&db, BATCH).await?;
    if reports.is_empty() {
        return Ok(());
    }
    let mut groups: BTreeMap<String, (AreaHome, Vec<Queued>)> = BTreeMap::new();
    for report in reports {
        // An area dropped from the bundles since the report: kept, unfiled.
        let Some(home) = catalog::area_home(&kv, &config, &report.area_id).await? else {
            console_error!("report {} is for an area no longer covered", report.id);
            continue;
        };
        groups
            .entry(group_key(&home.municipality_id, &report))
            .or_insert_with(|| (home, Vec::new()))
            .1
            .push(report);
    }

    let since = japan_day(Date::now().as_millis() - AREA_WINDOW_DAYS * DAY_MILLIS);
    let mut bundles: BTreeMap<String, Vec<u8>> = BTreeMap::new();
    for (key, (home, reports)) in groups {
        let filed = file_group(
            &github,
            &config,
            &db,
            &mut bundles,
            &since,
            &key,
            &home,
            &reports,
        );
        match filed.await {
            Ok(number) => console_log!("filed {} report(s) on #{number}", reports.len()),
            Err(e) => console_error!("filing {key} failed: {}", e.message),
        }
    }
    Ok(())
}

#[allow(clippy::too_many_arguments)]
async fn file_group(
    github: &GitHub<'_>,
    config: &Config,
    db: &worker::D1Database,
    bundles: &mut BTreeMap<String, Vec<u8>>,
    since: &str,
    key: &str,
    home: &AreaHome,
    reports: &[Queued],
) -> Result<u64, ApiError> {
    let existing = store::report_issue(db, key).await?;
    let open = match &existing {
        Some(issue) if github.is_open(issue.issue_number as u64).await? => Some(issue),
        _ => None,
    };
    let total = open.map_or(0, |i| i.reports as u64) + reports.len() as u64;
    let mut busiest_area = 0;
    for report in reports {
        busiest_area =
            busiest_area.max(store::area_reports_since(db, &report.area_id, since).await?);
    }
    let priority = total >= PRIORITY_REPORTS || busiest_area >= PRIORITY_REPORTS;
    let ids: Vec<i64> = reports.iter().map(|r| r.id).collect();

    let number = if let Some(issue) = open {
        let number = issue.issue_number as u64;
        github
            .comment(number, &comment_body(reports, total))
            .await?;
        if priority && issue.priority == 0.0 {
            github.add_labels(number, &[PRIORITY_LABEL]).await?;
        }
        number
    } else {
        if !bundles.contains_key(&home.bundle_path) {
            bundles.insert(
                home.bundle_path.clone(),
                catalog::bundle(config, home).await?,
            );
        }
        let first = &reports[0];
        let on = first.date.as_deref().unwrap_or(&first.day);
        let subject = report_subject(
            &bundles[&home.bundle_path],
            &first.area_id,
            first.item_id.as_deref(),
            on,
        )
        .map_err(|e| {
            console_error!("{e}");
            ApiError::internal()
        })?;
        let labels: &[&str] = if priority {
            &[LABEL, PRIORITY_LABEL]
        } else {
            &[LABEL]
        };
        github
            .create_issue(
                &title(&subject, first),
                &issue_body(&subject, first, reports),
                labels,
            )
            .await?
    };
    store::file_reports(db, key, number, total, priority, &ids).await?;
    Ok(number)
}
