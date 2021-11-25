% function s = pg_seg_segment_by_edge_fxd_mp(oS, I, cx, cy, rotation)
function spots = pg_seg_segment_by_edge_fxd_mp(params, I, cx, cy, ~)
spotPitch =  params.grdSpotPitch;


%  get the left upper coordinates and right lower coordinates
xLu = round(cx - spotPitch);
yLu = round(cy - spotPitch);
xRl = round(cx + spotPitch);
yRl = round(cy + spotPitch);

% make sure these are in the image
xLu(xLu < 1) = 1;
yLu(yLu < 1) = 1;
xRl(xRl > size(I,1)) = size(I,1);
yRl(yRl > size(I,2)) = size(I,2);

% resize the image for filtering
imxLu = min(xLu);
imyLu = min(yLu);
imxRl = max(xRl);
imyRl = max(yRl);



J = I(imxLu:imxRl, imyLu:imyRl);
% imagesc(J)

% apply morphological filtering if required.
if params.segNFilterDisk >= 1
    se = strel('disk', mean(round(params.segNFilterDisk/2)));
    J  = imerode(J, se);
    J  = imdilate(J, se);
end

J = edge(J, 'canny', params.segEdgeSensitivity);
I = false(size(I));
I(imxLu:imxRl, imyLu:imyRl) = J;
% start segmentation loop
pixAreaSize = params.segAreaSize * spotPitch;
pixOff = round(max(spotPitch -0.5*pixAreaSize,0));
spotPitch = round(spotPitch);

% preallocate the array of segmentation objects
params = pg_seg_set_background_mask(params, size(I));


if ~isfield( params, 'spots' )
    spot         = pg_seg_create_spot_structure(params);
    params.spots = repmat(spot, length(cx(:)), 1);
end

for i = 1:length(cx(:))
%     s(i) = oS;
%     s(i).initialMidpoint = [cx(i), cy(i)];
    params.spots(i).initialMidpoint = [cx(i), cy(i)];
    
    xLocal = round(xLu(i) + [0, 2*spotPitch]);
    yLocal = round(yLu(i) + [0, 2*spotPitch]);
    xLocal(xLocal < 1) = 1;
    xLocal(xLocal > size(I,1)) = size(I,1);
    yLocal(yLocal < 1) = 1;
    yLocal(yLocal > size(I,2)) = size(I,2);
    % get the local image around the spot
    Ilocal = false(size(I));
    xInitial = xLocal + [pixOff,-pixOff];
    yInitial = yLocal + [pixOff,-pixOff];
    Ilocal(xInitial(1):xInitial(2), yInitial(1):yInitial(2)) = I(xInitial(1):xInitial(2),yInitial(1):yInitial(2));
    Linitial = bwlabel(Ilocal);
    nObjects = max(Linitial(:));
    if nObjects > 1
        % keep the largest
        a = zeros(nObjects,1);
        for t = 1:nObjects
            a(t) = sum(Linitial(:) == t);
        end
        [~, nLargest] = max(a);
        Ilocal = Linitial == nLargest(1);
    end
    [x,y] = find(Ilocal);
    % store the current area left upper
%     s(i).bsLuIndex = [xLocal(1), yLocal(1)];
    params.spots(i).bsLuIndex = [xLocal(1), yLocal(1)];
    
%     s(i).bsSize = size(Ilocal);
    params.spots(i).bsLuIndex = size(Ilocal);
    
%     s(i) = translateBackgroundMask(s(i),[cx(i),cy(i)], size(I));
    params.spots(i) = pg_seg_translate_background_mask( params.spots(i), ...,
                    [cx(i), cy(i)], size(I) );
        
%     s(i).finalMidpoint = [cx(i),cy(i)];
    params.spots(i).finalMidpoint = [cx(i),cy(i)];
    
    
    
    
    if length(x) >= params.segMinEdgePixels
        % min nr of pixels found
        % fit a circle to the foreground pixels, at the fixed midpoint
        [r, nChiSqr] = pg_seg_rob_circ_fit_fxd_mp(x,y,cx(i),cy(i));
        
        Ilocal = false(size(Ilocal));
        params.spots(i).diameter = 2*r;
        params.spots(i).chisqr   = nChiSqr;
        
        if(length(r)>1), r = r(i); end
        [xFit, yFit] = pg_circle([cx(i),cy(i)],r,round(pi*r)/2);
        Ilocal = roipoly(Ilocal, yFit, xFit);
        params.spots(i).bsTrue    = find(Ilocal);
        params.spots(i).bsSize = size(Ilocal);
    end
end


spots = params.spots;