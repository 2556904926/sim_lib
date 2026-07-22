function [yout,x,t] = initial(a,b,c,d,x0,t)
%INITIAL  Initial condition response of state-space models.
%
%   For SS or SPARSS models, INITIAL computes the unforced response y from
%   the initial state XINIT:
%
%     Continuous time:  dx/dt = A x,  y = C x,  x(t0) = XINIT
%
%     Discrete time:  x[k+1] = A x[k],  y[k] = C x[k],  x[k0] = XINIT.
%
%   For LTVSS or LPVSS models, INITIAL computes the response with initial
%   state XINIT, initial parameter PINIT (when required), and input held to
%   its offset value (u(t)=u0(t) or u(t)=u0(t,p)). This corresponds to the
%   initial condition response of the local linear dynamics.
%
%   [Y,T] = INITIAL(SYS,XINIT) computes the Y from the initial state XINIT.
%   The time vector T is expressed in the time units of SYS and the time
%   range and number of points are chosen automatically. Y is of size
%   [NUMEL(T) NY] where NY is the number of outputs.
%
%   [Y,T] = INITIAL(SYS,XINIT,TFINAL) simulates the time response from t=0
%   to the final time t=TFINAL (expressed in the time units specified in
%   SYS.TimeUnit). For discrete-time models with unspecified sample time,
%   TFINAL is interpreted as the number of sampling periods.
%
%   [Y,T] = INITIAL(SYS,XINIT,[T0 TFINAL]) simulates from t=T0 to t=TFINAL. 
%
%   Y = INITIAL(SYS,XINIT,T) uses the time vector T for simulation (expressed
%   in the time units of SYS). T must be equisampled of the form t0:dt:tF
%   with dt equal to the sample time Ts for discrete-time models.
%
%   Y = INITIAL(SYS,XINIT,T,P) or Y = INITIAL(SYS,{XINIT,PINIT},T,P) also
%   specifies the parameter trajectory P for LPVSS models. This can be
%    1) A matrix where P(i,:) specifies the parameter values at time T(i)
%       (exogenous trajectory)
%    2) A function handle p=F(t,x,u) that gives parameters as a function of
%       time t, state x, and input u (endogenous trajectory). The initial
%       parameter value PINIT is required in this case.
%   This returns an array P of size [NUMEL(T) NP] containing the parameter
%   trajectories.
%
%   [Y,T,X,P] = INITIAL(SYS,...) returns additional information for some
%   model types:
%     * State trajectory X for SS models. This is an array of size
%       [NUMEL(T) NX] for a model with NX states.
%     * Parameter trajectory P for LPVSS models. This is an array of size
%       [NUMEL(T) NP] for an LPV model with NP parameters.
%
%   When called without output arguments, INITIAL(SYS,XINIT,...) plots the
%   initial response of SYS and is equivalent to INITIALPLOT(SYS,XINIT,...).
%   See INITIALPLOT for additional graphical options.
%
%   See also INITIALPLOT, SS, SPARSS, MECHSS, LTVSS, LPVSS, IMPULSE,
%   STEP, LSIM, LTIVIEW, DYNAMICSYSTEM.

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%INITIAL Initial condition response of continuous-time linear systems.
%   INITIAL(A,B,C,D,X0) plots the time response of the linear system
%       .
%       x = Ax + Bu
%       y = Cx + Du
%
%   due to an initial condition on the states.  The time vector is 
%   automatically determined based on the system poles and zeros.  
%
%   INITIAL(A,B,C,D,X0,T) plots the initial condition response for the
%   times specified in the vector T.  The time vector must be 
%   regularly spaced.  When invoked with left hand arguments:
%   
%       [Y,X,T] = INITIAL(A,B,C,D,X0,...)
%
%   returns the output and state responses (Y and X), and the time 
%   vector (T).  No plot is drawn on the screen.  The matrix Y has as
%   many columns as outputs and one row for element in T.  Similarly,
%   the matrix X has as many columns as states and length(T) rows.
%   
%   See also: IMPULSE,STEP,LSIM, and DINITIAL.

%	Clay M. Thompson  7-6-90
%	Revised ACWG 6-21-92
%	Revised AFP 9-21-94,  PG 4-25-96
%   Copyright 1986-2011 The MathWorks, Inc.

ni = nargin;
no = nargout;
narginchk(5,6)

% Determine which syntax is being used
error(abcdchk(a,b,c,d))
sys = ss(a,b,c,d);
if ni==5,
   t = [];
end

if no,
   [yout,t,x] = initial(sys,x0,t);
   t = t';
else
   initial(sys,x0,t);
end

% end initial
