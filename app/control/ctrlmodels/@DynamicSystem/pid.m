function sysOut = pid(varargin)
%PID  Create a PID controller in parallel form.
%
%  Construction:
%    SYS = PID(Kp,Ki,Kd,Tf) creates a continuous-time PID controller
%    in parallel form with a first-order derivative filter:
%
%               Ki      Kd*s
%         Kp + ---- + --------
%               s      Tf*s+1
%
%    The scalars Kp, Ki, Kd, and Tf specify the proportional gain,
%    integral gain, derivative gain, and filter time constant. The Tf
%    value must be nonnegative for stability. The default values are
%    Kp=1, Ki=0, Kd=0, and Tf=0. If a parameter is omitted, its default
%    value is used. For example, PID(Kp,Ki,Kd) creates a PID controller
%    with pure derivative term. The resulting SYS is of type PID if
%    Kp,Ki,Kd,Tf are all real, and of type GENSS if one of the gains
%    is tunable (see REALP and GENMAT).
%
%    SYS = PID(Kp,Ki,Kd,Tf,Ts) creates a discrete-time PID controller
%    with sample time Ts>0. The discrete-time PID formula is
%
%                                 Kd
%         Kp + Ki * IF(z) + --------------
%                             Tf  +  DF(z)
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
%    settings are ignored for continuous-time PIDs. The following
%    settings are disallowed because they generate unstable PIDs:
%
%        (1) Type='PID' and DFormula='Trapezoidal'
%        (2) Type='PIDF' and DFormula='ForwardEuler' and Ts>=2*Tf
%
%    You can set additional properties by using name/value pairs.
%    For example,
%        sys = pid(1,2,3,0.5,0.1,'IFormula','T','TimeUnit','min')
%    also specifies the integral-term formula and the time units. Type
%    "properties(pid)" for a complete list of PID properties, and type
%        help pid.<PropertyName>
%    for help on a particular property.
%
%    You can create arrays of PID objects by specifying arrays of values
%    for Kp,Ki,Kd,Tf. For example, if Kp and Ki are 3-by-4 arrays,
%    PID(Kp,Ki) creates a 3-by-4 array of PID controllers.
%
%  Conversion:
%    PIDSYS = PID(SYS) converts the dynamic system SYS to a PID object.
%    An error is thrown when SYS cannot be expressed as a PID controller
%    in parallel form.
%
%    PIDSYS = PID(SYS,'IFormula',Value1,'DFormula',Value2) returns an
%    equivalent PID controller with different formulas for the integral
%    and derivative terms.
%
%  See also PIDSTD, tunablePID, TF.

%   Author(s): Rong Chen
%   Copyright 2009-2013 The MathWorks, Inc.
try
   [ConstructFlag,InputList] = lti.isContructorCall('pid',varargin);
   if ConstructFlag
      error(message('Control:ltiobject:pidOperations6','PID'))
   else
      % Inherit metadata and Variable
      sys = InputList{1};
      if issiso(sys)
         if sys.Ts<0
            % Discrete-time PID formula requires knowing Ts
            error(message('Control:ltiobject:pidAmbiguousRate'))
         end
         Options = ltipack.AbstractPID.getConversionOptions(InputList(2:end),'pid');
         sysOut = copyMetaData(sys,pid_(sys,Options));
      else
         sysc = class(sys);
         if strcmp(sysc,'pid2') || strcmp(sysc,'pidstd2') %#ok<*STISA>
            error(message('Control:ltiobject:pidOperations11',sysc,['help ' sysc '.make1DOF']))
         else
            error(message('Control:ltiobject:pidOperations5'))
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
