function s = set(s, varargin)
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
            if isequal(val, 'Threshold')
                s.method = val;
            elseif isequal(val, 'Edge');
                s.method = val;
            
            elseif isequal(val, 'test')
                s.method = val;
            
            else
                bInvalid = 1;
            end
       
        case 'areaSize'
            if isnumeric(val) & length(val) == 1
                s.areaSize  = val;
            else
                bInvalid = 1;
            end
  
     
        case 'nFilterDisk'
            if isnumeric(val)
                s.nFilterDisk = val;
            else
                bInvalid = 1;
            end

        case 'edgeSensitivity'
            if isnumeric(val) && numel(val) == 2
                s.edgeSensitivity = val;
            else
                bInvalid = true;
            end
            
    
        case 'spotPitch'
            if isnumeric(val)
                s.spotPitch = val;
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
