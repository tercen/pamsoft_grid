function params = pg_seg_set_background_mask(params,imSize)

for i = 1:length(params.spots)
    spot = params.spots(i);
    
    spotPitch = spot.grdSpotPitch;

    if ~isfield(spot, 'finalMidpoint') || isempty(spot.finalMidpoint)
        % create dummy mask, centered around image midpoint
        spot.finalMidpoint = round(imSize/2); 

    end
    fmp   = spot.finalMidpoint;
    % FIXME
    % Does not work with spotPitch as a vector
    pxOff = spot.segBgOffset*spotPitch;

    if length(pxOff) == 1
        pxOff = [pxOff pxOff];
    end
    
    sqCorners = [   fmp(2)-pxOff(2), fmp(1)-pxOff(1);
                    fmp(2)-pxOff(2), fmp(1)+pxOff(1);
                    fmp(2)+pxOff(2), fmp(1)+pxOff(1);
                    fmp(2)+pxOff(2), fmp(1)-pxOff(1) ];
    aSquareMask = poly2mask(sqCorners(:,1), sqCorners(:,2), imSize(1), imSize(2));
    [crx, cry] = pg_circle([fmp(2), fmp(1)], mean(pxOff),25);
    aCircleMask = poly2mask(crx, cry, imSize(1), imSize(2));
    spot.bbTrue = find(aSquareMask & ~aCircleMask);

    params.spots(i) = spot;
end
