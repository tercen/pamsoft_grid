function p = pgFit(varIn)

if isa(varIn, 'pgFit')
    p = varIn;
    return
end

    
f = fitFunction(varIn);
if isempty(get(f, 'strModelName'))
    error([varIn, ' is not an available model for use the pgFit class']);
end
p.modelName = varIn;
p.modelObj  = f;
p.iniPars   = [];
p.lbPars    = [];
p.ubPars    = [];
p.fitPars   = true(size(get(f, 'clParameter')));
p.fitMethod = 'Normal';
p.robTune   = 1;

if get(f, 'jacFlag')
    p.jacobian  = 'on';
else
    p.jacobian = 'off';
end

p.maxIterations = 100;
p.TolX = 1e-2;
p.TolMode = 'Relative';
p.errorMethod = 'ASE';
p = class(p, 'pgFit');