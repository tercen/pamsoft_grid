function sOut = segment(s, I, cx, cy, bFxd, rotation)
% s = segment(s, I, cx, cy, rotation)
if ~isequal(size(cx),size(cy))
    error('The number of x coordinates must be equal to the number of y coordinates');
end
% if min(size(cx)) < 2
%     error('The grid must include at least 2 rows and two columns, use dummy spots if necessary.');
% end

if isempty(s.spotPitch)
    error('Parameter ''spotPitch'' has not been defined');
end

if nargin < 6
    rotation = [];
end
if nargin < 5 || isempty(bFxd)
    bFxd = false(size(cx));
end
    


switch s.method

    case 'Threshold'
        error('segment by threshold is currently not supported')
        %sOut = segmentByThreshold(s, I, cx, cy, rotation);
    case 'Edge'
        sOut = repmat(s, length(cx(:)),1);
        if any(~bFxd)
            sOut(~bFxd) = segmentByEdge(s, I, cx(~bFxd), cy(~bFxd), rotation);
        end
        if any(bFxd)
            sOut(bFxd)  = segmentByEdgeFxdMp(s, I, cx(bFxd), cy(bFxd), rotation); 
        end
end