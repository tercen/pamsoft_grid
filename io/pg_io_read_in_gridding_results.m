function [params, exitCode] = pg_io_read_in_gridding_results(params)
    exitCode = 0;
    
    if ~isfield(params, 'griddingoutputfile') || isempty(params.griddingoutputfile)
        % Output file from gridding output must be defined
        exitCode = -11;
        pg_error_message( exitCode, 'griddingoutputfile' );
        return
    end
    
    
    if ~exist(params.griddingoutputfile, 'file' )
        % Output file from gridding output must be defined
        exitCode = -1;
        pg_error_message( exitCode, params.griddingoutputfile, 'griddingoutputfile');
        return
    end
    
    try
        gridTable = readtable(params.griddingoutputfile);
    catch err
        exitCode = -20;
        pg_error_message( exitCode, params.griddingoutputfile, 'griddingoutputfile', err.message);
        return
    end

    inParams   = params;
    tblColumns = gridTable.Properties.VariableNames;
    
    for k = 1:length(tblColumns)
        params.(tblColumns{k}) = gridTable.(tblColumns{k});
    end
    
        
%     if isfield(params, 'isManual') && params.isManual(1) == 0
%         params.grdXFixedPosition = params.gridX;
%         params.grdYFixedPosition = params.gridY;
%     end

    params.grdRotation = params.grdRotation(1); 
    
end