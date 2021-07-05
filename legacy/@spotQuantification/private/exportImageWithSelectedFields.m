function exportImageWithSelectedFields(q, fName,sFields, pgVersion)
fid = fopen(fName, 'wt');
if fid == -1
    error('exportImage:fileError', '%s', ['Could not open: ', fName]);
end

if nargin < 4
    pgVersion = [];
end
fprintf(fid, '%s\n', '<General>');
fprintf(fid, '%s\t%s\n', 'File Name', fName);
fprintf(fid, '%s\t%s\n', 'Date', date);
fprintf(fid, '%s\t%s\n', 'Version', pgVersion);
fprintf(fid, '\n');
settings = getSettings(q(1,1));
fNames = fieldnames(settings);
for i=1:length(fNames);
    fprintf(fid, '%s\t', fNames{i});
    val = settings.(fNames{i});
    if isnumeric(val)
        fprintf(fid, '%f\n', val);
    else
        fprintf(fid, '%s\n', val);
    end
end
fprintf(fid, '%s\n', '</General>');

[nRows, nCols] = size(q);
results = getResult(q);
results = results(:);
fprintf(fid, '%s\n', '<Spots>');
fNames = fieldnames(results);

for i=1:length(fNames)
    if ismember(fNames(i), sFields)
        fprintf(fid, '%s\t', fNames{i});
    end
end
fprintf(fid, '\n');
for i=1:length(results)

    for j=1:length(fNames)
        
        if ismember(fNames(j), sFields)
            val = results(i).(fNames{j});
            if isnumeric(val) && ~isempty(val)
                fprintf(fid, '%f\t', val);
            elseif isnumeric(val) && isempty(val)
                fprintf(fid, '%s\t', 'NULL');
            elseif islogical(val)
                fprintf(fid, '%d\t', val);
            else
                fprintf(fid, '%s\t', val);
            end
        end
        
    end
    fprintf(fid, '\n');
end

fprintf(fid, '%s\n', '</Spots>');
fclose(fid);

            


