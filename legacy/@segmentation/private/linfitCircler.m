function [xFit, yFit, parOut] = linfitCircler(x,y,w)
if nargin < 3
    w = ones(size(x));
end



dt = 2*pi/length(x);
t = [0:dt:2*pi- dt]' ;


wBoth = [w;w];
dBoth = [x;y];
tBoth = [t - pi/2; t ];
oBoth = [ones(size(t)); zeros(size(t))];



A = [oBoth, flipud(oBoth), sin(tBoth), cos(tBoth)];

wA = A .* repmat(wBoth, 1, size(A,2));
wd = dBoth .* wBoth;
par = linsolve(wA, wd, struct('RECT',true));
x0  = par(1);
y0  = par(2);
r1 =  par(3);
r2 =  par(4);

% no we need to solve the following for r and teta:
% % r = r1*sin(teta)
% % r = r2*cos(teta)
% % hence
% r       = r2 * (pi/2 - r1);
% teta    = acos(r/r2);
parOut.x0   = x0;
parOut.y0   = y0;
parOut.r1    = r1;
parOut.r2   = r2;

dFit = A*par;
xFit = dFit(1:length(t));
yFit = dFit(length(t)+1:end);

