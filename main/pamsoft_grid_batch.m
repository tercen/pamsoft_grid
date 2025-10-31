function pamsoft_grid_batch(arglist)
% PAMSOFT_GRID_BATCH - Batch processing version with internal parallelization
% Processes multiple image groups in parallel using MATLAB parfor
%
% Usage: pamsoft_grid_batch --param-file=/path/to/batch_config.json
%
% JSON Structure:
% {
%   "mode": "batch",
%   "numWorkers": 4,
%   "progressFile": "/tmp/progress.txt",
%   "outputFile": "/tmp/batch_results.csv",
%   "imageGroups": [
%     {
%       "groupId": "1",
%       "sqcMinDiameter": 0.45,
%       ... (all pamsoft_grid parameters)
%     }
%   ]
% }

fprintf('Running PG Batch version: %d.%d.%d\n', 2, 0, 0);

[batchParams, exitCode] = parse_arguments(arglist);

if exitCode ~= 0
    error('Program finished with code %d\n', exitCode);
end

% Read batch configuration
if exitCode == 0
    [batchParams, exitCode] = read_batch_config(batchParams.paramfile);
end

if exitCode ~= 0
    error('Program finished with code %d\n', exitCode);
end

% Initialize progress tracking
numGroups = length(batchParams.imageGroups);
progressFile = batchParams.progressFile;
write_progress(progressFile, 0, numGroups, 'Initializing batch processing');

% Setup parallel pool if needed
numWorkers = batchParams.numWorkers;
if numWorkers > 1
    poolobj = gcp('nocreate'); % Get current pool
    if isempty(poolobj)
        parpool(numWorkers);
    elseif poolobj.NumWorkers ~= numWorkers
        delete(poolobj);
        parpool(numWorkers);
    end
end

% Process groups in parallel
results = cell(numGroups, 1);
groupIds = cell(numGroups, 1);

fprintf('Processing %d image groups with %d workers...\n', numGroups, numWorkers);

parfor i = 1:numGroups
    try
        % Each worker processes one group
        groupConfig = batchParams.imageGroups{i};
        groupIds{i} = groupConfig.groupId;

        fprintf('Worker processing group %s...\n', groupConfig.groupId);

        % Process single group using existing pamsoft_grid logic
        [groupResult, groupExitCode] = process_single_group(groupConfig);

        if groupExitCode == 0
            results{i} = groupResult;
            fprintf('Group %s completed successfully\n', groupConfig.groupId);
        else
            error('Group %s failed with exit code %d', groupConfig.groupId, groupExitCode);
        end

    catch ME
        fprintf('ERROR in group %s: %s\n', groupConfig.groupId, ME.message);
        rethrow(ME);
    end
end

% Update progress
write_progress(progressFile, numGroups, numGroups, 'Aggregating results');

% Aggregate results into single CSV
if exitCode == 0
    exitCode = aggregate_results(results, groupIds, batchParams.outputFile);
end

% Final progress update
if exitCode == 0
    write_progress(progressFile, numGroups, numGroups, 'Completed successfully');
    fprintf('Batch processing completed successfully\n');
else
    write_progress(progressFile, numGroups, numGroups, sprintf('Failed with code %d', exitCode));
    error('Batch processing failed with code %d\n', exitCode);
end

end % END of function pamsoft_grid_batch


function [groupResult, exitCode] = process_single_group(groupConfig)
% Process a single image group using core pamsoft_grid logic
% Returns structured result for aggregation

exitCode = 0;

% Convert group config to params structure
params = struct();

% Copy all fields from groupConfig to params
fields = fieldnames(groupConfig);
for i = 1:length(fields)
    params.(fields{i}) = groupConfig.(fields{i});
end

% Set defaults
[params, exitCode] = pg_io_read_params_json(params, 'default');

if exitCode ~= 0
    return;
end

% Read images list
if exitCode == 0
    [params, exitCode] = pg_io_read_images_list(params);
end

% Grid mode processing
if exitCode == 0 && strcmpi(params.pgMode, 'grid')
    % Read grid layout
    [params, exitCode] = pg_grd_read_layout_file(params, '#');

    if exitCode == 0
        [params, exitCode] = pg_grd_preprocess_images(params, true, false);
    end

    if exitCode == 0
        [params, exitCode] = pg_grd_gridding(params);
    end

    if exitCode == 0
        [params, exitCode] = pg_seg_segment_image(params);
    end

    % Extract results into structure
    if exitCode == 0
        groupResult = extract_group_results(params);
    end
end

end % END of process_single_group


function groupResult = extract_group_results(params)
% Extract results from params structure into standardized format

nSpots = length(params.spots);

groupResult = struct();
groupResult.groupId = params.groupId;
groupResult.nSpots = nSpots;

% Preallocate arrays
groupResult.qntSpotID = cell(nSpots, 1);
groupResult.grdIsReference = zeros(nSpots, 1);
groupResult.grdRow = zeros(nSpots, 1);
groupResult.grdCol = zeros(nSpots, 1);
groupResult.grdXFixedPosition = zeros(nSpots, 1);
groupResult.grdYFixedPosition = zeros(nSpots, 1);
groupResult.gridX = zeros(nSpots, 1);
groupResult.gridY = zeros(nSpots, 1);
groupResult.diameter = zeros(nSpots, 1);
groupResult.isManual = zeros(nSpots, 1);
groupResult.segIsBad = zeros(nSpots, 1);
groupResult.segIsEmpty = zeros(nSpots, 1);
groupResult.grdRotation = zeros(nSpots, 1);
groupResult.grdImageNameUsed = cell(nSpots, 1);

