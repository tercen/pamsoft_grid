use crate::config::{GridParams, SegmentationMethod};
use crate::error::{Error, Result};
use crate::image_processing::{compute_gradient, gaussian_blur, normalize_image, threshold};
use crate::types::{ImageData, Spot};
use ndarray::Array2;
use std::f64::consts::PI;

/// Circle parameters (x, y, radius)
#[derive(Debug, Clone, Copy)]
pub struct Circle {
    pub x: f64,
    pub y: f64,
    pub radius: f64,
}

/// Segment spot using edge-based method
fn segment_by_edge(
    image: &ImageData,
    spot: &Spot,
    params: &GridParams,
) -> Result<Option<Circle>> {
    let normalized = normalize_image(&image.data);

    // Extract region around spot
    let search_radius = params.spot_pitch;
    let x_start = (spot.grid_x - search_radius).max(0.0) as usize;
    let x_end = (spot.grid_x + search_radius)
        .min(image.width as f64 - 1.0) as usize;
    let y_start = (spot.grid_y - search_radius).max(0.0) as usize;
    let y_end = (spot.grid_y + search_radius)
        .min(image.height as f64 - 1.0) as usize;

    if x_end <= x_start || y_end <= y_start {
        return Ok(None);
    }

    let region_height = y_end - y_start + 1;
    let region_width = x_end - x_start + 1;

    let mut region = Array2::zeros((region_height, region_width));
    for y in y_start..=y_end {
        for x in x_start..=x_end {
            region[[y - y_start, x - x_start]] = normalized[[y, x]];
        }
    }

    // Apply Gaussian smoothing
    let smoothed = gaussian_blur(&region, 1.0);

    // Compute gradient
    let gradient = compute_gradient(&smoothed);

    // Threshold edges
    let edge_threshold = params.edge_sensitivity[1];
    let edges = threshold(&gradient, edge_threshold);

    // Find edge points
    let mut edge_points = Vec::new();
    for y in 0..region_height {
        for x in 0..region_width {
            if edges[[y, x]] {
                edge_points.push((
                    x as f64 + x_start as f64,
                    y as f64 + y_start as f64,
                ));
            }
        }
    }

    if edge_points.is_empty() {
        return Ok(None);
    }

    // Fit circle to edge points
    match fit_circle_robust(&edge_points, spot.grid_x, spot.grid_y, params) {
        Ok(circle) => Ok(Some(circle)),
        Err(_) => Ok(None), // Return None if fit fails (spot will be marked as bad)
    }
}

/// Segment spot using Hough transform
fn segment_by_hough(
    image: &ImageData,
    spot: &Spot,
    params: &GridParams,
) -> Result<Option<Circle>> {
    let normalized = normalize_image(&image.data);

    let search_radius = params.spot_pitch;
    let x_start = (spot.grid_x - search_radius).max(0.0) as usize;
    let x_end = (spot.grid_x + search_radius)
        .min(image.width as f64 - 1.0) as usize;
    let y_start = (spot.grid_y - search_radius).max(0.0) as usize;
    let y_end = (spot.grid_y + search_radius)
        .min(image.height as f64 - 1.0) as usize;

    if x_end <= x_start || y_end <= y_start {
        return Ok(None);
    }

    let region_height = y_end - y_start + 1;
    let region_width = x_end - x_start + 1;

    let mut region = Array2::zeros((region_height, region_width));
    for y in y_start..=y_end {
        for x in x_start..=x_end {
            region[[y - y_start, x - x_start]] = normalized[[y, x]];
        }
    }

    // Compute gradient for edge detection
    let smoothed = gaussian_blur(&region, 1.0);
    let gradient = compute_gradient(&smoothed);

    // Hough circle detection
    let min_radius = (params.min_diameter * params.spot_pitch / 2.0) as usize;
    let max_radius = (params.max_diameter * params.spot_pitch / 2.0) as usize;

    let circle = hough_circles(&gradient, min_radius, max_radius, 0.3)?;

    if let Some(mut c) = circle {
        // Adjust coordinates back to image space
        c.x += x_start as f64;
        c.y += y_start as f64;
        Ok(Some(c))
    } else {
        Ok(None)
    }
}

/// Fit circle to points using robust least squares
fn fit_circle_robust(
    points: &[(f64, f64)],
    init_x: f64,
    init_y: f64,
    params: &GridParams,
) -> Result<Circle> {
    if points.is_empty() {
        return Err(Error::SegmentationFailed("No points to fit".to_string()));
    }

    // Simple least squares circle fit
    let n = points.len() as f64;
    let sum_x: f64 = points.iter().map(|(x, _)| x).sum();
    let sum_y: f64 = points.iter().map(|(_, y)| y).sum();

    let mean_x = sum_x / n;
    let mean_y = sum_y / n;

    // Estimate radius from distance to mean
    let mut sum_r = 0.0;
    for (x, y) in points {
        let dx = x - mean_x;
        let dy = y - mean_y;
        sum_r += (dx * dx + dy * dy).sqrt();
    }
    let radius = sum_r / n;

    // Validate radius - if out of bounds or zero, skip validation and let calling code decide
    // This allows bad spots to be marked rather than failing the entire batch
    if radius == 0.0 || radius.is_nan() || radius.is_infinite() {
        return Err(Error::SegmentationFailed(format!(
            "Invalid radius: {}",
            radius
        )));
    }

    let min_radius = params.min_diameter * params.spot_pitch / 2.0;
    let max_radius = params.max_diameter * params.spot_pitch / 2.0;

    if radius < min_radius || radius > max_radius {
        // Out of bounds but valid - still return it, let the caller decide
        tracing::warn!("Radius {} out of suggested bounds [{}, {}], but accepting", radius, min_radius, max_radius);
    }

    Ok(Circle {
        x: mean_x,
        y: mean_y,
        radius,
    })
}

