function [C, exitCode] = pg_io_get_image_info(imgPath, info)
    exitCode = 0;

    try
        sInfo = pg_imtifinfo(imgPath);
    catch tifInfoException
        [~,name,ext] = fileparts(imgPath);
%         errstr = ['Error reading info from: ', name,ext,': ',tifInfoException.message];
%                 error(errstr);
        exitCode = -41;
        pg_error_message('preprocess.image_read', exitCode, name, tifInfoException.message);
        
    end


    C = cell(length(info), 1);
    for i = 1:length(info)
        if isfield(sInfo, info{i})
            C{i} = sInfo.(info{i});
        else
           C{i} = [];
        end
    end


end

