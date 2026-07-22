function blk = setData(blk,varargin)
%SETDATA  Set values of surface coefficients.
%
%   A tunable surface GS is a surface parameterization of the form
%
%         G(x) = G0 + f1(n(x)) G1 + ... + fm(n(x)) Gm
%
%   where f1,...,fm are basis functions, n(x) normalizes the range of x
%   to [-1,1]^N, and G0,G1,...,Gm are tunable coefficients.
%
%   GS = SETDATA(GS,G) sets the values of all tunable coefficients at
%   once using the array G = [G0,G1,...,Gm].
% 
%   GS = SETDATA(GS,J,GJ) sets the value of the coefficient for the J-th 
%   basis function to GJ. Use J=0 to set the value of G0.
%
%   See also GETDATA, EVALSURF, VIEWSURF, tunableSurface.

%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(2,3)
ny = blk.IOSize_(1);
nu = blk.IOSize_(2);
nf = blk.nFun_;
if nargin>2
   j = varargin{1};  G = varargin{2}; 
   if ~(isscalar(j) && isreal(j) && j==round(j) && j>=0 && j<=nf)
      error(message('Control:lftmodel:getsetData1',nf))
   elseif ~(isnumeric(G) && isreal(G) && isequal(size(G),[ny nu]))
      error(message('Control:lftmodel:getsetData2',mat2str([ny nu])))
   end
   blk.Coefficients_.Value(:,j*nu+1:(j+1)*nu) = G;
else
   G = varargin{1}; 
   refSize = [ny nu*(nf+1)];
   if ~(isnumeric(G) && isreal(G) && isequal(size(G),refSize))
      error(message('Control:lftmodel:getsetData3',mat2str(refSize)))
   end
   blk.Coefficients_.Value = G;
end