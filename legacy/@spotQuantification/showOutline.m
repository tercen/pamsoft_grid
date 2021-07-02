function hImage = showOutline(oQ, I, fr)
hold off
if nargin < 3
    fr = double(max(I(:)));
end
I = double(I)/fr;
hImage = imshow(I, [0,1]);
colormap(gca, 'jet');
hold on
[x,y] = getOutline(oQ.oSegmentation, 'coordinates', 'global');
hOutline = plot(y, x, 'w');
if oQ.isEmpty
    set(hOutline, 'color', 'k');
elseif oQ.isBad
    set(hOutline, 'color', 'r');
end
bg = getBackgroundMask(oQ, size(I));
L = bwlabel(double(bg));
B = bwboundaries(L);
nb = length(B);
for i=1:nb
    bounds = B{i};
    plot(bounds(:,2), bounds(:,1), 'k')
end
mp = get(oQ.oSegmentation, 'finalMidpoint');
sp  = get(oQ.oSegmentation, 'spotPitch');
set(gca, 'xlim', mp(2)+[-sp,sp], 'ylim',mp(1)+[-sp,sp]);


