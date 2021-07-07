function [params, exitCode] = pg_io_read_images_list(params)
exitCode = 0;

    if ~isfield( params, 'imageslist' )
        exitCode = -3;
        pg_error_message(exitCode, params.paramfile);
        return
    end

    imFiles       = params.imageslist;

    if ~iscell(imFiles) || isempty(imFiles)
        exitCode = -4;
        pg_error_message(exitCode);
        return
    end


    % Get information from an example image
    try
        sInfo    = imfinfo(imFiles{1});
    catch err
        exitCode = -6;
        pg_error_message(exitCode, imFiles{1}, err.message);
        return;
    end

    % Get image type
    imType   = class(imread(imFiles{1}));
    IMG_SIZE = [sInfo.Height, sInfo.Width];
    nImgs    = length(imFiles);
    I 	     = zeros( IMG_SIZE(1), IMG_SIZE(2), nImgs, imType );

    % load the images, read cycle and exposure time information
    expTime = zeros(1,nImgs);
    cycles  = zeros(1,nImgs);

    for i = 1:nImgs
        try
            I(:,:,i)   = imread(imFiles{i});
        catch
            exitCode = -5;
            pg_error_message( exitCode, imFiles{i});
            return
        end


        % get the image parameters from file, and sort the images to
        % exposure time  and cycle (down below)
        [imgInfo, exitCode]    = pg_io_get_image_info(imFiles{i}, {'ExposureTime', 'Cycle'});

        if exitCode < 0
            return;
        end
        expTime(i) = imgInfo{1};
        cycles(i)  = imgInfo{2};

    end



    if nImgs > 0 && size(unique([expTime', cycles'],'rows'),1) ~= length(expTime)
        exitCode = -7;
        pg_error_message(exitCode);
        return
    end


    bImageInfoFound = ~isempty(expTime)&& ~isempty(cycles);

    % sort the images to exposure time  and cycle
    if bImageInfoFound
        [ec, iSort] = sortrows( [expTime', cycles'], [2,1]);
        expTime     = ec(:,1);
        cycles      = ec(:,2);
        I           = I(:,:, iSort);


        % This order is later used in the quantification process to unsort the
        % quant results and match the ordering of expTime, cycles, I, and q
        params.grdSortOrder = iSort;


    elseif bUseAllImages == 1
        % @TODO Find the use cases where bUseAllImages is set to 0 or not
        error('Could not find embedded image information for use with ''useImage'' option ''All''');
    end

    
    params.images       = I;
    params.expTime      = expTime;
    params.cycles       = cycles;
    params.grdSortOrder = iSort;
    params.imageInfo    = sInfo;
end