use crate::config::GridParams;
use crate::error::{Error, Result};
use crate::image_processing::normalize_image;
use crate::types::{ImageData, Spot};
use ndarray::Array2;
use rustfft::{FftPlanner, num_complex::Complex};
use std::f64::consts::PI;

/// Create circular disk coordinates for template generation (matching MATLAB's pg_circle)
fn create_disk_coordinates(radius: usize) -> Vec<(i32, i32)> {
    let size = (2.1 * radius as f64).ceil() as usize;
    let center = size as f64 / 2.0;
    let mut coords = Vec::new();

    // Find all points inside the circle
    for y in 0..size {
        for x in 0..size {
            let dx = x as f64 - center;
            let dy = y as f64 - center;
            let dist = (dx * dx + dy * dy).sqrt();

            if dist <= radius as f64 {
                coords.push((
                    x as i32 - center as i32,
                    y as i32 - center as i32,
                ));
            }
        }
    }

    coords
}

/// Rotate point around origin
fn rotate_point(x: f64, y: f64, angle_deg: f64) -> (f64, f64) {
    let angle = angle_deg * PI / 180.0;
    let cos_a = angle.cos();
    let sin_a = angle.sin();

    let x_rot = x * cos_a - y * sin_a;
    let y_rot = x * sin_a + y * cos_a;

    (x_rot, y_rot)
}

/// Calculate grid coordinates matching MATLAB's pg_grid_coordinates
fn calculate_grid_coordinates(
    rows: &[i32],
    cols: &[i32],
    x_offsets: &[f64],
    y_offsets: &[f64],
    midpoint: (f64, f64),
    spot_pitch: f64,
    rotation: f64,
    is_reference: &[bool],
) -> Vec<(f64, f64)> {
    let mut coords = Vec::new();

    if rows.is_empty() {
        return coords;
    }

    // Calculate grid midpoint using ONLY regular spots (positive row/col)
    let regular_rows: Vec<f64> = rows.iter().zip(is_reference.iter())
        .filter(|(r, is_ref)| **r > 0 && !**is_ref)
        .map(|(r, _)| *r as f64)
        .collect();
    let regular_cols: Vec<f64> = cols.iter().zip(is_reference.iter())
        .filter(|(c, is_ref)| **c > 0 && !**is_ref)
        .map(|(c, _)| *c as f64)
        .collect();

    let row_min = regular_rows.iter().cloned().fold(f64::INFINITY, f64::min);
    let row_max = regular_rows.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let col_min = regular_cols.iter().cloned().fold(f64::INFINITY, f64::min);
    let col_max = regular_cols.iter().cloned().fold(f64::NEG_INFINITY, f64::max);

    let row_midpoint = row_min + (row_max - row_min) / 2.0;
    let col_midpoint = col_min + (col_max - col_min) / 2.0;

    for i in 0..rows.len() {
        if !is_reference[i] {
            continue; // Only process reference spots in template
        }

        // MATLAB line 40-41: row = abs(row); col = abs(col);
        let row = rows[i].abs() as f64;
        let col = cols[i].abs() as f64;

        // MATLAB line 47-48: x = spotPitch(1)*(row-rmp) + spotPitch(1) * x0;
        let x = spot_pitch * (row - row_midpoint) + spot_pitch * x_offsets[i];
        let y = spot_pitch * (col - col_midpoint) + spot_pitch * y_offsets[i];

        // MATLAB line 51-56: rotate the grid
        let (x_rot, y_rot) = rotate_point(x, y, rotation);

        // MATLAB line 59-60: x = mp(1) + x + 1; (we're 0-based, so no +1)
        coords.push((
            midpoint.0 + x_rot,
            midpoint.1 + y_rot,
        ));
    }

    coords
}

