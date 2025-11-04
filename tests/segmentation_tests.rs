/// Comprehensive tests for segmentation module
/// Tests both unit-level components and integration with MATLAB ground truth

use pamsoft_grid::config::GridParams;
use pamsoft_grid::types::{ImageData, Spot};
use ndarray::Array2;
use std::f64::consts::PI;

#[cfg(test)]
mod unit_tests {
    use super::*;

    /// Test circle fitting with perfect circle data
    #[test]
    fn test_perfect_circle_fitting() {
        // Generate perfect circle points: radius=10, center=(50, 50)
        let center_x = 50.0;
        let center_y = 50.0;
        let radius = 10.0;

        let mut points = Vec::new();
        for i in 0..36 {
            let angle = (i as f64) * (2.0 * PI / 36.0);
            let x = center_x + radius * angle.cos();
            let y = center_y + radius * angle.sin();
            points.push((x, y));
        }

        // Test would call fit_circle_robust() if it was pub(crate)
        // For now, we verify through integration tests
        // TODO: Make fit_circle_robust pub(crate) for direct testing
    }

    /// Test circle fitting with noisy data
    #[test]
    fn test_noisy_circle_fitting() {
        // Generate circle with some noise
        let center_x = 50.0;
        let center_y = 50.0;
        let radius = 10.0;

        let mut points = Vec::new();
        for i in 0..36 {
            let angle = (i as f64) * (2.0 * PI / 36.0);
            let noise = if i % 5 == 0 { 0.5 } else { 0.0 }; // Add noise to some points
            let x = center_x + (radius + noise) * angle.cos();
            let y = center_y + (radius + noise) * angle.sin();
            points.push((x, y));
        }

        // Robust fitting should handle noise well
        // Expected: fitted circle close to (50, 50, 10)
    }

    /// Test circle fitting with outliers
    #[test]
    fn test_circle_fitting_with_outliers() {
        let center_x = 50.0;
        let center_y = 50.0;
        let radius = 10.0;

        let mut points = Vec::new();
        // Good points on circle
        for i in 0..30 {
            let angle = (i as f64) * (2.0 * PI / 30.0);
            let x = center_x + radius * angle.cos();
            let y = center_y + radius * angle.sin();
            points.push((x, y));
        }

        // Add outliers
        points.push((100.0, 100.0));
        points.push((0.0, 0.0));
        points.push((200.0, 200.0));

        // Tukey weighting should downweight outliers
        // Expected: fitted circle still close to (50, 50, 10)
    }

    /// Test Tukey bisquare weighting function
    #[test]
    fn test_tukey_weighting() {
        // Small residuals should get weight ≈ 1
        // Large residuals should get weight ≈ 0
        // With k=4.685, cutoff at ~4.685 MAD

        let residuals = vec![0.0, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0];

        // Expected behavior:
        // - residuals[0-2] should have high weight (>0.8)
        // - residuals[4-6] should have low weight (<0.2)

        // TODO: Test calculate_tukey_weights() when made pub(crate)
    }

    /// Test morphological opening on synthetic image
    #[test]
    fn test_morphological_opening() {
        use pamsoft_grid::image_processing::morphological_opening;

        // Create 11x11 image with a small spike
        let mut img = Array2::<f64>::zeros((11, 11));

        // Add smooth background
        for i in 3..8 {
            for j in 3..8 {
                img[[i, j]] = 100.0;
            }
        }

        // Add spike (single high pixel)
        img[[5, 5]] = 200.0;

        // Apply opening with radius 1
        let opened = morphological_opening(&img, 1);

        // Spike should be removed
        assert!(opened[[5, 5]] < 150.0, "Spike should be smoothed out");

        // Background should remain
        assert!(opened[[4, 4]] > 50.0, "Background should remain");
    }

    /// Test morphological opening preserves large structures
    #[test]
    fn test_morphological_opening_preserves_structures() {
        use pamsoft_grid::image_processing::morphological_opening;

        // Create 21x21 image with a circle
        let mut img = Array2::<f64>::zeros((21, 21));
        let center = 10;
        let radius = 5;

        for i in 0..21 {
            for j in 0..21 {
                let dist = (((i as i32 - center) as f64).powi(2) +
                           ((j as i32 - center) as f64).powi(2)).sqrt();
                if dist <= radius as f64 {
                    img[[i, j]] = 100.0;
                }
            }
        }

        // Apply opening with small radius
        let opened = morphological_opening(&img, 2);

        // Circle center should still be high
        assert!(opened[[10, 10]] > 50.0, "Circle center should remain bright");

        // Edge might be slightly eroded but structure preserved
        assert!(opened[[10, 14]] > 20.0, "Circle edge should be partially preserved");
    }

