function q = check4EmptySpots(q)

[nRows, nCols] = size(q);
for i=1:nRows
    for j=1:nCols
        os = q(i,j).oSegmentation;
        bw = get(os, 'binSpot');
        if ~any(bw(:))
            q(i,j).isEmpty = true;
        end       
    end
end


            


