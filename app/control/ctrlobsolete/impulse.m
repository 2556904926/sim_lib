function [yout,x,t] = impulse(a,b,c,d,iu,t)
%IMPULSE  Impulse response of dynamic systems.
%
%   IMPULSE computes the response to an impulse change in input value after
%   TD time units:
%      u(t) = U + DU * delta(t-(t0+tD)) .
%   The start time t0, final time tF, impulse delay TD, baseline input U,
%   and amplitude DU are all adjustable with defaults t0=0, U=0, DU=1, TD=0.
%   You can also specify the initial state x(t0). When you don't, the system
%   is assumed to be initially at rest with input level U.
%
%   [Y,T] = IMPULSE(SYS) computes the impulse response Y of the dynamic
%   system SYS. The time vector T is expressed in the time units of SYS and
%   the time step and final time are chosen automatically. For multi-input
%   systems, independent impulses are applied to each input channel. If SYS
%   has NY outputs and NU inputs, Y is an array of size [NUMEL(T) NY NU]
%   where Y(:,:,j) contains the impulse response of the j-th input channel.
%
%   [Y,T] = IMPULSE(SYS,TFINAL) simulates the impulse response from t=0 to
%   the final time t=TFINAL (expressed in the time units of SYS). For
%   discrete-time models with unspecified sample time, TFINAL is interpreted
%   as the number of sampling periods.
%
%   [Y,T] = IMPULSE(SYS,[T0 TFINAL]) simulates from t=T0 to t=TFINAL. The
%   impulse delay TD is relative to T0.
%
%   Y = IMPULSE(SYS,T) specifies the time vector T for simulation (in the
%   time units of SYS). T must be equisampled of the form t0:dt:tF with dt
%   equal to the sample time Ts for discrete-time models.
%
%   Y = IMPULSE(SYS,T,P) also specifies the parameter trajectory P for LPV
%   models. This can be
%    1) A matrix where P(i,:) specifies the parameter values at time T(i)
%       (exogenous or explicit trajectory)
%    2) For discrete-time models, a function handle p=F(t,x,u) that gives 
%       parameters as a function of sample index k, state x, and input u 
%       (endogenous or implicit trajectory).
%
%   [Y,T] = IMPULSE(SYS,...,CONFIG) lets you customize U, DU, TD, and the
%   initial state x(t0). Use RespConfig to create CONFIG. For LTV models
%   with offsets x0(t),u0(t), you can simulate an impulse relative to this
%   baseline trajectory with
%      Config = RespConfig(InitialState='x0',InputOffset='u0',Amplitude=du)
%      y = impulse(sys,t,Config)
%
%   [Y,T,X,YSD,P] = IMPULSE(SYS,...) returns additional information for  
%   some model types:
%     * State trajectory X for state-space models. This is an array of size
%       [NUMEL(T) NX NU] for a model with NX states and NU inputs.
%     * Standard deviation YSD of Y for identified models (see IDMODEL).
%     * Parameter trajectory P for LPV models. This is an array of size
%       [NUMEL(T) NP NU] for an LPV model with NP parameters and NU inputs.
%
%   When called without output arguments, IMPULSE(SYS,...) plots the
%   impulse response of SYS and is equivalent to IMPULSEPLOT(SYS,...). See
%   IMPULSEPLOT for additional graphical options.
%
%   Note: In discrete time, IMPULSE computes the response to a pulse of
%   length Ts and height DU/Ts where Ts is the sample time. This pulse 
%   approaches the continuous-time Dirac impulse DU*delta(t) as Ts goes
%   to zero.
%
%   See also IMPULSEPLOT, RESPCONFIG, STEP, INITIAL, LSIM, LTIVIEW, 
%   DYNAMICSYSTEM, IDMODEL.

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%IMPULSE Impulse response of continuous-time linear systems.
%	 IMPULSE(A,B,C,D,IU)  plots the time response of the linear system
%		.
%		x = Ax + Bu
%		y = Cx + Du
%	to an impulse applied to the inputs IU.  The time vector is
%	automatically determined.  
%
%	IMPULSE(NUM,DEN) plots the impulse response of the polynomial 
%	transfer function  G(s) = NUM(s)/DEN(s)  where NUM and DEN contain
%	the polynomial coefficients in descending powers of s.
%
%	IMPULSE(A,B,C,D,IU,T) or IMPULSE(NUM,DEN,T) uses the user-supplied
%	time vector T which must be regularly spaced.  When invoked with
%	left hand arguments,
%		[Y,X,T] = IMPULSE(A,B,C,D,...)
%		[Y,X,T] = IMPULSE(NUM,DEN,...)
%	returns the output and state time history in the matrices Y and X.
%	No plot is drawn on the screen.  Y has as many columns as there 
%	are outputs and length(T) rows.  X has as many columns as there 
%	are states.
%
%	See also: STEP,INITIAL,LSIM and DIMPULSE.

%	J.N. Little 4-21-85
%	Revised: 8-1-90  Clay M. Thompson, 2-20-92 ACWG, 10-1-94 
%	Revised: A. Potvin 10-1-94, P. Gahinet, 4-24-96
%   Copyright 1986-2015 The MathWorks, Inc.

ni = nargin;
no = nargout;
if ni==0, 
   eval('exresp(''impulse'')')
   return
end
narginchk(2,6)

% Determine which syntax is being used
switch ni
case 2
   if size(a,1)>1,
      % SIMO syntax
      a = num2cell(a,2);
      den = b;
      b = cell(size(a,1),1);
      b(:) = {den};
   end
   sys = tf(a,b);
   t = [];

case 3
   % Transfer function form with time vector
   if size(a,1)>1,
      % SIMO syntax
      a = num2cell(a,2);
      den = b;
      b = cell(size(a,1),1);
      b(:) = {den};
   end
   sys = tf(a,b);
   t = c;

case 4
   % State space system without iu or time vector
   sys = ss(a,b,c,d);
   t = [];

otherwise
   % State space system with iu 
   if min(size(iu))>1,
      error('IU must be a vector.');
   elseif isempty(iu),
      iu = 1:size(d,2);
   end
   sys = ss(a,b(:,iu),c,d(:,iu));
   if ni<6, 
      t = [];
   end
end


if no==1,
   yout = impulse(sys,t);
   yout = yout(:,:);
elseif no>1,
   [yout,t,x] = impulse(sys,t);
   yout = yout(:,:);
   x = x(:,:);
   t = t';
else
   impulse(sys,t)
end

% end impulse
