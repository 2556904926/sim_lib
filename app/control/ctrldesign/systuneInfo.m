%SYSTUNEINFO  Optimization results from SYSTUNE.
%
%   The SYSTUNE command optionally returns an INFO structure that contains
%   data about each optimization run. This structure has N+1 elements when 
%   using N randomized starts. The fields of INFO are as follows:
%
%   Run            Run number (index).
%
%   Iterations     Total number of iterations performed during this run.
%
%   f              Final objective value.
%                  This is the maximum soft goal value upon termination.
%                  This value is only meaningful when the hard goals are
%                  satisfied.
%
%   g              Final constraint value.
%                  This is the maximum hard goal value upon termination.
%                  The hard goals are satisfied when this value is less
%                  than 1.
%
%   x              Final value of vector of tuned variables.
%                  This vector contains the values of the tuned variables 
%                  upon termination. It includes the tunable variables in 
%                  each block as well as additional variables such as loop
%                  scalings.
%
%   MinDecay       Minimum decay rate (1x2 vector).
%                  MinDecay(1) is the minimum decay rate of the closed-loop
%                  poles and MinDecay(2) is the minimum decay rate of block
%                  dynamics (for tuned blocks with stability constraints, 
%                  see TuningGoal.ControllerPoles). See "MinDecay" option
%                  in systuneOptions help for details.
%
%   fSoft          Individual soft constraint values.
%                  Vector of soft constraint values at the final x, in the 
%                  order they are specified in SYSTUNE.
%
%   gHard          Individual hard constraint values.
%                  Vector of hard constraint values at the final x, in the 
%                  order they are specified in SYSTUNE.
%
%   Blocks         Tuned blocks.
%                  Structure containing the tuned value of each tunable block. 
%                  To apply the tuned values from the k-th run, use
%                     CL = setBlockValue(CL0,Info(k).Blocks)
%
%   LoopScaling    Loop scaling.
%                  When applied to multi-loop control systems, "LoopShape"
%                  and "Margins" requirements can be sensitive to the scaling
%                  of each individual loop transfer. SYSTUNE automatically
%                  corrects scaling issues and returns the optimal diagonal
%                  scaling D in INFO.LoopScaling. The loop channels associated
%                  with the diagonal entries of D are listed in D.InputName.
%                  The scaled loop transfer is D\L*D where L is the open-loop
%                  transfer measured at the locations D.InputName.
%
%   The following fields apply only to robust tuning of control systems with
%   uncertainty:
%
%   wcPert         Worst combinations of uncertain parameters (struct array).
%                  Each struct contains one set of uncertain parameter values.
%                  The perturbations with worse performance are listed first.
%
%   wcf            Worst objective value.
%                  Largest soft goal value over the uncertainty range when
%                  using the tuned controller.
%
%   wcg            Worst constraint value.
%                  Largest hard goal value over the uncertainty range when
%                  using the tuned controller.
%
%   wcDecay        Worst decay rate value.
%                  Smallest closed-loop decay rate over the uncertainty range
%                  when using the tuned controller. A positive value indicates
%                  robust stability. See "MinDecay" option in systuneOptions 
%                  for details.
%
%   See also systune, systuneOptions, TuningGoal.

%   Copyright 1984-2012 The MathWorks, Inc.
