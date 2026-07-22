function [n,fpeak] = norm(sys,type,varargin)
%NORM  Dynamic system norms.
%
%   NORM(SYS) is the root-mean-squares of the impulse response of
%   the dynamic system SYS, or equivalently the H2 norm of SYS.
%
%   NORM(SYS,2) is the same as NORM(SYS).
%
%   NORM(SYS,inf) is the L-infinity norm of SYS, that is, the peak 
%   gain of its frequency response. In the MIMO case, NORM computes
%   the peak gain over all frequencies and input directions. This 
%   corresponds to the peak value of the largest singular value of 
%   the frequency response. See getPeakGain for more details.
%
%   NORM(SYS,inf,TOL) specifies a relative accuracy TOL for the
%   computed infinity norm (TOL=1e-2 by default).
%
%   [GPEAK,FPEAK] = NORM(SYS,inf) also returns the frequency FPEAK
%   (in rad/TimeUnit) where the gain achieves its peak value GPEAK.
%
%   If SYS is an array of dynamic systems, NORM returns an array
%   N of the same size where N(k) = NORM(SYS(:,:,k),...).
%
%   See also GETPEAKGAIN, HINFNORM, SIGMA, FREQRESP, DYNAMICSYSTEM.

%   Copyright 1986-2011 The MathWorks, Inc.
ni = nargin;
narginchk(1,3)
if ni<2
   type = 2;
elseif strcmpi(type,'inf')
   type = Inf;
elseif ~(isequal(type,2) || isequal(type,Inf))
   ctrlMsgUtils.error('Control:analysis:norm1')
end

% Compute norm
try
   switch type
      case 2
         % H2 norm
         n = normh2_(sys);    fpeak = [];
      case Inf
         % Linf norm
         [n,fpeak] = getPeakGain(sys,varargin{:});
   end
catch E
   ltipack.throw(E,'command','norm',class(sys))
end