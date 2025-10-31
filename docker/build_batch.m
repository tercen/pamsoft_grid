% Compilation script for pamsoft_grid_batch
% Compiles MATLAB code to standalone executable with batch processing support
%
% Usage: Run from MATLAB docker container
%   matlab -batch build_batch

fprintf('Compiling pamsoft_grid_batch v2.0.0...\n');

% Add paths to required modules
addpath(genpath('/pamsoft_grid/grid/'));
addpath(genpath('/pamsoft_grid/io/'));
addpath(genpath('/pamsoft_grid/util/'));
addpath(genpath('/pamsoft_grid/quantification'));
addpath(genpath('/pamsoft_grid/main'));

% Compile batch version
fprintf('Building standalone application...\n');

res = compiler.build.standaloneApplication('/pamsoft_grid/main/pamsoft_grid_batch.m', ...
    'TreatInputsAsNumeric', false,...
    'OutputDir', '/pamsoft_grid/standalone');

if res.Summary.Passed
    fprintf('Compilation successful!\n');

    % Clean up compilation artifacts
    delete('/pamsoft_grid/standalone/mccExcludedFiles.log');
    delete('/pamsoft_grid/standalone/readme.txt');
    delete('/pamsoft_grid/standalone/requiredMCRProducts.txt');

    fprintf('Executable: /pamsoft_grid/standalone/pamsoft_grid_batch\n');
    fprintf('Run script: /pamsoft_grid/standalone/run_pamsoft_grid_batch.sh\n');
else
    error('Compilation failed!');
end
