function [Index,fIndex,W1,W2,Z] = getSectorIndex(sys,Q,varargin)
%getSectorIndex  Compute conic sector index of linear system.
%
%   getSectorIndex checks whether all output trajectories y(t)=(Hu)(t) of
%   the linear system H lie in the conic sector
%
%      integral[0,T] y(t)' Q y(t) dt < 0  for all T>=0      (1)
%
%   The symmetric matrix Q specifies the cone geometry. To check whether
%   all I/O trajectories (u(t),y(t)) of a linear system G lie in the sector
%
%      integral[0,T] [y(t);u(t)]' Q [y(t);u(t)] dt < 0  for all T>=0
%
%   use getSectorIndex with H = [G;I].
%
%   RX = getSectorIndex(H,Q) computes the relative index RX. The system H
%   satisfies the sector bound (1) if and only if RX<1. If Q1,Q2 are the
%   positive and negative parts of Q:
%
%      Q = Q1 - Q2,  Q1>0,  Q2>0,  Q1'*Q2 = 0 .
%
%   the R-index is the smallest R>0 such that (1) holds for Q = Q1-R^2*Q2.
%   Varying R amounts to adjusting the slant angle until the cone fits
%   tightly around the output trajectories of H (the cone base-to-height
%   ratio is proportional to R).
%
%   TX = getSectorIndex(H,Q,dQ) computes the directional index TX. The
%   system H satisfies the sector bound (1) if and only if TX>0. The index
%   in the direction dQ is the largest t such that (1) holds for Q replaced
%   by Q+t*dQ. The matrix dQ must be nonnegative definite.
%
%   getSectorIndex(...,TOL) specifies the relative accuracy TOL for the
%   computed index value. By default, sector indices are computed with
%   1% accuracy (TOL=1e-2).
%
%   Both indices measure how well the output trajectories of H fit in the
%   conic sector (1). The LTI model H can be continuous or discrete. For
%   the R-index, Q can be an LTI model whose frequency response Q(jw) is 
%   Hermitian and nonsingular. If H is an array of dynamic systems, 
%   getSectorIndex returns an array of the same size where
%   INDX(k) = getSectorIndex(H(:,:,k),...).
%
%   When Q has as many negative eigenvalues as inputs in H(s), the R-index
%   is either infinite or is the smallest R>0 such that 
%      H(jw)' (Q1-R^2*Q2) H(jw) < 0 for all frequencies w. 
%   The following additional options and output arguments are available in 
%   such case:
%      RX = getSectorIndex(H,Q,TOL,FBAND) computes the R-index restricted
%      to the frequency interval FBAND. 
%
%      [RX,FX] = getSectorIndex(H,Q,...) also returns the frequency FX (in
%      rad/TimeUnit) at which the index value RX is achieved. FX can be 
%      negative when H or Q are complex-valued.
%
%      [RX,FX,W1,W2,Z] = getSectorIndex(...) also returns the matrices 
%      W1,W2 and the bi-stable state-space model Z such that 
%         Q = Z'*(W1*W1'-W2*W2')*Z. 
%      Note that Z=1 when Q is a matrix.
%
%   Example: Test if the I/O trajectories of G(s) = (s+2)/(s+1) belong to
%   the sector 0.1*u^2 < u*y < 10*u^2. The Q matrix for this sector is
%       a = 0.1;  b = 10;
%       Q = [1 -(a+b)/2 ; -(a+b)/2 a*b];
%   Compute the R-index for Q and H=[G;1]:
%       G = tf([1 2],[1 1]);
%       R = getSectorIndex([G;1],Q)
%   This returns R=0.41<1 so the graph of G(s) fits in the specified sector
%   and would fit in a narrower sector with a base 1/0.41=2.4 times smaller.
%
%   See also getSectorCrossover, getPassiveIndex, getPeakGain, freqresp,
%   nyquist, sectorplot, DynamicSystem.

%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.

% Note: For best results, the rows and columns of Q should be normalized
% using SYMSCALE and H should be scaled accordingly. Note that such scaling
% changes the cone geometry and the index value.
narginchk(2,5)
ni = nargin;

% Validate SYS and Q
[ny,nu] = iosize(sys);
if ny<2 || ny<nu
   error(message('Control:analysis:getSectorIndex1'))
elseif ~isequal(size(Q),[ny ny])
   error(message('Control:analysis:getSectorIndex2',ny))
elseif ~(isnumeric(Q) || isa(Q,'numlti'))
   error(message('Control:analysis:getSectorIndex15'))
end

% Process optional arguments
if ni==5 || (ni>2 && ~isempty(varargin{1}) && ~isscalar(varargin{1}))
   % Compute directional index
   dQ = varargin{1};
   if isa(sys,'FRDModel')
      % Cannot reliably compute directional index from frequency-domain data
      error(message('Control:analysis:getSectorIndex20'))
   end
   ni = ni-1;  varargin = varargin(2:end);
else
   % Compute R-index
   dQ = [];
end
if ni<3 || isempty(varargin{1})
   tol = 1e-2;
else
   tol = varargin{1};
   if ~(isnumeric(tol) && isscalar(tol) && isreal(tol) && tol>0)
      error(message('Control:analysis:getPeakGain1'))
   end
   tol = max(100*eps,double(tol));
end
if ni<4 || isempty(varargin{2})
   fBand = [];
elseif ~isempty(dQ)
   % Not supported for directional index
   error(message('Control:analysis:getSectorIndex18'))
else
   fBand = varargin{2};
   if ~(isnumeric(fBand) && isreal(fBand) && numel(fBand)==2 && 0<=fBand(1) && fBand(1)<fBand(2))
      error(message('Control:analysis:getPeakGain2'))
   end
   fBand = double(fBand);
end


try
   % Decompose Q
   [M0,W1,W2,Z] = ltipack.getSectorData(Q,dQ);
   if isempty(M0)
      % Compute R-index
      if size(W2,2)~=size(sys,2)
         % Equivalence with FDI breaks down
         if isa(sys,'FRDModel')
            error(message('Control:analysis:getSectorIndex19'))
         elseif ~isempty(fBand)
            error(message('Control:analysis:getSectorIndex17'))
         end
      end
      % Absorb spectral factor Z(s) into SYS
      if ~isempty(Z)
         try
            sys = Z * sys;
         catch
            error(message('Control:analysis:getSectorIndex16'))
         end
      end
      [Index,fIndex] = sectorbnd_(sys,[],W1,W2,tol,fBand);
      if isempty(Z)
         Z = 1;
      end
   else
      % Compute index for direction dQ
      [Index,fIndex] = sectorbnd_(sys,M0,[],W2,tol,[]);
   end
catch E
   ltipack.throw(E,'command','getSectorIndex',class(sys))
end
   
   
   


