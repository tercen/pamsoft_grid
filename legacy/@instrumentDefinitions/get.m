function value = get(p, strField)

clNames = fieldnames(p);
if nargin == 1
    for i=1:length(clNames)
        if ~isequal(clNames{i}, 'private')
            value.(clNames{i}) = p.(clNames{i});
        end
    end    
else
    
    for i=1:length(clNames)
        if isequal(strField, clNames{i}) & ~isequal(clNames{i}, 'private')
            value = p.(clNames{i});
            return
        end

    end
    error([strField, ' is not a valid and public instrumentDefinition property']);
end
    
