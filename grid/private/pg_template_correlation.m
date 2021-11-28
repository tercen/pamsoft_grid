function [mxcor, iRot]  = pg_template_correlation(Image, fftRotTemplate, roiSearch)
% function [mxcor, rotation] = templateCorrelation(Image, Templatet);
fftImage        = fft2(single(Image));

roiSearch = roiSearch(:);

mxcor = zeros( size(fftRotTemplate,3), 2 );
for i=1:size(fftRotTemplate,3)
    fftTemplate = squeeze(fftRotTemplate(:,:,i));
    C = real(ifft2(fftImage.*conj(fftTemplate)));    
    C = fftshift(C);
    C(~roiSearch) = NaN;
  
    [mx, idx] = nanmax(C(:));
   
    c(i) = mx(1);
    [x,y] = ind2sub(size(C), idx(1));
    mxcor(i,:) = [x,y]; 
    
end
[~, iRot] = max(c);
mxcor     = mxcor(iRot,:);
