function msgout(fid, msgline)
    if fid == 0
        return;
    elseif fid == 1
        disp(msgline)
    else
        fprintf(fid, '%s\n', msgline);
    end
    