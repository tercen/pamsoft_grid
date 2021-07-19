function [params, exitCode] = pg_grd_preprocess_images(params, rescale)
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



% produce the segmentation image and the grid image
uCycle = unique(cycles);
% FROM oSpotQuantification 
% oq.saturationLimit = 2^16 -1 ;
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

switch imageUse
    case 'Last'
        Igrid = I(:,:,bLast);
        if sum(bLast) > 1
            Igrid = pg_combine_exposures(Igrid, expTime(bLast),sl);
        end
        Iseg = Igrid;
        params.grdImageUsed = bLast;
    case 'FirstLast'
        Igrid = I(:,:,bFirst);
        if sum(bFirst) > 1
            Igrid = pg_combine_exposures(Igrid, exp(bFirst),sl);
        end
        Iseg = I(:,:,bLast);
        if sum(bLast) > 1
            Iseg = pg_combine_exposures(Iseg, exp(bLast), sl);
        end
        params.grdImageUsed = bLast | bFirst;
    case 'First'
        Igrid = I(:,:,bFirst);
        % @FIXME changed here from sum(bLast), which seemed inappropriate
        if sum(bFirst) > 1
            Igrid = pg_combine_exposures(Igrid, exp(bFirst),sl);
        end
        Iseg = Igrid;
        params.grdImageUsed = bFirst;
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
        
        params.grdImageUsed = bEC;
    otherwise
        exitCode = -13;
        pg_error_message(exitCode, 'grdImageUse', params.grdUseImage);
        return
end


params.image_grid = Igrid;
params.image_seg  = Iseg;
params.images     = I;

if rescale
    rsf     = params.gridImageSize./size(Igrid);
    params  = pg_pp_rescale(params, rsf(1));

    Igrid   = pg_pp_fun(params, imresize(Igrid, params.gridImageSize));
     
    params.image_grid_preproc = Igrid;
    params.rsf = rsf;
     
    params = pg_rescale(params, rsf);
end

               
end