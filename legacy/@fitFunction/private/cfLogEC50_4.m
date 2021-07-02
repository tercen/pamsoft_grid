function varargout = cfLogEC50_4(x, par)

Y0    = 0;
Ymax = par(1);
logIC50      = par(2);
h = -1;


u = -(logIC50-x)*h;
U = 10.^u;
A = 1./(1+U);

Y = Y0 + Ymax.*A;
varargout{1} = Y;
if nargout == 1
   
    return
else %nargout == 2
    c = log(10);
    J = [A, - c*Ymax*h*(A.^2).*U];
    varargout{2} = J;
    return
end

