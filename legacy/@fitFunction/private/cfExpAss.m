function varargout = cfExpAss(X, p)
% Y = Y0 + Yspan * (1- exp(-k*X)) 
Y0      = p(1);
Yspan   = p(2);
k       = p(3);

F = Y0 + Yspan*(1-exp(-k*X));
varargout{1} = F;
if nargout == 1  
    return
end
J = [ones(size(X)), (1-exp(-k*X)), Yspan*exp(-k*X).*X];
varargout{2} = J;
if nargout == 2
    return;
end

