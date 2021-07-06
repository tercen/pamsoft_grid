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
params = parse_arguments(arglist);

% Populate with default values
[params, exitCode] = pg_read_params_json(params, 'default.json');
params.grdPrivate  = [];
if exitCode == 0
    % Overwrite specific fields with user-defined values
    [params, exitCode] = pg_read_params_json(params,  params.paramfile);
end




if exitCode == 0
    [params, exitCode] = pg_io_read_images_list(params);
end




% First mode of execution: image preprocessing & gridding
if strcmpi(params.mode, 'grid') && exitCode == 0
    % Read grid layout information
    [params, exitCode] = pg_grd_read_layout_file(params, '#');
    

    if exitCode == 0
        [params, exitCode] = pg_grd_preprocess_images(params);
    end
    
    if exitCode == 0
        [params, exitCode] = pg_grd_gridding(params);
    end
    
   
    if exitCode == 0
%         params
        exitCode = pg_io_save_params(params, { 'grdRow', 'grdCol', ...
                        'grdXOffset', 'grdYOffset', ...
                        'grdXFixedPosition', 'grdYFixedPosition', ...
                        'qntSpotID', 'grdIsReference', ...
                        'grdRot', 'grdSortOrder', 'grdImageUsed'} );
    end
    
    
    % @FIXME 
    % Quantification uses some information which cannot be saved in a
    % single text file, at least not easily.
    %
    % For the time being, I am saving the params structure, but this needs
    % to be discussed
%     save(strrep(params.outputfile, '.txt','.mat'), 'params');
end


if strcmpi(params.mode, 'quantification')
    % See @FIXME above
    % The load command will be replaced by the function below which should
    % properly read the information into the params structure, likely from
    % a text file
    %     [params, exitCode] = pg_io_read_in_gridding_results(params);
%     load( strrep(params.outputfile, '.txt','.mat') );
    
    [params, exitCode] = pg_read_params_json(params,  params.griddingOutput);
%     params
    if exitCode == 0
%         params
        pg_qnt_segment_image(params);
        
    end
%         pg_preprocess_images(params);
%         params
%         qt = analyzeimageseries(params.sorted_imageslist);
%         qt
    


%     params
end



fprintf('Program finished with error code %d\n', exitCode);

end % END of function pamsoft_grid



function params = parse_arguments(argline)
    % Split the multiple arguments
    % Arguments are being validated in the bash script, so we can assume
    % the correct number of args, as well as their formatting
    argStrIdx = strfind(argline, '--');
    
    nArgs     = length(argStrIdx);

    params = struct;
    
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