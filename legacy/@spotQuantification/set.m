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
        case 'ID'
            q.ID = val;       
      
        case 'saturationLimit'
            if isnumeric(val)
                q.saturationLimit = val;
            else
                bInvalid = 1;
            end

        case 'oOutlier'
            if isa(val, 'outlier') | isempty(val)
                q.oOutlier = val;
    
            else
                bInvalid = 1;
            end
        case 'oSegmentation'
            if isa(val, 'segmentation')
                 q.oSegmentation = val;
            else
                bInvalid = true;
            end
        case 'oProperties'
            if isa(val, 'spotProperties')
                q.oProperties = val;
            else
                bInvalid = true;
            end

        case 'rotation'
            if isnumeric(val) & numel(val) == 1
                q.rotation = val;
            else
                bInvalid = true;
            end
  
        case 'cx'
            if isnumeric(val) && length(val) == 1
                q.cx = val;
            else
                bInvalid = 1;
            end
          case 'cy'
            if isnumeric(val) && length(val) == 1
                q.cy = val;
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
