function exitCode = pg_read_in_grid_results(params)
    exitCode = 1;
    if ~isfield(params, 'griddingOutput')
        % Output file from gridding output must be defined
        exitCode = -1;
        return
    end
    
    grid = readtable(params.griddingOutput);


    global grdRow;
    global grdCol;
    global grdXOffset;
    global grdYOffset;
    global grdXFixedPosition;
    global grdYFixedPosition;
    global qntSpotID;
    global grdIsReference;
    
    grdRow     = grid.ROW;
    grdCol     = grid.COL;
    grdXOffset = grid.XOffset;
    grdYOffset = grid.YOffset;
    grdXFixedPosition = grid.XFixedPos;
    grdYFixedPosition = grid.YFixedPos;
    qntSpotID         = grid.ID;
    grdIsReference    = grid.IsREF;
    
end