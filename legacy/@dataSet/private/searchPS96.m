function list = searchPS96(path, filter)
% check for image results
dirList = dir(path);
bFound = 0;
for i=1:length(dirList)
    if dirList(i).isdir && ~isempty(findstr(dirList(i).name, 'ImageResults'));
        bFound = 1;
        break;
    end
end

if ~bFound
    error(['No ImageResults found in: ',path]);
end
srchDir = [path, '\', dirList(i).name];
fList = filehound(srchDir, filter);
n = 0;
list = struct([]);
for i=1:length(fList)
    bName = fList(i).fName;
    iPoint = findstr('.', bName);
    bName = bName(1:iPoint-1);
    
    a = strread(bName, '%s', 'delimiter', '_');
    bWFTP = 1;
    iW = strmatch('W', a);
    iF = strmatch('F', a);
    iT = strmatch('T', a);
    iP = strmatch('P', a);
    
    if ~isempty(iW) && ~isempty(iT) && ~isempty(iF) && ~isempty(iP)
        n = n+1;
        list(n).name = fList(i).fName;
        list(n).path = fList(i).fPath;
        list(n).W = a{iW};
        list(n).F = a{iF};
        list(n).T = a{iT};
        list(n).P = a{iP};
    end
end
       