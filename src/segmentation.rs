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

/// Segment spot using edge-based method matching MATLAB's pg_seg_segment_by_edge
fn segment_by_edge(
    image: &ImageData,
    spot: &Spot,
    params: &GridParams,
) -> Result<Option<Circle>> {
    use imageproc::morphology::{erode, dilate};
    use imageproc::distance_transform::Norm;

    let normalized = normalize_image(&image.data);
    let spot_pitch = params.spot_pitch;

    // Default radius for fallback
    let default_radius = 0.6 * spot_pitch / 2.0;

    // Get initial position
    let cx = spot.grid_x;
    let cy = spot.grid_y;

    // Define ROI bounds (2× spot pitch window, matching MATLAB lines 8-17)
    let x_lu = (cx - spot_pitch).max(0.0) as usize;
    let y_lu = (cy - spot_pitch).max(0.0) as usize;
    let x_rl = (cx + spot_pitch).min((image.width - 1) as f64) as usize;
    let y_rl = (cy + spot_pitch).min((image.height - 1) as f64) as usize;

    if x_rl <= x_lu || y_rl <= y_lu {
        return Ok(None);
    }

    // Extract and filter ROI (MATLAB lines 26-33)
    let roi_width = x_rl - x_lu + 1;
    let roi_height = y_rl - y_lu + 1;
    let mut roi = Array2::zeros((roi_height, roi_width));

    for y in 0..roi_height {
        for x in 0..roi_width {
            roi[[y, x]] = normalized[[y_lu + y, x_lu + x]];
        }
    }

    // Apply morphological filtering if needed (MATLAB lines 29-33)
    if params.small_disk * spot_pitch >= 1.0 {
        let filter_disk_radius = (params.small_disk * spot_pitch / 2.0).round() as u32;
        // Note: morphological filtering would go here - simplified for now
        // This matches: se = strel('disk', round(segNFilterDisk/2))
    }

    // Apply Canny edge detection (MATLAB line 38)
    let lower_threshold = params.edge_sensitivity[0] as f32;
    let upper_threshold = params.edge_sensitivity[1] as f32;

    // Convert to imageproc format
    let array_view = roi.view();
    let mut img_u8 = image::GrayImage::new(roi_width as u32, roi_height as u32);
    for y in 0..roi_height {
        for x in 0..roi_width {
            let val = (array_view[[y, x]] * 255.0).min(255.0).max(0.0) as u8;
            img_u8.put_pixel(x as u32, y as u32, image::Luma([val]));
        }
    }

    let edges = imageproc::edges::canny(&img_u8, lower_threshold, upper_threshold);

    // Convert edges back to bool array
    let mut edge_map = Array2::<bool>::default((roi_height, roi_width));
    for y in 0..roi_height {
        for x in 0..roi_width {
            edge_map[[y, x]] = edges.get_pixel(x as u32, y as u32)[0] > 0;
        }
    }

    // Compute parameters for iteration (MATLAB lines 47-49)
    let pix_area_size = params.area_size * spot_pitch;
    let pix_off = ((spot_pitch - 0.5 * pix_area_size).max(0.0)).round() as isize;
    let spot_pitch_i = spot_pitch.round() as isize;

    // Iterative refinement loop (MATLAB lines 60-140)
    let mut current_midpoint = (cx, cy);
    let mut x_local = (x_lu as isize, x_lu as isize + 2 * spot_pitch_i);
    let mut y_local = (y_lu as isize, y_lu as isize + 2 * spot_pitch_i);

    let max_iterations = 3;
    let mut spot_found = false;
    let mut final_circle = None;

    for iteration in 0..max_iterations {
        // Clamp local coordinates to image bounds
        x_local.0 = x_local.0.max(0).min(image.width as isize - 1);
        x_local.1 = x_local.1.max(x_local.0 + 1).min(image.width as isize);
        y_local.0 = y_local.0.max(0).min(image.height as isize - 1);
        y_local.1 = y_local.1.max(y_local.0 + 1).min(image.height as isize);

        // Define search window with offset (MATLAB lines 85-86)
        let x_init = (x_local.0 + pix_off, x_local.1 - pix_off);
        let y_init = (y_local.0 + pix_off, y_local.1 - pix_off);

        if x_init.1 <= x_init.0 || y_init.1 <= y_init.0 {
            break;
        }

        // Extract local edge region
        let local_width = (x_init.1 - x_init.0) as usize;
        let local_height = (y_init.1 - y_init.0) as usize;

        // Find connected components in edge map (MATLAB lines 93-96)
        let mut edge_pixels = Vec::new();

        for y in y_init.0..y_init.1 {
            for x in x_init.0..x_init.1 {
                if y >= y_lu as isize && y < y_rl as isize &&
                   x >= x_lu as isize && x < x_rl as isize {
                    let roi_y = (y - y_lu as isize) as usize;
                    let roi_x = (x - x_lu as isize) as usize;
                    if roi_y < edge_map.nrows() && roi_x < edge_map.ncols() && edge_map[[roi_y, roi_x]] {
                        edge_pixels.push((x as f64, y as f64));
                    }
                }
            }
        }

        // Check minimum edge pixels (MATLAB line 102)
        if edge_pixels.len() >= params.min_edge_pixels {
            spot_found = true;

            // Fit circle to edge pixels (MATLAB line 120)
            if let Some(circle) = fit_circle_robust(&edge_pixels) {
                // Calculate movement (MATLAB lines 125-127)
                let dx = circle.x - current_midpoint.0;
                let dy = circle.y - current_midpoint.1;
                let delta = (dx * dx + dy * dy).sqrt();

                current_midpoint = (circle.x, circle.y);
                final_circle = Some(circle);

                // Converged? (MATLAB line 71)
                if delta <= 2.0_f64.sqrt() {
                    break;
                }

                // Shift window for next iteration (MATLAB lines 131-139)
                x_local.0 = (x_local.0 as f64 + dx).round() as isize;
                x_local.1 = (x_local.1 as f64 + dx).round() as isize;
                y_local.0 = (y_local.0 as f64 + dy).round() as isize;
                y_local.1 = (y_local.1 as f64 + dy).round() as isize;
            } else {
                spot_found = false;
                break;
            }
        } else {
            spot_found = false;
            break;
        }
    }

    // Return result (MATLAB lines 143-152)
    if spot_found {
        Ok(final_circle)
    } else {
        // Use default radius for empty spots
        Ok(Some(Circle {
            x: cx,
            y: cy,
            radius: default_radius,
        }))
    }
}

