function wRob = calcRobustWeights2(res, jac, tune)
% wRob = calcRobustWeight(res)
% calculates biquared robust weights from fit residuals and jacobian according
% DuMouchel and O'Brien in
% Computing and Graphics in Statisitics
% (Buja, A., Tukey, P.A., eds.)
% Springer New York (1991)
% p41-48
if nargin < 3
    tune = 1;
end

K = tune*4.685;
mad = median(abs(res));
robVar = mad/0.6745;
% compute leverage adjustment from the jacobian ('design matrix');
% matrix inverse calculated via qr algorithm (see matlab documentation)
warning('off', 'MATLAB:singularMatrix')
[Q,R] = qr(jac,0);
E = jac/R;
h = min(.9999, sum(E.*E,2));
warning('on', 'MATLAB:singularMatrix')
adjFactor = 1 ./ sqrt(1-h);
  
wResAdjusted = adjFactor.*res/(K*robVar);
wRob = zeros(size(res));
iNonZero = find(abs(wResAdjusted) < 1);
wRob(iNonZero) = (1-wResAdjusted(iNonZero).^2).^2;