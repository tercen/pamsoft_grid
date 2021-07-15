function [cx,cy, exitCode] = pg_grd_coordinates(params,mp, rotation)
%[cx,cy] = coordinates(oArray,mp, rotation)
% returns x and y coordinates of an array defined by the oArray object
% for entries with isreference == true;
% plus a midpoint [x,y]  plus an optional rotation (dft = 0)
% See also array/array
exitCode = 0;
cx = [];
cy = [];

if isempty(params.grdXOffset)
    params.grdXOffset = zeros(size(params.grdRow));
end
if isempty(params.grdYOffset)
    params.grdYOffset = zeros(size(params.grdCol));
end

if nargin < 3
    rotation = params.grdRotation;
end

if isempty(params.grdSpotPitch)
    exitCode = -11;
%     error('array property spotPitch is not defined')
    pg_error_message(exitCode, 'grdSpotPitch');
    return;
end

[cx, cy] = pg_grid_coordinates(params.grdRow, params.grdCol, params.grdXOffset, params.grdYOffset, mp, params.grdSpotPitch, rotation, params.grdIsReference);

