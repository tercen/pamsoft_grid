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
JI(imxLu:imxRl, imyLu:imyRl) = J;
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
    params.spots(i).initialMidpoint = [cx(i), cy(i)];
    
    delta = 2;
    xLocal = round(xLu(i) + [0, 2*spotPitch]);
    yLocal = round(yLu(i) + [0, 2*spotPitch]);
    
    %         aMidpoint = params.spots(i).initialMidpoint;
    % do while delta larger than sqrt(2)
    % make sure the local coordinates are within the image
    xLocal(xLocal < 1) = 1;
    xLocal(xLocal > size(I,1)) = size(I,1);
    yLocal(yLocal < 1) = 1;
    yLocal(yLocal > size(I,2)) = size(I,2);
    % get the local image around the spot
    %             %%
    %             clc;
    
    zoomFac = 0.8;
    xInitial = xLocal + round([pixOff,-pixOff].*zoomFac);
    yInitial = yLocal + round([pixOff,-pixOff].*zoomFac);
    
    Ilocal =  double(I(xInitial(1):xInitial(2),yInitial(1):yInitial(2)));
    
    windowWidth = 3; % Whatever you want.  More blur for larger numbers.
    kernel = ones(windowWidth) / windowWidth ^ 2;
    Ilocal = imfilter(Ilocal, kernel, 'replicate');
    
    
%     if i == 2 && length(cx) > 10
%         disp('.');
%     end
%     

    V = mean(Ilocal(:))/mean(I(:));
    if V < 1.6 && V > 1.2
%         fprintf('[E] %d - %.4f\n', i,  mean(Ilocal(:))/mean(I(:)) );
        

%         disp(i);
%         disp('Going for edge');
        params.spots(i).initialMidpoint = [cx(i), cy(i)];
       
        delta = 2;        
        xLocal = round(xLu(i) + [0, 2*spotPitch]);
        yLocal = round(yLu(i) + [0, 2*spotPitch]); 
        
        aMidpoint = params.spots(i).initialMidpoint;
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
%             Ilocal = false(size(I));          

            xInitial = xLocal + [pixOff,-pixOff];
            yInitial = yLocal + [pixOff,-pixOff];
            
            Ilocal = JI(xInitial(1):xInitial(2),yInitial(1):yInitial(2));
            anObjectList = bwconncomp(Ilocal);
            nPix = cellfun(@length, anObjectList.PixelIdxList);
            [mxPix,mxObject] = max(nPix);

            % store the current area left upper
            params.spots(i).bsLuIndex = [xLocal(1), yLocal(1)];
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
            
            [xFit, yFit] = pg_circle([x0,y0],r,round(pi*r)/2);
%             Ilocal = roipoly(Ilocal, yFit, xFit);   
            J = roipoly(J, yFit, xFit);   
        end
        
        
        params.spots(i).bsSize = size(J);
        params.spots(i).bsTrue = find(J);
        
        params.spots(i) = pg_seg_translate_background_mask( params.spots(i), ...
                        [x0, y0], size(I) );
                    
                    
        params.spots(i).finalMidpoint = [x0, y0];
        
    else
