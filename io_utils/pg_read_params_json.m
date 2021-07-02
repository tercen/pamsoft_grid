function [params, exitCode] = pg_read_params_json(params)
% Read in the parameter .json file
% INPUT:
%   jsonFile: path to the parameter file
% 
% OUTPUT
%   params: struct containing parameters. If a parameter is not defined,
%   the default value will be used
%
% exitCode 1:  Success
% exitCode -1: Parameter file does not exist
% exitCode -2: Error parsing JSON file



exitCode = 0;

if ~isfield(params, 'paramfile')
   exitCode = -11;
   return
end

jsonFile = params.paramfile;

if ~exist(jsonFile, 'file')
    fprintf('%s does not exist\n', jsonFile);
    exitCode = -1;
    return
end

% Read JSON file into a string
fid = fopen(jsonFile); 
raw = fread(fid, inf); 
str = char(raw'); 
fclose(fid); 



% Read Default JSON file into a string
fid = fopen('default.json'); 
raw = fread(fid, inf); 
strDef = char(raw'); 
fclose(fid); 
try
    jsonParams = jsondecode(strDef);
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
    
    
    jsonParams = jsondecode(str);
    jsonParamNames = fieldnames(jsonParams);
    for k = 1:length(jsonParamNames)
        paramName = jsonParamNames{k};
        if startsWith(paramName, 'x_')
            continue;
        end
        params.(paramName) = jsonParams.(paramName);
        
        if isnumeric(params.(paramName)) && length(params.(paramName)) > 1
            if size(params.(paramName),1) > size(params.(paramName), 2)
                params.(paramName) = params.(paramName)';
            end
        end

    end

    % In the legacy code, this was set in the array COM object constructor
    params.grdPrivate = [];
    
  

%     params
catch err
    exitCode = -2;
    err
end

end