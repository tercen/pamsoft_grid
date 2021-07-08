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

    
    params.grdRow            = gridTable.grdRow;
    params.grdCol            = gridTable.grdCol;
    params.grdXOffset        = gridTable.grdXOffset;
    params.grdYOffset        = gridTable.grdYOffset;
    params.grdXFixedPosition = gridTable.grdXFixedPosition;
    params.grdYFixedPosition = gridTable.grdYFixedPosition;
    params.qntSpotID         = gridTable.qntSpotID;
    params.grdIsReference    = gridTable.grdIsReference;
end