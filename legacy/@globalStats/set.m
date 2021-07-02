function g = set(g, varargin)
pArgin = varargin;

for i=1:2:length(pArgin)
    bInvalid = 0;
    if length(pArgin) < i+1
        error('set function expects property / value pairs as input');
    end
    prop = pArgin{i};
    val =  pArgin{i+1};
    switch prop
        case 'odSigmaFac'
            if isnumeric(val)
                g.odSigmaFac = val;
            else
                bInvalid = 1;
            end
        case 'odEpsilon'
            if isnumeric(val)
                g.odEpsilon = val;
            else
                bInvalid = 1;
            end
        case 'bLocalT'
            if isnumeric(val)
                g.bLocalT = val;
            else
                bInvalid = 1;
            end
       case 'bLocalCV'
            if isnumeric(val)
                g.bLocalCV = val;
            else
                bInvalid = 1;
            end
        case 'bGlobalMetrics'
            if isnumeric(val)
                g.bGlobalMetrics = val;
            else
                bInvalid = 1;
            end
        case 'badWells'
            if islogical(val)
                g.badWells = val;
            else
                bInvalid = 1;
            end
        case 'pOut'
            if val >= 0 & val <= 1
                g.pOut = val;
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
