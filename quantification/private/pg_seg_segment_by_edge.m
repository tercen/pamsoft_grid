function spots = pg_seg_segment_by_edge(params, I, cx, cy, ~)
spotPitch =  mean(params.grdSpotPitch);


dftRadius = 0.6 * spotPitch;
origI = I;
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

%%
J = I(imxLu:imxRl, imyLu:imyRl);

% apply morphological filtering if required.
if params.segNFilterDisk >= 1
    se = strel('disk', (round(params.segNFilterDisk/2)));
    J  = imerode(J, se);
    J  = imdilate(J, se);
end

%(1/var(double(J(:))))/2

% J = edge(J, 'canny', params.segEdgeSensitivity);
J = edge(J, 'canny', params.segEdgeSensitivity);


% clf; imshowpair(J,J1);
%  axis([0 40 0 40]);
%%
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
        params.spots(i).initialMidpoint = [cx(i), cy(i)];
       
        delta = 2;        

        xLocal = round(xLu(i) + [0, 2*spotPitch]);
        yLocal = round(yLu(i) + [0, 2*spotPitch]); 
        
        aMidpoint = params.spots(i).initialMidpoint;
        % do while delta larger than sqrt(2) 
        deltaIter = 0;
        while delta > sqrt(2) && deltaIter < 3
            deltaIter = deltaIter + 1;            
            %%
            % make sure the local coordinates are within the image
            xLocal(xLocal < 1) = 1;
            xLocal(xLocal > size(I,1)) = size(I,1);
            yLocal(yLocal < 1) = 1;
            yLocal(yLocal > size(I,2)) = size(I,2);                       
            % get the local image around the spot
            Ilocal = false(size(I));          

%             xInitial = xLocal + [pixOff-4,-pixOff+4];
%             yInitial = yLocal + [pixOff-4,-pixOff+4];
              
            xInitial = xLocal + [pixOff,-pixOff];
            yInitial = yLocal + [pixOff,-pixOff];
            
            Ilocal = I(xInitial(1):xInitial(2),yInitial(1):yInitial(2));
            
%             clf; imagesc(Ilocal)
            
            %%
            anObjectList = bwconncomp(Ilocal);
            
            nPix = cellfun(@length, anObjectList.PixelIdxList);
            [mxPix,mxObject] = max(nPix);
      

            % store the current area left upper
            params.spots(i).bsLuIndex = [xLocal(1), yLocal(1)];
%             if length(x) < params.segMinEdgePixels %oS.minEdgePixels
            if mxPix >= params.segMinEdgePixels
                spotFound = true;
            else

                % when the number of foreground pixels is too low, abort
                spotFound = false;

                x0 = cx(i);
                y0 = cy(i);
                break;
            end
            
            % fit a circle to the foreground pixels
            Ilocal = false(size(Ilocal));
            Ilocal(anObjectList.PixelIdxList{mxObject}) = true;
            J = false(size(I));
            J(xInitial(1):xInitial(2),yInitial(1):yInitial(2)) = Ilocal;
            [x,y] = find(J);
            [x0, y0, r, nChiSqr] = pg_seg_rob_circ_fit(x,y);

            %%

            % calculate the difference between area midpoint and fitted midpoint 
            mpOffset = [x0,y0] - aMidpoint;
            delta = norm(mpOffset);
            aMidpoint = [x0,y0];
            
            % shift area according to mpOffset for next iteration,
            % the loop terminates if delta converges to some low value.
            xLocal    = round(xLocal + mpOffset(1));
            
            xLocal(1) = max(xLocal(1),1); 
            xLocal(2) = max(xLocal(2),xLocal(1) + 1); 
            
            yLocal    = round(yLocal + mpOffset(2));  
            
            yLocal(1) = max(yLocal(1),1);
            yLocal(2) = max(yLocal(2), yLocal(1) + 1);
        end

        J = false(size(I));
        if spotFound                   
            params.spots(i).diameter = 2*r;
            params.spots(i).chisqr   = nChiSqr;
            params.spots(i).isFound  = 1; 
        else
            r = dftRadius / 2;
            params.spots(i).diameter = 2*r;
            params.spots(i).chisqr   = -1;
            params.spots(i).isFound  = 0;
        end
        

