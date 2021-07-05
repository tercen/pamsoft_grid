function [p0, pLow, pHigh] = ifLogIC50_2(X,Y)

    D = sortrows([X,Y],1);
    X = D(:,1);
    Y = D(:,2);
    
   
    p0(1) = max(X) + 0.5;
    p0(2) = -1;
    

    
    p0 = p0';
    pLow = [1e-7, -1e8, -1e8];
    pHigh = [1e8 , -1e-7, -1e-7];
    
    