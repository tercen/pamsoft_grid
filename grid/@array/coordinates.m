function [cx,cy] = coordinates(oArray,mp, rotation)
%[cx,cy] = coordinates(oArray,mp, rotation)
% returns x and y coordinates of an array defined by the oArray object
% for entries with isreference == true;
% plus a midpoint [x,y]  plus an optional rotation (dft = 0)
% See also array/array
if isempty(oArray.xOffset)
    oArray.xOffset = zeros(size(oArray.row));
end
if isempty(oArray.yOffset)
    oArray.yOffset = zeros(size(oArray.col));
end

if nargin < 3
    rotation = oArray.rotation;
end

if isempty(oArray.spotPitch)
    error('array property spotPitch is not defined')
end

% get the coordinates for set1, set2 respectivley
% bSet1 = oArray.row > 0 & oArray.col;
% bSet2 = oArray.col < 0 & oArray.row;
% cx = -ones(size(bSet1));
% cy = -ones(size(bSet1));
% bRefSet1 = bSet1 & oArray.isreference;
% bRefSet2 = bSet2 & oArray.isreference;
% 
% if any(bRefSet1)
%     [cx(bSet1), cy(bSet1)] = gridCoordinates(oArray.row(bSet1), oArray.col(bSet1), oArray.xOffset(bSet1), oArray.yOffset(bSet1), mp, oArray.spotPitch, rotation, oArray.isreference(bSet1));
% end
% if any(bRefSet2)
%     [cx(bSet2), cy(bSet2)] = gridCoordinates(oArray.row(bSet2), oArray.col(bSet2), oArray.xOffset(bSet2), oArray.yOffset(bSet2), mp, oArray.spotPitch, rotation, oArray.isreference(bSet2));
% end
        
[cx, cy] = gridCoordinates(oArray.row, oArray.col, oArray.xOffset, oArray.yOffset, mp, oArray.spotPitch, rotation, oArray.isreference);


