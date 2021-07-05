function p = set(p, varargin)
pArgin = varargin;


% p.modelName = model;
% p.modelObj  = f;
% p.iniPars   = [];
% p.lbPars    = [];
% p.ubPars    = [];
% p.fitMethod = 'Normal';
% p.jacobian  = 'on'
% p.xOffset   = 0;
% p.maxIterations = 100;
% p.TolX = 1e-2;

fDef    = get(p.modelObj);
nPars   = length(fDef.clParameter);    



for i=1:2:length(pArgin)
    
    if length(pArgin) < i+1
        error(['set function expect property / value pairs'])
    end
    
    
    pName = pArgin{i};
    pVal  = pArgin{i+1};
    
    
    if isequal(pName, 'iniPars')
        
        if length(pVal == length(fDef.clParameter))
            p.iniPars = pVal;
        else
            error([p.model, ' expects exactly ', num2str(nPars), ' parameters.']);
        end
    
    
    elseif isequal(pName, 'lbPars')
        
        if length(pVal == length(fDef.clParameter))
            p.lbPars = pVal;
        else
            error([p.model, ' expects exactly ', num2str(nPars), ' lower bounds.']);
        end
    
    
    elseif isequal(pName, 'ubPars')
        if length(pVal == length(fDef.clParameter))
            p.ubPars = pVal;
        else
            error([p.model, ' expects exactly ', num2str(nPars), ' upper bounds.']);
        end
    
    elseif isequal(pName, 'fitPars')
        if length(pVal == length(fDef.clParameter))
            p.fitPars = pVal;
        else
            error([p.model, ' expects exactly ', num2str(nPars), ' logicals for fitPars']);
        end
        
    elseif isequal(pName, 'fitMethod')
        if isequal(pVal, 'Normal')|isequal(pVal, 'Robust')|isequal(pVal, 'Robust2')|isequal(pVal, 'Filter')
            p.fitMethod = pVal;
        else
            error('value for fitMethod must be ''Normal'', ''Robust'', ''Robust2'', or ''Filter''');
        end
    elseif isequal(pName, 'jacobian')
        switch pVal
            case 'on'
                if ~fDef.jacFlag
                    warning(['jacobian is not available for this fit model: value is set to ''off''.'])   
                    p.jacobian = 'off';
                else
                    p.jacobian = 'on';
                end
            case 'off'
                p.jacobian = 'off';
            otherwise
                error(['jacobian can only have the values ''on'' or ''off''']);
        end
    
    elseif isequal(pName, 'maxIterations')
        p.maxIterations = pVal;
        

     elseif isequal(pName, 'TolX')
        p.TolX      = pVal;
    
    elseif isequal(pName, 'TolMode')
        if isequal(pVal, 'Relative') | isequal(pVal, 'Absolute') 
            p.TolMode   = pVal;
        else
            error(['Value of Property TolMode must be either ''Relative'' or ''Absolute'''])
        end
    
    elseif isequal(pName, 'robTune')
        p.robTune = pVal;
    
    elseif isequal(pName, 'errorMethod')
        if isequal(pVal, 'ASE')
            p.errorMethod = pVal;
        else
            error(['Invalid value for errorMethod property'])
        end
    
    
    else
        error(['invalid property: ', pName])
    end
    
   
    
end


        
        
        
    
        
        
