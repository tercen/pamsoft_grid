function params = pg_seg_segment_by_edge(params, I, cx, cy, ~)
spotPitch = params.grdSpotPitch; %oS.spotPitch;


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
% apply morphological filtering if required.
if params.segNFilterDisk >= 1
    se = strel('disk', round(params.segNFilterDisk/2));
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
% oS = setBackgroundMask(oS, size(I));
params = pg_seg_set_background_mask(params, size(I));
% s      = repmat(oS, length(cx(:)), 1);


spot        = pg_seg_create_spot_structure(params)
params.spot = repmat(spot, length(cx(:)), 1);

for i = 1:length(cx(:))
%         s(i) = oS;
%         s(i).initialMidpoint = [cx(i), cy(i)];
        
        params.spot(i).initialMidpoint = [cx(i), cy(i)];
        
        delta = 2;        
        xLocal = round(xLu(i) + [0, 2*spotPitch]);
        yLocal = round(yLu(i) + [0, 2*spotPitch]); 
        % do while delta larger than sqrt(2) 
        deltaIter = 0;
        while delta > sqrt(2) && deltaIter < 3
            deltaIter = deltaIter + 1;            
            % make sure the local coordinates are within the image
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
%             s(i).bsLuIndex = [xLocal(1), yLocal(1)];
            params.spot(i).bsLuIndex = [xLocal(1), yLocal(1)];
            if length(x) < params.segMinEdgePixels %oS.minEdgePixels
                % when the number of foreground pixels is too low, abort
                spotFound = false;
                x0 = cx(i);
                y0 = cy(i);
                break;
            end
            spotFound = true;
            % fit a circle to the foreground pixels
            [x0, y0, r, nChiSqr] = pg_seg_rob_circ_fit(x,y);
            % calculate the difference between area midpoint and fitted midpoint 
            %s(i).finalMidpoint = [x0, y0];
            
%             mpOffset = [x0,y0] - s(i).initialMidpoint;
            mpOffset = [x0, y0] - params.spot(i).initialMidpoint;
            delta = norm(mpOffset);   
            % shift area according to mpOffset for next iteration,
            % the loop terminates if delta converges to some low value.
            xLocal    = round(xLocal + mpOffset(1));
            
            xLocal(1) = max(xLocal(1),1); 
            xLocal(2) = max(xLocal(2),xLocal(1) + 1); 
            
            yLocal    = round(yLocal + mpOffset(2));  
            
            yLocal(1) = max(yLocal(1),1);
            yLocal(2) = max(yLocal(2), yLocal(1) + 1);
        end
        Ilocal = false(size(Ilocal));
        if spotFound                   
%             s(i).diameter = 2*r;
%             s(i).chisqr = nChiSqr;
            
            params.spot(i).diameter = 2*r;
            params.spot(i).chisqr   = nChiSqr;
            
            [xFit, yFit] = pg_circle(x0,y0,r,round(pi*r)/2);
            Ilocal = roipoly(Ilocal, yFit, xFit);    
        end
        
        s(i).bsSize    = size(Ilocal);
        s(i).bsTrue    = find(Ilocal);
        s(i) = translateBackgroundMask(s(i),[x0,y0], size(I));
        s(i).finalMidpoint = [x0, y0];
        
        params.spot(i).bsSize = size(Ilocal);
        params.spot(i).bsTrue = find(Ilocal);
        params.spot(i) = pg_translate_background_mask( params.spot(i), ...
                        [x0, y0], size(I) );
        params.spot(i).finalMidpoint = [x0, y0];
        
end





