/// Unit tests for Phase 1 grid coordinate calculation
/// Focus on diagonal bias and non-integer pitch handling

use pamsoft_grid::grid::generate_grid_coordinates;
use pamsoft_grid::types::Spot;
use std::collections::HashMap;

#[cfg(test)]
mod grid_tests {
    use super::*;

    /// Test that grid coordinates have no diagonal bias
    #[test]
    fn test_no_diagonal_bias() {
        // Create a simple 5x5 grid with non-integer pitch (like real data)
        let center = (200.0, 200.0);
        let rotation = 0.0;
        let spot_pitch = 21.5; // Non-integer pitch that causes the issue

        let mut layout = Vec::new();
        for row in 1..=5 {
            for col in 1..=5 {
                let spot_id = format!("spot_{}_{}", row, col);
                layout.push((spot_id, false, row, col));
            }
        }

        let spots = generate_grid_coordinates(center, rotation, spot_pitch, &layout);

        // Group spots by diagonal (row + col)
        let mut diagonal_positions: HashMap<i32, Vec<(f64, f64)>> = HashMap::new();
        for spot in &spots {
            let diagonal = spot.row as i32 + spot.col as i32;
            diagonal_positions.entry(diagonal)
                .or_insert_with(Vec::new)
                .push((spot.grid_x, spot.grid_y));
        }

        // Check fractional parts - they should be consistent
        let mut diagonal_fractional: HashMap<i32, Vec<(f64, f64)>> = HashMap::new();
        for spot in &spots {
            let diagonal = spot.row as i32 + spot.col as i32;
            let frac_x = spot.grid_x.fract().abs();
            let frac_y = spot.grid_y.fract().abs();
            diagonal_fractional.entry(diagonal)
                .or_insert_with(Vec::new)
                .push((frac_x, frac_y));
        }

        // Calculate standard deviation of fractional parts for each diagonal
        for (diagonal, fracs) in &diagonal_fractional {
            if fracs.len() > 1 {
                let mean_x: f64 = fracs.iter().map(|(x, _)| x).sum::<f64>() / fracs.len() as f64;
                let mean_y: f64 = fracs.iter().map(|(_, y)| y).sum::<f64>() / fracs.len() as f64;

                let var_x: f64 = fracs.iter()
                    .map(|(x, _)| (x - mean_x).powi(2))
                    .sum::<f64>() / fracs.len() as f64;
                let var_y: f64 = fracs.iter()
                    .map(|(_, y)| (y - mean_y).powi(2))
                    .sum::<f64>() / fracs.len() as f64;

                // Within a diagonal, fractional parts should be very similar (std < 0.1)
                assert!(var_x.sqrt() < 0.1,
                    "Diagonal {} has inconsistent X fractional parts: std={:.3}",
                    diagonal, var_x.sqrt());
                assert!(var_y.sqrt() < 0.1,
                    "Diagonal {} has inconsistent Y fractional parts: std={:.3}",
                    diagonal, var_y.sqrt());
            }
        }

        // Main test: Check that odd and even diagonals don't have systematic difference
        // Calculate average fractional part for odd vs even diagonals
        let mut odd_fracs = Vec::new();
        let mut even_fracs = Vec::new();

        for (diagonal, fracs) in &diagonal_fractional {
            let avg_frac = fracs.iter()
                .map(|(x, y)| (x + y) / 2.0)
                .sum::<f64>() / fracs.len() as f64;

            if diagonal % 2 == 1 {
                odd_fracs.push(avg_frac);
            } else {
                even_fracs.push(avg_frac);
            }
        }

        if !odd_fracs.is_empty() && !even_fracs.is_empty() {
            let odd_mean = odd_fracs.iter().sum::<f64>() / odd_fracs.len() as f64;
            let even_mean = even_fracs.iter().sum::<f64>() / even_fracs.len() as f64;

            // The difference in fractional parts should be small (<0.1)
            // Currently this will FAIL, demonstrating the diagonal bias
            let diff = (odd_mean - even_mean).abs();
            assert!(diff < 0.1,
                "Diagonal bias detected: odd diagonals avg frac={:.3}, even diagonals avg frac={:.3}, diff={:.3}",
                odd_mean, even_mean, diff);
        }
    }

