function [params, exitCode] = pg_seg_segment_image(params)

exitCode        = 0;
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
isRef     = logical(params.grdIsReference); %get(pgr.oArray, 'isreference');%= get(pgr.oArray, 'spotPitch');
% pgr.oSegmentation = set(pgr.oSegmentation, 'spotPitch', spotPitch);

% params.grdIsReference
% preallocate array of spotQuantification objects.
% @TODO Change this to a structure

% qOut = repmat(pgr.oSpotQuantification, size(x,1), 1);

% first segmentation pass is for refs only
arrayRow = params.grdRow; %get(pgr.oArray, 'row');
arrayCol = params.grdCol; %get(pgr.oArray, 'col');
xOff     = params.grdXOffset;% get(pgr.oArray, 'xOffset');
yOff     = params.grdYOffset; %get(pgr.oArray, 'yOffset');
xFxd     = params.grdXFixedPosition; %get(pgr.oArray, 'xFixedPosition');
yFxd     = params.grdYFixedPosition; %get(pgr.oArray, 'yFixedPosition');
ID       = params.qntSpotID; %get(pgr.oArray, 'ID');

% oaRef = removePositions(pgr.oArray, '~isreference');
% oaSub = removePositions(pgr.oArray, 'isreference');

[paramsRef, exitCode] = pg_qnt_get_position_array(params, 'isreference');
if exitCode < 0
    return;
end

[paramsSub, exitCode] = pg_qnt_get_position_array(params, '~isreference');
if exitCode < 0
    return;
end


% return

% pgrRef = set(pgr, 'oArray', oaRef);
% pgrSub = set(pgr, 'oArray', oaSub);
x = params.gridX;
y = params.gridY;
if any(~isRef)
    % segment as separate reference array (different quality settings)
%     [qRefs,~, mpRefs] = segmentAndRefine(pgrRef, I, xFxd(isRef), yFxd(isRef), params.grd, true);
    [paramsRef,~, mpRefs] = pg_seg_segment_and_refine(paramsRef, x(isRef), y(isRef), true);
else
%     [qRefs,~, mpRefs] = segmentAndRefine(pgrRef, I, xFxd(isRef),  yFxd(isRef), rot, false);
    [paramsRef,~, mpRefs] = pg_seg_segment_and_refine(paramsRef, x(isRef), y(isRef), false);
end




% if all(get(qRefs, 'isBad'))
if all(paramsRef.seg_res.isBad)
   % none of the references was properly found: gridding failure
   exitCode = -21;
   pg_error_message(exitCode);
   return
%    error('None of the reference spots was properly found')
end



% @FIXME This needs to be more sensibly passed
% As in, what needs to be saved from the segmentation?
% params.seg_ref = paramsRef;

% qOut(isRef) = qRefs; % refs are segmented!



% if any, segment and quantify the substrates (non refs), allow for another
% pass if the offset between resf and sub is to large
bFixedSpot = xFxd > 0; % not refined spots
if any(~isRef)
    
    paramsRefined = params;
    paramsRefined.grdRow = arrayRow(~isRef);
    paramsRefined.grdCol = arrayCol(~isRef);
    paramsRefined.grdIsReference = ~isRef(~isRef);
    paramsRefined.grdXOffset = xOff(~isRef);
    paramsRefined.grdYOffset = yOff(~isRef);
    paramsRefined.grdXFixedPosition = xFxd(~isRef);
    paramsRefined.grdYFixedPosition = yFxd(~isRef);
    paramsRefined.grdSpotPitch = spotPitch;
    paramsRefined.grdRotation = params.grdRotation;
    

%     arrayRefined = array(...
%         'row', arrayRow(~isRef), ...
%         'col', arrayCol(~isRef), ...
%         'isreference', ~isRef(~isRef), ... % set the ref prop to on to enable mp etc calculation
%         'xOffset', xOff(~isRef), ...
%         'yOffset', yOff(~isRef), ...
%         'xFixedPosition', xfxd(~isRef), ...
%         'yFixedPosition', yfxd(~isRef), ...
%         'spotPitch', spotPitch, ...
%         'rotation', rot);
    % These are the initial coordinates, based on the ref spot refined
    % midpoint
%     [xSub, ySub] = coordinates(arrayRefined, mpRefs);
    [xSub,ySub, exitCode] = pg_grd_coordinates(paramsRefined, mpRefs);
    for pass = 1:maxSubIter

%         [qSub, spotPitch, mpSub] = segmentAndRefine(pgrSub, I, xSub,ySub, rot); 
        
        [paramsSub, spotPitch, mpSub] = pg_seg_segment_and_refine(paramsSub, xSub, ySub);
     

        % @TODO Fine up to here
        
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
%         [xr,yr] = coordinates(arrayRefined, mpSub); % get expected coordinates from first pass midpoint
        xSub(~bFixedSpot(~isRef)) = xr(~bFixedSpot(~isRef)); % adapt the ~bFixedSpot coordinates 
        ySub(~bFixedSpot(~isRef)) = yr(~bFixedSpot(~isRef)); 
        mpRefs = mpSub;          
    end
