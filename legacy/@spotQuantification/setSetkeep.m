function oq = setSet(q0, oSeg, oProps, clID)
[nRows, nCols] = size(oSeg);
for i=1:nRows
    for j=1:nCols
        if numel(q0) == 1
            oq(i,j) = q0;
        else
            oq(i,j) = q0(i,j);
        end
        
        if ~isempty(oSeg)
            oq(i,j).oSegmentation = oSeg(i,j);
        end
        if ~isempty(oProps)
            oq(i,j).oProperties = oProps(i,j);
        end
  
        if ~isempty(oq(i,j).oSegmentation)
            oq(i,j) = setBackgroundMask(oq(i,j));    
            
        end
        
        if ~isempty(clID)
            oq(i,j).ID = clID{i,j};
        end
        
    end
end

