function [x,y] = pg_circle(mp, r, nPoints)

dt = 2*pi/nPoints;
t = [0:dt:2*pi -dt]';
x = mp(1) + r.*sin(t); y = mp(2) + r.*cos(t);
