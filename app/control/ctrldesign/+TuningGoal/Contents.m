% Goals for control system tuning.
%
% Use the following classes to specify design requirements when tuning
% a control system with SYSTUNE or LOOPTUNE.
%
% General.
%   evalGoal          - Evaluate goal for particular design.
%   viewGoal          - Graphically validate design against tuning goals.
%
% Time-domain goals.
%   StepTracking      - Tracking of step commands.
%   StepRejection     - Rejection of step disturbances.
%   Transient         - Transient response matching.
%   LQG               - Linear-quadratic-Gaussian objective.
%
% Frequency-domain goals.
%   Gain              - Maximum gain (H-infinity norm).
%   Variance          - Maximum amplification of signal variance (H-2 norm).
%   Tracking          - Reference tracking.
%   Overshoot         - Maximum overshoot.
%   Rejection         - Disturbance rejection.
%   Sensitivity       - Sensitivity of SISO or MIMO loops.
%   WeightedGain      - Maximum frequency-weighted gain.
%   WeightedVariance  - Maximum frequency-weighted variance amplification.
%
% Loop shapes and stability margins.
%   MinLoopGain       - Minimum gain for open-loop response.
%   MaxLoopGain       - Maximum gain for open-loop response.
%   LoopShape         - Target shape for open-loop response.
%   Margins           - Minimum stability margins for SISO or MIMO loops.
%
% Passivity and sector bounds
%   Passivity         - Passivity of open- or closed-loop response.
%   WeightedPassivity - Passivity of frequency-weighted response.
%   ConicSector       - Sector bounds on frequency response.
%
% System dynamics.
%   Poles             - Constraint on closed-loop dynamics.
%   ControllerPoles   - Constraint on controller dynamics.
%
% Goals for gain scheduling.
%   varyingGoal       - Specify goal that varies with design point.
%   getGoal           - Get goal at specific design point.
%
% Type "help TuningGoal.<goal type>" for more information on each tuning
% goal.
%
% See also systune, looptune.

%   Copyright 1990-2015 The MathWorks, Inc.

