function obj = pidtuneOptions(varargin)
%PIDTUNEOPTIONS  Define options for the PIDTUNE command.
%  
%   OPT = PIDTUNEOPTIONS returns the default option set for PIDTUNE.
%
%   OPT = PIDTUNEOPTIONS('Option1',Value1,'Option2',Value2,...) uses
%   name/value pairs to override the default values for 'Option1',
%   'Option2',...
% 
%   Supported tuning options include:
%  
%   PhaseMargin - Target phase margin in degrees (default = 60 degrees). 
%       PIDTUNE tries to enforce a phase margin greater or equal to this value.
%       Note that the selected crossover frequency may restrict the achievable 
%       phase margin. Typically, higher phase margin improves stability and 
%       overshoot but limits bandwidth and response speed.
%
%   NumUnstablePoles - Number of unstable poles in the plant G (default = 0). 
%       When G is an FRD model or a state-space model with internal delays, 
%       you must specify the number of open-loop unstable poles if any. 
%       Incorrect values may result in PID controllers that fail to stabilize 
%       the real plant. This option is ignored for all other model types.
%  
%   DesignFocus - A closed-loop performance objective for tuning.
%       PIDTUNE tries to achieve the closed-loop performance objective
%       specified through this option (default = balanced).
%       Acceptable values: reference-tracking, disturbance-rejection, balanced.
%       For more details on this option, refer to the documentation page
%       for pidtuneOptions by typing:
%           doc pidtuneOptions
%
%   Example
%      G = tf(1,[1 3 3 1]);
%      % Design PID with 45 degrees of phase margin
%      Options = pidtuneOptions('PhaseMargin',45);
%      [C info] = pidtune(G,'pid',Options) 
%  
%   See also PIDTUNE.

%   Author(s): Rong Chen
%   Copyright 2009-2011 The MathWorks, Inc.
try
    obj = initOptions(ltioptions.pidtune, varargin);
catch E
    throw(E);
end
