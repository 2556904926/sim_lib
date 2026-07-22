function [K,X,E] = lqr(a,b,q,r,varargin)
%LQR  Linear-quadratic regulator design for state-space systems.
%
%   LQR computes the state-feedback control u = -K*x that minimizes
%   the cost function
%
%      J = Integral {x'Qx + u'Ru + 2*x'Nu} dt     (continuous time)
%
%      J = Sum {x'Qx + u'Ru + 2*x'Nu}             (discrete time)
%
%   for the state dynamics dx/dt = Ax+Bu or x[n+1] = Ax[n]+Bu[n].
%
%   [K,S,CLP] = LQR(SYS,Q,R,N) calculates the optimal gain matrix K for the
%   continuous or discrete state-space model SYS. LQR also returns the
%   solution S of the associated algebraic Riccati equation and the 
%   closed-loop poles CLP = EIG(A-B*K). The matrix N is set to zero when 
%   omitted.
%
%   [K,S,CLP] = LQR(A,B,Q,R,N) is an equivalent syntax for continuous-time
%   models with dynamics dx/dt = Ax+Bu.
%
%   Note: 
%     * (A,B) must be stabilizable and [Q N;N' R] must be nonnegative
%       definite.
%     * The optimal cost is J(x0) = x0'*S*x0 where x0 is the initial state.
%
%   See also DLQR, LQRY, LQI, LQG, LQGREG, LQGTRACK, ICARE, IDARE.

%   Author(s): J.N. Little, P. Gahinet
%   Copyright 1986-2018 The MathWorks, Inc.
if nargin>0 && ~isnumeric(a)
   error(message('Control:general:NotSupportedModelsofClass','lqr',class(a)))
end
narginchk(4,5)

% Check dimensions
error(abcdchk(a,b));

try
   [K,X,E] = lqr(ss(a,b,[],[]),q,r,varargin{:});
catch ME
   throw(ME);
end
