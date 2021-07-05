function pg_preprocess_images(params, varargin)
% 02.07.2021, Thiago Monteiro
%
% Preprocess images and place the grid based on all or a specific image



% Second argument is used to process a single image from the list
if isempty(varargin)
    bUseAllImages = 1;
    imFiles      = params.imageslist;
else
    bUseAllImages = 0;
    imFiles      = params.imageslist(varargin{1});
end


params.prpNSmallDisk = round( params.prpSmallDisk * params.grdSpotPitch );
params.prpNLargeDisk = round( params.prpLargeDisk * params.grdSpotPitch );

% Get information from an example image
sInfo    = imfinfo(imFiles{1});

% Get imge type
imType   = class(imread(imFiles{1}));
IMG_SIZE = [sInfo.Height, sInfo.Width];
nImgs    = length(imFiles);
I 	     = zeros( IMG_SIZE(1), IMG_SIZE(2), nImgs, imType );

% load the images
expTime = zeros(1,nImgs);
cycles  = zeros(1,nImgs);

for i = 1:nImgs
    try
        I(:,:,i) = imread(imFiles{i});
        
        % get the image parameters from file, and sort the images to
        % exposure time  and cycle (down below)
        imgInfo    = pg_get_image_info(imFiles{i}, {'ExposureTime', 'Cycle'});
        expTime(i) = imgInfo{1};
        cycles(i)  = imgInfo{2};
        
    catch
        le =  lasterror;
        error(['Error while reading ', imFiles{i}, ': ',le.message ]);
    end
end



if nImgs > 0 && size(unique([expTime', cycles'],'rows'),1) ~= length(expTime)
    error('Invalid combination of input images to PamGrid: there are multiple images with both equal cycle and exposure time')
end
 
 
bImageInfoFound = ~isempty(expTime)&& ~isempty(cycles);
 
% sort the images to exposure time  and cycle
if bImageInfoFound
    [ec, iSort] = sortrows( [expTime', cycles'], [2,1]);
    expTime     = ec(:,1);
    cycles      = ec(:,2);
    I           = I(:,:, iSort);

elseif bUseAllImages == 1
    error('Could not find embedded image information for use with ''useImage'' option ''All''');
end


% [~, iSort] = sortrows([op.cycle, op.exposure]);
% exp = op.exposure(iSort);
% cycle = op.cycle(iSort);
% I = I(:, :, iSort);


               
%construct an array object
% UPDATE: Add this to the overall params structure
if isempty(params.grdCol)
    error('PamSoft_Grid property ''grdCol'' has not been set');
end

if isempty(params.grdIsReference)
    error('PamSoft_Grid property ''grdIsReference'' has not been set');
end
if isempty(params.grdXOffset);
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




params.grdSpotSize = params.grdSpotSize * params.grdSpotPitch;

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
% TODO: Receive this from the JSON file
sl     = str2num( params.qntSaturationLimit ); %get(pgr.oSpotQuantification, 'saturationLimit');
bLast  = cycles == uCycle(end);
bFirst = cycles == uCycle(1);

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
    case 'FirstLast'
        Igrid = I(:,:,bFirst);
        if sum(bFirst) > 1
            Igrid = pg_combine_exposures(Igrid, exp(bFirst),sl);
        end
        Iseg = I(:,:,bLast);
        if sum(bLast) > 1
            Iseg = pg_combine_exposures(Iseg, exp(bLast), sl);
        end
    case 'First'
%         bFirst
        Igrid = I(:,:,bFirst);
        % FIX changed here from sum(bLast), which seems inappropriate
        if sum(bFirst) > 1
            Igrid = pg_combine_exposures(Igrid, exp(bFirst),sl);
        end
        Iseg = Igrid;
    case 'Specific'
        ec = strsplit(params.grdUseImage, '_'  );
        e  = str2double(ec{1});
        c  = str2double(ec{2});
        
        bEC = expTime == e & cycles == c;
        
        if ~any(bEC)
            error('Specified Exposure_Cycle (%d_%d) is not present in the list of images.', e,c);
        end
        
        Igrid = I(:,:,bEC);
        if sum(bEC) > 1
            Igrid = pg_combine_exposures(Igrid, expTime(bEC), sl);
        end
        Iseg = Igrid;
    otherwise
        error('Invalid value for pamgrid parameter ''useImage''')
end


[x,y,rot,params] = pg_global_grid(params, Igrid);


%TODO Save x, y and what else is necessary
% Using a pg_save_params with a selection of fields might be more
% productive at the moment


% fprintf('%.1f x %.1f\n', x, y);

% END of preprocessing and gridding function

% ---------------------------






% [val, map]     = getpropenumeration('prpContrast');
% 
% strPrpContrast = char(map(params.prpContrast == val));

% Ensuring that this comes from the JSON file (which is stored in the
% params structure)
% oPrep = preProcess('nSmallDisk' , params.prpSmallDisk * params.grdSpotPitch, ...
%                    'nLargeDisk' , params.prpLargeDisk * params.grdSpotPitch, ...
%                    'contrast'   , strPrpContrast);
% 
%                
% if ~isempty(params.grdSearchDiameter)
%     % we need an the size of an example image here
%     sInfo    = imfinfo(params.imageslist{1});
%     bw       = false(sInfo.Height, sInfo.Width);
%     mp       = size(bw)/2;
%     r        = params.grdSpotPitch * params.grdSearchDiameter/2;
%     [r,c]    = pg_circle(mp, r, round(2*pi*r));
%     srchRoi  = roipoly(bw, c,r);    
% else
%     srchRoi = [];
% end
% 
% 
% oArray = array  ('row'              , params.grdRow, ...
%                  'col'              , params.grdCol, ...
%                  'isreference'      , params.grdIsReference, ...
%                  'spotPitch'        , params.grdSpotPitch, ...
%                  'spotSize'         , params.grdSpotSize * params.grdSpotPitch, ...
%                  'rotation'         , params.grdRotation, ...
%                  'xOffset'          , params.grdXOffset, ...
%                  'yOffset'          , params.grdYOffset, ...
%                  'xFixedPosition'   , params.grdXFixedPosition, ...
%                  'yFixedPosition'   , params.grdYFixedPosition, ...
%                  'roiSearch'        , srchRoi, ... 
%                  'ID'               , params.qntSpotID); 
%              
%              
% % finaly construct a pamgrid object 
% 
% [val, map]= getpropenumeration('grdOptimizeSpotPitch');
% strOpPitch = char(map(params.grdOptimizeSpotPitch == val));
% 
% [val, map]= getpropenumeration('grdOptimizeRefVsSub');
% strOpRefVsSub = char(map(params.grdOptimizeRefVsSub == val));
% 
% [val, map]= getpropenumeration('qntSeriesMode');
% strSeriesMode = char(map(params.qntSeriesMode == val));
% 
% [val, map]= getpropenumeration('grdUseImage');
% strUseImage = char(map(params.grdUseImage == val));
% 
% 
% pgr = pamgrid(  'oPreProcessing',   oPrep, ...
%                 'oArray',   oArray, ...
%                 'oSegmentation', oS0, ...
%                 'oSpotQuantification', oQ0, ...
%                 'oSpotQualityAssessment', aSubSqc, ...
%                 'oRefQualityAssessment', aRefSqc, ...
%                 'gridImageSize', params.prpResize, ...
%                 'optimizeSpotPitch', strOpPitch, ...
%                 'optimizeRefVsSub', strOpRefVsSub, ...
%                 'seriesMode', strSeriesMode, ...
%                 'useImage', strUseImage);
               
end