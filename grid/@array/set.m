function g = set(g, varargin)
pArgin = varargin;

for i=1:2:length(pArgin)
    bInvalid = 0;
    if length(pArgin) < i+1
        error('set function expects property/value pairs as input');
    end
    prop = pArgin{i};
    val =  pArgin{i+1};
    switch prop
        case 'row'
         
            if isnumeric(val)
                g.row = val;
            else
                bInvalid = 1;
            end
        case 'col'
            if isnumeric(val)
                g.col = val;
            else
                bInvalid = 1;
            end  
         case 'isreference'
            if isnumeric(val) || islogical(val)
                g.isreference = val;
            else
                bInvalid = 1;
            end 
         case 'xOffset'
            if isnumeric(val)
                g.xOffset = val;
            else
                bInvalid = 1;
            end 
         case 'yOffset'
            if isnumeric(val)
                g.yOffset = val;
            else
                bInvalid = 1;
            end 
        case 'xFixedPosition'
            if isnumeric(val)
                g.xFixedPosition = val;
            else
                bInvalid = 1;
            end 
        case 'yFixedPosition'
             if isnumeric(val)
                g.yFixedPosition = val;
            else
                bInvalid = 1;
            end 
        case 'spotPitch'
            if isnumeric(val) & length(val) <= 2
                g.spotPitch = val;
            else
                bInvalid = 1;
            end
        case 'spotSize'
            if isnumeric(val) & length(val) == 1
                g.spotSize = val;
            else
                bInvalid = 1;
            end
        case 'rotation'
            if isnumeric(val)
                g.rotation = val;
            else
                bInvalid = 1;
            end
        case 'method'
            if isequal(val, 'correlation2D')
                g.method = val;
            else
                bInvalid = 1;
            end
        case 'ID'
            g.ID = val;
        case 'roiSearch'
            if islogical(val)
                g.roiSearch = val;
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
