function sys = ssequiv(sys,TL,eL,TR,eR)
%SSEQUIV  Equivalence transformation for state-space models.
%
%   SYS = SSEQUIV(SYS,T1,e1,T2,e2) takes a state-space model SYS with 
%   matrices (A,B,C,D,E) and performs the equivalence transformation
%
%      (A,B,C,E)  ->  (TL * A * TR, TL * B, C * TR, TL * E * TR)
%
%   where TL is T1 or its inverse, and TR is T2 or its inverse: 
%
%      TL = T1^e1,   TR = T2^e2,   e1,e2 in {-1,1} .
%
%   The matrices T1 and T2 must be square and invertible. Set T1,e1 or 
%   T2,e2 to [] to omit the left or right transformation.
%
%   Example 1: To transform (A,B,C,E) to (T1\A*T2,T1\B,C*T2,T1\E*T2), use
%      sys = ssequiv(sys,T1,-1,T2,1);
%  
%   Example 2: To transform (A,B,C) to (T\A*T,T\B,C*T), use
%      sys = ssequiv(sys,T,-1,T,1);
%  
%   Example 3: To transform (A,B,C,E) to (TL'*A,TL'*B,C,TL'*E), use
%      sys = ssequiv(sys,TL',1,[],[]);
%
%   See also SS2SS, BALREAL, MODALREAL, SS, GENSS.

%   Copyright 2023 The MathWorks, Inc.
narginchk(5,5)
if nmodels(sys)==0
   return
end

% Check dimensions
nL = size(TL,1);
nR = size(TR,1);
if ~(ismatrix(TL) && ismatrix(TR) && nL==size(TL,2) && nR==size(TR,2) && ...
      (nL==0 || nR==0 || nL==nR))
   error(message('Control:transformation:ssequiv1'))
end
if nL==0 && isempty(eL)
   eL = 1;
elseif ~(isnumeric(eL) && isscalar(eL) && (eL==1 || eL==-1))
   error(message('Control:transformation:ssequiv3'))
end
if nR==0 && isempty(eR)
   eR = 1;
elseif ~(isnumeric(eR) && isscalar(eR) && (eR==1 || eR==-1))
   error(message('Control:transformation:ssequiv3'))
end
   
try
   sys = ssequiv_(sys,TL,eL,TR,eR);
catch E
   ltipack.throw(E,'command','ssequiv',class(sys))
end