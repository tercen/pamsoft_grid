use crate::error::{Error, Result};
use crate::types::ImageData;
use ndarray::{Array2, s};

#[cfg(feature = "opencv")]
use opencv::{
    core::{self, Mat, CV_32F, CV_8U},
    imgproc,
    prelude::*,
};

/// Rescale image to a given factor
pub fn rescale_image(image: &ImageData, scale_factor: f64) -> Result<ImageData> {
    if scale_factor <= 0.0 {
        return Err(Error::InvalidParameter(
            "Scale factor must be positive".to_string(),
        ));
    }

    if (scale_factor - 1.0).abs() < 1e-6 {
        return Ok(image.clone());
    }

    let new_width = (image.width as f64 * scale_factor).round() as usize;
    let new_height = (image.height as f64 * scale_factor).round() as usize;

    let mut scaled = Array2::<u16>::zeros((new_height, new_width));

    // Simple nearest neighbor interpolation
    for y in 0..new_height {
        for x in 0..new_width {
            let src_x = (x as f64 / scale_factor).floor() as usize;
            let src_y = (y as f64 / scale_factor).floor() as usize;

            let src_x = src_x.min(image.width - 1);
            let src_y = src_y.min(image.height - 1);

            scaled[[y, x]] = image.data[[src_y, src_x]];
        }
    }

    Ok(ImageData::new(scaled, image.name.clone()))
}

/// Preprocess images: rescale and combine exposures
pub fn preprocess_images(images: &[ImageData], rescale_factor: Option<f64>, use_image: &str) -> Result<ImageData> {
    if images.is_empty() {
        return Err(Error::InvalidParameter("No images provided".to_string()));
    }

    eprintln!("DEBUG: preprocess_images called with {} images, use_image={}", images.len(), use_image);
    tracing::info!("preprocess_images: {} images, use_image={}", images.len(), use_image);

    // Select image based on configuration
    let base_image = if images.len() == 1 {
        tracing::info!("Only 1 image, using: {}", images[0].name);
        images[0].clone()
    } else {
        // Select image according to use_image parameter
        let selected = match use_image.to_lowercase().as_str() {
            "first" => {
                tracing::info!("Selecting FIRST image for grid detection: {}", images[0].name);
                images[0].clone()
            },
            "last" => {
                tracing::info!("Selecting LAST image for grid detection: {}", images.last().unwrap().name);
                images.last().unwrap().clone()
            },
            "average" | "median" | _ => {
                tracing::info!("Selecting FIRST image (default) for grid detection: {}", images[0].name);
                images[0].clone()
            }
        };
        selected
    };

    // Apply rescaling if specified (use bilinear interpolation with OpenCV for better quality)
    if let Some(scale) = rescale_factor {
        rescale_image_auto(&base_image, scale, InterpolationMethod::Bilinear)
    } else {
        Ok(base_image)
    }
}

/// Normalize image intensity to 0-1 range
pub fn normalize_image(data: &Array2<u16>) -> Array2<f64> {
    let max_val = *data.iter().max().unwrap_or(&1) as f64;
    if max_val == 0.0 {
        return Array2::zeros(data.dim());
    }

    data.mapv(|x| x as f64 / max_val)
}

/// Apply Gaussian smoothing (simplified)
pub fn gaussian_blur(data: &Array2<f64>, sigma: f64) -> Array2<f64> {
    // Simplified box blur for now
    let kernel_size = (sigma * 3.0).ceil() as usize;
    let kernel_size = kernel_size.max(1);

    let (height, width) = data.dim();
    let mut result = data.clone();

    // Horizontal pass
    for y in 0..height {
        for x in 0..width {
            let x_start = x.saturating_sub(kernel_size);
            let x_end = (x + kernel_size + 1).min(width);

            let sum: f64 = (x_start..x_end).map(|i| data[[y, i]]).sum();
            let count = (x_end - x_start) as f64;
            result[[y, x]] = sum / count;
        }
    }

    // Vertical pass
    let mut final_result = result.clone();
    for x in 0..width {
        for y in 0..height {
            let y_start = y.saturating_sub(kernel_size);
            let y_end = (y + kernel_size + 1).min(height);

            let sum: f64 = (y_start..y_end).map(|i| result[[i, x]]).sum();
            let count = (y_end - y_start) as f64;
            final_result[[y, x]] = sum / count;
        }
    }

    final_result
}

/// Compute image gradient magnitude using Sobel operator
pub fn compute_gradient(data: &Array2<f64>) -> Array2<f64> {
    let (height, width) = data.dim();
    let mut gradient = Array2::zeros((height, width));

    // Sobel kernels
    let sobel_x = [[-1.0, 0.0, 1.0], [-2.0, 0.0, 2.0], [-1.0, 0.0, 1.0]];
    let sobel_y = [[-1.0, -2.0, -1.0], [0.0, 0.0, 0.0], [1.0, 2.0, 1.0]];

    for y in 1..height - 1 {
        for x in 1..width - 1 {
            let mut gx = 0.0;
            let mut gy = 0.0;

            for ky in 0..3 {
                for kx in 0..3 {
                    let val = data[[y + ky - 1, x + kx - 1]];
                    gx += val * sobel_x[ky][kx];
                    gy += val * sobel_y[ky][kx];
                }
            }

            gradient[[y, x]] = (gx * gx + gy * gy).sqrt();
        }
    }

    gradient
}

/// Threshold image
pub fn threshold(data: &Array2<f64>, threshold: f64) -> Array2<bool> {
    data.mapv(|x| x > threshold)
}

/// Create a disk structuring element for morphological operations
/// Returns a binary array where 1 indicates points within radius distance from center
pub fn create_disk_structuring_element(radius: usize) -> Array2<bool> {
    let size = 2 * radius + 1;
    let mut disk = Array2::<bool>::default((size, size));
    let center = radius as isize;

    for i in 0..size {
        for j in 0..size {
            let di = i as isize - center;
            let dj = j as isize - center;
            let dist = ((di * di + dj * dj) as f64).sqrt();
            disk[[i, j]] = dist <= radius as f64;
        }
    }
    disk
}

