function fTemplate = pg_make_fft_template(params, iSize)
template = single(pg_make_template(params, iSize));

fTemplate = zeros( size(template) );

for i=1:size(template,3)
    fTemplate(:,:,i) = fft2(template(:,:,i));
end

