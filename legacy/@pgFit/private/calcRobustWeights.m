function wRob = calcRobustWeights(res, tune)
% wRob = calcRobustWeight(res)
% bisquared Tukey biweight;
if nargin < 3
    tune = 1;
end

K = tune*4.685;
mad = median(abs(res));
robVar = mad/0.6745;

wResAdjusted = res/(K*robVar);
wRob = zeros(size(res));
iNonZero = find(abs(wResAdjusted) < 1);
wRob(iNonZero) = (1-wResAdjusted(iNonZero).^2).^2;