function [x,y] = circle(x0, y0, r, nPoints)
dt = 2*pi/nPoints;
t = [0:dt:2*pi -dt]';
x = x0 + r*sin(t); y = y0 + r*cos(t);
% EOF
