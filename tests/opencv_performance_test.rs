/// Performance comparison test for OpenCV vs pure Rust implementations
/// This test demonstrates the speedup from Phase 2a & 3a OpenCV integration
///
/// Run with: cargo test --release --test opencv_performance_test -- --ignored --nocapture

use pamsoft_grid::image_processing::{
    canny_edge_detection, canny_edge_detection_auto,
    gaussian_blur, gaussian_blur_auto,
    compute_gradient, compute_gradient_auto,
    morphological_opening, morphological_opening_auto,
    erode, erode_auto, dilate, dilate_auto,
    create_disk_structuring_element,
    rescale_image, rescale_image_auto, InterpolationMethod,
};
use pamsoft_grid::types::ImageData;
use ndarray::Array2;
use std::time::Instant;

#[test]
#[ignore]
fn benchmark_gaussian_blur() {
    // Create a test image (512x512)
    let size = 512;
    let mut image = Array2::<f64>::zeros((size, size));

    // Add some pattern
    for i in 0..size {
        for j in 0..size {
            image[[i, j]] = ((i + j) as f64 / size as f64).sin();
        }
    }

    let sigma = 2.0;
    let iterations = 10;

    // Benchmark pure Rust
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = gaussian_blur(&image, sigma);
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = gaussian_blur_auto(&image, sigma).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Gaussian Blur Performance ({}x{}, σ={}) ===", size, size, sigma);
    println!("Pure Rust:  {:>8} μs/iter", rust_avg);
    println!("OpenCV:     {:>8} μs/iter", opencv_avg);
    println!("Speedup:    {:>8.2}x", speedup);
}

#[test]
#[ignore]
fn benchmark_gradient_computation() {
    // Create a test image (512x512)
    let size = 512;
    let mut image = Array2::<f64>::zeros((size, size));

    for i in 0..size {
        for j in 0..size {
            image[[i, j]] = ((i * j) as f64 / (size * size) as f64).sqrt();
        }
    }

    let iterations = 10;

    // Benchmark pure Rust
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = compute_gradient(&image);
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = compute_gradient_auto(&image).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Sobel Gradient Performance ({}x{}) ===", size, size);
    println!("Pure Rust:  {:>8} μs/iter", rust_avg);
    println!("OpenCV:     {:>8} μs/iter", opencv_avg);
    println!("Speedup:    {:>8.2}x", speedup);
}

#[test]
#[ignore]
fn benchmark_canny_edge_detection() {
    // Create a test image (512x512)
    let size = 512;
    let mut image = Array2::<f64>::zeros((size, size));

    // Add circular patterns
    let center = size / 2;
    for i in 0..size {
        for j in 0..size {
            let dx = i as f64 - center as f64;
            let dy = j as f64 - center as f64;
            let dist = (dx * dx + dy * dy).sqrt();
            image[[i, j]] = (dist / 50.0).sin().abs();
        }
    }

    let low_threshold = 0.1;
    let high_threshold = 0.3;
    let sigma = 1.0;
    let iterations = 10;

    // Benchmark pure Rust
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = canny_edge_detection(&image, low_threshold, high_threshold, sigma);
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = canny_edge_detection_auto(&image, low_threshold, high_threshold, sigma).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Canny Edge Detection Performance ({}x{}) ===", size, size);
    println!("Pure Rust:  {:>8} μs/iter", rust_avg);
    println!("OpenCV:     {:>8} μs/iter", opencv_avg);
    println!("Speedup:    {:>8.2}x", speedup);
}

