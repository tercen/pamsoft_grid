/// Dump MATLAB vs Rust spot comparison to JSON for visualization
use pamsoft_grid::config::GridParams;
use pamsoft_grid::grid::process_gridding;
use pamsoft_grid::io::{load_tiff_image, read_layout_file};
use pamsoft_grid::segmentation::segment_image;
use pamsoft_grid::types::Spot;
use std::collections::HashMap;
use std::path::PathBuf;
use std::io::Write;

const TARGET_IMAGE: &str = "631402617_W1_F1_T10_P92_I433_A29";

/// Column indices for table1.csv (Tercen format)
mod table1_col {
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

/// Column indices for matlab_docker_output.csv (MATLAB direct output)
mod docker_col {
    pub const ID: usize = 0;
    pub const IS_REFERENCE: usize = 1;
    pub const SPOT_ROW: usize = 2;
    pub const SPOT_COL: usize = 3;
    pub const GRID_X: usize = 6;
    pub const GRID_Y: usize = 7;
    pub const DIAMETER: usize = 8;
    pub const BAD: usize = 10;
    pub const EMPTY: usize = 11;
    pub const IMAGE_NAME: usize = 13;
}

fn parse_bool_field(val: &str) -> bool {
    val.trim().trim_matches('"').parse::<f64>().unwrap_or(0.0) != 0.0
}

struct MatlabRecord {
    id: String,
    is_reference: bool,
    row: f64,
    col: f64,
    grid_x: f64,
    grid_y: f64,
    diameter: f64,
    is_bad: bool,
    is_empty: bool,
}

fn load_table1_csv(path: &std::path::Path, image_name: &str) -> Vec<MatlabRecord> {
    let mut records = Vec::new();
    let mut rdr = csv::Reader::from_path(path).unwrap();
    for result in rdr.records() {
        let record = result.unwrap();
        let img = record.get(table1_col::IMAGE_NAME).unwrap_or("").trim_matches('"');
        if img != image_name { continue; }
        records.push(MatlabRecord {
            id: record.get(table1_col::ID).unwrap_or("").trim_matches('"').to_string(),
            is_reference: record.get(table1_col::IS_REFERENCE).unwrap_or("").trim_matches('"') == "TRUE",
            row: record.get(table1_col::SPOT_ROW).unwrap_or("0").parse().unwrap_or(0.0),
            col: record.get(table1_col::SPOT_COL).unwrap_or("0").parse().unwrap_or(0.0),
            grid_x: record.get(table1_col::GRID_X).unwrap_or("0").parse().unwrap_or(0.0),
            grid_y: record.get(table1_col::GRID_Y).unwrap_or("0").parse().unwrap_or(0.0),
            diameter: record.get(table1_col::DIAMETER).unwrap_or("0").parse().unwrap_or(0.0),
            is_bad: parse_bool_field(record.get(table1_col::BAD).unwrap_or("0")),
            is_empty: parse_bool_field(record.get(table1_col::EMPTY).unwrap_or("0")),
        });
    }
    records
}

fn load_docker_csv(path: &std::path::Path, image_name: &str) -> Vec<MatlabRecord> {
    let mut records = Vec::new();
    let mut rdr = csv::Reader::from_path(path).unwrap();
    for result in rdr.records() {
        let record = result.unwrap();
        let img = record.get(docker_col::IMAGE_NAME).unwrap_or("").trim_matches('"');
        if img != image_name { continue; }
        let is_ref_val: f64 = record.get(docker_col::IS_REFERENCE).unwrap_or("0").parse().unwrap_or(0.0);
        records.push(MatlabRecord {
            id: record.get(docker_col::ID).unwrap_or("").trim_matches('"').to_string(),
            is_reference: is_ref_val != 0.0,
            row: record.get(docker_col::SPOT_ROW).unwrap_or("0").parse().unwrap_or(0.0),
            col: record.get(docker_col::SPOT_COL).unwrap_or("0").parse().unwrap_or(0.0),
            grid_x: record.get(docker_col::GRID_X).unwrap_or("0").parse().unwrap_or(0.0),
            grid_y: record.get(docker_col::GRID_Y).unwrap_or("0").parse().unwrap_or(0.0),
            diameter: record.get(docker_col::DIAMETER).unwrap_or("0").parse().unwrap_or(0.0),
            is_bad: parse_bool_field(record.get(docker_col::BAD).unwrap_or("0")),
            is_empty: parse_bool_field(record.get(docker_col::EMPTY).unwrap_or("0")),
        });
    }
    records
}

fn run_comparison(matlab_data: &[MatlabRecord], image_path: &std::path::Path, out_path: &std::path::Path) {
    let image = load_tiff_image(image_path).expect("Failed to load image");

    let mut initial_spots: Vec<Spot> = matlab_data.iter().map(|m| Spot {
        id: m.id.clone(),
        is_reference: m.is_reference,
        row: m.row as i32,
        col: m.col as i32,
        x_offset: 0.0, y_offset: 0.0,
        x_fixed: 0.0, y_fixed: 0.0,
        grid_x: m.grid_x, grid_y: m.grid_y,
        initial_x: m.grid_x, initial_y: m.grid_y,
        diameter: 0.0,
        is_manual: false, is_found: false,
        is_bad: false, is_empty: false,
        rotation: 0.0,
    }).collect();

    // Run Rust segmentation
    let mut params = GridParams::default();
    params.spot_pitch = 21.5;
    params.spot_size = 0.66;
    params.min_diameter = 0.45;
    params.max_diameter = 0.85;
    params.edge_sensitivity = [0.0, 0.01];

    let mut rust_results = initial_spots.clone();
    segment_image(&image, &mut rust_results, &params).expect("Segmentation failed");

    // Dump to JSON
    let mut f = std::fs::File::create(out_path).unwrap();
    write!(f, "[\n").unwrap();
    for (i, (m, rs)) in matlab_data.iter().zip(rust_results.iter()).enumerate() {
        let comma = if i < matlab_data.len() - 1 { "," } else { "" };
        write!(f, "  {{\"id\":\"{}\",\"is_ref\":{},\"matlab_x\":{:.2},\"matlab_y\":{:.2},\"matlab_d\":{:.2},\"matlab_bad\":{},\"matlab_empty\":{},\"rust_x\":{:.2},\"rust_y\":{:.2},\"rust_d\":{:.2},\"rust_bad\":{},\"rust_empty\":{}}}{}\n",
            m.id, m.is_reference, m.grid_x, m.grid_y, m.diameter, m.is_bad, m.is_empty,
            rs.grid_x, rs.grid_y, rs.diameter, rs.is_bad, rs.is_empty, comma
        ).unwrap();
    }
    write!(f, "]\n").unwrap();
    eprintln!("Wrote {}", out_path.display());
}

#[test]
#[ignore]
fn dump_spot_comparison_json() {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent().unwrap().join("tests");
    let image_dir = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("ImageResults");
    let image_path = image_dir.join(format!("{}.tif", TARGET_IMAGE));

    let matlab_data = load_table1_csv(&test_dir.join("table1.csv"), TARGET_IMAGE);
    assert!(!matlab_data.is_empty(), "No spots found for {}", TARGET_IMAGE);
    eprintln!("Loaded {} spots from table1.csv", matlab_data.len());

    run_comparison(&matlab_data, &image_path, &test_dir.join("spot_comparison.json"));
}

#[test]
#[ignore]
fn dump_spot_comparison_docker_json() {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent().unwrap().join("tests");
    let image_dir = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("ImageResults");
    let image_path = image_dir.join(format!("{}.tif", TARGET_IMAGE));

    let docker_csv = test_dir.join("matlab_docker_output.csv");
    assert!(docker_csv.exists(), "Docker CSV not found: {:?}. Run tests/run_matlab_docker.sh first.", docker_csv);

    let matlab_data = load_docker_csv(&docker_csv, TARGET_IMAGE);
    assert!(!matlab_data.is_empty(), "No spots found for {}", TARGET_IMAGE);
    eprintln!("Loaded {} spots from Docker CSV", matlab_data.len());

    run_comparison(&matlab_data, &image_path, &test_dir.join("spot_comparison.json"));
}

/// Write comparison JSON from pre-matched (matlab, rust) spot pairs
fn write_comparison_json(
    pairs: &[(MatlabRecord, Spot)],
    out_path: &std::path::Path,
) {
    let mut f = std::fs::File::create(out_path).unwrap();
    write!(f, "[\n").unwrap();
    for (i, (m, rs)) in pairs.iter().enumerate() {
        let comma = if i < pairs.len() - 1 { "," } else { "" };
        write!(f, "  {{\"id\":\"{}\",\"is_ref\":{},\"matlab_x\":{:.2},\"matlab_y\":{:.2},\"matlab_d\":{:.2},\"matlab_bad\":{},\"matlab_empty\":{},\"rust_x\":{:.2},\"rust_y\":{:.2},\"rust_d\":{:.2},\"rust_bad\":{},\"rust_empty\":{}}}{}\n",
            m.id, m.is_reference, m.grid_x, m.grid_y, m.diameter, m.is_bad, m.is_empty,
            rs.grid_x, rs.grid_y, rs.diameter, rs.is_bad, rs.is_empty, comma
        ).unwrap();
    }
    write!(f, "]\n").unwrap();
    eprintln!("Wrote {} spot pairs to {}", pairs.len(), out_path.display());
}

#[test]
#[ignore]
fn dump_end_to_end_comparison() {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent().unwrap().join("tests");
    let data_dir = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240");
    let image_path = data_dir.join("ImageResults").join(format!("{}.tif", TARGET_IMAGE));
    let layout_path = data_dir.join("631402617_631402618_631402619 86312 Array Layout.txt");

    // Load MATLAB Docker ground truth
    let docker_csv = test_dir.join("matlab_docker_output.csv");
    assert!(docker_csv.exists(), "Run tests/run_matlab_docker.sh first");
    let matlab_data = load_docker_csv(&docker_csv, TARGET_IMAGE);
    eprintln!("MATLAB Docker: {} spots for {}", matlab_data.len(), TARGET_IMAGE);

    // --- Full Rust pipeline ---
    // 1. Load image
    let image = load_tiff_image(&image_path).expect("Failed to load image");
    eprintln!("Image: {}x{}", image.width, image.height);

    // 2. Load layout
    let layout = read_layout_file(&layout_path).expect("Failed to read layout");
    eprintln!("Layout: {} spots", layout.len());

    // 3. Gridding (FFT center detection + grid generation + refinement)
    let params = GridParams {
        spot_pitch: 21.5,
        spot_size: 0.66,
        min_diameter: 0.45,
        max_diameter: 0.85,
        edge_sensitivity: [0.0, 0.01],
        rotation_range: vec![
            -2.0, -1.75, -1.5, -1.25, -1.0, -0.75, -0.5, -0.25,
            0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0,
        ],
        ..GridParams::default()
    };

    let mut rust_spots = process_gridding(&[image.clone()], &layout, &params)
        .expect("Gridding failed");
    eprintln!("Gridding produced {} spots", rust_spots.len());

    // Print a few grid positions for comparison
    for s in rust_spots.iter().take(5) {
        eprintln!("  Rust grid: {} (row={}, col={}) -> ({:.1}, {:.1})",
            s.id, s.row, s.col, s.grid_x, s.grid_y);
    }

    // 4. Segmentation
    segment_image(&image, &mut rust_spots, &params)
        .expect("Segmentation failed");

    let rust_good = rust_spots.iter().filter(|s| !s.is_bad && !s.is_empty).count();
    eprintln!("Rust: {} good / {} total after segmentation", rust_good, rust_spots.len());

    // --- Match Rust spots to MATLAB spots by (row, col) ---
    let mut rust_by_rc: HashMap<(i32, i32), &Spot> = HashMap::new();
    for s in &rust_spots {
        rust_by_rc.insert((s.row, s.col), s);
    }

    let mut pairs: Vec<(MatlabRecord, Spot)> = Vec::new();
    let mut unmatched_matlab = 0;

    for m in &matlab_data {
        let key = (m.row as i32, m.col as i32);
        if let Some(rs) = rust_by_rc.get(&key) {
            pairs.push((MatlabRecord {
                id: m.id.clone(),
                is_reference: m.is_reference,
                row: m.row,
                col: m.col,
                grid_x: m.grid_x,
                grid_y: m.grid_y,
                diameter: m.diameter,
                is_bad: m.is_bad,
                is_empty: m.is_empty,
            }, (*rs).clone()));
        } else {
            unmatched_matlab += 1;
            eprintln!("  No Rust spot for MATLAB row={}, col={} ({})", m.row, m.col, m.id);
        }
    }

    let matlab_rc: std::collections::HashSet<(i32, i32)> = matlab_data.iter()
        .map(|m| (m.row as i32, m.col as i32)).collect();
    let unmatched_rust = rust_spots.iter()
        .filter(|s| !matlab_rc.contains(&(s.row, s.col)))
        .count();

    eprintln!("\nMatching: {} matched, {} MATLAB unmatched, {} Rust unmatched",
        pairs.len(), unmatched_matlab, unmatched_rust);

    // Write comparison JSON
    write_comparison_json(&pairs, &test_dir.join("spot_comparison.json"));

    // Print summary stats
    let mut both_good = 0;
    let mut both_bad = 0;
    let mut miss = 0;
    let mut extra = 0;
    let mut pos_errors: Vec<f64> = Vec::new();

    for (m, rs) in &pairs {
        let mg = !m.is_bad && !m.is_empty;
        let rg = !rs.is_bad && !rs.is_empty;
        match (mg, rg) {
            (true, true) => {
                both_good += 1;
                let dx = rs.grid_x - m.grid_x;
                let dy = rs.grid_y - m.grid_y;
                pos_errors.push((dx * dx + dy * dy).sqrt());
            }
            (false, false) => both_bad += 1,
            (true, false) => miss += 1,
            (false, true) => extra += 1,
        }
    }

    eprintln!("\n=== END-TO-END: Rust (full pipeline) vs MATLAB Docker ===");
    let m_good = matlab_data.iter().filter(|m| !m.is_bad && !m.is_empty).count();
    eprintln!("MATLAB good: {}/{}", m_good, matlab_data.len());
    eprintln!("Rust good:   {}/{}", rust_good, rust_spots.len());
    eprintln!("Both good:   {}", both_good);
    eprintln!("Both bad:    {}", both_bad);
    eprintln!("Misses:      {} (MATLAB good, Rust not)", miss);
    eprintln!("Extras:      {} (Rust good, MATLAB not)", extra);
    if !pos_errors.is_empty() {
        let mean = pos_errors.iter().sum::<f64>() / pos_errors.len() as f64;
        let max = pos_errors.iter().cloned().fold(0.0f64, f64::max);
        let w3 = pos_errors.iter().filter(|e| **e <= 3.0).count();
        let w5 = pos_errors.iter().filter(|e| **e <= 5.0).count();
        eprintln!("Position error (both-good): mean={:.2}px, max={:.2}px", mean, max);
        eprintln!("  Within 3px: {}/{} ({:.1}%)", w3, pos_errors.len(), 100.0 * w3 as f64 / pos_errors.len() as f64);
        eprintln!("  Within 5px: {}/{} ({:.1}%)", w5, pos_errors.len(), 100.0 * w5 as f64 / pos_errors.len() as f64);
    }
}
