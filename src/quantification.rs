use crate::config::GridParams;
use crate::error::Result;
use crate::image_processing::normalize_image;
use crate::types::{ImageData, Spot, SpotResult};

/// Quantify spots in image
pub fn quantify_spots(
    image: &ImageData,
    spots: &[Spot],
    group_id: &str,
    _params: &GridParams,
) -> Result<Vec<SpotResult>> {
    let normalized = normalize_image(&image.data);
    let mut results = Vec::new();

    for spot in spots {
        let result = quantify_single_spot(image, &normalized, spot, group_id);
        results.push(result);
    }

    Ok(results)
}

/// Quantify a single spot
fn quantify_single_spot(
    image: &ImageData,
    normalized: &ndarray::Array2<f64>,
    spot: &Spot,
    group_id: &str,
) -> SpotResult {
    SpotResult {
        group_id: group_id.to_string(),
        spot_id: spot.id.clone(),
        is_reference: spot.is_reference,
        row: spot.row as f64,
        col: spot.col as f64,
        x_fixed: spot.x_fixed,
        y_fixed: spot.y_fixed,
        grid_x: spot.grid_x,
        grid_y: spot.grid_y,
        diameter: spot.diameter,
        is_manual: if spot.is_manual { 1 } else { 0 },
        is_bad: if spot.is_bad { 1 } else { 0 },
        is_empty: if spot.is_empty { 1 } else { 0 },
        rotation: spot.rotation,
        image_name: image.name.clone(),
    }
}

/// Remove outliers using IQR-based Tukey fences (matching MATLAB pg_seg_detect_outlier.m)
/// Values outside [Q1 - measure*IQR, Q3 + measure*IQR] are removed.
/// Default measure in MATLAB: params.qntOutlierMeasure = 1.75
fn remove_iqr_outliers(vals: &[f64], measure: f64) -> Vec<f64> {
    if vals.len() < 4 {
        return vals.to_vec();
    }

    let mut sorted = vals.to_vec();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());

    // MATLAB quantile([0.25, 0.75]) — use linear interpolation
    let n = sorted.len();
    let q1 = interpolate_quantile(&sorted, 0.25);
    let q3 = interpolate_quantile(&sorted, 0.75);
    let iqr = q3 - q1;

    let lower = q1 - measure * iqr;
    let upper = q3 + measure * iqr;

    vals.iter()
        .copied()
        .filter(|&v| v >= lower && v <= upper)
        .collect()
}

/// Interpolate quantile from sorted data (matches MATLAB quantile function)
fn interpolate_quantile(sorted: &[f64], p: f64) -> f64 {
    let n = sorted.len();
    if n == 0 { return 0.0; }
    if n == 1 { return sorted[0]; }

    // MATLAB quantile uses (i-0.5)/n for the i-th sorted value
    let index = p * n as f64 - 0.5;
    if index <= 0.0 {
        return sorted[0];
    }
    if index >= (n - 1) as f64 {
        return sorted[n - 1];
    }

    let lo = index.floor() as usize;
    let frac = index - lo as f64;
    sorted[lo] * (1.0 - frac) + sorted[lo + 1] * frac
}

/// Compute sample standard deviation (N-1 denominator, matching MATLAB std())
fn sample_std(vals: &[f64]) -> f64 {
    if vals.len() < 2 {
        return 0.0;
    }
    let mean = vals.iter().sum::<f64>() / vals.len() as f64;
    let var = vals.iter().map(|&v| (v - mean).powi(2)).sum::<f64>()
        / (vals.len() - 1) as f64;
    var.sqrt()
}

/// Compute SNR for a single spot (matching MATLAB pg_qnt_check_quantification.m)
///
/// Signal: filled circle at (center_x, center_y) with given radius.
/// Background: square annulus — square of side 2*bg_offset_px centered on spot,
///             minus a circle of radius bg_offset_px.
/// IQR-based outlier removal on both signal and background (MATLAB: pg_seg_detect_outlier)
/// SNR = (mean_signal - mean_background) / sqrt(std_signal² + std_background²)
pub fn compute_spot_snr(
    image: &ImageData,
    center_x: f64, // row
    center_y: f64, // col
    radius: f64,
    bg_offset_px: f64, // bg_offset * spot_pitch
) -> f64 {
    let normalized = normalize_image(&image.data);
    let (nrows, ncols) = normalized.dim();

    // Signal pixels: filled circle
    let mut sig_vals = Vec::new();
    let r_start = (center_x - radius).floor().max(0.0) as usize;
    let r_end = ((center_x + radius).ceil() as usize).min(nrows);
    let c_start = (center_y - radius).floor().max(0.0) as usize;
    let c_end = ((center_y + radius).ceil() as usize).min(ncols);

    for r in r_start..r_end {
        for c in c_start..c_end {
            let dr = r as f64 - center_x;
            let dc = c as f64 - center_y;
            if (dr * dr + dc * dc).sqrt() <= radius {
                sig_vals.push(normalized[[r, c]]);
            }
        }
    }

    // Background pixels: square annulus
    let mut bg_vals = Vec::new();
    let sq_r_start = (center_x - bg_offset_px).floor().max(0.0) as usize;
    let sq_r_end = ((center_x + bg_offset_px).ceil() as usize).min(nrows);
    let sq_c_start = (center_y - bg_offset_px).floor().max(0.0) as usize;
    let sq_c_end = ((center_y + bg_offset_px).ceil() as usize).min(ncols);

    for r in sq_r_start..sq_r_end {
        for c in sq_c_start..sq_c_end {
            let dr = r as f64 - center_x;
            let dc = c as f64 - center_y;
            // Inside square but outside inner circle
            if (dr * dr + dc * dc).sqrt() > bg_offset_px {
                bg_vals.push(normalized[[r, c]]);
            }
        }
    }

    if sig_vals.is_empty() || bg_vals.is_empty() {
        return 0.0;
    }

    // IQR-based outlier removal (MATLAB: pg_seg_detect_outlier with measure=1.75)
    let sig_clean = remove_iqr_outliers(&sig_vals, 1.75);
    let bg_clean = remove_iqr_outliers(&bg_vals, 1.75);

    if sig_clean.is_empty() || bg_clean.is_empty() {
        return 0.0;
    }

    let mean_sig = sig_clean.iter().sum::<f64>() / sig_clean.len() as f64;
    let mean_bg = bg_clean.iter().sum::<f64>() / bg_clean.len() as f64;

    // Sample std dev (N-1 denominator) matching MATLAB std()
    let std_sig = sample_std(&sig_clean);
    let std_bg = sample_std(&bg_clean);

    let denom = (std_sig * std_sig + std_bg * std_bg).sqrt();
    if denom < 1e-15 {
        return 0.0;
    }

    (mean_sig - mean_bg) / denom
}

