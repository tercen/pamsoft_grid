function params = pg_seg_set_background_mask(params,imSize)

if ~isfield(params, 'spots')
    % @TODO Error message
    return;
end

for i = 1:length(params.spots)
    spot = params.spots(i);
    % function s = setBackgroundMasks
    spotPitch = spot.grdSpotPitch;

    if ~isfield(spot, 'finalMidpoint') || isempty(spot.finalMidpoint)
        % create dummy mask, centered around image midpoint
        spot.finalMidpoint = round(imSize/2); 

    end
    fmp   = spot.finalMidpoint;
    pxOff = spot.segBgOffset*spotPitch;

    sqCorners = [   fmp(2)-pxOff, fmp(1)-pxOff;
                    fmp(2)-pxOff, fmp(1)+pxOff;
                    fmp(2)+pxOff, fmp(1)+pxOff;
                    fmp(2)+pxOff, fmp(1)-pxOff ];
    aSquareMask = poly2mask(sqCorners(:,1), sqCorners(:,2), imSize(1), imSize(2));
    [crx, cry] = pg_circle([fmp(2), fmp(1)], pxOff,25);
    aCircleMask = poly2mask(crx, cry, imSize(1), imSize(2));
    spot.bbTrue = find(aSquareMask & ~aCircleMask);

    params.spots(i) = spot;
end
