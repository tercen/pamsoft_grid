function varargout = cfLogIC50_5(x, par)

Ymax    = 1;
logIC50 = par(1);
h       = par(2);

u = (logIC50-x)*h;
U = 10.^u;
A = 1./(1+U);

Y = Ymax.*A;
varargout{1} = Y;
if nargout == 1
   
    return
else %nargout == 2
    c = log(10);
    J = [ - c*Ymax*h*(A.^2).*U, c*Ymax*(x-logIC50).*(A.^2).*U];
    varargout{2} = J;
    return
end

