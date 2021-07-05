function showBinary(oQ)
spot = getBinSpot(oQ.oSegmentation);
ignored = get(oQ, 'ignoredMask');
bg = get(oQ.oSegmentation, 'bbTrue');
binview = double(spot);
binview(bg) = 0.5;
binview(ignored) = 0.25;
imshow(binview);
colormap(gca, 'jet');
mp = get(oQ.oSegmentation, 'finalMidpoint');
sp  = get(oQ.oSegmentation, 'spotPitch');
set(gca, 'xlim', mp(2)+[-sp,sp], 'ylim',mp(1)+[-sp,sp]);
