function C = pg_get_image_info(imgPath, info)


    try
        sInfo = pg_imtifinfo(imgPath);
    catch tifInfoException
        [~,name,ext] = fileparts(imgPath);
        errstr = ['Error reading info from: ', name,ext,': ',tifInfoException.message];
        error(errstr);
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

