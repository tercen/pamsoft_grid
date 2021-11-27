function [params, exitCode] = pg_io_read_params_json(params, jsonFile)
    exitCode = 0;

    
    if strcmpi(jsonFile, 'default')
        params = pg_io_get_default_params(params);
        
        return
    end
    
    
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



function params = pg_io_get_default_params(params)

    params.verbose = 'no'; % no, on, yes
    
    % PReprocessing properties
    params.prpContrast = 'co-equalize'; %co-equalize, equalize, linear
    params.prpLargeDisk   = 0.51;
    params.prpSmallDisk   = 0.17;
    params.prpResize      = [256, 256];
    params.prpNCircle     = -1;
    
    % Gridding properties
    params.grdRow            = [];
    params.grdCol            = [];
    params.grdIsReference    = [];
    params.grdRotation       = -2:0.1:2;
    params.grdSpotPitch      = 17.7;
    params.grdSpotSize       = 0.66;
    params.grdSearchDiameter = 15;
    params.grdXOffset        = [];
    params.grdYOffset        = [];
    params.grdXFixedPostion  = [];
    params.grdYFixedPostion  = [];
    params.grdUseImage       = 'Last'; %Last, First, FirstLast, All, EXPOSURE_CYCLE
    params.grdOptimizeSpotPitch = 'yes';
    params.grdOptimizeRefVsSub  = 'no';
    params.gridImageSize        = [256, 256];
    params.grdMethod            = 'correlation2D';
    
    
    % Segmentation properties
    params.segEdgeSensitivity = [0, 0.05];
    params.segAreaSize        = 0.9;
    params.segMethod          = 'Edge';
    params.segNFilterDisk     = 0;
%     params.segEdgeSensitivity = [0, 0.005];
    params.segMinEdgePixels   = 6;
    params.segBgOffset        = 0.45;
    
    
    % Spot quality check properties
    params.sqcMinDiameter           = 0.45;
    params.sqcMaxDiameter           = 0.85;
    params.sqcMinSnr                = 1;
    params.sqcMaxPositionOffset     = 0.4;
    params.sqcMaxPositionOffsetRefs = 0.6;


    %Quantification properties
    params.qntSpotID            = [];
    params.qntSeriesMode        = 'Fixed'; %Fixed, AdaptGlobal
    params.qntSaturationLimit   = 2^12 -1; % 2-1 + 2^16;
    params.qntOutlierMethod     = 'iqrBased'; % none, iqrBased
    params.qntOutlierMeasure    = 1.75;
    params.qntShowPamGridViewer = 'no';
    
    
    
    % General properties
    params.pgMode = 'grid';
    params.arraylayoutfile = '';
    params.outputfile = '';
    params.imageslist = '';
    params.dbgPrintOutput = 'no';
    params.dbgShowPresenter = 'no';

    params.grdPrivate  = [];
   
    
end