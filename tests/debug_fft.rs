/// Debug test to understand FFT coordinate system

use pamsoft_grid::config::GridParams;
use pamsoft_grid::io::{load_tiff_image, read_layout_file};
use std::path::PathBuf;

#[test]
#[ignore]
fn debug_template_and_image() {
    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("tests");

    let image_dir = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("ImageResults");

    let image_path = image_dir.join("631402617_W1_F1_T10_P92_I433_A29.tif");
    let layout_path = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("631402617_631402618_631402619 86312 Array Layout.txt");

    let image = load_tiff_image(&image_path).unwrap();
    let layout = read_layout_file(&layout_path).unwrap();

    println!("Image dimensions: {}x{} (width x height)", image.width, image.height);
    println!("Image dimensions: {}x{} (height x width) - MATLAB order", image.height, image.width);
    println!();

    println!("Layout has {} spots:", layout.len());
    let ref_spots: Vec<_> = layout.iter().filter(|(_, is_ref, _, _)| *is_ref).collect();
    println!("  {} reference spots", ref_spots.len());

    for (id, is_ref, row, col) in ref_spots.iter().take(5) {
        println!("    {} (row={}, col={})", id, row, col);
    }
    println!();

    // MATLAB midpoint calculation
    println!("MATLAB midpoint calculation:");
    println!("  imageSize = [{}, {}] (MATLAB uses [rows, cols])", image.height, image.width);
    println!("  mp = round(0.5 * imageSize) = [{}, {}]",
        (image.height as f64 * 0.5).round(),
        (image.width as f64 * 0.5).round());
    println!();

    // The MATLAB-detected center
    println!("MATLAB detected center: (257.7, 347.2)");
    println!("  This is in (x, y) coordinates where x is horizontal, y is vertical");
    println!();

    // FFT detected
    println!("FFT detected center: (428.0, 278.0)");
    println!("  Error: x off by +170, y off by -69");
    println!();

    // Image center
    let img_center_x = image.width as f64 / 2.0;
    let img_center_y = image.height as f64 / 2.0;
    println!("Image geometric center: ({:.1}, {:.1})", img_center_x, img_center_y);
    println!("  FFT result is off from image center by: ({:.1}, {:.1})",
        428.0 - img_center_x, 278.0 - img_center_y);
    println!("  MATLAB result is off from image center by: ({:.1}, {:.1})",
        257.7 - img_center_x, 347.2 - img_center_y);
}