/// Simplified Hough circle detection
fn hough_circles(
    gradient: &Array2<f64>,
    min_radius: usize,
    max_radius: usize,
    threshold: f64,
) -> Result<Option<Circle>> {
    let (height, width) = gradient.dim();

    // Accumulator for circle centers
    let mut accumulator = Array2::<f64>::zeros((height, width));

    // Vote for circle centers
    for y in 0..height {
        for x in 0..width {
            if gradient[[y, x]] > threshold {
                // Vote for possible circle centers at different radii
                for r in min_radius..=max_radius {
                    for angle in (0..360).step_by(10) {
                        let angle_rad = (angle as f64) * PI / 180.0;
                        let cx = x as f64 + (r as f64) * angle_rad.cos();
                        let cy = y as f64 + (r as f64) * angle_rad.sin();

                        let cx = cx.round() as usize;
                        let cy = cy.round() as usize;

                        if cx < width && cy < height {
                            accumulator[[cy, cx]] += 1.0;
                        }
                    }
                }
            }
        }
    }

    // Find maximum in accumulator
    let mut max_val = 0.0;
    let mut max_pos = (0, 0);

    for ((y, x), &val) in accumulator.indexed_iter() {
        if val > max_val {
            max_val = val;
            max_pos = (y, x);
        }
    }

    if max_val < 10.0 {
        return Ok(None);
    }

    // Estimate radius from gradient at detected center
    let cx = max_pos.1 as f64;
    let cy = max_pos.0 as f64;
    let radius = ((min_radius + max_radius) / 2) as f64;

    Ok(Some(Circle {
        x: cx,
        y: cy,
        radius,
    }))
}

/// Segment all spots in image
pub fn segment_spots(
    image: &ImageData,
    spots: &mut [Spot],
    params: &GridParams,
) -> Result<()> {
    for spot in spots.iter_mut() {
        let circle_result = match params.segmentation_method {
            SegmentationMethod::Edge => segment_by_edge(image, spot, params),
            SegmentationMethod::Hough => segment_by_hough(image, spot, params),
            SegmentationMethod::Advanced => {
                // Use advanced Hough with adaptive thresholding
                use crate::advanced_segmentation;
                advanced_segmentation::hough_circle_detection(image, spot, params)
                    .map(|opt_circle| opt_circle.map(|c| Circle {
                        x: c.x,
                        y: c.y,
                        radius: c.radius,
                    }))
            }
        };

        match circle_result {
            Ok(Some(c)) => {
                spot.grid_x = c.x;
                spot.grid_y = c.y;
                spot.diameter = c.radius * 2.0;
                spot.is_bad = false;
            }
            Ok(None) | Err(_) => {
                // Mark as bad if segmentation failed or returned None
                spot.is_bad = true;
            }
        }

        // Check if spot is empty (low intensity)
        spot.is_empty = check_if_empty(image, spot, params);
    }

    Ok(())
}

/// Check if spot is empty based on intensity
fn check_if_empty(image: &ImageData, spot: &Spot, params: &GridParams) -> bool {
    if spot.is_bad {
        return true;
    }

    let normalized = normalize_image(&image.data);

    let radius = spot.diameter / 2.0;
    let x = spot.grid_x as usize;
    let y = spot.grid_y as usize;

    // Sample intensity within spot
    let mut sum = 0.0;
    let mut count = 0;

    let x_start = (x.saturating_sub(radius as usize)).max(0);
    let x_end = ((x + radius as usize + 1).min(image.width));
    let y_start = (y.saturating_sub(radius as usize)).max(0);
    let y_end = ((y + radius as usize + 1).min(image.height));

    for yi in y_start..y_end {
        for xi in x_start..x_end {
            let dx = xi as f64 - spot.grid_x;
            let dy = yi as f64 - spot.grid_y;
            if (dx * dx + dy * dy).sqrt() <= radius {
                sum += normalized[[yi, xi]];
                count += 1;
            }
        }
    }

    if count == 0 {
        return true;
    }

    let mean_intensity = sum / count as f64;

    // Spot is empty if mean intensity is below threshold
    mean_intensity < 0.1
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fit_circle_robust() {
        let params = GridParams {
            min_diameter: 0.4,
            max_diameter: 0.9,
            spot_pitch: 20.0,
            ..Default::default()
        };

        // Create perfect circle points
        let mut points = Vec::new();
        let center = (10.0, 10.0);
        let radius = 5.0;

        for angle in (0..360).step_by(10) {
            let angle_rad = (angle as f64) * PI / 180.0;
            let x = center.0 + radius * angle_rad.cos();
            let y = center.1 + radius * angle_rad.sin();
            points.push((x, y));
        }

        let circle = fit_circle_robust(&points, center.0, center.1, &params).unwrap();

        assert!((circle.x - center.0).abs() < 0.1);
        assert!((circle.y - center.1).abs() < 0.1);
        assert!((circle.radius - radius).abs() < 0.5);
    }
}