%         fprintf('[H] %d - %.4f\n', i,  mean(Ilocal(:))/mean(I(:))  );
        if mean(Ilocal(:)) > params.qntSaturationLimit/2
            % Potentially large spot
            [cnts, roff, metOff]=imfindcircles(Ilocal,[11 24], 'EdgeThreshold', 0.5, 'Sensitivity', 0.95);
        else
            [cnts, roff, metOff]=imfindcircles(Ilocal,[6 20], 'Sensitivity', 0.95);
        end
        
        largeSpot = 0;
        if ~isempty(metOff)
            lx = cnts(2);
            ly = cnts(1);
            
            th = 0:pi/40:2*pi;
            
            xunit = roff(1) * cos(th) + lx;
            yunit = roff(1) * sin(th) + ly;
            
            if min(xunit) < 0 || max(xunit)>size(Ilocal,1) || ...
                    min(yunit) < 0 || max(yunit)>size(Ilocal,1)
                zoomFac = zoomFac/2;
                largeSpot = 3;
            end
            
            
            
            
        else
            [mx,mxi] = max(Ilocal(:));
            [lx,ly] = ind2sub(size(Ilocal), mxi);
        end
        
        offX = size(Ilocal,1)/2-lx;
        offY = size(Ilocal,2)/2-ly;
        
        %             clf;
        %             subplot(121);
        %             imagesc(Ilocal);
        %
        %             hold on;
        %             plot(yunit, xunit, 'k');
        
        xInitial = xLocal + round([pixOff,-pixOff].*zoomFac) - floor(offX);
        yInitial = yLocal + round([pixOff,-pixOff].*zoomFac) - floor(offY);
        Ilocal =  double(I(xInitial(1):xInitial(2),yInitial(1):yInitial(2)));
        %
        %             subplot(122);
        %             imagesc(Ilocal);
        %             %%
        
        %             clc;
        %             Ilocal =  double(I(xInitial(1):xInitial(2),yInitial(1):yInitial(2)));
        rfac   = 3;
        [xp,yp] = meshgrid( 1:size(Ilocal,1) );
        [xq,yq] = meshgrid( 1:(1/rfac):size(Ilocal,1) );
        
        windowWidth = 5; % Whatever you want.  More blur for larger numbers.
        kernel = ones(windowWidth) / windowWidth ^ 2;
        
        
        Ihi =  interp2(xp,yp,imfilter(Ilocal.^8, kernel),xq,yq, 'linear');
        
        thrV = sqrt(sqrt(sqrt(mean(abs(diff(Ihi(:))))/length(Ihi(:)))));
        thr = 30;
        sens = 0.9;
        if thrV > 200
            windowWidth = 2; % Whatever you want.  More blur for larger numbers.
            kernel = ones(windowWidth) / windowWidth ^ 2;
            Ihi =  interp2(xp,yp,imfilter(Ilocal.^2, kernel),xq,yq, 'linear');
            
            thrV = (((mean(abs(diff(Ihi(:))))/length(Ihi(:)))));
            thr = 0.2;
            %                 sens = sens -0.1;
        end
        %%
%                     if i == 17 && length(cx(:)) > 10
%                          clf;
%                          imagesc(Ihi); hold on;
%                     end
        %
        [cnts, rdis, met]=imfindcircles(Ihi,[5*rfac (12+largeSpot)*rfac], 'Sensitivity', sens);
        if isempty(met)
            sens = sens + 0.1;
            [cnts, rdis, met]=imfindcircles(Ihi,[5*rfac (12+largeSpot)*rfac], 'Sensitivity', sens, 'EdgeThreshold', 0.1 );
        end
        
        
        if length(met) > 1
            mvs = zeros(length(met), 1);
            for ck = 1:length(met)
                [xFit, yFit] = pg_circle([cnts(ck,1), cnts(ck,2)],rdis(ck),round(pi*rdis(ck))/2);
                Ilocal = roipoly(Ihi, xFit, yFit);
                
                mvs(ck) = nansum( Ihi(Ilocal(:)) ) .* met(ck);
            end
            
            [~,mk] = max(mvs);
            
            rdis = rdis(mk);
            cnts = cnts(mk,:);
            met = met(mk);
            
        end
        
        
        
        if isempty(met)  || (thrV < thr  && met < 1) || (met < 0.9)
            rdis = [];
        end
        %
        %             if i == 1 && length(cx)  >10
        %                 disp('.');
        %             end
        %
        
        if ~isempty(rdis)
            %+ round([pixOff,-pixOff].*1) - floor(lx/2);
            xc = xLocal(1)+round(pixOff)*zoomFac - floor(offX)-0;
            yc = yLocal(1)+round(pixOff)*zoomFac - floor(offY)-0;
            
            x = cnts(1);
            y = cnts(2);
            r = rdis(1);
            
            th = 0:pi/40:2*pi;
            xunit = r * cos(th) + x;
            yunit = r * sin(th) + y;
