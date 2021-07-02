function [W,F,T,P, C, S] = imgReadFD10Name(name, path);
% this assumes:
% xxxxTestsiteN_P.tif;

W = [];
F = [];
T = [];
P = [];
C = [];
S = [];


if isequal(sInstrument, 'FD10')

    a = strread(baseName, '%s', 'delimiter', '_');
    if (length(a) ~= 2)
        return
    end
    arrayID     = a(1);
    pumpCycle   = a(2);

    sPathName = char(pathName);
    iSlash = findstr(sPathName,'\');
    iSlash = iSlash(length(iSlash));
    integrationTime = cellstr(sPathName(iSlash+1:length(sPathName)));
    filter  = 'F1';
end

W = arrayID;
F = filter;
T = integrationTime;
P = pumpCycle;

