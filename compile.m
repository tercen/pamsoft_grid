% mcc -m pamsoft_grid.m -d /media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/standalone -o pamsoft_grid -R -nodisplay
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/grid/'));
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/io/'));
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/util/'));
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/quantification'));

res = compiler.build.standaloneApplication('pamsoft_grid.m', ...
            'TreatInputsAsNumeric', false,...
            'OutputDir', '/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/standalone');
% copyfile('util/error_messages.json', 'standalone/error_messages.json');
% copyfile('util/properties/default.json', 'standalone/default.json');
% copyfile('test_params/input_params.json', 'standalone/input_params.json');
% copyfile('test/input_params_local.json', 'standalone/input_params_local.json');


% % Creating Docker image
% opts = compiler.package.DockerOptions(res,'ImageName','pamsoft_grid');
% compiler.package.docker(res, 'Options', opts)


% docker run --rm \
%       -v $PWD/standalone:/mcr/exe \
%       -v $PWD/test:/test \
%       -w /mcr/exe \
%       tercen/mcr:R2020b \
%       /mcr/exe/pamsoft_grid \
%       --param-file=/test/input/input_params.json

% TODO ORganize the structure to work on this command
% synchronize everythin on Github