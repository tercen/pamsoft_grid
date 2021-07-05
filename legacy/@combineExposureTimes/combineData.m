function [cData, iUsed] = combineData(oc, data, critData, expTime);

% make sure everything is sorted to asc. exposure
[expTime, iSort] = sort(expTime);
data = data(:,:,iSort);
critData = critData(:,:,iSort);
%
bOut = oc.criteriumParity * critData >= oc.criteriumParity * oc.combinationCriterium;


bOut = oc.criteriumParity * data >= oc.criteriumParity * oc.combinationCriterium;

cData = data(:,:,1)/expTime(1);
iUsed = ones(size(cData));
% s(3) will generally be 4 or 5 so we can conviently loop:
for i=2:size(data,3)
    b = ~bOut(:,:,i);
    hData = data(:,:,i);
    cData(b) =   hData(b)/expTime(i);
    iUsed(b) = i;
end