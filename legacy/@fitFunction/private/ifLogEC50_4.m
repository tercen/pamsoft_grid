function [p0, pLow, pHigh] = ifLogEC50_4(X,Y)

    D = sortrows([X,Y],1);
    X = D(:,1);
    Y = D(:,2);
    
 
    p0(1) = mean(Y(find(X == min(X))));
    p0(2) = max(X) + 0.5;
    
    

    
    p0 = p0';
    pLow = [1e-7, -1e8]';
    pHigh = [1e8, -1e-7]';
    
    