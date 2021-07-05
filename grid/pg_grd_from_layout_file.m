function params = pg_grd_from_layout_file(params, grdRefMarker)
% global prpContrast
% global prpLargeDisk
% global prpSmallDisk
% global prpResize
global grdRow
global grdCol
global grdIsReference
% global grdRotation
% global grdSpotPitch
% global grdSpotSize
global grdXOffset
global grdYOffset
% global grdUseImage
global grdXFixedPosition
global grdYFixedPosition
% global grdSearchDiameter
% global grdOptimizeSpotPitch
% global grdOptimizeRefVsSub;
% global segEdgeSensitivity
% global segAreaSize
% global sqcMaxDiameter
% global sqcMinDiameter
% global sqcMinFormFactor
% global sqcMaxAspectRatio
% global sqcMaxPositionOffset
global qntSpotID
% global qntSeriesMode
% global qntSaturationLimit
% global qntOutlierMethod
% global qntOutlierMeasure
% global qntShowPamGridViewer
% global stateQuantification


oArray            =  fromFile(array, params.arraylayoutfile, grdRefMarker);
qntSpotID         = get(oArray, 'ID');
grdCol            = get(oArray, 'col');
grdRow            = get(oArray, 'row');
grdIsReference    = get(oArray, 'isreference');
grdXOffset        = get(oArray, 'xOffset');
grdYOffset        = get(oArray, 'yOffset');
grdXFixedPosition = get(oArray, 'xFixedPosition');
grdYFixedPosition = get(oArray, 'yFixedPosition');

params.qntSpotID = qntSpotID;
params.grdCol    = grdCol;
params.grdRow    = grdRow;
params.grdIsReference = grdIsReference;
params.grdXOffset   = grdXOffset;
params.grdYOffset   = grdYOffset;
params.grdXFixedPosition = grdXFixedPosition;
params.grdYFixedPosition = grdYFixedPosition;

% tbl = table(qntSpotID, grdCol, grdRow, grdIsReference, grdXOffset, grdYOffset, grdXFixedPosition, grdYFixedPosition, ...
%         'VariableNames', {'ID', 'ROW', 'COL', 'IsREF', 'XOffset', 'YOffset', 'XFixedPos', 'YFixedPos'} );
%     
%     
% writetable( tbl, params.outputfile );

