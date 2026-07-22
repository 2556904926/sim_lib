function [num,den] = randND(nz,np,Ts)
% Random sampling of block parameters.

%   Author(s): P. Gahinet
%   Copyright 1986-2013 The MathWorks, Inc.
wp = 10.^(2*rand(1,np)-1);
wz = 10.^(2*rand(1,nz)-1);
g = 10^(2*rand-1);
if Ts==0
   num = g * poly(-wz);
   den = poly(-wp);
else
   fs = pi/50;
   num = g * poly(exp(-wz*fs));
   den = poly(exp(-wp*fs));
end
