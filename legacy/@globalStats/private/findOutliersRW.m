function [iOut, wSigma] = findOutliersRW(data, maxSigmaFactor, eps)
iter = 0;
maxIter = 5;
sData = size(data);
meanData    = mean(data);
medianData  = median(data);
K = 4.65;
mOut = zeros(size(data));
wSigma = zeros(1, sData(2));
for i=1:sData(2)
    while(1)
        iter = iter + 1;
        robVar = median(abs(data(:,i) - medianData(i) ))/0.6745;
        wRes =  ((data(:,i) - medianData(i)))/(K*robVar);
        wRob = zeros(size(wRes));
        iNonZero = find(wRes<1);
        wRob(iNonZero) = ( 1 - wRes(iNonZero).^2).^2;
        wSigma(i) = weightedDeviation(data(:,i), medianData(i), wRob);
        iOut = abs(data(:,i)-medianData(i)) > maxSigmaFactor * wSigma(i);
     
        meanData(i)     = mean  (data(find(~mOut(:,i))  ,i));
        medianData(i)   = median(data(find(~mOut(:,i))  ,i));
        M = abs(meanData(i)-medianData(i))/meanData(i);
        if (M < eps) | iter>maxIter
            break;
        end
    end
end