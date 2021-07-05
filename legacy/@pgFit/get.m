function val = get(p, propName)
names = fieldnames(p);

if nargin == 1
    for i=1:length(names)
        val.(names{i}) = p.(names{i});
    end
    

else

    iMatch = strmatch(propName, names);
    if ~isempty(iMatch)
        val = p.(names{iMatch});
    else
        error(['Invalid property: ', propName]);
    end
end
