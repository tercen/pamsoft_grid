function list = searchFD10(fList)
strFD10 = 'Testsite';
list = struct([]);
n = 0;
for i=1:length(fList)
    iStr = findstr(strFD10, fList(i).fName);
    if ~isempty(iStr)
        n = n + 1;
        list(n).name = fList(i).fName;
        list(n).path = fList(i).fPath;
        name = list(n).name;
        iW = iStr + length(strFD10);
        list(n).W = ['W',name(iW)];
        list(n).F = 'FX';
        path = list(n).path;
        iSample = findstr(path, '\sample');
        list(n).T = ['T',path(iSample + 1: end)];
        rname = name(iW:end);
        iDash = findstr(rname, '_');
        iPoint = findstr(rname, '.');
        list(n).P = ['P',rname(iDash + 1: iPoint -1)];
        
    end
end


        