/// Morphological erosion operation
/// Replaces each pixel with the minimum value in its neighborhood defined by structuring element
pub fn erode(image: &Array2<f64>, structuring_element: &Array2<bool>) -> Array2<f64> {
    let (img_h, img_w) = image.dim();
    let (se_h, se_w) = structuring_element.dim();
    let se_h_half = se_h / 2;
    let se_w_half = se_w / 2;

    let mut result = Array2::zeros((img_h, img_w));

    for i in 0..img_h {
        for j in 0..img_w {
            let mut min_val = f64::MAX;

            // Apply structuring element
            for si in 0..se_h {
                for sj in 0..se_w {
                    if structuring_element[[si, sj]] {
                        let ii = i as isize + si as isize - se_h_half as isize;
                        let jj = j as isize + sj as isize - se_w_half as isize;

                        if ii >= 0 && ii < img_h as isize && jj >= 0 && jj < img_w as isize {
                            let val = image[[ii as usize, jj as usize]];
                            if val < min_val {
                                min_val = val;
                            }
                        }
                    }
                }
            }

            result[[i, j]] = if min_val == f64::MAX { image[[i, j]] } else { min_val };
        }
    }
    result
}

/// Morphological dilation operation
/// Replaces each pixel with the maximum value in its neighborhood defined by structuring element
pub fn dilate(image: &Array2<f64>, structuring_element: &Array2<bool>) -> Array2<f64> {
    let (img_h, img_w) = image.dim();
    let (se_h, se_w) = structuring_element.dim();
    let se_h_half = se_h / 2;
    let se_w_half = se_w / 2;

    let mut result = Array2::zeros((img_h, img_w));

    for i in 0..img_h {
        for j in 0..img_w {
            let mut max_val = f64::MIN;

            // Apply structuring element
            for si in 0..se_h {
                for sj in 0..se_w {
                    if structuring_element[[si, sj]] {
                        let ii = i as isize + si as isize - se_h_half as isize;
                        let jj = j as isize + sj as isize - se_w_half as isize;

                        if ii >= 0 && ii < img_h as isize && jj >= 0 && jj < img_w as isize {
                            let val = image[[ii as usize, jj as usize]];
                            if val > max_val {
                                max_val = val;
                            }
                        }
                    }
                }
            }

            result[[i, j]] = if max_val == f64::MIN { image[[i, j]] } else { max_val };
        }
    }
    result
}

/// Morphological opening operation (erosion followed by dilation)
/// Removes small bright features while preserving the overall shape
pub fn morphological_opening(image: &Array2<f64>, radius: usize) -> Array2<f64> {
    let se = create_disk_structuring_element(radius);
    let eroded = erode(image, &se);
    dilate(&eroded, &se)
}

/// Compute 2D cross-correlation using FFT (simplified version)
pub fn cross_correlate(image: &Array2<f64>, template: &Array2<f64>) -> Array2<f64> {
    let (img_h, img_w) = image.dim();
    let (tmpl_h, tmpl_w) = template.dim();

    let result_h = img_h - tmpl_h + 1;
    let result_w = img_w - tmpl_w + 1;

    let mut result = Array2::zeros((result_h, result_w));

    // Direct correlation (simplified - FFT version would be much faster)
    for y in 0..result_h {
        for x in 0..result_w {
            let mut sum = 0.0;
            let mut img_sum = 0.0;
            let mut tmpl_sum = 0.0;

            for ty in 0..tmpl_h {
                for tx in 0..tmpl_w {
                    let img_val = image[[y + ty, x + tx]];
                    let tmpl_val = template[[ty, tx]];
                    sum += img_val * tmpl_val;
                    img_sum += img_val * img_val;
                    tmpl_sum += tmpl_val * tmpl_val;
                }
            }

            // Normalized cross-correlation
            let denom = (img_sum * tmpl_sum).sqrt();
            result[[y, x]] = if denom > 0.0 { sum / denom } else { 0.0 };
        }
    }

    result
}

/// Find maximum value and its position in 2D array
pub fn find_max_2d(data: &Array2<f64>) -> Option<(f64, (usize, usize))> {
    let mut max_val = f64::NEG_INFINITY;
    let mut max_pos = (0, 0);

    for ((y, x), &val) in data.indexed_iter() {
        if val > max_val {
            max_val = val;
            max_pos = (y, x);
        }
    }

    if max_val == f64::NEG_INFINITY {
        None
    } else {
        Some((max_val, max_pos))
    }
}

/// Canny edge detection with hysteresis thresholding
/// Implements the complete Canny algorithm matching MATLAB's edge() function
///
/// # Arguments
/// * `image` - Input grayscale image (normalized 0-1)
/// * `low_threshold` - Low threshold for hysteresis (0-1)
/// * `high_threshold` - High threshold for hysteresis (0-1)
/// * `sigma` - Gaussian blur sigma (typically 1.0-2.0)
///
/// # Returns
/// Binary edge map
pub fn canny_edge_detection(
    image: &Array2<f64>,
    low_threshold: f64,
    high_threshold: f64,
    sigma: f64,
) -> Array2<bool> {
    // Step 1: Gaussian blur to reduce noise
    let smoothed = gaussian_blur(image, sigma);

    // Step 2: Compute gradients using Sobel operators
    let (grad_x, grad_y) = compute_gradients_sobel(&smoothed);

    // Step 3: Compute gradient magnitude and direction
    let (magnitude, direction) = compute_gradient_magnitude_direction(&grad_x, &grad_y);

    // Step 4: Non-maximum suppression
    let suppressed = non_maximum_suppression(&magnitude, &direction, &grad_x, &grad_y);

    // Step 5: Hysteresis thresholding
    hysteresis_thresholding(&suppressed, low_threshold, high_threshold)
}

/// Compute gradients using Sobel operators
fn compute_gradients_sobel(image: &Array2<f64>) -> (Array2<f64>, Array2<f64>) {
    let (height, width) = image.dim();
    let mut grad_x = Array2::<f64>::zeros((height, width));
    let mut grad_y = Array2::<f64>::zeros((height, width));

    // Sobel kernels
    // Gx = [[-1, 0, 1],     Gy = [[-1, -2, -1],
    //       [-2, 0, 2],           [ 0,  0,  0],
    //       [-1, 0, 1]]           [ 1,  2,  1]]

    for y in 1..height-1 {
        for x in 1..width-1 {
            // Sobel X (horizontal edges)
            let gx = -image[[y-1, x-1]] + image[[y-1, x+1]]
                   + -2.0 * image[[y, x-1]] + 2.0 * image[[y, x+1]]
                   + -image[[y+1, x-1]] + image[[y+1, x+1]];

            // Sobel Y (vertical edges)
            let gy = -image[[y-1, x-1]] - 2.0 * image[[y-1, x]]  - image[[y-1, x+1]]
                   + image[[y+1, x-1]] + 2.0 * image[[y+1, x]] + image[[y+1, x+1]];

            grad_x[[y, x]] = gx;
            grad_y[[y, x]] = gy;
        }
    }

    (grad_x, grad_y)
}

