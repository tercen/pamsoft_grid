function pamsoft_grid(arglist)
% 
% Compilation command
% mcc -m pamsoft_grid.m -d /media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/standalone -o pamsoft_grid -R -nodisplay
% RUN As
% ./run_pamsoft_grid.sh $MCR_ROOT "--mode=grid --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx"

% From the standalone folder
% ./../pamsoft_grid.sh  --mode=grid --param-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/input_test_1.json --array-layout-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/631158404_631158405_631158406 86312 Array Layout.txt --images-list-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/image_list_test_1.txt --output-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/output_test_1.txt

% from shell
% pamsoft_grid --mode=grid --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx
% if isempty(arglist) || ~ischar(arglist)
%     print_error('usage')
% end


disp('');
[params, exitCode] = parse_arguments(arglist);

if exitCode == 0
    % Populate with default values
    [params, exitCode] = pg_io_read_params_json(params, 'default');
    params.grdPrivate  = [];
end

if exitCode == 0
    % Overwrite specific fields with user-defined values
    [params, exitCode] = pg_io_read_params_json(params,  params.paramfile);
end


if exitCode == 0
    [params, exitCode] = pg_io_read_images_list(params);
end





% First mode of execution: image preprocessing & gridding
if exitCode == 0 && strcmpi(params.pgMode, 'grid') 
    % Read grid layout information
    [params, exitCode] = pg_grd_read_layout_file(params, '#');

    if exitCode == 0
        [params, exitCode] = pg_grd_preprocess_images(params, true);
    end

    if exitCode == 0
        [params, exitCode] = pg_grd_gridding(params);
    end
    
   
    if exitCode == 0
        exitCode = pg_io_save_params(params, {'qntSpotID', 'grdIsReference', ...
                        'grdRow', 'grdCol', ...
                        'grdXOffset', 'grdYOffset', ...
                        'grdXFixedPosition', 'grdYFixedPosition', ...
                        'gridX', 'gridY', 'grdRotation'} );
    end

    
    if strcmpi(params.dbgPrintOutput, 'yes')
        disp(readlines(params.outputfile));
    end
    

end


if exitCode == 0 && strcmpi(params.pgMode, 'quantification')

    % @TODO It is probably a good idea to validate the layout and ensure
    % the spot IDs of the quantification's array layout match those saved
    % by the gridding procedure
    if exitCode == 0
        [params, exitCode] = pg_io_read_in_gridding_results(params);
    end
    
    
    % The image for gridding and segmentation must be the same, so run this
    % part again, though the rescaling part is not necessary (second
    % argument)
    if exitCode == 0
        [params, exitCode] = pg_grd_preprocess_images(params, false);
    end
    

    if exitCode == 0
        [params, exitCode] = pg_seg_segment_image(params);
    end
    
    
    if exitCode == 0
        [params, exitCode] = pg_qnt_quantify(params);  
    end
    
    
    if exitCode == 0
        
%         flags = checkQuantification(params);
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
    if strcmpi(params.dbgShowPresenter, 'yes') % @TODO Pass this as parameter
        if length(unique(cycles))> 1
            x = cycles;
        else
            x = expTime;
        end
        qTypes = permute(qTypes, [1,3,2]);
        params.qTypes= qTypes;
        hViewer = presenter(I, params, x);
        
%         hViewer = showInteractive(stateQuantification, I, x);
        set(hViewer, 'Name', 'PamGridViewer');
%         if 1 == 1 %qntShowPamGridViewer == 1
        uiwait(hViewer);
%         end
    end
    
end
    


fprintf('Program finished with error code %d\n', exitCode);

end % END of function pamsoft_grid



function [params, exitCode] = parse_arguments(argline)
    exitCode = 0;
    params   = struct;
    if isempty(argline)
        exitCode = -1000;
        pg_error_message(exitCode);
        return
    end
    
    argStrIdx = strfind(argline, '--');

    if isempty(argStrIdx)
        exitCode = -1000;
        pg_error_message(exitCode);
        return
    end

    % @TODO Create regex validation of the parameter passed to ensure the
    % code below works with the expected format
    
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