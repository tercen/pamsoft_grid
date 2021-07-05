function oI = instrumentDefinitions(varargin)
if length(varargin)  == 1
    b = varargin{1};
    if isa(b, 'instrumentDefinition')
        oI = b;
        return
    else
        error(['Cannot create an instrumentDefinition from object of class: ', class(b)]);
    end
end

oI.path  = [];
oI.fExtension = '.instrument';

oI = class(oI, 'instrumentDefinitions');
if length(varargin) > 1
    oI = set(oI, varargin{:});
end
