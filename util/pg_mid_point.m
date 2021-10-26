function mp = pg_mid_point(params, xPos, yPos)
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


if isempty(params.grdXOffset)
    params.grdXOffset = zeros(size(params.grdRow));
end
if isempty(params.grdYOffset)
    params.grdYOffset = zeros(size(params.grdCol));
end
isRef = params.grdIsReference;
row   = abs(params.grdRow);
col   = abs(params.grdCol);

if any(isRef)
    rmp = min(row) + (max(row)-min(row))/2;
    cmp = min(col) + (max(col)-min(col))/2;

    mp(:,1) = -1 + (xPos(isRef) -params.grdSpotPitch(1)    *params.grdXOffset(isRef)) + (rmp - row(isRef)) * params.grdSpotPitch(1);
    mp(:,2) = -1 + (yPos(isRef) -params.grdSpotPitch(end)  *params.grdYOffset(isRef)) + (cmp - col(isRef)) * params.grdSpotPitch(end);

   
    if size(mp,1) > 1
        mp = nanmean(mp);
    end
else
    mp =[];
end

    
