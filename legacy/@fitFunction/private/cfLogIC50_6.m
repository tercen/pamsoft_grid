function varargout = cfLogIC50_6(x, par)

Ymax    = 1;
logIC50 = par(1);
h       = -1;

u = (logIC50-x)*h;
U = 10.^u;
A = 1./(1+U);

Y = Ymax.*A;
varargout{1} = Y;
if nargout == 1
   
    return
else %nargout == 2
    c = log(10);
    J = [ - c*Ymax*h*(A.^2).*U];
    varargout{2} = J;
    return
end

