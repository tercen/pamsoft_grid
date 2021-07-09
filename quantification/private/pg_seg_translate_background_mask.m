function spot = pg_seg_translate_background_mask(spot, newMidpoint, imSize)
aTranslation = round(newMidpoint - spot.finalMidpoint);
[bgi, bgj] = ind2sub(imSize, spot.bbTrue);

bgi = bgi + aTranslation(1);
bgj = bgj + aTranslation(2);
try
    spot.bbTrue = sub2ind(imSize, bgi, bgj);
catch aMidPointOutOfRange
    % do not translate, leave for the QC to pick-up
    return
end

