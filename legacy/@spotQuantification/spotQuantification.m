function oq = spotQuantification(varargin)
if length(varargin) == 1
    % use existing object
    bIn = varargin{1};
    if isa(bIn, 'spotQuantification');
        oq = bIn;
        return;
    elseif isstruct(bIn);
        oq = class(bIn, 'spotQuantification');
        return;
    end
end
oq.ID = [];
oq.arrayRow = [];
oq.arrayCol = [];
oq.rotation = [];
oq.saturationLimit = 2^16 -1 ;
oq.oOutlier = [];
oq.oSegmentation = [];
oq.oProperties = [];
oq.medianBackground = [];
oq.meanBackground = [];
oq.stdBackground = [];
oq.minBackground = [];
oq.maxBackground = [];
oq.rseBackground = [];
oq.medianSignal = [];
oq.meanSignal = [];
oq.sumSignal = [];
oq.sumBackground = [];
oq.stdSignal = [];
oq.rseSignal = [];
oq.minSignal = [];
oq.maxSignal = [];
oq.iIgnored = [];
oq.fractionIgnored = [];
oq.signalSaturation = [];
oq.isEmpty = false;
oq.isBad   = false;
oq.isReplaced = false;

oq = class(oq, 'spotQuantification');
oq = set(oq, varargin{:});


