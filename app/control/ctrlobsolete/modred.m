function [ab,bb,cb,db] = modred(a,b,c,d,elim)
%MODRED  Model simplification by state elimination.
%
%   MODRED is obsolete, use XELIM instead.
%
%   See also XELIM.

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%MODRED Model state reduction.
%   [Ab,Bb,Cb,Db] = MODRED(A,B,C,D,ELIM) reduces the order of a model
%   by eliminating the states specified in vector ELIM.  The state
%   vector is partioned into X1, to be kept, and X2, to be eliminated,
%
%       A = |A11  A12|      B = |B1|    C = |C1 C2|
%           |A21  A22|          |B2|
%       .
%       x = Ax + Bu,   y = Cx + Du
%
%   The derivative of X2 is set to zero, and the resulting equations
%   solved for X1.  The resulting system has LENGTH(ELIM) fewer states
%   and can be envisioned as having set the ELIM states to be 
%   infinitely fast.
%
%   See also BALREAL and DMODRED

%   J.N. Little 9-4-86
%   Copyright 1986-2012 The MathWorks, Inc.
if ~isa(a,'double')
   ctrlMsgUtils.error('Control:general:NotSupportedModelsofClass','modred',class(a))
end
narginchk(5,5);
rsys = modred(ss(a,b,c,d),elim);
[ab,bb,cb,db] = ssdata(rsys);
