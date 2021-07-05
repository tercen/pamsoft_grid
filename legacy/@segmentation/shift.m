function s = shift(s, xyShift)
% function s = shift(s, xyShift)

for i=1:length(s(:))
    if ~isempty(s(i).finalMidpoint)
        s(i).initialMidpoint = s(i).initialMidpoint + xyShift;
        s(i).finalMidpoint = s(i). finalMidpoint + xyShift;
        s(i).bsLuIndex = s(i).bsLuIndex + xyShift;
    end
end
% EOF