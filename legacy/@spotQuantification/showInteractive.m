function hPresenter = showInteractive(oQ, I, xSeries)
if nargin < 3
    xSeries = 1:size(I,3);
end

% permute for historical reasons:
oQ = permute(oQ, [1,3,2]);
hPresenter = presenter(I, oQ, xSeries);
% EOF