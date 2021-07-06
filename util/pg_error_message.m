function pg_error_message(errorCodeStr, varargin)
    %TODO create error code files
    % Likely a JSON file containing the messages
    persistent errorCodeStruct;
    
    if isempty(errorCodeStruct)
        fid = fopen('error_messages.json');
        raw = fread(fid, inf);
        strDef = char(raw');
        fclose(fid);
        
        errorCodeStruct = jsondecode(strDef);
        errorCodes      = fieldnames(errorCodeStruct);
        for k = 1:length(errorCodes)
            disp(errorCodes{k});
        end
    end

    
end