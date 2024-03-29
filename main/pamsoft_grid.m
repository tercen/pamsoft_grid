function pamsoft_grid(arglist)
fprintf( 'Running PG version: %d.%d.%d\n', 1,0,26 );

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
        [inParams, ~]      = pg_io_read_params_json(params,  params.paramfile);
        [params, exitCode] = pg_grd_gridding(params);


        % Override a few internal fields
        tmpParams = params;
        params    = inParams;
        

        params.gridX       = tmpParams.gridX;
        params.gridY       = tmpParams.gridY;
        params.grdMx       = tmpParams.grdMx;
        saveRotation       = tmpParams.grdRotation;
        params.grdRotation = tmpParams.grdRotation(1);

        params.rsf = tmpParams.rsf;
        
    end
    
%     pg_dbg_plot_grid(params); colormap jet;
    
    if exitCode == 0
        [params, exitCode] = pg_seg_segment_image(params);
    end

%     %% Debugging code
%     pg_dbg_plot_grid(params, 'imgSeg', 'plotCircle');
    %%
    
    if exitCode == 0
        params.grdRotation = saveRotation;
        exitCode = pg_io_save_params(params, {...
                        'qntSpotID', 'grdIsReference',  ...
                        'grdRow', 'grdCol', ...
                        'grdXFixedPosition', 'grdYFixedPosition', ...
                        'gridX', 'gridY', ...
                        'diameter', 'isManual', ...
                        'segIsBad', 'segIsEmpty', ...
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

    if exitCode == 0
        [params, exitCode] = pg_seg_segment_image(params);
    end
    
    %imagesc(params.images); hold on;
    %circle(params.spots(142).finalMidpoint(2), params.spots(142).finalMidpoint(1),8)
    % pg_dbg_plot_grid(params, 'imgSeg', 'plotCircle');

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
    
    [~, qTypes, qntTbl] = pg_qnt_parse_results(params);


    
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


function h = circle(x,y,r)
        hold on
        th = 0:pi/50:2*pi;
        xunit = r * cos(th) + x;
        yunit = r * sin(th) + y;
        h = plot(xunit, yunit);
        hold off
end
