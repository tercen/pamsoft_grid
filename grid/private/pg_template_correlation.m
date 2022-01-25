function [mxcor, iRot, rot]  = pg_template_correlation(Image, fftRotTemplate, roiSearch)
% function [mxcor, rotation] = templateCorrelation(Image, Templatet);

% Image=single(Image');
fftImage        = fft2(double(Image));
roiSq = 1-roiSearch;
roiSearch = roiSearch(:);

mxcor = zeros( size(fftRotTemplate,3), 2 );


for i=1:size(fftRotTemplate,3)
    fftTemplate = single(squeeze(fftRotTemplate(:,:,i)));
    C = real(ifft2(fftImage.*conj((fftTemplate))));   

    C = fftshift(C);
    C(~roiSearch) = NaN;
    [mx, idx] = nanmax(C(:));
   
   
    c(i) = mx(1);
    [x,y] = ind2sub(size(C), idx(1));
    % ====================
    % NOTE
    % ====================
    % If the parameter grdRotation is equal to 0,
    % GRid rotation is performed in two steps.
    % First, an intensity based registration is performed to find optimal
    % translation and rotation parameters.
    % Then, the closest rotation in the -2:0.25:2 rotation search vector is
    % chosen as the final rotation.
    %
    % This procedure was implemented during the validation against the
    % results from version 1.10 of pamsoft_grid from BioNavigator, though
    % it is not running like this there.
    %
    % Thiago Monteiro, 12.2021
    if size(fftRotTemplate,3) == 1
        templ = double(ifft2(fftTemplate));
        im = double(Image);
        im=im.*roiSq;
        % For size 256,256 only
        im(1:30,:) = 0;
        im(226:end,:) = 0;
        im(:,1:30) = 0;
        im(:,226:end)=0;


        templ(templ<0.2) = 0;

        windowWidth = 3; 
        kernel = ones(windowWidth) / windowWidth ^ 2;
        templ = imfilter(templ, kernel); % Blur the image.



        [optimizer, metric] = imregconfig('multimodal');
        optimizer.MaximumIterations = 300;
        [~, ~, tform ]= imregister2(im, templ,  'rigid', optimizer, metric);

        tformInv = invert(tform);
        Tinv = tformInv.T;
        ss = Tinv(2,1);
        sc = Tinv(1,1);

        rot = atan2(ss,sc)*180/pi;
        trans = tform.T(1:2,3);
         mxcor(i,:) = [x+trans(1),y+trans(2)]; 

    else
         mxcor(i,:) = [x,y]; 


    end


end

if size(fftRotTemplate,3) ~= 1
    [~, iRot] = max(c);
    mxcor     = mxcor(iRot,:);
    rot = NaN;

else
%     rotations = -4:0.001:4;
% 
%     discRot = abs(rot - rotations);
%     [~,k] = min(discRot);
    iRot = 0;
%     rot=rotations(k);

end