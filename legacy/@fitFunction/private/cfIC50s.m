function varargout = cfIC50s(x, par)
Ymax = par(1);
IC50 = par(2);

A = 1./(1 + (x/IC50));
Y = Ymax.*A;

varargout{1} = Y;
if nargout == 1
    return
elseif nargout == 2
    J = [A, (Ymax*x/IC50^2).*A.^2];
    varargout{2} = J;
end

