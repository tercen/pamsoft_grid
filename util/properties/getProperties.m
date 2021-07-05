function pdef = getProperties
% global prpContrast
% global prpLargeDisk
% global prpSmallDisk
% global prpResize
% global grdRow
% global grdCol
% global grdIsReference
% global grdRotation
% global grdSpotPitch
% global grdSpotSize
% global grdXOffset
% global grdYOffset
% global grdUseImage
% global grdXFixedPosition
% global grdYFixedPosition
% global grdSearchDiameter
% global grdOptimizeSpotPitch
% global grdOptimizeRefVsSub;
% global segEdgeSensitivity
% global segAreaSize
% global sqcMaxDiameter
% global sqcMinDiameter
% global sqcMaxPositionOffset
% global qntSpotID
% global qntSeriesMode
% global qntSaturationLimit
% global qntOutlierMethod
% global qntOutlierMeasure
% global qntShowPamGridViewer
% global stateQuantification
%
pdef(1).name    = 'prpContrast';
pdef(1).string  = 'Preprocessing, contrast';
pdef(1).dft     = uint8(0);
pdef(1).enumVal = uint8([0,1,2]);
pdef(1).enumMap = {'co-equalize', 'equalize', 'linear'};
%
pdef(2).name    = 'prpLargeDisk';
pdef(2).string  = 'Preprocessing, size of large objects filter'; 
pdef(2).dft     = 0.51;
pdef(2).enumVal = [];
pdef(2).enumMap = [];
%
pdef(3).name    = 'prpSmallDisk';
pdef(3).string  = 'Preprocessing, size of small objects filter';
pdef(3).dft     = 0.17;
pdef(3).enumVal = [];
pdef(3).enumMap = [];
%
pdef(end+1).name = 'prpResize';
pdef(end).string = 'Preprocessing, size of preprocessed image';
pdef(end).dft   = [256,256];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdRow';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdCol';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdIsReference';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdRotation';
pdef(end).string = 'Global grid, rotation'; 
pdef(end).dft   = [-2:0.25:2];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdSpotPitch';
pdef(end).string = 'Global grid, spot pitch';
pdef(end).dft   = 17.7;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdSpotSize';
pdef(end).string = 'Global grid, spot size';
pdef(end).dft   = 0.66;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdSearchDiameter';
pdef(end).string = 'Global grid, search diameter';
pdef(end).dft   = 15;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdXOffset';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdYOffset';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdXFixedPosition';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdYFixedPosition';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'grdUseImage';
pdef(end).string = 'Global grid, use image for gridding';
pdef(end).dft   = int8(-3);
pdef(end).enumVal = int8([-3,-2,-1, 0]);
pdef(end).enumMap = {'FirstLast', 'Last', 'First', 'All'} ;
%
pdef(end+1).name = 'grdOptimizeSpotPitch';
pdef(end).string = 'Global grid, optimize spot pitch';
pdef(end).dft = uint8(1);
pdef(end).enumVal = uint8([0,1]);
pdef(end).enumMap = {'no', 'yes'};
%
pdef(end+1).name = 'grdOptimizeRefVsSub';
pdef(end).string = 'Global grid, optimize reference vs. substrate array';
pdef(end).dft = uint8(0);
pdef(end).enumVal = uint8([0,1]);
pdef(end).enumMap = {'no', 'yes'};
%
pdef(end+1).name = 'segEdgeSensitivity';
pdef(end).string = 'Segmentation, edge sensitivity';
pdef(end).dft   = [0, 0.01];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'segAreaSize';
pdef(end).string = 'Segmentation, initial search are size';
pdef(end).dft   = 0.7;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'sqcMinDiameter';
pdef(end).string = 'Spot QC, minimal spot diameter';
pdef(end).dft   = 0.45;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'sqcMaxDiameter';
pdef(end).string = 'Spot QC, maximal spot diameter';
pdef(end).dft   = 0.85;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'sqcMinSnr';
pdef(end).string = 'Spot QC, minimal signal to noise ratio';
pdef(end).dft = 1;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'sqcMaxPositionOffset';
pdef(end).string = 'Spot QC, maximal deviation from exoected position';
pdef(end).dft = 0.4;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'sqcMaxPositionOffsetRefs';
pdef(end).string = 'Spot QC, maximal deviation from exoected position';
pdef(end).dft = 0.6;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'qntSpotID';
pdef(end).dft   = [];
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'qntSeriesMode';
pdef(end).string = 'Quantification, handling of image series';
pdef(end).dft   = uint8(0);
pdef(end).enumVal = uint8([0,1]);
pdef(end).enumMap = {'Fixed', 'Adapt Global'};
%
pdef(end+1).name = 'qntSaturationLimit';
pdef(end).string = 'Quantification, saturation limit';
pdef(end).dft   = -1 + 2^16;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'qntOutlierMethod';
pdef(end).string = 'Quantification, method for outlier detection';
pdef(end).dft   = uint8(1);
pdef(end).enumVal = uint8([0,1]);
pdef(end).enumMap = {'none', 'iqrBased'};
%
pdef(end+1).name = 'qntOutlierMeasure';
pdef(end).string = 'Quantification, measure for outlier detection';
pdef(end).dft   = 1.75;
pdef(end).enumVal = [];
pdef(end).enumMap = [];
%
pdef(end+1).name = 'qntShowPamGridViewer';
pdef(end).string = 'Show Pamgrid viewer';
pdef(end).dft = uint8(0);
pdef(end).enumVal = uint8([0,1,2]);
pdef(end).enumMap = {'No','Show, Wait for Close', 'Show and Continue'};