%         %%
        
        %   -1 x -1: 9.644
%         %%
%         clf;
%         imagesc( origI ); colormap jet; hold on;
%         
%         
%         th = 0:pi/50:2*pi;
%         xunit = r * cos(th) + x0;
%         yunit = r * sin(th) + y0;
%         spotColor = 'g';
%         
%         plot(y0, x0, 'w+');
%         plot(yunit, xunit, spotColor);
%         
%         if i == 1
%         r0 = 9.644/2;
%         th = 0:pi/50:2*pi;
%         xunit = r0 * cos(th) + 198.07;
%         yunit = r0 * sin(th) + 139.57;
%         spotColor = 'k';
%         
%         plot(139.57, 198.07, 'kx')
%         plot(yunit, xunit, spotColor);
%         axis([132 149 190 206]);
%         end
%         
%         
%         if i == 2
% 
%                 r0 = 10.058/2;
%             th = 0:pi/50:2*pi;
%             xunit = r0 * cos(th) + 232.0;
%             yunit = r0 * sin(th) + 139.02;
%             spotColor = 'k';
% 
%             plot(139.02, 232.02, 'kx')
%             plot(yunit, xunit, spotColor);
%             axis([132 149 190+35 206+35]);
%         end

%         fprintf('%d x %d: %.3f (%.5f x %.5f)\n', params.grdRow(i), params.grdCol(i), r*2, y0, x0);
%         disp('.');
        %139.57 x 198.07
        %%
        
        
        [xFit, yFit] = pg_circle([x0,y0],r,round(pi*r)/2);

        J = roipoly(J, yFit, xFit);   
        
        params.spots(i).bsSize = size(J);
        params.spots(i).bsTrue = find(J);
        
        params.spots(i) = pg_seg_translate_background_mask( params.spots(i), ...
                        [x0, y0], size(I) );
                    
                    
        params.spots(i).finalMidpoint = [x0, y0];
end

spots = params.spots;



% -1 x -1: 10.076 (139.99996 x 198.00004)


