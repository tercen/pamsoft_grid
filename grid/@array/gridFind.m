function [x,y, rot, g, mx] = gridFind(g, I)
% array.gridFind
% function [x,y,rot,oArrayOut] = gridFind(oArray, I)
% IN:
% oArray, grid object as defined by oArray = array(args)
% I, image to find the grid on.
% OUT:
% x [nRow, nCol] , x(i,j) is the x coordinate of spot(i,j)
% y [nRow, nCol] , y(i,j) is the y coordinate of spot(i,j)
% rot, optimal rotation out of the rotation axis supplied to the grid
% object
% oArrayOut: updated grid object, in case of array.method = 'corelation2D' the first
% call of the gridFind function will be much slower than subsequent calls
% with the updated object.
% See also array/array, array/fromfile
%
% method: 'correlation2D', uses 2D template correlation to find the
% location of the grid.

% check if required parameters have been set
if isempty(g.row)
    error('Parameter ''row'' has not been set.');
end
if isempty(g.col)
    error('Parameter ''col'' has not been set.');
end
if size(g.row,2) > 1 || size(g.col,2) > 1 
    error('Parameters ''row'' and ''col'' must be vectors');
end
if length(g.row) ~= length(g.col)
    error('Parameters ''row'' and ''col'' must be vectors of the same length');
end




if ~isequal(size(g.xOffset),size(g.row)) || ~isequal(size(g.yOffset),size(g.row))
    error('Parameters ''xOffset'' and ''yOffset'' must be vectors of the same length as ''row'' and ''col''');
end

if ~isempty(g.xFixedPosition)
    if ~isequal(size(g.xFixedPosition),size(g.row)) || ~isequal(size(g.yFixedPosition),size(g.row))
        error('Parameters ''xFixedPosition'' and ''yFixedPosition'' must be vectors of the same length as ''row'' and ''col''');
    end
else
    g.xFixedPosition = zeros(size(g.row));
    g.yFixedPosition = zeros(size(g.col));
end

% if all xFixedPosition and yFixedPosition are non-zero (i.e. already set)
% return immediately

x = g.xFixedPosition;
y = g.yFixedPosition;
if ~any(~g.xFixedPosition) & ~any(~g.yFixedPosition)
    mx = midPoint(g, g.xFixedPosition, g.yFixedPosition);
    rot = 0;
    return
end

if isempty(g.roiSearch)
    g.roiSearch = true(size(I));
end

if isempty(g.spotPitch)
    error('Parameter ''spotPitch'' has not been set.');
end
if isempty(g.spotSize)
    error('Parameter ''spotSize'' has not been set.');
end





private = g.private;
switch g.method
    case 'correlation2D'
        % check if a template exists for the current grid object or
        % the template needs to be updated.
        if ~isfield(private, 'fftTemplate')
            % update template
  
            private(1).fftTemplate     = makeFFTTemplate(g, size(I));
            % store the current grid settings so it can be checked if the
            % template needs to be updated on the next call.
            private(1).templateState = struct(g);
            private(1).imageSize = size(I);
        elseif  ~isequal(private.templateState, struct(g)) || ...
                ~isequal(private.imageSize, size(I))
                 % template needs updating
                
            private(1).fftTemplate     = makeFFTTemplate(g, size(I));
            % store the current grid settings so it can be checked if the
            % template needs to be updated on the next call.
            private(1).templateState = struct(g);
            private(1).imageSize = size(I);
        end
        g.private  = private;
        
      
        [mx, iRot] = templateCorrelation(I, private.fftTemplate,g.roiSearch);
        rot = g.rotation(iRot);
        
        % get the coordinates for set1, set2 respectivley
        bSet1 = g.row > 0 & g.col > 0;
        bSet2 = ~bSet1;
        cx = -ones(size(bSet1));
        cy = -ones(size(cx));
        if any(bSet1)
            [cx(bSet1), cy(bSet1)] = gridCoordinates(g.row(bSet1), g.col(bSet1), g.xOffset(bSet1), g.yOffset(bSet1), mx, g.spotPitch, rot);
        end
        if any(bSet2)
            [cx(bSet2), cy(bSet2)] = gridCoordinates(g.row(bSet2), g.col(bSet2), g.xOffset(bSet2), g.yOffset(bSet2), mx, g.spotPitch, rot);
        end
        
        cx = cx-2;
        cy = cy-2;
        
        
    otherwise
        error('Unknown value for grid property ''method''');
end
% override the final results with the xFixedPosition and yFixedPosition
% props.
x(~x) = cx(~x);
y(~y) = cy(~y);

