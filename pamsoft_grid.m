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

%TODO create default.json with all default options and get them from there
% Right now, options are being used as strings, saved as numbers and mapped
% when needed
[params, exitCode] = pg_read_params_json(params);

if exitCode < 0
       disp('Error reading:')
       disp(params.paramfile);
     
       disp(exitCode);
       return
end


% Read in the image list
[params, exitCode] = pg_read_images_list(params);

%TODO check if reading the images ran well

% pg_image_analysis/PamSoft_Grid/com/grdFromFile.m
% 
% https://github.com/tercen/pg_image_analysis/blob/1b3e191210987687c4ae5fa6d623499acef99f1c/PamSoft_Grid/com/grdFromFile.m
% First mode of execution: image preprocessing & gridding
if strcmpi(params.mode, 'grid')
    % Read grid layout information
    %TODO Still relying on COM. Double check, but likely not anymore
    % Port all code into the grid folder
    params = pg_grd_from_layout_file(params, '#');
    
    %Preprocess image & calculate grid
    % TODO Pass a specific image. DONE
    pg_preprocess_images(params);
%    
    

end


if strcmpi(params.mode, 'quantification')
    % This function depends from the outcome of grdFromFile
%     params
    if( pg_read_in_grid_results(params) )
%         pg_preprocess_images(params);
%         params
%         qt = analyzeimageseries(params.sorted_imageslist);
%         qt
    end


%     params
end

% qt = analyzeimageseries(names(1:18));

end % END of function pamsoft_grid


% Helper function to print error messages without cluttering the main
% function
% errTypes: cell containing error key words
function print_error(errTypes)

    for i = 1:length(errTypes)
        errType = errTypes{i};
        
        fprintf('****** [ERROR %d] ******\n', i);
        
        if strcmp(errType, 'usage') == 0   
           fprintf('Incorrect usage of pamsoft_grid function.\n\n'); 
           fprintf('The following parameters are mandatory:\n'); 
           fprintf('mode: [grid, quantification]\n ');
           fprintf('param-file: [path to param file, .txt]\n ');
           fprintf('array-layout: [path to array layout, .txt]\n ');
           fprintf('images-list-file: [path to image list file, .json]\n ');
           fprintf('output-file: [path to output file, .txt]\n\n ');
           fprintf('EXAMPLE usage:\n ');
           fprintf('pamsoft_grid --mode=grid --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx\n\n ');
        end
        
        if strcmp(errType, 'pairs') == 0
            fprintf('All arguments must be specified as pairs\n');
            fprintf('E.g.: --mode=grid\n\n');
        end
        
        if strcmp(errType, 'images') == 0
            %@TODO add more meaningful error message
            fprintf('Error reading image list.\n');
        end
    end
    
    if length(errTypes) > 1
        fprintf('Multiple Errors Found\n');
    end
    
    fprintf('\nABORTING pamsoft_grid execution\n');
end


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