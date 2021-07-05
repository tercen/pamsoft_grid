function varargout = cfLogIC50(x, par)
Y0      = par(1);
Ymax    = par(2);
logIC50 = par(3);
h       = par(4);

u = (logIC50-x)*h;
U = 10.^u;
A = 1./(1+U);

Y = Y0 + Ymax.*A;
varargout{1} = Y;
if nargout == 1
   
    return
else %nargout == 2
    c = log(10);
    J = [ones(length(x),1), A, - c*Ymax*h*(A.^2).*U, c*Ymax*(x-logIC50).*(A.^2).*U];
    varargout{2} = J;
    return
end

