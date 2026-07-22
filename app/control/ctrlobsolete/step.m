function [yout,x,t] = step(a,b,c,d,iu,t)
%STEP  Step response of dynamic systems.
%
%   STEP computes the response to a step change in input value from U to
%   U+DU after TD time units. The start time t0, final time tF, step
%   delay TD, baseline input U, and step amplitude DU are all adjustable
%   with defaults t0=0, U=0, DU=1, TD=0. You can also specify the initial
%   state x(t0). When you don't, the system is assumed to be initially at
%   rest with input level U.
%
%   [Y,T] = STEP(SYS) computes the step response Y of the dynamic system SYS.
%   The time vector T is expressed in the time units of SYS and the time
%   step and final time are chosen automatically. For multi-input systems,
%   independent step commands are applied to each input channel. If SYS has
%   NY outputs and NU inputs, Y is an array of size [NUMEL(T) NY NU] where
%   Y(:,:,j) contains the step response of the j-th input channel.
%
%   [Y,T] = STEP(SYS,TFINAL) simulates the step response from t=0 to the
%   final time t=TFINAL (expressed in the time units of SYS). For discrete-
%   time models with unspecified sample time, TFINAL is interpreted as
%   the number of sampling periods.
%
%   [Y,T] = STEP(SYS,[T0 TFINAL]) simulates from t=T0 to t=TFINAL. The
%   step delay TD is relative to T0.
%
%   Y = STEP(SYS,T) specifies the time vector T for simulation (in the time
%   units of SYS). T must be equisampled of the form t0:dt:tF with dt equal
%   to the sample time Ts for discrete-time models.
%
%   Y = STEP(SYS,T,P) also specifies the parameter trajectory P for LPV
%   models. This can be
%    1) a matrix where P(i,:) specifies the parameter values at time T(i)
%       (exogenous or explicit trajectory)
%    2) a function handle p=F(t,x,u) that gives parameters as a function of
%       time t, state x, and input u (endogenous or implicit trajectory).
%   The second option is useful to simulate quasi-LPV models.
%
%   [Y,T] = STEP(SYS,...,CONFIG) lets you customize U, DU, TD, and the
%   initial state x(t0). Use RespConfig to create CONFIG. For LTV models
%   with offsets x0(t),u0(t), you can simulate a step change relative to
%   this baseline trajectory with
%      Config = RespConfig(InitialState='x0',InputOffset='u0',Amplitude=du)
%      y = step(sys,t,Config)
%
%   [Y,T,X,YSD,P] = STEP(SYS,...) returns additional information for some 
%   model types:
%     * State trajectory X for state-space models. This is an array of size
%       [NUMEL(T) NX NU] for a model with NX states and NU inputs.
%     * Standard deviation YSD of Y for identified models (see IDMODEL).
%     * Parameter trajectory P for LPV models. This is an array of size
%       [NUMEL(T) NP NU] for an LPV model with NP parameters and NU inputs.
%
%   When called without output arguments, STEP(SYS,...) plots the step
%   response of SYS and is equivalent to STEPPLOT(SYS,...). See STEPPLOT
%   for additional graphical options.
%
%   See also STEPPLOT, RESPCONFIG, STEPINFO, IMPULSE, INITIAL, LSIM, LTIVIEW,
%   DYNAMICSYSTEM, IDMODEL.

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%STEP   Step response of continuous-time linear systems.
%	STEP(A,B,C,D,IU)  plots the time response of the linear system:
%		.
%		x = Ax + Bu
%		y = Cx + Du
%	to a step applied to the input IU.  The time vector is auto-
%	matically determined.  STEP(A,B,C,D,IU,T) allows the specification
%	of a regularly spaced time vector T.
%
%	[Y,X] = STEP(A,B,C,D,IU,T) or [Y,X,T] = STEP(A,B,C,D,IU) returns
%	the output and state time response in the matrices Y and X 
%	respectively.  No plot is drawn on the screen.  The matrix Y has 
%	as many columns as there are outputs, and LENGTH(T) rows.  The 
%	matrix X has as many columns as there are states.  If the time 
%	vector is not specified, then the automatically determined time 
%	vector is returned in T.
%
%	[Y,X] = STEP(NUM,DEN,T) or [Y,X,T] = STEP(NUM,DEN) calculates the 
%	step response from the transfer function description 
%	G(s) = NUM(s)/DEN(s) where NUM and DEN contain the polynomial 
%	coefficients in descending powers of s.
%
%	See also: INITIAL, IMPULSE, LSIM and DSTEP.

%	J.N. Little 4-21-85
%	Revised A.C.W.Grace 9-7-89, 5-21-92
%	Revised A. Potvin 12-1-95
%   Copyright 1986-2015 The MathWorks, Inc.

ni = nargin;
no = nargout;
if ni==0,
   eval('exresp(''step'')')
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
   yout = step(sys,t);
   yout = yout(:,:);
elseif no>1,
   [yout,t,x] = step(sys,t);
   yout = yout(:,:);
   x = x(:,:);
   t = t';
else
   step(sys,t);
end

% end step
