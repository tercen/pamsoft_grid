function [signal, background, sigmbg] = getSignals(oq, qMetric);

if nargin == 1
    qMetric = 'median';
end
switch qMetric
    case 'median'
        sigField = 'medianSignal';
        bgField = 'medianBackground';
    case 'mean' 
        sigField = 'meanSignal';
        bgField = 'meanBackground';
    otherwise
        error('spotQuantification:unknownQuantitationMetric', '%s', ['unknown quantitaion metric (please check case): ', qMetric]);
end


[nRows, nCols] = size(oq);
signal = NaN(size(oq));
bg = NaN(size(oq));
sigmbg = NaN(size(oq));
for i=1:nRows
    for j=1:nCols
        if ~isempty(oq(i,j).(sigField))
            signal(i,j)         = double(oq(i,j).(sigField));
            background(i,j)     = double(oq(i,j).(bgField));
            sigmbg(i,j) = signal(i,j) - background(i,j);
        else
            signal(i,j) = NaN;
            bg(i,j) = NaN;
            sigmbg(i,j) = NaN;
        end
     end
end

