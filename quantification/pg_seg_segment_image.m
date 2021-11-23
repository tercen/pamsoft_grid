function [params, exitCode] = pg_seg_segment_image(params)

% If even a single spot was moved, segment the whole grid

if isfield(params, 'isManual') && ~any(params.isManual)
    
    disp('Segmentation already run. Skipping');
    exitCode = 0;
    
    
     
    cx =params.gridX;
    cy = params.gridY;
    r = params.diameter;
    
    I = params.image_seg;
    nSpots = length( cx);
    spots = repmat( pg_seg_create_spot_structure(params), nSpots, 1);
    for i = 1:nSpots
    
        [xFit, yFit] = pg_circle([cx(i),cy(i)],r(i)/2,round(pi*r(i)/2)/2);
        Ilocal = roipoly(I, yFit, xFit);

        spots(i).diameter = spots(i).diameter(i);
        spots(i).bsSize = size(Ilocal);
        spots(i).bsTrue = find(Ilocal);
        spots(i).finalMidpoint = [cx(i) cy(i)];
        spots(i).grdSpotPitch = params.grdSpotPitch;
        
    end
    
    params.spots = spots;
    params = pg_seg_set_background_mask(params,size(I));

    return
end



maxSubIter      = 2; % Max iterations for subs vs refs refinement 
maxRefSubOffset = 0.15; % Max offset criterium between refs and subs.

if isequal(params.verbose, 'on') || isequal(params.verbose, 'yes')
    bVerbose = true;
else
    bVerbose = false;
end

if isequal(params.grdOptimizeRefVsSub, 'yes')
    bOptimize = true;
else
    bOptimize = false;
end

spotPitch = params.grdSpotPitch;
isRef     = logical(params.grdIsReference); 

% first segmentation pass is for refs only
arrayRow = params.grdRow; 
arrayCol = params.grdCol; 
xOff     = params.grdXOffset;
yOff     = params.grdYOffset; 
xFxd     = params.grdXFixedPosition; 
yFxd     = params.grdYFixedPosition; 

% ID       = params.qntSpotID; 



[paramsRef, exitCode] = pg_qnt_get_position_array(params, 'isreference');
if exitCode < 0
    return;
end

[paramsSub, exitCode] = pg_qnt_get_position_array(params, '~isreference');
if exitCode < 0
    return;
end


x = params.gridX;
y = params.gridY;


if any(~isRef)
    % segment as separate reference array (different quality settings)
    [paramsRef,~, mpRefs] = pg_seg_segment_and_refine(paramsRef, x(isRef), y(isRef), true);
else
    [paramsRef,~, mpRefs] = pg_seg_segment_and_refine(paramsRef, x(isRef), y(isRef), false);
end

if all(paramsRef.seg_res.isBad)
   % none of the references was properly found: gridding failure
   exitCode = -21;
   pg_error_message(exitCode);
   return
end


% if any, segment and quantify the substrates (non refs), allow for another
% pass if the offset between resf and sub is to large
bFixedSpot = xFxd > 0; % not refined spots
if any(~isRef)
    
    paramsRefined        = params;
    paramsRefined.grdRow = arrayRow(~isRef);
    paramsRefined.grdCol = arrayCol(~isRef);
    paramsRefined.grdIsReference = ~isRef(~isRef);
    paramsRefined.grdXOffset     = xOff(~isRef);
    paramsRefined.grdYOffset     = yOff(~isRef);
    paramsRefined.grdXFixedPosition = xFxd(~isRef);
    paramsRefined.grdYFixedPosition = yFxd(~isRef);
    paramsRefined.grdSpotPitch      = spotPitch;
    paramsRefined.grdRotation       = params.grdRotation;
    
    % These are the initial coordinates, based on the ref spot refined
    % midpoint
    
    [xSub,ySub, exitCode] = pg_grd_coordinates(paramsRefined, mpRefs,0);
  
    %%
    
    if exitCode < 0
        return
    end
    
    for pass = 1:maxSubIter
        
        [paramsSub, spotPitch, mpSub] = pg_seg_segment_and_refine(paramsSub, xSub, ySub);

        if all(bFixedSpot(~isRef)) || ~bOptimize
            break;
        end
        if ~isempty(mpSub)
            delta = norm(mpSub - mpRefs)/spotPitch;
        else
            % this handles the case when to little substrates have been
            % properly found: no further optiization
            break;
        end
       if bVerbose
            disp('Ref Vs Sub optimization')
            disp(['Delta: ', num2str(delta)])
            if delta > maxRefSubOffset && pass < maxSubIter
                disp('Starting optimization');
            end
        end
        if delta <= maxRefSubOffset
            % no optimization needed
            break;
        end
          % optimize the sub coordinates
        [xr,yr, exitCode] = pg_grd_coordinates(arrayRefined, mpSub);

        xSub(~bFixedSpot(~isRef)) = xr(~bFixedSpot(~isRef)); % adapt the ~bFixedSpot coordinates 
        ySub(~bFixedSpot(~isRef)) = yr(~bFixedSpot(~isRef)); 
        mpRefs = mpSub;          
    end

    params.spots(~isRef) = paramsSub.spots;
    params.segOutliers(~isRef) = paramsSub.segOutliers;
    
    params.segIsBad(~isRef)      = paramsSub.seg_res.isBad;
    params.segIsEmpty(~isRef)    = paramsSub.seg_res.isEmpty;
    params.segIsReplaced(~isRef) = paramsSub.seg_res.isReplaced;
    
end

params.segOutliers(isRef) = paramsRef.segOutliers;
params.spots(isRef)       = paramsRef.spots;

params.segIsBad(isRef)      = paramsRef.seg_res.isBad;
params.segIsEmpty(isRef)    = paramsRef.seg_res.isEmpty;
params.segIsReplaced(isRef) = paramsRef.seg_res.isReplaced;

if ~isfield(params, 'isManual')
    params.isManual = zeros(length(params.spots),1);
end

if ~isfield(params, 'diameter')
    params.diameter = zeros(length(params.spots),1);
end

% %%
% x = [params.gridX];
% y = [params.gridY];
% 
% 
% %%


for i = 1:length(params.spots)
    spot = params.spots(i); 
    
    params.gridX(i) = spot.finalMidpoint(1);
    params.gridY(i) = spot.finalMidpoint(2);
    params.diameter(i) = spot.diameter;
    
end

% x2 = [params.gridX];
% y2 = [params.gridY];
% 
% scatter( x, y ); hold on;
% scatter(x2, y2);
end