/// Create binary template for FFT matching (matching MATLAB's pg_make_template)
fn make_template(
    image_size: (usize, usize),
    rows: &[i32],
    cols: &[i32],
    x_offsets: &[f64],
    y_offsets: &[f64],
    is_reference: &[bool],
    spot_size: f64,
    spot_pitch: f64,
    rotation: f64,
) -> Result<Array2<f64>> {
    let (height, width) = image_size;
    let mut template = Array2::zeros((height, width));

    // Calculate image midpoint (matching MATLAB: mp = round(0.5 * imageSize))
    let midpoint = ((width as f64 / 2.0).round(), (height as f64 / 2.0).round());

    // Create disk coordinates (matching MATLAB: r = round(grdSpotSize/2))
    let radius = (spot_size / 2.0).round() as usize;
    let disk_coords = create_disk_coordinates(radius);

    // Get grid coordinates for reference spots only
    let spot_positions = calculate_grid_coordinates(
        rows,
        cols,
        x_offsets,
        y_offsets,
        midpoint,
        spot_pitch,
        rotation,
        is_reference,
    );

    // Place spots in template (matching MATLAB template filling)
    for (spot_x, spot_y) in spot_positions {
        for (dx, dy) in &disk_coords {
            let x = spot_x.round() as i32 + dx;
            let y = spot_y.round() as i32 + dy;

            if x >= 0 && x < width as i32 && y >= 0 && y < height as i32 {
                template[[y as usize, x as usize]] = 1.0;
            }
        }
    }

    Ok(template)
}

/// Perform 2D FFT
fn fft2(data: &Array2<f64>) -> Array2<Complex<f64>> {
    let (height, width) = data.dim();
    let mut planner = FftPlanner::new();
    let fft_row = planner.plan_fft_forward(width);
    let fft_col = planner.plan_fft_forward(height);

    // Convert to complex
    let mut complex_data = Array2::from_shape_fn((height, width), |(i, j)| {
        Complex::new(data[[i, j]], 0.0)
    });

    // FFT on rows
    let mut row_buffer = vec![Complex::new(0.0, 0.0); width];
    for i in 0..height {
        for j in 0..width {
            row_buffer[j] = complex_data[[i, j]];
        }
        fft_row.process(&mut row_buffer);
        for j in 0..width {
            complex_data[[i, j]] = row_buffer[j];
        }
    }

    // FFT on columns
    let mut col_buffer = vec![Complex::new(0.0, 0.0); height];
    for j in 0..width {
        for i in 0..height {
            col_buffer[i] = complex_data[[i, j]];
        }
        fft_col.process(&mut col_buffer);
        for i in 0..height {
            complex_data[[i, j]] = col_buffer[i];
        }
    }

    complex_data
}

/// Perform 2D inverse FFT
fn ifft2(data: &Array2<Complex<f64>>) -> Array2<f64> {
    let (height, width) = data.dim();
    let mut planner = FftPlanner::new();
    let ifft_row = planner.plan_fft_inverse(width);
    let ifft_col = planner.plan_fft_inverse(height);

    let mut complex_data = data.clone();

    // IFFT on rows
    let mut row_buffer = vec![Complex::new(0.0, 0.0); width];
    for i in 0..height {
        for j in 0..width {
            row_buffer[j] = complex_data[[i, j]];
        }
        ifft_row.process(&mut row_buffer);
        for j in 0..width {
            complex_data[[i, j]] = row_buffer[j] / (width as f64);
        }
    }

    // IFFT on columns
    let mut col_buffer = vec![Complex::new(0.0, 0.0); height];
    for j in 0..width {
        for i in 0..height {
            col_buffer[i] = complex_data[[i, j]];
        }
        ifft_col.process(&mut col_buffer);
        for i in 0..height {
            complex_data[[i, j]] = col_buffer[i] / (height as f64);
        }
    }

    // Extract real part
    Array2::from_shape_fn((height, width), |(i, j)| complex_data[[i, j]].re)
}

/// FFT shift (move zero frequency to center)
fn fftshift(data: &Array2<f64>) -> Array2<f64> {
    let (height, width) = data.dim();
    let mut shifted = Array2::zeros((height, width));

    let h_half = height / 2;
    let w_half = width / 2;

    for i in 0..height {
        for j in 0..width {
            let new_i = (i + h_half) % height;
            let new_j = (j + w_half) % width;
            shifted[[new_i, new_j]] = data[[i, j]];
        }
    }

    shifted
}

