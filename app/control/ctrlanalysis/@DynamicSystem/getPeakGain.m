function [gpeak,fpeak] = getPeakGain(sys,tol,fBand)
%GETPEAKGAIN  Compute peak gain of frequency response.
%
%   GPEAK = getPeakGain(SYS) returns the peak input/output gain of the 
%   dynamic system SYS. For SISO systems, GPEAK is the largest value of
%   the frequency response magnitude across frequency. For MIMO systems, 
%   GPEAK is the largest value of the frequency response 2-norm (largest
%   singular value) across frequency. GPEAK is also called the L-infinity
%   norm of SYS and coincides with the H-infinity norm for stable systems.
%
%   GPEAK = getPeakGain(SYS,TOL) specifies the relative accuracy TOL for 
%   the computed value GPEAK. By default GPEAK is computed with 1% accuracy
%   (TOL=1e-2).
%
%   GPEAK = getPeakGain(SYS,TOL,FBAND) computes the peak gain inside the  
%   frequency interval FBAND=[f1,f2] with 0<=f1<f2. This takes into account
%   both positive and negative frequencies in this frequency band.
%
%   [GPEAK,FPEAK] = getPeakGain(SYS,...) also returns the frequency FPEAK
%   (in rad/TimeUnit) at which the gain achieves the peak value GPEAK.
%   FPEAK can be negative for systems with complex data.
% 
%   If SYS is an array of dynamic systems, getPeakGain returns an array 
%   of the same size where GPEAK(k) = getPeakGain(SYS(:,:,k)).
%
%   See also hinfnorm, freqresp, bode, sigma, getGainCrossover, 
%   getSectorBound, DynamicSystem.

%   Copyright 1986-2011 The MathWorks, Inc.
narginchk(1,3)
ni = nargin;

% Validate optional arguments
if ni<2 || isempty(tol)
   tol = 1e-2;
else
   if ~(isnumeric(tol) && isscalar(tol) && isreal(tol) && tol>0)
      error(message('Control:analysis:getPeakGain1'))
   end
   tol = max(100*eps,double(tol));
end
if ni<3 || isempty(fBand)
   fBand = [];
else
   if ~(isnumeric(fBand) && isreal(fBand) && numel(fBand)==2 && 0<=fBand(1) && fBand(1)<fBand(2))
      error(message('Control:analysis:getPeakGain2'))
   end
   fBand = double(fBand);
end

% Compute peak gain
try
   [gpeak,fpeak] = norminf_(sys,tol,fBand,false);
catch E
   ltipack.throw(E,'command','getPeakGain',class(sys))
end
