function o = outlier(varargin)
if length(varargin) == 1
    oIn = varargin{1};
    if isa(oIn, 'outlier')
        o = oIn;
        return;
    else
        error(['cannot create an oulier object from an object of class: ', class(oIn)]);
    end
end
o.method        = 'iqrBased';
o.measure       = 1.5;

o = class(o, 'outlier');
if ~isempty(varargin)
    o = set(o, varargin{:});
end
