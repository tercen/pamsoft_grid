function [params, exitCode] = pg_grd_gridding(params)

exitCode = 0;

if ~isfield(params, 'image_grid') 
    exitCode = -11;
    pg_error_message(exitCode, 'image_grid');
    
    return;
end

if ~isfield(params, 'image_grid_preproc') || ~isfield(params, 'rsf')
    exitCode = -11;
    pg_error_message( exitCode, 'image_grid_preproc');
    
    return;
end


I     = params.image_grid_preproc;
rsf   = params.rsf;


if isempty(params.grdRow)
%     error('Parameter ''row'' has not been set.');
    exitCode = -11;
    pg_error_message(exitCode, 'grdRow');
    
    return;
end
if isempty(params.grdCol)
%     error('Parameter ''col'' has not been set.');
    exitCode = -11;
    pg_error_message(exitCode, 'grdCol');
    
    return;
end
if size(params.grdRow,2) > 1 || size(params.grdCol,2) > 1 
    exitCode = -14;
    pg_error_message(exitCode);
    
    return;
end
if length(params.grdRow) ~= length(params.grdCol)
    exitCode = -15;
    pg_error_message( exitCode, 'grdRow', 'grdCol' );
    
    return;
end




if ~isequal(size(params.grdXOffset),size(params.grdRow)) || ~isequal(size(params.grdYOffset),size(params.grdRow))
%     error('Parameters ''xOffset'' and ''yOffset'' must be vectors of the same length as ''row'' and ''col''');
    exitCode = -16;
    pg_error_message(exitCode);
    
    return;
end

if ~isempty(params.grdXFixedPosition)
    if ~isequal(size(params.grdXFixedPosition),size(params.grdRow)) || ~isequal(size(params.grdYFixedPosition),size(params.grdRow))

        exitCode = -17;
        pg_error_message(exitCode);
        
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
    params.mx  =  pg_mid_point(params, params.grdXFixedPosition, params.grdYFixedPosition);
    params.rot = 0;
    
    
    params.gridX = x;
    params.gridY = y;


    % This is used to simplify saving. Rotation then is picked as first value
    % later on
    params.grdRotation       = repmat(params.rot, length(x), 1);
    params.grdMx             = params.mx;

    params.grdSpotPitch      = params.grdSpotPitch ./ params.rsf ;
    params.grdSpotSize       = params.grdSpotSize / mean(params.rsf);
    
    return
end

if isempty(params.grdRoiSearch)
    params.grdRoiSearch = true(size(I));
end

if isempty(params.grdSpotPitch)
    exitCode = -11;
    pg_error_message(exitCode, 'grdSpotPitch');
    
    return;
end
if isempty(params.grdSpotSize)
    exitCode = -11;
    pg_error_message(exitCode, 'grdSpotSize');
    
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

        [mx, iRot,rot] = pg_template_correlation(I, private.fftTemplate, params.grdRoiSearch);
        if isnan(rot)
          rot        = params.grdRotation(iRot);
        end
        
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
        exitCode = -13;
        pg_error_message(exitCode, 'grdMethod', params.grdMethod);

        return;
end
% override the final results with the xFixedPosition and yFixedPosition
% props.
x(~x) = cx(~x);
y(~y) = cy(~y);


% scale back to the original size and return
x = x/rsf(1);
y = y/rsf(2);
x(x<1) = 1;
y(y<1) = 1;


% Preproc image may be resized, so we need to use the original image size
x(x>size(params.image_grid,1)) = size(params.image_grid,1);
y(y>size(params.image_grid,2)) = size(params.image_grid,2);

params.gridX = x;
params.gridY = y;

% This is used to simplify saving. Rotation then is picked as first value
% later on
params.grdRotation       = repmat(rot, length(x), 1);
params.grdMx             = mx;

params.calcSpotPitch = params.grdSpotPitch ./ params.rsf;

params.grdSpotPitch      = params.grdSpotPitch / (params.rsf);
params.grdSpotSize       = params.grdSpotSize / mean(params.rsf);


end