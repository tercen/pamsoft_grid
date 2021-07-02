function bg = ilBackground(I, cx, cy, d);
a = 1:size(cx,1);
b = 2:size(cx,2);
ai = [0.5, ai +0.5];
bi = [0.5, bi +0.5];
xi = interp2(b,a,x,bi, ai');
yi = interp2(b,a,y,bi, ai');

xi(:,1) = xi(:,2);
xi(:,end) = xi(:,end-1);

dx = x(2,1) - x(1,1);
dy = y(1,2) - y(1,1); 
yi(:,1) = yi(:,2) - dy;
yi(:,end) = yi(:,end-1) + dy;




