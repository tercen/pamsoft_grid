% mcc -m pamsoft_grid.m -d /media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/standalone -o pamsoft_grid -R -nodisplay
function compile_docker()
fprintf('Reading source files\n');

% addpath(genpath('/mcr/grid/'));
% addpath(genpath('/mcr/io/'));
% addpath(genpath('/mcr/util/'));
% addpath(genpath('/mcr/quantification/'));

additionalFiles = get_files_in_dir('/mcr/grid');
additionalFiles = [additionalFiles get_files_in_dir('/mcr/io')];
additionalFiles = [additionalFiles get_files_in_dir('/mcr/util')];
additionalFiles = [additionalFiles get_files_in_dir('/mcr/quantification')];
for i = 1:length(additionalFiles)
   fprintf('%d - %s\n', i, additionalFiles{i}); 
end




if exist('/mcr/main/pamsoft_grid.m', 'file')
    fprintf('Compiling pamsoft_grid.m\n');
    res = compiler.build.standaloneApplication('/mcr/main/pamsoft_grid.m', ...
                'TreatInputsAsNumeric', false,...
                'AdditionalFiles', additionalFiles, ...
                'OutputDir', '/mcr/standalone');

    if ~exist('/mcr/standalone/pamsoft_grid', 'file')
       fprintf('[ERROR] /mcr/standalone/pamsoft_grid was not generated\n');
    end

    fprintf('Removing unnecessary files\n');
    delete('/mcr/standalone/mccExcludedFiles.log');
    delete('/mcr/standalone/readme.txt');
    delete('/mcr/standalone/requiredMCRProducts.txt');
else
    fprintf('Could not find /mcr/main/pamsoft_grid.m.\nABORTING\n');
end

end


function additionalFiles = get_files_in_dir(basePath)

additionalFiles = {};

paths = dir(basePath);

for i = 1:length(paths)
     if strcmpi( paths(i).name, '.' ) || strcmpi( paths(i).name, '..' )
         continue;
     end
     
     if paths(i).isdir == true

         path = cat(2, paths(i).folder, filesep, paths(i).name );

         additionalFiles = [additionalFiles get_files_in_dir(path)];
         
     else
        additionalFiles{end+1} =  cat(2, paths(i).folder, filesep, paths(i).name );
     end
    
end

end

