function s = addDataPoint(s, d)
if ~isa(d, 'dataPoint')
    error('d should be a datapoint object')
end

if (s.isempty)
    s.dataPoints(1) = d;
    s.isempty = 0;
else
    s.dataPoints(end+1) = d;
end
