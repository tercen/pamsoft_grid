function s = addComtrolPoint(s, d)
if ~isa(d, 'dataPoint')
    error('d should be a dataPoint object')
end
if s.controlisempty
    s.controlPoints(1) = d;
    s.controlisempty = 0;
else
    s.controlPoints(end+1) = d;
end

