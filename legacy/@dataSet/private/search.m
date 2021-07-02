function [list, instrument] = search(path, filter)
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
bFD10 = 0;
for i=1:length(fList)
    bName = fList(i).fName;
    if ~isempty(findstr(bName, 'TestSite'));
        % detect FD10 named data
        bFD10 = 1
        break;
    end
    
    
    iPoint = findstr('.', bName);
    bName = bName(1:iPoint-1);
    
    a = strread(bName, '%s', 'delimiter', '_');
    bWFTP = 1;
    iW = strmatch('W', a);
    iF = strmatch('F', a);
    iT = strmatch('T', a);
    iP = strmatch('P', a);
    iC = strmatch('C', a);
    iS = strmatch('S', a);
    
    
    if ~isempty(iW) && ~isempty(iT) && ~isempty(iF) && ~isempty(iP)
        n = n+1;
        list(n).name = fList(i).fName;
        list(n).path = fList(i).fPath;
        list(n).W = a{iW};
        list(n).F = a{iF};
        list(n).T = a{iT};
        list(n).P = a{iP};
        if ~isempty(iC)
            list(n).C = a{iC};
        else
            list(n).C = [];
        end
        if ~isempty(iS)
            list(n).S = a{iS};
        else
            list(n).S = [];
        end
            
    end
end

if bFD10
    % TO DO;
    error('Sorry, FD10 named data is currently not supported');
end

if isempty(str2num(list(1).W(2)))
    % detect PS96 naming
    instrument = 'PS96';
else
    instrument = 'PS4';
end

    