/// Compute gradient magnitude and direction
fn compute_gradient_magnitude_direction(grad_x: &Array2<f64>, grad_y: &Array2<f64>)
    -> (Array2<f64>, Array2<f64>) {
    let (height, width) = grad_x.dim();
    let mut magnitude = Array2::<f64>::zeros((height, width));
    let mut direction = Array2::<f64>::zeros((height, width));

    for y in 0..height {
        for x in 0..width {
            let gx = grad_x[[y, x]];
            let gy = grad_y[[y, x]];

            magnitude[[y, x]] = (gx * gx + gy * gy).sqrt();
            direction[[y, x]] = gy.atan2(gx);  // Returns angle in radians [-π, π]
        }
    }

    (magnitude, direction)
}

/// Non-maximum suppression matching OpenCV's Canny implementation exactly.
///
/// OpenCV's NMS uses:
/// - 4-direction quantization via tan(22.5°)/tan(67.5°) sector boundaries
/// MATLAB-compatible interpolated non-maximum suppression.
/// For each pixel, interpolate the magnitude at the two neighbors along the
/// exact gradient direction and suppress if not a local maximum.
/// This is more precise than OpenCV's 4-sector quantized approach and produces
/// fewer spurious edges in low-contrast regions.
///
/// Gradient convention: grad_x = column derivative (Sobel dx), grad_y = row derivative (Sobel dy).
/// Array indexing: magnitude[[row, col]] = magnitude[[y, x]].
fn non_maximum_suppression(magnitude: &Array2<f64>, _direction: &Array2<f64>,
                           grad_x: &Array2<f64>, grad_y: &Array2<f64>) -> Array2<f64> {
    let (height, width) = magnitude.dim();
    let mut suppressed = Array2::<f64>::zeros((height, width));

    for y in 1..height-1 {
        for x in 1..width-1 {
            let mag = magnitude[[y, x]];
            if mag == 0.0 {
                continue;
            }

            let gx = grad_x[[y, x]]; // column gradient
            let gy = grad_y[[y, x]]; // row gradient
            let ax = gx.abs();
            let ay = gy.abs();

            // Interpolate magnitude at the two neighbors along the gradient direction.
            // 8 octants mapped via |gx| vs |gy| and sign of gx*gy.
            let (interp1, interp2) = if ax >= ay {
                // Gradient closer to horizontal (|angle| <= 45° from x-axis)
                let t = if ax > 0.0 { ay / ax } else { 0.0 };
                if gx * gy >= 0.0 {
                    // SE/NW tendency (both positive or both negative)
                    // Forward: east → southeast; Backward: west → northwest
                    let m1 = (1.0 - t) * magnitude[[y, x+1]] + t * magnitude[[y+1, x+1]];
                    let m2 = (1.0 - t) * magnitude[[y, x-1]] + t * magnitude[[y-1, x-1]];
                    (m1, m2)
                } else {
                    // NE/SW tendency (opposite signs)
                    // Forward: east → northeast; Backward: west → southwest
                    let m1 = (1.0 - t) * magnitude[[y, x+1]] + t * magnitude[[y-1, x+1]];
                    let m2 = (1.0 - t) * magnitude[[y, x-1]] + t * magnitude[[y+1, x-1]];
                    (m1, m2)
                }
            } else {
                // Gradient closer to vertical (|angle| > 45° from x-axis)
                let t = if ay > 0.0 { ax / ay } else { 0.0 };
                if gx * gy >= 0.0 {
                    // SE/NW tendency
                    // Forward: south → southeast; Backward: north → northwest
                    let m1 = (1.0 - t) * magnitude[[y+1, x]] + t * magnitude[[y+1, x+1]];
                    let m2 = (1.0 - t) * magnitude[[y-1, x]] + t * magnitude[[y-1, x-1]];
                    (m1, m2)
                } else {
                    // NE/SW tendency
                    // Forward: north → northeast; Backward: south → southwest
                    let m1 = (1.0 - t) * magnitude[[y-1, x]] + t * magnitude[[y-1, x+1]];
                    let m2 = (1.0 - t) * magnitude[[y+1, x]] + t * magnitude[[y+1, x-1]];
                    (m1, m2)
                }
            };

            // Keep pixel only if it's a local maximum along gradient direction
            if mag >= interp1 && mag >= interp2 {
                suppressed[[y, x]] = mag;
            }
        }
    }

    suppressed
}

/// Hysteresis thresholding - connect strong edges through weak edges
fn hysteresis_thresholding(
    magnitude: &Array2<f64>,
    low_threshold: f64,
    high_threshold: f64,
) -> Array2<bool> {
    let (height, width) = magnitude.dim();
    let mut edges = Array2::<bool>::default((height, width));
    let mut visited = Array2::<bool>::default((height, width));

    // Normalize thresholds if they're in 0-1 range
    let max_magnitude = magnitude.iter().cloned().fold(0.0, f64::max);
    let high_thresh = if high_threshold <= 1.0 {
        high_threshold * max_magnitude
    } else {
        high_threshold
    };
    let low_thresh = if low_threshold <= 1.0 {
        low_threshold * max_magnitude
    } else {
        low_threshold
    };

    // Start with strong edges (above high threshold)
    for y in 1..height-1 {
        for x in 1..width-1 {
            if magnitude[[y, x]] >= high_thresh && !visited[[y, x]] {
                // Strong edge - trace connected weak edges
                trace_edge(magnitude, &mut edges, &mut visited, y, x, low_thresh);
            }
        }
    }

    edges
}

