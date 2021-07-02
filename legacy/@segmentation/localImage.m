function Ilocal = localImage(s, I)
% extracts local spot image from main image

cLu = s.bsLuIndex + 1;

i = ceil(cLu(1):cLu(1) + 2*s.spotPitch );
j = ceil(cLu(2):cLu(2) + 2*s.spotPitch );
iUse = i > 0 & i <= size(I,1);
jUse = j > 0 & j <= size(I,2);
if any(~iUse)||any(~jUse)
    error('Spot detection out of image frame');
end
Ilocal = I(i(iUse), j(jUse));
