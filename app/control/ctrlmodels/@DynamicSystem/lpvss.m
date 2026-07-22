function sysOut = lpvss(sys)
%LPVSS  Linear parameter-varying state-space model.
%
%  Construction:
%    VSYS = LPVSS(ParamNames,FCN) creates a continuous-time LPV model of
%    the form
%
%    E(t,p) dx/dt = dx0(t,p) + A(t,p) (x-x0(t,p)) + B(t,p) (u-u0(t,p))
%               y =  y0(t,p) + C(t,p) (x-x0(t,p)) + D(t,p) (u-u0(t,p))
%
%    where
%       * p is a vector of time-dependent exogenous parameters
%       * dx0,x0,u0,y0 are time-dependent offsets.
%    The cell array ParamNames specifies a name for each entry of p. The
%    function FCN specifies how to calculate the matrices and offsets for
%    given (t,p) values. Its syntax must follow the template
%
%       [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(t,p)
%
%    All output arguments except A,B,C,D can be set to [] when absent for
%    all (t,p) values. To specify fixed or varying delays at the inputs
%    or outputs, use a struct "Delay" with fields "Input" and "Output".
%
%    VSYS = LPVSS(ParamNames,FCN,Ts) creates a discrete-time LPV model
%    with sample time Ts. In discrete time, t is replaced by the index k
%    counting the elapsed sampling periods (clock time is k*Ts) and FCN
%    takes k instead ot t as input:
%       [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(k,p).
%
%    VSYS = LPVSS(ParamNames,FCN,Ts,t0,p0) uses FCN(t0,p0) to determine
%    the number of states, inputs, and outputs. By default, LPVSS uses
%    (t0,p0)=(0,0).
%
%    You can set additional model properties by using name/value pairs.
%    For example,
%       vsys = LPVSS(ParamNames,FCN,'InputName','torque',...
%                                  'StateName','position')
%    also sets the input and state names. Type "properties(lpvss)"
%    for a complete list of model properties, and type
%       help lpvss.<PropertyName>
%    for help on a particular property. For example, "help lpvss.StateName"
%    provides information about the "StateName" property.
%
%  Conversion:
%    VSYS = LPVSS(VSYS) converts the model VSYS to LPVSS.
%
%    See also SSINTERPOLANT, PSAMPLE, LTVSS, SS, DYNAMICSYSTEM.

%   Copyright 2022 The MathWorks, Inc.
try
   % Inherit metadata and Variable
   sysOut = copyMetaData(sys,lpvss_(sys));
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:LTV2',class(sys)))
   else
      throw(E)
   end
end
