function [x, y, clNormalizer, clNegative, primaryR2, sSig, aChiSqr, localT, localCV] = getSeries(series)

for i=1:length(series.dataPoints)
    x(i) = get(series.dataPoints(i), 'x');
    y(i) = get(series.dataPoints(i), 'y');
   
    clNormalizer{i} = get(series.dataPoints(i), 'normalizer');
    clNegative{i} = get(series.dataPoints(i), 'negative');
    primaryR2(i) = get(series.dataPoints(i),'primaryR2');
    sSig(i) = get(series.dataPoints(i), 'sSig');
    aChiSqr(i) = get(series.dataPoints(i), 'aChiSqr');
    localT(i) = get(series.dataPoints(i), 'localT');
    localCV(i) = get(series.dataPoints(i), 'localCV');
    end
[x, iSort] = sort(x);
x = x';
y = y(iSort)';

clNormalizer    = clNormalizer(iSort)';
clNegative      = clNegative(iSort)';
primaryR2       = primaryR2(iSort)';  
sSig            = sSig(iSort)';
aChiSqr           = aChiSqr(iSort)';
localT          = localT(iSort)';
localCV         = localCV(iSort)';

    