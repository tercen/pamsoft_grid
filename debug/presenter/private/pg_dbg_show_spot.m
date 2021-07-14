function [hImage, hBound] = pg_dbg_show_spot(oQ, I, dr)
if nargin < 3
    dr = [];
end
hImage = imshow(I, dr, 'ini', 'fit');
hBound = [];
colormap(gca, 'jet');
szArray = size(oQ);
if ~isempty(oQ)
    hold on
%     oQ = oQ(:);
    hBound = [];
    for i=1:length(oQ)
%         [x,y] = getOutline(oQ(i).oSegmentation);
        [x,y] = pg_seg_get_outline(oQ(i).Spot);
        if ~isempty(x) && ~isempty(y)
            if oQ(i).Empty_Spot
                cStr = 'k';
            elseif oQ(i).Bad_Spot
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