    /// Test that coordinates with integer pitch have no fractional parts
    #[test]
    fn test_integer_pitch_no_fractions() {
        let center = (200.0, 200.0);
        let rotation = 0.0;
        let spot_pitch = 20.0; // Integer pitch

        let mut layout = Vec::new();
        for row in 1..=5 {
            for col in 1..=5 {
                let spot_id = format!("spot_{}_{}", row, col);
                layout.push((spot_id, false, row, col));
            }
        }

        let spots = generate_grid_coordinates(center, rotation, spot_pitch, &layout);

        // With integer pitch and integer center, all coordinates should be integers
        for spot in &spots {
            let frac_x = spot.grid_x.fract().abs();
            let frac_y = spot.grid_y.fract().abs();

            assert!(frac_x < 0.01 || frac_x > 0.99,
                "Spot at row={}, col={} has non-integer X={:.2} with integer pitch",
                spot.row, spot.col, spot.grid_x);
            assert!(frac_y < 0.01 || frac_y > 0.99,
                "Spot at row={}, col={} has non-integer Y={:.2} with integer pitch",
                spot.row, spot.col, spot.grid_y);
        }
    }

    /// Test grid spacing consistency
    #[test]
    fn test_grid_spacing_consistency() {
        let center = (200.0, 200.0);
        let rotation = 0.0;
        let spot_pitch = 21.5;

        let mut layout = Vec::new();
        for row in 1..=5 {
            for col in 1..=5 {
                let spot_id = format!("spot_{}_{}", row, col);
                layout.push((spot_id, false, row, col));
            }
        }

        let spots = generate_grid_coordinates(center, rotation, spot_pitch, &layout);

        // Create a map for quick lookup
        let mut spot_map: HashMap<(i32, i32), &Spot> = HashMap::new();
        for spot in &spots {
            spot_map.insert((spot.row as i32, spot.col as i32), spot);
        }

        // Check horizontal spacing (same row, adjacent columns)
        // With rounding, spacing will be spot_pitch.round() (21 or 22 for pitch=21.5)
        for row in 1..=5 {
            for col in 1..4 {
                if let (Some(spot1), Some(spot2)) = (
                    spot_map.get(&(row, col)),
                    spot_map.get(&(row, col + 1))
                ) {
                    let dy = spot2.grid_y - spot1.grid_y;
                    // With rounding, spacing should be close to spot_pitch (within 1px)
                    assert!((dy - spot_pitch).abs() < 1.0,
                        "Horizontal spacing at row={} between col {} and {} is {:.2}, expected ~{:.2}",
                        row, col, col+1, dy, spot_pitch);
                }
            }
        }

        // Check vertical spacing (same column, adjacent rows)
        // With rounding, spacing will be spot_pitch.round() (21 or 22 for pitch=21.5)
        for col in 1..=5 {
            for row in 1..4 {
                if let (Some(spot1), Some(spot2)) = (
                    spot_map.get(&(row, col)),
                    spot_map.get(&(row + 1, col))
                ) {
                    let dx = spot2.grid_x - spot1.grid_x;
                    // With rounding, spacing should be close to spot_pitch (within 1px)
                    assert!((dx - spot_pitch).abs() < 1.0,
                        "Vertical spacing at col={} between row {} and {} is {:.2}, expected ~{:.2}",
                        col, row, row+1, dx, spot_pitch);
                }
            }
        }
    }

