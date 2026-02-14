/// Dump MATLAB vs Rust spot comparison to JSON for visualization
use pamsoft_grid::config::GridParams;
use pamsoft_grid::io::load_tiff_image;
use pamsoft_grid::segmentation::segment_image;
use pamsoft_grid::types::Spot;
use std::path::PathBuf;
use std::io::Write;

const TARGET_IMAGE: &str = "631402617_W1_F1_T10_P92_I433_A29";

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

fn parse_bool_field(val: &str) -> bool {
    val.trim().trim_matches('"').parse::<f64>().unwrap_or(0.0) != 0.0
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

    let image = load_tiff_image(&image_path).expect("Failed to load image");

    // Load initial spots
    let csv_path = test_dir.join("table1.csv");
    let mut rdr = csv::Reader::from_path(&csv_path).unwrap();
    let mut initial_spots = Vec::new();
    let mut matlab_data = Vec::new();

    for result in rdr.records() {
        let record = result.unwrap();
        let img = record.get(col::IMAGE_NAME).unwrap_or("").trim_matches('"');
        if img != TARGET_IMAGE { continue; }

        let id = record.get(col::ID).unwrap_or("").trim_matches('"').to_string();
        let is_reference = record.get(col::IS_REFERENCE).unwrap_or("").trim_matches('"') == "TRUE";
        let row: f64 = record.get(col::SPOT_ROW).unwrap_or("0").parse().unwrap_or(0.0);
        let col_val: f64 = record.get(col::SPOT_COL).unwrap_or("0").parse().unwrap_or(0.0);
        let grid_x: f64 = record.get(col::GRID_X).unwrap_or("0").parse().unwrap_or(0.0);
        let grid_y: f64 = record.get(col::GRID_Y).unwrap_or("0").parse().unwrap_or(0.0);
        let diameter: f64 = record.get(col::DIAMETER).unwrap_or("0").parse().unwrap_or(0.0);
        let is_bad = parse_bool_field(record.get(col::BAD).unwrap_or("0"));
        let is_empty = parse_bool_field(record.get(col::EMPTY).unwrap_or("0"));

        initial_spots.push(Spot {
            id: id.clone(),
            is_reference,
            row: row as i32,
            col: col_val as i32,
            x_offset: 0.0, y_offset: 0.0,
            x_fixed: 0.0, y_fixed: 0.0,
            grid_x, grid_y,
            initial_x: grid_x, initial_y: grid_y,
            diameter: 0.0,
            is_manual: false, is_found: false,
            is_bad: false, is_empty: false,
            rotation: 0.0,
        });

        matlab_data.push((id, grid_x, grid_y, diameter, is_bad, is_empty, is_reference));
    }

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
    let out_path = test_dir.join("spot_comparison.json");
    let mut f = std::fs::File::create(&out_path).unwrap();
    write!(f, "[\n").unwrap();
    for (i, ((id, mx, my, md, mb, me, is_ref), rs)) in matlab_data.iter().zip(rust_results.iter()).enumerate() {
        let comma = if i < matlab_data.len() - 1 { "," } else { "" };
        write!(f, "  {{\"id\":\"{}\",\"is_ref\":{},\"matlab_x\":{:.2},\"matlab_y\":{:.2},\"matlab_d\":{:.2},\"matlab_bad\":{},\"matlab_empty\":{},\"rust_x\":{:.2},\"rust_y\":{:.2},\"rust_d\":{:.2},\"rust_bad\":{},\"rust_empty\":{}}}{}\n",
            id, is_ref, mx, my, md, mb, me,
            rs.grid_x, rs.grid_y, rs.diameter, rs.is_bad, rs.is_empty, comma
        ).unwrap();
    }
    write!(f, "]\n").unwrap();
    eprintln!("Wrote {}", out_path.display());
}
