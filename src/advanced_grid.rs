use crate::config::GridParams;
use crate::error::{Error, Result};
use crate::types::{ImageData, Spot};
use ndarray::{Array2, ArrayView2};
use num_complex::Complex;
use rustfft::{Fft, FftPlanner};
use std::f64::consts::PI;
use std::sync::Arc;

/// FFT-based grid detection using frequency domain analysis
pub fn fft_grid_detection(
    image: &ImageData,
    params: &GridParams,
) -> Result<(f64, f64, f64)> {
    tracing::info!("Starting FFT-based grid detection");

    let data = &image.data;
    let (height, width) = data.dim();

    // Convert to complex numbers for FFT
    let mut complex_data: Vec<Complex<f64>> = data
        .iter()
        .map(|&val| Complex::new(val as f64, 0.0))
        .collect();

    // Perform 2D FFT
    let fft_result = compute_2d_fft(&mut complex_data, height, width)?;

    // Find dominant frequency (spot pitch)
    let (freq_x, freq_y) = find_dominant_frequency(&fft_result, height, width, params)?;

    // Calculate grid parameters from frequency
    let pitch_x = if freq_x > 0.0 { width as f64 / freq_x } else { params.spot_pitch };
    let pitch_y = if freq_y > 0.0 { height as f64 / freq_y } else { params.spot_pitch };

    tracing::info!("Detected pitch: x={:.2}, y={:.2}", pitch_x, pitch_y);

    // Convert data to f64 for grid origin finding
    let data_f64 = data.mapv(|v| v as f64);

    // Find grid origin using phase correlation
    let (origin_x, origin_y) = find_grid_origin(&data_f64, pitch_x, pitch_y)?;

    // Calculate rotation from frequency components
    let rotation = calculate_rotation(freq_x, freq_y);

    tracing::info!("FFT grid detection: origin=({:.2}, {:.2}), rotation={:.2}°",
                   origin_x, origin_y, rotation);

    Ok((origin_x, origin_y, rotation))
}

/// Compute 2D FFT of image data
fn compute_2d_fft(
    data: &mut [Complex<f64>],
    height: usize,
    width: usize,
) -> Result<Vec<Complex<f64>>> {
    let mut planner = FftPlanner::new();

    // FFT along rows
    let fft_row = planner.plan_fft_forward(width);
    for row in 0..height {
        let start = row * width;
        let end = start + width;
        fft_row.process(&mut data[start..end]);
    }

    // Transpose for column FFT
    let mut transposed = vec![Complex::new(0.0, 0.0); height * width];
    for i in 0..height {
        for j in 0..width {
            transposed[j * height + i] = data[i * width + j];
        }
    }

    // FFT along columns (now rows after transpose)
    let fft_col = planner.plan_fft_forward(height);
    for col in 0..width {
        let start = col * height;
        let end = start + height;
        fft_col.process(&mut transposed[start..end]);
    }

    // Transpose back
    let mut result = vec![Complex::new(0.0, 0.0); height * width];
    for i in 0..width {
        for j in 0..height {
            result[j * width + i] = transposed[i * height + j];
        }
    }

    Ok(result)
}

/// Find dominant frequency corresponding to spot pitch
fn find_dominant_frequency(
    fft_result: &[Complex<f64>],
    height: usize,
    width: usize,
    params: &GridParams,
) -> Result<(f64, f64)> {
    // Compute power spectrum
    let mut power_spectrum = Array2::zeros((height, width));
    for i in 0..height {
        for j in 0..width {
            let idx = i * width + j;
            let magnitude = fft_result[idx].norm();
            power_spectrum[[i, j]] = magnitude * magnitude;
        }
    }

    // Find peaks in expected frequency range
    let expected_freq = width as f64 / params.spot_pitch;
    let freq_range = expected_freq * 0.3; // ±30% tolerance

    let mut max_power = 0.0;
    let mut peak_x = 0.0;
    let mut peak_y = 0.0;

    for i in 1..(height / 2) {
        for j in 1..(width / 2) {
            let freq = ((i * i + j * j) as f64).sqrt();
            if (freq - expected_freq).abs() < freq_range {
                let power = power_spectrum[[i, j]];
                if power > max_power {
                    max_power = power;
                    peak_x = j as f64;
                    peak_y = i as f64;
                }
            }
        }
    }

    if max_power == 0.0 {
        tracing::warn!("No dominant frequency found, using default pitch");
        return Ok((0.0, 0.0));
    }

    Ok((peak_x, peak_y))
}

