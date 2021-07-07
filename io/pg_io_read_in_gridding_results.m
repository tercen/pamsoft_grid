function [params, exitCode] = pg_io_read_in_gridding_results(params)
    exitCode = 0;
    
    if ~isfield(params, 'qntGriddingOutput')
        % Output file from gridding output must be defined
        exitCode = -2001;
        pg_error_message('general.gridoutput.field', exitCode);
        return
    end
    
    
    if ~exist(params.qntGriddingOutput, 'file' )
        % Output file from gridding output must be defined
        exitCode = -2002;
        pg_error_message('general.gridoutput.exist', exitCode, params.qntGriddingOutput);
        return
    end
    
    try
        gridTable = readtable(params.griddingOutput);
    catch
        exitCode = -2003;
        pg_error_message('general.gridoutput.parse', exitCode, params.qntGriddingOutput);
        return
    end

    
    params.grdRow = gridTable.grdRow;
    params.grdCol = gridTable.grdCol;
    params.grdXOffset = gridTable.grdXOffset;
    params.grdYOffset = gridTable.grdYOffset;
    params.grdXFixedPosition = gridTable.grdXFixedPosition;
    params.grdYFixedPosition = gridTable.grdYFixedPosition;
    params.qntSpotID = gridTable.qntSpotID;
    params.grdIsReference = gridTable.grdIsReference;

    
end