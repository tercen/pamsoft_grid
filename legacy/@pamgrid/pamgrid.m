function o = pamgrid(varargin)
% high level class for analyzing pamgrid images

if length(varargin) == 0
  % initialize empty object
  stro = setProps([]);
 
elseif length(varargin) > 0 && isa(varargin{1}, 'pamgrid')
    o = varargin{1};
    stro = setProps(get(o), varargin{2:end});
elseif length(varargin) > 0 && ~isa(varargin{1}, 'pamgrid')
    stro = setProps([], varargin{:});
end

o = class(stro, 'pamgrid');

function stro = setProps(stro, varargin)
propdef.oPreprocessing = preProcess;
propdef.oArray = array;
propdef.oSegmentation = segmentation;
propdef.oSpotQuantification = spotQuantification;
propdef.oSpotQualityAssessment = spotQualityAssessment;
propdef.oRefQualityAssessment  = spotQualityAssessment;
propdef.gridImageSize = [256, 256];
propdef.optimizeSpotPitch = {'yes', 'no'};
propdef.optimizeRefVsSub = {'yes', 'no'};
propdef.useImage = {'Last', 'First', 'Refs on First then Last', 'All'};
propdef.seriesMode = {'Fixed', 'Adapt Global', 'Adapt Local', 'Adapt All'};
propdef.verbose = {'off', 'on'};
% propdef.prpContrast = {'co-equalize', 'equalize', 'linear'};
% propdef.prpLargeDisk = 0.51;
% propdef.prpSmallDisk = 0.17;
% propdef.prpResize = [256, 256];
% propdef.prpUseImage = {'Last', 'First', 'First then Last', 'All'};
% propdef.grdRotation = [-2:0.25:2];
% propdef.grdSpotPitch = 17.7;
% propdef.grdSpotSize = 0.66;
% propdef.grdSearchDiameter = 5;
% propdef.grdRow;
% propdef.grdCol;
% propdef.grdSpotID;
% propdef.grdIsReference;
% propdef.grdOptimizeSpotPitch = {'yes', 'no'};
% propdef.grdOptimizeRefVsSub = {'yes', 'no'};
% propdef.segEdgeSensitivity = [0, 0.01];
% propdef.segAreaSize = 0.7;
% propdef.sqcMaxDiameter = 0.85;
% propdef.sqcMinDiameter = 0.45;
% propdef.sqcMinFormFactor = 0.7;
% propdef.sqcMaxAspectRatio = 1.4;
% propdef.sqcMaxPositionOffset = 0.4;
% propdef.qntSeriesMode = {'Fixed', 'Adapt Global', 'Adapt Local', 'Adapt All'};
% propdef.qntSaturationLimit = 2^16;
% propdef.qntOutlierMethod = {'iqrBased', 'none'};
% propdef.qntOutlierMeasure = 1.75;

stro = setVarArginOptions(propdef, stro, varargin{:});
