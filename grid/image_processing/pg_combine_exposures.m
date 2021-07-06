function I = pg_combine_exposures(I, T, satLimit)
classOfImage = class(I);
I = double(I);
szI = size(I);
% convert to 2D array for convenience
I = reshape(I,szI(1)*szI(2), szI(3)); 
% mask saturated pixels
I(I >= satLimit) = nan;
% find and correct for the camera offset based on the 'image average'
J = nanmean(I)';
bNan = isnan(J);% exclude any fully saturated images.
if all(bNan)
    
    error('All images in the series are fully saturated')
end
beta = [ones(size(T(~bNan))), T(~bNan)]\J(~bNan);
I = I-beta(1);
% scale the images using exposure time
% note that this neglects any CCD offset.
I = I./repmat(T', size(I,1), 1);
% get the max non saturated value, set remaining NaN's to 1
I = nanmax(I, [], 2);
I = I/nanmax(I(:));
I(isnan(I)) = 1;
% convert back to image format
I = reshape(I, szI(1), szI(2));
switch classOfImage
    case 'uint8'
        I = uint8(I * (-1 + 2^8));
    case 'uint16'
        I = uint16(I * (-1 + 2^16));
end


       
