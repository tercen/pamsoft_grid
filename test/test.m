% DELETE THIS CODE AFTER RUNNING

clear all
global grdSpotPitch
global qntSeriesMode
global qntShowPamGridViewer
global grdSearchDiameter
global grdUseImage
global segEdgeSensitivity
global sqcMaxPositionOffset;
global segAreaSize;
global sqcMinSnr;
global sqcMinDiameter

global qntSpotID;
global grdCol;
global grdRow;
global grdIsReference;
global grdXOffset;
global grdYOffset;
global grdXFixedPosition;
global grdYFixedPosition;


sqcMinDiameter = 0.45;
segEdgeSensitivity = [0, 0.01];
qntSeriesMode = 0;
qntShowPamGridViewer = 1;
grdSpotPitch = 21.5;
grdUseImage = -3;
% dDir = 'D:\A_PG_Data\Rik\ImageSpotGrid2';
dDir = '/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/631158404_631158405_631158406-ImageResults/';
% 'pamsoft_grid/test/data/190007601_190007602_190007603-on read test ALEX-run 200305140725/ImageResults/';

%% load images from cycle 93 with varying exposure time
flist = dir([dDir, '/*.tif']);
clc;
display(flist)
for i=1:length(flist)
    flist(i).fullName = fullfile(dDir,flist(i).name);
    fprintf('%d - %s\n', i, flist(i).fullName );
end
%%
% grdfromfile('D:\A_PG_Data\Rik\ImageSpotGrid2\631044601 86311 Array Layout.txt', '#')
grdFromFile('/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/631158404_631158405_631158406 86312 Array Layout.txt', '#')
[names{1:length(flist)}] = deal(flist.fullName);
% %%
% names{1:18}
%%
% qt = analyzecycleseries(names);

qt = analyzeimageseries(names(1:18));