% Populate from params
for i = 1:nSpots
    groupResult.qntSpotID{i} = params.qntSpotID{i};
    groupResult.grdIsReference(i) = params.grdIsReference(i);
    groupResult.grdRow(i) = params.grdRow(i);
    groupResult.grdCol(i) = params.grdCol(i);
    groupResult.grdXFixedPosition(i) = params.grdXFixedPosition(i);
    groupResult.grdYFixedPosition(i) = params.grdYFixedPosition(i);
    groupResult.gridX(i) = params.gridX(i);
    groupResult.gridY(i) = params.gridY(i);
    groupResult.diameter(i) = params.diameter(i);
    groupResult.isManual(i) = params.isManual(i);
    groupResult.segIsBad(i) = params.segIsBad(i);
    groupResult.segIsEmpty(i) = params.segIsEmpty(i);
    groupResult.grdRotation(i) = params.grdRotation(i);
    groupResult.grdImageNameUsed{i} = params.grdImageNameUsed;
end

end % END of extract_group_results


function exitCode = aggregate_results(results, groupIds, outputFile)
% Aggregate results from all groups into single CSV file

exitCode = 0;

try
    % Open output file
    fid = fopen(outputFile, 'w');
    if fid == -1
        exitCode = -100;
        fprintf('ERROR: Cannot open output file: %s\n', outputFile);
        return;
    end

    % Write header
    fprintf(fid, 'groupId,qntSpotID,grdIsReference,grdRow,grdCol,');
    fprintf(fid, 'grdXFixedPosition,grdYFixedPosition,gridX,gridY,');
    fprintf(fid, 'diameter,isManual,segIsBad,segIsEmpty,grdRotation,grdImageNameUsed\n');

    % Write data from each group
    for g = 1:length(results)
        if isempty(results{g})
            continue;
        end

        groupResult = results{g};
        groupId = groupIds{g};

        for i = 1:groupResult.nSpots
            fprintf(fid, '%s,%s,%d,%f,%f,', ...
                groupId, groupResult.qntSpotID{i}, ...
                groupResult.grdIsReference(i), ...
                groupResult.grdRow(i), groupResult.grdCol(i));

            fprintf(fid, '%f,%f,%f,%f,', ...
                groupResult.grdXFixedPosition(i), groupResult.grdYFixedPosition(i), ...
                groupResult.gridX(i), groupResult.gridY(i));

            fprintf(fid, '%f,%d,%d,%d,%f,%s\n', ...
                groupResult.diameter(i), groupResult.isManual(i), ...
                groupResult.segIsBad(i), groupResult.segIsEmpty(i), ...
                groupResult.grdRotation(i), groupResult.grdImageNameUsed{i});
        end
    end

    fclose(fid);
    fprintf('Results written to: %s\n', outputFile);

catch ME
    exitCode = -101;
    fprintf('ERROR aggregating results: %s\n', ME.message);
    if fid ~= -1
        fclose(fid);
    end
end

end % END of aggregate_results


function [batchParams, exitCode] = read_batch_config(jsonFile)
% Read batch configuration JSON file

exitCode = 0;
batchParams = struct();

if ~exist(jsonFile, 'file')
    exitCode = -1;
    fprintf('ERROR: Batch config file not found: %s\n', jsonFile);
    return;
end

try
    % Read JSON file
    fid = fopen(jsonFile);
    raw = fread(fid, inf);
    str = char(raw');
    fclose(fid);

    % Parse JSON
    config = jsondecode(str);

    % Extract batch-level parameters
    batchParams.numWorkers = config.numWorkers;
    batchParams.progressFile = config.progressFile;
    batchParams.outputFile = config.outputFile;
    batchParams.imageGroups = config.imageGroups;

    % Convert imageGroups to cell array if needed
    if isstruct(batchParams.imageGroups)
        tmp = batchParams.imageGroups;
        batchParams.imageGroups = cell(length(tmp), 1);
        for i = 1:length(tmp)
            batchParams.imageGroups{i} = tmp(i);
        end
    end

    fprintf('Loaded batch config: %d groups, %d workers\n', ...
        length(batchParams.imageGroups), batchParams.numWorkers);

catch ME
    exitCode = -2;
    fprintf('ERROR parsing batch config: %s\n', ME.message);
end

end % END of read_batch_config


function write_progress(progressFile, actual, total, message)
% Write progress to file for external monitoring

try
    fid = fopen(progressFile, 'w');
    if fid ~= -1
        fprintf(fid, '%d/%d: %s\n', actual, total, message);
        fclose(fid);
    end
catch
    % Silently fail - progress reporting is not critical
end

end % END of write_progress


function [params, exitCode] = parse_arguments(argline)
% Parse command line arguments

exitCode = 0;
params = struct;

if isempty(argline)
    exitCode = -1000;
    fprintf('ERROR: No arguments provided. Usage: --param-file=<json>\n');
    return
end

argStrIdx = strfind(argline, '--');
argStrValid = regexp(argline, '--param-file=.+', 'ONCE');

if isempty(argStrValid)
    exitCode = -1000;
    fprintf('ERROR: --param-file argument required\n');
    return
end

nArgs = length(argStrIdx);

for i = 1:nArgs-1
    arg = argline(argStrIdx(i)+2:argStrIdx(i+1)-1);
    arg = strrep(arg, '-', '');

    if contains(arg, '=')
        [argName, argVal] = strtok(arg, '=');
    else
        [argName, argVal] = strtok(arg, ' ');
    end

    params.(argName) = strtrim(argVal(2:end));
end

arg = argline(argStrIdx(end)+2:end);
arg = strrep(arg, '-', '');

if contains(arg, '=')
    [argName, argVal] = strtok(arg, '=');
else
    [argName, argVal] = strtok(arg, ' ');
end

params.(argName) = strtrim(argVal(2:end));

end % END of parse_arguments
