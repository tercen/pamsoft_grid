use thiserror::Error;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Error, Debug)]
pub enum Error {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Image error: {0}")]
    Image(#[from] image::ImageError),

    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("CSV error: {0}")]
    Csv(#[from] csv::Error),

    #[error("Invalid parameter: {0}")]
    InvalidParameter(String),

    #[error("Invalid image dimensions: expected {expected}, got {actual}")]
    InvalidDimensions { expected: String, actual: String },

    #[error("Grid detection failed: {0}")]
    GridDetectionFailed(String),

    #[error("Segmentation failed: {0}")]
    SegmentationFailed(String),

    #[error("No valid spots found")]
    NoValidSpots,

    #[error("File not found: {0}")]
    FileNotFound(String),

    #[error("Invalid configuration: {0}")]
    InvalidConfiguration(String),

    #[error("Processing error: {0}")]
    ProcessingError(String),
}
