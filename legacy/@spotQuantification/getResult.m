function res = getResult(oq)
[r,c] = size(oq);
oq = struct(oq);
[res(1:r, 1:c).Row]                  = deal(oq.arrayRow);                  
[res(1:r, 1:c).Column]               = deal(oq.arrayCol);
[res(1:r,1:c).ID]                    = deal(oq.ID);
smb = getSigmBg(oq);
[res(1:r, 1:c).Mean_SigmBg]         = deal(smb.meansmb);
[res(1:r, 1:c).Median_SigmBg]       = deal(smb.mediansmb);
[res(1:r,1:c).Mean_Signal]           = deal(oq.meanSignal);
[res(1:r, 1:c).Median_Signal]        = deal(oq.medianSignal);
[res(1:r, 1:c).Std_Signal]           = deal(oq.stdSignal);
[res(1:r, 1:c).Min_Signal]           = deal(oq.minSignal);
[res(1:r, 1:c).Max_Signal]           = deal(oq.maxSignal);
[res(1:r, 1:c).Mean_Background]      = deal(oq.meanBackground);
[res(1:r, 1:c).Median_Background]    = deal(oq.medianBackground);
[res(1:r, 1:c).Std_Background]       = deal(oq.stdBackground);
[res(1:r, 1:c).Min_Background]       = deal(oq.minBackground);
[res(1:r, 1:c).Max_Background]       = deal(oq.maxBackground);
[res(1:r, 1:c).Signal_pValue]        = deal(oq.pSignal);
[res(1:r, 1:c).Signal_Saturation]    = deal(oq.signalSaturation);
dummy = getpignored(oq);
[res(1:r, 1:c).Fraction_Ignored]    = deal(dummy.pIgnored);

oProps = [oq(:).oProperties];
oProps = reshape(oProps,r,c); oProps = struct(oProps);
[res(1:r, 1:c).Diameter]            = deal(oProps.diameter);
[res(1:r, 1:c).Shape_Factor]        = deal(oProps.formFactor);
[res(1:r, 1:c).Aspect_Ratio]        = deal(oProps.aspectRatio);
[res(1:r, 1:c).nChiSqr ]            = deal(oProps.nChiSqr);

oSeg = [oq(:).oSegmentation];
oSeg = reshape(oSeg,r,c); oSeg = struct(oSeg);
dummy = getposition(oProps, oSeg);
[res(1:r, 1:c).X_Position]  = deal(dummy.X_Position);
[res(1:r, 1:c).Y_Position]  = deal(dummy.Y_Position);
[res(1:r, 1:c).X_Offset]    = deal(dummy.X_Offset);
[res(1:r, 1:c).Y_Offset]    = deal(dummy.Y_Offset);
[res(1:r, 1:c).Empty_Spot]  = deal(oq.isEmpty);
[res(1:r, 1:c).Bad_Spot]    = deal(oq.isBad);
[res(1:r, 1:c).Replaced_Spot] = deal(oq.isReplaced);

function shelp = getpignored(oq)
[r,c] = size(oq);
for i=1:r
    for j=1:c
        iIgnored = oq(i,j).iIgnored;
        sz = get(oq(i,j).oSegmentation, 'bsSize');
        if ~isempty(sz)
            shelp(i,j).pIgnored = length(iIgnored)/(sz(1)*sz(2));
        else
            shelp(i,j).pIgnored = [];
        end
    end
end

function shelp = getposition(op, os)
[r,c] = size(op);
for i=1:r
    for j =1:c
        if ~isempty(op(i,j).position)
            shelp(i,j).X_Position = op(i,j).position(1) + os(i,j).cLu(1) - 1;
            shelp(i,j).Y_Position = op(i,j).position(2) + os(i,j).cLu(2) - 1;
        else
            shelp(i,j).X_Position = [];
            shelp(i,j).Y_Position = [];
        end
        if ~isempty(op(i,j).positionOffset)
            shelp(i,j).X_Offset = op(i,j).positionOffset(1);
            shelp(i,j).Y_Offset = op(i,j).positionOffset(2);
        else
            shelp(i,j).X_Offset = [];
            shelp(i,j).Y_Offset = [];
        end
    end
end

function out = getSigmBg(oq)

[nRows, nCols] = size(oq);
for i =1:nRows
    for j =1:nCols
        out(i,j).meansmb     = oq(i,j).meanSignal - oq(i,j).meanBackground;
        out(i,j).mediansmb   = int32(oq(i,j).medianSignal) - int32(oq(i,j).medianBackground);
    end
end