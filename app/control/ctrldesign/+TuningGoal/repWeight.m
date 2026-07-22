function [A,B,C,D] = repWeight(aW,bW,cW,dW,N)
% Constructs realization of W*eye(N) where W is a SISO weight.

% Copyright 2009-2012 The MathWorks, Inc.
nx = size(aW,1);
nxN = nx*N;
A = zeros(nxN);
B = zeros(nxN,N);
C = zeros(N,nxN);
D = zeros(N);
ix = 0;
for ct=1:N
   A(ix+1:ix+nx,ix+1:ix+nx) = aW;
   B(ix+1:ix+nx,ct) = bW;
   C(ct,ix+1:ix+nx) = cW;
   D(ct,ct) = dW;
   ix = ix + nx;
end
