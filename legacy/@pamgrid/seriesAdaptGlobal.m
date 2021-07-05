function q = seriesAdaptGlobal(pgr, I, varargin)
opdef.cycle = [];
opdef.exposure = [];
op = setVarArginOptions(opdef, [], varargin{:});

% sort images to cycle and exposure
if isempty(op.cycle)
    op.cycle = 1:size(I,3);
end
if isempty(op.exposure)
    op.exposure = ones(size(op.cycle));
end
[~, iSort] = sortrows([op.cycle, op.exposure]);
exp = op.exposure(iSort);
cycle = op.cycle(iSort);
I = I(:, :, iSort);
% produce the fixed segmentation in the standard way.
qFixed = seriesFixed(pgr, I, 'cycle', cycle, 'exp', exp, 'action', 'segment');
% get this principal segmentation from the fixed data
s0 = get(qFixed, 'oSegmentation');
s0 = [s0{:}]';% convert to array of segmentation objects
% and get the midpoint mp0 associated with s0
% Note that the midpoint will be calculated based on the
% refs only (standard behaviour of array.midPoint)
[x0, y0] = getPosition(s0);
mp0 = midPoint(pgr.oArray, x0, y0);
% prepare for segmenting the other images.
bRef = get(pgr.oArray, 'isreference');
spPitch = get(pgr.oArray, 'spotPitch');
os = set(pgr.oSegmentation, 'spotPitch',spPitch); 
uCycle = unique(cycle);
sl = get(pgr.oSpotQuantification, 'saturationLimit');
q = repmat(spotQuantification, length(qFixed), size(I,3));
for i=1:length(uCycle)
    bThis = cycle == uCycle(i);
    % global grid finding 
    Igrid = I(:,:,bThis);
    if sum(bThis) > 1
        Igrid = combineExposures(I(:,:,bThis),exp(bThis), sl);
    end   
    [x,y,rot] = globalGrid(pgr, Igrid);
     % re-segment the refs only, find the midpoint associated with this
     % segmentation. Note that the midpoint will be calculated based on the
     % refs only (standard behaviour of array.midPoint)
     s0s = s0;
     oaRef = removePositions(pgr.oArray, '~isreference');
     pgrRef = set(pgr, 'oArray', oaRef);
     qRef = segmentImage(pgrRef, Igrid, x(bRef), y(bRef), rot);
     qRef = get(qRef);
     s0s(bRef) = [qRef.oSegmentation];
     [x1, y1] = getPosition(s0s);
     mp1 = midPoint(pgr.oArray, x1, y1);
     %shift the non-ref principal segmentation based on mp shift found
     s0s(~bRef) = shift(s0(~bRef),mp1 - mp0);
     qImage = setSet(qFixed,'oSegmentation', s0s);
     % and quantify for final output
     idxThis = find(bThis);
     for j=1:length(idxThis)
         q(:, idxThis(j)) = quantify(qImage, I(:,:,idxThis(j)) );
     end
end


