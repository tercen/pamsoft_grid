function o = combineExposureTimes(varargin)
if length(varargin) == 1
    oIn = varargin{1};
    if isa(oIn, 'combineExposureTimes')
        o = oIn;
        return;
    else
        error(['cannot create an combineExposureTimes object from an object of class: ', class(oIn)]);
    end
end

o.combinationCriterium = [];
o.criteriumParity = 1;

o = class(o, 'combineExposureTimes');
if ~isempty(varargin)
    o = set(o, varargin{:});
end
