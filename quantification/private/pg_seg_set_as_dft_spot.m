% function oS = setAsDftSpot(oS,dftSpotSize)
function spots = pg_seg_set_as_dft_spot(spots, dftSpotSize)
if nargin < 2
       dftSpotSize = [];
end

for i=1:length(spots)
    if isempty(spots(i).bsSize)
        error('bsSize (binSpot) property has not been set');
    end
    if isempty(dftSpotSize)
        dftSpotSize = 0.6 * spots(i).grdSpotPitch;
    end
%              spots(i) = pg_translate_background_mask( spots(i), ...
%                         [x0, y0], size(I) );
    spots(i) = pg_seg_translate_background_mask(spots(i), spots(i).initialMidpoint, spots(i).bsSize);
    
    spots(i).finalMidpoint = spots(i).initialMidpoint;
    spots(i).diameter      = dftSpotSize;
    spots(i).bsLuIndex 	 = spots(i).finalMidpoint - round(spots(i).bsSize)/2; 
    
    
    
    [x,y]                 = pg_seg_get_outline(spots(i), 'coordinates', 'global');   
    [xc,yc]               = find(true(spots(i).bsSize));
    in                    = inpolygon(xc,yc, x, y);
    spots(i).bsTrue = find(in);

end