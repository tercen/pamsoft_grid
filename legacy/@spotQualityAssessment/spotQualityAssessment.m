function o = spotQualityAssessment(varargin)


if length(varargin) == 0
  % initialize empty object
  stro = setProps([]);
 
elseif length(varargin) > 0 && isa(varargin{1}, 'spotQualityAssesment')
    o = varargin{1};
    stro = setProps(get(o), varargin{2:end});
elseif length(varargin) > 0 && ~isa(varargin{1}, 'spotQualityAssesment')
    stro = setProps([], varargin{:});
end

o = class(stro, 'spotQualityAssessment');

function stro = setProps(stro, varargin)
propdef.maxDiameter = 1.5;
propdef.minDiameter = 0.5;
propdef.maxOffset   = 0.4;
propdef.minSnr      = 1;

stro = setVarArginOptions(propdef, stro, varargin{:});
