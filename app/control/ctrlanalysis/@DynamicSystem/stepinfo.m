function [s,extra] = stepinfo(sys,varargin)
%STEPINFO  Computes step response characteristics.
%
%   S = STEPINFO(Y,T,YFINAL,YINIT) takes the step response data (T,Y), an
%   initial value YINIT, and a steady-state value YFINAL, and returns a
%   structure S containing the following performance indicators:
%     * RiseTime: rise time
%     * TransientTime: transient time
%     * SettlingTime: settling time
%     * SettlingMin: min value of Y once the response has risen
%     * SettlingMax: max value of Y once the response has risen
%     * Overshoot: percentage overshoot (relative to YFINAL)
%     * Undershoot: percentage undershoot
%     * Peak: peak value of deviation |Y-YINIT|
%     * PeakTime: time at which this peak value is reached.
%
%   For SISO responses, T and Y are vectors with the same length NS.
%   For systems with NU inputs and NY outputs, you can specify Y as
%   an NS-by-NY-by-NU array (see STEP) and YFINAL and YINIT as
%   NY-by-NU arrays. STEPINFO then returns a NY-by-NU structure array S
%   of performance metrics for each I/O pair.
%
%   When omitted, T defaults to 1:NS, YFINAL defaults to the last sample
%   value of Y, and YINIT defaults to zero. Set YINIT to a nonzero value
%   when the Y data has an initial offset (Y is nonzero prior to the step).
%
%   S = STEPINFO(SYS) computes the step response characteristics for
%   the dynamic system SYS. The rise time, settling time, and peak time
%   are all expressed in the time units of SYS (see "TimeUnit" property).
%
%   S = STEPINFO(SYS,YFINAL) explicitly specifies the steady-state value 
%   YFINAL.
%
%   S = STEPINFO(...,'SettlingTimeThreshold',ST) lets you specify the
%   threshold ST used in the settling time calculation.  The response
%   has settled when the error |y(t) - YFINAL| becomes smaller than a
%   fraction ST of |YINIT - YFINAL|. The default value is ST=0.02 (2%).
%
%   S = STEPINFO(...,'RiseTimeLimits',RT) lets you specify the lower
%   and upper thresholds used in the rise time calculation.  By default,
%   the rise time is the time the response takes to rise from 10% to 90%
%   of the steady-state value (RT=[0.1 0.9]).  Note that RT(2) is also
%   used to calculate SettlingMin and SettlingMax.
%
%   Example:
%      sys = rss(5);
%      s = stepinfo(sys,'RiseTimeLimits',[0.05,0.95])
%
%   See also STEP, LSIMINFO, DYNAMICSYSTEM.

%   Author(s): P. Gahinet
%   Copyright 1986-2021 The MathWorks, Inc.
if nmodels(sys)~=1
   error(message('Control:general:RequiresSingleModel','stepinfo'))
elseif issparse(sys)
   error(message('Control:analysis:stepinfo1'))
end
% Simulate response
try
   [y,t] = timeresp_(sys,'step',[],[],RespConfig());
catch E
   throw(E);
end
% Steady-state value
ns = length(t);
if nargin>1 && isnumeric(varargin{1})
   yf = varargin{1};
   varargin = varargin(2:end);
else
   % Use last sample value (set to final value by *RESP simulators)
   yf = permute(y(ns,:,:),[2 3 1]);
   if ~allfinite(yf)
      % Simulation has not reached steady state or system is unstable
      warning(message('Control:analysis:stepinfo2'))
   end
end
% Compute characteristics (remove last "final value" sample)
% Pass sample time to prevent interpolation in discrete time
[s,extra] = stepinfo(y(1:ns-1,:,:),t(1:ns-1),yf,0,'Ts',abs(sys.Ts),varargin{:});
