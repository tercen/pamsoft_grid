function s = setBackgroundMask(s,imSize)
spotPitch = s.spotPitch;
fmp = s.finalMidpoint;
if isempty(fmp)
    % create dummy mask, centered around image midpoint
    s.finalMidpoint = round(imSize/2);  
end
fmp = s.finalMidpoint;
pxOff = s.bgOffset*spotPitch;
sqCorners = [   fmp(2)-pxOff, fmp(1)-pxOff;
                fmp(2)-pxOff, fmp(1)+pxOff;
                fmp(2)+pxOff, fmp(1)+pxOff;
                fmp(2)+pxOff, fmp(1)-pxOff ];
aSquareMask = poly2mask(sqCorners(:,1), sqCorners(:,2), imSize(1), imSize(2));
[crx, cry] = circle(fmp(2), fmp(1), pxOff,25);
aCircleMask = poly2mask(crx, cry, imSize(1), imSize(2));
s.bbTrue = find(aSquareMask & ~aCircleMask);
