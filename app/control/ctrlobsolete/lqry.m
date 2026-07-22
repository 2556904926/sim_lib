function [k,s,e] = lqry(a,b,c,d,q,r,varargin)
%LQRY  Linear-quadratic regulator design with output weighting.
%
%   LQRY computes the state-feedback control u = -K*x that minimizes
%   the cost function
%
%      J = Integral {y'Qy + u'Ru + 2*y'Nu} dt     (continuous time)
%
%      J = Sum {y'Qy + u'Ru + 2*y'Nu}             (discrete time)
%
%   for the system dynamics 
%
%      dx/dt = Ax + Bu,  y = Cx + Du              (continuous time)
%
%      x[n+1] = Ax[n]+Bu[n],  y[n] = Cx[n]+Du[n]  (discrete time).
%
%   [K,S,CLP] = LQRY(SYS,Q,R,N) calculates the optimal gain matrix K for 
%   the continuous or discrete state-space model SYS. LQRY also returns 
%   the solution S of the associated algebraic Riccati equation and the 
%   closed-loop poles CLP = EIG(A-B*K). The matrix N is set to zero when 
%   omitted.
%
%   Note: 
%     * (A,B) must be stabilizable and [Q N;N' R] must be nonnegative
%       definite.
%     * The optimal cost is J(x0) = x0'*S*x0 where x0 is the initial state.
%
%   See also LQR, LQGREG, LQG, ICARE, IDARE.

%Old help
%LQRY   Linear quadratic regulator design with output weighting
%   for continuous-time systems.
%
%   [K,S,E] = LQRY(A,B,C,D,Q,R) calculates the optimal feedback
%   gain matrix K such that the feedback law  u = -Kx  minimizes
%   the cost function:
%
%      J = Integral {y'Qy + u'Ru} dt
%
%   subject to the constraint equation: 
%      .
%      x = Ax + Bu,  y = Cx + Du
%                
%   Also returned is S, the steady-state solution to the associated 
%   algebraic Riccati equation and the closed loop eigenvalues
%   E = EIG(A-B*K).
%
%   The controller can be formed using REG.
%
%   See also: LQR, LQR2 and REG.

%   J.N. Little 7-11-88
%   Revised: 7-18-90 Clay M. Thompson, P. Gahinet 7-24-96
%   Copyright 1986-2007 The MathWorks, Inc.
ni = nargin;
if ni>0 && ~isa(a,'double')
   ctrlMsgUtils.error('Control:general:NotSupportedModelsofClass','lqry',class(a));
end
narginchk(6,7);

% Check dimensions
error(abcdchk(a,b,c,d));

% Call lti/lqry
[k,s,e] = lqry(ss(a,b,c,d),q,r,varargin{:});

% end lqry
