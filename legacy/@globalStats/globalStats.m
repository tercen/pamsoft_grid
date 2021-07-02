function g = globalStats(varargin)
if length(varargin) == 1
    if isa(varargin{1}, 'globalStats')
        g = varargin{1};
       
    else
        error(['Cannot create a globalStats object from object of class: ', class(varargin{1})]);
    end
    return;
end

g.odSigmaFac = 3;
g.odEpsilon = 0.01;
g.bLocalT = 1;
g.bLocalCV = 1;
g.bGlobalMetrics = 1;
g.badWells = false(8,12);
g.pOut = 0;
g = class(g, 'globalStats');

if length(varargin) > 1
    g = set(g, varargin{:});
end


    

    