function aMask = pg_seg_get_background_mask(spot)
% function aMask = getBackgroundMask(oS)
% aMask = false(oS.bsSize);
% aMask(oS.bbTrue) = true; 

aMask = false(spot.bsSize);
aMask(spot.bbTrue) = true;