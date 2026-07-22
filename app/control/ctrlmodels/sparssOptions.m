%   Solver options for SPARSS models.
%
%   For SPARSS models SYS, SYS.SolverOptions lets you configure the solvers
%   used to analyze SYS, for example, compute its time or frequency response.
%   Supported options include:
%
%   UseParallel   Parallel computing flag (default = false).
%                 Setting UseParallel=true enables parallel computing where
%                 appropriate. This option requires the Parallel Computing
%                 Toolbox.
%
%   DAESolver     Solver for time response simulation (default = 'TRBDF2').
%                 The options are TRBDF2 and TRBDF3. Both are fixed-step
%                 DAE solvers with accuracy o(h^2) and o(h^3) where h is
%                 the step size. Reducing h increases accuracy and extends
%                 the frequency range where numerical damping is negligible.
%                 TRBDF3 requires about 50% more computation than TRBDF2.
%
%   See also SPARSS.

%   Copyright 2020 The MathWorks, Inc.
