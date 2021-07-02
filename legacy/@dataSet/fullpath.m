function pathLocation = fullpath(d,nList)

if isnumeric(nList) 
    sEntry = d.list(nList);
elseif isstruct(nList)
    sEntry = nList;
end

if length(sEntry) > 1
for j=1:length(sEntry)
    pathLocation{j} = fullfile(sEntry(j).path, sEntry(j).name);
end
else
    pathLocation = fullfile(sEntry.path, sEntry.name);
end

