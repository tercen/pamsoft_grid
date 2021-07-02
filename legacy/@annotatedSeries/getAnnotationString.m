function string = getAnnotationString(s)

ann = s.annotation;
if iscell(ann);
    string = [];
    for i=1:length(ann)
        string = [string, '_', ann{i}];
    end
elseif ischar(ann)
    string = ann;
elseif isnumeric(ann)
    string = num2str(ann);
end

