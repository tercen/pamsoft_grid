function qOut = segmentImage(pgr, I, x, y, rot)
maxSubIter = 2; % Max iterations for subs vs refs refinement 
maxRefSubOffset = 0.15; % Max offset criterium between refs and subs.

if isequal(pgr.verbose, 'on')
    bVerbose = true;
else
    bVerbose = false;
end

if isequal(pgr.optimizeRefVsSub, 'yes')
    bOptimize = true;
else
    bOptimize = false;
end

spotPitch = get(pgr.oArray, 'spotPitch');
pgr.oSegmentation = set(pgr.oSegmentation, 'spotPitch', spotPitch);
isRef = get(pgr.oArray, 'isreference');

% preallocate array of spotQuantification objects.
qOut = repmat(pgr.oSpotQuantification, size(x,1), 1);

% first segmentation pass is for refs only
arrayRow = get(pgr.oArray, 'row');
arrayCol = get(pgr.oArray, 'col');
xOff = get(pgr.oArray, 'xOffset');
yOff = get(pgr.oArray, 'yOffset');
xfxd = get(pgr.oArray, 'xFixedPosition');
yfxd = get(pgr.oArray, 'yFixedPosition');
ID = get(pgr.oArray, 'ID');

oaRef = removePositions(pgr.oArray, '~isreference');
oaSub = removePositions(pgr.oArray, 'isreference');
pgrRef = set(pgr, 'oArray', oaRef);
pgrSub = set(pgr, 'oArray', oaSub);

isRef = logical(isRef);
if any(~isRef)
    % segment as separate reference array (different quality settings)
    [qRefs,~, mpRefs] = segmentAndRefine(pgrRef, I, x(isRef), y(isRef), rot, true);
else
    [qRefs,~, mpRefs] = segmentAndRefine(pgrRef, I, x(isRef), y(isRef), rot, false);
end

if all(get(qRefs, 'isBad'))
   % none of the references was properly found: gridding failure
   error('None of the reference spots was properly found')
end
qOut(isRef) = qRefs; % refs are segmented!

% if any, segment and quantify the substrates (non refs), allow for another
% pass if the offset between resf and sub is to large
bFixedSpot = xfxd > 0; % not refined spots
if any(~isRef)
    arrayRefined = array(...
        'row', arrayRow(~isRef), ...
        'col', arrayCol(~isRef), ...
        'isreference', ~isRef(~isRef), ... % set the ref prop to on to enable mp etc calculation
        'xOffset', xOff(~isRef), ...
        'yOffset', yOff(~isRef), ...
        'xFixedPosition', xfxd(~isRef), ...
        'yFixedPosition', yfxd(~isRef), ...
        'spotPitch', spotPitch, ...
        'rotation', rot);
    % These are the initial coordinates, based on the ref spot refined
    % midpoint
    [xSub, ySub] = coordinates(arrayRefined, mpRefs);
    for pass = 1:maxSubIter

        [qSub, spotPitch, mpSub] = segmentAndRefine(pgrSub, I, xSub,ySub, rot); 
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
        [xr,yr] = coordinates(arrayRefined, mpSub); % get expected coordinates from first pass midpoint
        xSub(~bFixedSpot(~isRef)) = xr(~bFixedSpot(~isRef)); % adapt the ~bFixedSpot coordinates 
        ySub(~bFixedSpot(~isRef)) = yr(~bFixedSpot(~isRef)); 
        mpRefs = mpSub;          
    end
    qOut(~isRef) = qSub;
end
qOut = setSet(qOut, 'ID', ID, ...
                    'arrayRow', arrayRow, ...
                    'arrayCol', arrayCol);

% final QC