/// Old placeholder gradient-based method (deprecated)
fn segment_by_edge_old(
    image: &ImageData,
    spot: &Spot,
    params: &GridParams,
) -> Result<Option<Circle>> {
    use imageproc::morphology::{erode, dilate};
    use imageproc::distance_transform::Norm;

    let normalized = normalize_image(&image.data);
    let spot_pitch = params.spot_pitch;

    // Default radius for fallback
    let default_radius = 0.6 * spot_pitch / 2.0;

    // Get initial position
    let cx = spot.grid_x;
    let cy = spot.grid_y;

    // Define ROI bounds (2× spot pitch window, matching MATLAB lines 8-17)
    let x_lu = (cx - spot_pitch).max(0.0) as usize;
    let y_lu = (cy - spot_pitch).max(0.0) as usize;
    let x_rl = (cx + spot_pitch).min((image.width - 1) as f64) as usize;
    let y_rl = (cy + spot_pitch).min((image.height - 1) as f64) as usize;

    if x_rl <= x_lu || y_rl <= y_lu {
        return Ok(None);
    }

    // Extract and filter ROI (MATLAB lines 26-33)
    let roi_width = x_rl - x_lu + 1;
    let roi_height = y_rl - y_lu + 1;
    let mut roi = Array2::zeros((roi_height, roi_width));

    for y in 0..roi_height {
        for x in 0..roi_width {
            roi[[y, x]] = normalized[[y_lu + y, x_lu + x]];
        }
    }

    // Apply morphological filtering if needed (MATLAB lines 29-33)
    if params.small_disk * spot_pitch >= 1.0 {
        let filter_disk_radius = (params.small_disk * spot_pitch / 2.0).round() as u32;
        // Note: morphological filtering would go here - simplified for now
        // This matches: se = strel('disk', round(segNFilterDisk/2))
    }

    // Apply Canny edge detection (MATLAB line 38)
    let lower_threshold = params.edge_sensitivity[0] as f32;
    let upper_threshold = params.edge_sensitivity[1] as f32;

    // Convert to imageproc format
    let array_view = roi.view();
    let mut img_u8 = image::GrayImage::new(roi_width as u32, roi_height as u32);
    for y in 0..roi_height {
        for x in 0..roi_width {
            let val = (array_view[[y, x]] * 255.0).min(255.0).max(0.0) as u8;
            img_u8.put_pixel(x as u32, y as u32, image::Luma([val]));
        }
    }

    let edges = imageproc::edges::canny(&img_u8, lower_threshold, upper_threshold);

    // Convert edges back to bool array
    let mut edge_map = Array2::<bool>::default((roi_height, roi_width));
    for y in 0..roi_height {
        for x in 0..roi_width {
            edge_map[[y, x]] = edges.get_pixel(x as u32, y as u32)[0] > 0;
        }
    }

    // Compute parameters for iteration (MATLAB lines 47-49)
    let pix_area_size = params.area_size * spot_pitch;
    let pix_off = ((spot_pitch - 0.5 * pix_area_size).max(0.0)).round() as isize;
    let spot_pitch_i = spot_pitch.round() as isize;

    // Iterative refinement loop (MATLAB lines 60-140)
    let mut current_midpoint = (cx, cy);
    let mut x_local = (x_lu as isize, x_lu as isize + 2 * spot_pitch_i);
    let mut y_local = (y_lu as isize, y_lu as isize + 2 * spot_pitch_i);

    let max_iterations = 3;
    let mut spot_found = false;
    let mut final_circle = None;

    for iteration in 0..max_iterations {
        // Clamp local coordinates to image bounds
        x_local.0 = x_local.0.max(0).min(image.width as isize - 1);
        x_local.1 = x_local.1.max(x_local.0 + 1).min(image.width as isize);
        y_local.0 = y_local.0.max(0).min(image.height as isize - 1);
        y_local.1 = y_local.1.max(y_local.0 + 1).min(image.height as isize);

        // Define search window with offset (MATLAB lines 85-86)
        let x_init = (x_local.0 + pix_off, x_local.1 - pix_off);
        let y_init = (y_local.0 + pix_off, y_local.1 - pix_off);

        if x_init.1 <= x_init.0 || y_init.1 <= y_init.0 {
            break;
        }

        // Extract local edge region
        let local_width = (x_init.1 - x_init.0) as usize;
        let local_height = (y_init.1 - y_init.0) as usize;

        // Find connected components in edge map (MATLAB lines 93-96)
        let mut edge_pixels = Vec::new();

        for y in y_init.0..y_init.1 {
            for x in x_init.0..x_init.1 {
                if y >= y_lu as isize && y < y_rl as isize &&
                   x >= x_lu as isize && x < x_rl as isize {
                    let roi_y = (y - y_lu as isize) as usize;
                    let roi_x = (x - x_lu as isize) as usize;
                    if roi_y < edge_map.nrows() && roi_x < edge_map.ncols() && edge_map[[roi_y, roi_x]] {
                        edge_pixels.push((x as f64, y as f64));
                    }
                }
            }
        }

        // Check minimum edge pixels (MATLAB line 102)
        if edge_pixels.len() >= params.min_edge_pixels {
            spot_found = true;

            // Fit circle to edge pixels (MATLAB line 120)
            if let Some(circle) = fit_circle_robust(&edge_pixels) {
                // Calculate movement (MATLAB lines 125-127)
                let dx = circle.x - current_midpoint.0;
                let dy = circle.y - current_midpoint.1;
                let delta = (dx * dx + dy * dy).sqrt();

                current_midpoint = (circle.x, circle.y);
                final_circle = Some(circle);

                // Converged? (MATLAB line 71)
                if delta <= 2.0_f64.sqrt() {
                    break;
                }

                // Shift window for next iteration (MATLAB lines 131-139)
                x_local.0 = (x_local.0 as f64 + dx).round() as isize;
                x_local.1 = (x_local.1 as f64 + dx).round() as isize;
                y_local.0 = (y_local.0 as f64 + dy).round() as isize;
                y_local.1 = (y_local.1 as f64 + dy).round() as isize;
            } else {
                spot_found = false;
                break;
            }
        } else {
            spot_found = false;
            break;
        }
    }

    // Return result (MATLAB lines 143-152)
    if spot_found {
        Ok(final_circle)
    } else {
        // Use default radius for empty spots
        Ok(Some(Circle {
            x: cx,
            y: cy,
            radius: default_radius,
        }))
    }
}

