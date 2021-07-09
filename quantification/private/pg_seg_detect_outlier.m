function [iOut, limits, pval] = pg_seg_detect_outlier(data, params)
pval = [];
switch params.qntOutlierMethod
    case 'iqrBased'
        [iOut, limits] = internal_iqr_detection(data(:), params.qntOutlierMeasure);
end
end
% 

function  [iOut, limits] = internal_iqr_detection(data, measure)
% function [iOut, limits] = iqrDetection(data, [cutoff])
% detect outliers in the data matrix data using inter quantile range (iqr) as a
% estimator of data variance. outliers are those elements of data that
% are are cutoff * iqr above the 3/4 quantile or cutoff * iqr below the 1/4
% quantile point of the distribution of the points in data.
% when cutoff is not specified it default to 1.5.
% OUTPUT:
% iOut, logical array with the same dimensions as data. Elements are true when the corresponding element of data is an outlier,
% false otherwise.
% limits, 2 element array containg the lower and higher limit for the value
% of data elements to have a corresponding false in iOut.

if nargin == 1
    measure = 1.5;
end

% calculate iqr
iqrLimits = quantile(data, [0.25, 0.75]);
iqr = iqrLimits(2) - iqrLimits(1);
% calculate limits
limits(1) = iqrLimits(1) - measure *iqr;
limits(2) = iqrLimits(2) + measure *iqr;

iOut = data < limits(1) | data > limits(2);
end