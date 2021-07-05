function mp = midPoint(oArray, xPos, yPos)
% mp = midPoint(oArray, xPos, yPos);
% find the midPoint of an array defined by the oArray object and 
% actual coordinates xPos, yPos (corresponding to row and col properties.
% EXAMPLE:
% >> oArray = fromFile(array, 'MyArray.txt', '#');
% >> oArray = set(oArray, 'spotPitch', 1);
% >> [cx, cy] = coordinates(oArray, [100,100]);
% >> mp = midPoint(oArray, cx, cy)
% mp =
% 
%    100   100
% See also array/array, array/fromFile, array/coordinates


if isempty(oArray.xOffset)
    oArray.xOffset = zeros(size(oArray.row));
end
if isempty(oArray.yOffset)
    oArray.yOffset = zeros(size(oArray.col));
end
isRef = oArray.isreference;
row = abs(oArray.row);
col = abs(oArray.col);

if any(isRef)
    rmp = min(row) + (max(row)-min(row))/2;
    cmp = min(col) + (max(col)-min(col))/2;

    mp(:,1) = -1 + (xPos(isRef) -oArray.spotPitch(1)    *oArray.xOffset(isRef)) + (rmp - row(isRef)) * oArray.spotPitch(1);
    mp(:,2) = -1 + (yPos(isRef) -oArray.spotPitch(end)  *oArray.yOffset(isRef)) + (cmp - col(isRef)) * oArray.spotPitch(end);

    if size(mp,1) > 1
        mp = mean(mp);
    end
else
    mp =[];
end

    
