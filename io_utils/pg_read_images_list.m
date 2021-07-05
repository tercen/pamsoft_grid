function [params, exitCode] = pg_read_images_list(params)
    if ~isfield( params, 'imageslistfile' )
        exitCode = -11;
        return
    end
      
    imagesList = readlines(params.imageslistfile, 'WhitespaceRule', 'trim', ...
                    'EmptyLineRule', 'skip');

    params.imageslist = cellstr(imagesList);
    exitCode = 1;
    % Sorting is done in pg_preprocess_images
%     [imageList, exitCode]    = pg_sort_image_array(imagesList);
%     params.sorted_imageslist = cellstr(imageList);
    
end