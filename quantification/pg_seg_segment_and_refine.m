% function [q, spotPitch, mp] = pg_qnt_segment_and_refine(pgr, I, x, y, rot, asRef)
function [q, spotPitch, mp] = pg_qnt_segment_and_refine(params, asRef)
% Segments and attempts to refine the spotpitch
% if nargin == 5
%     asRef = false;
% end
q=[];
spotPitch=[];
mp = [];
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

% x and y come from gridding
x = params.grdXFixedPosition;
y = params.grdYFixedPosition;

maxDelta = 0.3;
spotPitch = params.grdSpotPitch; %get(pgr.oArray, 'spotPitch');

% From the test script
% 291.5000  372.0039
mp   = pg_mid_point(params, x,y);


fxdx       = x;
fxdy       = y;
bFixedSpot = fxdx ~= 0;
% For the fixed spots, replace the input x and y by xFixedPosition and yFixedPosition
x(bFixedSpot) = fxdx(bFixedSpot);
y(bFixedSpot) = fxdy(bFixedSpot);

% start the refinement loop, terminate when the refinedSpotPitch is close
% enough to the input spotPitch  (or when maxIter is reached);
iter = 0;
delta = maxDelta + 1;
while delta > maxDelta
    iter = iter + 1;
    if iter > maxIter
        break;
    end
    
    % @FIXME params.image_grid will not be available, but it will be a
    % parameter to select from the list
    % This will need to be changed once it is defined how results from the
    % gridding should be made available
    
    % @FIXME If FirstLast method is used, this will not work, though this
    % seems not be an use case
    ISeg = params.images(:,:, params.grdImageUsed );
    
    pg_seg_segment(params, Iseg, x, y, bFixedSpot, params.grdRot);
    
    pgr.oSegmentation = set(pgr.oSegmentation, 'spotPitch', spotPitch);
    oS = segment(pgr.oSegmentation, I, x, y,bFixedSpot,rot);
    if asRef
        flags = checkSegmentation(pgr.oRefQualityAssessment, oS);
    else
        flags = checkSegmentation(pgr.oSpotQualityAssessment, oS);
    end
    % replace empty spots by the default spot
    oS(flags == 2) = setAsDftSpot(oS(flags == 2));
    if all(bFixedSpot)
        break;
    end
    % if too little spots are correctly found, skip spot pitch refinement
    % here:
    bUse = flags == 0 & ~bFixedSpot;
    if sum(bUse) < 5
        break;
    end
    % Use the spots found to refine the pitch and array midpoint
    % exclude fixed points from the refinement
    [xPos, yPos] = getPosition(oS);
    array2fit = set(pgr.oArray, 'isreference',bUse);
    arrayRefined = refinePitch(array2fit, xPos, yPos);
    arrayRefined = set(arrayRefined, 'isreference', true(size(x)));
    refSpotPitch = get(arrayRefined, 'spotPitch');
    delta = abs(refSpotPitch - spotPitch);
    mp = midPoint(arrayRefined, xPos, yPos);

    % calculate array coordinates based on refined pitch
    [xr,yr] = coordinates(arrayRefined, mp, rot);

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
    spotPitch = refSpotPitch;
    x(~bFixedSpot) = xr(~bFixedSpot);
    y(~bFixedSpot) = yr(~bFixedSpot);
end
% replace bad spots by the default spot

oS(flags == 1) = setAsDftSpot(oS(flags == 1));

% create the array of spotQuantification objects for output.

q = setSet(pgr.oSpotQuantification, ...
                'oSegmentation', oS, ...
                'isEmpty', flags == 2, ...
                'isBad', flags == 1, ...
                'isReplaced', flags > 0);
            


            