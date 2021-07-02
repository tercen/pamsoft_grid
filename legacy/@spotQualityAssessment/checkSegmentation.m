function spotFlag = checkSegmentation(sqa, oS)
%function spotFlag = checkSegmentation(sqa, oS)
% returns 0 when OK, 1, when not OK, 2, when empty
sstr = get(oS);
spotFlag = zeros(size(sstr));
for i=1:length(sstr)
    mp0 = sstr(i).initialMidpoint;
    mp1 = sstr(i).finalMidpoint;
    sp = sstr(i).spotPitch;
    d = sstr(i).diameter/sp;
    if ~isempty(mp1) && ~isempty(d)
        offset = norm(mp1-mp0)/sp;
        if d >= sqa.minDiameter && d <= sqa.maxDiameter && offset <= sqa.maxOffset;
            spotFlag(i) = 0;
        else
            spotFlag(i) = 1;
        end
    else
        spotFlag(i) = 2;
    end
end

    


    