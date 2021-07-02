function outSeg = segmentByThreshold(oS, I, cx, cy, rotation)
[nRows, nCols] = size(cx);
spotPitch = oS.spotPitch


% then the left upper coordinates and right lower coordinates
xLu = round(cx - spotPitch-1);
yLu = round(cy - spotPitch-1);
xRl = round(cx + spotPitch+1);
yRl = round(cy + spotPitch+1);
% make sure these are in the image
xLu(xLu<1) = 1;
yLu(yLu<1) = 1;
xRl(xRl > size(I,1)) = size(I,1);
yRl(yRl > size(I,2)) = size(I,2);

% select the part of the image that contains the grid for filtering
If = I(xLu(1,1):xRl(end,end), yLu(1,1):yRl(end,end));

% apply morphological filtering if required.
if oS.nFilterDisk >= 1
    se = strel('disk', round(oS.nFilterDisk/2));
    If  = imerode(If, se);
    If  = imdilate(If, se);    
end
I(xLu(1,1):xRl(end,end), yLu(1,1):yRl(end,end)) = If;
% Get full scale factor, necessary for auto thresholding
if isequal(class(I), 'uint8')
    bitRange = 255;
elseif isequal(class(I), 'uint16');
    bitRange = 65535;
else
    bitRange = 1;
end

% apply local thresholding
pixAreaSize = oS.areaSize * spotPitch;
pixOff = round(max(spotPitch -0.5*pixAreaSize,0));
spotPitch = round(spotPitch);


for i  = 1:nRows
    for j = 1:nCols
        
       
        % store the results in nRows, nCols array of segmentation objects
        outSeg(i,j) = oS;
        outSeg(i,j).mp0 = [cx(i,j), cy(i,j)];
        Ilocal = I(xLu(i,j):xLu(i,j) + 2*spotPitch,yLu(i,j):yLu(i,j) + 2*spotPitch);
        % center in the local image to find the threshold level. 
        Iinitial = Ilocal(pixOff:end-pixOff, pixOff:end-pixOff);
        mFull = bitRange/max(Iinitial(:));
        Iinitial = Iinitial * mFull;
        [thr, eff] = graythresh(Iinitial);
        % apply threshold to the full local image
        bw  = im2bw(mFull * Ilocal, thr);
        %retain the object that is closest to the area midpoint
        L = bwlabel(bw);
        nObjects = max(L(:));
      
        mp = zeros(nObjects,2);
        delta = zeros(nObjects,1);
        objectArea = zeros(nObjects,1);
        
        for m=1:nObjects
            [a,b] = find(L == m);
            mp(m,:) = [mean(a), mean(b)];
            area_mp = size(Ilocal)/2;
            delta(m) = norm(mp(m,:) - area_mp);
            objectArea(m) = length(a);
        end
        mdelta = min(delta);
        mClose = find(mdelta == delta);
        % if more than 1 minimal distance, get the largets object:
        objectArea = objectArea(mClose);
        [mxval, iMax] = max(objectArea);
        mClose = mClose(iMax);
        
        outSeg(i,j).bsSize = size(Ilocal);
        outSeg(i,j).bsTrue = uint16(find((L == mClose)));
        outSeg(i,j).methodOutput.thrEff = eff;
        outSeg(i,j).methodOutput.spotMidpoint = mp(mClose,:);
        outSeg(i,j).cLu = [xLu(i,j), yLu(i,j)];
   
    end
end




