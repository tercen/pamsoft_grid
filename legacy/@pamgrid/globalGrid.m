function [x,y,rot,sp] = globalGrid(pgr, I)
%[x,y,rot] = globalGrid(pgr, I)
% create the grid image. Note that the grid image may be resized with
% respect to the input images for efficiency. rsf is the resize factor.
rsf = pgr.gridImageSize./size(I);
oP = rescale(pgr.oPreprocessing, rsf(1));
Igrid = getPrepImage(oP, imresize(I, pgr.gridImageSize));
arsc = rescale(pgr.oArray, rsf);
% call the grid finding method
[x,y,rot, sp] = gridFind(arsc, Igrid);
% scale back to the original size and return
x = x/rsf(1);
y = y/rsf(2);
x(x<1) = 1;
y(y<1) = 1;
x(x>size(I,1)) = size(I,1);
y(y>size(I,2)) = size(I,2);
