function oArray = removePositions(oArray, bRemove)
% function oArray = removePositions(oArray, bRemove)
% 
% if isequal(bRemove, 'isreference')
%     bKeep = ~oArray.isreference;
% elseif  isequal(bRemove, '~isreference')
%     bKeep = oArray.isreference;
% elseif islogical(bRemove)
%     bKeep = ~bRemove;

% else
%     error('invalid value for bRemove')
% end
% See also array/array
if isequal(bRemove, 'isreference')
    bKeep = ~oArray.isreference;
elseif  isequal(bRemove, '~isreference')
    bKeep = oArray.isreference;
elseif islogical(bRemove)
    bKeep = ~bRemove;
else
    error('invalid value for bRemove')
end
bKeep = logical(bKeep);
oArray.isreference = oArray.isreference(logical(bKeep));
oArray.row = oArray.row(bKeep);
oArray.col = oArray.col(bKeep);
oArray.xOffset = oArray.xOffset(bKeep);
oArray.yOffset = oArray.yOffset(bKeep);
oArray.xFixedPosition = oArray.xFixedPosition(bKeep);
oArray.yFixedPosition = oArray.yFixedPosition(bKeep);
oArray.ID = oArray.ID(bKeep);

    