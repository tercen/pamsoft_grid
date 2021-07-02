function oArray = rescale(oArray, rsf)
% function oArray = rescale(oArray, rsf)
% rescale the array object by multiplication by rsf
% where rsf is can be a scalar or a two element vector with x and y rescale
% factors.
if length(rsf) ==1
    rsf = [rsf, rsf];
end

if length(oArray.spotPitch) ==1
    oArray.spotPitch = [oArray.spotPitch, oArray.spotPitch];
end

oArray.spotPitch = rsf .* oArray.spotPitch;
oArray.spotSize = oArray.spotSize * mean(rsf);
oArray.xFixedPosition = oArray.xFixedPosition * rsf(1);
oArray.yFixedPosition = oArray.yFixedPosition * rsf(2);

if ~isempty(oArray.roiSearch)
    oArray.roiSearch = imresize(oArray.roiSearch, rsf .* size(oArray.roiSearch));
end