#[test]
#[ignore]
fn benchmark_full_pipeline() {
    // Simulate spot segmentation pipeline
    let size = 256; // Typical ROI size
    let mut image = Array2::<f64>::zeros((size, size));

    // Add spot pattern
    let center = size / 2;
    for i in 0..size {
        for j in 0..size {
            let dx = i as f64 - center as f64;
            let dy = j as f64 - center as f64;
            let dist = (dx * dx + dy * dy).sqrt();
            let radius = size as f64 / 4.0;
            image[[i, j]] = if dist < radius { 0.8 } else { 0.2 };
        }
    }

    let iterations = 20;

    // Benchmark pure Rust pipeline
    let start = Instant::now();
    for _ in 0..iterations {
        let smoothed = gaussian_blur(&image, 1.0);
        let gradient = compute_gradient(&smoothed);
        let _ = canny_edge_detection(&image, 0.1, 0.3, 1.0);
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV pipeline
    let start = Instant::now();
    for _ in 0..iterations {
        let smoothed = gaussian_blur_auto(&image, 1.0).unwrap();
        let gradient = compute_gradient_auto(&smoothed).unwrap();
        let _ = canny_edge_detection_auto(&image, 0.1, 0.3, 1.0).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Full Edge Detection Pipeline ({}x{}) ===", size, size);
    println!("(Gaussian blur + Sobel gradient + Canny edge detection)");
    println!("Pure Rust:  {:>8} μs/iter", rust_avg);
    println!("OpenCV:     {:>8} μs/iter", opencv_avg);
    println!("Speedup:    {:>8.2}x", speedup);
    println!("\nEstimated time for 1000 spots:");
    println!("Pure Rust:  {:>8.2} seconds", rust_avg as f64 * 1000.0 / 1_000_000.0);
    println!("OpenCV:     {:>8.2} seconds", opencv_avg as f64 * 1000.0 / 1_000_000.0);
}

#[test]
#[ignore]
fn benchmark_morphological_erosion() {
    // Create a test image (256x256)
    let size = 256;
    let mut image = Array2::<f64>::zeros((size, size));

    // Add circular spots pattern
    for i in 0..size {
        for j in 0..size {
            let dx = (i as i32 - size as i32 / 2).abs();
            let dy = (j as i32 - size as i32 / 2).abs();
            if dx < 50 && dy < 50 {
                image[[i, j]] = 0.8;
            }
        }
    }

    let radius = 3;
    let iterations = 20;

    // Benchmark pure Rust
    let se = create_disk_structuring_element(radius);
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = erode(&image, &se);
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = erode_auto(&image, radius).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Morphological Erosion ({}x{}, radius={}) ===", size, size, radius);
    println!("Pure Rust:  {:>8} μs/iter", rust_avg);
    println!("OpenCV:     {:>8} μs/iter", opencv_avg);
    println!("Speedup:    {:>8.2}x", speedup);
}

#[test]
#[ignore]
fn benchmark_morphological_dilation() {
    // Create a test image (256x256)
    let size = 256;
    let mut image = Array2::<f64>::zeros((size, size));

    // Add scattered points
    for i in (10..size).step_by(20) {
        for j in (10..size).step_by(20) {
            image[[i, j]] = 1.0;
        }
    }

    let radius = 3;
    let iterations = 20;

    // Benchmark pure Rust
    let se = create_disk_structuring_element(radius);
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = dilate(&image, &se);
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = dilate_auto(&image, radius).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Morphological Dilation ({}x{}, radius={}) ===", size, size, radius);
    println!("Pure Rust:  {:>8} μs/iter", rust_avg);
    println!("OpenCV:     {:>8} μs/iter", opencv_avg);
    println!("Speedup:    {:>8.2}x", speedup);
}

#[test]
#[ignore]
fn benchmark_morphological_opening() {
    // Create a test image with noise (256x256)
    let size = 256;
    let mut image = Array2::<f64>::zeros((size, size));

    // Add spots with noise
    for i in 0..size {
        for j in 0..size {
            let dx = i as f64 - size as f64 / 2.0;
            let dy = j as f64 - size as f64 / 2.0;
            let dist = (dx * dx + dy * dy).sqrt();
            if dist < 50.0 {
                image[[i, j]] = 0.8;
            }
            // Add noise
            if (i + j) % 7 == 0 {
                image[[i, j]] += 0.3;
            }
        }
    }

    let radius = 3;
    let iterations = 20;

    // Benchmark pure Rust
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = morphological_opening(&image, radius);
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = morphological_opening_auto(&image, radius).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Morphological Opening ({}x{}, radius={}) ===", size, size, radius);
    println!("Pure Rust:  {:>8} μs/iter", rust_avg);
    println!("OpenCV:     {:>8} μs/iter", opencv_avg);
    println!("Speedup:    {:>8.2}x", speedup);
    println!("\nNote: Opening = Erosion + Dilation");
}

#[test]
#[ignore]
fn benchmark_image_rescaling() {
    // Create a test image (512x512)
    let size = 512;
    let mut data = Array2::<u16>::zeros((size, size));

    // Add some pattern
    for i in 0..size {
        for j in 0..size {
            let val = ((i + j) as f64 / size as f64 * 65535.0) as u16;
            data[[i, j]] = val;
        }
    }

    let image = ImageData::new(data, "test".to_string());
    let scale_factor = 0.5; // Downscale to 256x256
    let iterations = 10;

    // Benchmark pure Rust (nearest neighbor)
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = rescale_image(&image, scale_factor).unwrap();
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV with bilinear interpolation
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = rescale_image_auto(&image, scale_factor, InterpolationMethod::Bilinear).unwrap();
    }
    let opencv_bilinear_time = start.elapsed();
    let opencv_bilinear_avg = opencv_bilinear_time.as_micros() / iterations;

    // Benchmark OpenCV with bicubic interpolation
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = rescale_image_auto(&image, scale_factor, InterpolationMethod::Bicubic).unwrap();
    }
    let opencv_bicubic_time = start.elapsed();
    let opencv_bicubic_avg = opencv_bicubic_time.as_micros() / iterations;

    // Benchmark OpenCV with Lanczos interpolation
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = rescale_image_auto(&image, scale_factor, InterpolationMethod::Lanczos).unwrap();
    }
    let opencv_lanczos_time = start.elapsed();
    let opencv_lanczos_avg = opencv_lanczos_time.as_micros() / iterations;

    let speedup_bilinear = rust_avg as f64 / opencv_bilinear_avg as f64;
    let speedup_bicubic = rust_avg as f64 / opencv_bicubic_avg as f64;
    let speedup_lanczos = rust_avg as f64 / opencv_lanczos_avg as f64;

    println!("\n=== Image Rescaling ({}x{} → {}x{}, scale={})",
        size, size,
        (size as f64 * scale_factor) as usize,
        (size as f64 * scale_factor) as usize,
        scale_factor);
    println!("Pure Rust (nearest):    {:>8} μs/iter", rust_avg);
    println!("OpenCV (bilinear):      {:>8} μs/iter  ({:.2}x)", opencv_bilinear_avg, speedup_bilinear);
    println!("OpenCV (bicubic):       {:>8} μs/iter  ({:.2}x)", opencv_bicubic_avg, speedup_bicubic);
    println!("OpenCV (Lanczos):       {:>8} μs/iter  ({:.2}x)", opencv_lanczos_avg, speedup_lanczos);
    println!("\nNote: OpenCV methods provide better quality interpolation");
}

