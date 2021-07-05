function sublist = getSubset(d, strWFTP)

if isempty(d.list)
    d = getList(d);
end

clWFTP = strread(strWFTP, '%s', 'delimiter', '_');
fnames = fieldnames(d.list);


bIn = true(size(d.list));
for i=1:length(clWFTP)
    fstr = clWFTP{i};
    iMatch = strmatch(fstr(1), fnames);
    if isempty(iMatch)
        error(['Cannot find a list element entry for: ', fstr(1)]);
    end
    [entries{1:length(d.list)}] = deal(d.list.(fnames{iMatch}));
    bIn = bIn & strcmp(fstr, entries);
end

sublist = d.list(bIn);
