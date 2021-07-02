function qCombined = combineExpTimeQuantification(qIn,expTime, maxSaturation)
% function qCombined = combineExposureTimeQuantifcation(qIn, expTime, maxSaturation)
% combines the multiple exposure time quantifcation qIn into a new combined
% spotQuantification object qCombined. 
% The combined object will posses data in units expTime, were the optimal
% exposure time is selected on a per spot basis. The optimal exposure time
% is the longest exposure time were the percentage of saturated pixels of a
% spot is lower than maxSaturation.
%
% qIn (i * j * k) array of spotquantifcation object where i and j correspond
% to array dimensions and k to the exposure times used.
%
% expTime. k element vector of exposure times
%
% maxSaturation (optional, dft = 0.02). max fraction of saturation pixels accpetable for a given exposuretime.
% (NOTE: in the combined object the property signalSaturation will
% correspond to that of the exposure time used).

if nargin == 2
    maxSaturation = 0.02;
end

if size(qIn,3) ~= length(expTime)
    error('size of input argument expTime does not conform to that of input argument qIn')
end

medSig      = get(qIn, 'medianSignal');
medBg       = get(qIn, 'medianBackground');
meanSig     = get(qIn, 'meanSignal');
meanBg      = get(qIn, 'meanBackground');
sSig        = get(qIn, 'stdSignal');
sBg         = get(qIn, 'stdBackground');
mxSignal    = get(qIn, 'maxSignal');
mnSignal    = get(qIn, 'minSignal');
mxBg        = get(qIn, 'maxBackground');
mnBg        = get(qIn, 'minBackground');
pSat        = get(qIn, 'signalSaturation');

oComb = combineExposureTimes('combinationCriterium', maxSaturation);

cMedSig     = combineData(oComb, double(medSig)     , pSat, expTime);
cMedBg      = combineData(oComb, double(medBg)      , pSat, expTime);
cMeanSig    = combineData(oComb, meanSig    , pSat, expTime);
cMeanBg     = combineData(oComb, meanBg     , pSat, expTime);
csSig       = combineData(oComb, sSig       , pSat, expTime);
csBg        = combineData(oComb, sBg        , pSat, expTime);
cmxSignal   = combineData(oComb, double(mxSignal)   , pSat, expTime);
cmnSignal   = combineData(oComb, double(mnSignal)   , pSat, expTime);
cmxBg       = combineData(oComb, double(mxBg)       , pSat, expTime);
cmnBg       = combineData(oComb, double(mnBg)       , pSat, expTime);
cpSat       = combineData(oComb, pSat       , pSat , ones(size(expTime)));

qCombined = setSet(qIn(:,:,1)  , 'medianSignal', cMedSig, ...
                            'medianBackground', cMedBg, ...
                            'meanSignal', cMeanSig, ...
                            'meanBackground', cMeanBg, ...
                            'stdSignal', csSig, ...
                            'stdBackground', csBg, ...
                            'maxSignal', cmxSignal, ...
                            'minSignal', cmnSignal, ...
                            'maxBackground', cmxBg, ...
                            'minBackground', cmnBg, ...
                            'signalSaturation', cpSat);
                    



    
