function [I, expTime, cycles] = pg_io_read_grid_images(params, gridImages)


    imFiles       = cellstr(strsplit(gridImages, ','));
% 
%     [imPath,~,ext] = fileparts(imFiles{1});
%     if isempty(ext)
%         [imPath,~,ext] = fileparts(params.imageInfo.Filename);
%         for i = 1:length(imFiles)
%             imFiles{i} = cat(2, imPath, filesep, imFiles{i}, ext);
%         end
%     end

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
        exitCode = -22;
        pg_error_message(exitCode);
        return;

    end

    

end