function [d,list] = getList(d)
if isempty(d.path)
    error('Please set the path property');
end


switch d.instrument
    case 'detect';
        [list, instrument] = searchDetect(d.path, d.filter, d.forceStructure);
        d.instrument = instrument;
    case 'PS96'
        list = searchPS96(d.path, d.filter);
    otherwise
        error(['Unknown instrument: ', d.instrument]);
end

d.list = list;
str = [list(1).path, '\', list(1).name];
info = imfinfo(str);
d.imageSize = [info.Height, info.Width];