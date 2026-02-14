/// Integration test against MATLAB ground truth
/// This test validates that segmentation accuracy matches MATLAB's pamsoft_grid

use pamsoft_grid::config::GridParams;
use pamsoft_grid::io::load_tiff_image;
use pamsoft_grid::segmentation::segment_image;
use pamsoft_grid::types::Spot;
use std::path::PathBuf;

/// Target image name used for single-image regression test
const TARGET_IMAGE: &str = "631402617_W1_F1_T10_P92_I433_A29";

/// CSV column indices (0-based, after header skip)
/// Header: .ci, ds1.IsReference, ds1.ID, ds1.spotRow, ds1.spotCol,
///         ds1.grdXFixedPosition, ds1.grdYFixedPosition, ds1.gridX, ds1.gridY,
///         ds1.diameter, ds1.manual, ds1.bad, ds1.empty, ds1.grdRotation,
///         ds1.grdImageNameUsed
mod col {
    pub const IS_REFERENCE: usize = 1;
    pub const ID: usize = 2;
    pub const SPOT_ROW: usize = 3;
    pub const SPOT_COL: usize = 4;
    pub const GRID_X: usize = 7;
    pub const GRID_Y: usize = 8;
    pub const DIAMETER: usize = 9;
    pub const BAD: usize = 11;
    pub const EMPTY: usize = 12;
    pub const IMAGE_NAME: usize = 14;
}

#[derive(Debug)]
struct MatlabSpot {
    id: String,
    row: i32,
    col: i32,
    grid_x: f64,
    grid_y: f64,
    diameter: f64,
    is_bad: bool,
    is_empty: bool,
}

#[derive(Debug)]
struct ComparisonStats {
    total_spots: usize,
    rust_success_count: usize,
    matlab_success_count: usize,
    position_errors: Vec<f64>,
    diameter_errors: Vec<f64>,
    within_2px: usize,
    within_3px: usize,
}

impl ComparisonStats {
    fn success_rate(&self) -> f64 {
        self.rust_success_count as f64 / self.total_spots as f64
    }

    fn mean_position_error(&self) -> f64 {
        if self.position_errors.is_empty() {
            return 0.0;
        }
        self.position_errors.iter().sum::<f64>() / self.position_errors.len() as f64
    }

    fn mean_diameter_error(&self) -> f64 {
        if self.diameter_errors.is_empty() {
            return 0.0;
        }
        self.diameter_errors.iter().sum::<f64>() / self.diameter_errors.len() as f64
    }

    fn within_2px_ratio(&self) -> f64 {
        if self.position_errors.is_empty() {
            return 0.0;
        }
        self.within_2px as f64 / self.position_errors.len() as f64
    }

    fn within_3px_ratio(&self) -> f64 {
        if self.position_errors.is_empty() {
            return 0.0;
        }
        self.within_3px as f64 / self.position_errors.len() as f64
    }
}

fn csv_path() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("tests")
        .join("table1.csv")
}

/// Parse a CSV float field as bool (MATLAB uses 0.0/1.0)
fn parse_bool_field(val: &str) -> bool {
    val.trim().trim_matches('"').parse::<f64>().unwrap_or(0.0) != 0.0
}

/// Load MATLAB ground truth for a specific image
fn load_matlab_ground_truth(image_name: &str) -> Result<Vec<MatlabSpot>, Box<dyn std::error::Error>> {
    let mut matlab_spots = Vec::new();
    let mut rdr = csv::Reader::from_path(csv_path())?;

    for result in rdr.records() {
        let record = result?;

        // Filter by image name
        let img = record.get(col::IMAGE_NAME).unwrap_or("").trim_matches('"');
        if img != image_name {
            continue;
        }

        let id = record.get(col::ID).unwrap_or("").trim_matches('"').to_string();
        let row: f64 = record.get(col::SPOT_ROW).unwrap_or("0").parse().unwrap_or(0.0);
        let col_val: f64 = record.get(col::SPOT_COL).unwrap_or("0").parse().unwrap_or(0.0);
        let grid_x: f64 = record.get(col::GRID_X).unwrap_or("0").parse().unwrap_or(0.0);
        let grid_y: f64 = record.get(col::GRID_Y).unwrap_or("0").parse().unwrap_or(0.0);
        let diameter: f64 = record.get(col::DIAMETER).unwrap_or("0").parse().unwrap_or(0.0);
        let is_bad = parse_bool_field(record.get(col::BAD).unwrap_or("0"));
        let is_empty = parse_bool_field(record.get(col::EMPTY).unwrap_or("0"));

        matlab_spots.push(MatlabSpot {
            id,
            row: row as i32,
            col: col_val as i32,
            grid_x,
            grid_y,
            diameter,
            is_bad,
            is_empty,
        });
    }

    Ok(matlab_spots)
}

