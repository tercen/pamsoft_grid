function d = set(d, varargin)
pArgin = varargin;

for i=1:2:length(pArgin)
    bInvalid = 0;
    if length(pArgin) < i+1
        error('set function expects property / value pairs as input');
    end
    prop = pArgin{i};
    val =  pArgin{i+1};
    switch prop
        case 'path'
            if ischar(val)
                d.path = val;
            else
                bInvalid = 1;
            end
        case 'instrument'
            if ischar(val)
                d.instrument = val;
            else
                bInvalid = 1;
            end
        case 'filter'
            if ischar(val)
                d.filter = val;
            else
                bInvalid = 1;
            end
        case 'forceStructure'
            if isnumeric(val)
                d.forceStructure = logical(val);
            else
                bInvalid = 1;
            end
                
        otherwise
            error(['Invalid property: ', prop]);
    end
    if bInvalid
        error(['Invalid value for :',prop]);
    end
end