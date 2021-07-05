function [clID, msg] = getUniqueID(v, fName)
% clID = vGetUniqueID(v, fName)
% return the unique values in structure v, field fName

% check if field fName exists
names = fieldnames(v);
clID = cellstr('');
if isempty(strmatch(fName, names, 'exact'))
    msg = ['vGetUniqueID: input structure v does not contain required field ',fName,'.'];
    return
end

nFound = 0;
for i=1:length(v)
    if isempty(strmatch(v(i).(fName), clID))
       nFound = nFound + 1;
       clID(nFound) = cellstr(v(i).(fName));
    end
end
