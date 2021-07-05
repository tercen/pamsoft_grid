function d = dataSet(varargin)
if length(varargin) == 1
    b = varargin{1};
    if isa(b, 'dataSet')
        d = b;
    else
        error(['Cannot create a dataset from an object of class: ', class(b)]);
    end
end
d.path = [];
d.instrument = [];
d.filter = '*.tif*';
d.list = [];
d.forceStructure = 1;
d.imageSize = [];


d = class(d, 'dataSet');
if length(varargin) > 1
    d = set(d, varargin{:});
end
