function grdFromFile(params, grdRefMarker)
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
% global sqcMaxPositionOffset
% global sqcMaxPositionOffsetRefs
% global sqcMinSnr
global qntSpotID
% global qntSeriesMode
% global qntSaturationLimit
% global qntOutlierMethod
% global qntOutlierMeasure
% global qntShowPamGridViewer
% global stateQuantification

if nargin < 2
    grdRefMarker = [];
end

oArray =  fromFile(array, params.arraylayoutfile, grdRefMarker);
qntSpotID = get(oArray, 'ID');
grdCol          = get(oArray, 'col');
grdRow          = get(oArray, 'row');
grdIsReference  = get(oArray, 'isreference');
grdXOffset = get(oArray, 'xOffset');
grdYOffset = get(oArray, 'yOffset');
grdXFixedPosition = get(oArray, 'xFixedPosition');
grdYFixedPosition = get(oArray, 'yFixedPosition');


tbl = table( qntSpotID, grdCol, grdRow, grdXOffset, grdYOffset, grdXFixedPosition, grdYFixedPosition, grdIsReference, ...
            'VariableNames', {'ID', 'ROW', 'COL', 'XOffset', 'YOffset', 'XFixedPos','YFixedPos','IsREF'});

writetable( tbl,  params.outputfile, 'Delimiter', ',');
