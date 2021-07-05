function oArray = refinePitch(oArray,xPos, yPos)
% oArray = refinePitch(oArray,xPos, yPos)
% Find and update the best fitting spot pitch of an array defined by the oArray object
% and actual coordinates xPos, yPos
% See also array/array, array/midPoint

% cater for differnt x and y pitch
% use the ratio of the pitch on input for the refinement

if length(oArray.spotPitch) == 1
    aYX = 1;
else
    aYX = oArray.spotPitch(2)/oArray.spotPitch(1);
end
isRef = oArray.isreference;

r =     oArray.row;
c =     oArray.col;

if (~all(r>0) & ~all(r<0)) | (~all(c>0) & ~all(c<0) )
    warning('cannot simultaneously refine pitch for pos and neg index arrays, keeping positive index only')
    bUse = r > 0 & c > 0; 
else
    bUse = true(size(r));
end

r = abs(r(isRef & bUse));
c = abs(c(isRef & bUse));

xPos = xPos(isRef & bUse);
yPos = yPos(isRef & bUse);

if any(isRef & bUse)
    dr = r(2:end)-r(1);
    dc = c(2:end)-c(1);
    dx = xPos(2:end)- xPos(1);
    dy = yPos(2:end)- yPos(1);
    pitch = sqrt( (dx.^2 + dy.^2)./(dr.^2 + (aYX*dc).^2) );

    if length(pitch) > 1
        bOut = detect(outlier, pitch(:));
        oArray.spotPitch = mean(pitch(~bOut));
    end
end
