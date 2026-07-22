function G = getData(blk,j)
%GETDATA  Get values of surface coefficients.
%
%   A tunable surface GS is a surface parameterization of the form
%
%         G(x) = G0 + f1(n(x)) G1 + ... + fm(n(x)) Gm
%
%   where f1,...,fm are basis functions, n(x) normalizes the range of x
%   to [-1,1]^N, and G0,G1,...,Gm are tunable coefficients.
%
%   G = GETDATA(GS) returns the current values of the tunable coefficients
%   in the double array G=[G0,G1,...,Gm].
%
%   GJ = GETDATA(GS,J) returns the current value of the coefficient for
%   the J-th basis function fj(.). Use J=0 to get the constant coefficient
%   G0.
%
%   See also SETDATA, EVALSURF, VIEWSURF, tunableSurface.

%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(1,2)
G = blk.Coefficients_.Value;
if nargin>1
   % Extract Gj
   nu = blk.IOSize_(2);
   nf = blk.nFun_;
   if ~(isscalar(j) && isreal(j) && j==round(j) && j>=0 && j<=nf)
      error(message('Control:lftmodel:getsetData1',nf))
   end
   G = G(:,j*nu+1:(j+1)*nu);
end