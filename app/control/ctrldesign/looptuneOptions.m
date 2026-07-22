function obj = looptuneOptions(varargin)
%LOOPTUNEOPTIONS  Creates option set for the LOOPTUNE command.
%
%   OPT = LOOPTUNEOPTIONS returns the default options for the LOOPTUNE command.
%
%   OPT = LOOPTUNEOPTIONS('Option1',Value1,'Option2',Value2,...) uses name/value
%   pairs to override the default values for 'Option1','Option2',...
%
%   Supported options include:
%
%   Display        Display level [{'final'} | 'iter' | 'off'].
%                  Set Display='final' to print a one-line summary at the
%                  end of each optimization run (default). Set Display='iter'
%                  to show the optimization progress after each iteration.
%                  Set Display='off' to run LOOPTUNE in silent mode.
%
%   GainMargin     Target gain margin (in dB, default = 7.6).
%                  Specifies the required gain margin for the feedback loop.
%                  See DISKMARGIN for details on the notion of MIMO gain margin.
%
%   PhaseMargin    Target phase margin (in degrees, default = 45).
%                  Specifies the required phase margin for the feedback loop.
%                  See DISKMARGIN for details on the notion of MIMO phase margin.
%
%   MaxIter        Maximum number of iterations (default = 300).
%
%   RandomStart    Number of randomized starts (default = 0).
%                  Setting RandomStart=0 runs a single optimization starting
%                  from the initial values of the tunable blocks. Setting
%                  RandomStart=N>0 runs N additional optimizations starting
%                  from N randomly generated values of the block parameters.
%                  Running a few random starts helps mitigate the risk of
%                  premature termination due to local minima.
%
%   UseParallel    Parallel processing flag (default = false).
%                  Setting UseParallel=true enables parallel processing by
%                  distributing the randomized starts among MATLAB workers and 
%                  running the optimizations concurrently. This option requires 
%                  the Parallel Computing Toolbox.
%
%   TargetGain     Target objective value (default = 1).
%                  LOOPTUNE turns design requirements into normalized gain
%                  constraints and tries to drive the overall gain below 1 to
%                  enforce all requirements. The default TargetGain=1 ensures
%                  that the optimization stops as soon as the gain value falls 
%                  below 1. Set TargetGain to a smaller/larger value to continue 
%                  the optimization or stop earlier.
%
%   TolGain        Relative tolerance for termination (default = 1e-3).
%                  The optimization stops when the objective decreases by less 
%                  than this relative amount over 10 consecutive iterations. 
%                  Increasing TolGain speeds up termination, decreasing TolGain 
%                  yields tighter final values.
%
%   MinDecay       Minimum decay rate for closed-loop poles (default = 1e-7).
%                  Constrains all closed-loop poles to satisfy:
%                       Re(s)  < -MinDecay    (continuous time)
%                     log(|z|) < -MinDecay    (discrete time).
%                  Increase this value to push the closed-loop poles farther 
%                  into the stable region.
%
%   MaxFrequency   Maximum natural frequency of closed-loop poles (default=Inf).
%                  Constrains the closed-loop poles to satisfy: 
%                          |s|    < MaxFrequency    (continuous time)
%                     |log(z)/Ts| < MaxFrequency    (discrete time).
%                  Use this option to prevent fast dynamics and high-gain 
%                  control.
%
%   Example: Use three randomized starts, set the target gain and phase margins
%   to 6 dB and 50 degrees, and limit the closed-loop pole magnitude to 100:
%      opt = looptuneOptions('GainMargin',6,'PhaseMargin',50,...
%                            'RandomStart',3,'MaxFrequency',100);
%      C = looptune(G,C0,opt)
%
%   See also LOOPTUNE, DISKMARGIN, HINFSTRUCTOPTIONS.

%   Author(s): P.Gahinet
%   Copyright 1984-2012 The MathWorks, Inc.
try
   obj = initOptions(rctoptions.looptune,varargin);
catch E
   throw(E)
end
