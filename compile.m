% mcc -m pamsoft_grid.m -d /media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/standalone -o pamsoft_grid -R -nodisplay
addpath(genpath('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/grid/'));
addpath(genpath('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/io/'));
addpath(genpath('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/util/'));
addpath(genpath('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/quantification'));

res = compiler.build.standaloneApplication('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/main/pamsoft_grid.m', ...
            'TreatInputsAsNumeric', false,...
            'OutputDir', '/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/standalone');

        
delete('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/standalone/mccExcludedFiles.log');
delete('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/standalone/readme.txt');
delete('/media/thiago/EXTRALINUX/Tercen/matlab/pamsoft_grid/standalone/requiredMCRProducts.txt');


