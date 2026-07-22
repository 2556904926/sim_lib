function wc = getSectorCrossover(sys,Q)
%getSectorCrossover  Crossover frequencies for sector bound.
%
%   For a given linear system H(s), getSectorCrossover computes the 
%   frequencies w for which the matrix
%
%        M(w) = H(-jw)' * Q * H(jw)          (1)
%
%   is singular. These are the frequencies at which the range of H(jw) 
%   intersects the boundary of the conic sector
%
%        C = { y : y' * Q * y < 0 } .
%
%   WC = getSectorCrossover(H,Q) takes a continuous or discrete linear
%   model H and returns the vector WC of frequencies satisfying (1).
%   The symmetric matrix or para-Hermitian LTI model Q specifies the 
%   cone geometry. The frequencies WC are expressed in rad/TimeUnit 
%   relative to the time units of H(s).
%
%   See also getSectorIndex, getGainCrossover, freqresp, sectorplot,
%   DynamicSystem/ctranspose, DynamicSystem.

%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(2,2)
if nmodels(sys)~=1
   error(message('Control:analysis:getSectorCrossover1'))
end

% Validate SYS and Q
[ny,nu] = iosize(sys);
if ny<2 || ny<nu
   error(message('Control:analysis:getSectorIndex1'))
elseif ~isequal(size(Q),[ny ny])
   error(message('Control:analysis:getSectorIndex2',ny))
elseif ~(isnumeric(Q) || isa(Q,'numlti'))
   error(message('Control:analysis:getSectorIndex15'))
end

try
   % Factorize Q = W1*W1'-W2*W2' or Q(s) = Z(s)'*(W1*W1'-W2*W2')*Z(s)
   [~,W1,W2,Z] = ltipack.getSectorData(Q,[]);
   if ~isempty(Z)
      % Absorb spectral factor Z(s) into SYS
      try
         sys = Z * sys;
      catch
         error(message('Control:analysis:getSectorIndex16'))
      end
   end
   % Compute crossover frequencies
   wc = getSectorCrossover_(sys,W1,W2);
catch ME
   ltipack.throw(ME,'command','getSectorCrossover',class(sys))
end