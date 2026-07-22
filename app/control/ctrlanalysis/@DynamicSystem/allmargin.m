function s = allmargin(L,optArgs)
%ALLMARGIN  All stability margins and crossover frequencies.
%
%   S = ALLMARGIN(L) computes the gain, phase, and delay margins and the 
%   corresponding crossover frequencies for the negative feedback loop
%
%         u --->O---->[ L ]----+---> y
%             - |              |
%               +<-------------+
%
%   When L is SISO, S is a structure with the following fields:
%     * GMFrequency: all -180 deg crossover frequencies in rad/TimeUnit
%       (relative to the time units specified in L.TimeUnit, the default
%       being seconds)
%     * GainMargin: corresponding gain margins (g.m. = 1/G where G is the
%       gain at crossover)
%     * PMFrequency: all 0 dB crossover frequencies (in rad/TimeUnit)
%     * PhaseMargin: corresponding  phase margins (in degrees)
%     * DelayMargin, DMFrequency: delay margins (in the units specified
%       in L.TimeUnit for continuous-time systems, and in multiples of
%       the sample time for discrete-time systems) and corresponding
%       critical frequencies
%     * Stable: 1 if nominal closed loop is stable, 0 if unstable, and NaN
%       if stability cannot be assessed (as in the case for FRD models)
%
%   When L is an N-by-N MIMO transfer function, S is N-by-1 and S(j) gives  
%   the stability margins for the j-th feedback channel with all other
%   loops closed (one-loop-at-a-time margins).
%
%   S = ALLMARGIN(L,Focus=[FMIN,FMAX]) only looks at margins in the 
%   frequency range [FMIN,FMAX] and ignores stability issues outside this 
%   range, for example, low-frequency instabilities.
%
%   S = ALLMARGIN(MAG,PHASE,W,TS) computes the stability margins from the
%   frequency response data W, MAG, PHASE and the sample time TS. ALLMARGIN
%   expects gain values MAG in absolute units and phase values PHASE in
%   degrees. Interpolation is used between frequency points to approximate
%   the true stability margins.
%
%   See also MARGIN, DISKMARGIN, BODE, NYQUIST, NICHOLS, LTIVIEW, DYNAMICSYSTEM.

%   Copyright 1986-2023 The MathWorks, Inc.
arguments
   L
   optArgs.?ltioptions.margin;
end

[ny,nu] = iosize(L);
if ny~=nu || ny==0
   error(message('Control:analysis:allmargin1'))
end

% Options
try
   opt = initOptions(ltioptions.margin,namedargs2cell(optArgs));
catch ME
   throw(ME)
end
if opt.Focus(1)>=pi/abs(getTs_(L))
   error(message('Control:analysis:allmargin3'))
end

% Compute margins and related frequencies
try
   if ny>1 && ~isa(L,'FRDModel')
      % Convert to state space to facilitate loop closures and handle delays
      L = ss(L);
   end
   s = allmargin_(L,opt);
catch E
   ltipack.throw(E,'command','allmargin',class(L))
end