/// Old placeholder gradient-based method (deprecated)
fn segment_by_edge_old(
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

                // Check diameter bounds (MATLAB: sqcMinDiameter, sqcMaxDiameter)
                // Diameter is relative to spot_pitch
                let relative_diameter = spot.diameter / params.spot_pitch;
                if relative_diameter < params.min_diameter || relative_diameter > params.max_diameter {
                    spot.is_bad = true;
                } else {
                    spot.is_bad = false;
                }
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

/// Fit circle to points using weighted least squares
/// Based on MATLAB's pg_seg_circfit.m
/// Solves: x^2 + y^2 + a1*x + a2*y + a3 = 0
fn fit_circle_weighted(points: &[(f64, f64)], weights: &[f64]) -> Option<Circle> {
    if points.len() < 3 {
        return None;
    }

    let n = points.len();

    // Build weighted least squares system: A*a = b
    // A = [x, y, 1], b = -(x^2 + y^2)
    let mut atwa = [[0.0; 3]; 3];  // A^T * W * A
    let mut atwb = [0.0; 3];        // A^T * W * b

    for i in 0..n {
        let (x, y) = points[i];
        let w = weights[i];
        let b = -(x * x + y * y);

        // A^T * W * A
        atwa[0][0] += w * x * x;
        atwa[0][1] += w * x * y;
        atwa[0][2] += w * x;
        atwa[1][1] += w * y * y;
        atwa[1][2] += w * y;
        atwa[2][2] += w;

        // A^T * W * b
        atwb[0] += w * x * b;
        atwb[1] += w * y * b;
        atwb[2] += w * b;
    }

    // Symmetric matrix
    atwa[1][0] = atwa[0][1];
    atwa[2][0] = atwa[0][2];
    atwa[2][1] = atwa[1][2];

    // Solve 3x3 system using Gaussian elimination with partial pivoting
    let mut a = atwa;
    let mut b = atwb;

    // Forward elimination
    for k in 0..2 {
        // Find pivot
        let mut max_row = k;
        for i in (k+1)..3 {
            if a[i][k].abs() > a[max_row][k].abs() {
                max_row = i;
            }
        }

        // Swap rows
        if max_row != k {
            a.swap(k, max_row);
            b.swap(k, max_row);
        }

        if a[k][k].abs() < 1e-10 {
            return None;  // Singular matrix
        }

        // Eliminate
        for i in (k+1)..3 {
            let factor = a[i][k] / a[k][k];
            for j in k..3 {
                a[i][j] -= factor * a[k][j];
            }
            b[i] -= factor * b[k];
        }
    }

    // Back substitution
    let mut coef = [0.0; 3];
    for i in (0..3).rev() {
        let mut sum = b[i];
        for j in (i+1)..3 {
            sum -= a[i][j] * coef[j];
        }
        coef[i] = sum / a[i][i];
    }

    // Extract circle parameters
    let xc = -0.5 * coef[0];
    let yc = -0.5 * coef[1];
    let r_sq = (coef[0] * coef[0] + coef[1] * coef[1]) / 4.0 - coef[2];

    if r_sq <= 0.0 {
        return None;
    }

    Some(Circle {
        x: xc,
        y: yc,
        radius: r_sq.sqrt(),
    })
}

/// Calculate Tukey bisquare weights for robust fitting
/// Based on MATLAB's pg_seg_calc_tukey_weights.m
fn calculate_tukey_weights(residuals: &[f64]) -> Vec<f64> {
    let k = 4.685;  // Tukey constant

    // Calculate MAD (Median Absolute Deviation)
    let mut abs_res: Vec<f64> = residuals.iter().map(|r| r.abs()).collect();
    abs_res.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let mad = if abs_res.len() % 2 == 0 {
        (abs_res[abs_res.len() / 2 - 1] + abs_res[abs_res.len() / 2]) / 2.0
    } else {
        abs_res[abs_res.len() / 2]
    };

    // Handle zero MAD
    let mad = if mad < 1e-10 {
        residuals.iter().map(|r| r.abs()).sum::<f64>() / residuals.len() as f64 * 0.001
    } else {
        mad
    };

    // Robust variance estimate
    let rob_var = mad / 0.6745;

    // Calculate Tukey bisquare weights
    residuals.iter().map(|&r| {
        let w_res = r / (k * rob_var);
        if w_res.abs() < 1.0 {
            let temp = 1.0 - w_res * w_res;
            temp * temp
        } else {
            0.0
        }
    }).collect()
}

/// Fit circle using robust iterative reweighted least squares
/// Based on MATLAB's pg_seg_rob_circ_fit.m
fn fit_circle_robust(points: &[(f64, f64)]) -> Option<Circle> {
    if points.len() < 3 {
        return None;
    }

    let max_iter = 10;
    let eps = 0.001;

    // Initial fit with unit weights
    let mut weights = vec![1.0; points.len()];
    let mut circle = fit_circle_weighted(points, &weights)?;

    let mut chi_sqr = calculate_chi_square(points, &circle, &weights);

    // Iterative refinement with robust weighting
    for _ in 0..max_iter {
        let old_chi_sqr = chi_sqr;

        // Calculate residuals
        let residuals: Vec<f64> = points.iter().map(|(x, y)| {
            let dx = x - circle.x;
            let dy = y - circle.y;
            let dist = (dx * dx + dy * dy).sqrt();
            let res = dist - circle.radius;
            res * res  // Squared residual
        }).collect();

        // Calculate Tukey weights
        weights = calculate_tukey_weights(&residuals);

        // Refit with new weights
        circle = fit_circle_weighted(points, &weights)?;
        chi_sqr = calculate_chi_square(points, &circle, &weights);

        // Check convergence
        if (chi_sqr - old_chi_sqr).abs() / chi_sqr <= eps {
            break;
        }
    }

    Some(circle)
}

/// Calculate chi-square goodness of fit
fn calculate_chi_square(points: &[(f64, f64)], circle: &Circle, weights: &[f64]) -> f64 {
    let mut chi_sqr = 0.0;
    for (i, (x, y)) in points.iter().enumerate() {
        let dx = x - circle.x;
        let dy = y - circle.y;
        let dist = (dx * dx + dy * dy).sqrt();
        let res = dist - circle.radius;
        chi_sqr += weights[i] * res * res;
    }
    chi_sqr / (points.len() as f64 - 3.0).max(1.0)
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
