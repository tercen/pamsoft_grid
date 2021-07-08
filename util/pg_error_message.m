function pg_error_message(errorCode, varargin)
    persistent errMap;
    
    if isempty(errMap)
%         fid = fopen('error_messages.json');
%         raw = fread(fid, inf);
%         strDef = char(raw');
%         fclose(fid);
%         
%         errorCodeStruct = jsondecode(strDef);
        errMap = pg_create_error_map();
    end


%     errorCode = strrep(sprintf('x%d', errorCode), '-', '_');

    errMsg =errMap(errorCode);
%     if isfield(errorCodeStruct, errorCode)
%     errMsg = errorCodeStruct.(errorCode);

    pIdx = 1;
    for i = 1:length(varargin)
        errMsg = strrep(errMsg, sprintf('$%d', pIdx), varargin{i});
        pIdx = pIdx + 1;
    end
    fprintf('%s\n', errMsg);
%     end
    
end



function errMap = pg_create_error_map()


    errMap = containers.Map('KeyType', 'int32', 'ValueType', 'char');
    errMap(-1) = 'The specified filepath for $2 does not exist ($1).';
  
    errMap(-2) = 'Error parsing configuration file $1.';
    errMap(-3) = 'Parameter imageslist has not been set in $1.';
    errMap(-4) = 'Parameter imageslist must be an array with length > 1.';
    errMap(-5) = 'Could not read image $1.';
    errMap(-6) = 'Error reading information from $1 ($2).';
    errMap(-7) = 'Invalid combination of input images: there are multiple images with both equal cycle and exposure time.';
    errMap(-8) = 'Parameter arralyoutfile has not been set in $1.';
    errMap(-9) = 'The specified arraylayout file ($1) does not exist.';
    errMap(-10) = 'Could not open arraylayoutfile $1.';
    errMap(-11) = 'Property $1 has not been set or is empty.';
    errMap(-12) = 'Specified exposure time and cycle are not present in the list of images ($1, $2).';
    errMap(-13) = 'Value $2 is invalid for param $1.';
    errMap(-14) = 'grdRow and grdCol properties must be vectors.';
    errMap(-15) = 'Vectors $1 and $2 must have the same length.';
    errMap(-16) = 'Parameters grdXOffset and grdYOffset must have the same length as grdCol and grdRow.';
    errMap(-17) = 'Parameters grdXFixedPosition and grdYFixedPosition must have the same length as grdCol and grdRow.';
    errMap(-18) = 'Failed to save inexistent params field $1.';
    errMap(-19) = 'All parameters to be saved must have the same length (different field: $1).';
    errMap(-20) = 'Error reading file $2 [$1] (Message: $3).';
    
    errMap(-21) = 'None of the reference spots were properly found.';
    
    errMap(-1000) = 'Invalid command line argument passed. Expected pamsoft_grid --param-file=/path/to/paramfile.json';
    


end