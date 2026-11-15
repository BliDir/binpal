//! What the BinPal API decides, separate from how it runs on Cloudflare
//! Workers: request checks, the prompt sent to Claude, reading its answer,
//! what a call costs, and the daily limits.

pub mod answer;
pub mod catalog;
pub mod cost;
pub mod error;
pub mod jpeg;
pub mod keys;
pub mod limits;
pub mod prompt;
pub mod request;

pub use error::ApiError;
