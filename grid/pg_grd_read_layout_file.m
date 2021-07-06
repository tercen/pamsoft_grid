function [params, exitCode] = pg_grd_read_layout_file(params, gridRefMarker)
% array.fromFile.
% [oArrayOut, extraHeaders, extraColumns] = fromFile(oArray, filename, <gridRefMarker>)
% read array object form file
% This method can be used to read in mask and spot ID's for a tab delimited
% textfile filename (ie a template file).
% Required columns:
% Row: row of a spot in the array
% Col: columns of spot in the array
% ID: spot ID
%
% optionals:
% Xoff: offset from ideal in pixels
% Yoff: offset from ideal in pixels
% If the offsets are not specified they will default to zero
%
% xFixedPosition: yFixedPosition: pre set coordinates for spots
% IsReference: 1 if the corresponding spot is as position reference,
% otherwise 0. If the IsReference column is specified the grdRefMarker argument (if specified) 
% will be ignored (see below).
%
% Next to these required / optional columscolumns extra columns can be added for user
% reference
% 
% OUT:
% oArrayOut will contain loaded row, col, isreference, xOffset, yOffset
% extraHeaders: headers of the extra colums as a cell array (see above)
% extraColumns:extra colum,sn corresponding to extra headers, as a cell
% array
% IN:
% oArray: array object as definde by oArray = array(args)
% filename: full path to the template file
% gridRefMarker (optional and obsolete): When the IsReference columns is not found this is a  code that precedes an ID in the file and
% signifies that the spot should be used a gridding reference. If the
% gridRefMarker is omitted or the specified gridRefMarker is not found in
% the template file all spots are used as gridRefMarkers.
%
% EXAMPLE:
% template file ('MyArray.txt')
% Row    Col ID      Xoff    Yoff   MyRef       IsReference
% 1     1   SPOT1   0       0       mutation1   0
% 1     2   ref     0       0       ref         1
% 2     1   ref     0       0       ref         1
% 2     2   SPOT2   0       0       mutation1   0
% oArray = array();
% % oArray = fromFile(oArray, 'MyArray.txt', '#');
% r = get(oArray, 'row')
% 
% r =
% 
%      1
%      1
%      2
%      2
% >> b = get(oArray, 'isreference')
% 
% b =
% 
%      0
%      1
%      1
%      0
% 
%  >> ID = get(oArray, 'ID')
% 
% ID = 
% 
%     'SPOT1'
%     '#ref'
%     '#ref'
%     'SPOT2'
% See also array/array, array/gridFind
exitCode = 0;



if nargin == 1
    gridRefMarker = [];
end

if ~isfield(params, 'arraylayoutfile')
    exitCode = -8;
    pg_error_message( exitCode, params.paramfile );
    return;
end


if ~exist( params.arraylayoutfile, 'file' )
    exitCode =-9;
    pg_error_message( exitCode, params.arraylayoutfile );
    return;
end



fid = fopen(params.arraylayoutfile, 'rt');
if fid == -1
%     error(['Could not open: ', fName]);
    exitCode =-10;
    pg_error_message(exitCode, params.arraylayoutfile );
    return;
end

% define columnheader keywords as the fields of KeyWord struct.
% the value is true when the columns are required, optional when false
KeyWord.Row = true;
KeyWord.Col = true;
KeyWord.ID = true;
KeyWord.Xoff = false;
KeyWord.Yoff = false;
KeyWord.xFixedPosition = false;
KeyWord.yFixedPosition = false;
KeyWord.IsReference = false;

fLine  = strread(fgetl(fid), '%s', 'delimiter', '\t')';
fLine  = deblank(fLine);
labels = fieldnames(KeyWord);
%identfy columns nrs corresponding to keyword.
% error return when any of the keywords is not matched exactly one time:
fMatch = false(size(fLine));
for i = 1:length(labels)
    iMatch = strmatch(labels{i}, fLine, 'exact');
    if isempty(iMatch) && KeyWord.(labels{i})
        fclose(fid);
        error(['Error reading: ', fName,'. Cannot find required columns header: ', labels{i}]);
    elseif length(iMatch) > 1
        fclose(fid);
        error(['Error reading: ', fName,'. Cannot uniquely identify column header: ',labels{i}]);
    elseif isempty(iMatch) && ~KeyWord.(labels{i})
        Match.(labels{i}) = 0;
    elseif ~isempty(iMatch)
        Match.(labels{i}) = iMatch;   
        fMatch(iMatch) = true;
    end
    
end

% make a list of the non-matched headers
extraHeaders = fLine(~fMatch);

% read in spot data 
n = 1;
while(1)
    strLine = fgetl(fid);  
    if strLine == -1
        break;
    end
    strLine = deblank(strLine);
    if ~isempty(strLine)
        try
            % read into cell array.
            clLine = strread(strLine,'%s', 'delimiter', '\t');
            % get required / optional according to Match
            % convert to numerics if appropriate
            row(n)     = str2num(char((clLine(Match.Row))) );
            col(n)     = str2num(char((clLine(Match.Col))) );
            ID(n)      = clLine(Match.ID);
            xOff(n)    = str2num(char((clLine(Match.Xoff))) );
            yOff(n)    = str2num(char((clLine(Match.Yoff))) );
            if Match.xFixedPosition && Match.yFixedPosition
                xFxd(n) = str2num(char((clLine(Match.xFixedPosition)))  );
                yFxd(n) = str2num(char((clLine(Match.yFixedPosition)))  );
            end
            if Match.IsReference
                isreference(n) =  str2num(char((clLine(Match.IsReference))) );
            end
            extraColumns(n,:) = clLine(~fMatch);
            %[row(n), col(n), strID, xOff(n), yOff(n)]  = strread(strLine, '%f%f%s%f%f', 'delimiter', '\t');                        
        catch
            fclose(fid);
            eStr = [lasterr,' On line ',num2str(n),': ',strLine];
            error(eStr, 'error reading template file');
        end
        n= n+ 1; 

    end
end
fclose(fid);

% if ~Match.IsReference try to get refs from the gridRefMarker
if ~isempty(gridRefMarker) && ~Match.IsReference
    isreference = strncmp(gridRefMarker, ID, length(gridRefMarker));
    
    if ~any(isreference)
        % if no grdRefMarker set all true;
        isreference = true(size(ID));
    end
elseif ~Match.IsReference
    % if no ref specified set all true;
    isreference = true(size(ID));
else
    isreference = logical(isreference);
end

% g.row = row';
% g.col = col';
% g.isreference = isreference';
% g.ID = ID';

if Match.Xoff
    xOffset = xOff';
else
    xOffset = zeros(size(row));
end

if Match.Yoff
    yOffset = yOff';
else
    yOffset = zeros(size(row));
end

if Match.xFixedPosition && Match.yFixedPosition
    xFixedPosition = xFxd';
    yFixedPosition = yFxd';
else
    xFixedPosition = zeros(size(row'));
    yFixedPosition = zeros(size(row'));
end

% isreference
params.qntSpotID = ID';
params.grdCol    = col';
params.grdRow    = row';
params.grdIsReference = isreference';
params.grdXOffset   = xOffset;
params.grdYOffset   = yOffset;
params.grdXFixedPosition = xFixedPosition;
params.grdYFixedPosition = yFixedPosition;
    



end