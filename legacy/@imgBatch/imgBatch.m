function b = imgBatch(varargin)


if nargin ==0
% create new empty object
    b.batchID   = [];
    b.pathImageResults = [];
    b.pathTemplate  = [];
    b.pathConfiguration = [];
    b.nChannel = 0;
    b.channelName   = '';
    b.imageFilter = '*.tif*';
    b.instrument = [];
    b.gridMode = [];
    b.combineExposures = 0;
    b.adjustSpots = 1;
    b.ppObj = [];
    b.log = 1;
    b = class(b, 'imgBatch');
end
if length(varargin) == 1
    % copy input object to output object
    bIn = varargin{1};
    if isa(bIn, 'imgBatch');
        b = bIn;
    else
        error(['Cannot create imgBatch object from object of class ',class(bIn)]);
    end
end


    
    

    
    
