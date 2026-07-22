function [sys,u] = minreal(sys,tol,dispflag)
%MINREAL  Minimal realization and pole-zero cancellation.
%
%   MSYS = MINREAL(SYS) computes a minimal realization MSYS of the LTI model
%   SYS. For state-space models, MINREAL eliminates all uncontrollable or 
%   unobservable states. For transfer functions, MINREAL eliminates all
%   cancelling pole/zero pairs.
%
%   MSYS = MINREAL(SYS,TOL) further specifies the tolerance TOL used for 
%   pole-zero cancellation or state dynamics elimination. The default value is 
%   TOL=SQRT(EPS) and increasing this tolerance may force additional 
%   cancellations.
%
%   For a state-space model SYS=SS(A,B,C,D),
%      [MSYS,U] = MINREAL(SYS)
%   also returns an orthogonal matrix U such that (U*A*U',U*B,C*U') is a 
%   Kalman decomposition of (A,B,C). 
%
%   See also SMINREAL, BALRED, BALREAL, LTI.

%   Authors: J.N. Little, A.C.W.Grace, P. Gahinet
%   Copyright 1986-2010 The MathWorks, Inc.

% Note: no balancing since nearness to non-minimal is not
% invariant under ill-conditioned transf.
% Take for instance A = [1 100;1e-14 1], B = [1;0], C=[1 1]
ni = nargin;
no = nargout;
narginchk(1,3)
if ni<2 || isempty(tol),
   tol = sqrt(eps);
end

% Validate data
if no>1 && numsys(sys)~=1
   ctrlMsgUtils.error('Control:transformation:minreal2','minreal')
elseif ~(isnumeric(tol) && isscalar(tol) && tol>0)
   ctrlMsgUtils.error('Control:transformation:minreal3')
end

% Eliminate cancelling dynamics
isStateSpace = isa(sys,'StateSpaceModel');
dispflag = isStateSpace && numsys(sys)==1 && (ni<3 || dispflag);
try
   hw = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU>
   if isStateSpace && no>1
      [sys,u] = minreal_(sys,tol,dispflag);
   else
      sys = minreal_(sys,tol,dispflag); 
      u = [];
   end
catch E
   ltipack.throw(E,'command','minreal',class(sys))
end
