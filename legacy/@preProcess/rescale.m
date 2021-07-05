function oP = rescale(oP, rFactor)
if oP.nSmallDisk > 0
    oP.nSmallDisk = max(round(oP.nSmallDisk * rFactor),1);
end
if oP.nLargeDisk > 0
    oP.nLargeDisk = max(round(oP.nLargeDisk * rFactor),1);
end
if oP.nCircle > 0
    oP.nCircle = max(round(oP.nCircle * rFactor),1);
end
