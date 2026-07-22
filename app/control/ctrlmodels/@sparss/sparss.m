classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      sparss < numlti & StateSpaceModel
   %SPARSS  Sparse state-space model.
   %
   %  Construction:
   %    SYS = SPARSS(A,B,C,D,E) creates an object SYS representing the 
   %    continuous-time state-space model
   %        E dx/dt = Ax(t) + Bu(t)
   %           y(t) = Cx(t) + Du(t)
   %    where x(t) denotes the state vector (vector of generalized degrees
   %    of freedom). You can set D=0 to mean the zero matrix of appropriate 
   %    size. The A,B,C,D,E matrices are stored as sparse double arrays. 
   %    When omitted, E defaults to the identity matrix.
   %
   %    SYS = SPARSS(A,B,C,D,E,Ts) creates a discrete-time state-space model 
   %    with sample time Ts (set Ts=-1 if the sample time is undetermined).
   %    When E is the identity matrix, you can set E=[] or omit E as long 
   %    as A is not a scalar.
   %
   %    SYS = SPARSS(D) specifies a static gain matrix D.
   %
   %    Type "properties(sparss)" for a list of model properties, and type 
   %       help sparss.<PropertyName>
   %    for help on specific property. For example, "help sparss.InputDelay" 
   %    has details about the "InputDelay" property. Use the "SolverOptions"
   %    property to configure numerical computation involving SYS, see
   %    sparssOptions for details.
   %
   %  Arrays of sparse state-space models:
   %    You can create arrays of sparse state-space models using indexed
   %    assignment or the STACK function. For example,
   %       sys = sparss(zeros(1,1,2))   % create 2x1 array of models
   %       sys(:,:,1) = sparss(A,B,C,D) % assign 1st model
   %       sys(:,:,2) = MDL2            % assign 2nd model
   %       sys = stack(1,sys,MDL3)      % add 3rd model to array
   %
   %  Conversion:
   %    SYS = SPARSS(SYS) converts any dynamic system SYS to SPARSS. For a 
   %    MECHSS model with displacement q and nonsingular mass matrix M, 
   %    the SPARSS equivalent has state x(t) = [q(t);q'(t)] or 
   %    x[k] = [q[k];q[k+1]]. Use GETX0 to map initial conditions from
   %    MECHSS to SPARSS.
   %
   %  See also MECHSS, STACK, SPARSSDATA, SPARSSOPTIONS, SHOWSTATEINFO, 
   %  MECHSS/GETX0, SS, FULL, DYNAMICSYSTEM.
   
%   Author(s): P. Gahinet
%   Copyright 2020 The MathWorks, Inc.
   
   % Add static method to be included for compiler
   %#function ltipack.utValidateTs
   %#function sparss.make
   %#function sparss.checkMatrix

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
      % State partition (struct array)
      %
      % Contains partition of the state vector into components, interfaces
      % between components, and internal signals connecting components.
      % Struct array with fields "Type", "Name", and "Size" (number of states).
      StateInfo
      % Solver options (struct)
      %
      % Configures options for model analysis, such as enabling parallel
      % computing or choosing a particular DAE solver. See SPARSSOPTIONS
      % for details.
      SolverOptions
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
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'sparss';
      end

      function T = superiorTypes()
         T = {'sparss','mechss'};
      end
      
      function A = getAttributes(A)
         % Override default attributes
         A.Varying = false;
         A.Structured = false;
         A.FRD = false;
      end
      
      function T = toStructured()
         error(message('Control:combination:Sparse2'))
      end
      
      function T = toVarying()
         error(message('Control:combination:Sparse3'))
      end

      function T = toFRD()
         T = 'frd';
      end
      
   end
   
   
   methods
      
      function sys = sparss(varargin)
         ni = nargin;
         % Handle conversion SPARSS(SYS) where SYS is already SPARSS
         if ni>0 && isa(varargin{1},'sparss')
            if ni>1
               error(message('Control:ltiobject:construct1','sparss'))
            end
            sys = varargin{1};
            return
         end
         % Handle conversion SPARSS(ND ARRAY)
         if ni==1 && isnumeric(varargin{1}) && ~ismatrix(varargin{1})
            sys = sparss(ss(varargin{1}));
            return
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
               error(message('Control:ltiobject:construct3','sparss'))
            elseif ni>0
               error(message('Control:general:InvalidSyntaxForCommand','sparss','sparss'))
            end
         elseif DataInputs>6
            error(message('Control:general:InvalidSyntaxForCommand','sparss','sparss'))
         end
         
         % Process numerical data
         e = [];  Ts = 0;
         try
            switch DataInputs
               case 0
                  % Empty model
                  a = sparse(0,0);  b = sparse(0,0);
                  c = sparse(0,0);  d = sparse(0,0);
               case 1
                  % Gain matrix
                  a = sparse(0,0);  
                  d = sparss.checkMatrix(varargin{1},'D');
                  [Ny,Nu,~] = size(d);
                  b = sparse(0,Nu);
                  c = sparse(Ny,0);
                  % Optimization for fast pre-allocation
                  CheckData = ~allfinite(d);
               case {2,3}
                  error(message('Control:general:InvalidSyntaxForCommand','sparss','sparss'))
               case 4
                  % A,B,C,D specified: validate data
                  a = sparss.checkMatrix(varargin{1},'A');
                  b = sparss.checkMatrix(varargin{2},'B');
                  c = sparss.checkMatrix(varargin{3},'C');
                  d = sparss.checkMatrix(varargin{4},'D');
                  CheckData = true;
               case 5
                  a = sparss.checkMatrix(varargin{1},'A');
                  b = sparss.checkMatrix(varargin{2},'B');
                  c = sparss.checkMatrix(varargin{3},'C');
                  d = sparss.checkMatrix(varargin{4},'D');
                  if isscalar(varargin{5}) && ~isscalar(a)
                     Ts = ltipack.utValidateTs(varargin{5});
                  else
                     e = sparss.checkMatrix(varargin{5},'E');
                  end
                  CheckData = true;
               case 6
                  a = sparss.checkMatrix(varargin{1},'A');
                  b = sparss.checkMatrix(varargin{2},'B');
                  c = sparss.checkMatrix(varargin{3},'C');
                  d = sparss.checkMatrix(varargin{4},'D');
                  e = sparss.checkMatrix(varargin{5},'E');
                  Ts = ltipack.utValidateTs(varargin{6});
                  CheckData = true;
            end
         catch ME
            throw(ME)
         end
         
         % Determine I/O and array size
         if ni>0
            Ny = max(size(c,1),size(d,1));
            Nu = max(size(b,2),size(d,2));
         else
            Ny = 0;  Nu = 0; 
         end
         sys.IOSize_ = [Ny Nu];
         
         % Create @spssdata object array
         sys.Data_ = ltipack.spssdata(a,b,c,d,e,Ts);
         
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
                  % @sparss does not inherit internal delays (including IODelay)
                  arg = rmfield(arg,intersect(fieldnames(arg),{'IODelay','InternalDelay','FrequencyUnit'}));
                  Settings = [Settings , lti.struct2pv(arg)];
               end
               Settings = [Settings , varargin(:,PVStart:ni)];
               
               % Apply settings
               if ~isempty(Settings)
                  sys = fastSet(sys,Settings{:});
               end
               
               % Consistency check
               if CheckData || ~isempty(Settings)
                  sys = checkConsistency(sys);
               end
            catch ME
               throw(ME)
            end
         end
      end

      %---------------- GET/SET ------------------------------------------
      
      function Value = get.A(sys)
         Value = localGetABCDE(sys.Data_,'a',[0,0]);
      end      
      function Value = get.B(sys)
         Value = localGetABCDE(sys.Data_,'b',[0,sys.IOSize_(2)]);
      end
      function Value = get.C(sys)
         Value = localGetABCDE(sys.Data_,'c',[sys.IOSize_(1),0]);
      end
      function Value = get.D(sys)
         Value = localGetABCDE(sys.Data_,'d',sys.IOSize_);
      end
      function Value = get.E(sys)
         Value = localGetABCDE(sys.Data_,'e',[0,0]);
      end

      function sys = set.A(sys,Value)
         sys = localSetABCDE(sys,'a',Value);
      end
      function sys = set.B(sys,Value)
         sys = localSetABCDE(sys,'b',Value);
      end
      function sys = set.C(sys,Value)
         sys = localSetABCDE(sys,'c',Value);
      end
      function sys = set.D(sys,Value)
         sys = localSetABCDE(sys,'d',Value);
      end
      function sys = set.E(sys,Value)
         % SET method for e property (cannot change state size)
         Value = sparss.checkMatrix(Value,'E');
         Data = sys.Data_;
         for ct=1:numel(Data)
            if isempty(Data(ct).Delay.Internal)
               Data(ct).e = Value;
            else
               error(message('Control:ltiobject:setSS1','E'))
            end
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

      function S = get.StateInfo(sys)
         Data = sys.Data_;
         if isempty(Data)
            S = [];
         else
            S = Data(1).StateInfo;
            for ct=2:numel(Data)
               if ~isequal(Data(ct).StateInfo,S)
                  error(message('Control:ltiobject:sparss4'))
               end
            end
            Types = ["Component","Interface","Signal"];
            for ct=1:numel(S)
               S(ct).Type = Types(S(ct).Type);
            end
         end
      end
      
      function sys = set.StateInfo(sys,S)
         S = ltipack.util.checkStateInfo(S);
         if any(order(sys)~=sum([S.Size]),'all')
            error(message('Control:ltiobject:sparss5'))
         end
         Data = sys.Data_;
         for ct=1:numel(Data)
            Data(ct).StateInfo = S;
         end
         sys.Data_ = Data;
      end
      
      function S = get.SolverOptions(sys)
         Data = sys.Data_;
         if isempty(Data)
            S = [];
         else
            S = Data(1).SolverConfig;
            for ct=2:numel(Data)
               if ~isequal(Data(ct).SolverConfig,S)
                  error(message('Control:ltiobject:sparss12'))
               end
            end
         end
         if isempty(S)
            S = ltioptions.sparss;
         end
      end
      
      function sys = set.SolverOptions(sys,Value)
         if strcmp(class(Value),'ltioptions.sparss') %#ok<STISA>
            if isequal(Value,ltioptions.sparss)
               Value = [];  % storage optimization
            end
            Data = sys.Data_;
            for ct=1:numel(Data)
               Data(ct).SolverConfig = Value;
            end
            sys.Data_ = Data;
         else
            error(message('Control:ltiobject:sparss11','sparss'))
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
            % Array case: Only supported when uniform across models
            Value = Data(1).Delay.Internal;
            for ct=2:Nsys
               if ~isequal(Data(ct).Delay.Internal,Value)
                  error(message('Control:ltiobject:sparss10'))
               end
            end
         end
      end
      
      function sys = set.InternalDelay(sys,Value)
         % SET method for InternalDelay property
         if ~(isnumeric(Value) && isreal(Value) && all(Value>=0 & Value<Inf,'all'))
            error(message('Control:ltiobject:setLTI1','InternalDelay'))
         else
            Value = full(double(Value(:)));
         end
         Data = sys.Data_;
         for ct=1:numel(Data)
            if numel(Value)~=numel(Data(ct).Delay.Internal)
               error(message('Control:ltiobject:setSS3'))
            elseif sys.CrossValidation_
               Data(ct).Delay.Internal = ...
                  ltipack.util.checkInternalDelay(Value,Data(ct).Ts);
            else
               Data(ct).Delay.Internal = Value;
            end
         end
         sys.Data_ = Data;
      end            
      
   end
   
   
   methods (Hidden)
      
      function sys = utSimplifyDelay(sys)
         % Replaces internal delays by input or output delays when possible
         % (used by SCD)
         sys.Data_ = simplifyDelay(sys.Data_);
      end

      % MOR
      function BalInfo = runBT(sys,Options)
         % Called by PROCESS
         if ~isempty(Options.Rayleigh)
            error(message('Control:transformation:BALROM29'))
         end
         BalInfo = hsvd(sys.Data_,Options);
      end

      function boo = isFirstOrder(~)
         boo = true;
      end
      
   end
   
      
   methods (Access = protected)
      
      function boo = isSparse_(~)
         boo = true;
      end
            
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
            disp(getString(message('Control:ltiobject:SizeSPARSS1',ny,nu,nx)))
         else
            ArrayDims = sprintf('%dx',sizes(3:end));
            if all(nx(:)==nx(1))
               disp(getString(message('Control:ltiobject:SizeSPARSS2',...
                  ArrayDims(1:end-1),ny,nu,nx(1))))
            else
               disp(getString(message('Control:ltiobject:SizeSPARSS3',...
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
         ny = ioSize(1);  nu = ioSize(2);
         D0 = ltipack.spssdata([],sparse(0,nu),sparse(ny,0),sparse(ny,nu),[],sys.Ts);
         % Update data
         sys.Data_ = ltipack.reassignData(sys.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
      end
      
      %% TRANSFORMATIONS
      function [sys,nx] = augstate_(sys)
         [sys,nx] = augstate_@ltipack.SystemArray(sys);
         ES = repmat({''},[nx 1]);
         sys = augmentOutput(sys,ES,ES);
      end
      
      function sys = augoffset_(sys)
         sys = augoffset_@ltipack.SystemArray(sys);
         sys = augmentInput(sys,{'offset'},{''});
      end

      function fsys = full_(sys)
         Data = sys.Data_;
         fD = createArray(size(Data),'ltipack.ssdata');
         for ct=1:numel(Data)
            fD(ct) = full(Data(ct));
         end
         fsys = ss.make(fD);
         fsys.TimeUnit = sys.TimeUnit;
      end
      
      %% BINARY OPS
      function boo = hasCustomScalarMultiply_(~)
         % Supported for scalar A
         boo = true;
      end
            
      function sys = leftMultiplyByScalar_(sys,A)
         % Multiplies by a numeric matrix without adding extra states
         s = size(A);  s = [s ones(1,4-numel(s))];
         Data = sys.Data_;
         if (isscalar(A) || isequal(s(3:end),size(Data)))
            for ct=1:numel(Data)
               FACT = sparse(A(:,:,min(ct,end)));
               aux = FACT * Data(ct).d;
               if allfinite(aux)
                  Data(ct).c = FACT * Data(ct).c;
                  Data(ct).d = aux;
               else
                  Data(ct) = createGain(Data(ct),NaN(size(aux)));
               end
            end
            sys.Data_ = Data;
         else
            error(message('Control:combination:Sparse1'))
         end
      end
      
      function sys = rightMultiplyByScalar_(sys,A)
         % Multiplies by a numeric matrix without adding extra states
         s = size(A);  s = [s ones(1,4-numel(s))];
         Data = sys.Data_;
         if (isscalar(A) || isequal(s(3:end),size(Data)))
            for ct=1:numel(Data)
               FACT = sparse(A(:,:,min(ct,end)));
               aux = Data(ct).d * FACT;
               if allfinite(aux)
                  Data(ct).b = Data(ct).b * FACT;
                  Data(ct).d = aux;
               else
                  Data(ct) = createGain(Data(ct),NaN(size(aux)));
               end
            end
            sys.Data_ = Data;
         else
            error(message('Control:combination:Sparse1'))
         end
      end
               
      %% UTILITIES
      function sys = setName_(sys,Value)
         % Overloaded
         sys.Name_ = Value;
         if ~isempty(Value)
            Value = string(Value);
            Data = sys.Data_;
            for ct=1:numel(Data)
               if isscalar(Data(ct).StateInfo)
                  Data(ct).StateInfo.Name = Value;
               end
            end
            sys.Data_ = Data;
         end
      end
      
      
   end
   
   %% STATIC METHODS
   methods(Static, Hidden)
            
      function sys = loadobj(s)
         sys = s;
         sys.Version_ = ltipack.ver();
      end
      
      function sys = convert(X,varargin)
         % Safe conversion to SPARSS.
         sys = sparss(X);
      end
      
      function sys = make(D,IOSize)
         % Constructs SPARSS model from ltipack.spssdata instance
         sys = sparss;
         sys.Data_ = D;
         if nargin>1
            sys.IOSize_ = IOSize;  % support for empty model arrays
         else
            sys.IOSize_ = iosize(D(1));
         end
      end
      
      function C = makeC(C,TU)
         % Applies ss.make to each entry of the cell array C.
         % Used by uncertainty analysis functions
         for ct=1:numel(C)
            V = C{ct};
            if isa(V,'ltipack.spssdata')
               C{ct} = setTimeUnit_(sparss.make(V),TU);
            end
         end
      end

      function S = makeS(S,TU)
         % Applies sparss.make to each field of a struct array S.
         % Used by uncertainty analysis functions
         S = cell2struct(sparss.makeC(struct2cell(S),TU),fieldnames(S),1);
      end
            
      function M = checkMatrix(M,MatrixName)
         % Checks A,B,C,D,E data is of proper type
         if isnumeric(M) && ismatrix(M)
            if ~(strcmp(MatrixName,'D') || allfinite(M))
               error(message('Control:ltiobject:sparss2',MatrixName))
            end
            M = sparse(double(M));
         else
            error(message('Control:ltiobject:sparss3',MatrixName))
         end
      end
      
   end
   
end
   
   
%--------------------- Local Functions --------------------------------


function Value = localGetABCDE(Data,ABCDE,DefaultSize)
% Return values of A, B, C, D, or E (with internal delays to zero)
if isempty(Data)
   % Empty array
   Value = zeros(DefaultSize);
elseif numel(Data)>1
   error(message('Control:ltiobject:sparss1',upper(ABCDE)))
else
   if hasInternalDelay(Data)
      warning(message('Control:ltiobject:sparss13'))
   end
   [a,b,c,d,~,e] = getABCDE(Data);
   switch ABCDE
      case 'a'
         Value = a;
      case 'b'
         Value = b;
      case 'c'
         Value = c;
      case 'd'
         Value = d;
      case 'e'
         Value = e;
   end
end
end

%%%%%%%%
function sys = localSetABCDE(sys,Property,Value)
% SET function for A,B,C,D
Value = sparss.checkMatrix(Value,upper(Property));
Data = sys.Data_;
SameSize = (~isempty(Data) && isequal(size(Value),size(Data(1).(Property))));
for ct=1:numel(Data)
   if isempty(Data(ct).Delay.Internal)
      Data(ct).(Property) = Value;
   else
      error(message('Control:ltiobject:setSS1',upper(Property)))
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
