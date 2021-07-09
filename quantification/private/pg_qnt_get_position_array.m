function [subParams, exitCode] = pg_qnt_get_position_array(params, keepType)
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
exitCode = 0;
if isequal(keepType, 'isreference')
    bKeep = params.grdIsReference;
elseif  isequal(keepType, '~isreference')
    bKeep = ~params.grdIsReference;
elseif islogical(keepType)
    bKeep = keepType;
else
%     error('invalid value for keepType')
    exitCode = -201;
    return;
end

bKeep = logical(bKeep);

subParams = params;
subParams.grdIsReference = params.grdIsReference(bKeep);
subParams.grdRow = params.grdRow(bKeep);
subParams.grdCol = params.grdCol(bKeep);
subParams.grdXOffset = params.grdXOffset(bKeep);
subParams.grdYOffset = params.grdYOffset(bKeep);
subParams.grdXFixedPosition = params.grdXFixedPosition(bKeep);
subParams.grdYFixedPosition = params.grdYFixedPosition(bKeep);
subParams.qntSpotID = params.qntSpotID(bKeep);

end
    