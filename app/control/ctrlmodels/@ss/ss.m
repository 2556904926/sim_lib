classdef (CaseInsensitiveProperties, TruncatedProperties, SupportExtensionMethods, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      ss < numlti & StateSpaceModel
   %SS  State-space models.
   %
   %  Construction:
   %    SYS = SS(A,B,C,D) creates an object SYS representing the continuous- 
   %    time state-space model
   %         dx/dt = Ax(t) + Bu(t)
   %          y(t) = Cx(t) + Du(t)
   %    You can set D=0 to mean the zero matrix of appropriate size. SYS is 
   %    of type SS when A,B,C,D are dense numeric arrays, of type GENSS when 
   %    A,B,C,D depend on tunable parameters (see REALP and GENMAT), and 
   %    of type USS when A,B,C,D are uncertain matrices (requires Robust 
   %    Control Toolbox). Use SPARSS when A,B,C,D are sparse matrices.
   %
   %    SYS = SS(A,B,C,D,Ts) creates a discrete-time state-space model with
   %    sample time Ts (set Ts=-1 if the sample time is undetermined).
   %
   %    SYS = SS(D) specifies a static gain matrix D.
   %
   %    You can set additional model properties by using name/value pairs.
   %    For example,
   %       sys = ss(-1,2,1,0,'InputDelay',0.7,'StateName','position')
   %    also sets the input delay and the state name. Type "properties(ss)" 
   %    for a complete list of model properties, and type 
   %       help ss.<PropertyName>
   %    for help on a particular property. For example, "help ss.StateName" 
   %    provides information about the "StateName" property.
   %
   %  Arrays of state-space models:
   %    You can create arrays of state-space models by using ND arrays for
   %    A,B,C,D. The first two dimensions of A,B,C,D define the number of 
   %    states, inputs, and outputs, while the remaining dimensions specify 
   %    the array sizes. For example,
   %       sys = ss(rand(2,2,3,4),[2;1],[1 1],0)
   %    creates a 3x4 array of SISO state-space models. You can also use
   %    indexed assignment and STACK to build SS arrays:
   %       sys = ss(zeros(1,1,2))     % create 2x1 array of SISO models
   %       sys(:,:,1) = rss(2)        % assign 1st model
   %       sys(:,:,2) = ss(-1)        % assign 2nd model
   %       sys = stack(1,sys,rss(5))  % add 3rd model to array
   %
   %  Conversion:
   %    SYS = SS(SYS) converts any dynamic system SYS to the state-space 
   %    representation. The resulting model SYS is always of class SS.
   %
   %    SYS = SS(SYS,'min') computes a minimal realization of SYS.
   %
   %    SYS = SS(SYS,'explicit') computes an explicit realization (E=I) of SYS.
   %    An error is thrown if SYS is improper.
   %
   %    See also DSS, DELAYSS, RSS, DRSS, SPARSS, MECHSS, SSDATA, TF, ZPK, FRD, GENSS, USS, DYNAMICSYSTEM.
   
%   Author(s): A. Potvin, P. Gahinet
%   Copyright 1986-2024 The MathWorks, Inc.
   
   % Add static method to be included for compiler
   %#function ltipack.utValidateTs
   %#function ss.loadobj
   %#function ss.make
   %#function ss.convert
   %#function ss.checkABCDE

   % Public properties with restricted value
   properties (Access = public, Dependent)
      % State matrix A.
      %
      % Set this property to a square matrix with as many rows as states, for 
      % example, sys.a = [-1 3;0 -5] for a second-order model "sys".
      A
      % Input-to-state matrix B.
      %
      % Set this property to a matrix with as many rows as states and as many   
      % columns as inputs, for example, sys.b = [0;1] for a single-input, 
      % second-order system "sys".
      B
      % State-to-output matrix C.
      %
      % Set this property to a matrix with as many rows as outputs and as many   
      % columns as states, for example, sys.c = [1 -1] for a single-output, 
      % second-order system "sys".
      C
      % Feedthrough matrix D.
      %
      % Set this property to a matrix with as many rows as outputs and as many   
      % columns as inputs, for example, sys.d = [1 0] for a single-output, 
      % two-input system "sys".
      D
      % E matrix for implicit (descriptor) state-space models.
      %
      % By default E=[], meaning that the state equation is explicit. To 
      % specify an implicit state equation E dx/dt = A x + B u, set this
      % property to a square matrix of the same size as A. Note that E
      % may be singular, for example, when modeling a pure derivative
      % element in state-space form. See DSS for more details on descriptor
      % state-space models.
      E
      % Offsets (default = none).
      %
      % Set this property to a struct with fields u,y,x,dx specifying the 
      % input, output, state, and state derivative offsets. Offsets usually
      % arise when linearizing nonlinear dynamics at some operating condition.
      % By default Offsets=[] to mean no offsets.
      Offsets
      % Enables/disables auto-scaling (logical, default = false).
      %
      % When Scaled=false, most numerical algorithms acting on this system
      % automatically rescale the state vector to improve numerical accuracy.
      % You can disable such auto-scaling by setting Scaled=true. See PRESCALE
      % for more details on scaling issues.
      Scaled
      % State names (cell array of char vectors, default = '' for all states).
      %
      % This property can be set to:
      %  * A char vector for first-order models, for example, 'position'
      %  * A cell array of char vectors for models with two or more states,
      %    for example, {'position' ; 'velocity'}
      % Use the empty char array '' for unnamed states.
      StateName
      % State paths (cell array of char vectors, default = '' for all states).
      %
      % In the linearization of a Simulink model, each state originates from
      % a particular Simulink block, and this property gives the full pathname
      % of the block associated with each state.
      StatePath
      % State units (cell array of char vectors, default = '' for all states).
      %
      % Use this property to keep track of the units each state is expressed in.
      % It can be set to:
      %  * A char vector for first-order models, for example, 'm/s'
      %  * A cell array of char vectors for models with two or more states,
      %    for example, {'m' ; 'm/s'}
      StateUnit
      % Internal delays (numeric vector, default = []).
      %
      % Internal delays arise, for example, when closing feedback loops with
      % delays or connecting delay systems in series or parallel. See the
      % documentation for details. For continuous-time systems, internal delays
      % are expressed in the time unit specified by the "TimeUnit" property.
      % For discrete-time systems, internal delays are expressed as integer
      % multiples of the sampling period "Ts", for example, InternalDelay=3
      % means a delay of three sampling periods.
      %
      % You can modify the values of internal delays but the number of entries
      % in sys.InternalDelay cannot change (structural property of the model).
      InternalDelay
   end
   
   % OBSOLETE PROPERTIES
   properties (Access = public, Dependent, Hidden)
      % Obsolete property for state-space models.
      IODelayMatrix
   end
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'ss';
      end

      function T = superiorTypes()
         T = {'ss'};
      end
      
      function A = getAttributes(A)
         % Override default attributes
         A.Varying = false;
         A.Structured = false;
         A.FRD = false;
         A.Sparse = false;
      end
      
      function T = toStructured()
         % Use virtual class to ensure op(ss,uss)=uss
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
   
   
   methods
      
      function sys = ss(varargin)
         ni = nargin;
         % Handle conversion SS(SYS) where SYS is a class with constructor named "ss"
         % (no ss() converter can be defined for such class)
         if ni>0 && isa(varargin{1},'StateSpaceModel')
            sys0 = varargin{1};
            try
               switch ni
                  case 1
                     if isa(sys0,'ss')  % Optimization for SYS of class @ss
                        sys = sys0;
                     else
                        sys = copyMetaData(sys0,ss_(sys0)); % e.g., ltiblock.ss
                     end
                  case 2
                     optflag = ltipack.matchKey(varargin{2},{'minimal','explicit'});
                     sys = copyMetaData(sys0,ss_(sys0,optflag));
                  otherwise
                     error(message('Control:ltiobject:construct1','ss'))
               end
               return
            catch ME
               throw(ME)
            end
         end
         
         % Dissect input list
         DataInputs = 0;
         LtiInput = 0;
         PVStart = ni+1;
         for ct=1:ni
            nextarg = varargin{ct};
            if isa(nextarg,'struct') || isa(nextarg,'lti')
               % LTI settings inherited from other model
               LtiInput = ct;   PVStart = ct+1;   break
            elseif ischar(nextarg) || isStringScalar(nextarg)
               PVStart = ct;   break
            else
               DataInputs = DataInputs+1;
            end
         end
         
         % Handle bad calls
         if PVStart==1
            if ni==1
               % Bad conversion
               error(message('Control:ltiobject:construct3','ss'))
            elseif ni>0
               error(message('Control:general:InvalidSyntaxForCommand','ss','ss'))
            end
         elseif DataInputs>5
            error(message('Control:general:InvalidSyntaxForCommand','ss','ss'))
         end
         
         % Process numerical data
         try
            switch DataInputs
               case 0
                  if ni
                     error(message('Control:ltiobject:construct4','ss'))
                  else
                     % Empty model
                     a = [];  b = [];  c = [];  d = [];
                  end
               case 1
                  % Gain matrix
                  a = [];
                  d = ss.checkABCDE(varargin{1},'D');
                  [Ny,Nu,~] = size(d);
                  b = zeros(0,Nu);
                  c = zeros(Ny,0);
                  % Optimization for fast pre-allocation
                  CheckData = ~allfinite(d);
                  % Handle ss(1,'explicit')
                  if ni==2 && ~isempty(ltipack.matchKey(varargin{2},{'minimal','explicit'}))
                     ni = ni-1;  % ignore flag
                  end
               case {2,3}
                  error(message('Control:general:InvalidSyntaxForCommand','ss','ss'))
               otherwise
                  % A,B,C,D specified: validate data
                  a = ss.checkABCDE(varargin{1},'A');
                  b = ss.checkABCDE(varargin{2},'B');
                  c = ss.checkABCDE(varargin{3},'C');
                  d = ss.checkABCDE(varargin{4},'D');
                  CheckData = true;
            end
            
            % Sample time
            if DataInputs==5
               % Discrete SS
               Ts = ltipack.utValidateTs(varargin{5});
            else
               Ts = 0;
            end
         catch ME
            throw(ME)
         end
         
         % Determine I/O and array size
         if ni>0
            Ny = max(size(c,1),size(d,1));
            Nu = max(size(b,2),size(d,2));
            ArraySize = ltipack.getLTIArraySize(2,a,b,c,d);
            if isempty(ArraySize)
               error(message('Control:ltiobject:ss1'))
            end
         else
            Ny = 0;  Nu = 0;  ArraySize = [1 1];
         end
         Nsys = prod(ArraySize);
         sys.IOSize_ = [Ny Nu];
         
         % Create @ssdata object array
         % RE: Inlined for optimal speed
         if Nsys==1
            Data = ltipack.ssdata(a,b,c,d,[],Ts);
         else
            Data = createArray(ArraySize,'ltipack.ssdata');
            Delay = ltipack.utDelayStruct(Ny,Nu,true);
            for ct=1:Nsys
               Data(ct) = ltipack.ssdata(a(:,:,min(ct,end)),b(:,:,min(ct,end)),...
                  c(:,:,min(ct,end)),d(:,:,min(ct,end)),[],Ts); 
               Data(ct).Delay = Delay;
            end
         end
         sys.Data_ = Data;
         
         % Process additional settings and validate system
         % Note: Skip when just constructing empty instance for efficiency
         if ni>0
            try
               % User-defined properties
               Settings = cell(1,0);
               if LtiInput
                  % Properties inherited from other system
                  arg = varargin{LtiInput};
                  if isa(arg,'lti')
                     arg = getSettings(arg);
                  end
                  % @ss does not inherit internal delays (including IODelay)
                  arg = rmfield(arg,intersect(fieldnames(arg),{'IODelay','FrequencyUnit'}));
                  Settings = [Settings , lti.struct2pv(arg)];
               end
               [pvpairs,iodSettings] = LocalCheckDelaySettings(varargin(:,PVStart:ni));
               Settings = [Settings , pvpairs];
               
               % Apply settings except IODelay
               if ~isempty(Settings)
                  sys = fastSet(sys,Settings{:});
               end
               
               % Consistency check
               if CheckData || ~isempty(Settings)
                  sys = checkConsistency(sys);
               end
               
               % I/O delay settings. Must be done after data checks to prevent errors in
               % setIODelay when A,B,C are not properly formatted (e.g., A=B=C=[] and D=1)
               if ~isempty(iodSettings)
                  sys = fastSet(sys,iodSettings{:});
               end
            catch ME
               throw(ME)
            end
         end
      end
      
      %---------------- GET/SET ------------------------------------------
      
      function Value = get.A(sys)
         % GET method for a property
         Value = localGetABCDE(sys.Data_,'a',[0,0]);
      end
      
      function Value = get.B(sys)
         % GET method for b property
         Value = localGetABCDE(sys.Data_,'b',[0,sys.IOSize_(2)]);
      end
      
      function Value = get.C(sys)
         % GET method for c property
         Value = localGetABCDE(sys.Data_,'c',[sys.IOSize_(1),0]);
      end
      
      function Value = get.D(sys)
         % GET method for d property
         Value = localGetABCDE(sys.Data_,'d',sys.IOSize_);
      end
      
      function Value = get.E(sys)
         % GET method for e property
         Value = localGetABCDE(sys.Data_,'e',[0,0]);
      end
      
      function sys = set.A(sys,Value)
         % SET method for a property
         sys = localSetABCDE(sys,'a',Value);
      end
      
      function sys = set.B(sys,Value)
         % SET method for b property
         sys = localSetABCDE(sys,'b',Value);
      end
      
      function sys = set.C(sys,Value)
         % SET method for c property
         sys = localSetABCDE(sys,'c',Value);
      end
      
      function sys = set.D(sys,Value)
         % SET method for d property
         sys = localSetABCDE(sys,'d',Value);
      end
      
      function sys = set.E(sys,Value)
         % SET method for e property (cannot change state size)
         Value = ss.checkABCDE(Value,'E');
         Data = ltipack.utCheckAssignValueSize(sys.Data_,Value,2);
         for ct=1:numel(Data)
            Data(ct).e = Value(:,:,min(ct,end));
            if sys.CrossValidation_
               Data(ct) = checkData(Data(ct));  % Quick validation
            end
         end
         sys.Data_ = Data;
      end
      
      function Value = get.Offsets(sys)
         % GET method for Offsets property
         Value = getOffsets(sys.Data_);
      end

      function sys = set.Offsets(sys,Value)
         % SET method for Offsets property
         try
            sys.Data_ = setOffsets(sys.Data_,Value,sys.CrossValidation_,true);
         catch ME
            throw(ME)
         end
      end

      function Value = get.Scaled(sys)
         % GET method for Scaled property
         % True if all models are scaled, false otherwise
         Value = true;
         Data = sys.Data_;
         for ct=1:numel(Data)
            if ~Data(ct).Scaled
               Value = false;  break
            end
         end
      end
      
      function sys = set.Scaled(sys,Value)
         % SET method for Scaled property
         if ~(isscalar(Value) && (islogical(Value) || isnumeric(Value)))
            error(message('Control:ltiobject:setSS4'))
         end
         Value = logical(Value);
         Data = sys.Data_;
         for ct=1:numel(Data)
            Data(ct).Scaled = Value;
         end
         sys.Data_ = Data;
      end
      
      function Value = get.StateName(sys)
         % GET method for StateName property
         Value = cellstr(ltipack.SystemArray.getStateInfo(sys.Data_,'StateName'));
      end
      
      function Value = get.StatePath(sys)
         % GET method for StatePath property
         Value = cellstr(ltipack.SystemArray.getStateInfo(sys.Data_,'StatePath'));
      end
      
      function Value = get.StateUnit(sys)
         % GET method for StateUnit property
         Value = cellstr(ltipack.SystemArray.getStateInfo(sys.Data_,'StateUnit'));
      end
      
      function sys = set.StateName(sys,Value)
         % SET method for StateName property
         Data = sys.Data_;
         nsys = numel(Data);
         if nsys>0
            Value = ltipack.mustBeStringVector(Value,'StateName',false);
            nx = size(Data(1).a,1);
            for ct=1:nsys
               if size(Data(ct).a,1)~=nx
                  % Not supported for varying state dimension
                  error(message('Control:ltiobject:setSS2'))
               end
            end
            for ct=1:nsys
               Data(ct).StateName = Value;
               if sys.CrossValidation_
                  Data(ct) = checkData(Data(ct));
               end
            end
            sys.Data_ = Data;
         end
      end
      
      function sys = set.StatePath(sys,Value)
         % SET method for StatePath property
         Data = sys.Data_;
         nsys = numel(Data);
         if nsys>0
            Value = ltipack.mustBeStringVector(Value,'StatePath',false);
            % Replace carriage returns by blanks
            Value = regexprep(Value,'\n',' ');
            nx = size(Data(1).a,1);
            for ct=1:nsys
               if size(Data(ct).a,1)~=nx
                  % Not supported for varying state dimension
                  error(message('Control:ltiobject:setSS2'))
               end
            end
            for ct=1:nsys
               Data(ct).StatePath = Value;
               if sys.CrossValidation_
                  Data(ct) = checkData(Data(ct));
               end
            end
            sys.Data_ = Data;
         end
      end
      
      function sys = set.StateUnit(sys,Value)
         % SET method for StateUnit property
         Data = sys.Data_;
         nsys = numel(Data);
         if nsys>0
            Value = ltipack.mustBeStringVector(Value,'StateUnit',false);
            nx = size(Data(1).a,1);
            for ct=1:nsys
               if size(Data(ct).a,1)~=nx
                  % Not supported for varying state dimension
                  error(message('Control:ltiobject:setSS5'))
               end
            end
            for ct=1:nsys
               Data(ct).StateUnit = Value;
               if sys.CrossValidation_
                  Data(ct) = checkData(Data(ct));
               end
            end
            sys.Data_ = Data;
         end
      end
      
      function Value = get.InternalDelay(sys)
         % GET method for InternalDelay property
         Data = sys.Data_;
         Nsys = numel(Data);
         if Nsys==0
            Value = zeros(0,1);
         elseif Nsys==1 
            Value = Data.Delay.Internal;
         else
            RefValue = Data(1).Delay.Internal;
            ndf = length(RefValue);
            Value = zeros([ndf 1 size(Data)]);
            isUniform = true;
            for ct=1:Nsys
               Df = Data(ct).Delay.Internal;
               isUniform = isUniform && isequal(Df,RefValue);
               if length(Df)==ndf
                  Value(:,ct) = Df;
               else
                  error(message('Control:ltiobject:get5'))
               end
            end
            if isUniform
               Value = Value(:,1);
            end
         end
      end
      
      function sys = set.InternalDelay(sys,Value)
         % SET method for InternalDelay property
         if ~(isnumeric(Value) && isreal(Value) && allfinite(Value) && all(Value(:)>=0))
            error(message('Control:ltiobject:setLTI1','InternalDelay'))
         else
            Value = double(full(Value));
         end
         Data = ltipack.utCheckAssignValueSize(sys.Data_,Value,2);
         for ct=1:numel(Data)
            NewValue = Value(:,:,min(ct,end));
            if numel(NewValue)~=numel(Data(ct).Delay.Internal)
               error(message('Control:ltiobject:setSS3'))
            elseif sys.CrossValidation_
               Data(ct).Delay.Internal = ...
                  ltipack.util.checkInternalDelay(NewValue,Data(ct).Ts);
            else
               Data(ct).Delay.Internal = NewValue;
            end
         end
         sys.Data_ = Data;
      end            
      
      function Value = get.IODelayMatrix(sys)
         % GET method for IODelay property
         Value = getIODelay(sys);
      end
      
      function sys = set.IODelayMatrix(sys,Value)
         % SET method for IODelay property
         sys = setIODelay(sys,Value);
      end
      
   end
   
   
   methods (Hidden)

      function sys = setLPVOffsets(sys,Value)
         % For LPV block, allow offset specification for models with
         % internal delays (for backward compatibility)
         sys.Data_ = setOffsets(sys.Data_,Value,sys.CrossValidation_,false);
      end
      
      function sys = utSimplifyDelay(sys)
         % Replaces internal delays by input or output delays when possible
         % (used by SCD)
         sys.Data_ = simplifyDelay(sys.Data_);
      end
      
      function [sys,isProper] = ioderiv(sys,r)
         % Multiplies SYS by (s+r) or (z+r)  (used by PID tool)
         [sys.Data_,isProper] = ioderiv(sys.Data_,r);
      end
      
      function sys = augmentMPCPlantModel(sys, b)
         % Add an "offset" signal to the plant model used by MPC object
         [ny, nu] = size(sys);
         data = sys.Data_;
         data = utGrowIO(data, ny, nu+1);
         data.b(:, nu+1) = b;
         sys.Data_ = data;
      end
      
      function [a,b1,b2,c1,c2,d11,d12,d21,d22,Ts] = titodata(P,nY,nU)
         % Extract data for two-input, two-output system
         %    [y1;y2] = D * [u1;u2]
         % NY and NU are the sizes of y2 and u2.
         Dss = P.Data_;
         [a,b1,b2,c1,c2,d11,d12,d21,d22] = titodata(Dss,nY,nU);
         Ts = Dss.Ts;
      end
      
      % MUSYN support
      function P = sector2gain(P,F,ny,nu)
         % Transforms the problem
         %
         %    Find K such that [T1(jw);I]' Q(jw) [T1(jw);I] < 0,   T1 = LFT(P1,K)
         %
         % into the HINFSYN problem
         %
         %    Find K such that || T2 ||oo < 1 , T2 = LFT(P2,K) .
         %
         % T2 is related to T1 by
         %
         %    T2 = Z1/Z2,   [Z1;Z2] = F [T1;I]
         %
         % where
         %
         %    Q(s) = F(s)' J F(s),  J = diag(I,-I),  F bi-stable
         %
         % is the J-spectral factorization of Q.
         P.Data_ = sector2gain(P.Data_,F.Data_,ny,nu);
      end

      % MOR API
      function BalInfo = runBT(sys,Options)
         % Called by PROCESS
         BalInfo = hsvd(sys.Data_,Options);
      end

      function ModalInfo = runMT(sys,Options)
         % Called by PROCESS
         ModalInfo = modsepMOR(sys.Data_,Options);
      end

   end
   
      
   methods (Access = protected)
      
      function boo = isLinear_(sys)
         % Not linear when with offsets.
         boo = true;
         Data = sys.Data_;
         for ct=1:numel(Data)
            if hasOffset(Data(ct))
               boo = false;  return
            end
         end
      end

      %% INPUTOUTPUTMODEL ABSTRACT INTERFACE
      function displaySize(sys,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         nx = order(sys);
         if isempty(nx)
            nx = 0;
         end
         if length(sizes)==2
            disp(getString(message('Control:ltiobject:SizeSS1',ny,nu,nx)))
         else
            ArrayDims = sprintf('%dx',sizes(3:end));
            if all(nx(:)==nx(1))
               disp(getString(message('Control:ltiobject:SizeSS2',...
                  ArrayDims(1:end-1),ny,nu,nx(1))))
            else
               disp(getString(message('Control:ltiobject:SizeSS3',...
                  ArrayDims(1:end-1),ny,nu,min(nx(:)),max(nx(:)))))
            end
         end
      end
      
      %% DATA ABSTRACTION INTERFACE
      function sys = indexasgn_(sys,indices,rhs,ioSize,ArrayMask)
         % Data management in SYS(indices) = RHS.
         % ioSize is the new I/O size and ArrayMask tracks which
         % entries in the resulting system array have been reassigned.

         % Construct template initial value for new entries in system array
         D0 = ltipack.ssdata([],zeros(0,ioSize(2)),zeros(ioSize(1),0),...
            zeros(ioSize),[],sys.Ts);
         % Update data
         sys.Data_ = ltipack.reassignData(sys.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
      end
       
      function [rsys,Info] = balred_(sys,orders,Info,Options)
         % BALRED support (obsolete)
         R = reducespec(sys,'balanced');
         R.Options = mapOptions(R.Options,Options);
         if isempty(Info)
            R = process(R);
         else
            R = setBalredInfo(R,Info);
         end
         rsys = getrom(R,Order=orders,Method=Options.StateProjection);
         Info = getBalredInfo(R);
      end

      function [sys,nx] = augstate_(sys)
         [sys,nx] = augstate_@ltipack.SystemArray(sys);
         sys = augmentOutput(sys,sys.StateName,sys.StateUnit,'states');
      end

      function sys = augoffset_(sys)
         sys = augoffset_@ltipack.SystemArray(sys);
         sys = augmentInput(sys,{'offset'},{''});
      end

      function [sys,varargout] = c2d_(sys,Ts,options)
         no = nargout;
         Data = sys.Data_;
         if ~isempty(Data) && strcmp(options.Consistency,'on') && any(options.Method(1)=='zfit')
            % Enforce state and delay consistency
            sys.Data_ = c2dXC(Data,Ts,options);
            varargout = cell(1,no-1);
         else
            [sys,varargout{1:no-1}] = c2d_@ltipack.SystemArray(sys,Ts,options);
         end
      end

      function [sys,varargout] = d2c_(sys,options)
         no = nargout;
         Data = sys.Data_;
         if ~isempty(Data) && strcmp(options.Consistency,'on') && any(options.Method(1)=='zft')
            sys.Data_ = d2cXC(Data,options);
            varargout = cell(1,no-1);
         else
            [sys,varargout{1:no-1}] = d2c_@ltipack.SystemArray(sys,options);
         end
      end

      function sys = d2d_(sys,Ts,options)
         Data = sys.Data_;
         if ~isempty(Data) && strcmp(options.Consistency,'on') && any(options.Method(1)=='zt')
            sys.Data_ = d2dXC(Data,Ts,options);
         else
            sys = d2d_@ltipack.SystemArray(sys,Ts,options);
         end
      end

      vsys = ssInterpolant_(asys,offsets,varargin)

   end
   
   %% STATIC METHODS
   methods(Static, Hidden)
      
      sys = loadobj(s)

      function sys = make(D,IOSize)
         % Constructs SS model from ltipack.ssdata instance
         sys = ss;
         sys.Data_ = D;
         if nargin>1
            sys.IOSize_ = IOSize;  % support for empty model arrays
         else
            sys.IOSize_ = iosize(D(1));
         end
      end
      
      function sys = convert(X,varargin)
         % Safe conversion to SS.
         %
         %   X = SS.CONVERT(X) safely converts the variable X to SS even when
         %   X is a static model (in which case SS(X) returns a GENSS or USS 
         %   model rather than an SS model). This method is used in indexed 
         %   assignments and conversions from LTIBLOCK.SS to SS.
         %   
         %   X = SS.CONVERT(X,OPT) further specifies an option for the
         %   DynamicSystem/ss converter.
         if isnumeric(X) || isa(X,'StaticModel')
            % Work around ss(GENMAT) yielding a GENSS
            sys = ss(double(X));
         elseif isa(X,'DynamicSystem')
            % DynamicSystem subclass
            sys = copyMetaData(X,ss_(X,varargin{:}));
         else
            error(message('Control:transformation:ss2',class(X)))
         end
      end
      
      function C = makeC(C,TU)
         % Applies ss.make to each entry of the cell array C.
         % Used by uncertainty analysis functions
         for ct=1:numel(C)
            V = C{ct};
            if isa(V,'ltipack.ssdata')
               C{ct} = setTimeUnit_(ss.make(V),TU);
            end
         end
      end

      function S = makeS(S,TU)
         % Applies ss.make to each field of a struct array S.
         % Used by uncertainty analysis functions
         S = cell2struct(ss.makeC(struct2cell(S),TU),fieldnames(S),1);
      end
            
      function M = checkABCDE(M,MatrixName)
         % Checks A,B,C,D,E data is of proper type
         if isnumeric(M)
            if ~(strcmp(MatrixName,'D') || allfinite(M))
               error(message('Control:ltiobject:ssProperties6',MatrixName))
            end
            % Convert to full double
            if issparse(M)
               warning(message('Control:ltiobject:SSSparse2Full',MatrixName))
               M = full(M);
            end
            M = double(M);
         elseif ~isa(M,'StaticModel')
            if isa(M,'InputOutputModel')
               error(message('Control:lftmodel:ss1',MatrixName))
            else
               error(message('Control:ltiobject:ssProperties6',MatrixName))
            end
         end
      end

      % MOR API
      function [rsys,INFO] = reduceMT_(ModalInfo,select,MatchDC)
         % Called by GETROM
         if isa(ModalInfo,'mor.util.ModalDecompositionCache')
            % Select modal components
            MC = ModalInfo.Component(select,:);
            d = ModalInfo.Feedthrough;
            if isempty(MC)
               [ny,nu] = size(d);
               Dr = ltipack.ssdata([],zeros(0,nu),zeros(ny,0),zeros(ny,nu),[],ModalInfo.Ts);
            else
               Dr = modsum(MC);
            end
            if MatchDC
               s = ModalInfo.DCFrequency;  % complex
               X = ModalInfo.Component(~select);
               for ct=1:numel(X)
                  d = d + evalfr(X(ct),s);
               end
               if ~allfinite(d)
                  error(message('Control:transformation:MODALROM18'))
               end
            end
            Dr.d = d;
            jsel = getSelectedCol(ModalInfo,select);
            INFO = struct('PL',ModalInfo.TL(:,jsel),'PR',ModalInfo.TR(:,jsel));
         else
            % Modal split
            G = ModalInfo.SchurQZ;
            p = ModalInfo.Mode;
            e = p(select,:);
            % For real problems, selected modes should be self-conjugate
            if ModalInfo.REAL && ~isequal(sort(e(imag(e)>0)),sort(conj(e(imag(e)<0))))
               error(message('Control:transformation:MODALROM20'))
            end
            % Perform split
            RegionFcn = @(p) 2-(ismember(p,e));
            [H,~,Info2] = modsepREG(G,2,RegionFcn,ltioptions.modalsep);
            Dr = H(1);
            % Adjust feedthrough
            if MatchDC
               DCcorr = evalfr(H(2),ModalInfo.DCFrequency);
               if ~allfinite(DCcorr)
                  error(message('Control:transformation:MODALROM18'))
               end
               Dr.d = G.d + DCcorr;
            else
               Dr.d = G.d;
            end
            % Projectors
            PL = ModalInfo.TL*Info2.TL';
            PR = ModalInfo.TR*Info2.TR;
            nsel = numel(e);
            INFO = struct('PL',PL(:,1:nsel),'PR',PR(:,1:nsel));
         end
         rsys = ss.make(Dr);
      end
	
      %CODER REDIRECT TO CAPTURE USAGE OF SS IN CODEGEN      
      function name = matlabCodegenRedirect(~)
          name = 'coder.internal.ss';
      end
   end   
end
   
   
%--------------------- Local Functions --------------------------------

function [pvp,iodpvp] = LocalCheckDelaySettings(pvp)
% Pulls out IODelay settings, throws error when setting InternalDelays
if any(strncmpi(pvp(1:2:end),'int',3))
    error(message('Control:ltiobject:ss2'))
end
idx = find(strncmpi(pvp(1:2:end),'io',2));
iodpvp = cell(1,0);
for ct=length(idx):-1:1
   k = 2*idx(ct)-1;
   iodpvp = [iodpvp , pvp(k:min(k+1:end))]; %#ok<AGROW>
   pvp = [pvp(1:k-1) , pvp(k+2:end)];
end
end


function Value = localGetABCDE(Data,ABCDE,DefaultSize)
% Return nominal values of A, B, C, D, or E
tmp = cell(1,6);
iselect = find(ABCDE=='abcd e');
ArraySize = size(Data);
if isempty(Data)
   % Empty array
   Value = zeros([DefaultSize,ArraySize]);
elseif isscalar(Data)
   [tmp{:}] = getABCDE(Data);
   Value = tmp{iselect};
else
   ValueArray = cell(ArraySize);
   for ct=1:numel(Data)
      [tmp{:}] = getABCDE(Data(ct));
      ValueArray{ct} = tmp{iselect};
   end
   % Replace E=[] by identity of proper size if some E's are non-empty
   if strcmp(ABCDE,'e') && ~all(cellfun(@isempty,ValueArray(:)))
      for ct=1:numel(Data)
         if isempty(ValueArray{ct})
            ValueArray{ct} = eye(size(Data(ct).a));
         end
      end
   end
   % Turn into ND array
   try
      Value = cat(3,ValueArray{:});
      Value = reshape(Value,[size(Value,1) size(Value,2) ArraySize]);
   catch %#ok<CTCH>
       % A,B,C,E cannot be represented as ND arrays
       error(message('Control:ltiobject:get4',upper(ABCDE)))
   end
end 
end


%%%%%%%%
function sys = localSetABCDE(sys,Property,Value)
% SET function for A,B,C,D
Value = ss.checkABCDE(Value,upper(Property));
% Check compatibility of RHS with model array sizes
Data = ltipack.utCheckAssignValueSize(sys.Data_,Value,2);
sv = size(Value);
SameSize = (~isempty(Data) && isequal(sv(1:2),size(Data(1).(Property))));
for ct=1:numel(Data)
   if isempty(Data(ct).Delay.Internal)
      Data(ct).(Property) = Value(:,:,min(ct,end));
   else
      error(message('Control:ltiobject:setSS1',Property))
   end
   if SameSize && sys.CrossValidation_
      Data(ct) = checkData(Data(ct));  % Quick validation
   end
end
sys.Data_ = Data;
if ~SameSize && sys.CrossValidation_
   % Note: Full validation needed because a single assignment can change I/O size,
   % e.g., sys = ss; sys.a = [1 2;3 4]
   %       sys = ss(1); sys.d = [1 2;3 4]
   %       sys = ss(1,[],[],[]); sys.b = 1;
   sys = checkConsistency(sys);
end
end
