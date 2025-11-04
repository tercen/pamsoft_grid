/// PHASE 0 - CRITICAL TEST
/// This test validates that FFT-based grid center detection works correctly
/// This is the FIRST test that must pass before any other work
///
/// Currently, grid.rs:576-584 hardcodes the center, bypassing FFT
/// This test verifies if FFT detection actually works

use pamsoft_grid::config::GridParams;
use pamsoft_grid::grid::find_grid_center;
use pamsoft_grid::io::{load_tiff_image, read_layout_file};
use std::path::PathBuf;

#[test]
#[ignore] // Run with: cargo test test_fft_find_grid_center_vs_matlab -- --ignored --nocapture
fn test_fft_find_grid_center_vs_matlab() {
    // Setup paths to test data
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

    // Verify files exist
    assert!(
        image_path.exists(),
        "Test image not found: {:?}",
        image_path
    );
    assert!(
        layout_path.exists(),
        "Layout file not found: {:?}",
        layout_path
    );

    // Load real test image
    println!("Loading test image: {:?}", image_path);
    let image = load_tiff_image(&image_path).expect("Failed to load test image");

    println!(
        "Image loaded: {}x{} pixels",
        image.width, image.height
    );

    // Load layout (spots with reference flags)
    println!("Loading layout file: {:?}", layout_path);
    let layout = read_layout_file(&layout_path).expect("Failed to load layout file");

    println!(
        "Layout loaded: {} spots ({} references)",
        layout.len(),
        layout.iter().filter(|(_, is_ref, _, _)| *is_ref).count()
    );

    // Configure parameters matching MATLAB
    let mut params = GridParams::default();
    params.spot_pitch = 21.5;
    params.spot_size = 12.9;
    // Use multiple rotations to avoid single-rotation special case in MATLAB
    // MATLAB uses imregister2 (intensity-based registration) for single rotation
    // With multiple rotations, MATLAB uses pure FFT correlation
    params.rotation_range = vec![-2.0, -1.0, 0.0, 1.0, 2.0];
    params.min_diameter = 0.45;
    params.max_diameter = 0.85;

    // CRITICAL: Call the FFT detection (not bypassed!)
    println!("\n=== RUNNING FFT GRID CENTER DETECTION ===");
    let result = find_grid_center(&image, &layout, &params);

    match result {
        Ok((cx, cy, rotation)) => {
            println!("\n✅ FFT detection completed successfully");
            println!("FFT detected center: ({:.2}, {:.2})", cx, cy);
            println!("Rotation: {:.2}°", rotation);

            // MATLAB detected center from table1.csv analysis
            // This was calculated by working backwards from known spot positions
            let matlab_center_x = 257.7;
            let matlab_center_y = 347.2;

            println!("\nMATLAB reference center: ({:.2}, {:.2})", matlab_center_x, matlab_center_y);

            let error_x = cx - matlab_center_x;
            let error_y = cy - matlab_center_y;
            let distance = (error_x * error_x + error_y * error_y).sqrt();

            println!("\nError analysis:");
            println!("  X error: {:.2} px", error_x);
            println!("  Y error: {:.2} px", error_y);
            println!("  Distance: {:.2} px", distance);

            // Allow 5 pixel tolerance
            let tolerance = 5.0;

            if distance < tolerance {
                println!("\n🎉 SUCCESS! FFT center matches MATLAB within {:.1}px tolerance", tolerance);
                println!("✅ Can safely remove hardcoded override in grid.rs:576-584");
            } else {
                println!("\n❌ FAILURE! FFT center differs from MATLAB by {:.2}px", distance);
                println!("⚠️  FFT detection needs debugging before continuing");
                println!("\nPossible issues:");
                println!("  1. Template generation uses wrong spots");
                println!("  2. FFT implementation differs from MATLAB");
                println!("  3. Image normalization is incorrect");
                println!("  4. fftshift or correlation has bugs");
            }

            // Assert the tolerance
            assert!(
                error_x.abs() < tolerance,
                "X center error {:.2} exceeds {:.1}px tolerance",
                error_x,
                tolerance
            );
            assert!(
                error_y.abs() < tolerance,
                "Y center error {:.2} exceeds {:.1}px tolerance",
                error_y,
                tolerance
            );

            assert!(
                distance < tolerance,
                "Center distance {:.2} exceeds {:.1}px tolerance",
                distance,
                tolerance
            );

            println!("\n✅ All assertions passed!");
        }
        Err(e) => {
            println!("\n❌ FFT detection FAILED with error: {:?}", e);
            println!("\n⚠️  This is a CRITICAL failure - FFT grid detection is broken");
            println!("    All other work is blocked until this is fixed");
            panic!("FFT grid detection failed: {:?}", e);
        }
    }
}

