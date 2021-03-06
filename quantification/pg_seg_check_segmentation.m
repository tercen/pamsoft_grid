% function spotFlag = pg_seg_check_segmentation(sqa, oS)
function spotFlag = pg_seg_check_segmentation(params, maxOffset)
%function spotFlag = checkSegmentation(sqa, oS)
% returns 0 when OK, 1, when not OK, 2, when empty
sstr     = params.spots;
spotFlag = zeros(size(sstr));


for i=1:length(sstr)
    mp0 = sstr(i).initialMidpoint;
    mp1 = sstr(i).finalMidpoint;
    sp  = mean( sstr(i).grdSpotPitch );
    
    d   = sstr(i).diameter/sp;

 
    if ~isempty(mp1) && ~isempty(d) && sstr(i).isFound == 1
        offset = norm(mp1-mp0)/sp;
        if d >= params.sqcMinDiameter && d <= params.sqcMaxDiameter && offset <=maxOffset || all(mp1 == mp0)
            spotFlag(i) = 0;
        else
            spotFlag(i) = 1;
        end
    else
        spotFlag(i) = 2;
    end
end

    


    