% -1 x -1: 9.644 (139.57 x 198.07)
% -3 x -1: 10.058 (139.02 x 232.00)
% -5 x -1: 10.076 (139.00 x 266.00)
% -3 x -2: 10.076 (156.00 x 232.00)
% -2 x -20: 9.519 (462.54 x 214.97)
% -4 x -20: 9.438 (462.39 x 248.61)
% -6 x -20: 9.465 (462.48 x 282.89)
% -6 x -19: 9.521 (445.49 x 282.79)
% 1 x 1: 9.465 (206.52 x 146.96)
% 1 x 2: 10.200 (224.31 x 146.92)
% 1 x 3: 9.528 (240.50 x 146.99)
% 1 x 4: 10.200 (258.31 x 146.92)
% 1 x 5: 10.200 (275.31 x 146.92)
% 1 x 6: 10.200 (292.31 x 146.92)
% 1 x 7: 10.200 (309.31 x 146.92)
% 1 x 8: 10.200 (326.31 x 146.92)
% 1 x 9: 10.200 (343.31 x 146.92)
% 1 x 10: 10.200 (360.31 x 146.92)
% 1 x 11: 9.625 (377.52 x 147.48)
% 1 x 12: 10.200 (394.31 x 146.92)
% 2 x 1: 10.200 (207.31 x 163.92)
% 2 x 2: 10.200 (224.31 x 163.92)
% 2 x 3: 10.200 (241.31 x 163.92)
% 2 x 4: 10.200 (258.31 x 163.92)
% 2 x 5: 10.200 (275.31 x 163.92)
% 2 x 6: 10.200 (292.31 x 163.92)
% 2 x 7: 10.200 (309.31 x 163.92)
% 2 x 8: 10.200 (326.31 x 163.92)
% 2 x 9: 10.200 (343.31 x 163.92)
% 2 x 10: 10.200 (360.31 x 163.92)
% 2 x 11: 10.200 (377.31 x 163.92)
% 2 x 12: 10.200 (394.31 x 163.92)
% 3 x 1: 10.200 (207.31 x 180.92)
% 3 x 2: 10.200 (224.31 x 180.92)
% 3 x 3: 10.200 (241.31 x 180.92)
% 3 x 4: 10.200 (258.31 x 180.92)
% 3 x 5: 10.200 (275.31 x 180.92)
% 3 x 6: 10.200 (292.31 x 180.92)
% 3 x 7: 10.200 (309.31 x 180.92)
% 3 x 8: 10.200 (326.31 x 180.92)
% 3 x 9: 10.200 (343.31 x 180.92)
% 3 x 10: 10.200 (360.31 x 180.92)
% 3 x 11: 10.200 (377.31 x 180.92)
% 3 x 12: 10.153 (394.91 x 180.94)
% 4 x 1: 10.200 (207.31 x 197.92)
% 4 x 2: 10.200 (224.31 x 197.92)
% 4 x 3: 10.200 (241.31 x 197.92)
% 4 x 4: 10.200 (258.31 x 197.92)
% 4 x 5: 10.200 (275.31 x 197.92)
% 4 x 6: 10.200 (292.31 x 197.92)
% 4 x 7: 10.200 (309.31 x 197.92)
% 4 x 8: 10.200 (326.31 x 197.92)
% 4 x 9: 10.200 (343.31 x 197.92)
% 4 x 10: 10.200 (360.31 x 197.92)
% 4 x 11: 10.200 (377.31 x 197.92)
% 4 x 12: 10.200 (394.31 x 197.92)
% 5 x 1: 10.200 (207.31 x 214.92)
% 5 x 2: 10.200 (224.31 x 214.92)
% 5 x 3: 10.200 (241.31 x 214.92)
% 5 x 4: 10.200 (258.31 x 214.92)
% 5 x 5: 10.200 (275.31 x 214.92)
% 5 x 6: 10.200 (292.31 x 214.92)
% 5 x 7: 10.200 (309.31 x 214.92)
% 5 x 8: 10.200 (326.31 x 214.92)
% 5 x 9: 10.200 (343.31 x 214.92)
% 5 x 10: 10.200 (360.31 x 214.92)
% 5 x 11: 10.200 (377.31 x 214.92)
% 5 x 12: 10.200 (394.31 x 214.92)
% 6 x 1: 10.200 (207.31 x 231.92)
% 6 x 2: 10.200 (224.31 x 231.92)
% 6 x 3: 10.200 (241.31 x 231.92)
% 6 x 4: 10.200 (258.31 x 231.92)
% 6 x 5: 10.200 (275.31 x 231.92)
% 6 x 6: 10.200 (292.31 x 231.92)
% 6 x 7: 10.200 (309.31 x 231.92)
% 6 x 8: 10.200 (326.31 x 231.92)
% 6 x 9: 10.200 (343.31 x 231.92)
% 6 x 10: 10.200 (360.31 x 231.92)
% 6 x 11: 10.200 (377.31 x 231.92)
% 6 x 12: 10.200 (394.31 x 231.92)
% 7 x 1: 10.200 (207.31 x 248.92)
% 7 x 2: 10.200 (224.31 x 248.92)
% 7 x 3: 10.200 (241.31 x 248.92)
% 7 x 4: 10.200 (258.31 x 248.92)
% 7 x 5: 10.200 (275.31 x 248.92)
% 7 x 6: 10.200 (292.31 x 248.92)
% 7 x 7: 10.200 (309.31 x 248.92)
% 7 x 8: 10.200 (326.31 x 248.92)
% 7 x 9: 10.200 (343.31 x 248.92)
% 7 x 10: 10.200 (360.31 x 248.92)
% 7 x 11: 10.200 (377.31 x 248.92)
% 7 x 12: 10.200 (394.31 x 248.92)
% 8 x 1: 10.200 (207.31 x 265.92)
% 8 x 2: 10.200 (224.31 x 265.92)
% 8 x 3: 10.200 (241.31 x 265.92)
% 8 x 4: 10.200 (258.31 x 265.92)
% 8 x 5: 10.200 (275.31 x 265.92)
% 8 x 6: 10.200 (292.31 x 265.92)
% 8 x 7: 10.200 (309.31 x 265.92)
% 8 x 8: 10.200 (326.31 x 265.92)
% 8 x 9: 10.200 (343.31 x 265.92)
% 8 x 10: 10.200 (360.31 x 265.92)
% 8 x 11: 10.200 (377.31 x 265.92)
% 8 x 12: 10.088 (394.01 x 266.01)
% 9 x 1: 10.200 (207.31 x 282.92)
% 9 x 2: 10.200 (224.31 x 282.92)
% 9 x 3: 10.200 (241.31 x 282.92)
% 9 x 4: 10.200 (258.31 x 282.92)
% 9 x 5: 10.200 (275.31 x 282.92)
% 9 x 6: 10.200 (292.31 x 282.92)
% 9 x 7: 10.200 (309.31 x 282.92)
% 9 x 8: 10.200 (326.31 x 282.92)
% 9 x 9: 10.200 (343.31 x 282.92)
% 9 x 10: 10.200 (360.31 x 282.92)
% 9 x 11: 10.200 (377.31 x 282.92)
% 9 x 12: 10.062 (394.02 x 282.99)
% 10 x 1: 10.200 (207.31 x 299.92)
% 10 x 2: 10.200 (224.31 x 299.92)
% 10 x 3: 10.200 (241.31 x 299.92)
% 10 x 4: 10.200 (258.31 x 299.92)
% 10 x 5: 10.200 (275.31 x 299.92)
% 10 x 6: 10.200 (292.31 x 299.92)
% 10 x 7: 10.200 (309.31 x 299.92)
% 10 x 8: 10.200 (326.31 x 299.92)
% 10 x 9: 9.497 (343.38 x 299.44)
% 10 x 10: 8.255 (359.58 x 300.33)
% 10 x 11: 10.200 (377.31 x 299.92)
% 10 x 12: 10.243 (394.97 x 299.04)
% 11 x 1: 10.200 (207.31 x 316.92)
% 11 x 2: 10.200 (224.31 x 316.92)
% 11 x 3: 10.200 (241.31 x 316.92)
% 11 x 4: 10.200 (258.31 x 316.92)
% 11 x 5: 10.200 (275.31 x 316.92)
% 11 x 6: 10.200 (292.31 x 316.92)
% 11 x 7: 10.200 (309.31 x 316.92)
% 11 x 8: 10.200 (326.31 x 316.92)
% 11 x 9: 10.200 (343.31 x 316.92)
% 11 x 10: 10.200 (360.31 x 316.92)
% 11 x 11: 10.200 (377.31 x 316.92)
% 11 x 12: 10.068 (394.00 x 316.99)
% 12 x 1: 10.093 (207.01 x 333.99)
% 12 x 2: 10.200 (224.31 x 333.92)
% 12 x 3: 10.200 (241.31 x 333.92)
% 12 x 4: 10.200 (258.31 x 333.92)
% 12 x 5: 10.200 (275.31 x 333.92)
% 12 x 6: 10.200 (292.31 x 333.92)
% 12 x 7: 10.200 (309.31 x 333.92)
% 12 x 8: 10.200 (326.31 x 333.92)
% 12 x 9: 10.200 (343.31 x 333.92)
% 12 x 10: 10.200 (360.31 x 333.92)
% 12 x 11: 10.200 (377.31 x 333.92)
% 12 x 12: 10.200 (394.31 x 333.92)