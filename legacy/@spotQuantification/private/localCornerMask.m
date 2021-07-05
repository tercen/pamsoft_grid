function iMask = localCornerMask(q)
%
bgOffset = 0.45;
oS = get(q, 'oSegmentation');
oS = oS{:};
segMethod = get(oS, 'method');
switch segMethod
    case 'Edge'
        iMask = maskFromEdgeSegmentation(oS, bgOffset);
    otherwise
        error('segmentation method not supported');
end

function iMask = maskFromEdgeSegmentation(oS, bgOffset)
spotPitch = get(oS, 'spotPitch');
fmp = get(oS, 'finalMidpoint');
mSize = get(oS, 'bsSize');
pxOff = bgOffset*spotPitch;
sqCorners = [   fmp(1)-pxOff, fmp(2)-pxOff;
                fmp(1)-pxOff, fmp(2)+pxOff;
                fmp(1)+pxOff, fmp(2)+pxOff;
                fmp(1)+pxOff, fmp(2)-pxOff ];
aSquareMask = poly2mask(sqCorners(:,1), sqCorners(:,2), mSize(1), mSize(2));
[crx, cry] = circle(fmp(1), fmp(2), pxOff,25);
aCircleMask = poly2mask(crx, cry, mSize(1), mSize(2));
iMask = find(aSquareMask & ~aCircleMask);



