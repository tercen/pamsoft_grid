function pg_error_message(errorCode, varargin)
    persistent errorCodeStruct;
    
    if isempty(errorCodeStruct)
        fid = fopen('error_messages.json');
        raw = fread(fid, inf);
        strDef = char(raw');
        fclose(fid);
        
        errorCodeStruct = jsondecode(strDef);
    end


    errorCode = strrep(sprintf('x%d', errorCode), '-', '_');

    
    if isfield(errorCodeStruct, errorCode)
        errMsg = errorCodeStruct.(errorCode);

        pIdx = 1;
        for i = 1:length(varargin)
            errMsg = strrep(errMsg, sprintf('$%d', pIdx), varargin{i});
            pIdx = pIdx + 1;
        end
        fprintf('%s\n', errMsg);
    end
    
end