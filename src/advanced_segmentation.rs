use crate::config::GridParams;
use crate::error::{Error, Result};
use crate::image_processing::{compute_gradient, gaussian_blur, normalize_image};
use crate::types::{ImageData, Spot};
use ndarray::Array2;
use rayon::prelude::*;
use std::f64::consts::PI;

#[derive(Debug, Clone)]
pub struct Circle {
    pub x: f64,
    pub y: f64,
    pub radius: f64,
    pub votes: usize,
}

/// Advanced Hough Circle Transform implementation
pub fn hough_circle_detection(
    image: &ImageData,
    spot: &Spot,
    params: &GridParams,
) -> Result<Option<Circle>> {
    // Extract region around expected spot location
    let search_radius = params.spot_pitch;
    let x_start = (spot.grid_x - search_radius).max(0.0) as usize;
    let x_end = (spot.grid_x + search_radius).min(image.width as f64 - 1.0) as usize;
    let y_start = (spot.grid_y - search_radius).max(0.0) as usize;
    let y_end = (spot.grid_y + search_radius).min(image.height as f64 - 1.0) as usize;

    if x_end <= x_start || y_end <= y_start {
        return Ok(None);
    }

    let region_height = y_end - y_start + 1;
    let region_width = x_end - x_start + 1;

    // Extract region
    let mut region = Array2::zeros((region_height, region_width));
    for y in 0..region_height {
        for x in 0..region_width {
            region[[y, x]] = image.data[[y_start + y, x_start + x]];
        }
    }

    // Preprocess: normalize and blur
    let normalized = normalize_image(&region);
    let blurred = gaussian_blur(&normalized, 1.5);

    // Compute gradients
    let gradient = compute_gradient(&blurred);

    // Apply adaptive thresholding for edge pixels
    let edges = adaptive_edge_detection(&gradient, 0.3);

    // Define radius range based on spot size
    let min_radius = (params.min_diameter * params.spot_pitch / 2.0) as usize;
    let max_radius = (params.max_diameter * params.spot_pitch / 2.0) as usize;

    if min_radius >= max_radius || max_radius == 0 {
        return Ok(None);
    }

    // Perform Hough transform
    let circles = hough_transform(&edges, min_radius, max_radius, region_width, region_height)?;

    // Find best circle
    if let Some(best) = circles.first() {
        // Adjust coordinates back to image space
        let circle = Circle {
            x: best.x + x_start as f64,
            y: best.y + y_start as f64,
            radius: best.radius,
            votes: best.votes,
        };

        // Refine circle parameters using least squares
        let refined = refine_circle_parameters(&gradient, &circle, &edges)?;

        Ok(Some(refined))
    } else {
        Ok(None)
    }
}

/// Adaptive edge detection using local statistics
fn adaptive_edge_detection(gradient: &Array2<f64>, percentile: f64) -> Array2<bool> {
    let (height, width) = gradient.dim();
    let mut edges = Array2::from_elem((height, width), false);

    // Compute threshold using percentile
    let mut values: Vec<f64> = gradient.iter().copied().collect();
    values.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let threshold_idx = (values.len() as f64 * (1.0 - percentile)) as usize;
    let threshold = values.get(threshold_idx).copied().unwrap_or(0.0);

    // Mark edges above threshold
    for y in 0..height {
        for x in 0..width {
            if gradient[[y, x]] >= threshold {
                edges[[y, x]] = true;
            }
        }
    }

    edges
}

/// Hough Transform for circle detection
fn hough_transform(
    edges: &Array2<bool>,
    min_radius: usize,
    max_radius: usize,
    width: usize,
    height: usize,
) -> Result<Vec<Circle>> {
    // Create accumulator array [x, y, radius]
    let num_radii = max_radius - min_radius + 1;
    let mut accumulator = vec![vec![vec![0usize; num_radii]; width]; height];

    // Vote for circles
    for y in 0..height {
        for x in 0..width {
            if !edges[[y, x]] {
                continue;
            }

            // For each edge pixel, vote for possible circle centers
            for (r_idx, radius) in (min_radius..=max_radius).enumerate() {
                // Vote in circular pattern around edge pixel
                for angle_deg in (0..360).step_by(15) {
                    let angle = angle_deg as f64 * PI / 180.0;
                    let cx = x as f64 + radius as f64 * angle.cos();
                    let cy = y as f64 + radius as f64 * angle.sin();

                    let cx_i = cx.round() as isize;
                    let cy_i = cy.round() as isize;

                    if cx_i >= 0 && cx_i < width as isize && cy_i >= 0 && cy_i < height as isize {
                        accumulator[cy_i as usize][cx_i as usize][r_idx] += 1;
                    }
                }
            }
        }
    }

    // Find peaks in accumulator
    let mut circles = Vec::new();
    let min_votes = 10; // Minimum votes to consider

    for y in 0..height {
        for x in 0..width {
            for r_idx in 0..num_radii {
                let votes = accumulator[y][x][r_idx];
                if votes >= min_votes {
                    circles.push(Circle {
                        x: x as f64,
                        y: y as f64,
                        radius: (min_radius + r_idx) as f64,
                        votes,
                    });
                }
            }
        }
    }

    // Sort by votes (descending)
    circles.sort_by(|a, b| b.votes.cmp(&a.votes));

    // Non-maximum suppression: remove overlapping circles
    let mut filtered = Vec::new();
    for circle in circles {
        let overlaps = filtered.iter().any(|c: &Circle| {
            let dx = circle.x - c.x;
            let dy = circle.y - c.y;
            let dist = (dx * dx + dy * dy).sqrt();
            dist < (circle.radius + c.radius) * 0.5
        });

        if !overlaps {
            filtered.push(circle);
        }

        if filtered.len() >= 3 {
            break; // Keep top 3 candidates
        }
    }

    Ok(filtered)
}

