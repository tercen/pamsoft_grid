function spots = pg_seg_segment_by_hough(params, I, cx, cy, ~)
spotPitch =  mean(params.grdSpotPitch);

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
    params.spots(i).initialMidpoint = [cx(i), cy(i)];
    
    xLocal = round(xLu(i) + [0, 2*spotPitch]);
    yLocal = round(yLu(i) + [0, 2*spotPitch]);
    
    xLocal(xLocal < 1) = 1;
    xLocal(xLocal > size(I,1)) = size(I,1);
    yLocal(yLocal < 1) = 1;
    yLocal(yLocal > size(I,2)) = size(I,2);
    
    zoomFac = 0.8;
    xInitial = xLocal + round([pixOff,-pixOff].*zoomFac);
    yInitial = yLocal + round([pixOff,-pixOff].*zoomFac);
    
    Ilocal =  double(I(xInitial(1):xInitial(2),yInitial(1):yInitial(2)));
    
    windowWidth = 3; 
    kernel = ones(windowWidth) / windowWidth ^ 2;
    Ilocal = imfilter(Ilocal, kernel, 'replicate');
    
   % Loosely fit a circle to find the spot.
   % Sometimes, this is used to center the windows on the spot of interest
    if mean(Ilocal(:)) > params.qntSaturationLimit/2
        % Potentially large spot
        [cnts, roff, metOff]=imfindcircles(Ilocal,[11 24], 'EdgeThreshold', 0.5, 'Sensitivity', 0.95);
    else
        [cnts, roff, metOff]=imfindcircles(Ilocal,[6 20], 'Sensitivity', 0.95);
    end
    
    

    if ~isempty(metOff)
        lx = cnts(2);
        ly = cnts(1);
        
        th = 0:pi/40:2*pi;
        
        xunit = roff(1) * cos(th) + lx;
        yunit = roff(1) * sin(th) + ly;
        
        if min(xunit) < 0 || max(xunit)>size(Ilocal,1) || ...
                min(yunit) < 0 || max(yunit)>size(Ilocal,1)
            zoomFac = zoomFac/2;
        end
    else
        [~,mxi] = max(Ilocal(:));
        [lx,ly] = ind2sub(size(Ilocal), mxi);
        
        if lx <= 2 || lx >= (size(Ilocal,1)-2) || ...
                ly <= 2 || ly >= (size(Ilocal,2)-2)
            % Maximum is on the border and is likely a different spot
            lx = size(Ilocal,1)/2;
            ly = size(Ilocal,2)/2;
        end
        
    end
    
    offX = size(Ilocal,1)/2-lx;
    offY = size(Ilocal,2)/2-ly;
    
    
    xInitial = xLocal + round([pixOff,-pixOff].*zoomFac) - floor(offX);
    yInitial = yLocal + round([pixOff,-pixOff].*zoomFac) - floor(offY);
    Ilocal =  double(I(xInitial(1):xInitial(2),yInitial(1):yInitial(2)));
    
    rfac   = 3;
    [xp,yp] = meshgrid( 1:size(Ilocal,1) );
    [xq,yq] = meshgrid( 1:(1/rfac):size(Ilocal,1) );
    
    windowWidth = 3;
    kernel = ones(windowWidth) / windowWidth ^ 2;
    
    %%
    Ihi =  interp2(xp,yp,imfilter(Ilocal.^2, kernel),xq,yq, 'linear');
    %         Ihi =  interp2(xp,yp,imfilter(Ilocal.^8, kernel),xq,yq, 'linear');
    
    thrV = (max(Ilocal(:))) / params.qntSaturationLimit;
    
    lowCont = 0;
    if thrV < 0.6
        % Possibly low contrast Spot
        Ihi =  interp2(xp,yp,imfilter(Ilocal.^8, kernel),xq,yq, 'linear');
        lowCont = 1;
    end
    
    
    if lowCont
        mu = 1;
        t = 0.00;
        while mu > 0.5
            t = t + 0.05;
            Ilochi = Ihi > max(Ihi(:) * t);
            mu = mean(Ilochi(:));
            
        end
    else
        
        if thrV > 0.9
            % Likely large spot
            Ilochi = Ihi > max(Ihi(:) * 0.5);
        else
            Ilochi = Ihi > max(Ihi(:) * 0.3);
        end
        
        
    end
    
    % Use the Hough transform to find the spot center and radius
    [cnts, rdis, mets] = imfindcircles(Ilochi, [7 30]);
    
        
    
    if isempty(rdis) || isempty(mets) || mets(1) < 0.4
        spotFound = false;
        x0 = cx(i);
        y0 = cy(i);
    else
        spotFound = true;
        
        % Re-center the window relative to the initial coordinates
        xc = xLocal(1)+round(pixOff)*zoomFac - floor(offX);
        yc = yLocal(1)+round(pixOff)*zoomFac - floor(offY);
        
        x0 = xc + (cnts(1,2)-1)/rfac;
        y0 = yc + (cnts(1,1)-1)/rfac;
        
        diam  = (2*rdis(1)/rfac);
    end
    
    
    Ilocal = false(size(I));
    
    if spotFound
        params.spots(i).diameter = diam;
        r = diam/2;
        
        [xFit, yFit] = pg_circle([x0,y0],r,round(pi*r)/2);
        Ilocal = roipoly(Ilocal, yFit, xFit);
    end
    
    params.spots(i).bsSize = size(Ilocal);
    params.spots(i).bsTrue = find(Ilocal);
    
    params.spots(i) = pg_seg_translate_background_mask( params.spots(i), ...
        [x0, y0], size(I) );
    
    
    params.spots(i).finalMidpoint = [x0, y0];

    
    
    
    
end

spots = params.spots;