/// Load initial spots from MATLAB ground truth (using MATLAB gridX/gridY as starting positions)
fn load_initial_spots(image_name: &str) -> Result<Vec<Spot>, Box<dyn std::error::Error>> {
    let mut spots = Vec::new();
    let mut rdr = csv::Reader::from_path(csv_path())?;

    for result in rdr.records() {
        let record = result?;

        // Filter by image name
        let img = record.get(col::IMAGE_NAME).unwrap_or("").trim_matches('"');
        if img != image_name {
            continue;
        }

        let id = record.get(col::ID).unwrap_or("").trim_matches('"').to_string();
        let is_reference = record.get(col::IS_REFERENCE).unwrap_or("").trim_matches('"') == "TRUE";
        let row: f64 = record.get(col::SPOT_ROW).unwrap_or("0").parse().unwrap_or(0.0);
        let col_val: f64 = record.get(col::SPOT_COL).unwrap_or("0").parse().unwrap_or(0.0);
        let grid_x: f64 = record.get(col::GRID_X).unwrap_or("0").parse().unwrap_or(0.0);
        let grid_y: f64 = record.get(col::GRID_Y).unwrap_or("0").parse().unwrap_or(0.0);

        spots.push(Spot {
            id,
            is_reference,
            row: row as i32,
            col: col_val as i32,
            x_offset: 0.0,
            y_offset: 0.0,
            x_fixed: 0.0,
            y_fixed: 0.0,
            grid_x,
            grid_y,
            initial_x: grid_x,
            initial_y: grid_y,
            diameter: 0.0,
            is_manual: false,
            is_found: false,
            is_bad: false,
            is_empty: false,
            rotation: 0.0,
        });
    }

    Ok(spots)
}

/// Compare Rust results against MATLAB ground truth by index
/// (spots are loaded in CSV order, so indices correspond)
fn compare_results(matlab: &[MatlabSpot], rust: &[Spot]) -> ComparisonStats {
    let mut position_errors = Vec::new();
    let mut diameter_errors = Vec::new();
    let mut within_2px = 0;
    let mut within_3px = 0;

    let rust_success_count = rust.iter().filter(|s| !s.is_bad && !s.is_empty).count();
    let matlab_success_count = matlab.iter().filter(|s| !s.is_bad && !s.is_empty).count();

    assert_eq!(matlab.len(), rust.len(),
        "MATLAB and Rust spot counts must match");

    // Flag agreement analysis
    let mut both_good = 0;
    let mut both_empty = 0;
    let mut matlab_good_rust_empty = 0;
    let mut matlab_empty_rust_good = 0;
    let mut matlab_bad_count = 0;
    let mut rust_bad_count = 0;

    // Compare by index (same CSV order)
    for (i, (matlab_spot, rust_spot)) in matlab.iter().zip(rust.iter()).enumerate() {
        let m_good = !matlab_spot.is_bad && !matlab_spot.is_empty;
        let r_good = !rust_spot.is_bad && !rust_spot.is_empty;

        if matlab_spot.is_bad { matlab_bad_count += 1; }
        if rust_spot.is_bad { rust_bad_count += 1; }

        match (m_good, r_good) {
            (true, true) => {
                both_good += 1;

                let dx = rust_spot.grid_x - matlab_spot.grid_x;
                let dy = rust_spot.grid_y - matlab_spot.grid_y;
                let pos_error = (dx * dx + dy * dy).sqrt();
                position_errors.push(pos_error);

                if pos_error <= 2.0 { within_2px += 1; }
                if pos_error <= 3.0 { within_3px += 1; }

                let diam_error = (rust_spot.diameter - matlab_spot.diameter).abs();
                diameter_errors.push(diam_error);
            }
            (true, false) => {
                matlab_good_rust_empty += 1;
                println!("  MISS: Spot {:3} '{}' (row={}, col={}) - MATLAB found, Rust missed",
                    i, matlab_spot.id, matlab_spot.row, matlab_spot.col);
            }
            (false, true) => {
                matlab_empty_rust_good += 1;
            }
            (false, false) => {
                both_empty += 1;
            }
        }
    }

    println!("\nFlag agreement:");
    println!("  Both good:                 {:3}", both_good);
    println!("  Both empty/bad:            {:3}", both_empty);
    println!("  MATLAB good, Rust empty:   {:3}  (Rust misses)", matlab_good_rust_empty);
    println!("  MATLAB empty, Rust good:   {:3}  (Rust extra detections)", matlab_empty_rust_good);
    println!("  MATLAB bad / Rust bad:     {:3} / {:3}", matlab_bad_count, rust_bad_count);

    ComparisonStats {
        total_spots: matlab.len(),
        rust_success_count,
        matlab_success_count,
        position_errors,
        diameter_errors,
        within_2px,
        within_3px,
    }
}

