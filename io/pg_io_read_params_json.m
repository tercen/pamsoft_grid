function [params, exitCode] = pg_io_read_params_json(params, jsonFile)
    exitCode = 0;

    if ~exist(jsonFile, 'file')
        exitCode = -1;
        pg_error_message(exitCode, jsonFile);
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

    catch 
        exitCode = -2;  
        pg_error_message(exitCode, jsonFile);
    end

end