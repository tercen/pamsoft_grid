function [params, exitCode] = pg_grd_preprocess_images(params, rescale, checkImageUsed)
exitCode = 0;


params.prpNSmallDisk = round( params.prpSmallDisk * params.grdSpotPitch );
params.prpNLargeDisk = round( params.prpLargeDisk * params.grdSpotPitch );
params.grdSpotSize   = params.grdSpotSize * params.grdSpotPitch;

I       = params.images;
expTime = params.expTime;
cycles  = params.cycles;
sInfo   = params.imageInfo;

if isempty(params.grdCol)
    exitCode = -11;
    pg_error_message(exitCode, 'grdCol');
    return
end

if isempty(params.grdIsReference)
    exitCode = -11;
    pg_error_message(exitCode, 'grdIsReference');
    return
end
if isempty(params.grdXOffset)
    params.grdXOffset = zeros(size(params.grdRow));
end
if isempty(params.grdYOffset)
    params.grdYOffset = zeros(size(params.grdCol));
end
if isempty(params.grdXFixedPosition)
    params.grdXFixedPosition = zeros(size(params.grdCol));
end
if isempty(params.grdYFixedPosition)
    params.grdYFixedPosition = zeros(size(params.grdCol));
end



if ~isempty(params.grdSearchDiameter)
    % we need an the size of an example image here
    bw    = false(sInfo.Height, sInfo.Width);
    mp    = size(bw)/2;
    r     = params.grdSpotPitch * params.grdSearchDiameter/2;
    [r,c] = pg_circle(mp, r, round(2*pi*r));
    params.grdRoiSearch = roipoly(bw, c,r);    
else
    params.grdRoiSearch = [];
end



if checkImageUsed 
    
    if ~isfield(params, 'grdImageNameUsed')
        exitCode = -11;
        pg_error_message(exitCode, 'grdImageNameUsed');
        return
    end
    
    gridImages = params.grdImageNameUsed;
end



% produce the segmentation image and the grid image
uCycle = unique(cycles);

sl     = params.qntSaturationLimit; %get(pgr.oSpotQuantification, 'saturationLimit');
bLast  = cycles == uCycle(end);
bFirst = cycles == uCycle(1);


% For the case where an image with specific Exposure time and cycle will be
% used 
if ~isempty( strfind(params.grdUseImage, '_') )
    imageUse = 'Specific';
else
    imageUse = params.grdUseImage;
end

if checkImageUsed
     [Igrid, ets, ] = pg_io_read_grid_images(params, gridImages{1});
     
     if size(Igrid,3) > 1
         Igrid = pg_combine_exposures(Igrid, ets, sl);
     end
     
     Iseg = Igrid;
else

    
    switch imageUse
        case 'Last'
            Igrid = I(:,:,bLast);
            if sum(bLast) > 1
                Igrid = pg_combine_exposures(Igrid, expTime(bLast),sl);
            end
            Iseg = Igrid;
            params.grdImageUsed      = bLast;
            params.grdImageNameUsed  = internal_create_image_used_string(params, bLast);
        case 'FirstLast'
            Igrid = I(:,:,bFirst);
            if sum(bFirst) > 1
                Igrid = pg_combine_exposures(Igrid, exp(bFirst),sl);
            end
            Iseg = I(:,:,bLast);
            if sum(bLast) > 1
                Iseg = pg_combine_exposures(Iseg, exp(bLast), sl);
            end
            params.grdImageUsed      = bLast | bFirst;
            params.grdImageNameUsed  = internal_create_image_used_string(params, bLast | bFirst);
        case 'First'
            Igrid = I(:,:,bFirst);
            % Changed here from sum(bLast), which seemed inappropriate
            if sum(bFirst) > 1
                Igrid = pg_combine_exposures(Igrid, exp(bFirst),sl);
            end
            Iseg = Igrid;
            params.grdImageUsed      = bFirst;
            params.grdImageNameUsed  = internal_create_image_used_string(params, bFirst);
        case 'Specific'
            ec = strsplit(params.grdUseImage, '_'  );
            e  = str2double(ec{1});
            c  = str2double(ec{2});

            bEC = expTime == e & cycles == c;

            if ~any(bEC)
                exitCode = -12;
                pg_error_message(exitCode, e, c);
                return
            end

            Igrid = I(:,:,bEC);
            if sum(bEC) > 1
                Igrid = pg_combine_exposures(Igrid, expTime(bEC), sl);
            end
            Iseg = Igrid;

            params.grdImageUsed     = bEC;
            params.grdImageNameUsed = internal_create_image_used_string(params, bEC);
        otherwise
            exitCode = -13;
            pg_error_message(exitCode, 'grdImageUse', params.grdUseImage);
            return
    end

end

params.image_grid = Igrid;
params.image_seg  = Iseg;
params.images     = I;

if checkImageUsed && exitCode == 0
%     quantImages = strsplit(params.grdImageNameUsed, ',' );
%     gridImages  = strsplit(gridImages{1}, ',' );
%     
%     imageFound  = zeros(length(quantImages), 1);
%     
%     for i = 1:length(quantImages)        
%         for j = 1:length(gridImages)
%             if strcmp(quantImages{i}, gridImages{j} )
%                 imageFound(i) = 1;
%                 break;
%             end
%         end
%     end
%     
%     if ~all(imageFound)
%         exitCode = -25;
%         pg_error_message(exitCode);
%     end
else
    params.grdImageNameUsed = cellstr(repmat( params.grdImageNameUsed, size(params.grdRow, 1), 1));
end


if rescale %|| any(params.isManual)
    rsf     = params.gridImageSize./size(Igrid);
    params  = pg_pp_rescale(params, rsf(1));

    Igrid   = pg_pp_fun(params, imresize(Igrid, params.gridImageSize));
     
    params.image_grid_preproc = Igrid;
    params.rsf = rsf;
     
    params = pg_rescale(params, rsf);
else
    disp('Rescale already run. Skipping');
end

   
%params.grdSpotPitch = inParams.grdSpotPitch;
%params.grdSpotSize   = inParams.grdSpotSize;


end


function imgString = internal_create_image_used_string(params, idx)
    sortedImages = params.imageslist;
    imgString    = '';
    
    
    if length(idx) == 1
        [~, f, ~] = fileparts( sortedImages{idx} );
        imgString = f;
    else
        
        idx = find(idx);
        
        comma = ',';
        for i = 1:length(idx)
            
            
            [~, f, ~] = fileparts( sortedImages{idx(i)} );
            
           
            
            if i == length(idx), comma = ''; end
            
            imgString = cat(2, imgString, f, comma);
        end
    end
end


