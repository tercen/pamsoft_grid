function varargout = cfLogEC50_2(x, par)

Ymax    = par(1);
logIC50 = par(2);
h       = par(3);

u = -(logIC50-x)*h;
U = 10.^u;
A = 1./(1+U);

Y = Ymax.*A;
varargout{1} = Y;
if nargout == 1
   
    return
else %nargout == 2
    c = log(10);
    J = [A, - c*Ymax*h*(A.^2).*U, -c*Ymax*(x-logIC50).*(A.^2).*U];
    varargout{2} = J;
    return
end

