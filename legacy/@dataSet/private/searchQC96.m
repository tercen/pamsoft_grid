function list = searchQC96(fList)
n = 0;
list = struct([]);
for i=1:length(fList)
    rowStr = ['ABCDEFGH'];
    colStr = ['01';'02';'03';'04';'05';'06';'07';'08';'09';'10';'11';'12'];
    bName = fList(i).fName;
    iPoint = findstr(bName, '.');
    iPoint = iPoint(end);
    bName = bName(1:iPoint-1);
    a = strread(bName, '%s', 'delimiter', '_');
    nChip = str2num(a{end-1});
    nArray = str2num(a{end});
    W = [];
    if nChip <= 12 & nArray >= 1 & nArray <=4
        W = ['W',rowStr(nArray),colStr(nChip,:)];
    elseif nChip > 12 & nArray >= 1 & nArray <=4
        W = ['W',rowStr(nArray+4),colStr(nChip-12,:)];
    end
    if ~isempty(W)
        n = n+1;
        list(n).name = fList(i).fName;
        list(n).path = fList(i).fPath;
        list(n).W    = W;
        list(n).P    = 'P1';
        list(n).F    = 'FX';
        list(n).T    = 'TX';
        list(n).C    = [];
        list(n).S    = [];
    end

end