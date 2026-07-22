% Control System Toolbox -- Compensator design and tuning.
%
% PID tuning.
%   pidtune        - Automated tuning of PID controllers.
%   pidTuner       - PID tuning app.
%   
% Classical design.
%   rlocus         - Evans root locus.
%   controlSystemDesigner  - Graphical compensator design app.
%
% State-space design.
%   lqr, dlqr         - Linear-Quadratic (LQ) state-feedback regulator.
%   lqry              - LQ regulator with output weighting.
%   lqrd              - Discrete LQ regulator for continuous plant.
%   lqi               - Linear-Quadratic-Integral (LQI) controller.
%   kalman            - Kalman state estimator.
%   kalmd             - Discrete Kalman estimator for continuous plant.
%   extendedKalmanFilter  - Extended Kalman filter state estimator for discrete nonlinear plants.
%   unscentedKalmanFilter - Unscented Kalman filter state estimator for discrete nonlinear plants.
%   particleFilter        - Particle filter state estimator for discrete nonlinear plants.
%   <a href="matlab:help ss/lqg">lqg</a>            - Single-step LQG design.
%   lqgreg            - Build LQG regulator from LQ gain and Kalman estimator.
%   lqgtrack          - Build LQG servo-controller.
%   estim             - Form estimator given estimator gain.
%   reg               - Form regulator given state-feedback and estimator gains.
%   place             - Pole placement.
%
% Control system tuning.
%   systune        - Tuning of fixed-structure controllers.
%   looptune       - Tuning of MIMO feedback loops.
%   TuningGoal     - Tuning goals for SYSTUNE and LOOPTUNE.
%   realp          - Tunable real parameter.
%   tunablePID     - Tunable 1-DOF PID controller.
%   tunablePID2    - Tunable 2-DOF PID controller.
%   tunableTF      - Tunable SISO transfer function.
%   tunableSS      - Tunable state-space model.
%   tunableGain    - Tunable static gain.
%   genmat         - Matrix with tunable parameters.
%   genss          - State-space model with tunable blocks.
%   showTunable    - Display values of tuned blocks.
%   getBlockValue  - Get current value of tuned block.
%   setBlockValue  - Modify value of tuned block.
%   slTuner        - Simulink interface for SYSTUNE and LOOPTUNE.
%   controlSystemTuner - Control system tuning app.
%
% Gain scheduling.
%   tunableSurface - Create tunable gain surface.
%   polyBasis      - Create polynomial basis for gain surface tuning.
%   fourierBasis   - Create Fourier series expansion for gain surface tuning.
%   ndBasis        - Build N-dimensional basis function expansion.
%   varyingGoal    - Specify variable tuning goal for gain scheduling.
%   getGoal        - Get tuning goal at specific design point.

%   Copyright 1986-2017 The MathWorks, Inc.
