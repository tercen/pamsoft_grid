function spots = pg_seg_segment_by_hough_fxd_mp(params, I, cx, cy, ~)
spotPitch =  mean(params.grdSpotPitch);

dftRadius = 0.6 * spotPitch;

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

% apply morphological filtering if required.
if params.segNFilterDisk >= 1
    se = strel('disk', (round(params.segNFilterDisk/2)));
    J  = imerode(J, se);
    J  = imdilate(J, se);
end


J = edge(J, 'canny', params.segEdgeSensitivity);
JI = false(size(I));

% J=JI;

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
    %%
    x0 = cx(i);
    y0 = cy(i);
    
    params.spots(i).initialMidpoint = [cx(i), cy(i)];
    params.spots(i).finalMidpoint   = [cx(i), cy(i)];
    
    r = params.spots(i).diameter/2;
    
    
    [xFit, yFit] = pg_circle([x0,y0],r,round(pi*r)/2);
    Ilocal = roipoly(Ilocal, yFit, xFit);
    
    params.spots(i).bsSize = size(Ilocal);
    params.spots(i).bsTrue = find(Ilocal);
    
    params.spots(i) = pg_seg_translate_background_mask( params.spots(i), ...
        [x0, y0], size(I) );
    
    
    params.spots(i).finalMidpoint = [x0, y0];
end

spots = params.spots;



