function [params, exitCode] = pg_read_params_json(params, jsonFile)
% Read in the parameter .json file
% INPUT:
%   jsonFile: path to the parameter file
%
% OUTPUT
%   params: struct containing parameters. If a parameter is not defined,
%   the default value will be used
%
% exitCode 0:  Success
% exitCode -11: No paramfie specified
% exitCode -12: Parameter file does not exist
% exitCode -13: Error parsing JSON file



exitCode = 0;

% jsonFile = params.paramfile;

if ~exist(jsonFile, 'file')
    exitCode = -12;
    pg_error_message('general.paramfile.exist', exitCode, jsonFile);
    
    return
end

% Read JSON file into a string
fid = fopen(jsonFile);
raw = fread(fid, inf);
str = char(raw');
fclose(fid);



try
    jsonParams = jsondecode(str);
    jsonParamNames = fieldnames(jsonParams);
    for k = 1:length(jsonParamNames)
        paramName = jsonParamNames{k};
        if startsWith(paramName, 'x_')
            continue;
        end
        params.(paramName) = jsonParams.(paramName);
        
        % The code is expecting column format, but arrays come in row
        % format from the JSON parsing
        % If that is the case, we transpose it
        if isnumeric(params.(paramName)) && length(params.(paramName)) > 1
            if size(params.(paramName),1) > size(params.(paramName), 2)
                params.(paramName) = params.(paramName)';
            end
        end
        
    end
    
       
    % In the legacy code, this was set in the @array object constructor as
    % empty
    
catch
    exitCode = -13;
    pg_error_message('general.paramfile.parse', exitCode, jsonFile);
end

end