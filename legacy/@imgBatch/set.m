function b = set(b, varargin)
pArgin = varargin;

for i=1:2:length(pArgin)
    bInvalid = 0;
    if length(pArgin) < i+1
        error('set function expects property / value pairs as input');
    end
    prop = pArgin{i};
    val =  pArgin{i+1};
    switch prop
        case 'pathImageResults'
            if ischar(val)
                b.pathImageResults = val;
            else
                bInvalid = 1;
            end
          case 'pathTemplate'
            if ischar(val)
                b.pathTemplate = val;
            else
                bInvalid = 1;
            end
        case 'pathConfiguration'
            if ischar(val)
                b.pathConfiguration= val;
            else
                bInvalid = 1;
            end
        case 'nChannel'
            if isnumeric(val)
                b.nChannel = val;
            else
                bInvalid = 1;
            end
        case 'channelName'
            if ischar(val)
                b.channelName = val;
            else
                bInvalid = 1;
            end
        case 'instrument'
            if ischar(val)
                b.instrument = val;
            else
                bInvalid = 1;
            end
        case 'gridMode'
            if ischar(val)
                b.gridMode = val;
            else
                bInvalid = 1;
            end
        case 'batchID'
            if ischar(val)
                b.batchID = val;
            else
                bInvalid = 1;
            end
        
        case 'imageFilter'
            if ischar(val)
                b.imageFilter = val;
            else
                bInvalid = 1;
            end
        case 'combineExposures'
            if isnumeric(val)
                b.combineExposures = logical(val);
            else
                bInvalid = 1;
            end
        case 'adjustSpots'
            if isnumeric(val)
                b.adjustSpots = logical(val);
            else
                bInvalid = 0;
            end
            
        case 'log'
            b.log = val;
        case 'ppObj'
            if isa(val, 'preProcess') 
               b.ppObj = val;
            elseif isempty(val)
               b.ppObj = [];
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
