function [r, rms] = robCircFitFxdMp(x,y,x0,y0)
% irlsq
x = x(:)-x0;
y = y(:)-y0;
maxIter = 10;
eps = 0.001;
r = sqrt(ones(size(x))\(x.^2+ y.^2) );
res =  ( x.^2 + y.^2 - r^2).^2;
ChiSqr = sum(res);
n = 0;
while(1)
    n = n + 1;
    oChiSqr = ChiSqr;
    w = calcTukeyWeights(res);
    r = sqrt(w\(w.*(x.^2+ y.^2)) );  
    res =  (x.^2 + y.^2 - r^2).^2;
    ChiSqr = sum(res);
    if abs(ChiSqr - oChiSqr)/ChiSqr <= eps
        break;
    end
    if n > maxIter
        break;
    end
end
rms = ChiSqr/length(x);
