function y = utFcnBasisOuterProduct(FDATA,varargin)
% Helper function for NDBASIS.

%   Author(s): P. Gahinet
%   Copyright 1986-2017 The MathWorks, Inc.

% This function takes a cell array FDATA of vector-valued functions 
% F1,...,FN and a list VARARGIN of scalar values such that
%    X = [VARARGIN{:}] = [X1 X2 ... XN]
% provides one set of input values for each function Fj. If
%    Y1 = [1 , F1(X1)]
%    Y2 = [1 , F2(X2)]
%    ...
%    YN = [1 , FN(XN)]
% are the vector values of F1,...,FN, then Y = Z(2:end) where Z is the 
% ND array with generic entry
%    Z(i1,...,iN) = Y1(i1) Y2(i2) ... YN(iN) .
nF = numel(FDATA);
if nF==1
   % Single basis
   y = FDATA{1}(varargin{:});
else
   % Recursive evaluation
   k = 0;
   F = FDATA{1};
   nargs = nargin(F);
   y = [1 , F(varargin{k+1:k+nargs})];
   k = k+nargs;
   for ct=2:nF
      F = FDATA{ct};
      nargs = nargin(F);
      y = y' * [1 , F(varargin{k+1:k+nargs})];  % outer product
      y = reshape(y,[1 numel(y)]);
      k = k+nargs;
   end
   y = y(1,2:end);
end