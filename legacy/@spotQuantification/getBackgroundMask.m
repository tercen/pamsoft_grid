function bgMask = getBackgroundMask(q)
if isempty(q.oSegmentation)
    error('segmentation property has not been set');
end
bsSize = get(q.oSegmentation, 'bsSize');

if isempty(bsSize)
    error('segmentation.binSpot property has not been set');
end
bgMask = false(bsSize); bgMask(q.iBackground) = true;
% EOF
