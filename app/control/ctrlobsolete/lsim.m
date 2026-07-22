function  [yout,x] = lsim(a, b, c, d, u, t, x0)
%LSIM  Simulate time response of dynamic systems to arbitrary inputs.
%
%   Y = LSIM(SYS,U,T) computes the response Y of the dynamic system SYS to
%   the input signal described by U and T. The time vector T is expressed
%   in the time units of SYS and consists of regularly spaced time samples.
%   The matrix U has as many columns as inputs in SYS and U(i,:) specifies
%   the input value at time T(i). For example,
%           t = 0:0.01:5;   u = sin(t);   lsim(sys,u,t)
%   simulates the response of a single-input model SYS to the input
%   u(t)=sin(t) during 5 time units.
%
%   For discrete-time models, U should be sampled at the same rate as SYS
%   (T is then redundant and can be omitted or set to the empty matrix).
%   For continuous-time models, choose the sampling period T(2)-T(1) small 
%   enough to accurately describe the input U. LSIM issues a warning when
%   U is undersampled and hidden oscillations may occur.
%         
%   Y = LSIM(SYS,U,T,XINIT) specifies the initial state vector XINIT at  
%   time T(1) (for state-space models only). When omitted, the simulation
%   starts from the all-zero initial condition.
%
%   Y = LSIM(SYS,U,T,XINIT,P) specifies the parameter trajectory P for LPV 
%   models. This can be
%    1) a matrix where P(i,:) specifies the parameter values at time T(i) 
%       (exogenous or explicit trajectory)
%    2) a function handle p=F(t,x,u) that gives parameters as a function of
%       time t, state x, and input u (endogenous or implicit trajectory).
%   The second option is useful to simulate quasi-LPV models.
%
%   Y = LSIM(SYS,...,'zoh') and Y = LSIM(SYS,...,'foh') specify how to 
%   interpolate input values between samples in continuous time ('zoh' is 
%   zero-order hold, 'foh' is linear interpolation). By default, LSIM 
%   automatically selects the interpolation method based on smoothness of
%   the signal U. LSIM always uses 'foh' for sparse and time-varying models.
%
%   [Y,T,X,P] = LSIM(SYS,...) returns additional information for some model
%   types:
%     * State trajectory X for SS models. This is an array of size
%       [NUMEL(T) NX] for a model with NX states.
%     * Parameter trajectory P for LPVSS models. This is an array of size
%       [NUMEL(T) NP] for an LPV model with NP parameters. When p=F(t,x,u), 
%       the output P contains the actual parameter trajectory.
%
%   When called without output arguments, LSIM(SYS,...) plots the response
%   and is equivalent to LSIMPLOT(SYS,...). See LSIMPLOT for additional 
%   graphical options.
%
%   See also LSIMPLOT, GENSIG, STEP, IMPULSE, INITIAL, DYNAMICSYSTEM.

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%LSIM	Simulation of continuous-time linear systems to arbitrary inputs.
%	LSIM(A,B,C,D,U,T) plots the time response of the linear system:
%			.
%			x = Ax + Bu
%			y = Cx + Du
%	to the input time history U. Matrix U must have as many columns as
%	there are inputs, U.  Each row of U corresponds to a new time 
%	point, and U must have LENGTH(T) rows.  The time vector T must be
%	regularly spaced.  LSIM(A,B,C,D,U,T,X0) can be used if initial 
%	conditions exist.
%
%	LSIM(NUM,DEN,U,T) plots the time response of the polynomial 
%	transfer function  G(s) = NUM(s)/DEN(s)  where NUM and DEN contain
%	the polynomial coefficients in descending powers of s.  When 
%	invoked with left hand arguments,
%		[Y,X] = LSIM(A,B,C,D,U,T)
%		[Y,X] = LSIM(NUM,DEN,U,T)
%	returns the output and state time history in the matrices Y and X.
%	No plot is drawn on the screen.  Y has as many columns as there 
%	are outputs, y, and with LENGTH(T) rows.  X has as many columns 
%	as there are states.
%
%	See also: STEP,IMPULSE,INITIAL and DLSIM.

%	LSIM normally linearly interpolates the input (using a first order hold)
%	which is more accurate for continuous inputs. For discrete inputs such 
%	as square waves LSIM tries to detect these and uses a more accurate 
%	zero-order hold method. LSIM can be confused and for accurate results
%	a small time interval should be used.

%	J.N. Little 4-21-85
%	Revised 7-31-90  Clay M. Thompson
%       Revised A.C.W.Grace 8-27-89 (added first order hold)
%	                    1-21-91 (test to see whether to use foh or zoh)
%	Revised 12-5-95 Andy Potvin
%	Revised 5-8-96  P. Gahinet
%	Copyright 1986-2003 The MathWorks, Inc.

ni = nargin;
no = nargout;
narginchk(4,7);

switch ni
case 4
   % Transfer function description 
   if size(a,1)>1,
      % SIMO syntax
      a = num2cell(a,2);
      den = b;
      b = cell(size(a,1),1);
      b(:) = {den};
   end
   sys = tf(a,b);
   u = c;
   t = d;
   x0 = [];
case 5
   error('Wrong number of input arguments.');
case 6
   sys = ss(a,b,c,d);
   x0 = zeros(size(a,1),1);
case 7
   sys = ss(a,b,c,d);
end

if no,
   [yout,t1,x] = lsim(sys,u,t,x0);
else
   lsim(sys,u,t,x0)
end

% end lsim
