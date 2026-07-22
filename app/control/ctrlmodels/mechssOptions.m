%   Solver options for MECHSS models.
%
%   For MECHSS models SYS, SYS.SolverOptions lets you configure the solvers
%   used to analyze SYS, for example, compute its time or frequency response.
%   Supported options include:
%
%   UseParallel   Parallel computing flag (default = false).
%                 Setting UseParallel=true enables parallel computing where
%                 appropriate. This option requires the Parallel Computing
%                 Toolbox.
%
%   DAESolver     Solver for time response simulation (default = 'TRBDF2').
%                 The options are TRBDF2, HHT, and TRBDF3. All three are
%                 fixed-step DAE solvers with accuracy o(h^2), o(h^2), and 
%                 o(h^3) where h is the step size. Reducing h increases 
%                 accuracy and extends the frequency range where numerical
%                 damping is negligible. HHT is fastest but can run into
%                 difficulties with high initial acceleration (e.g., impulse
%                 response with initial jerk). TRBDF2 requires about twice 
%                 as many computations, and TRBDF3 another 50% more.
%
%   See also MECHSS.

%   Copyright 2020 The MathWorks, Inc.
