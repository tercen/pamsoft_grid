function [p0, pLower, pUpper] = ifExpAss(X,Y)


p0(1) = min(Y);
p0(2) = max(Y) - min(Y);
XMID  = (max(X) - min(X))/2;
xi = find(X<XMID);
if ~isempty(xi)
    xi = xi(length(xi));
else
    xi = 1;
end

p0(3) = 1.3/(X(xi));
p0 = p0';
pLower = [-1e8;-1e8;1e-7];
pUpper = [1e8; 1e8; 1e8];

