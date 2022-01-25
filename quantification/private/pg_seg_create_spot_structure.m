function spot = pg_seg_create_spot_structure(params)
    fieldNames = {'segMethod', 'segAreaSize', 'grdSpotPitch', ...
        'segNFilterDisk', 'segEdgeSensitivity', 'segMinEdgePixels', ...
        'segBgOffset', 'initialMidpoint', 'finalMidpoint', 'diameter', ...
        'chisqr', 'bsLuIndex', 'bsSize', 'bsTrue', 'bbTrue', 'isFound' };

    fieldDefaultValues = { 'Edge', params.segAreaSize, params.grdSpotPitch, 0, params.segEdgeSensitivity, 6, 0.45, ...
            [],[],0.6*params.grdSpotPitch,[],[],[],[],[], 0};


    spot = struct;    
    for k = 1:length(fieldNames)
        fName = fieldNames{k};
        if isfield(params, fName)
            spot.(fName) = params.(fName);
        else
            spot.(fName) = fieldDefaultValues{k};
        end

    end
end