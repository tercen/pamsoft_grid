function [hImage, hBound] = show(oQ, I, dr)
if nargin < 3
    dr = [];
end
hImage = imshow(I, dr, 'ini', 'fit');
hBound = [];
colormap(gca, 'jet');
szArray = size(oQ);
if ~isempty(oQ)
    hold on
    oQ = oQ(:);
    hBound = [];
    for i=1:length(oQ)
        [x,y] = getOutline(oQ(i).oSegmentation);
        if ~isempty(x) && ~isempty(y)
            if oQ(i).isEmpty
                cStr = 'k';
            elseif oQ(i).isBad
                cStr = 'r';
            else
                cStr = 'w';
            end
            [n,m] = ind2sub(szArray,i);
            hBound(n,m) = plot(y, x, cStr);
        end
    end
    hold off
end