    /// Test that rounding is consistent across the grid
    #[test]
    fn test_consistent_rounding() {
        let center = (200.0, 200.0);
        let rotation = 0.0;
        let spot_pitch = 21.5;

        let mut layout = Vec::new();
        for row in 1..=5 {
            for col in 1..=5 {
                let spot_id = format!("spot_{}_{}", row, col);
                layout.push((spot_id, false, row, col));
            }
        }

        let spots = generate_grid_coordinates(center, rotation, spot_pitch, &layout);

        // Check that fractional parts follow a consistent pattern
        // With pitch = 21.5, spots should alternate between .0 and .5 fractional parts
        for spot in &spots {
            let frac_x = spot.grid_x.fract().abs();
            let frac_y = spot.grid_y.fract().abs();

            // Each coordinate should be either near .0 or near .5
            let x_near_half = (frac_x - 0.5).abs() < 0.01;
            let x_near_zero = frac_x < 0.01 || frac_x > 0.99;

            let y_near_half = (frac_y - 0.5).abs() < 0.01;
            let y_near_zero = frac_y < 0.01 || frac_y > 0.99;

            assert!(x_near_half || x_near_zero,
                "Spot row={}, col={} has unexpected X fractional part: {:.3}",
                spot.row, spot.col, frac_x);
            assert!(y_near_half || y_near_zero,
                "Spot row={}, col={} has unexpected Y fractional part: {:.3}",
                spot.row, spot.col, frac_y);
        }
    }

    /// Test with real P92 dataset parameters
    #[test]
    fn test_p92_grid_parameters() {
        // Real parameters from P92 dataset
        let center = (246.95, 293.45); // Approximate from test data
        let rotation = 0.0;
        let spot_pitch = 21.5;

        // Create 12x12 grid like P92
        let mut layout = Vec::new();
        for row in 1..=12 {
            for col in 1..=12 {
                let spot_id = format!("spot_{}_{}", row, col);
                layout.push((spot_id, false, row, col));
            }
        }

        let spots = generate_grid_coordinates(center, rotation, spot_pitch, &layout);

        assert_eq!(spots.len(), 144, "Should generate 144 spots for 12x12 grid");

        // Check that we don't have the diagonal bias
        // Group by diagonal and check variance
        let mut diagonal_coords: HashMap<i32, Vec<(f64, f64)>> = HashMap::new();
        for spot in &spots {
            let diagonal = spot.row as i32 + spot.col as i32;
            diagonal_coords.entry(diagonal)
                .or_insert_with(Vec::new)
                .push((spot.grid_x, spot.grid_y));
        }

        // Calculate distance from expected position for each spot
        let mut diagonal_errors: HashMap<i32, Vec<f64>> = HashMap::new();
        for spot in &spots {
            let diagonal = spot.row as i32 + spot.col as i32;

            // Expected position
            let expected_x = center.0 + ((spot.row - 1) as f64) * spot_pitch;
            let expected_y = center.1 + ((spot.col - 1) as f64) * spot_pitch;

            // Error (should be consistent for all spots)
            let error_x = (spot.grid_x - expected_x).abs();
            let error_y = (spot.grid_y - expected_y).abs();
            let error = (error_x.powi(2) + error_y.powi(2)).sqrt();

            diagonal_errors.entry(diagonal)
                .or_insert_with(Vec::new)
                .push(error);
        }

        // Check that error is consistent across diagonals
        let mut odd_errors = Vec::new();
        let mut even_errors = Vec::new();

        for (diagonal, errors) in &diagonal_errors {
            let avg_error = errors.iter().sum::<f64>() / errors.len() as f64;
            if diagonal % 2 == 1 {
                odd_errors.push(avg_error);
            } else {
                even_errors.push(avg_error);
            }
        }

        if !odd_errors.is_empty() && !even_errors.is_empty() {
            let odd_mean = odd_errors.iter().sum::<f64>() / odd_errors.len() as f64;
            let even_mean = even_errors.iter().sum::<f64>() / even_errors.len() as f64;

            // Errors should be similar for odd and even diagonals
            let diff = (odd_mean - even_mean).abs();
            assert!(diff < 0.5,
                "P92 grid shows diagonal bias: odd diagonals error={:.3}, even diagonals error={:.3}, diff={:.3}",
                odd_mean, even_mean, diff);
        }
    }
}
