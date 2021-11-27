% function [q, spotPitch, mp] = pg_qnt_segment_and_refine(pgr, I, x, y, rot, asRef)
function [params, spotPitch, mp, exitCode] = pg_seg_segment_and_refine(params, x, y, asRef)
% Segments and attempts to refine the spotpitch
if nargin == 3
    asRef = false;
end
exitCode = 0;
q         = [];
mp        = [];
if isequal(params.grdOptimizeSpotPitch', 'yes')
    % this determines if (a) spotPitch refinement iteration(s) will be
    % performed
    maxIter = 2;
else
    maxIter = 1;
end

if isequal(params.verbose, 'yes')
    bVerb = true;
else
    bVerb = false;
end


maxDelta  = 0.3;
spotPitch = params.grdSpotPitch;


mp         = pg_mid_point(params, x,y);

fxdx       = params.grdXFixedPosition;
fxdy       = params.grdYFixedPosition;
bFixedSpot = fxdx ~= 0;

% For the fixed spots, replace the input x and y by xFixedPosition and yFixedPosition
x(bFixedSpot) = fxdx(bFixedSpot);
y(bFixedSpot) = fxdy(bFixedSpot);

% start the refinement loop, terminate when the refinedSpotPitch is close
% enough to the input spotPitch  (or when maxIter is reached);
iter  = 0;
delta = maxDelta + 1;
xr = -100;
while delta > maxDelta
    iter = iter + 1;
    if iter > maxIter
        break;
    end
    
    I = params.image_seg;
%     imagesc(I); hold on; scatter(x,y,'k');
    [params, exitCode] = pg_seg_segment(params, I, x, y, bFixedSpot, params.grdRotation);
    
%                 imagesc(params.image_grid); hold on;
% fp = [params.spots.finalMidpoint];
% plot(fp(1:2:end), fp(2:2:end), 'oy');

            
    
    if exitCode < 0
        return
    end
    
    
    if asRef
        flags = pg_seg_check_segmentation( params, params.sqcMaxPositionOffsetRefs );
    else
        flags = pg_seg_check_segmentation( params, params.sqcMaxPositionOffset );
    end
    
    % replace empty spots by the default spot
    params.spots(flags == 2) = pg_seg_set_as_dft_spot(params.spots(flags == 2));
    if all(bFixedSpot)
        params.segOutliers = zeros(length(params.spots), 1);
        break;
    end
    % if too little spots are correctly found, skip spot pitch refinement
    % here:
    bUse = flags == 0 & ~bFixedSpot;
    if sum(bUse) < 5
        fprintf('[WARNING] Too few spots found (%d/%d), skipping spot pitch refinement.\n', ...
            sum(bUse), length(bUse));
        params.segOutliers = zeros(length(bUse), 1);
        break;
    end
    %%
    % Use the spots found to refine the pitch and array midpoint
    % exclude fixed points from the refinement
%     clc;
    [xPos, yPos] = pg_seg_get_position(params.spots);
    
    params2fit                = params;
    params2fit.grdIsReference = bUse;
    
    arrayRefined = pg_seg_refine_pitch(params2fit, xPos, yPos);
    arrayRefined.grdIsReference = true(size(x));
    refSpotPitch = arrayRefined.grdSpotPitch;
    

    
    delta        = abs(refSpotPitch - spotPitch);
    
    
    mp = pg_mid_point(arrayRefined, xPos, yPos);
    
    
    % Within pg_seg_refine_pitch, outliers are calculated relative to the
    % first position
    params.segOutliers = zeros(length(bUse), 1);
    % FIXME THIS is being ignored later on
    %params.segOutliers(bUse(2:end)) = arrayRefined.segOutliers;
%     %%
    % calculate array coordinates based on refined pitch
%     mp = mp(2:-1:1);
%
% clf;
%  imagesc(I); hold on; 
%  fp = [params.spots.finalMidpoint];
% plot(fp(1:2:end), fp(2:2:end), 'oy');

    [xr,yr, exitCode] = pg_grd_coordinates(arrayRefined,mp, -pi/2+params.grdRotation);
%     plot(xr,yr, 'ok');
% plot(mp(2),mp(1),'.k', 'MarkerSize', 15);
        %%
%     imagesc(params.image_grid); hold on; scatter(xPos, yPos, 'k'); 
    
%     scatter(xr, yr, 'y')
    
    %%
    
%     scatter(xPos, yPos); hold on; scatter(xr, yr);
%     %%
    if bVerb
        disp('Spot pitch optimization')
        disp(['iter ',num2str(iter)]);
        disp(['delta: ', num2str(delta)]);
        disp(['sp in: ', num2str(spotPitch)]);
        disp(['sp out: ', num2str(refSpotPitch)]);
        if delta <= maxDelta
            disp('Spot pitch optimization finished')
        end
    end
    spotPitch      = refSpotPitch;


    
    x(~bFixedSpot) = xr(~bFixedSpot);
    y(~bFixedSpot) = yr(~bFixedSpot);
end

% replace bad spots by the default spot
params.spots(flags == 1) = pg_seg_set_as_dft_spot(params.spots(flags == 1));

% if xr ~= -100
%     for i = 1:length(params.spots)
%         params.spots(i).finalMidpoint = [yr(i) xr(i)];
%     end
% end

% create the array of spotQuantification objects for output.
params.seg_res.isEmpty    = flags == 2;
params.seg_res.isBad      = flags == 1;
params.seg_res.isReplaced = flags > 0;