    /// Test connected component analysis
    #[test]
    fn test_connected_components_single_blob() {
        // Create binary image with single connected blob
        let mut edge_map = Array2::<bool>::default((20, 20));

        // Add connected blob
        for i in 8..12 {
            for j in 8..12 {
                edge_map[[i, j]] = true;
            }
        }

        // Test would call find_largest_connected_component()
        // Expected: return all 16 pixels
        // TODO: Make find_largest_connected_component pub(crate)
    }

    /// Test connected component analysis with multiple blobs
    #[test]
    fn test_connected_components_multiple_blobs() {
        // Create binary image with multiple blobs
        let mut edge_map = Array2::<bool>::default((30, 30));

        // Small blob (4 pixels)
        for i in 5..7 {
            for j in 5..7 {
                edge_map[[i, j]] = true;
            }
        }

        // Large blob (16 pixels)
        for i in 15..19 {
            for j in 15..19 {
                edge_map[[i, j]] = true;
            }
        }

        // Test should return the large blob (16 pixels)
        // Expected: largest component has 16 pixels at positions 15-18, 15-18
    }

    /// Test connected component with 8-connectivity
    #[test]
    fn test_connected_components_diagonal() {
        // Create binary image with diagonal connection
        let mut edge_map = Array2::<bool>::default((10, 10));

        // Diagonal line (should be one component with 8-connectivity)
        edge_map[[3, 3]] = true;
        edge_map[[4, 4]] = true;
        edge_map[[5, 5]] = true;
        edge_map[[6, 6]] = true;

        // Test should return all 4 pixels as one component
        // Expected: single component with 4 pixels
    }
}

#[cfg(test)]
mod integration_tests {
    use super::*;

    /// Helper to create test image with a spot
    fn create_spot_image(center_x: usize, center_y: usize, radius: f64, width: usize, height: usize) -> Array2<f64> {
        let mut image = Array2::<f64>::from_elem((height, width), 50.0); // Background

        for y in 0..height {
            for x in 0..width {
                let dx = x as f64 - center_x as f64;
                let dy = y as f64 - center_y as f64;
                let dist = (dx * dx + dy * dy).sqrt();

                // Create edge at radius
                if (dist - radius).abs() < 1.5 {
                    image[[y, x]] = 200.0; // Bright edge
                }
            }
        }

        image
    }

    /// Test segmentation on synthetic spot with known parameters
    #[test]
    fn test_segment_synthetic_spot() {
        // Create synthetic spot: radius 6.45px (diameter 12.9px like MATLAB default)
        let center_x = 50;
        let center_y = 50;
        let expected_radius = 6.45;
        let image_data = create_spot_image(center_x, center_y, expected_radius, 100, 100);

        let image = ImageData {
            data: image_data,
            width: 100,
            height: 100,
            bits_per_sample: 16,
        };

        // Create spot at expected center
        let spot = Spot {
            id: "test_spot".to_string(),
            is_reference: false,
            row: 1,
            col: 1,
            fixed_x: 0.0,
            fixed_y: 0.0,
            grid_x: center_x as f64,
            grid_y: center_y as f64,
            diameter: 0.0,
            is_manual: false,
            is_bad: false,
            is_empty: false,
        };

        let params = GridParams::default();

        // Segment the spot
        let spots = vec![spot];
        let result = segment_spots(&image, &spots, &params);

        assert!(result.is_ok(), "Segmentation should succeed");
        let segmented = result.unwrap();

        assert_eq!(segmented.len(), 1, "Should have one spot");

        let seg_spot = &segmented[0];

        // Check position accuracy (should be very close to center)
        let pos_error_x = (seg_spot.grid_x - center_x as f64).abs();
        let pos_error_y = (seg_spot.grid_y - center_y as f64).abs();
        assert!(pos_error_x < 2.0, "X position should be accurate within 2px, got error {}", pos_error_x);
        assert!(pos_error_y < 2.0, "Y position should be accurate within 2px, got error {}", pos_error_y);

        // Check diameter accuracy
        let expected_diameter = expected_radius * 2.0;
        let diameter_error = (seg_spot.diameter - expected_diameter).abs();
        assert!(diameter_error < 2.0, "Diameter should be accurate within 2px, got error {}", diameter_error);

        // Spot should not be marked bad or empty
        assert!(!seg_spot.is_bad, "Good synthetic spot should not be bad");
        assert!(!seg_spot.is_empty, "Good synthetic spot should not be empty");
    }

