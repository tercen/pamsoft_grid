function [x0, y0, r, nChiSqr] = robCircFit(x,y)
% irlsq
x = x(:);
y = y(:);
maxIter = 10;
eps = 0.001;
w = ones(size(y));
[x0, y0, r] = circfit(x,y,w);
res =  ( (x- x0).^2 + (y - y0).^2 - r^2).^2;
ChiSqr = sum(res);
n = 0;
while(1)
    n = n + 1;
    oChiSqr = ChiSqr;
    w = calcTukeyWeights(res);
    [x0, y0, r, nChiSqr] = circfit(x,y,w);
    res =  ( (x- x0).^2 + (y - y0).^2 - r^2).^2;
    ChiSqr = sum(res);
    if abs(ChiSqr - oChiSqr)/ChiSqr <= eps
        break;
    end
    if n > maxIter
        break;
    end
end

    
        


end

