function D = distanceMap(x,y)
% calculates euclidian distances between all points with coordinates in the
% vectors x and y
X = meshgrid(x); Y = meshgrid(y);
D = sqrt( (X-X').^2 + (Y-Y').^2);

