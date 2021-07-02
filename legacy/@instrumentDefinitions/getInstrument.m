function parameters = getInstrument(oI, strInstrument);
fName = [oI.path, '\', strInstrument, oI.fExtension];
fid = fopen(fName, 'rt');
if fid == -1
    error(['Could not open the definition file: ', fName]);
end

% read in tab delimited definitions:
while(1)
    strLine = fgetl(fid);
    if strLine == -1
        break;
    end
    clLine = strread(strLine, '%s', 'delimiter', '\t');
    numVal = str2num(clLine{2});
    if isempty(numVal)
        parameters.(clLine{1}) = clLine{2};
    else
        parameters.(clLine{1}) = numVal;
    end
end
fclose(fid);

