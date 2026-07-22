function sysOut = pid2(varargin)
%PID2  Create a 2-DOF PID controller in parallel form.
%
%  Construction:
%    SYS = PID2(Kp,Ki,Kd,Tf,b,c) creates a continuous-time 2-DOF PID
%    controller in parallel form with a first-order derivative filter:
%
%                             Ki              Kd*s
%         u = Kp * (b*r-y) + ---- * (r-y) + -------- * (c*r-y)
%                             s              Tf*s+1
%
%    u is controller output, r is reference input and y is plant output.
%
%    The scalars Kp, Ki, Kd, Tf, b, and c specify the proportional gain,
%    integral gain, derivative gain, filter time constant, setpoint weight
%    for proportional term and setpoint weight for derivative term. The Tf
%    value must be nonnegative for stability. The default values are Kp=1,
%    Ki=0, Kd=0, Tf=0, b=1 and c=1. If a parameter is omitted, its default
%    value is used. For example, PID2(Kp,Ki,Kd) creates a 2-DOF PID
%    controller with pure derivative term and b=c=1. The resulting SYS is
%    of type PID2 if Kp,Ki,Kd,Tf,b,c are all real, and of type GENSS if one
%    of the gains is tunable (see REALP and GENMAT).
%
%    SYS = PID2(Kp,Ki,Kd,Tf,b,c,Ts) creates a discrete-time PID controller
%    with sample time Ts>0. The discrete-time PID formula is
%
%                                                  Kd
%         Kp * (b*r-y) + Ki * IF(z) * (r-y) + -------------- * (c*r-y)
%                                              Tf  +  DF(z)
%
%    where IF(z) and DF(z) are the discrete integrator formulas for the
%    integral and derivative terms. Use the "IFormula" and "DFormula"
%    properties to specify these formulas. Available formulas include:
%
%        'ForwardEuler'        Ts/(z-1)
%        'BackwardEuler'      Ts*z/(z-1)
%        'Trapezoidal'     (Ts/2)*(z+1)/(z-1)
%
%    The default formula is ForwardEuler. The 'IFormula' and 'DFormula'
%    settings are ignored for continuous-time PIDs. The following settings
%    are disallowed because they generate unstable PIDs:
%
%        (1) Type='PID2' and DFormula='Trapezoidal'
%        (2) Type='PIDF2' and DFormula='ForwardEuler' and Ts>=2*Tf
%
%    You can set additional properties by using name/value pairs. For
%    example,
%        sys = pid2(1,2,3,0.5,1,1,0.1,'IFormula','T','TimeUnit','min')
%    also specifies the integral-term formula and the time units. Type
%    "properties(pid2)" for a complete list of PID2 properties, and type
%        help pid2.<PropertyName>
%    for help on a particular property.
%
%    You can create arrays of PID2 objects by specifying arrays of values
%    for Kp,Ki,Kd,Tf,b,c. For example, if Kp and Ki are 3-by-4 arrays,
%    PID2(Kp,Ki) creates a 3-by-4 array of PID2 controllers.
%
%  Conversion:
%    PIDSYS = PID2(SYS) converts the dynamic system SYS to a PID2 object.
%    An error is thrown when SYS cannot be expressed as a PID2 controller
%    in parallel form.
%
%    PIDSYS = PID2(SYS,'IFormula',Value1,'DFormula',Value2) returns an
%    equivalent PID2 controller with different formulas for the integral
%    and derivative terms.
%
%  See also PIDSTD2, PID, PIDSTD, tunablePID, tunablePID2, TF.

%   Author(s): B. Singh Copyright 2015 The MathWorks, Inc.
try
   [ConstructFlag,InputList] = lti.isContructorCall('pid2',varargin);
   if ConstructFlag
      error(message('Control:ltiobject:pidOperations6','PID2'))
   else
      % Inherit metadata and Variable
      sys = InputList{1};
      if isequal(iosize(sys),[1 2])
         if sys.Ts<0
            % Discrete-time PID formula requires knowing Ts
            error(message('Control:ltiobject:pidAmbiguousRate'))
         end
         Options = ltipack.AbstractPID.getConversionOptions(InputList(2:end),'pid2');
         sysOut = copyMetaData(sys,pid2_(sys,Options));
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
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:pid1',class(sys)))
   else
      throw(E)
   end
end