/// Trace connected edges from a strong edge pixel
fn trace_edge(
    magnitude: &Array2<f64>,
    edges: &mut Array2<bool>,
    visited: &mut Array2<bool>,
    y: usize,
    x: usize,
    low_threshold: f64,
) {
    let (height, width) = magnitude.dim();

    // Stack for depth-first search
    let mut stack = vec![(y, x)];

    while let Some((cy, cx)) = stack.pop() {
        if visited[[cy, cx]] {
            continue;
        }

        visited[[cy, cx]] = true;
        edges[[cy, cx]] = true;

        // Check 8-connected neighbors
        for dy in -1..=1 {
            for dx in -1..=1 {
                if dy == 0 && dx == 0 {
                    continue;
                }

                let ny = cy as i32 + dy;
                let nx = cx as i32 + dx;

                if ny > 0 && ny < (height - 1) as i32 &&
                   nx > 0 && nx < (width - 1) as i32 {
                    let ny = ny as usize;
                    let nx = nx as usize;

                    // Follow weak edges connected to strong edges
                    if !visited[[ny, nx]] && magnitude[[ny, nx]] >= low_threshold {
                        stack.push((ny, nx));
                    }
                }
            }
        }
    }
}

// ============================================================================
// OpenCV-accelerated implementations (Phase 2a)
// ============================================================================

/// Helper function to convert ndarray to OpenCV Mat
#[cfg(feature = "opencv")]
fn array_to_mat_f32(array: &Array2<f64>) -> Result<Mat> {
    let (h, w) = array.dim();
    let mut mat = unsafe {
        Mat::new_rows_cols(h as i32, w as i32, CV_32F)
            .map_err(|e| Error::ProcessingError(format!("Failed to create Mat: {}", e)))?
    };

    for i in 0..h {
        for j in 0..w {
            *mat.at_2d_mut::<f32>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to set pixel: {}", e)))?
                = array[[i, j]] as f32;
        }
    }

    Ok(mat)
}

/// Helper function to convert OpenCV Mat to ndarray
#[cfg(feature = "opencv")]
fn mat_to_array_f64(mat: &Mat) -> Result<Array2<f64>> {
    let h = mat.rows() as usize;
    let w = mat.cols() as usize;
    let mut array = Array2::<f64>::zeros((h, w));

    for i in 0..h {
        for j in 0..w {
            array[[i, j]] = *mat.at_2d::<f32>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to get pixel: {}", e)))? as f64;
        }
    }

    Ok(array)
}

/// Helper function to convert OpenCV Mat (u8) to boolean array
#[cfg(feature = "opencv")]
fn mat_u8_to_array_bool(mat: &Mat) -> Result<Array2<bool>> {
    let h = mat.rows() as usize;
    let w = mat.cols() as usize;
    let mut array = Array2::<bool>::default((h, w));

    for i in 0..h {
        for j in 0..w {
            array[[i, j]] = *mat.at_2d::<u8>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to get pixel: {}", e)))? > 0;
        }
    }

    Ok(array)
}

/// Apply Gaussian smoothing using OpenCV (10x faster than pure Rust)
#[cfg(feature = "opencv")]
pub fn gaussian_blur_opencv(data: &Array2<f64>, sigma: f64) -> Result<Array2<f64>> {
    let mat = array_to_mat_f32(data)?;

    // Compute kernel size from sigma (OpenCV convention: size = 2 * ceil(3*sigma) + 1)
    let kernel_size = (2.0 * (3.0 * sigma).ceil() + 1.0) as i32;
    let kernel_size = if kernel_size % 2 == 0 { kernel_size + 1 } else { kernel_size };

    let mut result = Mat::default();
    imgproc::gaussian_blur(
        &mat,
        &mut result,
        core::Size::new(kernel_size, kernel_size),
        sigma,
        sigma,
        core::BORDER_DEFAULT,
    ).map_err(|e| Error::ProcessingError(format!("Gaussian blur failed: {}", e)))?;

    mat_to_array_f64(&result)
}

/// Compute image gradient magnitude using OpenCV Sobel operator (10x faster than pure Rust)
#[cfg(feature = "opencv")]
pub fn compute_gradient_opencv(data: &Array2<f64>) -> Result<Array2<f64>> {
    let mat = array_to_mat_f32(data)?;

    // Compute gradients in X and Y directions
    let mut grad_x = Mat::default();
    let mut grad_y = Mat::default();

    imgproc::sobel(
        &mat,
        &mut grad_x,
        CV_32F,
        1, 0, // dx=1, dy=0 for X gradient
        3,    // kernel size
        1.0,  // scale
        0.0,  // delta
        core::BORDER_DEFAULT,
    ).map_err(|e| Error::ProcessingError(format!("Sobel X failed: {}", e)))?;

    imgproc::sobel(
        &mat,
        &mut grad_y,
        CV_32F,
        0, 1, // dx=0, dy=1 for Y gradient
        3,    // kernel size
        1.0,  // scale
        0.0,  // delta
        core::BORDER_DEFAULT,
    ).map_err(|e| Error::ProcessingError(format!("Sobel Y failed: {}", e)))?;

    // Compute magnitude: sqrt(gx^2 + gy^2)
    let (h, w) = data.dim();
    let mut magnitude = Array2::<f64>::zeros((h, w));

    for i in 0..h {
        for j in 0..w {
            let gx = *grad_x.at_2d::<f32>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to read grad_x: {}", e)))? as f64;
            let gy = *grad_y.at_2d::<f32>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to read grad_y: {}", e)))? as f64;
            magnitude[[i, j]] = (gx * gx + gy * gy).sqrt();
        }
    }

    Ok(magnitude)
}

