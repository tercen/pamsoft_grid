# Compiling MATLAB Code for PAMsoft Grid

This guide explains how to compile the MATLAB code into standalone executables that can run with MATLAB Runtime (MCR) instead of requiring a full MATLAB installation.

## Overview

The PAMsoft Grid operator uses MATLAB for image processing algorithms. To deploy it:
1. Compile MATLAB `.m` files to standalone executables
2. Package with MATLAB Runtime (MCR)
3. Deploy in Docker container

## Prerequisites

### Required Software
- **MATLAB R2020b** (or compatible version)
- **MATLAB Compiler** toolbox
- **Image Processing Toolbox**
- **Statistics and Machine Learning Toolbox**
- **Docker** (for containerization)

### Required Files
```
pamsoft_grid/
├── main/
│   ├── pamsoft_grid.m          # Original single-image processor
│   └── pamsoft_grid_batch.m    # NEW: Batch processor with parfor
├── grid/                        # Grid detection algorithms
├── io/                          # Input/output functions
├── quantification/              # Spot segmentation
├── util/                        # Utility functions
└── docker/
    ├── build.m                  # Compile script (original)
    └── build_batch.m            # NEW: Compile script for batch version
```

## Compilation Methods

### Method 1: Using MATLAB Docker Container (Recommended)

This is the cleanest method - uses a Docker container with MATLAB already installed.

#### Step 1: Prepare MATLAB Docker Image

```bash
# Start MATLAB container with VNC (for GUI-based addon installation)
docker run -it -d --name matlab \
  -p 5901:5901 -p 6080:6080 \
  --shm-size=512M \
  mathworks/matlab:r2020b -vnc

# Access at http://localhost:6080 (password: matlab)
# Login with MathWorks credentials
# Install required addons:
#   - MATLAB Compiler
#   - Image Processing Toolbox
#   - Statistics and Machine Learning Toolbox

# Commit the container with addons
docker commit matlab tercen/matlab:r2020b-4

# Stop and remove the container
docker rm -f matlab
```

#### Step 2: Compile Original Version

```bash
# From pamsoft_grid directory
docker run -it --rm \
  -v $PWD/docker/startup.m:/opt/matlab/R2020b/toolbox/local/startup.m \
  -v $PWD/grid:/pamsoft_grid/grid \
  -v $PWD/io:/pamsoft_grid/io \
  -v $PWD/util:/pamsoft_grid/util \
  -v $PWD/standalone:/pamsoft_grid/standalone \
  -v $PWD/quantification:/pamsoft_grid/quantification \
  -v $PWD/main:/pamsoft_grid/main \
  -v $PWD/docker:/pamsoft_grid/docker \
  --entrypoint=/bin/bash \
  -w /pamsoft_grid/docker \
  tercen/matlab:r2020b-4 \
  -i -c "matlab -batch build"

# Output: standalone/pamsoft_grid and standalone/run_pamsoft_grid.sh
```

#### Step 3: Compile Batch Version (NEW)

```bash
# Compile batch processor with parfor support
docker run -it --rm \
  -v $PWD:/pamsoft_grid \
  -v $PWD/docker/startup.m:/opt/matlab/R2020b/toolbox/local/startup.m \
  --entrypoint=/bin/bash \
  -w /pamsoft_grid/docker \
  tercen/matlab:r2020b-4 \
  -i -c "matlab -batch build_batch"

# Output: standalone/pamsoft_grid_batch and standalone/run_pamsoft_grid_batch.sh
```

#### Step 4: Verify Compilation

```bash
# Check that executables were created
ls -lh standalone/
# Should see:
# - pamsoft_grid          (original)
# - run_pamsoft_grid.sh   (original wrapper)
# - pamsoft_grid_batch    (NEW: batch version)
# - run_pamsoft_grid_batch.sh  (NEW: batch wrapper)
```

### Method 2: Using Local MATLAB Installation

If you have MATLAB installed locally:

#### Step 1: Start MATLAB

```bash
# Navigate to pamsoft_grid directory
cd /path/to/pamsoft_grid

# Start MATLAB
matlab
```

#### Step 2: Run Compilation Script

```matlab
% In MATLAB console

% Add paths
addpath(genpath('grid/'));
addpath(genpath('io/'));
addpath(genpath('util/'));
addpath(genpath('quantification/'));
addpath(genpath('main/'));

% Compile original version
run('docker/build.m')

% Compile batch version (NEW)
run('docker/build_batch.m')
```

