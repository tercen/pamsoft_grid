use crate::error::{Error, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SegmentationMethod {
    Edge,
    Hough,
    Advanced, // Advanced Hough with adaptive thresholding
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum GridDetectionMethod {
    Template,  // Template matching (current)
    FFT,       // FFT-based frequency analysis
    Hybrid,    // Combination of both
}

impl std::str::FromStr for SegmentationMethod {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self> {
        match s.to_lowercase().as_str() {
            "edge" => Ok(SegmentationMethod::Edge),
            "hough" => Ok(SegmentationMethod::Hough),
            "advanced" => Ok(SegmentationMethod::Advanced),
            _ => Err(Error::InvalidParameter(format!(
                "Unknown segmentation method: {}",
                s
            ))),
        }
    }
}

impl std::str::FromStr for GridDetectionMethod {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self> {
        match s.to_lowercase().as_str() {
            "template" => Ok(GridDetectionMethod::Template),
            "fft" => Ok(GridDetectionMethod::FFT),
            "hybrid" => Ok(GridDetectionMethod::Hybrid),
            _ => Err(Error::InvalidParameter(format!(
                "Unknown grid detection method: {}",
                s
            ))),
        }
    }
}

/// Grid detection and processing parameters
#[derive(Debug, Clone)]
pub struct GridParams {
    /// Minimum spot diameter (relative)
    pub min_diameter: f64,
    /// Maximum spot diameter (relative)
    pub max_diameter: f64,
    /// Spot pitch in pixels
    pub spot_pitch: f64,
    /// Spot size (relative)
    pub spot_size: f64,
    /// Rotation angles to try (in degrees)
    pub rotation_range: Vec<f64>,
    /// Saturation limit
    pub saturation_limit: f64,
    /// Segmentation method
    pub segmentation_method: SegmentationMethod,
    /// Grid detection method
    pub grid_detection_method: GridDetectionMethod,
    /// Edge sensitivity [low, high]
    pub edge_sensitivity: [f64; 2],
    /// Array layout file path
    pub array_layout_file: Option<String>,
}

impl Default for GridParams {
    fn default() -> Self {
        Self {
            min_diameter: 0.45,
            max_diameter: 0.85,
            spot_pitch: 0.0,
            spot_size: 0.66,
            rotation_range: vec![],
            saturation_limit: 4095.0,
            segmentation_method: SegmentationMethod::Edge,
            grid_detection_method: GridDetectionMethod::Template,
            edge_sensitivity: [0.0, 0.05],
            array_layout_file: None,
        }
    }
}

impl GridParams {
    pub fn validate(&self) -> Result<()> {
        if self.min_diameter >= self.max_diameter {
            return Err(Error::InvalidParameter(
                "min_diameter must be less than max_diameter".to_string(),
            ));
        }

        if self.spot_pitch < 0.0 {
            return Err(Error::InvalidParameter(
                "spot_pitch must be non-negative".to_string(),
            ));
        }

        if self.spot_size <= 0.0 || self.spot_size > 1.0 {
            return Err(Error::InvalidParameter(
                "spot_size must be between 0 and 1".to_string(),
            ));
        }

        if self.edge_sensitivity[0] < 0.0 || self.edge_sensitivity[1] < 0.0 {
            return Err(Error::InvalidParameter(
                "edge_sensitivity values must be non-negative".to_string(),
            ));
        }

        Ok(())
    }
}
