function [met, imet] = pg_seg_circle_intensity_ratio(I, cx, cy, r)
    
%     clc
    I = I./max(I(:));
    % Create a logical image of a circle with specified
    % diameter, center, and image size.
    % First create the image.
    imageSizeX = size(I,1);
    imageSizeY = size(I,2);
    
    [columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
    % Next create the circle in the image.
    centerX = cy;
    centerY = cx;
    radius  = r;
    circlePixels = (rowsInImage - centerY).^2 ...
        + (columnsInImage - centerX).^2 <= radius.^2;
    
    
%     mean( I(circlePixels(:)) ) 
%     mean( I(~circlePixels(:)) ) 
    met = median( I(circlePixels(:)) ) /  median( I(~circlePixels(:)) );
    
    imet = mean( I(~circlePixels(:)) );

end