function bw = getBinSpot(s)
bw = [];
if ~isempty(s.bsSize)
    bw = false(s.bsSize);
    bw(s.bsTrue) = true;
end
