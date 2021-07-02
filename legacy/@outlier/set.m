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
        case 'method'
            if isequal(val, 'iqrBased')
               q.method = val;
            else
                bInvalid = 1;
            end
        case 'measure'
            if isnumeric(val)
                q.measure = val;
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
