function sBatchFile = batchCreate(b)


sBatchFile = [];
% check inputs
if ~exist(b.pathImageResults, 'dir') 
    error(['Directory not found: ', b.pathImageResults]);
end

if ~exist(b.pathTemplate, 'file') & ~isequal(b.pathTemplate, 'null')
    error(['file not found: ', b.pathTemplate]);
end

if ~exist(b.pathConfiguration, 'file') & ~isequal(b.pathConfiguration, 'null')
    error(['file not found: ',b.pathConfiguration]);
end

msgout(b.log, ['Searching data in: ',b.pathImageResults]);
foundList = filehound(b.pathImageResults, b.imageFilter);
nFiles = length(foundList);
msgout(b.log, ['Found: ',num2str(nFiles)]);

switch b.instrument
    case 'PS96'
        instrumentID = 0;
    case 'PS4'
        instrumentID = 1;
    case 'FD10m'
        instrumentID = 2;
    case 'FD10'
        instrumentID = 3;
    otherwise
        error(['Invalid instrument identifier: ', b.Instrument]);
end




% check all names and keep only the ones with recognized format
[ResultList, clMsg] = getResultList(foundList, instrumentID);
if ~isempty(clMsg)
    for i=1:length(clMsg)
        msgout(b.log, clMsg{i});
    end
end


switch b.gridMode
    % stBatch is used to write the batchfile
    % preprocessing is used    
    case 'normal'
        stBatch = normalBatch(b,ResultList);
    case 'last'
        stBatch = lastBatch(b, ResultList);
    otherwise
        error(['Invalid value for gridMode: ',b.gridMode]);
end

% preprocessing, if defined

if ~isempty(b.ppObj)
        [isGridImage{1:length(stBatch)}] = deal(stBatch.isGridImage);
        iGrid = find(cell2mat(isGridImage));
 
        nPreProcess = length(iGrid);
        for i=1:nPreProcess
            k = iGrid(i);
            gridImageSrc = [stBatch(k).gridImageInfo.fPath, '\', stBatch(k).gridImageInfo.fName];
            msgout(b.log, ['preprocessing: ',num2str(i),'/',num2str(nPreProcess)]);
            preProcessExe(b.ppObj, gridImageSrc, stBatch(k).Image);
        end
    
    
end

sBatchFile = [b.pathImageResults,'\',b.batchID,'_batchfile.bch'];
msgout(b.log, ['Creating batch file for: ',num2str(length(stBatch)),' images']);

msg = writeBatch(sBatchFile, stBatch);
if ~isempty(msg)
    error(['Error creating: ',sBatchFile,': ', msg]);
end
