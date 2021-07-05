function value = get(g, strField)

clNames = fieldnames(g);
if nargin == 1
    for i=1:length(clNames)
        if ~isequal(clNames{i}, 'private')
            value.(clNames{i}) = g.(clNames{i});
        end
    end    
else
    
    for i=1:length(clNames)
        if isequal(strField, clNames{i}) & ~isequal(clNames{i}, 'private')
            value = g.(clNames{i});
            return
        end

    end
    error([strField, ' is not a valid and public grid property']);
end
    
