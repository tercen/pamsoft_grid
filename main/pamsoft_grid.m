function pamsoft_grid(arglist)

%fprintf("Running build from 202109211730\n")


[params, exitCode] = parse_arguments(arglist);




if exitCode == 0
    % Populate with default values
    [params, exitCode] = pg_io_read_params_json(params, 'default');
    
end



if exitCode == 0
    % Overwrite specific fields with user-defined values
    [params, exitCode] = pg_io_read_params_json(params,  params.paramfile);
end




% This is used both for grid and quantification modes
if exitCode == 0
    [params, exitCode] = pg_io_read_images_list(params);
end




% First mode of execution: image preprocessing & gridding
if exitCode == 0 && strcmpi(params.pgMode, 'grid') 
    % Read grid layout information
    [params, exitCode] = pg_grd_read_layout_file(params, '#');

    if exitCode == 0
        [params, exitCode] = pg_grd_preprocess_images(params, true, false);
    end


    
    if exitCode == 0
%             preprocParams = params;
            
            [params, exitCode] = pg_grd_gridding(params);
            
            [inParams, ~] = pg_io_read_params_json(params,  params.paramfile);

            % Override a few internal fields
            tmpParams = params;
            params    = inParams;
            params.gridX = tmpParams.gridX;                   
            params.gridY = tmpParams.gridY;
            params.grdMx = tmpParams.grdMx;
            saveRotation = tmpParams.grdRotation;
            params.grdRotation = tmpParams.grdRotation(1);
            params.prpNSmallDisk = round( params.prpSmallDisk * params.grdSpotPitch );
            params.prpNLargeDisk = round( params.prpLargeDisk * params.grdSpotPitch );
            params.grdSpotSize   = params.grdSpotSize * params.grdSpotPitch;
    end


             
    
    if exitCode == 0
        [params, exitCode] = pg_seg_segment_image(params);
        
        for i = 1:length(params.spots)
           params.grdXOffset(i) = params.spots(i).initialMidpoint(1)-params.spots(i).finalMidpoint(1);
           params.grdYOffset(i) = params.spots(i).initialMidpoint(2)-params.spots(i).finalMidpoint(2);
        end
        
    end

    
    
    if exitCode == 0
        params.grdRotation = saveRotation;
        exitCode = pg_io_save_params(params, {...
                        'qntSpotID', 'grdIsReference', ...
                        'grdRow', 'grdCol', ...
                        'grdXOffset', 'grdYOffset', ...
                        'grdXFixedPosition', 'grdYFixedPosition', ...
                        'gridX', 'gridY', ...
                        'diameter', 'segOutliers', 'isManual', ...
                        'segIsBad', 'segIsReplaced', 'segIsEmpty', ...
                        'grdRotation', ...
                        'grdImageNameUsed'} );
    end

    
    if strcmpi(params.dbgPrintOutput, 'yes')
        disp(readlines(params.outputfile));
    end
    

end


if exitCode == 0 && strcmpi(params.pgMode, 'quantification')
    
    if exitCode == 0
        [params, exitCode] = pg_io_read_in_gridding_results(params);
    end

    
    if exitCode == 0
        [params, exitCode] = pg_grd_preprocess_images(params, false, true);
    end
    

%     return
    if exitCode == 0
        [params, exitCode] = pg_seg_segment_image(params);
    end
    
    
    if exitCode == 0
        [params, exitCode] = pg_qnt_quantify(params);  
    end

    if exitCode == 0
         [params, exitCode] = pg_qnt_check_quantification(params);
    end
    
    
    
    if exitCode == 0
        idxUnsort(params.grdSortOrder) = 1:length(params.grdSortOrder);
        params.quant  =  params.quant(:, idxUnsort);
        I             = params.images(:,:,idxUnsort);
        expTime       = params.expTime(idxUnsort);
        cycles        = params.cycles(idxUnsort);
        
    end
    
    [~, qTypes, ~] = pg_qnt_parse_results(params);

    %permute qTypes from: Spot-QuantitationType-Array 
    % % to : Array-Spot-QuantitationType
    qTypes = permute(qTypes, [3,1,2]);
    if strcmpi(params.dbgShowPresenter, 'yes') 
        if length(unique(cycles))> 1
            x = cycles;
        else
            x = expTime;
        end
        qTypes = permute(qTypes, [1,3,2]);
        params.qTypes= qTypes;
        hViewer = presenter(I, params, x);
        
        set(hViewer, 'Name', 'PamGridViewer');
        uiwait(hViewer);
    end
    
end
    


if exitCode ~= 0
    error('Program finished with code %d\n', exitCode);
end



end % END of function pamsoft_grid



function [params, exitCode] = parse_arguments(argline)
    exitCode = 0;
    params   = struct;
    if isempty(argline)
        exitCode = -1000;
        pg_error_message(exitCode);
        return
    end
    
    argStrIdx   = strfind(argline, '--');
    argStrValid = regexp(argline, '--param-file=.+', 'ONCE');
    
    if isempty(argStrValid) 
        exitCode = -1000;
        pg_error_message(exitCode);
        return
    end

    nArgs     = length(argStrIdx);

    for i = 1:nArgs-1
        arg = argline(argStrIdx(i)+2:argStrIdx(i+1)-1);
        arg = strrep(arg, '-', '');
        
        if contains( arg, '=' ) 
            [argName, argVal] = strtok(arg, '=');
        else
            [argName, argVal] = strtok(arg, ' ');
        end
        
        params.(argName) = strtrim(argVal(2:end));
       
    end
    
    arg = argline(argStrIdx(end)+2:end);
    arg = strrep(arg, '-', '');
    
    if contains( arg, '=' ) 
        [argName, argVal] = strtok(arg, '=');
    else
        [argName, argVal] = strtok(arg, ' ');
    end

    params.(argName) = strtrim(argVal(2:end));
end