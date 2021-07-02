function msg = writeBatch(sBatchFile, stBatch)
[fid,em]  = fopen(sBatchFile, 'wt');
msg = [];
if fid ==-1
    msg = em;
    return;
end
fprintf(fid, '%s\n', '<Batch>');
clNames = fieldnames(stBatch);
skipFields{1} = 'gridImageInfo';
skipFields{2} = 'isGridImage';

iSkip = logical(zeros(size(clNames)));
for i =1:length(skipFields)
    iMatch = strmatch(skipFields{i}, clNames);
    iSkip(iMatch) = 1;
end
clNames = clNames(~iSkip);

for i=1:length(stBatch)
    fprintf(fid, '%s\n', '<Entry>');
    for j=1:length(clNames)
        sOpenItem       = ['<',clNames{j},'>'];
        sCloseItem      = ['</',clNames{j},'>'];
        sValue = stBatch(i).(clNames{j});
        if isnumeric(sValue)
            sValue = num2str(sValue);
        end
        if ischar(sValue)
            fprintf(fid, '%s%s%s\n', sOpenItem, sValue, sCloseItem);
        end
     end
    fprintf(fid, '%s\n', '</Entry>');
end
fprintf(fid, '%s\n', '</Batch>');
fclose(fid);