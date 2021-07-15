function [params, exitCode] = pg_seg_segment(params, I, cx, cy, bFxd, rotation)
% function sOut = segment(s, I, cx, cy, bFxd, rotation)
% s = segment(s, I, cx, cy, rotation)
exitCode = 0;
if ~isequal(size(cx),size(cy))
    exitCode = -15;
    pg_error_message(exitCode, 'x coordinates', 'y coordinates');
    return
    
end


if min(size(cx)) < 2
    exitCode = -24;
    pg_error_message(exitCode);
    return;
end


% From analyzeImages.m when creating the preprocess object
% 'nFilterDisk'       , prpSmallDisk * grdSpotPitch
params.segNFilterDisk = params.prpSmallDisk * params.grdSpotPitch;


if isempty(params.grdSpotPitch)
    exitCode = -11;
    pg_error_message(exitCode, 'grdSpotPitch');
    return
end

if nargin < 6
    rotation = [];
end
if nargin < 5 || isempty(bFxd)
    bFxd = false(size(cx));
end
    


switch params.segMethod

    case 'Threshold'
        % Segment by threshold is currently not supported.
        exitCode = -13;
        pg_error_message(exitCode, 'params.segMethod', params.segMethod);
        return
    case 'Edge'
        spot         = pg_seg_create_spot_structure(params);
        params.spots = repmat(spot, length(cx(:)), 1);

        if any(~bFxd)
            params.spots(~bFxd) = pg_seg_segment_by_edge(params, I, cx(~bFxd), cy(~bFxd), rotation);
        end
        if any(bFxd)
            params.spots(bFxd)  = pg_seg_segment_by_edge_fxd_mp(params, I, cx(bFxd), cy(bFxd), rotation); 
        end
end

end