function [x,y] = pg_grid_coordinates(row,col,x0,y0,mp,spotPitch,rotation, bUse)
% function [x,y] = gridCoordinates(mp, refMask, spotPitch, rotation, x0, y0)
% this function generates the coordinates of spots in a grid. private
% function of the array class
%
% IN:
%
% row: row indices used in the array (N element vector)
% col: col indices used in the array (N element vector)
%
% x0, xOffsets from ideal in units spotPitch, N element vector correspondig
% to row and col
%
% y0, yOffsets from ideal in units spotPitch, N element vector
% corresponding to row and col
%
% mp: two element vector with the x and y coordinate of the midpoint of
% the array in the image or template.
%
% spotPitch (2 element vector) x and y pitch of the array, if spotPitch is
% scalar the function use spotPitch for both the x and y pitch.
%
% rotation (scalar) rotation of the array (degrees)
%
% <bUse>, optional, logical array of size(row) == size(col), coordinates for row, col positons for which bUse
% is False will be skipped in the output. Default: true(size(row));
%
% OUT:
% x,y coordinates of positions

if nargin < 8
    bUse = true(size(row));
end

if length(spotPitch) == 1
    spotPitch(2) = spotPitch(1);
end
%%
% spotPitch = spotPitch(2:-1:1);
row = abs(row);
col = abs(col);

% calculate grid coordinates, zeros centered
rmp = min(row) + (max(row)-min(row))/2;
cmp = min(col) + (max(col)-min(col))/2;

x = spotPitch(1)*(row-rmp) + spotPitch(1) * x0;
y = spotPitch(2)*(col-cmp) + spotPitch(2) * y0;

% rotate the grid
teta = (2*pi/360) * rotation; 
R = [cos(teta), -sin(teta);
    sin(teta), cos(teta)];

v = (R * [x';y'])'; % Note: this is matrix multiplcation
x = v(:,1); y = v(:,2);

% center around midpoint of array in image or template
x = mp(1) + x + 1;
y = mp(2) + y + 1;
% figure;
% scatter(x,y, 'k');
%%
x = x(bUse); y = y(bUse);
%EOF