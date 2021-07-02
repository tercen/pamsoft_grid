function d = dataPoint(x , y, normalizer, negative, primaryR2, sSig ,aChiSqr,  localT, localCV);
d.x = x;
d.y = y;
d.normalizer = normalizer;
d.negative = negative;
d.primaryR2 = primaryR2;
d.sSig      = sSig;
d.aChiSqr   = aChiSqr;
d.localT    = localT;
d.localCV   = localCV;

d = class(d, 'dataPoint');
