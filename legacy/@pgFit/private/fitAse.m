function ase = fitAse(res, J)
% function ase = fitAse(res, j)
% calculates asymptotic standard errors for a fit with residuals res with jacobian j 
% See: Johnson and Faunt in Methods in Enzymology 210 1-37 (Brand and Johnson
% ed.) Academic Press 1992, 
[nPoints, nPars] = size(J);
v = nPoints - nPars;
s2 = norm(res)/sqrt(v);

cv = inv(J'*J);
ase = s2 .* sqrt(diag(cv));
