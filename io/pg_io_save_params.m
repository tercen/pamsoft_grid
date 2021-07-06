function exitCode = pg_io_save_params(params, fields)

    exitCode = 0;
    
    if ~isfield(params, 'outputfile')
        exitCode = -80;
        pg_error_message('general.no_outputfile', exitCode);
        return;
    end

    nFields = length(fields);
    lFields = -1;
    
    
    for i = 1:nFields
        if ~isfield( params, fields{i} )
 
            exitCode = -81;
            pg_error_message('general.no_savefield', exitCode, fields{i});
            return;
        end
        
        if lFields == -1
            lFields = length(params.(fields{i}));
        end
        
        if length(params.(fields{i})) ~= lFields
            exitCode = -82;
            pg_error_message('general.save_length', exitCode, fields{i});
            return;
        end
    end
    
%     paramsOut = struct;
    
%     outMatrix = zeros(lFields, length(fields) );
    
    tbl = table();
    
    for i = 1:nFields

        tbl.(fields{i}) = params.(fields{i});
%         paramsOut.(fields{i}) = params.(fields{i});
    end
    
    
%     jsonTxt = jsonencode(paramsOut);
%     
%     
%     fid = fopen(params.outputfile,'wt');
%     fprintf(fid, pg_io_json_prettyprint(jsonTxt));
%     fclose(fid);
    
%     tbl = table(outMatrix);
%     
    
    writetable(tbl, params.outputfile );
    

end