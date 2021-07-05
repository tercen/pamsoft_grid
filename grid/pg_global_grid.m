function [x,y,rot, params] = pg_global_grid(params, I)
%[x,y,rot] = globalGrid(pgr, I)
% create the grid image. Note that the grid image may be resized with
% respect to the input images for efficiency. rsf is the resize factor.
% params.gridImageSize
% size(I)
rsf     = params.gridImageSize./size(I);


params  = pg_pp_rescale(params, rsf(1));

%CORRECT up to here....


% Igrid = getPrepImage(oP, imresize(I, params.gridImageSize));
Igrid = pg_pp_fun(params, imresize(I, params.gridImageSize));
% Igrid
% imagesc(Igrid)
% rsf
params = pg_rescale(params, rsf);


% call the grid finding method
% [x,y, rot, params, mx]

[x,y,rot, ~] = pg_grid_find(params, Igrid);


% scale back to the original size and return
x = x/rsf(1);
y = y/rsf(2);
x(x<1) = 1;
y(y<1) = 1;
x(x>size(I,1)) = size(I,1);
y(y>size(I,2)) = size(I,2);

% x