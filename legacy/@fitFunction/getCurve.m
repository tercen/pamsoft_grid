function varargout = getCurve(f, x, p, bFit)
if nargin < 4
    bFit = true(1, size(p,1));
end


[sp1, sp2] = size(p);

if f.jacFlag & nargout == 2
    bJac = 1;
else
    bJac = 0;
end
bJac = logical(bJac);

for i=1:sp2
    strFunction = f.strFitFunctionName;
    if bJac
        [y(:,i), j]  = feval(strFunction, x, p(:,i), bFit);
        J(:,:,i) = j;
    else
        y(:,i) = feval(strFunction,x, p(:,i));
    end
end

if bJac
    varargout{1} = y;
    varargout{2} = J;
else
    varargout{1} = y;
end



