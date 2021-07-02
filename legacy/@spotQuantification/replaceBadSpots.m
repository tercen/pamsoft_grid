function q = replaceBadSpots(q, dftSpotSize)
if nargin < 2
    dftSpotSize = [];
end

%[nRows, nCols] = size(q);
qs = struct(q);
isBad = [qs(:).isBad];
iBad = find(isBad);
for i=1:length(iBad)
    q(iBad(i)).oSegmentation = setAsDftSpot(q(iBad(i)).oSegmentation, dftSpotSize);
    q(iBad(i)).isReplaced = true;
end

    



% for i =1:nRows
%     for j=1:nCols  
%         oProp = q(i,j).oProperties;
%         if isempty(oProp)
%             error('oProperties has not been set');
%         end
%         bOk = check(oProp, varargin{:});
%         if any(~bOk)
%             oSeg = q(i,j).oSegmentation;
%             if isempty(oSeg)
%                 error('oSegmentation has not been set');
%             end
%             oSeg = setAsDftSpot(oSeg, dftSpotSize);
%             q(i,j).oSegmentation = oSeg;
%             q(i,j).wasBad = true;
%         end
%     end
% end

            