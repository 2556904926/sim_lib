function [PF,R] = isPassive(G,varargin)
%isPassive  Check passivity of linear system.
%
%   PF = isPassive(G) returns TRUE if the LTI model G is passive and FALSE
%   otherwise. A system is passive when all its I/O trajectories (u(t),y(t))
%   satisfy
%                  
%      integral[0,T] y(t)'*u(t) dt > 0  for all T > 0
%                 
%   or, equivalently, when its frequency response is positive real:
%
%      G(jw) + G'(-jw) > 0  for all frequencies w.
%
%   PF = isPassive(G,NU,RHO) returns TRUE if the LTI model G is with index
%   NU at the inputs and RHO at the outputs. Such systems satisfy
%
%      integral[0,T] (y(t)'*u(t) - NU*u(t)'*u(t) - RHO*y(t)'*y(t)) dt > 0
%                 
%   Set RHO=0 or NU=0 to check whether a system is "input passive" with
%   index NU at the inputs or "output passive" with index RHO at the
%   outputs. When omitted, NU and RHO default to zero.
%
%   [PF,R] = isPassive(G,...) also returns the relative index R for the
%   corresponding passivity bound (see getPassiveIndex). The R-index
%   measures by how much the desired passivity property is satisfied (R<1)
%   or violated (R>1).
%
%   The LTI model G can be continuous or discrete. If G is an array of
%   dynamic systems, isPassive returns an array of the same size where
%   [PF(k),R(k)] = isPassive(G(:,:,k),...).
%
%   Example: Test whether G(s)=(s+1)/(s+2) is passive.
%      G = tf([1,1],[1,2]);
%      [PF,R] = isPassive(G)
%   returns PF = TRUE and R = 0.3333. Thus, G is passive. 
%
%   See also getPassiveIndex, passiveplot, getSectorIndex,
%   getSectorCrossover, getPeakGain, freqresp, nyquist,
%   DynamicSystem.

%   Copyright 1986-2017 The MathWorks, Inc.
narginchk(1,3)
ni = nargin;

% Validate G, must be non-empty square systems
[ny,nu] = iosize(G);
if (ny ~= nu) || (ny < 1)
   error(message('Control:analysis:isPassiveSquare'));
end

% Specify system H
H = [G;eye(nu)];

% Specify matrix Q
RHO = 0; NU = 0;
if (ni > 1)
   % Process optional argument NU
   NU = varargin{1};
   if ~(isnumeric(NU) && isscalar(NU) && isreal(NU) && isfinite(NU))
      error(message('Control:analysis:isPassiveScalarInputIndex'))
   end
end
if (ni > 2)
   % Process optional argument RHO
   RHO = varargin{2};
   if ~(isnumeric(RHO) && isscalar(RHO) && isreal(RHO) && isfinite(RHO))
      error(message('Control:analysis:isPassiveScalarOutputIndex'))
   end
end
Q =  [RHO*eye(ny), -1/2*eye(ny);-1/2*eye(nu), NU*eye(nu)];

%
try
   % Compute relative index R
   % Note: Ask for best possible accuracy to avoid inconsistency with
   %       getPassiveIndex
   R = getSectorIndex(H,Q,eps);
   PF = (R < 1+sqrt(eps));
catch E
   ltipack.throw(E,'command','isPassive',class(G))
end