#[test]
fn benchmark_connected_components() {
    use pamsoft_grid::segmentation::find_largest_connected_component;
    use pamsoft_grid::image_processing::find_largest_connected_component_auto;

    println!("\n=== Benchmark: Connected Components ===");

    // Create a test edge map with multiple components (simulating spot edges)
    let size = 100;
    let mut edge_map = Array2::<bool>::default((size, size));

    // Create multiple circular components (like spot edges)
    let centers = vec![(20, 20), (50, 50), (80, 30), (30, 70)];
    for (cx, cy) in centers {
        for y in 0..size {
            for x in 0..size {
                let dx = x as f64 - cx as f64;
                let dy = y as f64 - cy as f64;
                let dist = (dx * dx + dy * dy).sqrt();
                // Create ring (edge) at radius 8-10 pixels
                if dist >= 8.0 && dist <= 10.0 {
                    edge_map[[y, x]] = true;
                }
            }
        }
    }

    let x_start = 0;
    let x_end = size;
    let y_start = 0;
    let y_end = size;
    let iterations = 50;

    // Benchmark pure Rust
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = find_largest_connected_component(
            &edge_map,
            x_start,
            x_end,
            y_start,
            y_end,
        );
    }
    let rust_time = start.elapsed();
    let rust_avg = rust_time.as_micros() / iterations;

    // Benchmark OpenCV (auto dispatch)
    let start = Instant::now();
    for _ in 0..iterations {
        let _ = find_largest_connected_component_auto(
            &edge_map,
            x_start,
            x_end,
            y_start,
            y_end,
        ).unwrap();
    }
    let opencv_time = start.elapsed();
    let opencv_avg = opencv_time.as_micros() / iterations;

    let speedup = rust_avg as f64 / opencv_avg as f64;

    println!("\n=== Connected Components ({}x{} edge map with 4 components)", size, size);
    println!("Pure Rust (flood-fill): {:>8} μs/iter", rust_avg);
    println!("OpenCV (connectedComponents): {:>8} μs/iter", opencv_avg);
    if speedup > 1.0 {
        println!("Speedup: {:.2}x (OpenCV faster)", speedup);
    } else {
        println!("Speedup: {:.2}x (Rust faster)", 1.0 / speedup);
    }
}

