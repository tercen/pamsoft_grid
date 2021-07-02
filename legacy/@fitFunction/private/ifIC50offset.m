function [p0, pLow, pHigh] = ifIC50offset(X,Y)

    D = sortrows([X,Y],1);
    X = D(:,1);
    Y = D(:,2);
    
    p0(1) = 0;
    p0(2) = mean(Y(find(X == min(X))));
    MinP1 = 1e-4;
    if p0(1) < MinP1
        p0(1) = MinP1;
    end
    
    iRh = find(Y <= (p0(2)-p0(1))/2);
    iLh = find(Y >  (p0(2)-p0(2))/2);
    %iRh= iRh(1);
    %iLh = iLh(length(iLh));
    if ~isempty(iRh) & ~isempty(iLh)
        xRh = log10(mean(X(iRh)));
        xLh = log10(mean(X(iLh)));
        p0(3) =10^((xRh + xLh)/2);
    else
        p0(3) = (max(X) - min(X))/2;
    end
    
    p0 = p0';
    pLow = [MinP1,1e-10, -1e-20]';
    pHigh = [1e8,1e8, 1e8]';
    