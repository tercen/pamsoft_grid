%   flags = checkQuantification(pgr.oSpotQualityAssessment, q(:,i));
function [params, exitCode] = pg_qnt_check_quantification(params)
q = params.quant;
exitCode = 0;
flags = zeros(length(q(:,1)),size(q,2));

for i=1:size(q,2)
    qs = q(:,i);
    flag = zeros(length(qs),1);
    % 1. find those spots that are considered empty:
    snr = ([qs.meanSignal] - [qs.meanBackground])./sqrt([qs.stdSignal].^2 + [qs.stdBackground].^2);
    bEmpty = snr < params.sqcMinSnr;
    flag(bEmpty) = 2;
    
    flags(:,i) = flag;
    
    for j = 1:size(q,1)
        q(j,i).isEmpty = flag(j) == 2;
        q(j,i).isBad   = flag(j) == 1;
    end
%     q(:,i) = setSet(q(:,i), ...
%         'isEmpty', flags == 2, ...
%         'isBad', flags == 1);
end
params.quant = q;

end

