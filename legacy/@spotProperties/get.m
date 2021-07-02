function value = get(p, strField)

clNames = fieldnames(p);
if nargin == 1
    value = struct(p);
    if isfield(value, 'private')
        value = rmfield(value, 'private');
    end
else
    for i=1:length(clNames)
        if isequal(strField, clNames{i}) & ~isequal(clNames{i}, 'private')
            [n, m] = size(p);
            value = [p(:).(clNames{i})];
            value = reshape(value, n,m, length(value));
            return
        end

    end
    error([strField, ' is not a valid and public spotQuantification property']);
end
    
