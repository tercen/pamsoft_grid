function settings = getSettings(oq)

oq = struct(oq);
[nRow, nCol] = size(oq);
oSeg = [oq(:).oSegmentation];
oSeg = reshape(oSeg, nRow, nCol); oSeg = struct(oSeg);
[settings(1:nRow, 1:nCol).Segmentation_Method] = deal(oSeg.method);
[settings(1:nRow, 1:nCol).Segmentation_AreaSize] = deal(oSeg.areaSize);
[settings(1:nRow, 1:nCol).Segmentation_nFilterDisk] = deal(oSeg.nFilterDisk);    

dummy = getEdgeSensitivity(oSeg);
[settings(1:nRow, 1:nCol).Segmentation_WeakEdgeSensitivity]      = deal(dummy.weakEdge);
[settings(1:nRow, 1:nCol).Segmentation_StrongEdgeSensitivity]    = deal(dummy.strongEdge);
dummy = getOutlierMethod(oq);
[settings(1:nRow, 1:nCol).Quantification_OutlierMethod]          = deal(dummy.outlierMethod);
[settings(1:nRow, 1:nCol).Quantification_OutlierMeasure]         = deal(dummy.outlierMeasure);
function shelp = getEdgeSensitivity(os)
[r,c] = size(os);
for i=1:r
    for j=1:c
        es = os(i,j).edgeSensitivity;
        shelp(i,j).weakEdge= es(1);
        shelp(i,j).strongEdge = es(2);
    end
end

function shelp = getOutlierMethod(oq)
[r,c] = size(oq);
for i=1:r
    for j=1:c
        oOut = oq(i,j).oOutlier;
        if ~isempty(oOut)
            shelp(i,j).outlierMethod     = get(oOut, 'method');
            shelp(i,j).outlierMeasure    = get(oOut, 'measure');
        else
            shelp(i,j).outlierMethod     = [];
            shelp(i,j).outlierMeasure    = [];
    
        end
    end
end


% if nargout == 2
%     q0 = oq(1,1);
%     settings.Segmentation_Method   = get(q0.oSegmentation, 'method');
%     settings.Segmentation_AreaSize  = get(q0.oSegmentation, 'areaSize');
%     settings.Segmentation_nFilterDisk = get(q0.oSegmentation, 'nFilterDisk');
%     es = get(q0.oSegmentation, 'edgeSensitivity');
%     settings.Segmentation_EdgeSensitivity = es(2);
%     settings.Segmentation_PixFlexibility = get(q0.oSegmentation, 'thrPixFlexibility');
%     if isempty(q0.oOutlier)
%         settings.Quantification_OutlierMethod = 'none';
%         settings.Quantification_OutlierMeasure = [];
%     else
%         settings.Quantification_OutlierMethod = get(q0.oOutlier, 'method');
%         settings.Quantification_OutlierMeasure = get(q0.oOutlier, 'measure');
%     end
% end