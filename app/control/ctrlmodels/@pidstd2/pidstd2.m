classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      pidstd2 < pidstd
    %PIDSTD2  Create a 2-DOF PID controller in standard form.
    %
    %  Construction:
    %    SYS = PIDSTD2(Kp,Ti,Td,N,b,c) creates a continuous-time 2-DOF PID controller
    %    in standard form with a first order derivative filter:
    %
    %                              1                 Td*s
    %           Kp * [ (b*r-y) + ------ * (r-y) + ------------ * (c*r-y) ]
    %                             Ti*s             (Td/N)*s+1
    %
    %    u is controller output, r is reference input and y is plant output.
    %
    %    When Kp, Ti, Td, N, b, and c are scalar, the output SYS is a PIDSTD2
    %    object that represents a two-input-one-output PID controller. The
    %    following rules apply to construct a valid 2-DOF PID controller in standard
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
    %       PIDSTD2(Kp,Ti) returns a 2-DOF PI controller
    %       PIDSTD2(Kp,Ti,Td) returns a 2-DOF PID controller
    %       PIDSTD2(Kp,Ti,Td,N) returns a 2-DOF PID controller with derivative filter
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
    %    that set the various properties of PIDSTD systems. Type
    %    "properties(pidstd2)" for a complete list of PIDSTD2 properties, and type
    %        help pidstd2.<PropertyName>
    %    for help on a particular property.
    %
    %    You can create arrays of PIDSTD2 objects by using N-dimension
    %    double arrays for Kp, Ti, Td, N, b, and c parameters.  For example, if Kp
    %    and Ti are arrays of size [3 4], then
    %
    %       SYS = PIDSTD2(Kp,Ti)
    %
    %    creates a 3-by-4 array of PIDSTD2 objects.  You can also use
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
    %  See also PID2, PIDSTD, TF.
    
    %  Copyright 2015-2016 The MathWorks, Inc.
    
    % Public properties with restricted values
    properties (Access = public, Dependent)
        % Setpoint weight for proportional term
        %
        % The "b" property stores the setpoint weight for proportional term of a PID controller.
        % b must be real and positive. For an array of 2-DOF PID objects, b has
        % the same size as the array size. For example,
        %   Kp = 1;
        %   Ti = 2;
        %   Td = 3;
        %   N = 4;
        %   b = 1;
        %   c = 1;
        %   C = pidstd2(Kp,Ti,Td,N,b,c);
        % creates a 2-DOF PID controller in parallel form.
        b
        % Setpoint weight for derivative term
        %
        % The "c" property stores the setpoint weight for derivative term of a PID controller.
        % c must be real and positive. For an array of 2-DOF PID objects, c has
        % the same size as the array size. For example,
        %   Kp = 1;
        %   Ti = 2;
        %   Td = 3;
        %   N = 4;
        %   b = 1;
        %   c = 1;
        %   C = pidstd2(Kp,Ti,Td,N,b,c);
        % creates a 2-DOF PID controller in parallel form.
        c
    end
    % TYPE MANAGEMENT IN BINARY OPERATIONS
    methods (Static, Hidden)
        
      function T = toClosed(op)
         switch op
            case 'stack'
               T = 'pidstd2';
            case 'connect'
               T = 'ss';
            otherwise
               T = 'tf';
         end
      end

      function T = superiorTypes()
         T = {'pidstd2','pid2','tf','zpk','ss','sparss'};
      end
      
   end
    
    % Public methods
    methods
        
        function sys = pidstd2(varargin)
            ni = nargin;
            
            % Handle conversion PIDSTD2(SYS) where SYS is also a PIDSTD2 object
            if ni>0 && isa(varargin{1},'pidstd2')
                sys0 = varargin{1};
                if ni==1
                    sys = sys0; % Optimization for SYS of class @pidstd2
                else
                    % convert with options.  For example, from one formula to another formula
                    try
                        Options = ltipack.AbstractPID.getConversionOptions(varargin(2:end),'pidstd2');
                        sys = copyMetaData(sys0,pidstd2_(sys0,Options));
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
                % only ni==0 is allowed
                if ni==1
                    % Bad conversion
                    error(message('Control:ltiobject:construct3','pidstd2'))
                elseif ni>0
                    % not allowed
                    error(message('Control:general:InvalidSyntaxForCommand','pidstd2','pidstd2'))
                end
            elseif DataInputs>7
                error(message('Control:general:InvalidSyntaxForCommand','pidstd2','pidstd2'))
            end
            
            % Process parameters Kp, Ti, Td, N, Ts, b and c.  If any
            % PIDSTD2 parameters is omitted or empty, default value is used.
            try
                Params = {1 inf 0 inf 1 1};  % defaults
                Params(1:DataInputs) = varargin(1:DataInputs);
                Kp = checkParameterData(sys,'Kp',Params{1});
                Ti = checkParameterData(sys,'Ti',Params{2});
                Td = checkParameterData(sys,'Td',Params{3});
                N = checkParameterData(sys,'N',Params{4});
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
                ArraySize = ltipack.getLTIArraySize(0,Kp,Ti,Td,N,b,c);
                if isempty(ArraySize)
                    error(message('Control:ltiobject:pids1'))
                end
            else
                ArraySize = [1 1];
            end
            Nsys = prod(ArraySize);
            sys.IOSize_ = [1 2];
            
            % Create @piddataS2 object array
            % RE: Inlined for optimal speed
            if Nsys==1
                Data = ltipack.piddataS2(Kp,Ti,Td,N,b,c,Ts);
                Data.Delay = ltipack.utDelayStruct(1,2,false);
            else
                Data = createArray(ArraySize,'ltipack.piddataS2');
                Delay = ltipack.utDelayStruct(1,2,false);
                for ct=1:Nsys
                    Data(ct).Kp = Kp(min(ct,end));
                    Data(ct).Ti = Ti(min(ct,end));
                    Data(ct).Td = Td(min(ct,end));
                    Data(ct).N = N(min(ct,end));
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
        
        function PIDS = make1DOF(PIDS2)
            %%MAKE1DOF converts a 2-DOF PID controller to a 1-DOF PID
            %controller
            %
            % C = make1DOF(C2) returns a 1-DOF PID object C by removing the
            % coefficients b and c from a 2-DOF PID object C2.
            
            Data = PIDS2.Data_;
            pidData = createArray(size(Data),'ltipack.piddataS');
            for ct=1:numel(Data)
                pidData(ct) = make1DOF(Data(ct));
            end
            PIDS = pidstd.make(pidData,PIDS2.IOSize_);
            PIDS.TimeUnit = PIDS2.TimeUnit;
            PIDS.SamplingGrid = PIDS2.SamplingGrid;
        end
        
        function PIDS2 = make2DOF(PIDS2,varargin)
            %%MAKE2DOF converts a 1-DOF PID controller to a 2-DOF PID
            %controller
            %
            % C2 = make2DOF(C) returns a PIDSTD2 object C2 when C is a
            % PIDSTD object. By default, setpoint weights b and c are set
            % to 1.
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
            b = PIDS2.b; c = PIDS2.c; %#ok<*PROPLC>
            try
                if nargin >= 2
                    b = checkParameterData(PIDS2,'b',varargin{1});
                end
                if nargin >= 3
                    c = checkParameterData(PIDS2,'c',varargin{2});
                end
            catch E
                throw(E);
            end
            
            PID = make1DOF(PIDS2);
            PIDS2 = make2DOF(PID,b,c);
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
            D0 = ltipack.piddataS2(0,inf,0,inf,1,1,sys.Ts);
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
            % Constructs PIDSTD2 model from ltipack.piddataS2 instance
            sys = pidstd2;
            sys.Data_ = D;
        end
        
        function sys = convert(X)
            % Safe conversion to PIDSTD2.
            if isnumeric(X) || isa(X,'StaticModel')
                sys = pidstd2(tf(double(X)));
            else
                sys = pidstd2(X);
            end
        end
        
    end
    
end
