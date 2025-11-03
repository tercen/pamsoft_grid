use ndarray::Array2;
use serde::{Deserialize, Serialize};

/// Represents a single spot on the array
#[derive(Debug, Clone)]
pub struct Spot {
    pub id: String,
    pub row: i32,
    pub col: i32,
    pub is_reference: bool,
    pub x_offset: f64,      // Offset from ideal position (in units of spot_pitch)
    pub y_offset: f64,      // Offset from ideal position (in units of spot_pitch)
    pub x_fixed: f64,
    pub y_fixed: f64,
    pub grid_x: f64,
    pub grid_y: f64,
    pub diameter: f64,
    pub is_manual: bool,
    pub is_bad: bool,
    pub is_empty: bool,
    pub rotation: f64,
}

/// Result of spot quantification
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpotResult {
    #[serde(rename = "groupId")]
    pub group_id: String,

    #[serde(rename = "qntSpotID")]
    pub spot_id: String,

    #[serde(rename = "grdIsReference")]
    pub is_reference: bool,

    #[serde(rename = "grdRow")]
    pub row: f64,

    #[serde(rename = "grdCol")]
    pub col: f64,

    #[serde(rename = "grdXFixedPosition")]
    pub x_fixed: f64,

    #[serde(rename = "grdYFixedPosition")]
    pub y_fixed: f64,

    #[serde(rename = "gridX")]
    pub grid_x: f64,

    #[serde(rename = "gridY")]
    pub grid_y: f64,

    pub diameter: f64,

    #[serde(rename = "isManual")]
    pub is_manual: i32,

    #[serde(rename = "segIsBad")]
    pub is_bad: i32,

    #[serde(rename = "segIsEmpty")]
    pub is_empty: i32,

    #[serde(rename = "grdRotation")]
    pub rotation: f64,

    #[serde(rename = "grdImageNameUsed")]
    pub image_name: String,
}

/// Image data container
#[derive(Debug, Clone)]
pub struct ImageData {
    pub data: Array2<u16>,
    pub width: usize,
    pub height: usize,
    pub name: String,
}

impl ImageData {
    pub fn new(data: Array2<u16>, name: String) -> Self {
        let (height, width) = data.dim();
        Self {
            data,
            width,
            height,
            name,
        }
    }
}

/// Image type detection
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImageType {
    Evolve3,  // 552 x 413
    Evolve2,  // 697 x 520
    Unknown,
}

impl ImageType {
    pub fn detect(width: usize, height: usize) -> Self {
        match (width, height) {
            (552, 413) => ImageType::Evolve3,
            (697, 520) => ImageType::Evolve2,
            _ => ImageType::Unknown,
        }
    }

    pub fn default_spot_pitch(&self) -> Option<f64> {
        match self {
            ImageType::Evolve3 => Some(17.0),
            ImageType::Evolve2 => Some(21.5),
            ImageType::Unknown => None,
        }
    }
}

/// Configuration for a single image group
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GroupConfig {
    #[serde(rename = "groupId")]
    pub group_id: String,

    #[serde(rename = "sqcMinDiameter")]
    pub min_diameter: f64,

    #[serde(rename = "sqcMaxDiameter")]
    pub max_diameter: f64,

    #[serde(rename = "segEdgeSensitivity")]
    pub edge_sensitivity: Vec<f64>,

    #[serde(rename = "qntSeriesMode")]
    pub series_mode: i32,

    #[serde(rename = "qntShowPamGridViewer")]
    pub show_viewer: i32,

    #[serde(rename = "grdSpotPitch")]
    pub spot_pitch: f64,

    #[serde(rename = "grdSpotSize")]
    pub spot_size: f64,

    #[serde(rename = "grdRotation")]
    pub rotation: Vec<f64>,

    #[serde(rename = "qntSaturationLimit")]
    pub saturation_limit: f64,

    #[serde(rename = "segMethod")]
    pub seg_method: String,

    #[serde(rename = "grdUseImage")]
    pub use_image: String,

    #[serde(rename = "pgMode")]
    pub pg_mode: String,

    #[serde(rename = "dbgShowPresenter")]
    pub debug_show: i32,

    #[serde(rename = "arraylayoutfile")]
    pub array_layout_file: String,

    #[serde(rename = "imageslist")]
    pub images_list: Vec<String>,
}

/// Batch processing configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchConfig {
    pub mode: String,

    #[serde(rename = "numWorkers")]
    pub num_workers: usize,

    #[serde(rename = "progressFile")]
    pub progress_file: String,

    #[serde(rename = "outputFile")]
    pub output_file: String,

    #[serde(rename = "imageGroups")]
    pub image_groups: Vec<GroupConfig>,
}
