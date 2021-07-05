function q = set(q, varargin)
pArgin = varargin;

for i=1:2:length(pArgin)
    bInvalid = 0;
    if length(pArgin) < i+1
        error('set function expects property / value pairs as input');
    end
    prop = pArgin{i};
    val =  pArgin{i+1};
    
    switch prop
        case 'combinationCriterium'
            if isnumeric(val)
                q.combinationCriterium = val;
            else
                bInvalid = 1;
            end
        case 'criteriumParity'
            if value == 1 | value == -1
                q.criteriumParity = val;
            else
                bInvalid = 1;
            end
            
                
        otherwise
            error(['Invalid property: ', prop]);
    end
    if bInvalid
        error(['Invalid value for : ',prop]);
    end
end
