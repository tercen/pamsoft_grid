/// Debug template generation to understand coordinate system

use pamsoft_grid::config::GridParams;
use pamsoft_grid::io::{load_tiff_image, read_layout_file};
use std::path::PathBuf;

#[test]
#[ignore]
fn debug_template_generation() {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("tests");

    let layout_path = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("631402617_631402618_631402619 86312 Array Layout.txt");

    let layout = read_layout_file(&layout_path).unwrap();

    println!("Reference spots in layout:");
    for (id, is_ref, row, col) in layout.iter().filter(|(_, is_ref, _, _)| *is_ref) {
        println!("  {} at row={}, col={}", id, row, col);
    }

    // Image is 697x520 (width x height)
    // MATLAB midpoint: mp = round(0.5 * [520, 697]) = [260, 349]
    println!("\nImage: 697x520 (width x height)");
    println!("MATLAB imageSize: [520, 697] (height, width)");
    println!("MATLAB midpoint: mp = [260, 349]");
    println!("  mp(1) = 260 (for x, which is rows)");
    println!("  mp(2) = 349 (for y, which is cols)");

    // Reference spot at row=-1, col=-1
    // MATLAB calculates (with spot_pitch=21.5):
    // For reference spots, they form their own grid
    // rmp, cmp calculated from min/max of reference rows/cols
    println!("\nFor reference spot at row=-1, col=-1:");
    println!("  abs(row) = 1, abs(col) = 1");

    // Need to find rmp, cmp from all reference spots
    let ref_rows: Vec<i32> = layout.iter()
        .filter(|(_, is_ref, _, _)| *is_ref)
        .map(|(_, _, row, _)| row.abs())
        .collect();
    let ref_cols: Vec<i32> = layout.iter()
        .filter(|(_, is_ref, _, _)| *is_ref)
        .map(|(_, _, _, col)| col.abs())
        .collect();

    let row_min = *ref_rows.iter().min().unwrap() as f64;
    let row_max = *ref_rows.iter().max().unwrap() as f64;
    let col_min = *ref_cols.iter().min().unwrap() as f64;
    let col_max = *ref_cols.iter().max().unwrap() as f64;

    let rmp = row_min + (row_max - row_min) / 2.0;
    let cmp = col_min + (col_max - col_min) / 2.0;

    println!("  Reference rows: min={}, max={}, rmp={}", row_min, row_max, rmp);
    println!("  Reference cols: min={}, max={}, cmp={}", col_min, col_max, cmp);

    let spot_pitch = 21.5;
    let row = 1.0;
    let col = 1.0;

    let x_before_rot = spot_pitch * (row - rmp);
    let y_before_rot = spot_pitch * (col - cmp);

    println!("  x (before rotation) = {:.2} * ({} - {:.2}) = {:.2}", spot_pitch, row, rmp, x_before_rot);
    println!("  y (before rotation) = {:.2} * ({} - {:.2}) = {:.2}", spot_pitch, col, cmp, y_before_rot);

    // No rotation
    let x_after_rot = x_before_rot;
    let y_after_rot = y_before_rot;

    // Add midpoint + 1 (MATLAB)
    let x_final_matlab = 260.0 + x_after_rot + 1.0;
    let y_final_matlab = 349.0 + y_after_rot + 1.0;

    println!("  x (final) = 260 + {:.2} + 1 = {:.2}", x_after_rot, x_final_matlab);
    println!("  y (final) = 349 + {:.2} + 1 = {:.2}", y_after_rot, y_final_matlab);

    // From table1.csv, the reference spot at -1,-1 is at:
    println!("\nFrom MATLAB table1.csv:");
    println!("  Reference spot #REF at row=-1, col=-1: gridX=206.90, gridY=144.36");

    println!("\nNote: MATLAB's (x, y) in pg_grid_coordinates means:");
    println!("  x relates to rows (vertical direction)");
    println!("  y relates to cols (horizontal direction)");
    println!("\nBut when MATLAB writes to gridX, gridY in CSV:");
    println!("  gridX is horizontal (cols)");
    println!("  gridY is vertical (rows)");
    println!("\nSo there's likely a swap when outputting to CSV!");
}
