function q = check4BadSpots(q, varargin)
[nRows, nCols] = size(q);
for i =1:nRows
    for j=1:nCols 
        oProp = q(i,j).oProperties;
        if isempty(oProp)
            error('oProperties has not been set');
        end
        bOk = check(oProp, varargin{:});
        if any(~bOk)
              q(i,j).isBad = true;  
        end
    end
end

            