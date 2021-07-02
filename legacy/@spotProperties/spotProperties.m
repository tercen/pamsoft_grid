function sp = spotProperties(varargin)
if length(varargin) == 1
    % use existing object
    bIn = varargin{1};
    if isa(bIn, 'spotProperties');
        s = bIn;
        s = get(s);
        s.spots = [];
        return;
    elseif isstruct(bIn);
        dummy = spotProperties();
        s = class(bIn, 'spotProperties');
        return;
    
    else
        error(['cannot create a spotProperties object from an object of class: ', isa(bIn)]);
    end
end

sp.formFactor       = [];
sp.diameter         = [];
sp.aspectRatio      = [];
sp.position         = [];
sp.positionOffset   = [];
sp.positionDelta    = [];
sp.nChiSqr          = -1;
sp = class(sp,'spotProperties');
% EOF


