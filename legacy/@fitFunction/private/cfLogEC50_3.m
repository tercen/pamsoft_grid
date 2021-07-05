function varargout = cfLogEC50_3(x, par)

Y0    = par(1);
Ymax = par(2);
logIC50      = par(3);
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
    J = [ones(length(x),1), A, - c*Ymax*h*(A.^2).*U];
    varargout{2} = J;
    return
end