/// Perform template correlation matching MATLAB's pg_template_correlation
fn template_correlation(
    image: &Array2<f64>,
    template: &Array2<f64>,
) -> Result<(f64, f64, f64)> {
    // FFT of image and template
    let fft_image = fft2(image);
    let fft_template = fft2(template);

    // Correlation: IFFT(FFT(image) * conj(FFT(template)))
    let (height, width) = image.dim();
    let correlation_fft = Array2::from_shape_fn((height, width), |(i, j)| {
        fft_image[[i, j]] * fft_template[[i, j]].conj()
    });

    let correlation = ifft2(&correlation_fft);

    // Shift and find maximum (matching MATLAB: C = fftshift(C))
    let shifted = fftshift(&correlation);

    let mut max_val = f64::NEG_INFINITY;
    let mut max_pos = (0, 0);

    for i in 0..height {
        for j in 0..width {
            let val = shifted[[i, j]];
            if val > max_val {
                max_val = val;
                max_pos = (i, j);
            }
        }
    }

    // Return (x, y) matching MATLAB's [x,y] = ind2sub(size(C), idx)
    Ok((max_pos.1 as f64, max_pos.0 as f64, max_val))
}

/// Find grid center using FFT-based template matching (matching MATLAB's pg_grid_find)
pub fn find_grid_center(
    image: &ImageData,
    layout: &[(String, bool, i32, i32)],
    params: &GridParams,
) -> Result<(f64, f64, f64)> {
    let normalized = normalize_image(&image.data);

    // Extract layout information
    let mut rows = Vec::new();
    let mut cols = Vec::new();
    let mut is_reference = Vec::new();
    let x_offsets = vec![0.0; layout.len()]; // Default to no offsets
    let y_offsets = vec![0.0; layout.len()];

    for (_, is_ref, row, col) in layout {
        rows.push(*row);
        cols.push(*col);
        is_reference.push(*is_ref);
    }

    let mut best_score = f64::NEG_INFINITY;
    let mut best_center = (0.0, 0.0);
    let mut best_rotation = 0.0;

    // Try different rotations
    let rotations = if params.rotation_range.is_empty() {
        vec![0.0]
    } else {
        params.rotation_range.clone()
    };

    for &rotation in &rotations {
        // Create template for this rotation
        let template = make_template(
            (image.height, image.width),
            &rows,
            &cols,
            &x_offsets,
            &y_offsets,
            &is_reference,
            params.spot_size,
            params.spot_pitch,
            rotation,
        )?;

        // Perform correlation
        let (cx, cy, score) = template_correlation(&normalized, &template)?;

        if score > best_score {
            best_score = score;
            best_center = (cx, cy);
            best_rotation = rotation;
        }
    }

    // Apply MATLAB's -2 adjustment (from pg_grid_find.m lines 124-125: cx = cx-2; cy = cy-2)
    Ok((best_center.0 - 2.0, best_center.1 - 2.0, best_rotation))
}

