function q = analyzeImageSeries(pgr, imFiles)
assert(iscellstr(imFiles), 'Input argument ''imFiles'' must be a cell array of string');
if isequal(pgr.verbose, 'on')
    bVerb = true;
else
    bVerb = false;
end

% load the images
for i=1:length(imFiles)
    try
        I(:,:,i) = imread(imFiles{i});
    catch
        le =  lasterror;
        error(['Error while reading ', imFiles{i}, ': ',le.message ]);
    end
end

% get the image parameters from file
[expTime, cycles]  = getImageInfo(imFiles);
if isempty(expTime)||isempty(cycles)
    warning('Could not read image parameters from file, results may be inaccurate');
end
% call the appropriate segmentation/quantification method

switch pgr.seriesMode
    case 'Fixed'
        q = seriesFixed(pgr, I, expTime, cycles);
    case 'Adapt Local'
        
    case 'Adapt Global'
        
    case 'Adapt'
end
keyboard
