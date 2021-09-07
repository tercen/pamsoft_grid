function exitCode = pg_io_save_params(params, fields)

    exitCode = 0;
    
    if ~isfield(params, 'outputfile')
        exitCode = -11;
        pg_error_message(exitCode, 'outputfile');
        return;
    end

    [filepath, ~, ~] = fileparts(params.outputfile);
    
    if ~exist(filepath, 'dir')
        mkdir(filepath);
    end
    
    
    nFields = length(fields);
    lFields = -1;
    
    
    for i = 1:nFields
       
        if ~isfield( params, fields{i} )
            exitCode = -18;
            pg_error_message(exitCode, fields{i});
            return;
        end
        
        if lFields == -1
            lFields = length(params.(fields{i}));
        end
        
        if length(params.(fields{i})) ~= lFields
            exitCode = -19;
            pg_error_message(exitCode, fields{i});
            return;
        end
    end
    

    tbl = table();
    
    for i = 1:nFields

        tbl.(fields{i}) = params.(fields{i});
    end
    

    
    writetable(tbl, params.outputfile );
    

end