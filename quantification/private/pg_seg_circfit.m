function   [xc,yc,R,nChiSqr, a] = pg_seg_circfit(x,y, w)
%
%   [xc yx R] = circfit(x,y)
%
%   fits a circle  in x,y plane in a more accurate
%   (less prone to ill condition )
%  procedure than circfit2 but using more memory
%  x,y are column vector where (x(i),y(i)) is a measured point
%
%  result is center point (yc,xc) and radius R
%  an optional output is the vector of coeficient a
% describing the circle's equation
%
%   x^2+y^2+a(1)*x+a(2)*y+a(3)=0
%
%  By:  Izhak bucher 25/oct /1991, modified by Rdw dec 2005    
   x=x(:); y=y(:);
   if nargin == 2 
       w = ones(size(x));
   end
   A = [x y ones(size(x))];
   b = -(x.^2+y.^2);
   warning('off', 'MATLAB:rankDeficientMatrix');
   a = linsolve([w,w,w].*A,w.*b,struct('RECT',true));
   warning('on', 'MATLAB:rankDeficientMatrix');
   xc = -.5*a(1);
   yc = -.5*a(2);
   R  =  sqrt((a(1)^2+a(2)^2)/4-a(3));
  
   nChiSqr = sum( (w.*(b-A*a)).^2) / (size(A,1) - size(A,2));
   
   