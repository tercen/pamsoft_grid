function D = spotDipole(I, bIn, oS)

[i,j] = find(true(size(I)));% coordinates into the image;
mp  = get(oS, 'finalMidpoint');
r   = get(oS, 'diameter')/2;
%D = dipole(I, mp, r);
bIn = bIn(:);
ii = ([i,j] - mp(ones(size(I)),:))/r; %normalized image coordinates
II = double([I(:), I(:)]);

dc = sum(ii(bIn,:).*II(bIn,:));
D  = norm(dc)/length(find(bIn));


function Dc = dipole(I, midpoint, radius)
[i,j] = find(ones(size(I))); % coordinates into the image;
[cx,cy] = circle(midpoint, radius, round(2*pi*radius)); % coordinates of the circle;
bIn = inpolygon(i,j,cx,cy); % true if inside the circle


ii = ([i,j] - repmat(midpoint, length(i),1))/radius; %normalized image coordinates
II = double([I(:), I(:)]);

dc = sum(ii(bIn,:).*II(bIn,:));
Dc = norm(dc)/length(find(bIn));
% Ds = norm(dc)/mean(II(bIn,1));


