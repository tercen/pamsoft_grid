function outSeg = segmentByEdge2(oS, I, cx, cy, rotation)
[nRows, nCols] = size(cx);
spotPitch = oS.spotPitch;
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
if oS.nFilterDisk >= 1
    se = strel('disk', round(oS.nFilterDisk/2));
    J  = imerode(J, se);
    J  = imdilate(J, se);
end
J = edge(J, 'canny', oS.edgeSensitivity);
I = false(size(I));
I(imxLu:imxRl, imyLu:imyRl) = J;
% start segmentation loop
pixAreaSize = oS.areaSize * spotPitch;
pixOff = round(max(spotPitch -0.5*pixAreaSize,0));
spotPitch = round(spotPitch);
for i  = 1:nRows
    for j = 1:nCols
        % store the results in nRows, nCols array of segmentation objects
        
        outSeg(i,j) = oS;
        outSeg(i,j).mp0 = [cx(i,j), cy(i,j)];
        delta = 2;
        xLocal = round(xLu(i,j) + [0, 2*spotPitch]);
        yLocal = round(yLu(i,j) + [0, 2*spotPitch]);
        
        % do while delta larget than sqrt(2) 
        deltaIter = 0;
        while delta > sqrt(2) & deltaIter < 3
            deltaIter = deltaIter + 1;            
            Ilocal = I(xLocal(1):xLocal(2),yLocal(1):yLocal(2));
        
            % center in the local image, keep the center part only.
            Iinitial = Ilocal(pixOff:end-pixOff, pixOff:end-pixOff);
            % check the number of objects found:
            Linitial = bwlabel(Iinitial);
            nObjects = max(Linitial(:));
            if nObjects > 1
                % keep the largest
                a = zeros(nObjects,1);
                for t = 1:nObjects
                    a(t) = sum(Linitial(:) == t);
                end
                [mx, nLargest] = max(a);
                Iinitial = Linitial == nLargest(1);
            end
           
            % keep the center part of Ilocal only
            Ilocal = false(size(Ilocal));
            Ilocal(pixOff:end-pixOff, pixOff:end-pixOff) = Iinitial;
          
            areaMidpoint = round(size(Ilocal)/2);
            % get the cooridnates of foreground pixels
            [x,y] = find(Ilocal);
            % store the currebt area left upper
            outSeg(i,j).cLu = [xLocal(1), yLocal(1)];
            if length(x) < 6
                % when the number of foreground pixels is too low, abort
                spotFound = false;
                break;
            else
                spotFound = true;
            end     
            % fit a circle to the foreground pixles
            [x0, y0, r, nChiSqr] = robCircFit(x,y);
            % calculate the difference between area midpoint and fitted midpoint 
            mpOffset = [x0, y0]- areaMidpoint;
            delta = norm(mpOffset);        
            % shift area according to mpOffset for next iteration,
            % the loop terminates if delta converges to some low value.
            xLocal = round(xLocal + mpOffset(1));
            xLocal(1) = max(xLocal(1),1); xLocal(2) = max(xLocal(2),xLocal(1) + 1); 
            yLocal = round(yLocal + mpOffset(2));    
            yLocal(1) = max(yLocal(1),1); yLocal(2) = max(yLocal(2), yLocal(1) + 1);
        end
        Ilocal = false(size(Ilocal));
        if spotFound            
            outSeg(i,j).methodOutput.spotMidpoint = [x0, y0];
            outSeg(i,j).methodOutput.spotRadius = r;
            outSeg(i,j).methodOutput.nChiSqr = nChiSqr;
            [xFit, yFit] = circle(x0,y0,r,round(pi*r)/2);
            %[xc,yc] = find(~Ilocal);
            %[in, on] = inpolygon(xc,yc, xFit, yFit);
            Ilocal = roipoly(Ilocal, xFit, yFit);    
        else
            outSeg(i,j).methodOutput = []; 
        end
        outSeg(i,j).bsSize    = size(Ilocal);
        outSeg(i,j).bsTrue    = uint16(find(Ilocal));
    end
end




