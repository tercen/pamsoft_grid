function  bOk = check(sp, varargin)
sp = struct(sp);
fields = fieldnames(sp);
bOk = [];
for i=1:2:length(varargin)
    if length(varargin) < i+1
        error('check function expects property / value pairs as input');
    end
    prop = varargin{i};
    val = varargin{i+1};
    lowWord     = prop(1:3);
    highWord    = prop(4:end);
    iMatch = strmatch(highWord, fields);
    if isempty(iMatch)
        error(['Invalid Property: ', prop]);
    end
    
    switch lowWord
        case 'max'
            p = 1;
        case 'min'
            p = -1;
        otherwise
            error(['Invalid Property: ', prop]);
    end
    
    if isempty(sp.(fields{iMatch}))
        error(['Property has not been set: ',fields{iMatch}]);
    end
    bOk(end+1) = p * val > p * sp.(fields{iMatch});
end

    