#[test]
#[ignore] // Run with: cargo test --test matlab_ground_truth_test -- --ignored --nocapture
fn test_p92_matlab_ground_truth_regression() {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("tests");
    let image_dir = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("ImageResults");
    let image_path = image_dir.join(format!("{}.tif", TARGET_IMAGE));

    // Load test image
    println!("Loading test image: {:?}", image_path);
    let image = load_tiff_image(&image_path)
        .expect("Failed to load test image");

    // Load initial spots for this image only
    println!("Loading initial spots for image: {}", TARGET_IMAGE);
    let initial_spots = load_initial_spots(TARGET_IMAGE)
        .expect("Failed to load initial spots");
    println!("Loaded {} spots", initial_spots.len());

    // Configure segmentation parameters (MATLAB-aligned)
    let mut params = GridParams::default();
    params.spot_pitch = 21.5;
    params.spot_size = 0.66;
    params.min_diameter = 0.45;
    params.max_diameter = 0.85;
    params.edge_sensitivity = [0.0, 0.01];

    // Run segmentation
    println!("Running segmentation...");
    let mut rust_results = initial_spots.clone();
    segment_image(&image, &mut rust_results, &params)
        .expect("Segmentation failed");

    // Load MATLAB ground truth for same image
    println!("Loading MATLAB ground truth...");
    let matlab_results = load_matlab_ground_truth(TARGET_IMAGE)
        .expect("Failed to load MATLAB ground truth");

    println!("MATLAB spots: {}", matlab_results.len());
    println!("Rust spots:   {}", rust_results.len());

    // Compare results
    let stats = compare_results(&matlab_results, &rust_results);

    // Print detailed results
    println!("\n=== REGRESSION TEST RESULTS ({}) ===", TARGET_IMAGE);
    println!("Total spots: {}", stats.total_spots);
    println!("MATLAB success: {} ({:.1}%)",
             stats.matlab_success_count,
             100.0 * stats.matlab_success_count as f64 / stats.total_spots as f64);
    println!("Rust success:   {} ({:.1}%)",
             stats.rust_success_count,
             100.0 * stats.success_rate());

    // Detection recall: how many MATLAB-found spots did Rust also find?
    let recall = if stats.matlab_success_count > 0 {
        stats.position_errors.len() as f64 / stats.matlab_success_count as f64
    } else {
        0.0
    };
    println!("\nDetection recall: {}/{} ({:.1}%) of MATLAB-found spots also found by Rust",
        stats.position_errors.len(), stats.matlab_success_count, 100.0 * recall);

    println!("\nPosition accuracy (for mutually successful detections):");
    println!("  Compared: {} spots", stats.position_errors.len());
    println!("  Mean error: {:.2} px", stats.mean_position_error());
    println!("  Within 2px: {} ({:.1}%)", stats.within_2px, 100.0 * stats.within_2px_ratio());
    println!("  Within 3px: {} ({:.1}%)", stats.within_3px, 100.0 * stats.within_3px_ratio());

    println!("\nDiameter accuracy:");
    println!("  Mean error: {:.2} px", stats.mean_diameter_error());

    // Print worst spots for debugging
    if !stats.position_errors.is_empty() {
        let mut errors_with_idx: Vec<(usize, f64)> = stats.position_errors.iter()
            .enumerate()
            .map(|(i, &e)| (i, e))
            .collect();
        errors_with_idx.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

        println!("\nWorst 5 position errors:");
        for (i, (idx, err)) in errors_with_idx.iter().take(5).enumerate() {
            let ms = &matlab_results[*idx];
            let rs = &rust_results[*idx];
            println!("  {}. Spot '{}' (row={}, col={}): {:.2}px  MATLAB({:.1},{:.1}) vs Rust({:.1},{:.1})",
                i + 1, ms.id, ms.row, ms.col, err,
                ms.grid_x, ms.grid_y, rs.grid_x, rs.grid_y);
        }
    }

    // Assert accuracy metrics (for spots where both succeeded)
    if !stats.position_errors.is_empty() {
        assert!(stats.mean_position_error() <= 2.5,
            "POSITION ERROR REGRESSION: Expected <=2.5px, got {:.2}px",
            stats.mean_position_error());

        assert!(stats.mean_diameter_error() <= 2.0,
            "DIAMETER ERROR REGRESSION: Expected <=2.0px, got {:.2}px",
            stats.mean_diameter_error());

        assert!(stats.within_3px_ratio() >= 0.70,
            "POSITION ACCURACY REGRESSION: Expected >=70% within 3px, got {:.1}%",
            100.0 * stats.within_3px_ratio());
    }

    // Assert detection recall (Rust should find most of what MATLAB finds)
    assert!(recall >= 0.50,
        "DETECTION RECALL REGRESSION: Expected >=50% of MATLAB detections, got {:.1}%",
        100.0 * recall);

    println!("\nAll regression tests passed!");
    println!("  - Recall: {:.1}% of MATLAB detections", 100.0 * recall);
    println!("  - Position error: {:.2}px (mean)", stats.mean_position_error());
    println!("  - Diameter error: {:.2}px (mean)", stats.mean_diameter_error());
    println!("  - Within 3px: {:.1}%", 100.0 * stats.within_3px_ratio());
}
