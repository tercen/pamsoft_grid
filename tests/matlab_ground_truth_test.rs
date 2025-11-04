/// Integration test against MATLAB ground truth
/// This test validates that Phase 2 accuracy is maintained

use pamsoft_grid::config::GridParams;
use pamsoft_grid::io::load_tiff;
use pamsoft_grid::segmentation::segment_spots;
use pamsoft_grid::types::Spot;
use std::path::PathBuf;

#[derive(Debug)]
struct MatlabSpot {
    id: String,
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

fn load_matlab_ground_truth() -> Result<Vec<MatlabSpot>, Box<dyn std::error::Error>> {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).parent().unwrap().join("tests");
    let matlab_file = test_dir.join("table1.csv");

    let mut matlab_spots = Vec::new();
    let mut rdr = csv::Reader::from_path(matlab_file)?;

    for result in rdr.records() {
        let record = result?;

        let id = record.get(0).unwrap_or("").to_string(); // ds1.ID
        let grid_x: f64 = record.get(5).unwrap_or("0").parse().unwrap_or(0.0); // ds1.gridX
        let grid_y: f64 = record.get(6).unwrap_or("0").parse().unwrap_or(0.0); // ds1.gridY
        let diameter: f64 = record.get(7).unwrap_or("0").parse().unwrap_or(0.0); // ds1.diameter
        let is_bad = record.get(10).unwrap_or("FALSE") == "TRUE"; // ds1.bad
        let is_empty = record.get(11).unwrap_or("FALSE") == "TRUE"; // ds1.empty

        matlab_spots.push(MatlabSpot {
            id,
            grid_x,
            grid_y,
            diameter,
            is_bad,
            is_empty,
        });
    }

    Ok(matlab_spots)
}

fn load_initial_spots() -> Result<Vec<Spot>, Box<dyn std::error::Error>> {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).parent().unwrap().join("tests");
    let results_file = test_dir.join("table1.csv");

    let mut spots = Vec::new();
    let mut rdr = csv::Reader::from_path(results_file)?;

    for result in rdr.records() {
        let record = result?;

        let id = record.get(0).unwrap_or("").to_string();
        let is_reference = record.get(1).unwrap_or("FALSE") == "TRUE";
        let row: usize = record.get(2).unwrap_or("0").parse().unwrap_or(0);
        let col: usize = record.get(3).unwrap_or("0").parse().unwrap_or(0);
        let grid_x: f64 = record.get(5).unwrap_or("0").parse().unwrap_or(0.0);
        let grid_y: f64 = record.get(6).unwrap_or("0").parse().unwrap_or(0.0);

        spots.push(Spot {
            id,
            is_reference,
            row,
            col,
            fixed_x: 0.0,
            fixed_y: 0.0,
            grid_x,
            grid_y,
            diameter: 0.0,
            is_manual: false,
            is_bad: false,
            is_empty: false,
        });
    }

    Ok(spots)
}

fn compare_results(matlab: &[MatlabSpot], rust: &[Spot]) -> ComparisonStats {
    let mut position_errors = Vec::new();
    let mut diameter_errors = Vec::new();
    let mut within_2px = 0;
    let mut within_3px = 0;

    let rust_success_count = rust.iter().filter(|s| !s.is_bad && !s.is_empty).count();
    let matlab_success_count = matlab.iter().filter(|s| !s.is_bad && !s.is_empty).count();

    // Match spots by ID
    for matlab_spot in matlab {
        if let Some(rust_spot) = rust.iter().find(|s| s.id == matlab_spot.id) {
            // Only compare successful detections
            if !matlab_spot.is_bad && !matlab_spot.is_empty &&
               !rust_spot.is_bad && !rust_spot.is_empty {
                // Position error
                let dx = rust_spot.grid_x - matlab_spot.grid_x;
                let dy = rust_spot.grid_y - matlab_spot.grid_y;
                let pos_error = (dx * dx + dy * dy).sqrt();
                position_errors.push(pos_error);

                if pos_error <= 2.0 {
                    within_2px += 1;
                }
                if pos_error <= 3.0 {
                    within_3px += 1;
                }

                // Diameter error
                let diam_error = (rust_spot.diameter - matlab_spot.diameter).abs();
                diameter_errors.push(diam_error);
            }
        }
    }

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
#[ignore] // Run with: cargo test -- --ignored --test-threads=1
fn test_p92_matlab_ground_truth_regression() {
    // This test validates Phase 2 results against MATLAB ground truth
    // Run with: cargo test --test matlab_ground_truth_test -- --ignored --test-threads=1

    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).parent().unwrap().join("tests");
    let image_dir = test_dir.join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("ImageResults");
    let image_path = image_dir.join("631402617_W1_F1_T10_P92_I433_A29.tif");

    // Load test image
    println!("Loading test image: {:?}", image_path);
    let image = load_tiff(&image_path)
        .expect("Failed to load test image");

    // Load initial spots (with grid coordinates from MATLAB)
    println!("Loading initial spots...");
    let initial_spots = load_initial_spots()
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
    let rust_results = segment_spots(&image, &initial_spots, &params)
        .expect("Segmentation failed");

    // Load MATLAB ground truth
    println!("Loading MATLAB ground truth...");
    let matlab_results = load_matlab_ground_truth()
        .expect("Failed to load MATLAB ground truth");

    println!("MATLAB spots: {}", matlab_results.len());
    println!("Rust spots: {}", rust_results.len());

    // Compare results
    let stats = compare_results(&matlab_results, &rust_results);

    // Print statistics
    println!("\n=== REGRESSION TEST RESULTS ===");
    println!("Total spots: {}", stats.total_spots);
    println!("MATLAB success: {} ({:.1}%)",
             stats.matlab_success_count,
             100.0 * stats.matlab_success_count as f64 / stats.total_spots as f64);
    println!("Rust success: {} ({:.1}%)",
             stats.rust_success_count,
             100.0 * stats.success_rate());
    println!("\nPosition accuracy (for successful detections):");
    println!("  Mean error: {:.2} px", stats.mean_position_error());
    println!("  Within 2px: {} ({:.1}%)", stats.within_2px, 100.0 * stats.within_2px_ratio());
    println!("  Within 3px: {} ({:.1}%)", stats.within_3px, 100.0 * stats.within_3px_ratio());
    println!("\nDiameter accuracy:");
    println!("  Mean error: {:.2} px", stats.mean_diameter_error());

    // Assert Phase 2 baseline metrics
    assert!(stats.success_rate() >= 0.95,
        "SUCCESS RATE REGRESSION: Expected ≥95%, got {:.1}%",
        100.0 * stats.success_rate());

    assert!(stats.mean_position_error() <= 2.5,
        "POSITION ERROR REGRESSION: Expected ≤2.5px, got {:.2}px",
        stats.mean_position_error());

    assert!(stats.mean_diameter_error() <= 1.0,
        "DIAMETER ERROR REGRESSION: Expected ≤1.0px, got {:.2}px",
        stats.mean_diameter_error());

    assert!(stats.within_2px_ratio() >= 0.70,
        "POSITION ACCURACY REGRESSION: Expected ≥70% within 2px, got {:.1}%",
        100.0 * stats.within_2px_ratio());

    println!("\n✅ All regression tests passed!");
    println!("Phase 2 accuracy maintained:");
    println!("  - Success rate: {:.1}%", 100.0 * stats.success_rate());
    println!("  - Position error: {:.2}px", stats.mean_position_error());
    println!("  - Diameter error: {:.2}px", stats.mean_diameter_error());
}
