function [p0, pLow, pHigh] = ifLogIC50_3bw(X,Y)
D = sortrows([X,Y],1);
X = D(:,1);
Y = D(:,2);

yLeft = mean(Y(X == min(X)));
yRight = mean(Y(X == max(X)));

if yLeft > yRight
    p0(1) = 0;
    p0(2) = yLeft;

else
    p0(2) = -yRight;
    p0(1) = yRight;
end




    

%p0(1) = mean(Y(find(Y == max(Y))));
%p0(2) = mean(Y(find(X == min(X))));
p0(3) = max(X) + 0.5;

p0 = p0';
pLow = [-1e8, -1e8, -1e8];
pHigh = [1e8 ,1e8, -1e-7];
    
    