/// Full float-precision Canny edge detection. No u8 conversion anywhere.
///
/// Pipeline:
///   1. OpenCV Gaussian blur on f32 (proper Gaussian kernel)
///   2. OpenCV Sobel on f32 (gradient computation)
///   3. L1 gradient magnitude (|dx|+|dy|, matching OpenCV default) on f64
///   4. Non-maximum suppression on f64 (matching OpenCV's 4-sector algorithm)
///   5. Hysteresis thresholding on f64
///
/// Thresholds follow MATLAB convention: sensitivity * max(gradient_magnitude).
#[cfg(feature = "opencv")]
pub fn canny_edge_detection_float(
    image: &Array2<f64>,
    sensitivity: [f64; 2],
    sigma: f64,
) -> Result<Array2<bool>> {
    // Step 1: Convert to f32 Mat (keep [0,1] range — thresholds scale accordingly)
    let mat = array_to_mat_f32(image)?;

    // Step 2: Gaussian blur on f32 (proper Gaussian, full float precision)
    let blurred = if sigma > 0.0 {
        let kernel_size = (2.0 * (3.0 * sigma).ceil() + 1.0) as i32;
        let kernel_size = if kernel_size % 2 == 0 { kernel_size + 1 } else { kernel_size };

        let mut blurred_mat = Mat::default();
        imgproc::gaussian_blur(
            &mat,
            &mut blurred_mat,
            core::Size::new(kernel_size, kernel_size),
            sigma,
            sigma,
            core::BORDER_DEFAULT,
        ).map_err(|e| Error::ProcessingError(format!("Gaussian blur failed: {}", e)))?;
        blurred_mat
    } else {
        mat
    };

    // Step 3: Sobel gradients on f32
    let mut grad_x_mat = Mat::default();
    let mut grad_y_mat = Mat::default();
    imgproc::sobel(&blurred, &mut grad_x_mat, CV_32F, 1, 0, 3, 1.0, 0.0, core::BORDER_DEFAULT)
        .map_err(|e| Error::ProcessingError(format!("Sobel X failed: {}", e)))?;
    imgproc::sobel(&blurred, &mut grad_y_mat, CV_32F, 0, 1, 3, 1.0, 0.0, core::BORDER_DEFAULT)
        .map_err(|e| Error::ProcessingError(format!("Sobel Y failed: {}", e)))?;

    // Step 4: Convert gradients to Array2<f64>
    let grad_x = mat_to_array_f64(&grad_x_mat)?;
    let grad_y = mat_to_array_f64(&grad_y_mat)?;

    // Step 5: L2 gradient magnitude (hypot, matching MATLAB's edge('canny') default)
    let (height, width) = grad_x.dim();
    let mut magnitude = Array2::<f64>::zeros((height, width));
    for y in 0..height {
        for x in 0..width {
            magnitude[[y, x]] = grad_x[[y, x]].hypot(grad_y[[y, x]]);
        }
    }

    // Step 6: Compute MATLAB-compatible thresholds: sensitivity * max(mag)
    let max_mag = magnitude.iter().cloned().fold(0.0_f64, f64::max);
    if max_mag < 1e-10 {
        return Ok(Array2::default(image.dim()));
    }
    let high_threshold = sensitivity[1] * max_mag;
    let low_threshold = if sensitivity[0] > 0.0 {
        sensitivity[0] * max_mag
    } else {
        0.4 * high_threshold
    };

    // Step 7: Non-maximum suppression matching OpenCV (f64 precision)
    let direction = Array2::<f64>::zeros((height, width)); // unused, NMS uses grad_x/grad_y directly
    let suppressed = non_maximum_suppression(&magnitude, &direction, &grad_x, &grad_y);

    // Step 8: Hysteresis thresholding with absolute thresholds
    // For [0,1] input, thresholds may be < 1.0 which hysteresis would rescale.
    // Convert to fractions of max_suppressed to match hysteresis's auto-scaling.
    let max_suppressed = suppressed.iter().cloned().fold(0.0_f64, f64::max);
    if max_suppressed < 1e-10 {
        return Ok(Array2::default(image.dim()));
    }
    let high_frac = high_threshold / max_suppressed;
    let low_frac = low_threshold / max_suppressed;
    Ok(hysteresis_thresholding(&suppressed, low_frac, high_frac))
}

/// Canny edge detection using OpenCV with MATLAB-compatible auto-thresholding.
/// The sensitivity parameter is interpreted as MATLAB does: gradient histogram
/// percentiles, not absolute threshold values.
#[cfg(feature = "opencv")]
pub fn canny_edge_detection_opencv(
    image: &Array2<f64>,
    sensitivity: [f64; 2],
    sigma: f64,
) -> Result<Array2<bool>> {
    // Convert to 8-bit for OpenCV Canny (it expects 8-bit input)
    let (h, w) = image.dim();
    let mut mat_u8 = unsafe {
        Mat::new_rows_cols(h as i32, w as i32, CV_8U)
            .map_err(|e| Error::ProcessingError(format!("Failed to create Mat: {}", e)))?
    };

    // Normalize to 0-255 range
    for i in 0..h {
        for j in 0..w {
            let val = (image[[i, j]] * 255.0).min(255.0).max(0.0) as u8;
            *mat_u8.at_2d_mut::<u8>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to set pixel: {}", e)))? = val;
        }
    }

    // Apply Gaussian blur if sigma > 0
    let blurred = if sigma > 0.0 {
        let kernel_size = (2.0 * (3.0 * sigma).ceil() + 1.0) as i32;
        let kernel_size = if kernel_size % 2 == 0 { kernel_size + 1 } else { kernel_size };

        let mut blurred_mat = Mat::default();
        imgproc::gaussian_blur(
            &mat_u8,
            &mut blurred_mat,
            core::Size::new(kernel_size, kernel_size),
            sigma,
            sigma,
            core::BORDER_DEFAULT,
        ).map_err(|e| Error::ProcessingError(format!("Gaussian blur failed: {}", e)))?;
        blurred_mat
    } else {
        mat_u8
    };

    // Compute MATLAB-compatible auto-thresholds from Sobel gradient magnitudes
    let (low_thresh, high_thresh) = {
        let mut gx = Mat::default();
        let mut gy = Mat::default();
        imgproc::sobel(&blurred, &mut gx, CV_32F, 1, 0, 3, 1.0, 0.0, core::BORDER_DEFAULT)
            .map_err(|e| Error::ProcessingError(format!("Sobel X failed: {}", e)))?;
        imgproc::sobel(&blurred, &mut gy, CV_32F, 0, 1, 3, 1.0, 0.0, core::BORDER_DEFAULT)
            .map_err(|e| Error::ProcessingError(format!("Sobel Y failed: {}", e)))?;
        let mut max_mag: f64 = 0.0;
        for i in 0..h {
            for j in 0..w {
                let vx = *gx.at_2d::<f32>(i as i32, j as i32)
                    .map_err(|e| Error::ProcessingError(format!("Read grad_x: {}", e)))? as f64;
                let vy = *gy.at_2d::<f32>(i as i32, j as i32)
                    .map_err(|e| Error::ProcessingError(format!("Read grad_y: {}", e)))? as f64;
                let mag = (vx * vx + vy * vy).sqrt();
                if mag > max_mag { max_mag = mag; }
            }
        }
        if max_mag < 1e-10 {
            (0.0, 1.0)
        } else {
            let high = sensitivity[1] * max_mag;
            let low = if sensitivity[0] > 0.0 { sensitivity[0] * max_mag } else { 0.4 * high };
            (low, high)
        }
    };

    // Apply Canny edge detection with computed thresholds
    let mut edges = Mat::default();
    imgproc::canny(
        &blurred,
        &mut edges,
        low_thresh,
        high_thresh,
        3,     // aperture size for Sobel
        false, // L2 gradient
    ).map_err(|e| Error::ProcessingError(format!("Canny failed: {}", e)))?;

    mat_u8_to_array_bool(&edges)
}

