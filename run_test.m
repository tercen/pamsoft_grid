PGDIR  = which('pamsoft_grid');
sepIdx = strfind(PGDIR, filesep);
PGDIR = PGDIR(1:sepIdx(end));
pamsoft_grid(sprintf('--param-file=%s/test/input_params_local.json', PGDIR))