#### Step 3: Check Output

```bash
# Exit MATLAB and check
ls -lh standalone/
```

### Method 3: Manual Compilation

For full control:

```matlab
% In MATLAB console

% Set paths
addpath(genpath('grid/'));
addpath(genpath('io/'));
addpath(genpath('util/'));
addpath(genpath('quantification/'));

% Compile original single-image version
mcc -m main/pamsoft_grid.m \
    -d standalone \
    -o pamsoft_grid \
    -R -nodisplay

% Compile batch version with parfor
mcc -m main/pamsoft_grid_batch.m \
    -d standalone \
    -o pamsoft_grid_batch \
    -R -nodisplay

% Clean up artifacts
delete('standalone/mccExcludedFiles.log');
delete('standalone/readme.txt');
delete('standalone/requiredMCRProducts.txt');
```

## Compilation Scripts

### docker/build.m (Original)
```matlab
% Compile original pamsoft_grid.m
addpath(genpath('/pamsoft_grid/grid/'));
addpath(genpath('/pamsoft_grid/io/'));
addpath(genpath('/pamsoft_grid/util/'));
addpath(genpath('/pamsoft_grid/quantification'));

res = compiler.build.standaloneApplication(
    '/pamsoft_grid/main/pamsoft_grid.m', ...
    'TreatInputsAsNumeric', false,...
    'OutputDir', '/pamsoft_grid/standalone'
);

% Cleanup
delete('/pamsoft_grid/standalone/mccExcludedFiles.log');
delete('/pamsoft_grid/standalone/readme.txt');
delete('/pamsoft_grid/standalone/requiredMCRProducts.txt');
```

### docker/build_batch.m (NEW - Batch Version)
```matlab
% Compile pamsoft_grid_batch.m with parfor support
fprintf('Compiling pamsoft_grid_batch v2.0.0...\n');

% Add paths
addpath(genpath('/pamsoft_grid/grid/'));
addpath(genpath('/pamsoft_grid/io/'));
addpath(genpath('/pamsoft_grid/util/'));
addpath(genpath('/pamsoft_grid/quantification'));
addpath(genpath('/pamsoft_grid/main'));

% Build standalone application
res = compiler.build.standaloneApplication(
    '/pamsoft_grid/main/pamsoft_grid_batch.m', ...
    'TreatInputsAsNumeric', false,...
    'OutputDir', '/pamsoft_grid/standalone'
);

if res.Summary.Passed
    fprintf('Compilation successful!\n');

    % Clean up
    delete('/pamsoft_grid/standalone/mccExcludedFiles.log');
    delete('/pamsoft_grid/standalone/readme.txt');
    delete('/pamsoft_grid/standalone/requiredMCRProducts.txt');

    fprintf('Executable: standalone/pamsoft_grid_batch\n');
    fprintf('Run script: standalone/run_pamsoft_grid_batch.sh\n');
else
    error('Compilation failed!');
end
```

## Output Files

### Original Version
```
standalone/
├── pamsoft_grid              # Compiled executable
├── run_pamsoft_grid.sh       # Wrapper script (sets MCR paths)
└── [other support files]
```

### Batch Version (NEW)
```
standalone/
├── pamsoft_grid_batch        # Compiled executable (with parfor)
├── run_pamsoft_grid_batch.sh # Wrapper script
└── [other support files]
```

## Testing Compiled Executables

### Test with MCR Docker Container

```bash
# Build base image with MCR
docker build -t tercen/pamsoft_grid:2.0.0 .

# Test original version
docker run --rm \
  -v $PWD/test:/test \
  tercen/pamsoft_grid:2.0.0 \
  /mcr/exe/run_pamsoft_grid.sh \
  /opt/mcr/v99 \
  --param-file=/test/input/input_params.json

# Test batch version (NEW)
docker run --rm \
  -v $PWD/test:/test \
  tercen/pamsoft_grid:2.0.0 \
  /mcr/exe/run_pamsoft_grid_batch.sh \
  /opt/mcr/v99 \
  --param-file=/test/input/input_params_batch.json
```

### Expected Output

Original version:
```
Running PG version: 1.0.26
Processing single image group...
Output written to: /test/output/output_grid.txt
```

Batch version:
```
Running PG Batch version: 2.0.0
Processing 2 image groups with 2 workers...
Worker processing group 1...
Group 1 completed successfully
Worker processing group 2...
Group 2 completed successfully
Results written to: /tmp/batch_results.csv
Batch processing completed successfully
```