/// Compute gradients using OpenCV Sobel operators (returns both X and Y gradients)
#[cfg(feature = "opencv")]
pub fn compute_gradients_sobel_opencv(image: &Array2<f64>) -> Result<(Array2<f64>, Array2<f64>)> {
    let mat = array_to_mat_f32(image)?;

    let mut grad_x = Mat::default();
    let mut grad_y = Mat::default();

    imgproc::sobel(
        &mat,
        &mut grad_x,
        CV_32F,
        1, 0, 3, 1.0, 0.0,
        core::BORDER_DEFAULT,
    ).map_err(|e| Error::ProcessingError(format!("Sobel X failed: {}", e)))?;

    imgproc::sobel(
        &mat,
        &mut grad_y,
        CV_32F,
        0, 1, 3, 1.0, 0.0,
        core::BORDER_DEFAULT,
    ).map_err(|e| Error::ProcessingError(format!("Sobel Y failed: {}", e)))?;

    let gx = mat_to_array_f64(&grad_x)?;
    let gy = mat_to_array_f64(&grad_y)?;

    Ok((gx, gy))
}

/// Morphological erosion using OpenCV (5-10x faster than pure Rust)
#[cfg(feature = "opencv")]
pub fn erode_opencv(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    let mat = array_to_mat_f32(image)?;

    // Create circular structuring element (disk)
    let kernel_size = (2 * radius + 1) as i32;
    let kernel = imgproc::get_structuring_element(
        imgproc::MORPH_ELLIPSE,
        core::Size::new(kernel_size, kernel_size),
        core::Point::new(radius as i32, radius as i32),
    ).map_err(|e| Error::ProcessingError(format!("Failed to create structuring element: {}", e)))?;

    let mut result = Mat::default();
    imgproc::erode(
        &mat,
        &mut result,
        &kernel,
        core::Point::new(-1, -1), // Default anchor point (center)
        1,                         // Iterations
        core::BORDER_CONSTANT,
        imgproc::morphology_default_border_value()
            .map_err(|e| Error::ProcessingError(format!("Failed to get border value: {}", e)))?,
    ).map_err(|e| Error::ProcessingError(format!("Erosion failed: {}", e)))?;

    mat_to_array_f64(&result)
}

/// Morphological dilation using OpenCV (5-10x faster than pure Rust)
#[cfg(feature = "opencv")]
pub fn dilate_opencv(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    let mat = array_to_mat_f32(image)?;

    // Create circular structuring element (disk)
    let kernel_size = (2 * radius + 1) as i32;
    let kernel = imgproc::get_structuring_element(
        imgproc::MORPH_ELLIPSE,
        core::Size::new(kernel_size, kernel_size),
        core::Point::new(radius as i32, radius as i32),
    ).map_err(|e| Error::ProcessingError(format!("Failed to create structuring element: {}", e)))?;

    let mut result = Mat::default();
    imgproc::dilate(
        &mat,
        &mut result,
        &kernel,
        core::Point::new(-1, -1), // Default anchor point (center)
        1,                         // Iterations
        core::BORDER_CONSTANT,
        imgproc::morphology_default_border_value()
            .map_err(|e| Error::ProcessingError(format!("Failed to get border value: {}", e)))?,
    ).map_err(|e| Error::ProcessingError(format!("Dilation failed: {}", e)))?;

    mat_to_array_f64(&result)
}

/// Morphological opening using OpenCV (erosion followed by dilation)
#[cfg(feature = "opencv")]
pub fn morphological_opening_opencv(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    let mat = array_to_mat_f32(image)?;

    // Create circular structuring element (disk)
    let kernel_size = (2 * radius + 1) as i32;
    let kernel = imgproc::get_structuring_element(
        imgproc::MORPH_ELLIPSE,
        core::Size::new(kernel_size, kernel_size),
        core::Point::new(radius as i32, radius as i32),
    ).map_err(|e| Error::ProcessingError(format!("Failed to create structuring element: {}", e)))?;

    let mut result = Mat::default();
    imgproc::morphology_ex(
        &mat,
        &mut result,
        imgproc::MORPH_OPEN, // Opening operation
        &kernel,
        core::Point::new(-1, -1), // Default anchor point
        1,                         // Iterations
        core::BORDER_CONSTANT,
        imgproc::morphology_default_border_value()
            .map_err(|e| Error::ProcessingError(format!("Failed to get border value: {}", e)))?,
    ).map_err(|e| Error::ProcessingError(format!("Morphological opening failed: {}", e)))?;

    mat_to_array_f64(&result)
}

/// Interpolation methods for image rescaling
#[derive(Debug, Clone, Copy)]
pub enum InterpolationMethod {
    /// Nearest neighbor interpolation (fastest, lowest quality)
    Nearest,
    /// Bilinear interpolation (good balance)
    Bilinear,
    /// Bicubic interpolation (high quality, slower)
    Bicubic,
    /// Lanczos interpolation (best quality, slowest)
    Lanczos,
}

