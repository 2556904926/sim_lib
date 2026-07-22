function obj = systuneOptions(varargin)
%SYSTUNEOPTIONS  Creates option set for the SYSTUNE command.
%
%   OPT = SYSTUNEOPTIONS returns the default options for the SYSTUNE command.
%
%   OPT = SYSTUNEOPTIONS('Option1',Value1,'Option2',Value2,...) uses
%   name/value pairs to override the default values for 'Option1','Option2',...
%
%   Supported options include:
%
%   Display      Display level [{'final'} | 'sub' | 'iter' | 'off'].
%                Set Display='final' to print a one-line summary at the
%                end of each optimization run (default). Set Display='sub'
%                to show the result of each subproblem. Set Display='iter'
%                to show the optimization progress after each iteration.
%                Set Display='off' to run SYSTUNE in silent mode.
%
%   MaxIter      Maximum number of iterations (default = 300).
%
%   RandomStart  Number of randomized starts (default = 0).
%                Setting RandomStart=0 runs a single optimization starting
%                from the initial values of the tunable blocks. Setting
%                RandomStart=N>0 runs N additional optimizations starting
%                from N randomly generated values of the block parameters.
%                Running a few random starts helps mitigate the risk of
%                premature termination due to local minima.
%
%   UseParallel  Parallel processing flag (default = false).
%                Setting UseParallel=true enables parallel processing by
%                distributing the randomized starts among MATLAB workers
%                and running the optimizations concurrently. This option
%                requires the Parallel Computing Toolbox.
%
%   SkipModels   Models or design points to ignore (default = empty).
%                Use this option to skip specific models or ignore portions
%                of the design space (for example, grid points outside the
%                flight envelope or operating range). Each skipped model is
%                identified by its absolute index in the tuned model array.
%                This is an easy way to narrow the scope of tuning without
%                having to reconfigure each tuning goal.
%
%   SoftTarget   Target value for soft constraints (default = 0).
%                The optimization stops when the maximum value of the soft
%                constraints falls below the specified SoftTarget value.
%                Set SoftTarget=0 to minimize the soft constraints subject
%                to satisfying the hard constraints.
%
%   SoftTol      Relative tolerance for termination (default = 1e-3).
%                The optimization stops when the relative decrease in soft
%                constraint value over the last 10 iterations falls below
%                SoftTol. Increasing SoftTol speeds up termination,
%                decreasing it yields tighter final values.
%
%   SoftScale    Estimate of best soft constraint value (default = 1).
%                For problems mixing soft and hard constraints, a rough
%                estimate of the optimal value of the soft constraints
%                subject to the hard constraints helps speed up the 
%                optimization. Ignored for problems with all hard or all
%                soft constraints.
%
%   MinDecay     Minimum decay rate for stabilized dynamics (default = 1e-7).
%                Constrains all stabilized poles and zeros to satisfy:
%                     Re(s)  < -MinDecay    (continuous time)
%                   log(|z|) < -MinDecay    (discrete time).
%                Most tuning goals carry an implicit closed-loop stability
%                or minimum-phase constraint. "Stabilized dynamics" refers
%                to the poles and zeros affected by these constraints.
%                Adjust the default value if it cannot be met or conflicts
%                with other requirements. Alternatively, use TuningGoal.Poles
%                to control the decay rate of a specific feedback loop.
%
%   MaxRadius    Maximum spectral radius for stabilized dynamics (default=1e8).
%                Constrains all stabilized poles and zeros to satisfy:
%                    |s| < MaxRadius.
%                This is useful to prevent poles and zeros from going to 
%                infinity as a result of algebraic loops becoming singular or  
%                control effort growing unbounded. Adjust the default value
%                if it cannot be met or conflicts with other requirements. 
%                Ignored in discrete time tuning where stability constraints
%                already impose |z| < 1.
%
%   Example: Tune the controller parameters to drive the soft constraints
%   below 1, using three randomized starts and a maximum of 200 iterations
%   per run:
%      opt = systuneOptions('SoftTarget',1,'RandomStart',3,'MaxIter',200)
%      T = systune(T0,Soft,Hard,opt)
%
%   See also systune, TuningGoal.

%   Author(s): P.Gahinet
%   Copyright 1984-2014 The MathWorks, Inc.
try
   obj = initOptions(rctoptions.systune,varargin);
catch E
   throw(E)
end
