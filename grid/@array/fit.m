function [mpOut, rotOut, spOut, xFit, yFit] = fit(oArray, xPos, yPos)
% [mpOut, rotOut, spOut, xFit, yFit] = fit(oArray, xPos, yPos)
% fits an array defined by the oArray object to the coordinates xPos, yPos
% (corresponding to the row and col property).
% The oArray.spotPitch property must be set as  initial estimate.
% OUT:
% mpOut: fitted midpoint
% rotOut: fitted rotation
% spOut: fitted spotPitch
% xFit, yFit, x and y fit of an ideal grid as a best fit of xPos, yPos.
% See also array/array
mp(1) = mean(xPos(:));
mp(2) = mean(yPos(:));

if isempty(oArray.xOffset)
    oArray.xOff = zeros(size(oArray.row));
end
if isempty(oArray.yOffset)
    oArray.yOff = zeros(size(oArray.row));
end

                 
% call lsq fit with @arrayFitFunction to get mp and rotation in p
pIn  = [mp(1), mp(2), 0, oArray.spotPitch];
pLower = [-1000,-1000,-5,-1000];
pUpper = [1000,1000, 5, 1000];
opt = optimset('Display', 'off', 'MaxFunEvals', 200, 'TolFun', 0.05);

pOut = lsqnonlin(@arrayFitFunction, pIn, pLower, pUpper, opt,oArray, xPos, yPos);
mpOut = pOut(1:2);
rotOut = pOut(3);
spOut = pOut(4);
[xFit, yFit] = coordinates(oArray, mpOut, rotOut);

