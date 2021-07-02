function [p0, pLow, pHigh] = ifLogIC50(X,Y)

    D = sortrows([X,Y],1);
    X = D(:,1);
    Y = D(:,2);
    
    p0(1) = 1e-7;
    %p0(2) = mean(Y(find(X == min(X))));
    Yleft   = mean(Y(find(X==min(X))));
    Yright  = mean(Y(find(X==max(X))));
    
    [p0(2), iMax] = max([Yleft, Yright]);
    %p0(3) = max(X) + 0.5;
    if iMax == 1
        p0(4) = -1;
        p0(3) = max(X) + 0.5;
    else
        p0(4) = 1;
        p0(3) = max(X) + 0.5;
    end

    
    p0 = p0';
    pLow = [1e-7, 1e-7, -1e8, -10];
    pHigh = [1e8, 1e8 , -1e-7, 10];
    
    