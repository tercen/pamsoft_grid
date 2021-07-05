function value = get(s, strField)

clNames = fieldnames(s);
if nargin == 1
    value = struct(s);
    if isfield(value, 'private')
        value = rmfield(value, 'private');
    end
else
    
    for i=1:length(clNames)
        if strcmp(strField, 'binSpot')
            value = getBinSpot(s);
            return
        elseif strcmp(strField, clNames{i}) && ~strcmp(clNames{i}, 'private')
            [n, m] = size(s);
            [value{1:n, 1:m}]  = deal(s.(clNames{i}));
            value = cell2mat(value);
          
            return
        end

    end
    error([strField, ' is not a valid and public segmentation property']);
end
    
