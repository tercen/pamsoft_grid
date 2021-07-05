function varargout = lsqFun(p, oFit, X, Y, W)
% varargout = lsqFun(p, X,Y, FitFunc)
% generic fitfunction that calls the model function
% and calculates the residuals for least square fitting
    
if get(oFit.modelObj, 'jacFlag') & nargout == 2
      
     [f, j] = getCurve(oFit.modelObj, X, p, oFit.fitPars);
     Wt = repmat(W, 1,length(p));    
     varargout{2} = Wt.*j;
else
     f = getCurve(oFit.modelObj, X, p);
end
varargout{1} = W.*(f-Y);