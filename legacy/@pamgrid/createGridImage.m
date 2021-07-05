function [Igrid, rsizFactor] = createGridImage(pgr, I, varargin)
% function [Igrid, resizeFactor] = createGridImage(I, varargin)
opdef.cycle = [];
opdef.exposure = [];

op = setVarArginOptions(opdef, [], varargin{:});

% generate dft cycle and exposure vectors, if not on input.
if isempty(op.cycle)
    op.cycle = (1:size(I,3))';
end
if isempty(op.exposure)
    op.exposure = ones(size(I,3), 1);
end

% error checking
if length(op.cycle) ~= size(I,3)
    error('Length of parameter vector ''cycle'' must be equal to the number of images');
end
if length(op.exposure) ~= size(I,3)
    error('Length of parameter vector ''exposure'' must be equal to the number of images');
end

[op.cycle, iSort] = sort(op.cycle);
I = I(:,:,iSort);

% create the grid image
switch pgr.useImage
    case 'Last'
        I = I(:,:,end);
    case 'First'
        I = I(:,:,1);
    case 'Refs on First then Last'
        I = I(:,:,1);
    case 'All'
        sl = get(pgr.oSpotQuantification, 'saturationLimit');
        I = combineExposures(I, op.exposure,sl);
    otherwise
        error(['Unknown option for pamgrid.useImage: ', pgr.useImage]);
end

rsizFactor = pgr.gridImageSize./size(I);
oP = rescale(pgr.oPreprocessing, rsizFactor(1));
Igrid = getPrepImage(oP, imresize(I, pgr.gridImageSize));




    
    





