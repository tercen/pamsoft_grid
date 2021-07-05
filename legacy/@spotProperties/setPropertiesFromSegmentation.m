function spOut = setPropertiesFromSegmentation(sp, oS)
[nRows, nCols] = size(oS);

segMethod = get(oS(1), 'method');
switch segMethod
    case 'Edge'
        % just copy properties from segmentation.methodOutput 
         spOut = cpSeg2spOut(sp,oS);        
    otherwise
            % get properties from segmentation.binSpot
            
            % The matlab regionprops function has a large performance
            % overhead.
            % Therefore: combine all binary spots into a single label
            % matrix, and call regionprops only 1 time.
            [L, rcIndex] = bs2label(oS);
            metrics = regionprops(L,'MajorAxisLength', 'MinorAxisLength', 'Perimeter', 'Area');
            spOut = mapMetrics2spOut(sp, metrics, rcIndex);
            % map spotPosition:
            for i=1:numel(oS)
                mo = get(oS(i), 'methodOutput');
                spOut(i).position = mo.spotMidpoint;
            end
                
end

spOut = setPositionOffset(spOut, oS);
%EXIT ---------------------

function spOut = cpSeg2spOut(sp, oS)
[nRows, nCols] = size(oS);
for i=1:nRows
    for j=1:nCols
        spOut(i,j) = sp;
        mo = get(oS(i,j), 'methodOutput');
        if ~isempty(mo)
            spOut(i,j).formFactor = 1; % fit is always round;
            spOut(i,j).aspectRatio = 1; % fit is always round;
            spOut(i,j).diameter = 2 * mo.spotRadius;
            spOut(i,j).position = mo.spotMidpoint;            
            spOut(i,j).nChiSqr  = mo.nChiSqr;
        end
    end
end

function [L, rcIndex]  = bs2label(oS)
% combines all binspots in the oS array into a single label matrix, L
% rcIndex(i,j) keeps the entry number of oS(i,j).binSpot in L
[nRows, nCols] = size(oS);
nSpots = nRows * nCols;
bw = get(oS(1), 'binSpot');
sbw = size(bw);
L = zeros(sbw(1)*nSpots, sbw(2));
rcIndex = zeros(size(oS));
for i=1:nSpots
    bw = get(oS(i), 'binSpot');
    if any(bw(:))
        iUpper = 1 + (i-1) * sbw(1);
        iLower = iUpper + sbw(1)-1;
        l = zeros(size(bw)); l(bw) = i;
        L(iUpper:iLower,:) = l;
        rcIndex(i) = i;
    else
        rcIndex(i) = 0;
    end
end

function spOut = mapMetrics2spOut(sp, metrics, rcIndex)
[nRows, nCols] = size(rcIndex);

for i=1:nRows
    for j=1:nCols
        spOut(i,j) = sp;
        li = rcIndex(i,j);
        if li
            spOut(i,j).diameter       = metrics(li).MajorAxisLength;
            spOut(i,j).aspectRatio    = metrics(li).MajorAxisLength/metrics(li).MinorAxisLength;
        %    spOut(i,j).position       = %metrics(li).Centroid;
            if metrics(li).Perimeter
                spOut(i,j).formFactor     = (metrics(li).Area * 4*pi )/(metrics(li).Perimeter)^2;
            else
                spOut(i,j).formFactor    = 0;
            end


        end
    end
end

function sp = setPositionOffset(sp, os);
[nRows, nCols] = size(sp);
for i=1:nRows
    for j=1:nCols
        if ~isempty(sp(i,j).position)
            mp0 = get(os(i,j), 'mp0');
            cLu = get(os(i,j), 'cLu');
            sp(i,j).positionOffset =  mp0 - (cLu + sp(i,j).position-1);
            sp(i,j).positionDelta   = norm(sp(i,j).positionOffset);
        end
    end
end

        
