function [x,y, rot, params, mx] = pg_grid_find(params, I)
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


if isempty(params.grdRow)
    error('Parameter ''row'' has not been set.');
end
if isempty(params.grdCol)
    error('Parameter ''col'' has not been set.');
end
if size(params.grdRow,2) > 1 || size(params.grdCol,2) > 1 
    error('Parameters ''row'' and ''col'' must be vectors');
end
if length(params.grdRow) ~= length(params.grdCol)
    error('Parameters ''row'' and ''col'' must be vectors of the same length');
end




if ~isequal(size(params.grdXOffset),size(params.grdRow)) || ~isequal(size(params.grdYOffset),size(params.grdRow))
    error('Parameters ''xOffset'' and ''yOffset'' must be vectors of the same length as ''row'' and ''col''');
end

if ~isempty(params.grdXFixedPosition)
    if ~isequal(size(params.grdXFixedPosition),size(params.grdRow)) || ~isequal(size(params.grdYFixedPosition),size(params.grdRow))
        error('Parameters ''xFixedPosition'' and ''yFixedPosition'' must be vectors of the same length as ''row'' and ''col''');
    end
else
    params.grdXFixedPosition = zeros(size(params.grdRow));
    params.grdYFixedPosition = zeros(size(params.grdCol));
end

% if all xFixedPosition and yFixedPosition are non-zero (i.e. already set)
% return immediately

x = params.grdXFixedPosition;
y = params.grdYFixedPosition;

if ~any(~params.grdXFixedPosition) & ~any(~params.grdYFixedPosition)
    mx = pg_mid_point(params, params.grdXFixedPosition, params.grdYFixedPosition);
    rot = 0;
    return
end

if isempty(params.grdRoiSearch)
    params.grdRoiSearch = true(size(I));
end

if isempty(params.grdSpotPitch)
    error('Parameter ''spotPitch'' has not been set.');
end
if isempty(params.grdSpotSize)
    error('Parameter ''spotSize'' has not been set.');
end



private = params.grdPrivate;
switch params.grdMethod
    case 'correlation2D'
        % check if a template exists for the current grid object or
        % the template needs to be updated.
        if ~isfield(private, 'fftTemplate')
            % update template
  
            private(1).fftTemplate     = pg_make_fft_template(params, size(I));
            % store the current grid settings so it can be checked if the
            % template needs to be updated on the next call.
            private(1).templateState = params;
            private(1).imageSize    = size(I);
            
        elseif  ~isequal(private.templateState, params) || ...
                ~isequal(private.imageSize, size(I))
                 % template needs updating
                
            private(1).fftTemplate     = pg_make_fft_template(params, size(I));
            % store the current grid settings so it can be checked if the
            % template needs to be updated on the next call.
            private(1).templateState = params;
            private(1).imageSize     = size(I);
        end
        
        
        params.grdPrivate  = private;
        
      
        [mx, iRot] = pg_template_correlation(I, private.fftTemplate, params.grdRoiSearch);
        rot = params.grdRotation(iRot);
        
        % get the coordinates for set1, set2 respectivley
        bSet1 = params.grdRow > 0 & params.grdCol > 0;
        bSet2 = ~bSet1;
        cx = -ones(size(bSet1));
        cy = -ones(size(cx));
        if any(bSet1)
            [cx(bSet1), cy(bSet1)] = pg_grid_coordinates(params.grdRow(bSet1), params.grdCol(bSet1),...
                params.grdXOffset(bSet1), params.grdYOffset(bSet1), mx, params.grdSpotPitch, rot);
        end
        if any(bSet2)
            [cx(bSet2), cy(bSet2)] = pg_grid_coordinates(params.grdRow(bSet2), params.grdCol(bSet2), ...
                params.grdXOffset(bSet2), params.grdYOffset(bSet2), mx, params.grdSpotPitch, rot);
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

