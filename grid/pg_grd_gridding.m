function [params, exitCode] = pg_grd_gridding(params)

exitCode = 0;

% [x,y,rot,params] = pg_global_grid(params, params.image_grid);
if ~isfield(params, 'image_grid') 
    exitCode = -61;
    pg_error_message('grid.no_imagegrid_field', exitCode);
    
    return;
end

if ~isfield(params, 'image_grid_preproc') || ~isfield(params, 'rsf')
    exitCode = -62;
    pg_error_message('grid.preproc.pp_fields', exitCode);
    
    return;
end


I     = params.image_grid_preproc;
rsf   = params.rsf;
%[x,y,rot] = globalGrid(pgr, I)
% create the grid image. Note that the grid image may be resized with
% respect to the input images for efficiency. rsf is the resize factor.
% rsf     = params.gridImageSize./size(I);

% params  = pg_pp_rescale(params, rsf(1));


% Igrid = getPrepImage(oP, imresize(I, params.gridImageSize));
% Igrid = pg_pp_fun(params, imresize(I, params.gridImageSize));

% params.image_grid_preproc;
% params.rsf = rsf;

% Igrid
% imagesc(Igrid)
% rsf
% params = pg_rescale(params, rsf);


% call the grid finding method
% [x,y, rot, params, mx]

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
%     error('Parameter ''row'' has not been set.');
    exitCode = -63;
    pg_error_message('grid.no_row', exitCode);
    
    return;
end
if isempty(params.grdCol)
%     error('Parameter ''col'' has not been set.');
    exitCode = -64;
    pg_error_message('grid.no_col', exitCode);
    
    return;
end
if size(params.grdRow,2) > 1 || size(params.grdCol,2) > 1 
%     error('Parameters ''row'' and ''col'' must be vectors');
    exitCode = -65;
    pg_error_message('grid.rowcol_vector', exitCode);
    
    return;
end
if length(params.grdRow) ~= length(params.grdCol)
%     error('Parameters ''row'' and ''col'' must be vectors of the same length');
    exitCode = -66;
    pg_error_message('grid.rowcol_length', exitCode);
    
    return;
end




if ~isequal(size(params.grdXOffset),size(params.grdRow)) || ~isequal(size(params.grdYOffset),size(params.grdRow))
%     error('Parameters ''xOffset'' and ''yOffset'' must be vectors of the same length as ''row'' and ''col''');
    exitCode = -67;
    pg_error_message('grid.xyoff_length', exitCode);
    
    return;
end

if ~isempty(params.grdXFixedPosition)
    if ~isequal(size(params.grdXFixedPosition),size(params.grdRow)) || ~isequal(size(params.grdYFixedPosition),size(params.grdRow))
%         error('Parameters ''xFixedPosition'' and ''yFixedPosition'' must be vectors of the same length as ''row'' and ''col''');
        exitCode = -68;
        pg_error_message('grid.xyfix_length', exitCode);
        
        return;
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
%     mx = pg_mid_point(params, params.grdXFixedPosition, params.grdYFixedPosition);
%     rot = 0;
    
    params.mx  =  pg_mid_point(params, params.grdXFixedPosition, params.grdYFixedPosition);
    params.rot = 0;
    return
end

if isempty(params.grdRoiSearch)
    params.grdRoiSearch = true(size(I));
end

if isempty(params.grdSpotPitch)
%     error('Parameter ''spotPitch'' has not been set.');
    exitCode = -69;
    pg_error_message('grid.no_spotpitch', exitCode);
    
    return;
end
if isempty(params.grdSpotSize)
%     error('Parameter ''spotSize'' has not been set.');
    exitCode = -70;
    pg_error_message('grid.no_spotsize', exitCode);
    
    return;
end


%grdPrivate is initially set (as default) empty and filled here
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
%         error('Unknown value for grid property ''method''');
        exitCode = -71;
        pg_error_message('grid.unknown_method', exitCode, params.grdMethod);

        return;
end
% override the final results with the xFixedPosition and yFixedPosition
% props.
x(~x) = cx(~x);
y(~y) = cy(~y);




% [x,y,rot, ~] = pg_grid_find(params, Igrid);


% scale back to the original size and return
x = x/rsf(1);
y = y/rsf(2);
x(x<1) = 1;
y(y<1) = 1;
% Preproc image may be resized, so we need to use the original image size
x(x>size(params.image_grid,1)) = size(params.image_grid,1);
y(y>size(params.image_grid,2)) = size(params.image_grid,2);


params.grdXFixedPosition = x;
params.grdYFixedPosition = y;
params.grdRot            = rot;
params.grdMx             = mx;

params.grdSpotPitch      = params.grdSpotPitch ./ params.rsf ;
params.grdSpotSize       = params.grdSpotSize / mean(params.rsf);



end