use crate::error::{Error, Result};
use crate::types::ImageData;
use ndarray::{Array2, s};

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

    // Apply rescaling if specified
    if let Some(scale) = rescale_factor {
        rescale_image(&base_image, scale)
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
fn create_disk_structuring_element(radius: usize) -> Array2<bool> {
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
    let suppressed = non_maximum_suppression(&magnitude, &direction);

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

/// Non-maximum suppression - thin edges to single pixel width
fn non_maximum_suppression(magnitude: &Array2<f64>, direction: &Array2<f64>) -> Array2<f64> {
    let (height, width) = magnitude.dim();
    let mut suppressed = Array2::<f64>::zeros((height, width));

    for y in 1..height-1 {
        for x in 1..width-1 {
            let mag = magnitude[[y, x]];
            let angle = direction[[y, x]];

            // Quantize angle to 0°, 45°, 90°, 135°
            let angle_deg = angle.to_degrees();
            let angle_quantized = ((angle_deg + 180.0) / 45.0).round() as i32 % 4;

            // Compare with neighbors in gradient direction
            let (n1, n2) = match angle_quantized {
                0 => {
                    // 0° - horizontal, compare left and right
                    (magnitude[[y, x-1]], magnitude[[y, x+1]])
                },
                1 => {
                    // 45° - diagonal /, compare NE and SW
                    (magnitude[[y-1, x+1]], magnitude[[y+1, x-1]])
                },
                2 => {
                    // 90° - vertical, compare up and down
                    (magnitude[[y-1, x]], magnitude[[y+1, x]])
                },
                _ => {
                    // 135° - diagonal \, compare NW and SE
                    (magnitude[[y-1, x-1]], magnitude[[y+1, x+1]])
                }
            };

            // Keep only if local maximum
            if mag >= n1 && mag >= n2 {
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