/// Find grid origin using spatial correlation
fn find_grid_origin(
    data: &Array2<f64>,
    pitch_x: f64,
    pitch_y: f64,
) -> Result<(f64, f64)> {
    let (height, width) = data.dim();

    // Create grid template with expected pitch
    let template_size = (pitch_x.max(pitch_y) * 3.0) as usize;
    let mut template = Array2::zeros((template_size, template_size));

    let center = template_size as f64 / 2.0;
    for y in 0..template_size {
        for x in 0..template_size {
            let dx = x as f64 - center;
            let dy = y as f64 - center;

            // Create spot pattern at grid positions
            let grid_x = (dx / pitch_x).round() * pitch_x;
            let grid_y = (dy / pitch_y).round() * pitch_y;

            let dist = ((dx - grid_x).powi(2) + (dy - grid_y).powi(2)).sqrt();
            if dist < pitch_x * 0.3 {
                template[[y, x]] = 1.0;
            }
        }
    }

    // Find best match position
    let mut max_corr = f64::NEG_INFINITY;
    let mut best_x = width as f64 / 2.0;
    let mut best_y = height as f64 / 2.0;

    // Sample positions (for performance)
    let step = 5;
    for y in (0..height).step_by(step) {
        for x in (0..width).step_by(step) {
            if let Some(corr) = compute_local_correlation(data, &template, x, y) {
                if corr > max_corr {
                    max_corr = corr;
                    best_x = x as f64;
                    best_y = y as f64;
                }
            }
        }
    }

    Ok((best_x, best_y))
}

/// Compute local correlation between image and template
fn compute_local_correlation(
    data: &Array2<f64>,
    template: &Array2<f64>,
    x: usize,
    y: usize,
) -> Option<f64> {
    let (img_h, img_w) = data.dim();
    let (tmpl_h, tmpl_w) = template.dim();

    if x + tmpl_w >= img_w || y + tmpl_h >= img_h {
        return None;
    }

    let mut sum = 0.0;
    let mut count = 0;

    for ty in 0..tmpl_h {
        for tx in 0..tmpl_w {
            sum += data[[y + ty, x + tx]] * template[[ty, tx]];
            count += 1;
        }
    }

    Some(sum / count as f64)
}

/// Calculate rotation angle from frequency components
fn calculate_rotation(freq_x: f64, freq_y: f64) -> f64 {
    if freq_x == 0.0 && freq_y == 0.0 {
        return 0.0;
    }

    let angle_rad = freq_y.atan2(freq_x);
    let angle_deg = angle_rad * 180.0 / PI;

    // Normalize to [-2, 2] degree range (typical for array alignment)
    let normalized = angle_deg % 90.0;
    if normalized > 45.0 {
        normalized - 90.0
    } else if normalized < -45.0 {
        normalized + 90.0
    } else {
        normalized
    }.clamp(-2.0, 2.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rotation_calculation() {
        assert!((calculate_rotation(1.0, 0.0) - 0.0).abs() < 0.1);
        assert!((calculate_rotation(1.0, 1.0) - 0.0).abs() < 45.1); // 45 degrees normalized
        assert!((calculate_rotation(0.0, 1.0) - 0.0).abs() < 90.1); // 90 degrees normalized
    }
}
