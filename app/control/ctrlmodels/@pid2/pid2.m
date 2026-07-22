classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      pid2 < pid
   %PID2  Create a 2-DOF PID controller in parallel form.
   %
   %  Construction:
   %    SYS = PID2(Kp,Ki,Kd,Tf,b,c) creates a continuous-time 2-DOF PID
   %    controller in parallel form with a first-order derivative filter.
   %    The controller output u is calculated from the controller inputs
   %    r (reference signal) and y (plant output) by:
   %
   %                             Ki              Kd*s
   %         u = Kp * (b*r-y) + ---- * (r-y) + -------- * (c*r-y)
   %                             s              Tf*s+1
   %
   %    The scalars Kp, Ki, Kd, Tf, b, and c specify the proportional
   %    gain, integral gain, derivative gain, filter time constant,
   %    setpoint weight for proportional term and setpoint weight for
   %    derivative term. The Tf value must be nonnegative for stability.
   %    Values of b and c must also be nonnegative.
   %
   %    The default values are Kp=1, Ki=0, Kd=0, Tf=0, b=1 and c=1. If a
   %    parameter is omitted, its default value is used. For example,
   %    PID2(Kp,Ki,Kd) creates a 2-DOF PID controller with pure derivative
   %    term and b=c=1. The resulting SYS is of type PID2 if
   %    Kp,Ki,Kd,Tf,b,c are all real, and of type GENSS if one of the
   %    gains is tunable (see REALP and GENMAT).
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
   %        (1) (Kd > 0, Tf = 0) and DFormula='Trapezoidal'
   %        (2) (Kd > 0, Tf > 0) and DFormula='ForwardEuler' and Ts>=2*Tf
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
   
   %  Copyright 2015-2016 The MathWorks, Inc.
   
   % Public properties with restricted values
   properties (Access = public, Dependent)
      % Setpoint weight for proportional term
      %
      % The "b" property stores the setpoint weight for proportional term of a PID controller.
      % b must be real and positive. For an array of 2-DOF PID objects, b has
      % the same size as the array size. For example,
      %   Kp = 1;
      %   Ki = 2;
      %   Kd = 3;
      %   Tf = 4;
      %   b = 1;
      %   c = 1;
      %   C = pid2(Kp,Ki,Kd,Tf,b,c);
      % creates a 2-DOF PID controller in parallel form.
      b
      % Setpoint weight for derivative term
      %
      % The "c" property stores the setpoint weight for derivative term of a PID controller.
      % c must be real and positive. For an array of 2-DOF PID objects, c has
      % the same size as the array size. For example,
      %   Kp = 1;
      %   Ki = 2;
      %   Kd = 3;
      %   Tf = 4;
      %   b = 1;
      %   c = 1;
      %   C = pid2(Kp,Ki,Kd,Tf,b,c);
      % creates a 2-DOF PID controller in parallel form.
      c
   end
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(op)
         switch op
            case 'stack'
               T = 'pid2';
            case 'connect'
               T = 'ss';
            otherwise
               T = 'tf';
         end
      end

      function T = superiorTypes()
         T = {'pid2','tf','zpk','ss','sparss'};
      end
   end
   
   % Public methods
   methods
      
      function sys = pid2(varargin)
         ni = nargin;
         
         % Handle conversion PID2(SYS) where SYS is a @pid2 or ltiblock.pid2 object
         if ni>0 && (isa(varargin{1},'pid2') || isa(varargin{1},'ltiblock.pid2'))
            sys0 = varargin{1};
            if ni==1 && isa(sys0,'pid2')  % Optimization for SYS of class @pid2
               sys = sys0;
            else
               try
                  Options = ltipack.AbstractPID.getConversionOptions(varargin(2:end),'pid2');
                  sys = copyMetaData(sys0,pid2_(sys0,Options));
               catch ME
                  throw(ME)
               end
            end
            return
         end
         
         % Dissect input list
         DataInputs = 0;
         PVStart = ni+1;
         for ct=1:ni
            nextarg = varargin{ct};
            if ischar(nextarg) || isStringScalar(nextarg)
               PVStart = ct;
               break
            else
               DataInputs = DataInputs+1;
            end
         end
         
         % Handle bad calls
         if PVStart==1
            % only ni == 0 is allowed
            if ni==1
               % Bad conversion
               error(message('Control:ltiobject:construct3','pid2'))
            elseif ni>0
               % not allowed
               error(message('Control:general:InvalidSyntaxForCommand','pid2','pid2'))
            end
         elseif DataInputs>7
            error(message('Control:general:InvalidSyntaxForCommand','pid2','pid2'))
         end
         
         % Process parameters Kp, Ki, Kd, Tf, b, c and sample time Ts.  If any
         % PID parameters is omitted or empty, default value is used.
         try
            Params = {1 0 0 0 1 1};  % defaults
            Params(1:DataInputs) = varargin(1:DataInputs);
            Kp = checkParameterData(sys,'Kp',Params{1});
            Ki = checkParameterData(sys,'Ki',Params{2});
            Kd = checkParameterData(sys,'Kd',Params{3});
            Tf = checkParameterData(sys,'Tf',Params{4});
            b = checkParameterData(sys,'b',Params{5});
            c = checkParameterData(sys,'c',Params{6});
            % Sample time
            if DataInputs==7
               Ts = ltipack.utValidateTs(varargin{7});
            else
               Ts = 0;
            end
         catch ME
            throw(ME)
         end
         
         % Determine I/O and array size
         if ni>0
            ArraySize = ltipack.getLTIArraySize(0,Kp,Ki,Kd,Tf,b,c);
            if isempty(ArraySize)
               error(message('Control:ltiobject:pid21'))
            end
         else
            ArraySize = [1 1];
         end
         Nsys = prod(ArraySize);
         sys.IOSize_ = [1 2];
         
         % Create @piddataP2 object array
         % RE: Inlined for optimal speed
         if Nsys==1
            Data = ltipack.piddataP2(Kp,Ki,Kd,Tf,b,c,Ts);
            Data.Delay = ltipack.utDelayStruct(1,2,false);
         else
            Data = createArray(ArraySize,'ltipack.piddataP2');
            Delay = ltipack.utDelayStruct(1,2,false);
            for ct=1:Nsys
               Data(ct).Kp = Kp(min(ct,end));
               Data(ct).Ki = Ki(min(ct,end));
               Data(ct).Kd = Kd(min(ct,end));
               Data(ct).Tf = Tf(min(ct,end));
               Data(ct).b = b(min(ct,end));
               Data(ct).c = c(min(ct,end));
               Data(ct).Ts = Ts;
               Data(ct).Delay = Delay;
            end
         end
         sys.Data_ = Data;
         
         % Process additional settings and validate system
         % Note: Skip when just constructing empty instance for efficiency
         if ni>0
            try
               % User-defined properties
               Settings = varargin(:,PVStart:ni);
               
               % Apply settings
               if ~isempty(Settings)
                  sys = fastSet(sys,Settings{:});
               end
               % Consistency check: parameters
               sys = checkConsistency(sys);
               
            catch ME
               throw(ME)
            end
         end
      end
      
      %% Conversion
      
      function PID = make1DOF(PID2)
         %%MAKE1DOF converts a 2-DOF PID controller to a 1-DOF PID
         %controller
         %
         % C = make1DOF(C2) returns a 1-DOF PID object C by removing the
         % coefficients b and c from a 2-DOF PID object C2.
         
         Data = PID2.Data_;
         pidData = createArray(size(Data),'ltipack.piddataP');
         for ct=1:numel(Data)
            pidData(ct) = make1DOF(Data(ct));
         end
         PID = pid.make(pidData);
         PID.TimeUnit = PID2.TimeUnit;
         PID.SamplingGrid = PID2.SamplingGrid;
      end
      
      function PID2 = make2DOF(PID2,varargin)
         %%MAKE2DOF converts a 1-DOF PID controller to a 2-DOF PID
         %controller
         %
         % C2 = make2DOF(C) returns a PID2 object C2 when C is a PID
         % object. By default, setpoint weights b and c are set to 1.
         %
         % C2 = make2DOF(C,b) specifies the setpoint weight for
         % proportional term
         %
         % C2 = make2DOF(C,b,c) specifies the setpoint weights for both
         % proportional and derivative terms
         
         if nargin > 3
            error(message('MATLAB:narginchk:tooManyInputs'));
         end
         
         if nargin == 1
            return
         end
         b = PID2.b; c = PID2.c; %#ok<*PROPLC>
         try
            if nargin >= 2
               b = checkParameterData(PID2,'b',varargin{1});
            end
            if nargin >= 3
               c = checkParameterData(PID2,'c',varargin{2});
            end
         catch E
            throw(E);
         end
         
         PID = make1DOF(PID2);
         PID2 = make2DOF(PID,b,c);
      end
      
      function M = fliplr(M) %#ok<MANU>
         %FLIPLR   Flips input channels of input/output model.
         %
         %   C = FLIPLR(C) is not supported for 2-DOF PID controllers.
         %   The Input channels are fixed to [r;y] where "r" is the
         %   reference signal and "y" is the plant output.
         
         error(message('Control:ltiobject:pidFlipLR'))
      end
      
      %% get methods
      function Value = get.b(sys)
         % GET method for b
         Value = getParameter(sys,'b');
      end
      
      function Value = get.c(sys)
         % GET method for c
         Value = getParameter(sys,'c');
      end
      
      %% set methods
      function sys = set.b(sys,Value)
         % SET method for b
         sys = setParameter(sys,'b',Value);
      end
      
      function sys = set.c(sys,Value)
         % SET method for c
         sys = setParameter(sys,'c',Value);
      end
      
   end
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      %% INDEXING
      function sys = indexasgn_(sys,indices,rhs,ioSize,ArrayMask)
         % Data management in SYS(indices) = RHS.
         % ioSize is the new I/O size and ArrayMask tracks which
         % entries in the resulting system array have been reassigned.
         
         % Construct template initial value for new entries in system array
         D0 = ltipack.piddataP2(0,inf,0,inf,1,1,sys.Ts);
         % Update data
         sys.Data_ = ltipack.reassignData(sys.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
      end
      %% TRANSFORMATIONS
      function sys = transpose_(sys)
         % Convert to TF before evaluating
         sys = transpose_(tf(sys));
      end
   end
   
   %% STATIC METHODS
   methods(Static, Hidden)
      
      function sys = loadobj(s)
         % Overload as superclass method is not applicable
         sys = DynamicSystem.updateMetaData(s);
      end
      
      function sys = make(D,~)
         % Constructs PID2 model from ltipack.piddataP2 instance
         sys = pid2;
         sys.Data_ = D;
      end
      
      function sys = convert(X)
         % Safe conversion to PID2.
         if isnumeric(X) || isa(X,'StaticModel')
            sys = pid2(tf(double(X)));
         else
            sys = pid2(X);
         end
      end
      
   end
   
end


