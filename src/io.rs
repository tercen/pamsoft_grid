use crate::error::{Error, Result};
use crate::types::{BatchConfig, ImageData, ImageType};
use image::{DynamicImage, ImageBuffer, Luma};
use ndarray::Array2;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;

/// Load a TIFF image from file
pub fn load_tiff_image<P: AsRef<Path>>(path: P) -> Result<ImageData> {
    let path = path.as_ref();
    let img = image::open(path)?;

    let gray_img = match img {
        DynamicImage::ImageLuma16(img) => img,
        _ => img.to_luma16(),
    };

    let (width, height) = gray_img.dimensions();
    let width = width as usize;
    let height = height as usize;

    // Convert to ndarray
    let mut data = Array2::<u16>::zeros((height, width));
    for (x, y, pixel) in gray_img.enumerate_pixels() {
        data[[y as usize, x as usize]] = pixel.0[0];
    }

    let name = path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .to_string();

    Ok(ImageData::new(data, name))
}

/// Load multiple TIFF images from a list of paths
pub fn load_images<P: AsRef<Path>>(paths: &[P]) -> Result<Vec<ImageData>> {
    paths.iter().map(load_tiff_image).collect()
}

/// Detect image type from dimensions
pub fn detect_image_type(image: &ImageData) -> ImageType {
    ImageType::detect(image.width, image.height)
}

/// Read array layout file
pub fn read_layout_file<P: AsRef<Path>>(path: P) -> Result<Vec<(String, bool, i32, i32)>> {
    use std::io::Read;

    let mut file = File::open(path)?;
    let mut content = Vec::new();
    file.read_to_end(&mut content)?;

    // Try to decode as UTF-8, replacing invalid sequences
    let text = String::from_utf8_lossy(&content);
    let mut layout = Vec::new();
    let mut first_line = true;

    for line in text.lines() {
        let line = line.trim();

        // Skip header row, comments, and empty lines
        if first_line || line.is_empty() || line.starts_with("Row") || line.starts_with('#') {
            first_line = false;
            continue;
        }

        // Parse layout line: Row, Col, ID (tab-separated)
        let parts: Vec<&str> = line.split('\t').map(|s| s.trim()).collect();
        if parts.len() < 3 {
            continue;
        }

        // Try to parse row and col
        let row_result = parts[0].parse::<i32>();
        let col_result = parts[1].parse::<i32>();

        if row_result.is_err() || col_result.is_err() {
            continue;
        }

        let row = row_result.unwrap();
        let col = col_result.unwrap();
        let id = parts[2].to_string();

        // Check if this is a reference spot (#REF)
        let is_ref = id == "#REF" || id == "NA";

        // Keep negative indices as-is (reference spots at edges)
        layout.push((id, is_ref, row, col));
    }

    tracing::info!("Loaded {} spots from layout file ({} references)",
        layout.len(),
        layout.iter().filter(|(_, is_ref, _, _)| *is_ref).count()
    );

    Ok(layout)
}

/// Load batch configuration from JSON file
pub fn load_batch_config<P: AsRef<Path>>(path: P) -> Result<BatchConfig> {
    let file = File::open(path)?;
    let config: BatchConfig = serde_json::from_reader(file)?;
    Ok(config)
}

/// Write progress to file
pub fn write_progress<P: AsRef<Path>>(
    path: P,
    current: usize,
    total: usize,
    message: &str,
) -> Result<()> {
    use std::io::Write;
    let mut file = File::create(path)?;
    writeln!(file, "{}/{}: {}", current, total, message)?;
    Ok(())
}

/// Convert ImageData to image crate format for saving
pub fn to_image_buffer(data: &ImageData) -> ImageBuffer<Luma<u16>, Vec<u16>> {
    let mut img = ImageBuffer::new(data.width as u32, data.height as u32);

    for (x, y, pixel) in img.enumerate_pixels_mut() {
        *pixel = Luma([data.data[[y as usize, x as usize]]]);
    }

    img
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_image_type_detection() {
        assert_eq!(ImageType::detect(552, 413), ImageType::Evolve3);
        assert_eq!(ImageType::detect(697, 520), ImageType::Evolve2);
        assert_eq!(ImageType::detect(100, 100), ImageType::Unknown);
    }

    #[test]
    fn test_spot_pitch_defaults() {
        assert_eq!(ImageType::Evolve3.default_spot_pitch(), Some(17.0));
        assert_eq!(ImageType::Evolve2.default_spot_pitch(), Some(21.5));
        assert_eq!(ImageType::Unknown.default_spot_pitch(), None);
    }
}
