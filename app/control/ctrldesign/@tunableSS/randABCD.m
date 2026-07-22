function [a,b,c,d] = randABCD(Astruct,nx,ny,nu,Ts)
% Random initialization of block parameters.

%   Author(s): P. Gahinet
%   Copyright 1986-2013 The MathWorks, Inc.
if nx==0
   a = [];
elseif Ts==0
   w = 10.^(2*rand(1,nx)-1);
   switch Astruct(1)
      case 'c'
         % Companion
         p = poly(-w);
         a = balance([-p(:,2:nx+1) ; eye(nx-1,nx)]);
      case 't'
         % Tridiagonal
         a = diag(-w);
      case 'f'
         % Full
         t = rand(nx);
         a = t\diag(-w)*t;
   end
else
   Ts = abs(Ts);
   lnf = log10(pi/Ts)-0.5;
   w = 10.^(lnf-2*rand(1,nx));
   z = exp(-w*Ts);
   switch Astruct(1)
      case 'c'
         % Companion
         p = poly(z);
         a = balance([-p(:,2:nx+1) ; eye(nx-1,nx)]);
      case 't'
         % Tridiagonal
         a = diag(z);
      case 'f'
         % Full
         t = rand(nx);
         a = t\diag(z)*t;
   end
end
g = 10^(2*rand-1);
b = g * (2*rand(nx,nu)-1);
c = g * (2*rand(ny,nx)-1);
d = (g/10)^2 * (2*rand(ny,nu)-1);

