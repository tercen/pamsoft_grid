use crate::config::GridParams;
use crate::error::{Error, Result};
use crate::image_processing::{cross_correlate, find_max_2d, normalize_image};
use crate::types::{ImageData, Spot};
use ndarray::Array2;
use std::f64::consts::PI;

/// Create a circular template for grid detection
fn create_circular_template(radius: f64, size: usize) -> Array2<f64> {
    let center = size as f64 / 2.0;
    let mut template = Array2::zeros((size, size));

    for y in 0..size {
        for x in 0..size {
            let dx = x as f64 - center;
            let dy = y as f64 - center;
            let dist = (dx * dx + dy * dy).sqrt();

            if dist <= radius {
                template[[y, x]] = 1.0;
            }
        }
    }

    // Normalize
    let sum: f64 = template.iter().sum();
    if sum > 0.0 {
        template.mapv_inplace(|x| x / sum);
    }

    template
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

/// Find grid center using template matching
pub fn find_grid_center(
    image: &ImageData,
    params: &GridParams,
) -> Result<(f64, f64, f64)> {
    let normalized = normalize_image(&image.data);

    // Create template based on spot size
    let template_radius = params.spot_size * params.spot_pitch / 2.0;
    let template_size = (template_radius * 3.0).ceil() as usize;
    let template = create_circular_template(template_radius, template_size);

    let mut best_score = f64::NEG_INFINITY;
    let mut best_center = (0.0, 0.0);
    let mut best_rotation = 0.0;

    // Try different rotations
    for &rotation in &params.rotation_range {
        // For intensity-based registration (rotation = 0), use direct correlation
        let correlation = cross_correlate(&normalized, &template);

        if let Some((score, (y, x))) = find_max_2d(&correlation) {
            if score > best_score {
                best_score = score;
                best_center = (
                    x as f64 + template.ncols() as f64 / 2.0,
                    y as f64 + template.nrows() as f64 / 2.0,
                );
                best_rotation = rotation;
            }
        }
    }

    if best_score == f64::NEG_INFINITY {
        return Err(Error::GridDetectionFailed(
            "Could not find grid center".to_string(),
        ));
    }

    Ok((best_center.0, best_center.1, best_rotation))
}

/// Generate grid coordinates from center and layout
pub fn generate_grid_coordinates(
    center: (f64, f64),
    rotation: f64,
    spot_pitch: f64,
    layout: &[(String, bool, usize, usize)],
) -> Vec<Spot> {
    let mut spots = Vec::new();

    for (id, is_ref, row, col) in layout {
        // Calculate position relative to center
        let rel_x = (*col as f64) * spot_pitch;
        let rel_y = (*row as f64) * spot_pitch;

        // Apply rotation
        let (rot_x, rot_y) = rotate_point(rel_x, rel_y, rotation);

        // Add center offset
        let abs_x = center.0 + rot_x;
        let abs_y = center.1 + rot_y;

        let spot = Spot {
            id: id.clone(),
            row: *row,
            col: *col,
            is_reference: *is_ref,
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
    layout: &[(String, bool, usize, usize)],
    params: &GridParams,
) -> Result<Vec<Spot>> {
    if images.is_empty() {
        return Err(Error::InvalidParameter("No images provided".to_string()));
    }

    // Use last image for gridding
    let grid_image = images.last().unwrap();

    // Find grid center and rotation
    let (center_x, center_y, rotation) = find_grid_center(grid_image, params)?;

    // Generate initial grid coordinates
    let mut spots = generate_grid_coordinates(
        (center_x, center_y),
        rotation,
        params.spot_pitch,
        layout,
    );

    // Refine positions
    refine_grid_positions(grid_image, &mut spots, params)?;

    Ok(spots)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_circular_template() {
        let template = create_circular_template(5.0, 11);
        assert_eq!(template.dim(), (11, 11));

        // Center should be non-zero
        assert!(template[[5, 5]] > 0.0);

        // Template should be normalized
        let sum: f64 = template.iter().sum();
        assert!((sum - 1.0).abs() < 1e-6);
    }

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
    fn test_generate_grid_coordinates() {
        let layout = vec![
            ("A1".to_string(), true, 0, 0),
            ("A2".to_string(), false, 0, 1),
            ("B1".to_string(), false, 1, 0),
        ];

        let spots = generate_grid_coordinates((100.0, 100.0), 0.0, 20.0, &layout);

        assert_eq!(spots.len(), 3);
        assert_eq!(spots[0].id, "A1");
        assert!(spots[0].is_reference);
        assert_eq!((spots[0].grid_x, spots[0].grid_y), (100.0, 100.0));
    }
}
