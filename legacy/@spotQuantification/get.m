function value = get(p, strField)

clNames = fieldnames(p);
if nargin == 1
    value = struct(p);
    if isfield(value, 'private')
        value = rmfield(value, 'private');
    end
else
    for i=1:length(clNames)
        if isequal(strField, 'ignoredMask')
            value = getIgnoredMask(p);  
            return
        elseif isequal(strField, clNames{i}) && ~isequal(clNames{i}, 'private')
            %[n, m] = size(p);
            [value{1:length(p(:))}]  = deal(p(:).(clNames{i}));
            value = reshape(value, size(p));
            if isnumeric(p(1).(clNames{i})) ||  islogical(p(1).(clNames{i}))
                value = cell2mat(value);
            end    
            return
        end

    end
    error([strField, ' is not a valid and public spotQuantification property']);
end
    
