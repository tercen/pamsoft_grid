function P = numericPumpCycle(d, nList)
if isnumeric(nList) 
    sEntry = d.list(nList);
elseif isstruct(nList)
    sEntry = nList;
end

[P{1:length(sEntry)}]  = deal(sEntry.P);
P = char(P);
P = str2num(P(:, 2:end));