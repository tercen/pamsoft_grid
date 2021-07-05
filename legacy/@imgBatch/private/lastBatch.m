function stBatch = lastBatch(b, ResList)
%
% Select the last image from eaxh directory and use for gridding

if ~isempty(b.ppObj)
    lpp = 1;
else
    lpp = 0;
end

if b.adjustSpots
    strAdjustSpots = 'true';
else
    strAdjustSpots = 'false';
end

nEntry = 0;
clUnW = getUniqueID(ResList, 'W');
[clWList{1:length(ResList)}] = deal(ResList.W);

% create list cResult of matching WFT and find the last cycle image
for w=1:length(clUnW)
    % loop over wells
    iW = strmatch(clUnW{w}, clWList);
    cResult = ResList(iW);
    clUnF    = getUniqueID(cResult, 'F');
    [clFList{1:length(cResult)}]  = deal(cResult.F);
    for f=1:length(clUnF)
        % loop over filters
        iF = strmatch(clUnF{f}, clFList);
        length(cResult);
        cResult = cResult(iF);
        clUnT = getUniqueID(cResult, 'T');
        [clTList{1:length(cResult)}] = deal(cResult.T);
        for t=1:length(clUnT)
            %loop over exposure times
            iT = strmatch(clUnT{t}, clTList);
            
            % this is the list with unique WFT:
            cResult = cResult(iT);

            % identify the highest pumpnumber.
            [clPump{1:length(cResult)}] = deal(cResult.P);
            for p =1:length(clPump)
                pump = char(clPump{p});
                pump = str2num(pump(2:end));
            end
            [mx, iGridImage] = max(pump);
            
            
            if lpp
                bName      = fnRemoveExtension(cResult(iGridImage).fName);
                sGridImage =  [cResult(iGridImage).fPath,'\GridImage',bName,'.tif'];
            else
                sGridImage = [cResult(iGridImage).fPath, '\', cResult(iGridImage).fName];
            end

            nEntry = nEntry + 1;
            % entry for the grid image
            stBatch(nEntry).Image            = sGridImage;
            stBatch(nEntry).Template         = b.pathTemplate;
            stBatch(nEntry).Configuration    = b.pathConfiguration;
            stBatch(nEntry).Destination      = cResult(iGridImage).fPath;
            stBatch(nEntry).Channel          = b.nChannel;
            stBatch(nEntry).ChannelName      = b.channelName;
            stBatch(nEntry).SubstituteGridImage = 'null';
            stBatch(nEntry).SubstituteGridChannel = b.nChannel;
            stBatch(nEntry).AdjustGrid = 'true';
            stBatch(nEntry).AdjustSpots = 'true';
            stBatch(nEntry).isGridImage = 1;
            stBatch(nEntry).gridImageInfo = cResult(iGridImage);
            % srcImages
            for j =1:length(cResult)
                nEntry = nEntry+1;
                stBatch(nEntry).Image            = [cResult(j).fPath, '\', cResult(j).fName];
                stBatch(nEntry).Template         = b.pathTemplate;
                stBatch(nEntry).Configuration    = b.pathConfiguration;
                stBatch(nEntry).Destination      = cResult(j).fPath;
                stBatch(nEntry).Channel          = b.nChannel;
                stBatch(nEntry).ChannelName      = b.channelName;
                stBatch(nEntry).SubstituteGridImage = sGridImage;
                stBatch(nEntry).SubstituteGridChannel = b.nChannel;
                stBatch(nEntry).AdjustGrid = 'false';
                stBatch(nEntry).AdjustSpots = strAdjustSpots;
                stBatch(nEntry).isGridImage = 0;
                stBatch(nEntry).gridImageInfo = [];
            end

            clear clPump
        end
        clear clTList
    end
    clear clFList
end

