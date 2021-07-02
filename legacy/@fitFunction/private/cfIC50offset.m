function varargout = cfIC50offset(x, par)
Y0   = par(1);
Ymax = par(2);
IC50 = par(3);

A = 1./(1 + (x/IC50));

Y = Y0 + Ymax*A;

varargout{1} = Y;
if nargout == 1
    return
elseif nargout == 2
    J = [ones(length(x),1), A, (Ymax*x/IC50^2).*A.^2];
    varargout{2} = J;
end