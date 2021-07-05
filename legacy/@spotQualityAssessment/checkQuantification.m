function flag = checkQuantification(sa, q)
qs = get(q(:));
flag = zeros(length(qs),1);
% 1. find those spots that are considered empty:
snr = ([qs.meanSignal] - [qs.meanBackground])./sqrt([qs.stdSignal].^2 + [qs.stdBackground].^2);
bEmpty = snr < sa.minSnr;
flag(bEmpty) = 2;









        
