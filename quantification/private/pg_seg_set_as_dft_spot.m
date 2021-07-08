% function oS = setAsDftSpot(oS,dftSpotSize)
function params = pg_seg_set_as_dft_spot(params, dftSpotSize)
if nargin < 2
       dftSpotSize = [];
end

for i=1:length(params.spot)
    if isempty(params.spot(i).bsSize)
        error('bsSize (binSpot) property has not been set');
    end
    if isempty(dftSpotSize)
        dftSpotSize = 0.6 * params.spot(i).grdSpotPitch;
    end
%              params.spot(i) = pg_translate_background_mask( params.spot(i), ...
%                         [x0, y0], size(I) );
    params.spot(i) = pg_translate_background_mask(params.spot(i), params.spot(i).initialMidpoint, params.spot(i).bsSize);
    
    params.spot(i).finalMidpoint = params.spot(i).initialMidpoint;
    params.spot(i).diameter      = dftSpotSize;
    params.spot(i).bsLuIndex 	 = params.spot(i).finalMidpoint - round(params.spot(i).bsSize)/2; 
    
    
    
    [x,y]                 = pg_seg_get_outline(params.spot(i), 'coordinates', 'global');   
    [xc,yc]               = find(true(oS(i).bsSize));
    in                    = inpolygon(xc,yc, x, y);
    params.spot(i).bsTrue = find(in);

end