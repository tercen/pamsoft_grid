function q = seriesAdaptLocal(pgr, I, varargin)
% obsolete as off PamGrid 4.2!
% function q = seriesAdaptLocal(pgr, I, varargin)
% analysis of image series with:
% global grid finding on fixed image
% local spot finding repeated on each image
opdef.cycle = [];
opdef.exposure = [];
op = setVarArginOptions(opdef, [], varargin{:});

% sort images to cycle
if isempty(op.cycle)
    op.cycle = 1:size(I,3);
end
if isempty(op.exposure)
    op.exposure = ones(size(op.cycle));
end

[cycle, iSort] = sort(op.cycle);
exp = op.exposure(iSort);
I = I(:, :, iSort);

[~,x,y,rot] = seriesFixed(pgr, I, 'exposure', exp, ...
                                  'cycle', cycle, ...
                                  'action', 'global');
uCycle = unique(cycle);
sl = get(pgr.oSpotQuantification, 'saturationLimit');
keyboard
q = repmat(spotQuantification, numel(x), size(I,3));
for i=1:length(uCycle)
    bThis = cycle == uCycle(i); 
    Iseg = I(:,:,bThis);
    if sum(bThis) > 1
        Iseg = combineExposures(Iseg, exp(bThis), sl);
    end
    qSegmented = segmentImage(pgr, Iseg, x, y, rot);
    idxThis = find(bThis);
    for j=1:idxThis
        q(:,idxThis(j)) = quantify(qSegmented, I(:,:,idxThis(j)));
    end
end
                           

