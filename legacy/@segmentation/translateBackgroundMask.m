function oS = translateBackgroundMask(oS, newMidpoint, imSize)
aTranslation = round(newMidpoint - oS.finalMidpoint);
[bgi, bgj] = ind2sub(imSize, oS.bbTrue);
bgi = bgi + aTranslation(1);
bgj = bgj + aTranslation(2);
try
    oS.bbTrue = sub2ind(imSize, bgi, bgj);
catch aMidPointOutOfRange
    % do not translate, leave for the QC to pick-up
    return
end

