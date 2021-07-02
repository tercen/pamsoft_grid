function [xPos, yPos] = getPosition(oq)
[r,c] = size(oq);
oq = struct(oq);
oProps = [oq(:).oProperties];
oProps = reshape(oProps,r,c); oProps = struct(oProps);
oSeg = [oq(:).oSegmentation];
oSeg = reshape(oSeg,r,c); oSeg = struct(oSeg);
dummy = getposition(oProps, oSeg);

[xPos{1:r, 1:c}] = deal(dummy.X_Position);
[yPos{1:r, 1:c}] = deal(dummy.Y_Position);

xPos = cell2mat(xPos);
yPos = cell2mat(yPos);


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