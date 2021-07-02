function value = get(f, strField)

clNames = fieldnames(f);
if nargin == 1
    for i=1:length(clNames)
        value.(clNames{i}) = f.(clNames{i});
    end    
else
    
    for i=1:length(clNames)
        if isequal(strField, clNames{i})
            value = f.(clNames{i});
            return
        end

    end
    error([strField, ' is not a valid preProcess property']);
end
    
