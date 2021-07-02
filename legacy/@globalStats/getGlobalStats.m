function [localT, localCV, globalCVAll, globalCVFiltered, nFiltered, hFig] = getGlobalStats(g,data, bOutput, strID)
%[localT, localCV, globalCVAll, globalCVFiltered] = getGlobalStats(g, data, bOutput)
% data: (NxM) matrix containing reference data from N wells using M intra
% well multiples
% localT:       Nx1 matrix with t - factor of individual well based on
% ensemble average
% localCV       Nx1 matrix with CV (as a fraction) of multiples in
% individual well
% globalCVAll, CV (as a fraction) of reference data in all wells
% globalCVFiltered, CV (as a fraction) of reference data in wells after
% outlier removal
if nargin < 3 | isempty(bOutput);
    bOutput = 0;
end

if nargin < 4
    strID = 'unknown';
end

[s1,s2] = size(data);

for i=1:s2
    m = mean(data(:,i));
    if m ~= 0
        mData(:,i) = data(:,i)/m;
    else
        mData(:,i) = mData(:,i) + 1;

    end
end

sData = std(mData,0,2);
mData = mean(mData,2);




globalCVAll = std(mData)/mean(mData);


iOut = findOutliersRW(mData, g.odSigmaFac, g.odEpsilon);
%iOut = RWoutlierDetection(mData, g.pOut);
mFiltered = mean(mData(~iOut));
nFiltered = length(mData(~iOut));
sFiltered = std(mData(~iOut));
globalCVFiltered = sFiltered/mFiltered;
localT      = (mData - mFiltered)/sFiltered;
localCV     = sData./mData;

if bOutput
    hFig = graphOut(mData, sData, iOut, strID);
else
    hFig = 0;
end




