% function [x,y] = getPosition(oS
function [x,y] = pg_seg_get_position(spots)

x = zeros(size(spots));
y = x;
for i=1:length(spots)
%     mp = get(oS(i), 'finalMidpoint');
    mp = spots(i).finalMidpoint;
    x(i) = mp(1); y(i) = mp(2);
end

