function [Dc, Ds]= spotDipole(I, mp, r)
[i,j] = find(ones(size(I))); % coordinates into the image;
[cx,cy] = circle(mp, r, round(2*pi*r)); % coordinates of the circle;
bIn = inpolygon(i,j,cx,cy); % true if inside the circle

ii = ([i,j] - repmat(mp, length(i),1))/r; %normalized image coordinates
II = [I(:), I(:)];

dc = sum(ii(bIn,:).*II(bIn,:));
Dc = norm(dc)/length(find(bIn));
Ds = norm(dc)/mean(II(bIn,1));



