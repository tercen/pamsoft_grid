function p = set(p, varargin)
pArgin = varargin;

for i=1:2:length(pArgin)
    bInvalid = 0;
    if length(pArgin) < i+1
        error('set function expects property / value pairs as input');
    end
    prop = pArgin{i};
    val =  pArgin{i+1};
    switch prop
        case 'nSmallDisk'
            if isnumeric (val)
                if round(val) < 0
                    bInvalid = 1;
                end
                
                p.nSmallDisk = round(val);
 
            else
                bInvalid = 1;
            end
        case 'nLargeDisk'
            if isnumeric(val)
                 if round(val) < 0
                    bInvalid = 1;
                end
                
                p.nLargeDisk = round(val);
            else
                bInvalid = 1;
            end
        case 'nCircle'
            if isnumeric(val)
               
                
                p.nCircle = round(val);
            else
                bInvalid = 1;
            end

        case 'contrast'
            if isequal(val, 'linear')
                p.contrast = val;
            elseif isequal(val, 'equalize')
                p.contrast = val;
            elseif isequal(val, 'co-equalize')
                p.contrast = val;
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
