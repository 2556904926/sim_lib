function [y,t,varargout] = initial(varargin)
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
%   [Y,T] = INITIAL(SYS,IC) computes the Y from the initial condition IC.
%   IC can be a state value XINIT, a configuration created with RESPCONFIG,
%   or an operating condition obtained with FINDOP. The time vector T is
%   expressed in the time units of SYS and the time range and number of
%   points are chosen automatically. Y is of size [NUMEL(T) NY] where NY is
%   the number of outputs.
%
%   [Y,T] = INITIAL(SYS,IC,TFINAL) simulates the time response from t=0
%   to the final time t=TFINAL (expressed in the time units specified in
%   SYS.TimeUnit). For discrete-time models with unspecified sample time,
%   TFINAL is interpreted as the number of sampling periods.
%
%   [Y,T] = INITIAL(SYS,IC,[T0 TFINAL]) simulates from t=T0 to t=TFINAL. 
%
%   Y = INITIAL(SYS,IC,T) uses the time vector T for simulation (expressed
%   in the time units of SYS). T must be equisampled of the form t0:dt:tF
%   with dt equal to the sample time Ts for discrete-time models.
%
%   Y = INITIAL(SYS,IC,T,P) also specifies the parameter trajectory P 
%   for LPVSS models. This can be
%    1) A matrix where P(i,:) specifies the parameter values at time T(i)
%       (exogenous trajectory)
%    2) A function handle p=F(t,x,u) that gives parameters as a function of
%       time t, state x, and input u (endogenous trajectory). In this case,
%       you must also specify the initial parameter value PINIT using:
%          IC = RespConfig('InitialState',xinit,'InitialParameter',pinit);
%          y = initial(sys,IC,t,p)
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
%   When called without output arguments, INITIAL(SYS,IC,...) plots the
%   initial response of SYS and is equivalent to INITIALPLOT(SYS,IC,...).
%   See INITIALPLOT for additional graphical options.
%
%   See also INITIALPLOT, SS, SPARSS, MECHSS, LTVSS, LPVSS, 
%   DYNAMICSYSTEM/FINDOP, RESPCONFIG, IMPULSE, STEP, LSIM, LTIVIEW, 
%   DYNAMICSYSTEM.

%   Copyright 1986-2022 The MathWorks, Inc.
ni = nargin;
no = nargout;

% Simulate the initial response
if no
   try
      % Call with output arguments. Parse input list
      [sysList,Extras] = DynamicSystem.parseRespFcnInputs(varargin);
      [sysList,tspec,p,Config] = DynamicSystem.checkInitialInputs(sysList,Extras,false);
      sys = sysList(1).System;
      if (numel(sysList)>1 || numsys(sys)~=1)
         error(message('Control:analysis:RequiresSingleModelWithOutputArgs','initial'))
      end
      % Compute response
      varargout = cell(1,no-2+(no>3));  % x,ysd,p
      [y,t,focus,varargout{:}] = timeresp_(sys,'initial',tspec,p,Config);
      % Clip to FOCUS
      [t,y,varargout{:}] = ltipack.util.roundTimeFocus(focus,t,y,varargout{:});
      % Drop YSD
      if no==4
         varargout(:,2) = [];
      end
   catch E
      throw(E)
   end

else
   % Initial response plot
   ArgNames = cell(ni,1);
   for ct=1:ni
      ArgNames(ct) = {inputname(ct)};
   end
   varargin = argname2sysname(varargin,ArgNames);
   try
      initialplot(varargin{:});
   catch E
      throw(E)
   end
end
