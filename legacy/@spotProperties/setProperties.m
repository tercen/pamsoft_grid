function sp = setProperties(sp, binImage);
% function sp = setProperties(binImage);
if any(binImage(:))
    metrics           = regionprops(double(binImage),{'MajorAxisLength', 'MinorAxisLength', 'Perimeter', 'Area', 'Centroid'});
    sp.diameter       = metrics.MajorAxisLength;
    sp.aspectRatio    = metrics.MajorAxisLength/metrics.MinorAxisLength;
    sp.position       = metrics.Centroid;
    if metrics.Perimeter
        sp.formFactor     = (metrics.Area * 4*pi )/(metrics.Perimeter)^2;
    else
        sp.formFactor    = 0;
    end
end