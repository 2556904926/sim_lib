function sysOut = pidstd2(varargin)
%PIDSTD2  Create a 2-DOF PID controller in standard form.
%
%  Construction:
%    SYS = PIDSTD2(Kp,Ti,Td,N,b,c) creates a continuous-time 2-DOF PID controller
%    in standard form with a first order derivative filter:
%
%                              1                 Td*s
%           Kp * ( (b*r-y) + ------ * (r-y) + ------------ * (c*r-y) )
%                             Ti*s             (Td/N)*s+1
%
%    u is controller output, r is reference input and y is plant output.
%
%    When Kp, Ti, Td, N, b, and c are scalar, the output SYS is a PIDSTD2
%    object that represents a two-input-one-output PID controller. The
%    following rules apply to construct a valid PID2 controller in standard
%    form:
%
%       Kp (proportional gain) must be real and finite
%       Ti (integral time) must be real and positive
%       Td (derivative time) must be real, finite and non-negative
%       N (filter divisor) must be real and positive
%       b (setpoint weight for proportional term) must be real and positive
%       c (setpoint weight for derivative term) must be real and positive
%
%    The default values are Kp=1, Ti=Inf, Td=0, N=Inf, b=1, and c=1. If a
%    parameter is omitted, its default value is used.  For example:
%
%       PIDSTD2(Kp) returns a proportional only controller
%       PIDSTD2(Kp,Ti) returns a PI2 controller
%       PIDSTD2(Kp,Ti,Td) returns a PID2 controller
%       PIDSTD2(Kp,Ti,Td,N) returns a PID2 controller with derivative filter
%
%    SYS = PIDSTD2(Kp,Ti,Td,N,b,c,Ts) creates a discrete-time 2-DOF PID
%    controller with sample time Ts (a positive real value). A discrete
%    time PID controller is obtained by discretizing the integrators
%    with numerical integration methods:
%
%        The above continuous-time 2-DOF PID formula can be rewritten in
%        an equivalent expression that contains two integrators:
%
%                             1     1                 Td
%           Kp * [ (b*r-y) + --- * --- * (r-y)+ --------------- * (c*r-y)]
%                             Ti    s              Td     1
%                                                 ---- + ---
%                                                   N     s
%
%         When the PID controller is discretized, the two integrators
%         are replaced by the discretizers that are defined in the
%         "IFormula" and "DFormula" properties respectively.  The
%         supported numerical integration methods are:
%
%           'ForwardEuler':     replace 1/s with Ts/(z-1)
%           'BackwardEuler':    replace 1/s with Ts*z/(z-1)
%           'Trapezoidal':      replace 1/s with (Ts/2)*(z+1)/(z-1)
%
%        The default method for both integrators is ForwardEuler. When
%        the PID controller is in continuous time, 'IFormula' and
%        'DFormula' are ignored.
%
%    In all syntax above, the input list can be followed by pairs
%       'PropertyName1', PropertyValue1, ...
%    that set the various properties of PIDSTD systems. Type LTIPROPS
%    for details of the properties that are common for LTI systems.
%
%    You can create arrays of PIDSTD objects by using N-dimension
%    double arrays for Kp, Ti, Td, N, b, and c parameters.  For example, if Kp
%    and Ti are arrays of size [3 4], then
%
%       SYS = PIDSTD2(Kp,Ti)
%
%    creates a 3-by-4 array of PIDSTD objects.  You can also use
%    indexed assignment and STACK to build PIDSTD2 arrays:
%
%       SYS = PIDSTD2(zeros(2,1))          % create 2x1 array of 2-DOF PID controllers
%       SYS(:,:,1) = PIDSTD2(1)            % assign 1st 2-DOF PID controller
%       SYS(:,:,2) = PIDSTD2(2,3)          % assign 2st 2-DOF PID controller
%       SYS = STACK(1,SYS,PIDSTD2(4,5,6))  % add 3rd 2-DOF PID controller to array
%
%  Conversion:
%    PIDSYS = PIDSTD2(SYS) converts the dynamic system SYS to a PIDSTD2
%    object. An error is thrown when SYS cannot be expressed as a 2-DOF PID
%    controller in standard form. If SYS is a LTI array, PIDSYS is an array
%    of PIDSTD2 objects.
%
%    PIDSYS = PIDSTD2(SYS,'IFormula',Value1,'DFormula',Value2) converts
%    SYS to PIDSYS with specified discrete-time formulas for the
%    integrator and derivative terms.
%
%  See also PID2, PIDSTD, PID, TF.

%   Author(s): B. Singh
%   Copyright 2015 The MathWorks, Inc.
try
   [ConstructFlag,InputList] = lti.isContructorCall('pidstd2',varargin);
   if ConstructFlag
      error(message('Control:ltiobject:pidOperations6','PIDSTD2'))
   else
      % Inherit metadata and Variable
      sys = InputList{1};
      if isequal(iosize(sys),[1 2])
         if sys.Ts<0
            error(message('Control:ltiobject:pidAmbiguousRate'))
         end
         Options = ltipack.AbstractPID.getConversionOptions(InputList(2:end),'pidstd2');
         sysOut = copyMetaData(sys,pidstd2_(sys,Options));
      else
         sysc = class(sys);
         if strcmp(sysc,'pid') || strcmp(sysc,'pidstd') %#ok<*STISA>
            error(message('Control:ltiobject:pidOperations10',sysc,['help ' sysc '.make2DOF']))
         else
            error(message('Control:ltiobject:pidOperations9'))
         end
      end
   end
catch E
   if strcmp(E.identifier,'Control:ltiobject:pid2DOFNegativeBC')
      error(message('Control:ltiobject:pid2DOFNegativeBC','pidstd2'))
   elseif any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:pid1',class(sys)))
   else
      throw(E)
   end
end