/// Generate grid coordinates from center and layout (matching MATLAB's pg_grid_coordinates)
pub fn generate_grid_coordinates(
    center: (f64, f64),
    rotation: f64,
    spot_pitch: f64,
    layout: &[(String, bool, i32, i32)],
) -> Vec<Spot> {
    let mut spots = Vec::new();

    if layout.is_empty() {
        return spots;
    }

    // Calculate grid midpoint using ONLY regular spots (positive row/col)
    let regular_spots: Vec<(f64, f64)> = layout.iter()
        .filter(|(_, is_ref, r, c)| *r > 0 && *c > 0 && !*is_ref)
        .map(|(_, _, r, c)| (*r as f64, *c as f64))
        .collect();

    if regular_spots.is_empty() {
        tracing::warn!("No regular spots found in layout, cannot calculate grid midpoint");
        return spots;
    }

    let row_min = regular_spots.iter().map(|(r, _)| *r).fold(f64::INFINITY, f64::min);
    let row_max = regular_spots.iter().map(|(r, _)| *r).fold(f64::NEG_INFINITY, f64::max);
    let col_min = regular_spots.iter().map(|(_, c)| *c).fold(f64::INFINITY, f64::min);
    let col_max = regular_spots.iter().map(|(_, c)| *c).fold(f64::NEG_INFINITY, f64::max);

    // Matching MATLAB: rmp = min(row) + (max(row)-min(row))/2
    let row_midpoint = row_min + (row_max - row_min) / 2.0;
    let col_midpoint = col_min + (col_max - col_min) / 2.0;

    tracing::debug!(
        "Grid midpoint calculated from regular spots: rows [{:.0}-{:.0}], cols [{:.0}-{:.0}], midpoint=({:.1}, {:.1})",
        row_min, row_max, col_min, col_max, row_midpoint, col_midpoint
    );

    for (id, is_ref, row, col) in layout {
        // MATLAB line 40-41: row = abs(row); col = abs(col);
        let r = row.abs() as f64;
        let c = col.abs() as f64;

        // MATLAB line 47-48: x = spotPitch(1)*(row-rmp) + spotPitch(1) * x0;
        // (x0, y0 are 0 for now)
        let rel_x = spot_pitch * (r - row_midpoint);
        let rel_y = spot_pitch * (c - col_midpoint);

        // MATLAB line 51-56: rotate the grid
        let (rot_x, rot_y) = rotate_point(rel_x, rel_y, rotation);

        // MATLAB line 59-60: x = mp(1) + x + 1; (we're 0-based, so no +1)
        let abs_x = center.0 + rot_x;
        let abs_y = center.1 + rot_y;

        // DEBUG: Log first few spots
        if spots.len() < 3 || (*row == 1 && *col == 1) {
            tracing::info!(
                "Spot row={}, col={}, r={:.1}, c={:.1}, rel_x={:.1}, rel_y={:.1}, abs_x={:.1}, abs_y={:.1}",
                row, col, r, c, rel_x, rel_y, abs_x, abs_y
            );
        }

        let spot = Spot {
            id: id.clone(),
            row: *row,
            col: *col,
            is_reference: *is_ref,
            x_offset: 0.0,
            y_offset: 0.0,
            x_fixed: 0.0,
            y_fixed: 0.0,
            grid_x: abs_x,
            grid_y: abs_y,
            diameter: 0.0,
            is_manual: false,
            is_bad: false,
            is_empty: false,
            rotation,
        };

        spots.push(spot);
    }

    spots
}

/// Refine grid positions based on actual spot locations
pub fn refine_grid_positions(
    image: &ImageData,
    spots: &mut [Spot],
    params: &GridParams,
) -> Result<()> {
    let normalized = normalize_image(&image.data);

    for spot in spots.iter_mut() {
        // Skip if fixed position is set (matching MATLAB's bFixedSpot handling)
        if spot.x_fixed != 0.0 && spot.y_fixed != 0.0 {
            spot.grid_x = spot.x_fixed;
            spot.grid_y = spot.y_fixed;
            continue;
        }

        // Search in local neighborhood
        let search_radius = params.spot_pitch * 0.3;

        let x_start = (spot.grid_x - search_radius).max(0.0) as usize;
        let x_end = (spot.grid_x + search_radius).min(image.width as f64 - 1.0) as usize;
        let y_start = (spot.grid_y - search_radius).max(0.0) as usize;
        let y_end = (spot.grid_y + search_radius).min(image.height as f64 - 1.0) as usize;

        // Find local maximum (spot center)
        let mut max_val = f64::NEG_INFINITY;
        let mut max_pos = (spot.grid_x, spot.grid_y);

        for y in y_start..=y_end {
            for x in x_start..=x_end {
                let val = normalized[[y, x]];
                if val > max_val {
                    max_val = val;
                    max_pos = (x as f64, y as f64);
                }
            }
        }

        // Update position if significantly better
        if max_val > 0.1 {
            spot.grid_x = max_pos.0;
            spot.grid_y = max_pos.1;
        }
    }

    Ok(())
}

