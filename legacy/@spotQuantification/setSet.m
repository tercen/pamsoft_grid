function qOut = setSet(q0, varargin)
qProps = fieldnames(q0(1));
for i = 1:2:length(varargin)
    if length(varargin) < i+1;
        error('setSet function expects property/value pairs as imput arguments');
    end
    prop    = varargin{i};
    if ~any(strcmp(qProps, prop))
        error(['Invalid property: ', prop]);
    end

    val     = varargin{i+1};
    sVal = size(val);
    if numel(q0) ~= 1 && ~isequal(size(val), size(q0))
        error(['size of q0 does not correspond to that of the value array of property: ',prop])
    end
    
    if i==1
        % initialize
        for j=1:length(val(:))
            if iscell(val(j))
                setval = val{j};
            else
                setval = val(j);
            end
            if numel(q0) == 1   
                qOut(j) = q0;
            else                
                qOut(j) = q0(j);
            end
            qOut(j).(prop) = setval;
        end
    elseif ~isequal(size(qOut),size(val))
        error('all val arrays must have the same size');
    else
        % proceed with next
        for j=1:length(val(:))
            if iscell(val(j))
                setval = val{j};
            else
                setval = val(j);
            end
            qOut(j).(prop) = setval;
        end
    end
    qOut = reshape(qOut, sVal);
end
% EOF

