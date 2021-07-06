function [params, exitCode] = pg_io_read_images_list(params)
exitCode = 0;

    if ~isfield( params, 'imageslistfile' )
        exitCode = -21;
        pg_error_message('general.imagelist.exist',exitCode);
        return
    end

    try
        imagesList = readlines(params.imageslistfile, 'WhitespaceRule', 'trim', ...
            'EmptyLineRule', 'skip');
        params.imageslist = cellstr(imagesList);
    catch
        pg_error_message('general.imagelist.read', exitCode,  params.imageslistfile );
        exitCode = -22;
    end

    imFiles       = params.imageslist;


    % Get information from an example image
    sInfo    = imfinfo(imFiles{1});

    % Get image type
    imType   = class(imread(imFiles{1}));
    IMG_SIZE = [sInfo.Height, sInfo.Width];
    nImgs    = length(imFiles);
    I 	     = zeros( IMG_SIZE(1), IMG_SIZE(2), nImgs, imType );

    % @TODO The imge reading and sorting code will likely be used before the
    % segmentation and quantification steps and thus are expected to be moved
    % out of the preprocess function

    % load the images, read cycle and exposure time information
    expTime = zeros(1,nImgs);
    cycles  = zeros(1,nImgs);

    for i = 1:nImgs
        try
            I(:,:,i)   = imread(imFiles{i});
        catch
            exitCode = -1001;
            pg_error_message('grid.preprocess.read_image', exitCode, imFiles{i});
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

        %     catch
        %         le =  lasterror;
        %         error(['Error while reading ', imFiles{i}, ': ',le.message ]);
        %     end
    end



    if nImgs > 0 && size(unique([expTime', cycles'],'rows'),1) ~= length(expTime)
        %     error('Invalid combination of input images to PamGrid: there are multiple images with both equal cycle and exposure time')
        exitCode = -1002;
        pg_error_message('grid.preprocess.exp_time_combo', exitCode, imFiles{i});
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

    
    params.images = I;
    params.expTime = expTime;
    params.cycles = cycles;
    params.grdSortOrder = iSort;
    params.imageInfo = sInfo;
end