function [x,y] = getPosition(oS)

x = zeros(size(oS));
y = x;
for i=1:length(oS)
    mp = get(oS(i), 'finalMidpoint');
    x(i) = mp(1); y(i) = mp(2);
end