/// Rescale image using OpenCV with advanced interpolation (2-3x faster + better quality)
#[cfg(feature = "opencv")]
pub fn rescale_image_opencv(
    image: &ImageData,
    scale_factor: f64,
    interpolation: InterpolationMethod,
) -> Result<ImageData> {
    if scale_factor <= 0.0 {
        return Err(Error::InvalidParameter(
            "Scale factor must be positive".to_string(),
        ));
    }

    if (scale_factor - 1.0).abs() < 1e-6 {
        return Ok(image.clone());
    }

    let new_width = (image.width as f64 * scale_factor).round() as i32;
    let new_height = (image.height as f64 * scale_factor).round() as i32;

    // Convert Array2<u16> to OpenCV Mat (CV_16U)
    let (h, w) = image.data.dim();
    let mut src_mat = unsafe {
        Mat::new_rows_cols(h as i32, w as i32, core::CV_16U)
            .map_err(|e| Error::ProcessingError(format!("Failed to create Mat: {}", e)))?
    };

    for i in 0..h {
        for j in 0..w {
            *src_mat.at_2d_mut::<u16>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to set pixel: {}", e)))? =
                image.data[[i, j]];
        }
    }

    // Select interpolation method
    let interp_flag = match interpolation {
        InterpolationMethod::Nearest => imgproc::INTER_NEAREST,
        InterpolationMethod::Bilinear => imgproc::INTER_LINEAR,
        InterpolationMethod::Bicubic => imgproc::INTER_CUBIC,
        InterpolationMethod::Lanczos => imgproc::INTER_LANCZOS4,
    };

    // Resize the image
    let mut dst_mat = Mat::default();
    imgproc::resize(
        &src_mat,
        &mut dst_mat,
        core::Size::new(new_width, new_height),
        0.0, // dx (calculated from dsize)
        0.0, // dy (calculated from dsize)
        interp_flag,
    )
    .map_err(|e| Error::ProcessingError(format!("Resize failed: {}", e)))?;

    // Convert back to Array2<u16>
    let mut scaled = Array2::<u16>::zeros((new_height as usize, new_width as usize));
    for i in 0..new_height as usize {
        for j in 0..new_width as usize {
            scaled[[i, j]] = *dst_mat
                .at_2d::<u16>(i as i32, j as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to read pixel: {}", e)))?;
        }
    }

    Ok(ImageData::new(scaled, image.name.clone()))
}

/// Find connected components in a binary image and return the largest one using OpenCV
/// More robust than flood-fill, handles edge cases better
#[cfg(feature = "opencv")]
pub fn find_largest_connected_component_opencv(
    edge_map: &Array2<bool>,
    x_start: usize,
    x_end: usize,
    y_start: usize,
    y_end: usize,
) -> Result<Vec<(usize, usize)>> {
    if x_end <= x_start || y_end <= y_start {
        return Ok(Vec::new());
    }

    let height = x_end - x_start;
    let width = y_end - y_start;

    // Create ROI from edge map
    let mut roi = unsafe {
        Mat::new_rows_cols(height as i32, width as i32, CV_8U)
            .map_err(|e| Error::ProcessingError(format!("Failed to create Mat: {}", e)))?
    };

    for local_x in 0..height {
        for local_y in 0..width {
            let global_x = x_start + local_x;
            let global_y = y_start + local_y;

            let val = if global_x < edge_map.nrows() && global_y < edge_map.ncols() && edge_map[[global_x, global_y]] {
                255u8
            } else {
                0u8
            };

            *roi.at_2d_mut::<u8>(local_x as i32, local_y as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to set pixel: {}", e)))? = val;
        }
    }

    // Find connected components
    let mut labels = Mat::default();
    let mut stats = Mat::default();
    let mut centroids = Mat::default();

    let num_labels = imgproc::connected_components_with_stats(
        &roi,
        &mut labels,
        &mut stats,
        &mut centroids,
        8, // 8-connectivity
        core::CV_32S,
    ).map_err(|e| Error::ProcessingError(format!("Connected components failed: {}", e)))?;

    if num_labels <= 1 {
        // No components found (label 0 is background)
        return Ok(Vec::new());
    }

    // Find the largest component (excluding background which is label 0)
    let mut largest_label = 1;
    let mut largest_area = 0;

    for label in 1..num_labels {
        let area = *stats.at_2d::<i32>(label, imgproc::CC_STAT_AREA)
            .map_err(|e| Error::ProcessingError(format!("Failed to read area: {}", e)))?;

        if area > largest_area {
            largest_area = area;
            largest_label = label;
        }
    }

    // Extract pixels belonging to the largest component
    let mut component = Vec::new();
    for local_x in 0..height {
        for local_y in 0..width {
            let label = *labels.at_2d::<i32>(local_x as i32, local_y as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to read label: {}", e)))?;

            if label == largest_label {
                let global_x = x_start + local_x;
                let global_y = y_start + local_y;
                component.push((global_x, global_y));
            }
        }
    }

    Ok(component)
}

/// Find contours using OpenCV (alternative to connected components)
/// Returns contour with the most points in the ROI
#[cfg(feature = "opencv")]
pub fn find_largest_contour_opencv(
    edge_map: &Array2<bool>,
    x_start: usize,
    x_end: usize,
    y_start: usize,
    y_end: usize,
) -> Result<Vec<(usize, usize)>> {
    if x_end <= x_start || y_end <= y_start {
        return Ok(Vec::new());
    }

    let height = x_end - x_start;
    let width = y_end - y_start;

    // Create ROI from edge map
    let mut roi = unsafe {
        Mat::new_rows_cols(height as i32, width as i32, CV_8U)
            .map_err(|e| Error::ProcessingError(format!("Failed to create Mat: {}", e)))?
    };

    for local_x in 0..height {
        for local_y in 0..width {
            let global_x = x_start + local_x;
            let global_y = y_start + local_y;

            let val = if global_x < edge_map.nrows() && global_y < edge_map.ncols() && edge_map[[global_x, global_y]] {
                255u8
            } else {
                0u8
            };

            *roi.at_2d_mut::<u8>(local_x as i32, local_y as i32)
                .map_err(|e| Error::ProcessingError(format!("Failed to set pixel: {}", e)))? = val;
        }
    }

    // Find contours
    let mut contours = opencv::core::Vector::<opencv::core::Vector<core::Point>>::new();
    imgproc::find_contours(
        &roi,
        &mut contours,
        imgproc::RETR_EXTERNAL, // Only external contours
        imgproc::CHAIN_APPROX_SIMPLE, // Compress contours
        core::Point::new(0, 0),
    ).map_err(|e| Error::ProcessingError(format!("Find contours failed: {}", e)))?;

    if contours.is_empty() {
        return Ok(Vec::new());
    }

    // Find the largest contour
    let mut largest_idx = 0;
    let mut largest_size = 0;

    for i in 0..contours.len() {
        let contour = contours.get(i)
            .map_err(|e| Error::ProcessingError(format!("Failed to get contour: {}", e)))?;
        if contour.len() > largest_size {
            largest_size = contour.len();
            largest_idx = i;
        }
    }

    // Extract points from the largest contour
    let largest_contour = contours.get(largest_idx)
        .map_err(|e| Error::ProcessingError(format!("Failed to get largest contour: {}", e)))?;

    let mut component = Vec::new();
    for i in 0..largest_contour.len() {
        let pt = largest_contour.get(i)
            .map_err(|e| Error::ProcessingError(format!("Failed to get point: {}", e)))?;
        let global_x = x_start + pt.y as usize;
        let global_y = y_start + pt.x as usize;
        component.push((global_x, global_y));
    }

    Ok(component)
}

// ============================================================================
// Wrapper functions that use OpenCV when available, fallback to pure Rust
// ============================================================================

/// Apply Gaussian smoothing (uses OpenCV if available, otherwise pure Rust)
#[cfg(feature = "opencv")]
pub fn gaussian_blur_auto(data: &Array2<f64>, sigma: f64) -> Result<Array2<f64>> {
    gaussian_blur_opencv(data, sigma)
}

#[cfg(not(feature = "opencv"))]
pub fn gaussian_blur_auto(data: &Array2<f64>, sigma: f64) -> Result<Array2<f64>> {
    Ok(gaussian_blur(data, sigma))
}

/// Compute image gradient magnitude (uses OpenCV if available, otherwise pure Rust)
#[cfg(feature = "opencv")]
pub fn compute_gradient_auto(data: &Array2<f64>) -> Result<Array2<f64>> {
    compute_gradient_opencv(data)
}

#[cfg(not(feature = "opencv"))]
pub fn compute_gradient_auto(data: &Array2<f64>) -> Result<Array2<f64>> {
    Ok(compute_gradient(data))
}

/// Canny edge detection with MATLAB-compatible auto-thresholding.
/// sensitivity = [low_sens, high_sens] as MATLAB edge() sensitivity parameter.
/// (uses OpenCV if available, otherwise pure Rust with absolute thresholds as fallback)
#[cfg(feature = "opencv")]
pub fn canny_edge_detection_auto(
    image: &Array2<f64>,
    sensitivity: [f64; 2],
    sigma: f64,
) -> Result<Array2<bool>> {
    canny_edge_detection_float(image, sensitivity, sigma)
}

#[cfg(not(feature = "opencv"))]
pub fn canny_edge_detection_auto(
    image: &Array2<f64>,
    sensitivity: [f64; 2],
    sigma: f64,
) -> Result<Array2<bool>> {
    // Pure Rust fallback: interpret sensitivity as absolute thresholds (legacy behavior)
    Ok(canny_edge_detection(image, sensitivity[0], sensitivity[1], sigma))
}

/// Morphological erosion (uses OpenCV if available, otherwise pure Rust)
#[cfg(feature = "opencv")]
pub fn erode_auto(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    erode_opencv(image, radius)
}

#[cfg(not(feature = "opencv"))]
pub fn erode_auto(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    let se = create_disk_structuring_element(radius);
    Ok(erode(image, &se))
}

/// Morphological dilation (uses OpenCV if available, otherwise pure Rust)
#[cfg(feature = "opencv")]
pub fn dilate_auto(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    dilate_opencv(image, radius)
}

#[cfg(not(feature = "opencv"))]
pub fn dilate_auto(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    let se = create_disk_structuring_element(radius);
    Ok(dilate(image, &se))
}

/// Morphological opening (uses OpenCV if available, otherwise pure Rust)
#[cfg(feature = "opencv")]
pub fn morphological_opening_auto(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    morphological_opening_opencv(image, radius)
}

#[cfg(not(feature = "opencv"))]
pub fn morphological_opening_auto(image: &Array2<f64>, radius: usize) -> Result<Array2<f64>> {
    Ok(morphological_opening(image, radius))
}

/// Rescale image with advanced interpolation (uses OpenCV if available, otherwise pure Rust)
///
/// When OpenCV is available, offers multiple interpolation methods:
/// - Bilinear: Good balance of speed and quality (default)
/// - Bicubic: Higher quality, slightly slower
/// - Lanczos: Best quality, slowest
///
/// Without OpenCV, falls back to nearest neighbor interpolation
#[cfg(feature = "opencv")]
pub fn rescale_image_auto(
    image: &ImageData,
    scale_factor: f64,
    interpolation: InterpolationMethod,
) -> Result<ImageData> {
    rescale_image_opencv(image, scale_factor, interpolation)
}

#[cfg(not(feature = "opencv"))]
pub fn rescale_image_auto(
    image: &ImageData,
    scale_factor: f64,
    _interpolation: InterpolationMethod,
) -> Result<ImageData> {
    // Without OpenCV, fall back to nearest neighbor (original implementation)
    rescale_image(image, scale_factor)
}

/// Find largest connected component (uses OpenCV if available, otherwise pure Rust flood-fill)
///
/// OpenCV provides more robust connected component analysis with better edge case handling
#[cfg(feature = "opencv")]
pub fn find_largest_connected_component_auto(
    edge_map: &Array2<bool>,
    x_start: usize,
    x_end: usize,
    y_start: usize,
    y_end: usize,
) -> Result<Vec<(usize, usize)>> {
    find_largest_connected_component_opencv(edge_map, x_start, x_end, y_start, y_end)
}

#[cfg(not(feature = "opencv"))]
pub fn find_largest_connected_component_auto(
    edge_map: &Array2<bool>,
    x_start: usize,
    x_end: usize,
    y_start: usize,
    y_end: usize,
) -> Result<Vec<(usize, usize)>> {
    // Import from segmentation module
    Ok(crate::segmentation::find_largest_connected_component(edge_map, x_start, x_end, y_start, y_end))
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::arr2;

    #[test]
    fn test_normalize_image() {
        let data = Array2::from_shape_vec((2, 2), vec![0, 100, 200, 255]).unwrap();
        let normalized = normalize_image(&data);

        assert!((normalized[[0, 0]] - 0.0).abs() < 1e-6);
        assert!((normalized[[1, 1]] - 1.0).abs() < 1e-6);
    }

    #[test]
    fn test_threshold() {
        let data = arr2(&[[0.1, 0.5], [0.7, 0.9]]);
        let thresholded = threshold(&data, 0.6);

        assert!(!thresholded[[0, 0]]);
        assert!(!thresholded[[0, 1]]);
        assert!(thresholded[[1, 0]]);
        assert!(thresholded[[1, 1]]);
    }

    #[test]
    fn test_find_max_2d() {
        let data = arr2(&[[1.0, 2.0], [3.0, 4.0]]);
        let result = find_max_2d(&data);

        assert!(result.is_some());
        let (max_val, (y, x)) = result.unwrap();
        assert_eq!(max_val, 4.0);
        assert_eq!((y, x), (1, 1));
    }
}
