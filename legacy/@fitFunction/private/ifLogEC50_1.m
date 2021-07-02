function [p0, pLow, pHigh] = ifLogEC50_1(X,Y)

    D = sortrows([X,Y],1);
    X = D(:,1);
    Y = D(:,2);
    
    p0(1) = 1e-7;
    p0(2) = mean(Y(find(X == max(X))));
    p0(3) = max(X) + 0.5;
    p0(4) = -1;
    

    
    p0 = p0';
    pLow = [1e-7, 1e-7, -1e8, -1e8];
    pHigh = [1e8, 1e8 , -1e-7, -1e-7];
    
    