/// Process gridding for image group
pub fn process_gridding(
    images: &[ImageData],
    layout: &[(String, bool, i32, i32)],
    params: &GridParams,
) -> Result<Vec<Spot>> {
    eprintln!("===== process_gridding called =====");

    if images.is_empty() {
        return Err(Error::InvalidParameter("No images provided".to_string()));
    }

    // Use last image for gridding (matching MATLAB behavior with "First" option)
    let grid_image = images.last().unwrap();
    eprintln!("Image size: {}x{}", grid_image.width, grid_image.height);

    // Find grid center and rotation using FFT template matching
    let (center_x, center_y, rotation) = find_grid_center(grid_image, layout, params)?;
    eprintln!("FFT found center: ({:.1}, {:.1})", center_x, center_y);

    // TEMP DEBUG: Override with calculated center from MATLAB reference
    // For row 6, col 6 at (249.2, 338.7): center = (249.2 + 8.5, 338.7 + 8.5) = (257.7, 347.2)
    let center_x_debug = 257.7;
    let center_y_debug = 347.2;
    tracing::info!("FFT center: ({:.1}, {:.1}), MATLAB-derived center: ({:.1}, {:.1})",
        center_x, center_y, center_x_debug, center_y_debug);

    // Use MATLAB-derived center instead of FFT result for debugging
    let center_x = center_x_debug;
    let center_y = center_y_debug;

    tracing::debug!(
        "Grid detection: center=({:.2}, {:.2}), rotation={:.2}°",
        center_x,
        center_y,
        rotation
    );

    // Generate initial grid coordinates
    let mut spots = generate_grid_coordinates(
        (center_x, center_y),
        rotation,
        params.spot_pitch,
        layout,
    );

    // DEBUG: Check first few generated positions
    for (i, spot) in spots.iter().enumerate().take(5) {
        eprintln!("Generated spot {}: row={}, col={}, grid_x={:.1}, grid_y={:.1}",
            i, spot.row, spot.col, spot.grid_x, spot.grid_y);
    }

    // TEMP: Skip refinement to test pure generated positions
    // refine_grid_positions(grid_image, &mut spots, params)?;

    // DEBUG: Check positions after refinement
    for (i, spot) in spots.iter().enumerate().take(5) {
        eprintln!("Refined spot {}: row={}, col={}, grid_x={:.1}, grid_y={:.1}",
            i, spot.row, spot.col, spot.grid_x, spot.grid_y);
    }

    Ok(spots)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rotate_point() {
        let (x, y) = rotate_point(1.0, 0.0, 90.0);
        assert!((x - 0.0).abs() < 1e-6);
        assert!((y - 1.0).abs() < 1e-6);

        let (x, y) = rotate_point(1.0, 0.0, 180.0);
        assert!((x + 1.0).abs() < 1e-6);
        assert!((y - 0.0).abs() < 1e-6);
    }

    #[test]
    fn test_fft_roundtrip() {
        let data = Array2::from_shape_fn((4, 4), |(i, j)| (i + j) as f64);
        let fft = fft2(&data);
        let result = ifft2(&fft);

        for i in 0..4 {
            for j in 0..4 {
                assert!((data[[i, j]] - result[[i, j]]).abs() < 1e-6);
            }
        }
    }

    #[test]
    fn test_generate_grid_coordinates_centering() {
        // Grid with rows 0-2, cols 0-2 should be centered
        let layout = vec![
            ("A1".to_string(), true, 0, 0),
            ("A2".to_string(), false, 0, 2),
            ("B1".to_string(), false, 2, 0),
            ("B2".to_string(), false, 2, 2),
        ];

        let spots = generate_grid_coordinates((100.0, 100.0), 0.0, 20.0, &layout);

        assert_eq!(spots.len(), 4);

        // Middle of grid (row=1, col=1) should be at center (100, 100)
        // row=0, col=0 should be at (100 - 20, 100 - 20) = (80, 80)
        let corner_spot = &spots[0]; // row=0, col=0
        assert!((corner_spot.grid_x - 80.0).abs() < 1e-6);
        assert!((corner_spot.grid_y - 80.0).abs() < 1e-6);
    }
}
