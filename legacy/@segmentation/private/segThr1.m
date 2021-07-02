function spots = segThr1(I, cx,cy, spotAreaSize, mFull)

[nRows, nCols] = size(cx);

for i = 1:nRows
    for j=1:nCols
        cLu  = round([cx(i,j), cy(i,j)] - (spotAreaSize/2));
        
        cLu(cLu<1) = 1;
        
        xLu = cLu(1);
        yLu = cLu(2);
        xRl = round(xLu + spotAreaSize);
        yRl = round(yLu + spotAreaSize);
        
        xRl = min(xRl, size(I,1));
        yRl = min(yRl, size(I,2));
        
        Ispot = I(xLu:xRl, yLu:yRl);
        Ispot = (mFull/max(Ispot(:)) ) * Ispot;
        
        [level, eps] = graythresh(Ispot);
        spots(i,j).cLu = [xLu, yLu];
        spots(i,j).binSpot = im2bw(Ispot, level);
        spots(i,j).thrEff  = eps;        
    end
end