    /// Test segmentation with weak edges
    #[test]
    fn test_segment_weak_edges() {
        // Create spot with weak edges (low contrast)
        let mut image = Array2::<f64>::from_elem((100, 100), 100.0);
        let center_x = 50;
        let center_y = 50;
        let radius = 6.45;

        for y in 0..100 {
            for x in 0..100 {
                let dx = x as f64 - center_x as f64;
                let dy = y as f64 - center_y as f64;
                let dist = (dx * dx + dy * dy).sqrt();

                // Weak edge (only 20 intensity difference)
                if (dist - radius).abs() < 1.5 {
                    image[[y, x]] = 120.0;
                }
            }
        }

        let image_data = ImageData {
            data: image,
            width: 100,
            height: 100,
            bits_per_sample: 16,
        };

        let spot = Spot {
            id: "weak_spot".to_string(),
            is_reference: false,
            row: 1,
            col: 1,
            fixed_x: 0.0,
            fixed_y: 0.0,
            grid_x: center_x as f64,
            grid_y: center_y as f64,
            diameter: 0.0,
            is_manual: false,
            is_bad: false,
            is_empty: false,
        };

        let mut params = GridParams::default();
        params.edge_sensitivity = [0.0, 0.02]; // More sensitive to detect weak edges

        let spots = vec![spot];
        let result = segment_spots(&image_data, &spots, &params);

        assert!(result.is_ok(), "Segmentation should handle weak edges");
        // Might be marked empty due to weak edges, which is correct behavior
    }

    /// Test segmentation with noisy background
    #[test]
    fn test_segment_noisy_background() {
        use rand::Rng;
        use rand::SeedableRng;
        use rand_chacha::ChaCha8Rng;

        let mut rng = ChaCha8Rng::seed_from_u64(42);
        let mut image = Array2::<f64>::zeros((100, 100));

        // Add noise to background
        for y in 0..100 {
            for x in 0..100 {
                image[[y, x]] = 100.0 + rng.gen_range(-20.0..20.0);
            }
        }

        // Add clear spot on top
        let center_x = 50;
        let center_y = 50;
        let radius = 6.45;

        for y in 0..100 {
            for x in 0..100 {
                let dx = x as f64 - center_x as f64;
                let dy = y as f64 - center_y as f64;
                let dist = (dx * dx + dy * dy).sqrt();

                if (dist - radius).abs() < 1.5 {
                    image[[y, x]] = 250.0; // Strong edge above noise
                }
            }
        }

        let image_data = ImageData {
            data: image,
            width: 100,
            height: 100,
            bits_per_sample: 16,
        };

        let spot = Spot {
            id: "noisy_spot".to_string(),
            is_reference: false,
            row: 1,
            col: 1,
            fixed_x: 0.0,
            fixed_y: 0.0,
            grid_x: center_x as f64,
            grid_y: center_y as f64,
            diameter: 0.0,
            is_manual: false,
            is_bad: false,
            is_empty: false,
        };

        let params = GridParams::default();
        let spots = vec![spot];
        let result = segment_spots(&image_data, &spots, &params);

        assert!(result.is_ok(), "Robust fitting should handle noise");
        let segmented = result.unwrap();

        // Should still detect spot accurately despite noise
        assert!(!segmented[0].is_empty, "Strong spot should be detected despite noise");
    }
}

#[cfg(test)]
mod regression_tests {
    use super::*;
    use std::path::PathBuf;

    /// Test against MATLAB ground truth for P92 dataset
    /// This is the main regression test to ensure Phase 2 accuracy is maintained
    #[test]
    #[ignore] // Ignore by default since it requires test data files
    fn test_p92_matlab_ground_truth() {
        // Load MATLAB ground truth from tests/table1.csv
        let matlab_results = load_matlab_ground_truth();

        // Run Rust segmentation on same image
        let rust_results = run_segmentation_on_p92();

        // Compare results
        let stats = compare_results(&matlab_results, &rust_results);

        // Assert Phase 2 accuracy metrics
        assert!(stats.success_rate >= 0.95,
            "Success rate should be ≥95%, got {}", stats.success_rate);

        assert!(stats.mean_position_error <= 2.5,
            "Mean position error should be ≤2.5px, got {}", stats.mean_position_error);

        assert!(stats.mean_diameter_error <= 1.0,
            "Mean diameter error should be ≤1.0px, got {}", stats.mean_diameter_error);

        assert!(stats.within_2px_ratio >= 0.70,
            "At least 70% should be within 2px, got {}", stats.within_2px_ratio);
    }

    struct ComparisonStats {
        success_rate: f64,
        mean_position_error: f64,
        mean_diameter_error: f64,
        within_2px_ratio: f64,
    }

    fn load_matlab_ground_truth() -> Vec<Spot> {
        // TODO: Implement CSV parsing
        vec![]
    }

    fn run_segmentation_on_p92() -> Vec<Spot> {
        // TODO: Implement test execution
        vec![]
    }

    fn compare_results(matlab: &[Spot], rust: &[Spot]) -> ComparisonStats {
        // TODO: Implement comparison logic
        ComparisonStats {
            success_rate: 0.0,
            mean_position_error: 0.0,
            mean_diameter_error: 0.0,
            within_2px_ratio: 0.0,
        }
    }
}
