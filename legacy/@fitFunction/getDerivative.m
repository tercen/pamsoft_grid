function df = getDerivative(oF, x, p);
if isempty(oF.strDerFunctionName)
    error(['A derivative function has not been defined for model: ', oF.strModelName]);
end
df = feval(oF.strDerFunctionName, x, p);
% EOF