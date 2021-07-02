function [iOut,limits, pVal]  = detect(o, data)

pval = [];
switch o.method
    case 'iqrBased'
        [iOut, limits] = iqrDetection(data(:), o.measure);
end
%EOF