/// Refine circle parameters using least squares fitting
fn refine_circle_parameters(
    gradient: &Array2<f64>,
    initial: &Circle,
    edges: &Array2<bool>,
) -> Result<Circle> {
    let (height, width) = gradient.dim();

    // Collect edge points near the circle
    let mut edge_points = Vec::new();
    let search_radius = initial.radius * 1.5;

    for y in 0..height {
        for x in 0..width {
            if !edges[[y, x]] {
                continue;
            }

            let dx = x as f64 - initial.x;
            let dy = y as f64 - initial.y;
            let dist = (dx * dx + dy * dy).sqrt();

            if (dist - initial.radius).abs() < search_radius * 0.3 {
                edge_points.push((x as f64, y as f64));
            }
        }
    }

    if edge_points.len() < 10 {
        return Ok(initial.clone());
    }

    // Fit circle using algebraic approach
    let n = edge_points.len() as f64;
    let mut sum_x = 0.0;
    let mut sum_y = 0.0;
    let mut sum_x2 = 0.0;
    let mut sum_y2 = 0.0;
    let mut sum_xy = 0.0;
    let mut sum_x3 = 0.0;
    let mut sum_y3 = 0.0;
    let mut sum_x2y = 0.0;
    let mut sum_xy2 = 0.0;

    for &(x, y) in &edge_points {
        sum_x += x;
        sum_y += y;
        sum_x2 += x * x;
        sum_y2 += y * y;
        sum_xy += x * y;
        sum_x3 += x * x * x;
        sum_y3 += y * y * y;
        sum_x2y += x * x * y;
        sum_xy2 += x * y * y;
    }

    // Solve system of equations
    let a11 = sum_x2;
    let a12 = sum_xy;
    let a13 = sum_x;
    let a22 = sum_y2;
    let a23 = sum_y;
    let a33 = n;

    let b1 = -(sum_x3 + sum_xy2);
    let b2 = -(sum_x2y + sum_y3);
    let b3 = -(sum_x2 + sum_y2);

    // Simple 3x3 determinant solve
    let det = a11 * (a22 * a33 - a23 * a23)
        - a12 * (a12 * a33 - a13 * a23)
        + a13 * (a12 * a23 - a13 * a22);

    if det.abs() < 1e-10 {
        return Ok(initial.clone());
    }

    let cx = (b1 * (a22 * a33 - a23 * a23)
        - a12 * (b2 * a33 - b3 * a23)
        + a13 * (b2 * a23 - b3 * a22))
        / det
        / -2.0;

    let cy = (a11 * (b2 * a33 - b3 * a23)
        - b1 * (a12 * a33 - a13 * a23)
        + a13 * (a12 * b3 - a13 * b2))
        / det
        / -2.0;

    // Calculate radius from center
    let mut sum_r = 0.0;
    for &(x, y) in &edge_points {
        let dx = x - cx;
        let dy = y - cy;
        sum_r += (dx * dx + dy * dy).sqrt();
    }
    let radius = sum_r / edge_points.len() as f64;

    // Validate refined parameters
    if radius > 0.0 && radius < width as f64 && radius < height as f64 {
        Ok(Circle {
            x: cx,
            y: cy,
            radius,
            votes: initial.votes,
        })
    } else {
        Ok(initial.clone())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_adaptive_edge_detection() {
        let mut gradient = Array2::zeros((10, 10));
        gradient[[5, 5]] = 1.0;
        gradient[[5, 6]] = 0.9;

        let edges = adaptive_edge_detection(&gradient, 0.1);
        assert!(edges[[5, 5]]);
    }
}