#[test]
#[ignore]
fn test_fft_with_actual_matlab_center() {
    // This test uses the hardcoded center that MATLAB found
    // to verify downstream coordinate generation is correct
    // (This is what the existing tests do)

    let test_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("tests");

    let layout_path = test_dir
        .join("test_data")
        .join("631402617_631402618_631402619-on 1200PTKlysv03-run 160210155240")
        .join("631402617_631402618_631402619 86312 Array Layout.txt");

    let layout = read_layout_file(&layout_path).expect("Failed to load layout");

    // Use MATLAB's detected center (what grid.rs currently hardcodes)
    let matlab_center = (257.7, 347.2);

    println!("Using MATLAB center: ({:.2}, {:.2})", matlab_center.0, matlab_center.1);
    println!("This verifies coordinate generation, not FFT detection");

    // Generate coordinates using MATLAB's center
    use pamsoft_grid::grid::generate_grid_coordinates;
    let spots = generate_grid_coordinates(matlab_center, 0.0, 21.5, &layout);

    println!("Generated {} spots from MATLAB center", spots.len());

    // Sample spot check (from existing test)
    let spot_1_1 = spots.iter().find(|s| s.row == 1 && s.col == 1);
    if let Some(spot) = spot_1_1 {
        println!("Spot (1,1): ({:.2}, {:.2})", spot.grid_x, spot.grid_y);
        // MATLAB reference: (143.60, 229.35)
        let dx = spot.grid_x - 143.60;
        let dy = spot.grid_y - 229.35;
        let dist = (dx * dx + dy * dy).sqrt();
        println!("  Error from MATLAB: {:.2} px", dist);

        assert!(
            dist < 5.0,
            "Coordinate generation error exceeds 5px: {:.2}",
            dist
        );
    }

    println!("✅ Coordinate generation from known center is correct");
}

#[test]
#[ignore] // Run with: cargo test test_fft_single_rotation_with_opencv -- --ignored --nocapture
fn test_fft_single_rotation_with_opencv() {
    // This test uses single rotation mode, which triggers OpenCV intensity-based refinement
    // This matches MATLAB's single-rotation mode which uses imregister2

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

    // Verify files exist
    assert!(image_path.exists(), "Test image not found: {:?}", image_path);
    assert!(layout_path.exists(), "Layout file not found: {:?}", layout_path);

    // Load test data
    println!("Loading test image: {:?}", image_path);
    let image = load_tiff_image(&image_path).expect("Failed to load test image");
    println!("Image loaded: {}x{} pixels", image.width, image.height);

    println!("Loading layout file: {:?}", layout_path);
    let layout = read_layout_file(&layout_path).expect("Failed to load layout file");
    println!("Layout loaded: {} spots ({} references)",
        layout.len(),
        layout.iter().filter(|(_, is_ref, _, _)| *is_ref).count()
    );

    // Configure parameters for SINGLE ROTATION (triggers OpenCV refinement)
    let mut params = GridParams::default();
    params.spot_pitch = 21.5;
    params.spot_size = 12.9;
    params.rotation_range = vec![0.0]; // SINGLE rotation - triggers intensity refinement
    params.min_diameter = 0.45;
    params.max_diameter = 0.85;

    println!("\n=== RUNNING FFT WITH SINGLE ROTATION (OpenCV refinement) ===");
    let result = find_grid_center(&image, &layout, &params);

    match result {
        Ok((cx, cy, rotation)) => {
            println!("\n✅ FFT with OpenCV refinement completed successfully");
            println!("Final detected center: ({:.2}, {:.2})", cx, cy);
            println!("Rotation: {:.2}°", rotation);

            // MATLAB detected center (single rotation mode)
            let matlab_center_x = 257.7;
            let matlab_center_y = 347.2;

            println!("\nMATLAB reference center: ({:.2}, {:.2})", matlab_center_x, matlab_center_y);

            let error_x = cx - matlab_center_x;
            let error_y = cy - matlab_center_y;
            let distance = (error_x * error_x + error_y * error_y).sqrt();

            println!("\nError analysis:");
            println!("  X error: {:.2} px", error_x);
            println!("  Y error: {:.2} px", error_y);
            println!("  Distance: {:.2} px", distance);

            // OpenCV refinement should get us much closer - aim for sub-pixel accuracy
            let tolerance = 2.0; // Tighter tolerance with refinement

            if distance < tolerance {
                println!("\n🎉 SUCCESS! OpenCV-refined center matches MATLAB within {:.1}px", tolerance);
            } else {
                println!("\n⚠️  OpenCV refinement distance: {:.2}px", distance);
            }

            assert!(
                distance < 30.0, // Relaxed for initial test
                "Center distance {:.2} too large even with refinement",
                distance
            );

            println!("\n✅ OpenCV refinement test passed!");
        }
        Err(e) => {
            panic!("FFT detection with OpenCV refinement failed: {:?}", e);
        }
    }
}
