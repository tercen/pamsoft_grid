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
/// These parameters match MATLAB's default values from pg_io_get_default_params
#[derive(Debug, Clone)]
pub struct GridParams {
    // Quality Check Parameters (sqc* in MATLAB)
    /// Minimum spot diameter (relative to pitch) - MATLAB: sqcMinDiameter = 0.45
    pub min_diameter: f64,
    /// Maximum spot diameter (relative to pitch) - MATLAB: sqcMaxDiameter = 0.85
    pub max_diameter: f64,
    /// Minimum SNR for spot detection - MATLAB: sqcMinSnr = 1
    pub min_snr: f64,
    /// Maximum position offset for regular spots (relative to pitch) - MATLAB: sqcMaxPositionOffset = 0.4
    pub max_position_offset: f64,
    /// Maximum position offset for reference spots (relative to pitch) - MATLAB: sqcMaxPositionOffsetRefs = 0.6
    pub max_position_offset_refs: f64,

    // Grid Parameters (grd* in MATLAB)
    /// Spot pitch in pixels - MATLAB: grdSpotPitch = 21.5
    pub spot_pitch: f64,
    /// Spot size (relative) - MATLAB: grdSpotSize = 0.66
    pub spot_size: f64,
    /// Rotation angles to try (in degrees) - MATLAB: grdRotation = 0
    pub rotation_range: Vec<f64>,
    /// Search diameter for spot detection - MATLAB: grdSearchDiameter = 15
    pub search_diameter: f64,
    /// Array layout file path
    pub array_layout_file: Option<String>,

    // Segmentation Parameters (seg* in MATLAB)
    /// Saturation limit - MATLAB: qntSaturationLimit = 4095 (2^12-1)
    pub saturation_limit: f64,
    /// Segmentation method - MATLAB: segMethod = 'Edge'
    pub segmentation_method: SegmentationMethod,
    /// Grid detection method
    pub grid_detection_method: GridDetectionMethod,
    /// Edge sensitivity [low, high] - MATLAB: segEdgeSensitivity = [0, 0.01]
    pub edge_sensitivity: [f64; 2],
    /// Area size threshold (relative) - MATLAB: segAreaSize = 0.7
    pub area_size: f64,
    /// Minimum edge pixels - MATLAB: segMinEdgePixels = 6
    pub min_edge_pixels: usize,
    /// Background offset (relative) - MATLAB: segBgOffset = 0.45
    pub bg_offset: f64,

    // Preprocessing Parameters (prp* in MATLAB)
    /// Large disk size for preprocessing (relative) - MATLAB: prpLargeDisk = 0.51
    pub large_disk: f64,
    /// Small disk size for preprocessing (relative) - MATLAB: prpSmallDisk = 0.17
    pub small_disk: f64,
}

impl Default for GridParams {
    fn default() -> Self {
        // These defaults match MATLAB's pg_io_get_default_params
        Self {
            // Quality check parameters
            min_diameter: 0.45,
            max_diameter: 0.85,
            min_snr: 1.0,
            max_position_offset: 0.4,
            max_position_offset_refs: 0.6,

            // Grid parameters
            spot_pitch: 21.5,
            spot_size: 0.66,
            rotation_range: vec![0.0],
            search_diameter: 15.0,
            array_layout_file: None,

            // Segmentation parameters
            saturation_limit: 4095.0,  // 2^12-1 for 12-bit images
            segmentation_method: SegmentationMethod::Edge,
            grid_detection_method: GridDetectionMethod::Template,
            edge_sensitivity: [0.0, 0.01],  // MATLAB default
            area_size: 0.7,
            min_edge_pixels: 6,
            bg_offset: 0.45,

            // Preprocessing parameters
            large_disk: 0.51,
            small_disk: 0.17,
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
