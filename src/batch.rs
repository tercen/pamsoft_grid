use crate::config::{GridParams, SegmentationMethod};
use crate::error::{Error, Result};
use crate::grid::process_gridding;
use crate::image_processing::preprocess_images;
use crate::io::{load_images, load_tiff_image, read_layout_file, write_progress};
use crate::quantification::quantify_spots;
use crate::segmentation::segment_spots;
use crate::types::{BatchConfig, GroupConfig, ImageType, SpotResult};
use rayon::prelude::*;
use std::path::Path;
use std::sync::{Arc, Mutex};

/// Process a single image group
pub fn process_single_group(config: &GroupConfig) -> Result<Vec<SpotResult>> {
    tracing::info!("Processing group: {}", config.group_id);

    // Load images
    let images = load_images(&config.images_list)?;

    if images.is_empty() {
        return Err(Error::InvalidParameter("No images in group".to_string()));
    }

    // Detect image type and set spot pitch if needed
    let image_type = ImageType::detect(images[0].width, images[0].height);
    let mut spot_pitch = config.spot_pitch;

    if spot_pitch == 0.0 {
        spot_pitch = image_type
            .default_spot_pitch()
            .ok_or_else(|| Error::InvalidConfiguration("Cannot auto-detect spot pitch".to_string()))?;
    }

    // Parse rotation range
    let rotation_range = config.rotation.clone();

    // Build parameters
    let seg_method = config
        .seg_method
        .parse::<SegmentationMethod>()
        .unwrap_or(SegmentationMethod::Edge);

    let params = GridParams {
        min_diameter: config.min_diameter,
        max_diameter: config.max_diameter,
        spot_pitch,
        spot_size: config.spot_size,
        rotation_range,
        saturation_limit: config.saturation_limit,
        segmentation_method: seg_method,
        grid_detection_method: crate::config::GridDetectionMethod::Template,
        edge_sensitivity: [
            config.edge_sensitivity[0],
            config.edge_sensitivity[1],
        ],
        array_layout_file: if config.array_layout_file.is_empty() {
            None
        } else {
            Some(config.array_layout_file.clone())
        },
        // Use MATLAB defaults for new parameters
        ..Default::default()
    };

    params.validate()?;

    // Load array layout
    let layout = if let Some(ref layout_file) = params.array_layout_file {
        read_layout_file(layout_file)?
    } else {
        return Err(Error::InvalidConfiguration(
            "Array layout file required".to_string(),
        ));
    };

    // Preprocess images
    let grid_image = preprocess_images(&images, None, &config.use_image)?;

    // Process gridding
    let mut spots = process_gridding(&[grid_image.clone()], &layout, &params)?;

    // Segment spots (re-enabled for Phase 2)
    segment_spots(&grid_image, &mut spots, &params)?;

    // Quantify spots
    let results = quantify_spots(&grid_image, &spots, &config.group_id, &params)?;

    tracing::info!(
        "Group {} completed: {} spots processed",
        config.group_id,
        results.len()
    );

    Ok(results)
}

/// Process batch configuration with parallel execution
pub fn process_batch(config: BatchConfig) -> Result<Vec<SpotResult>> {
    tracing::info!(
        "Starting batch processing: {} groups with {} workers",
        config.image_groups.len(),
        config.num_workers
    );

    // Initialize progress
    write_progress(&config.progress_file, 0, config.image_groups.len(), "Initializing")?;

    // Track progress
    let progress_counter = Arc::new(Mutex::new(0usize));
    let total_groups = config.image_groups.len();

    // Process groups in parallel
    let results: Result<Vec<Vec<SpotResult>>> = rayon::ThreadPoolBuilder::new()
        .num_threads(config.num_workers)
        .build()
        .map_err(|e| Error::ProcessingError(format!("Failed to build thread pool: {}", e)))?
        .install(|| {
            config
                .image_groups
                .par_iter()
                .map(|group_config| {
                    let result = process_single_group(group_config);

                    // Update progress
                    let mut counter = progress_counter.lock().unwrap();
                    *counter += 1;
                    let current = *counter;
                    drop(counter);

                    let _ = write_progress(
                        &config.progress_file,
                        current,
                        total_groups,
                        &format!("Processing group {}", group_config.group_id),
                    );

                    result
                })
                .collect()
        });

    let results = results?;

    // Flatten results
    let all_results: Vec<SpotResult> = results.into_iter().flatten().collect();

    tracing::info!("Batch processing completed: {} total results", all_results.len());

    write_progress(
        &config.progress_file,
        config.image_groups.len(),
        config.image_groups.len(),
        "Completed",
    )?;

    Ok(all_results)
}

/// Write results to CSV file
pub fn write_results_csv<P: AsRef<Path>>(
    results: &[SpotResult],
    output_path: P,
) -> Result<()> {
    let mut writer = csv::Writer::from_path(output_path)?;

    for result in results {
        writer.serialize(result)?;
    }

    writer.flush()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_process_batch_empty() {
        let config = BatchConfig {
            mode: "batch".to_string(),
            num_workers: 2,
            progress_file: "/tmp/progress_test.txt".to_string(),
            output_file: "/tmp/output_test.csv".to_string(),
            image_groups: vec![],
        };

        let result = process_batch(config);
        assert!(result.is_ok());
        let results = result.unwrap();
        assert_eq!(results.len(), 0);
    }
}
