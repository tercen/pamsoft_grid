function D = arrayFitFunction(par, oArray, xData, yData)
m = par(1:2);
rot = par(3);
spotPitch = par(4);
[x,y] = gridCoordinates(oArray.row, oArray.col, oArray.xOffset, oArray.yOffset,m, spotPitch, rot);
w = double(oArray.isreference);
D = w.*sqrt(((xData(:) - x(:)).^2 + (yData(:)-y(:)).^2));
D = D/length(find(w));

