function params = pg_rescale(params, rsf)
% function oArray = rescale(oArray, rsf)
% rescale the array object by multiplication by rsf
% where rsf is can be a scalar or a two element vector with x and y rescale
% factors.
if length(rsf) ==1
    rsf = [rsf, rsf];
    params.rsf = rsf;
end

if length(params.grdSpotPitch) ==1
    params.grdSpotPitch = [params.grdSpotPitch, params.grdSpotPitch];
end

params.grdSpotPitch            = rsf .* params.grdSpotPitch ;
params.grdSpotSize             = params.grdSpotSize * mean(rsf);
params.grdXFixedPosition = params.grdXFixedPosition * rsf(1);
params.grdYFixedPosition = params.grdYFixedPosition * rsf(2);

if ~isempty(params.grdRoiSearch)
    params.grdRoiSearch = imresize(params.grdRoiSearch, rsf .* size(params.grdRoiSearch));
end