## Troubleshooting

### Issue: Compilation fails with "License error"
```
Solution: Ensure MATLAB license is valid and Compiler toolbox is installed
Check: matlab.internal.licensing.getLicenseInfo()
```

### Issue: "Cannot find toolbox"
```
Solution: Install required toolboxes
- MATLAB Compiler
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox

In MATLAB: Home -> Add-Ons -> Get Add-Ons
Or use: addon.install('Image Processing Toolbox')
```

### Issue: Compiled executable doesn't run
```bash
# Check MCR version matches
ls -l /opt/mcr/
# Should show v99 for R2020b

# Check wrapper script
cat standalone/run_pamsoft_grid_batch.sh
# Should reference correct MCR path

# Run with debug
./standalone/run_pamsoft_grid_batch.sh /opt/mcr/v99 --param-file=test.json
```

### Issue: parfor not working in batch version
```
Solution: Ensure Parallel Computing Toolbox is included
Check: ver parallel
If missing, the code will still work but run sequentially
```

### Issue: "Function not found" error
```
Solution: Check all required functions are in included paths
Verify: All directories added with addpath(genpath(...))

Missing paths:
addpath(genpath('/pamsoft_grid/grid/'));
addpath(genpath('/pamsoft_grid/io/'));
addpath(genpath('/pamsoft_grid/util/'));
addpath(genpath('/pamsoft_grid/quantification/'));
```

## MATLAB Runtime (MCR)

### What is MCR?
MATLAB Runtime is a free, standalone set of libraries that enables running compiled MATLAB applications without a MATLAB license.

### MCR Version Compatibility
| MATLAB Version | MCR Version | Release |
|----------------|-------------|---------|
| R2020b | v99 | 9.9 |
| R2021a | v910 | 9.10 |
| R2021b | v911 | 9.11 |

**Important**: Compile with R2020b → Requires MCR v99

### MCR Installation in Docker
The MCR is installed in the base Dockerfile:
```dockerfile
# See pamsoft_grid/Dockerfile
# MCR is installed to /opt/mcr/v99
```

## Build Performance

| Method | Time | Requirements |
|--------|------|--------------|
| Docker compilation | ~5-10 min | MATLAB Docker image |
| Local MATLAB | ~3-5 min | MATLAB license |
| Manual mcc | ~3-5 min | MATLAB license |

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Compile MATLAB

on: [push]

jobs:
  compile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Pull MATLAB Docker
        run: docker pull tercen/matlab:r2020b-4

      - name: Compile MATLAB Batch Processor
        run: |
          cd pamsoft_grid
          docker run --rm \
            -v $PWD:/pamsoft_grid \
            tercen/matlab:r2020b-4 \
            -i -c "matlab -batch build_batch"

      - name: Build Base Image
        run: |
          cd pamsoft_grid
          docker build -t tercen/pamsoft_grid:${{ github.sha }} .

      - name: Test Compilation
        run: |
          ls -lh pamsoft_grid/standalone/pamsoft_grid_batch
```

## Next Steps

After successful compilation:

1. **Build base Docker image**
   ```bash
   cd pamsoft_grid
   docker build -t tercen/pamsoft_grid:2.0.0 .
   ```

2. **Build operator images**
   ```bash
   cd ..
   docker build -f Dockerfile_python -t operator:python .
   docker build -f Dockerfile_refactored_v2 -t operator:r .
   ```

3. **Test end-to-end**
   ```bash
   docker run --rm -v $PWD/test:/test operator:python
   ```

## Summary

**Quick Compilation (Docker Method):**
```bash
# One-time: Create MATLAB image with toolboxes
docker run -d --name matlab -p 6080:6080 mathworks/matlab:r2020b -vnc
# Install toolboxes via http://localhost:6080
docker commit matlab tercen/matlab:r2020b-4
docker rm -f matlab

# Compile original
docker run --rm -v $PWD:/pamsoft_grid tercen/matlab:r2020b-4 \
  matlab -batch "cd /pamsoft_grid/docker; build"

# Compile batch version
docker run --rm -v $PWD:/pamsoft_grid tercen/matlab:r2020b-4 \
  matlab -batch "cd /pamsoft_grid/docker; build_batch"

# Verify
ls -lh standalone/pamsoft_grid_batch
```

**Output**: Standalone executables ready for deployment with MCR.