/// Compute spot intensity statistics
pub fn compute_spot_statistics(
    image: &ImageData,
    spot: &Spot,
) -> Option<SpotStatistics> {
    if spot.is_bad {
        return None;
    }

    let normalized = normalize_image(&image.data);

    let radius = spot.diameter / 2.0;
    let x = spot.grid_x;
    let y = spot.grid_y;

    let mut intensities = Vec::new();

    let x_start = ((x - radius).max(0.0) as usize).min(image.width);
    let x_end = ((x + radius).ceil() as usize).min(image.width);
    let y_start = ((y - radius).max(0.0) as usize).min(image.height);
    let y_end = ((y + radius).ceil() as usize).min(image.height);

    for yi in y_start..y_end {
        for xi in x_start..x_end {
            let dx = xi as f64 - x;
            let dy = yi as f64 - y;
            let dist = (dx * dx + dy * dy).sqrt();

            if dist <= radius {
                intensities.push(normalized[[yi, xi]]);
            }
        }
    }

    if intensities.is_empty() {
        return None;
    }

    let sum: f64 = intensities.iter().sum();
    let mean = sum / intensities.len() as f64;

    let variance: f64 = intensities
        .iter()
        .map(|&x| {
            let diff = x - mean;
            diff * diff
        })
        .sum::<f64>()
        / intensities.len() as f64;

    let std_dev = variance.sqrt();

    let mut sorted = intensities.clone();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let median = if sorted.len() % 2 == 0 {
        (sorted[sorted.len() / 2 - 1] + sorted[sorted.len() / 2]) / 2.0
    } else {
        sorted[sorted.len() / 2]
    };

    Some(SpotStatistics {
        mean,
        median,
        std_dev,
        min: *sorted.first().unwrap(),
        max: *sorted.last().unwrap(),
        sum,
        pixel_count: intensities.len(),
    })
}

/// Statistics for a single spot
#[derive(Debug, Clone)]
pub struct SpotStatistics {
    pub mean: f64,
    pub median: f64,
    pub std_dev: f64,
    pub min: f64,
    pub max: f64,
    pub sum: f64,
    pub pixel_count: usize,
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::Array2;

    #[test]
    fn test_quantify_single_spot() {
        let data = Array2::from_elem((100, 100), 100u16);
        let image = ImageData::new(data, "test".to_string());

        let spot = Spot {
            id: "A1".to_string(),
            row: 5,
            col: 5,
            is_reference: true,
            x_offset: 0.0,
            y_offset: 0.0,
            x_fixed: 0.0,
            y_fixed: 0.0,
            grid_x: 50.0,
            grid_y: 50.0,
            initial_x: 50.0,
            initial_y: 50.0,
            diameter: 10.0,
            is_manual: false,
            is_found: true,
            is_bad: false,
            is_empty: false,
            rotation: 0.0,
        };

        let normalized = normalize_image(&image.data);
        let result = quantify_single_spot(&image, &normalized, &spot, "group1");

        assert_eq!(result.spot_id, "A1");
        assert_eq!(result.group_id, "group1");
        assert!(result.is_reference);
        assert_eq!(result.is_bad, 0);
    }

    #[test]
    fn test_compute_spot_statistics() {
        let mut data = Array2::from_elem((100, 100), 0u16);

        // Create a bright spot
        for y in 45..55 {
            for x in 45..55 {
                data[[y, x]] = 1000;
            }
        }

        let image = ImageData::new(data, "test".to_string());

        let spot = Spot {
            id: "A1".to_string(),
            row: 5,
            col: 5,
            is_reference: true,
            x_offset: 0.0,
            y_offset: 0.0,
            x_fixed: 0.0,
            y_fixed: 0.0,
            grid_x: 50.0,
            grid_y: 50.0,
            initial_x: 50.0,
            initial_y: 50.0,
            diameter: 8.0,
            is_manual: false,
            is_found: true,
            is_bad: false,
            is_empty: false,
            rotation: 0.0,
        };

        let stats = compute_spot_statistics(&image, &spot).unwrap();

        assert!(stats.mean > 0.0);
        assert!(stats.sum > 0.0);
        assert!(stats.pixel_count > 0);
    }
}
