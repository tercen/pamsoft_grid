function preProcessExe(p, src, dst)

if ischar(src) | (iscell(src) & length(src) == 1)
    preProcessSingle(p, src, dst);
end
