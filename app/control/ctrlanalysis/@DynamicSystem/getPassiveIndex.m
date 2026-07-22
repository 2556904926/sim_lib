function [Index,fIndex,Q,dQ] = getPassiveIndex(G,varargin)
%getPassiveIndex  Compute passivity index of linear system.
%
%   A linear system G(s) is passive when all I/O trajectories (u(t),y(t))
%   satisfy
%               
%      integral[0,T] y(t)'*u(t) dt > 0  for all T > 0
%               
%   or equivalently, when its frequency response is positive real:
%
%      G(jw) + G'(-jw) > 0  for all frequencies w.
%
%   getPassiveIndex computes various measures of the excess/shortage of
%   passivity for a given system.
%
%   R = getPassiveIndex(G) computes the relative index R. The system is 
%   passive when its R-index is less than one, and R measures the relative 
%   excess (R<1) or shortage (R>1) of passivity. When I+G is minimum phase,
%   R coincides with the peak gain of (I-G(jw))/(I+G(jw)).
%
%   NU = getPassiveIndex(G,'input') computes the input passivity index 
%   defined as the largest NU such that
%
%      integral[0,T] (y(t)'*u(t) - NU * u(t)'*u(t)) dt > 0
%
%   or equivalently,  G(jw) + G'(-jw) > 2*NU * I.  The system G is 
%   "input strictly passive" (ISP) when NU>0. NU is also called the 
%   "input feedforward passivity" (IFP) index and corresponds to the 
%   minimum feedforward action needed to make the system passive.
%
%   RHO = getPassiveIndex(G,'output') computes the output passivity index 
%   defined as the largest RHO such that
%
%      integral[0,T] (y(t)'*u(t) - RHO * y(t)'*y(t)) dt > 0 .
%
%   The system G is "output strictly passive" (OSP) if RHO>0. RHO is also 
%   called the "output feedback passivity" (OFP) index and corresponds to 
%   the minimum feedback action needed to make the system passive.
%
%   TAU = getPassiveIndex(G,'io') computes the combined I/O passivity
%   index defined as the largest TAU such that
%
%      integral[0,T] (y(t)'*u(t) - TAU * (u(t)'*u(t)+y(t)'*y(t))) dt > 0 .
%
%   The system is "very strictly passive" (VSP) if TAU>0.
%
%   DX = getPassiveIndex(G,dQ) computes the passivity index in the direction
%   dQ, defined as the largest DX for which
%      
%      integral[0,T] (y(t)'*u(t) - DX * [y(t);u(t)]'*dQ*[y(t);u(t)]) dt > 0 .
%
%   The RHO, NU, and TAU indices correspond to particular choices of dQ.
%
%   INDX = getPassiveIndex(...,TOL) specifies the relative accuracy TOL for
%   the computed value INDX. By default INDX is computed with 1% accuracy
%   (TOL=1e-2).
%
%   INDX = getPassiveIndex(...,TOL,FBAND) computes passivity indices 
%   restricted to the frequency interval FBAND.
%
%   [INDX,FI] = getPassiveIndex(...) also returns the frequency FI (in
%   rad/TimeUnit) at which the index value INDX is achieved. FI can be 
%   negative for systems with complex data.
%
%   [INDX,FI,Q,dQ] = getPassiveIndex(...) also returns the Q,dQ matrices
%   for the underlying sector index computation, see getSectorIndex.
%
%   The LTI model G can be continuous or discrete. If G is an array of
%   dynamic systems, getPassiveIndex returns an array of the same size
%   where INDX(k) = getPassiveIndex(G(:,:,k),...).
%
%   Example: Find the IFP index of G(s)=(s+2)/(s+1).
%      G = tf([1 2],[1 1]);
%      nu = getPassiveIndex(G,'input')
%   This returns nu = 1.
%
%   See also isPassive, passiveplot, getSectorIndex, getSectorCrossover,
%   getPeakGain, freqresp, nyquist, sectorplot, DynamicSystem.

%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(1,4)
ni = nargin;

% Validate system G
[ny,nu] = iosize(G);
% G must be non-empty square systems
if (ny ~= nu) || (ny < 1)
    error(message('Control:analysis:isPassiveSquare'));
end

% Compute index
Q = [zeros(nu),-eye(nu)/2;-eye(nu)/2,zeros(nu)];
if ni>1 && isnumeric(varargin{1})
   dQ = varargin{1};
else
   dQ = [];
end
try
   if ni>1 && (ischar(varargin{1}) || isStringScalar(varargin{1}))
      IndexType = varargin{1};
      if strncmpi(IndexType,'input',2)
         % IFP
         [tol,fBand] = localParseOptions(varargin{2:end});
         [Index,fIndex] = ifpofp_(G,'input',tol,fBand);
         dQ = diag([zeros(nu,1);ones(nu,1)]);
      elseif strncmpi(IndexType,'output',2)
         % OFP
         [tol,fBand] = localParseOptions(varargin{2:end});
         [Index,fIndex] = ifpofp_(G,'output',tol,fBand);
         dQ = diag([ones(nu,1);zeros(nu,1)]);
      elseif strncmpi(varargin{1},'io',2)
         % I/O index
         H = [G;eye(nu)];
         [R,fIndex] = getSectorIndex(H,Q,varargin{2:end});
         if isinf(R)
            Index = -1/2;
         else
            Index = (1-R^2)/(1+R^2)/2;
         end
         dQ = eye(2*nu);
      else
         error(message('Control:analysis:getPassiveIndexString'))
      end
    else
      % R-index or directional index
      H = [G;eye(nu)];
      [Index,fIndex] = getSectorIndex(H,Q,varargin{:});
   end
catch E
   ltipack.throw(E,'command','getPassiveIndex',class(G))
end

%-------------- Local Functions -------------

function [tol,fBand] = localParseOptions(varargin)
ni = nargin;
if ni<1 || isempty(varargin{1})
   tol = 1e-2;
else
   tol = varargin{1};
   if ~(isnumeric(tol) && isscalar(tol) && isreal(tol) && tol>0)
      error(message('Control:analysis:getPeakGain1'))
   end
   tol = max(100*eps,double(tol));
end
if ni<2 || isempty(varargin{2})
   fBand = [];
else
   fBand = varargin{2};
   if ~(isnumeric(fBand) && isreal(fBand) && numel(fBand)==2 && fBand(2)>fBand(1))
      error(message('Control:analysis:getPeakGain2'))
   end
   fBand = double(fBand);
end
