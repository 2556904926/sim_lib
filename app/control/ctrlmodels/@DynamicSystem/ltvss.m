function sysOut = ltvss(sys)
%LTVSS  Linear time-varying state-space model.
%
%  Construction:
%    VSYS = LTVSS(FCN) creates a continuous-time LTV model of the form
%
%       E(t) dx/dt = dx0(t) + A(t) (x(t)-x0(t)) + B(t) (u(t)-u0(t))
%             y(t) = y0(t)  + C(t) (x(t)-x0(t)) + D(t) (u(t)-u0(t))
%
%    where dx0,x0,u0,y0 are time-dependent offsets. The function FCN
%    specifies how to calculate the matrices and offsets at any given
%    time t. Its syntax must follow the template
%
%       [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(t) .
%
%    All output arguments except A,B,C,D can be set to [] when absent
%    for all times t. To specify fixed or varying delays at the inputs
%    or outputs, use a struct "Delay" with fields "Input" and "Output".
%
%    VSYS = LTVSS(FCN,Ts) creates a discrete-time LTV model with sample
%    time Ts. In discrete time, t is replaced by the index k counting
%    the elapsed sampling periods (clock time is k*Ts) and FCN takes k
%    instead ot t as input: [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(k).
%
%    VSYS = LTVSS(FCN,Ts,t0) uses FCN(t0) to determine the number of
%    states, inputs, and outputs. By default, LTVSS uses t0=0.
%
%    You can set additional model properties by using name/value pairs.
%    For example,
%       vsys = LTVSS(FCN,'InputName','torque','StateName','position')
%    also sets the input and state names. Type "properties(ltvss)"
%    for a complete list of model properties, and type
%       help ltvss.<PropertyName>
%    for help on a particular property. For example, "help ltvss.StateName"
%    provides information about the "StateName" property.
%
%  Conversion:
%    VSYS = LTVSS(VSYS) converts the model VSYS to LTVSS.
%
%    See also SSINTERPOLANT, PSAMPLE, LPVSS, SS, DYNAMICSYSTEM.

%   Copyright 2022-2024 The MathWorks, Inc.
try
   % Inherit metadata and Variable
   sysOut = copyMetaData(sys,ltvss_(sys));
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:LTV2',class(sys)))
   else
      throw(E)
   end
end
