//! # PamSoft Grid Library
//!
//! Image analysis library for processing PamGene array images.
//! Provides grid detection, spot segmentation, and quantification.

pub mod config;
pub mod error;
pub mod grid;
pub mod advanced_grid;
pub mod image_processing;
pub mod io;
pub mod quantification;
pub mod segmentation;
pub mod advanced_segmentation;
pub mod types;
pub mod batch;

pub use config::{GridParams, SegmentationMethod};
pub use error::{Error, Result};
pub use types::{ImageData, Spot, SpotResult, BatchConfig};

/// Library version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
    }
}
