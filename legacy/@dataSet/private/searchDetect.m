function [list, instrument] = searchDetect(path, filter, forceStructure)
% check for image results
dirList = dir(path);
bFound = 0;
for i=1:length(dirList)
    if dirList(i).isdir && ~isempty(findstr(dirList(i).name, 'ImageResults'));
        bFound = 1;
        srchDir = [path, '\', dirList(i).name];
        break;
    end
end

bFD10 = 0;
bQC = 0;

if (bFound)
    % forced structure for PS96 and PS4 (WFTP)
    fList = filehound(srchDir, filter);
    n = 0;
    list = struct([]);
    for i=1:length(fList)
        bName = fList(i).fName;


        iPoint = findstr('.', bName);
        bName = bName(1:iPoint-1);
        a = strread(bName, '%s', 'delimiter', '_');


        % read in WFTP set

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

    % detect WFTP instrument

    if isempty(list)
        error(['No data found in: ', path])
    end

    if isempty(str2num(list(1).W(2)))
        % detect PS96 naming
        instrument = 'PS96';
    else
        str = [list(1).path, '\', list(1).name];
        info = imfinfo(str);
        is = [info.Height, info.Width];
        if is < 1000
            instrument = 'PS4_12';
        else
            instrument = 'PS4_23';
        end
    end
    return

else

    % if no ImageResults is found we define: QC system and FD10
  
    srchStr = [path, '\', filter];
    fList = dir(path);
    % FD10: look for sub dirs with the word Testsite
    strFD10 = 'Testsite';
    [clName{1:length(fList)}] = deal(fList.name);
    [clIsDir{1:length(fList)}] = deal(fList.isdir);
    isdir = logical(cell2mat(clIsDir));
    clDir = clName(isdir);
    for i=1:length(clDir)
        if ~isempty(findstr(clDir{i}, strFD10));
            bFD10 = 1;
            break;
        end
    end
    % QC96, look for QC named images in selected directory
    fList = filehound(path, filter, 0);
    if ~isempty(fList)

        bName = fList(i).fName;
        iPoint = findstr('.', bName);
        bName = bName(1:iPoint-1);
        a = strread(bName, '%s', 'delimiter', '_');
        if length(a) > 2
            if ~isempty(str2num(a{end-1})) && ~isempty(str2num(a{end}))
                bQC = 1;
            end
        end

    end
end

if bQC
    % map qc naming to PS96 naming
    instrument = 'QC96';
    list = searchQC96(fList);
elseif bFD10
    instrument = 'FD10';
    fList = filehound(path, filter);
    list = searchFD10(fList);
else
    error('No supported data structure found');
end

if isempty(list)
    error(['No data found in: ', path]);
end

    
   


    