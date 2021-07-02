function m = getBackgroundMask(oQ, imSize);
m = false(imSize);
bbTrue = get(oQ.oSegmentation, 'bbTrue');
m(bbTrue) = true;
