function [K,S,CLP] = dlqr(a,b,q,r,varargin)
%DLQR  Linear-quadratic regulator design for discrete-time systems.
%
%   [K,S,CLP] = DLQR(A,B,Q,R,N) calculates the optimal gain matrix K 
%   such that the state-feedback control u[n] = -Kx[n] minimizes the 
%   cost function
%
%         J = Sum {x'Qx + u'Ru + 2*x'Nu}
%
%   subject to the state dynamics  x[n+1] = Ax[n] + Bu[n].  
%
%   The matrix N is set to zero when omitted.  Also returned are the
%   Riccati equation solution S and the closed-loop eigenvalues CLP                            
%                                  -1
%       A'SA - S - (A'SB+N)(R+B'SB) (B'SA+N') + Q = 0 ,
%
%       CLP = EIG(A-B*K) .
%
%   See also DLQRY, LQRD, LQGREG, IDARE.

%   Author(s): J.N. Little , P. Gahinet
%   Copyright 1986-2018 The MathWorks, Inc.
narginchk(4,5)
if ~isnumeric(a)
   error(message('Control:general:NotSupportedModelsofClass','dlqr',class(a)))
end

% Check dimensions
error(abcdchk(a,b));

try
   [K,S,CLP] = lqr(ss(a,b,[],[],1),q,r,varargin{:});
catch ME
   throw(ME);
end