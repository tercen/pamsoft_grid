function Ic = combineImages(oc ,I, expTimes)
% combines multi exposure time images on a per pixel basis
I = double(I);
s = size(I);

[expTimes, iSort] = sort(expTimes);
I = I(:,:,iSort);
Ic = I(:,:,1)/expTimes(1);

bOut = oc.criteriumParity * I >= oc.criteriumParity * oc.combinationCriterium;
% s(3) will generally be 4 or 5 so we can conviently loop:
for i=2:s(3);
    b = ~bOut(:,:,i);
    Ih = I(:,:,i);
    Ic(b) =   Ih(b)/expTimes(i);    
end
% convert to uint16
Ic = uint16((Ic*(2^16-1))/max(Ic(:)));

    

