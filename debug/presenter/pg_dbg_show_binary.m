% function pg_dbg_show_binary(oQ)
function pg_dbg_show_binary(oQ)
spot = pg_get_bin_spot(oQ.Spot);
ignored = getIgnoredMask(oQ); % oQ.iIgnored;
% get(oQ, 'ignoredMask');
bg = oQ.Spot.bbTrue; %get(oQ.oSegmentation, 'bbTrue');
binview = double(spot);
binview(bg) = 0.5;
binview(ignored) = 0.25;
imshow(binview);
colormap(gca, 'jet');
mp = oQ.Spot.finalMidpoint; %get(oQ.oSegmentation, 'finalMidpoint');
sp  = oQ.Spot.grdSpotPitch; % get(oQ.oSegmentation, 'spotPitch');
set(gca, 'xlim', mp(2)+[-sp,sp], 'ylim',mp(1)+[-sp,sp]);
end


function bw = pg_get_bin_spot(s)
bw = [];
if ~isempty(s.bsSize)
    bw = false(s.bsSize);
    bw(s.bsTrue) = true;
end
end

 
 
 
 function igMask = getIgnoredMask(q)
     if isempty(q.Spot)
         error('segmentation property has not been set');
     end
     bsSize = q.Spot.bsSize;
     
     if isempty(bsSize)
         error('segmentation.binSpot property has not been set');
     end
     igMask = false(bsSize); 
     igMask(q.iIgnored) = true;
 end