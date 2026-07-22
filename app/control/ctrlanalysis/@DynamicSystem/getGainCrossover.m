function wc = getGainCrossover(sys,g)
%GETGAINCROSSOVER  Crossover frequencies for specific gain level.
%
%   WC = getGainCrossover(SYS,G) returns the vector WC of frequencies where
%   the frequency response of the dynamic system SYS has gain G. For MIMO 
%   systems, "gain" refers to the principal gain (largest singular value of 
%   the transfer matrix). The gain G is specified in absolute value and the
%   frequencies WC are expressed in rad/TimeUnit relative to the time units 
%   of SYS.
%
%   See also freqresp, bode, sigma, bandwidth, getPeakGain, DynamicSystem.

%   Copyright 1986-2011 The MathWorks, Inc.
narginchk(2,2)
if nmodels(sys)~=1
   error(message('Control:analysis:getGainCrossover1'))
elseif ~(isnumeric(g) && isscalar(g) && isreal(g) && g>0)
   error(message('Control:analysis:getGainCrossover2'))
end
try
   wc = getGainCrossover_(sys,g);
catch ME
   ltipack.throw(ME,'command','getGainCrossover',class(sys))
end