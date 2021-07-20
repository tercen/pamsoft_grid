
addpath(genpath('/pamsoft_grid/grid/'));
addpath(genpath('/pamsoft_grid/io/'));
addpath(genpath('/pamsoft_grid/util/'));
addpath(genpath('/pamsoft_grid/quantification'));

res = compiler.build.standaloneApplication('/pamsoft_grid/main/pamsoft_grid.m', ...
            'TreatInputsAsNumeric', false,...
            'OutputDir', '/pamsoft_grid/standalone');

