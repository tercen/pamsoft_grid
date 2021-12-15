function [params, exitCode] = pg_seg_segment_image(params)

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

refSpot = find(isRef);


params.spots(refSpot) = paramsRef.spots;


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
    
    % These are the initial coordinates, based on the ref spot refined midpoint
    [xSub,ySub, exitCode] = pg_grd_coordinates(paramsRefined, mpRefs, params.grdRotation);

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
        [xSub,ySub, exitCode] = pg_grd_coordinates(paramsRefined, mpSub);

        xSub(~bFixedSpot(~isRef)) = xr(~bFixedSpot(~isRef)); % adapt the ~bFixedSpot coordinates 
        ySub(~bFixedSpot(~isRef)) = yr(~bFixedSpot(~isRef)); 


        mpRefs = mpSub;          
    end
    

    params.spots(~isRef)       = paramsSub.spots;
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


for i = 1:length(params.spots)
    spot = params.spots(i); 
    
    params.gridX(i) = spot.finalMidpoint(1);
    params.gridY(i) = spot.finalMidpoint(2);
    
    params.grdXFixedPosition(i) = spot.finalMidpoint(1);
    params.grdYFixedPosition(i) = spot.finalMidpoint(2);
    
    params.diameter(i) = spot.diameter;
    
end

end