%                             plot(xunit, yunit, 'k');
            %
            xOut = sum(xunit>size(Ihi,1)) + sum(xunit<=0);
            yOut = sum(yunit>size(Ihi,1)) + sum(yunit<=0);
            
            
            %
            if xOut/length(xunit) > 0.1 || yOut/length(yunit) > 0.1
                spotFound = false;
                x0 = cx(i);
                y0 = cy(i);
                
                %                     fprintf('%d: %.2f, %.2f\n', i, abs(cnts(2)/rfac - size(Ihi,2)/(2*rfac)), abs(cnts(1)/rfac - size(Ihi,1)/(2*rfac)));
            else
                
                spotFound = true;
                
                
                %                 x0 = cx(i) + xoff/2 -2;
                %                 y0 = cy(i) + yoff/2 -2;
                
                x0 = xc + cnts(2)/rfac ;
                y0 = yc + cnts(1)/rfac ;
                diam  = 2*r/rfac;
                
                if abs(cx(i) - x0) > spotPitch/1.5 || abs(cy(i) - y0) > spotPitch/1.5
                    %                         fprintf('%d - %.3f, %.3f\n', i, abs(cx(i) - x0), abs(cy(i) - y0));
                    spotFound = false;
                    x0 = cx(i);
                    y0 = cy(i);
                    
                    
                end
                
                
                %                 if abs( cnts(2)/rfac - size(Ilocal,2)/2) > spotPitch/2 || ...
                %                    abs( cnts(1)/rfac - size(Ilocal,1)/2) > spotPitch/2
                %                 if i == 1 && length(cx) > 10
                %                    if abs(cnts(2)/rfac - size(Ihi,2)/(2*rfac)) > 1 || ...
                %                       abs(cnts(1)/rfac - size(Ihi,1)/(2*rfac)) > 1
                %                     fprintf('%d: %.2f, %.2f\n', i, abs(cnts(2)/rfac - size(Ihi,2)/(2*rfac)), abs(cnts(1)/rfac - size(Ihi,1)/(2*rfac)));
                %                  end
                
                %
%                                     clf;
%                                     imagesc(I); hold on;
%                 %     % %
%                                     th = 0:pi/40:2*pi;
%                                     xunit = r/rfac * cos(th) + x0;
%                                     yunit = r/rfac * sin(th) + y0;
%                                     plot(yunit, xunit, 'k');
                %                     axis([120 160 180 220]);
                
                %                 x0 = xLocal(1) + cnts(1)/rfac;
                %                 y0 = yLocal(1) + cnts(2)/rfac;
                
            end
            
            
            %                 break;
        else
            spotFound = false;
            x0 = cx(i);
            y0 = cy(i);
            %                 break;
        end
        %%
        
          Ilocal = false(size(I));
    %
    if spotFound
        params.spots(i).diameter = diam;
        r = diam/2;
        %             params.spots(i).chisqr   = nChiSqr;
        
        [xFit, yFit] = pg_circle([x0,y0],r,round(pi*r)/2);
        Ilocal = roipoly(Ilocal, yFit, xFit);
        %             clf; imagesc(I); hold on; plot(yFit, xFit, 'k.');
        
        %
        %             if ~isempty(met)
        %                 fprintf('[x] %d: %.3f\n', i, met);
        %             else
        %                 fprintf('[x] %d: %.3f\n', i, 0.000);
        %             end
        
    else
        
        %             if ~isempty(met)
        %                 fprintf('[ ] %d: %.3f\n', i, met);
        %             else
        %                 fprintf('[ ] %d: %.3f\n', i, 0.000);
        %             end
        %             clf; imagesc(I); hold on; plot(cy(i), cx(i), 'k.');
        %             disp('.');
    end
    
    params.spots(i).bsSize = size(Ilocal);
    params.spots(i).bsTrue = find(Ilocal);
    
    params.spots(i) = pg_seg_translate_background_mask( params.spots(i), ...
        [x0, y0], size(I) );
    
    
    params.spots(i).finalMidpoint = [x0, y0];
        %%
    end
    
  
    
end

spots = params.spots;



