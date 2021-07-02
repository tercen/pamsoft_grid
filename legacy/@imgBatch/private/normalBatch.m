function stBatch= normalBatch(b, fList)
if ~isempty(b.ppObj)
    lpp = 1;
else
    lpp = 0;
end



if ~lpp
    for i=1:length(fList)
        stBatch(i).Image            = [fList(i).fPath, '\', fList(i).fName];
        stBatch(i).Template         = b.pathTemplate;
        stBatch(i).Configuration    = b.pathConfiguration;
        stBatch(i).Destination      = fList(i).fPath;
        stBatch(i).Channel          = b.nChannel;
        stBatch(i).ChannelName      = b.channelName;
        stBatch(i).SubstituteGridImage = 'null';
        stBatch(i).SubstituteGridChannel = b.nChannel;
        stBatch(i).AdjustGrid = 'true';
        stBatch(i).AdjustSpots = 'true';
        stBatch(i).isGridImage = 0;
        stBatch(i).gridImageInfo = [];
    end
else
    for i=1:length(fList)
        j = 1 + (i-1)*2;
        bName = fnRemoveExtension(fList(i).fName);
        sGridImage = ['GridImage',bName,'.tif'];
        % gridImage       
        stBatch(j).Image            = [fList(i).fPath, '\', sGridImage];
        stBatch(j).Template         = b.pathTemplate;
        stBatch(j).Configuration    = b.pathConfiguration;
        stBatch(j).Destination      = fList(i).fPath;
        stBatch(j).Channel          = b.nChannel;
        stBatch(j).ChannelName      = b.channelName;
        stBatch(j).SubstituteGridImage = 'null';
        stBatch(j).SubstituteGridChannel = b.nChannel;
        stBatch(j).AdjustGrid = 'true';
        stBatch(j).AdjustSpots = 'true';
        stBatch(j).isGridImage = 1;
        stBatch(j).gridImageInfo = fList(i);
        
        % srcImage
        stBatch(j+1).Image            = [fList(i).fPath, '\', fList(i).fName];
        stBatch(j+1).Template         = b.pathTemplate;
        stBatch(j+1).Configuration    = b.pathConfiguration;
        stBatch(j+1).Destination      = fList(i).fPath;
        stBatch(j+1).Channel          = b.nChannel;
        stBatch(j+1).ChannelName      = b.channelName;
        stBatch(j+1).SubstituteGridImage = [fList(i).fPath, '\', sGridImage];
        stBatch(j+1).SubstituteGridChannel = b.nChannel;
        stBatch(j+1).AdjustGrid = 'false';
        stBatch(j+1).AdjustSpots = 'true';
        stBatch(j+1).isGridImage = 0;
        stBatch(j+1).gridImageSrc = [];
        
    end
end

