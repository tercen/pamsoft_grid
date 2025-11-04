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
