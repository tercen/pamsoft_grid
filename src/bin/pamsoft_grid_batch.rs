use anyhow::Result;
use clap::Parser;
use pamsoft_grid::batch::{process_batch, write_results_csv};
use pamsoft_grid::io::load_batch_config;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

#[derive(Parser, Debug)]
#[command(name = "pamsoft_grid_batch")]
#[command(version = "2.0.0")]
#[command(about = "PamSoft Grid Batch Processor", long_about = None)]
struct Args {
    /// Path to batch configuration JSON file
    #[arg(long = "param-file")]
    param_file: String,
}

fn main() -> Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(EnvFilter::from_default_env().add_directive(tracing::Level::INFO.into()))
        .init();

    tracing::info!("PamSoft Grid Batch Processor v{}", pamsoft_grid::VERSION);

    // Parse command line arguments
    let args = Args::parse();

    tracing::info!("Loading batch configuration from: {}", args.param_file);

    // Load configuration
    let config = load_batch_config(&args.param_file)?;

    tracing::info!(
        "Batch configuration loaded: {} groups, {} workers",
        config.image_groups.len(),
        config.num_workers
    );

    // Process batch
    let results = process_batch(config.clone())?;

    tracing::info!("Writing {} results to: {}", results.len(), config.output_file);

    // Write results
    write_results_csv(&results, &config.output_file)?;

    tracing::info!("Batch processing completed successfully");

    Ok(())
}
