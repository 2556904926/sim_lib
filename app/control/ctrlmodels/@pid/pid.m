classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      pid < ltipack.AbstractPID
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
   %        (1) (Kd > 0, Tf = 0) and DFormula='Trapezoidal'
   %        (2) (Kd > 0, Tf > 0) and DFormula='ForwardEuler' and Ts>=2*Tf
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
   %  See also PIDSTD, PID2, PIDSTD2, tunablePID, tunablePID2, TF.
   
   %   Author(s): R. Chen
   %   Copyright 2009-2011 The MathWorks, Inc.
   
   % Public properties with restricted values
   properties (Access = public, Dependent)
      % Proportional gain
      %
      % The "Kp" property stores the proportional gain of a PID
      % controller. Kp must be real and finite. For an array of PID
      % objects, Kp has the same size as the array size. For example,
      %   Kp = 1;
      %   Ki = 2;
      %   Kd = 3;
      %   Tf = 4;
      %   C = pid(Kp,Ki,Kd,Tf);
      % creates a PID controller in parallel form.
      Kp
      % Integral gain
      %
      % The "Ki" property stores the integral gain of a PID controller.
      % Ki must be real and finite. For an array of PID objects, Ki has
      % the same size as the array size. For example,
      %   Kp = 1;
      %   Ki = 2;
      %   Kd = 3;
      %   Tf = 4;
      %   C = pid(Kp,Ki,Kd,Tf);
      % creates a PID controller in parallel form.
      Ki
      % Derivative gain
      %
      % The "Kd" property stores the derivative gain of a PID controller.
      % Kd must be real and finite. For an array of PID objects, Kd has
      % the same size as the array size. For example,
      %   Kp = 1;
      %   Ki = 2;
      %   Kd = 3;
      %   Tf = 4;
      %   C = pid(Kp,Ki,Kd,Tf);
      % creates a PID controller in parallel form.
      Kd
      % Derivative filter time constant
      %
      % The "Tf" property stores the derivative filter time constant of a
      % PID controller. Tf must be real, finite, greater than or equal to
      % 0. For an array of PID objects, Tf has the same size as the array
      % size. For example,
      %   Kp = 1;
      %   Ki = 2;
      %   Kd = 3;
      %   Tf = 4;
      %   C = pid(Kp,Ki,Kd,Tf);
      % creates a PID controller in parallel form.
      Tf
   end
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(op)
         switch op
            case 'stack'
               T = 'pid';
            case 'connect'
               T = 'ss';
            otherwise
               T = 'tf';
         end
      end

      function T = superiorTypes()
         T = {'pid','tf','zpk','ss'};
      end
            
      function A = getAttributes(A)
         % Override default attributes
         A.Varying = false;
         A.Structured = false;
         A.FRD = false;
         A.Sparse = false;
      end
      
      function T = toStructured()
         T = 'neutral_genss';
      end
      
      function T = toVarying()
         T = 'ltvss';
      end

      function T = toFRD()
         T = 'frd';
      end
      
      function T = toSparse()
         T = 'sparss';
      end
      
   end
   
   % Public methods
   methods
      
      function sys = pid(varargin)
         ni = nargin;
         
         % Handle conversion PID(SYS) where SYS is a @pid or ltiblock.pid object
         if ni>0 && (isa(varargin{1},'pid') || isa(varargin{1},'ltiblock.pid'))
            sys0 = varargin{1};
            if ni==1 && isa(sys0,'pid')  % Optimization for SYS of class @pid
               sys = sys0;
            else
               try
                  Options = ltipack.AbstractPID.getConversionOptions(varargin(2:end),'pid');
                  sys = copyMetaData(sys0,pid_(sys0,Options));
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
               ctrlMsgUtils.error('Control:ltiobject:construct3','pid')
            elseif ni>0
               % not allowed
               ctrlMsgUtils.error('Control:general:InvalidSyntaxForCommand','pid','pid')
            end
         elseif DataInputs>5
            ctrlMsgUtils.error('Control:general:InvalidSyntaxForCommand','pid','pid')
         end
         
         % Process parameters Kp, Ki, Kd, Tf and sample time Ts.  If any
         % PID parameters is omitted or empty, default value is used.
         try
            Params = {1 0 0 0};  % defaults
            Params(1:DataInputs) = varargin(1:DataInputs);
            Kp = checkParameterData(sys,'Kp',Params{1});
            Ki = checkParameterData(sys,'Ki',Params{2});
            Kd = checkParameterData(sys,'Kd',Params{3});
            Tf = checkParameterData(sys,'Tf',Params{4});
            % Sample time
            if DataInputs==5
               Ts = ltipack.utValidateTs(varargin{5});
            else
               Ts = 0;
            end
         catch ME
            throw(ME)
         end
         
         % Determine I/O and array size
         if ni>0
            ArraySize = ltipack.getLTIArraySize(0,Kp,Ki,Kd,Tf);
            if isempty(ArraySize)
               ctrlMsgUtils.error('Control:ltiobject:pid1')
            end
         else
            ArraySize = [1 1];
         end
         Nsys = prod(ArraySize);
         sys.IOSize_ = [1 1];
         
         % Create @piddataP object array
         % RE: Inlined for optimal speed
         if Nsys==1
            Data = ltipack.piddataP(Kp,Ki,Kd,Tf,Ts);
         else
            Data = createArray(ArraySize,'ltipack.piddataP');
            Delay = ltipack.utDelayStruct(1,1,false);
            for ct=1:Nsys
               Data(ct).Kp = Kp(min(ct,end));
               Data(ct).Ki = Ki(min(ct,end));
               Data(ct).Kd = Kd(min(ct,end));
               Data(ct).Tf = Tf(min(ct,end));
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
      function PID2 = make2DOF(PID,varargin)
         %%MAKE2DOF converts a 1-DOF PID controller to a 2-DOF PID
         %controller
         %
         % C2 = make2DOF(C) creates a PID2 object C2 by adding
         % coefficients b and c to a a PID object C. By default,
         % setpoint weights b and c are set to 1.
         %
         % C2 = make2DOF(C,b) specifies the setpoint weight for
         % proportional term
         %
         % C2 = make2DOF(C,b,c) specifies the setpoint weights for both
         % proportional and derivative terms
         
         if nargin > 3
            error(message('MATLAB:narginchk:tooManyInputs'));
         end
         b = 1; c = 1;
         try
            if nargin >= 2
               b = checkParameterData(PID,'b',varargin{1});
            end
            if nargin >= 3
               c = checkParameterData(PID,'c',varargin{2});
            end
         catch E
            throw(E);
         end
         
         Data = PID.Data_;
         pidData = createArray(size(Data),'ltipack.piddataP2');
         for ct=1:numel(Data)
            pidData(ct) = make2DOF(Data(ct),b,c);
         end
         PID2 = pid2.make(pidData);
         PID2.TimeUnit_ = PID.TimeUnit_;
         PID2.SamplingGrid_ = PID.SamplingGrid_;
      end
      
      %% get methods
      function Value = get.Kp(sys)
         % GET method for Kp
         Value = getParameter(sys,'Kp');
      end
      
      function Value = get.Ki(sys)
         % GET method for Ki
         Value = getParameter(sys,'Ki');
      end
      
      function Value = get.Kd(sys)
         % GET method for Kd
         Value = getParameter(sys,'Kd');
      end
      
      function Value = get.Tf(sys)
         % GET method for Tf
         Value = getParameter(sys,'Tf');
      end
      
      %% set methods
      function sys = set.Kp(sys,Value)
         % SET method for Kp
         sys = setParameter(sys,'Kp',Value);
      end
      
      function sys = set.Ki(sys,Value)
         % SET method for Ki
         sys = setParameter(sys,'Ki',Value);
      end
      
      function sys = set.Kd(sys,Value)
         % SET method for Kd
         sys = setParameter(sys,'Kd',Value);
      end
      
      function sys = set.Tf(sys,Value)
         % SET method for Tf
         sys = setParameter(sys,'Tf',Value);
         if sys.CrossValidation_ && sys.Ts>0
            sys = checkFilterStability(sys);
         end
      end
      
   end
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      
      %% BINARY OPERATIONS
      function boo = hasCustomScalarMultiply_(~)
         % Supported for PID and PID2
         boo = true;
      end
      function boo = hasCustomScalarAdd_(sys)
         % Only supported for PID + SCALAR
         boo = issiso(sys);
      end
      
      function sys = addScalar_(sys,A)
         % Add numeric scalar to PID
         s = size(A);  s = [s ones(1,4-numel(s))];
         Data = sys.Data_;
         if numel(A)==1 || isequal(s(3:end),size(Data))
            for ct=1:numel(Data)
               Data(ct).Kp = Data(ct).Kp + A(min(ct,end));
            end
            sys.Data_ = Data;
         else
            error(message('Control:combination:IncompatibleModelArrayDims'))
         end
      end
      
      function sys = leftMultiplyByScalar_(sys,A)
         % Multiplies PID for a numeric scalar
         s = size(A);  s = [s ones(1,4-numel(s))];
         Data = sys.Data_;
         if numel(A)==1 || isequal(s(3:end),size(Data))
            for ct=1:numel(Data)
               alpha = A(min(ct,end));
               Data(ct).Kp = alpha * Data(ct).Kp;
               Data(ct).Ki = alpha * Data(ct).Ki;
               Data(ct).Kd = alpha * Data(ct).Kd;
            end
            sys.Data_ = Data;
         else
            error(message('Control:combination:IncompatibleModelArrayDims'))
         end
      end
      
      function sys = rightMultiplyByScalar_(sys,A)
         % Multiplies PID for a numeric scalar
         sys = leftMultiplyByScalar_(sys,A);
      end

      %% INDEXING
      function sys = indexasgn_(sys,indices,rhs,ioSize,ArrayMask)
         % Data management in SYS(indices) = RHS.
         % ioSize is the new I/O size and ArrayMask tracks which
         % entries in the resulting system array have been reassigned.
         
         % Construct template initial value for new entries in system array
         D0 = ltipack.piddataP(0,inf,0,inf,sys.Ts);
         % Update data
         sys.Data_ = ltipack.reassignData(sys.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
      end
      
   end
   
   %% PROTECTED METHODS
   methods (Access=protected)
      
      function value = checkParameterData(~, type, value)
         % Checks parameter is properly formatted
         if isempty(value)
            value = ones(size(value));
         else
            if isnumeric(value) && isreal(value) && allfinite(value)
               value = double(full(value));
               if strcmp(type,'Tf') && any(value(:)<0)
                  ctrlMsgUtils.error('Control:ltiobject:pidSet2','Tf');
               end
               if strcmp(type,'b') && any(value(:)<0)
                  ctrlMsgUtils.error('Control:ltiobject:pidSet2','b');
               end
               if strcmp(type,'c') && any(value(:)<0)
                  ctrlMsgUtils.error('Control:ltiobject:pidSet2','c');
               end
            else
               ctrlMsgUtils.error('Control:ltiobject:pidSet1',type);
            end
         end
      end
      
      function sys = checkFilterStability(sys)
         % Ensure derivative filter pole in discrete time to be stable
         Data = sys.Data_;
         for ct=1:numel(Data)
            D = Data(ct);
            if D.Kd>0
               Tf = D.Tf;
               if Tf==0 && D.DFormula == 'T'
                  ctrlMsgUtils.error('Control:ltiobject:pidNoTrapezoidal')
               elseif Tf~=0 && D.DFormula == 'F' && sys.Ts>=2*Tf
                  ctrlMsgUtils.error('Control:ltiobject:pidUnstableFilterPolePID')
               end
            end
         end
      end
   end
   
   
   %% STATIC METHODS
   methods(Static, Hidden)
      
      function sys = loadobj(s)
         % Load filter for @pid objects
         if isa(s,'pid')
            % MCOS
            sys = DynamicSystem.updateMetaData(s);
            % replace unstable pole for R2010b PID object
            if sys.Version_==10 && sys.Ts>0
               Data = sys.Data_;
               for ct=1:numel(Data)
                  if Data(ct).Kd~=0
                     if Data(ct).Tf==0 && Data(ct).DFormula=='T'
                        Data(ct).DFormula='F';
                        ctrlMsgUtils.warning('Control:ltiobject:pidLoadReplaceTrapezoidal')
                     elseif Data(ct).Tf~=0 && Data(ct).DFormula=='F' && Data(ct).Ts>=2*Data(ct).Tf
                        Data(ct).Tf = Data(ct).Ts;
                        ctrlMsgUtils.warning('Control:ltiobject:pidLoadReplaceTf')
                     end
                  end
               end
               sys.Data_ = Data;
            end
            sys.Version_ = ltipack.ver();
         end
      end
      
      function sys = make(D,~)
         % Constructs PID model from ltipack.piddataP instance
         sys = pid;
         sys.Data_ = D;
      end
      
      function sys = convert(X)
         % Safe conversion to PID.
         if isnumeric(X) || isa(X,'StaticModel')
            sys = pid(double(X));
         else
            sys = pid(X);
         end
      end
      
   end
   
end