%     qOut(~isRef) = qSub;
    params.spots(~isRef) = paramsSub.spots;
    params.segOutliers(~isRef) = paramsSub.segOutliers;
    
    params.segIsBad(~isRef)      = paramsSub.seg_res.isBad;
    params.segIsEmpty(~isRef)    = paramsSub.seg_res.isEmpty;
    params.segIsReplaced(~isRef) = paramsSub.seg_res.isReplaced;
    
    % @FIXME Set the desired output here
end

params.segOutliers(isRef) = paramsRef.segOutliers;
params.spots(isRef)       = paramsRef.spots;

params.segIsBad(isRef)      = paramsRef.seg_res.isBad;
params.segIsEmpty(isRef)    = paramsRef.seg_res.isEmpty;
params.segIsReplaced(isRef) = paramsRef.seg_res.isReplaced;
% 
% qOut = setSet(qOut, 'ID', ID, ...
%                     'arrayRow', arrayRow, ...
%                     'arrayCol', arrayCol);
%%

% 
% clc;
% % segAreaSize = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_areaSize.txt');
% % grdSpotPitch = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_spotPitch.txt');
% % segNFilterDisk = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_nFilterDisk.txt');
% % segEdgeSensitivity = readmatrix( '/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_edgeSensitivity.txt');
% % segMinEdgePixels = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_minEdgePixels.txt');
% % segBgOffset = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_bgOffset.txt');
% % initialMidpoint = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_initialMidpoint.txt');
% % finalMidpoint = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_finalMidpoint.txt');
% % diameter = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_diameter.txt');
% % chisqr = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_chisqr.txt');
% % bsLuIndex = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_bsLuIndex.txt');
% % bsSize = readmatrix('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_bsSize.txt');
% % bbTrue = readmatrix( '/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy_bbTrue.txt');
% 
% vals = load('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy.mat');
% 
% i = 100;
% 
% plot( params.spots(i).bbTrue)
% hold on
% plot( vals.val12 )
% 
% if all(vals.val1 == params.spots(i).segAreaSize )
%     fprintf('[SPOT %d] segAreaSize is equal\n', 1);
% else
%     fprintf('[SPOT %d] segAreaSize is DIFFERENT\n', 1);
% end
% 
% if all(vals.val2 == params.spots(i).grdSpotPitch )
%     fprintf('[SPOT %d] grdSpotPitch is equal\n', 1);
% else
%     fprintf('[SPOT %d] grdSpotPitch is DIFFERENT\n', 1);
% end
% 
% if all(vals.val3 == params.spots(i).segNFilterDisk )
%     fprintf('[SPOT %d] segNFilterDisk is equal\n', 1);
% else
%     fprintf('[SPOT %d] segNFilterDisk is DIFFERENT\n', 1);
% end
% 
% if all(vals.val == params.spots(i).segEdgeSensitivity )
%     fprintf('[SPOT %d] segEdgeSensitivity is equal\n', 1);
% else
%     fprintf('[SPOT %d] segEdgeSensitivity is DIFFERENT\n', 1);
% end
% 
% if all(vals.val4 == params.spots(i).segMinEdgePixels )
%     fprintf('[SPOT %d] segMinEdgePixels is equal\n', 1);
% else
%     fprintf('[SPOT %d] segMinEdgePixels is DIFFERENT\n', 1);
% end
% 
% 
% if all(vals.val5 == params.spots(i).segBgOffset )
%     fprintf('[SPOT %d] segBgOffset is equal\n', 1);
% else
%     fprintf('[SPOT %d] segBgOffset is DIFFERENT\n', 1);
% end
% 
% 
% if all(vals.val6 == params.spots(i).initialMidpoint )
%     fprintf('[SPOT %d] initialMidpoint is equal\n', 1);
% else
%     fprintf('[SPOT %d] initialMidpoint is DIFFERENT\n', 1);
% end
% % isequal(finalMidpoint, params.spots(i).finalMidpoint )
% if all(vals.val7 == params.spots(i).finalMidpoint )
%     fprintf('[SPOT %d] finalMidpoint is equal\n', 1);
% else
%     fprintf('[SPOT %d] finalMidpoint is DIFFERENT\n', 1);
% end
% 
% if all(vals.val8 == params.spots(i).diameter )
%     fprintf('[SPOT %d] diameter is equal\n', 1);
% else
%     fprintf('[SPOT %d] diameter is DIFFERENT\n', 1);
% end
% 
% 
% 
% if all(vals.val9 == params.spots(i).chisqr )
%     fprintf('[SPOT %d] chisqr is equal\n', 1);
% else
%     fprintf('[SPOT %d] chisqr is DIFFERENT\n', 1);
% end
% 
% 
% if all(vals.val10 == params.spots(i).bsLuIndex )
%     fprintf('[SPOT %d] bsLuIndex is equal\n', 1);
% else
%     fprintf('[SPOT %d] bsLuIndex is DIFFERENT\n', 1);
% end
% 
% 
% 
% if all(vals.val11 == params.spots(i).bsSize )
%     fprintf('[SPOT %d] bsSize is equal\n', 1);
% else
%     fprintf('[SPOT %d] bsSize is DIFFERENT\n', 1);
% end
% 
% 
% 
% if all(vals.val12 == params.spots(i).bbTrue )
%     fprintf('[SPOT %d] bbTrue is equal\n', 1);
% else
%     fprintf('[SPOT %d] bbTrue is DIFFERENT\n', 1);
% end
% 
% 
% disp('.')
% 
% 
% %%

end