function [q,x,y,rot] = seriesFixed(pgr, I, varargin)
% function q = seriesFixed(pgr, I, varargin)
% Analysis of image series with:
% Global gridding on a fixed image
% Local spot finding on a fixed image
opdef.cycle = [];
opdef.exposure = [];
opdef.action = {'quantify', 'segment', 'global'};
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
% produce the segmentation image and the grid image
uCycle = unique(cycle);
sl = get(pgr.oSpotQuantification, 'saturationLimit');
bLast  = cycle == uCycle(end);
bFirst = cycle == uCycle(1);
switch pgr.useImage
    case 'Last'
        Igrid = I(:,:,bLast);
        if sum(bLast) > 1
            Igrid = combineExposures(Igrid, exp(bLast),sl);
        end
        Iseg = Igrid;
    case 'Refs on First then Last'
        Igrid = I(:,:,bFirst);
        if sum(bFirst) > 1
            Igrid = combineExposures(Igrid, exp(bFirst),sl);
        end
        Iseg = I(:,:,bLast);
        if sum(bLast) > 1
            Iseg = combineExposures(Iseg, exp(bLast), sl);
        end
    case 'First'
        Igrid = I(:,:,bFirst);
        if sum(bLast) > 1
            Igrid = combineExposures(Igrid, exp(bFirst),sl);
        end
        Iseg = Igrid;
    otherwise 
        error('Invalid value for pamgrid parameter ''useImage''')                                            
end
[x,y,rot] = globalGrid(pgr, Igrid);
x

switch op.action
    case 'global'
        q = [];
    case 'segment'
        q = segmentImage(pgr, Iseg, x, y, rot);
    case 'quantify'
        qSegmented = segmentImage(pgr, Iseg, x, y, rot);
        for i=1:size(I,3)
            q(:,i) = quantify(qSegmented, I(:,:,i));
        end
    otherwise
        error('Invalid value for ''action''')
end


                                 