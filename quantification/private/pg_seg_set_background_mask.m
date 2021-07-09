function params = pg_seg_set_background_mask(params,imSize)

% function s = setBackgroundMasks
spotPitch = params.grdSpotPitch;

if ~isfield(params, 'segFinalMidpoint') || isempty(params.segFinalMidPoint)
    % create dummy mask, centered around image midpoint
    params.segFinalMidPoint = round(imSize/2); 
   
end
fmp   = params.segFinalMidPoint;
pxOff = params.segBgOffset*spotPitch;

sqCorners = [   fmp(2)-pxOff, fmp(1)-pxOff;
                fmp(2)-pxOff, fmp(1)+pxOff;
                fmp(2)+pxOff, fmp(1)+pxOff;
                fmp(2)+pxOff, fmp(1)-pxOff ];
aSquareMask = poly2mask(sqCorners(:,1), sqCorners(:,2), imSize(1), imSize(2));
[crx, cry] = pg_circle([fmp(2), fmp(1)], pxOff,25);
aCircleMask = poly2mask(crx, cry, imSize(1), imSize(2));
params.bbTrue = find(aSquareMask & ~aCircleMask);
