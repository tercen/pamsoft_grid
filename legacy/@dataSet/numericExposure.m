function T = numericExposure(d, nList)
if isnumeric(nList) 
    sEntry = d.list(nList);
elseif isstruct(nList)
    sEntry = nList;
end

[T{1:length(sEntry)}]  = deal(sEntry.T);
T = char(T);
T = str2num(T(:, 2:end));