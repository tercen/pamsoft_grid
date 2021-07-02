function q = replaceEmptySpots(q, dftSpotSize)
if nargin < 2
    % if not specified the dftSpotSize will be set to 0.6 * spotPitch,
    % by setAsDftSpot
    dftSpotSize = [];
end

qs = struct(q(:));
emptySpot = [qs(:).isEmpty];
iEmpty = find(emptySpot);
for i=1:length(iEmpty)
    q(iEmpty(i)).oSegmentation = setAsDftSpot(q(iEmpty(i)).oSegmentation, dftSpotSize);
    q(iEmpty(i)).isReplaced = true;
end



            


