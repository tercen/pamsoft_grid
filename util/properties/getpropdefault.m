function dftValue = getPropDefault(parName);
global prpContrast
global prpLargeDisk
global prpSmallDisk
global prpResize
global grdRow
global grdCol
global grdIsReference
global grdRotation
global grdSpotPitch
global grdSpotSize
global grdXOffset
global grdYOffset
global grdUseImage
global grdXFixedPosition
global grdYFixedPosition
global grdSearchDiameter
global grdOptimizeSpotPitch
global grdOptimizeRefVsSub;
global segEdgeSensitivity
global segAreaSize
global sqcMaxDiameter
global sqcMinDiameter
global sqcMaxPositionOffset
global sqcMaxPositionOffsetRefs
global sqcMinSnr
global qntSpotID
global qntSeriesMode
global qntSaturationLimit
global qntOutlierMethod
global qntOutlierMeasure
global qntShowPamGridViewer
global stateQuantification

pdef = getProperties();
[pnames{1:length(pdef)}] = deal(pdef.name);
iMatch = strmatch(parName, pnames, 'exact');
if ~isempty(iMatch)
    dftValue = pdef(iMatch).dft;
else
    dftValue = [];
end


