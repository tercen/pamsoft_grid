function FileList = filehound(parentDir, fFilter, doRecursive)
%FileList = filehound(parentDir, filter, doRecursive)

FileList = ([]);

if (nargin < 3)
    doRecursive = 1;    
end

AllNames = dir(parentDir);
nAllNames = length(AllNames);

% these are the requested files
FileNames = dir([parentDir,'\',fFilter]);
nFiles = length(FileNames);

if (nFiles)
    for i=1:nFiles
        FileList(i).fPath   = parentDir;
        FileList(i).fName   = FileNames(i).name; 
    end
end
if (doRecursive)
    for i=1:nAllNames
        if  AllNames(i).isdir  & ...
           ~isequal(AllNames(i).name, '.') & ...
           ~isequal(AllNames(i).name, '..') 
                     
           FileList = [FileList, filehound([parentDir,'\',AllNames(i).name], fFilter)];
        end
    end
end

    % EOF