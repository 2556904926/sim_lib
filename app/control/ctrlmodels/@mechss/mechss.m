classdef (CaseInsensitiveProperties, TruncatedProperties, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      mechss < numlti & StateSpaceModel
   %MECHSS  Sparse mass-spring-damper model.
   %
   %  Construction:
   %    SYS = MECHSS(M,C,K,B,F,G,D) creates an object SYS representing the
   %    continuous-time second-order model
   %         M q''(t) + C q'(t) + K q(t) = B u(t) 
   %         y(t) = F q(t) + G q'(t) + D u
   %    Such models are common in finite-element analysis of mechanical 
   %    systems, where q and q' are the vector of displacements and
   %    velocities (the full state is x = [q;q']). The matrices M,C,K 
   %    specify mass, damping, and stiffness. You can set M=[] when the 
   %    mass matrix is identity, and set G,D to [] or omit them when G=0 or
   %    D=0. The M,C,K,B,F,G,D matrices are stored as sparse double arrays.
   %
   %    SYS = MECHSS(M,C,K,B,F,G,D,Ts) creates a discrete-time model with 
   %    equations
   %         M q[k+2] + C q[k+1] + K q[k] = B u[k]
   %         y[k] = F q[k] + G q[k+1] + D u[k]
   %    and sample time Ts. Set Ts=-1 if the sample time is undetermined.
   %
   %    SYS = MECHSS(D) specifies a static model with feedthrough D.
   %
   %    SYS = MECHSS(M,C,K) specifies a model with B=F=I and G=0.
   %
   %    Type "properties(mechss)" for a list of model properties, and type
   %       help mechss.<PropertyName>
   %    for help on specific property. For example, "help mechss.InputDelay"
   %    has details about the "InputDelay" property. Use the "SolverOptions"
   %    property to configure numerical computation involving SYS, see
   %    mechssOptions for details.
   %
   %  Arrays of sparse mechanical models:
   %    You can create an array of MECHSS models using indexed assignment
   %    or the STACK function. For example,
   %       sys = mechss(zeros(1,1,2))     % create 2x1 array of models
   %       sys(:,:,1) = mechss(M,C,K,B,F) % assign 1st model
   %       sys(:,:,2) = MDL2              % assign 2nd model
   %       sys = stack(1,sys,MDL3)        % add 3rd model to array
   %
   %  Conversion:
   %    SYS = MECHSS(SYS) converts any dynamic system SYS to second-order
   %    form. For SPARSS models, the result has a nonzero mass matrix
   %    when SYS has a second-order structure, and a zero mass matrix
   %    otherwise.
   %
   %  See also SPARSS, STACK, MECHSSDATA, MECHSSOPTIONS, SHOWSTATEINFO, 
   %  SS, FULL, DYNAMICSYSTEM.
   
%   Author(s): P. Gahinet
%   Copyright 2020 The MathWorks, Inc.
   
   % Add static method to be included for compiler
   %#function ltipack.utValidateTs
   %#function mechss.make
   %#function mechss.checkMatrix

   % Public properties with restricted value
   properties (Access = public, Dependent)
      % Mass matrix M (real, symmetric).
      %
      % Set this property to a square sparse matrix with as many rows as 
      % states (degrees of freedom).
      M
      % Damping matrix C (real, symmetric).
      %
      % Set this property to a square sparse matrix with as many rows as 
      % states (degrees of freedom).
      C
      % Stiffness matrix K (real, symmetric).
      %
      % Set this property to a square sparse matrix with as many rows as 
      % states (degrees of freedom).
      K
      % Input matrix B.
      %
      % Set this property to a matrix with as many rows as states and as many   
      % columns as inputs.
      B
      % Displacement-to-output matrix F.
      %
      % Set this property to a matrix with as many rows as outputs and as many   
      % columns as entries in x(t).
      F
      % Velocity-to-output matrix G.
      %
      % Set this property to a matrix with as many rows as outputs and as many   
      % columns as entries in x(t).
      G
      % Feedthrough matrix D.
      %
      % Set this property to a matrix with as many rows as outputs and as many   
      % columns as inputs.
      D
      % State partition (struct array)
      %
      % Contains partition of the state vector into components, interfaces
      % between components, and internal signals connecting components.
      % Struct array with fields "Type", "Name", and "Size" (number of states).
      StateInfo
      % Solver options (struct)
      %
      % Configures options for model analysis, such as enabling parallel
      % computing or choosing a particular DAE solver. See MECHSSSOPTIONS
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
         T = 'mechss';
      end

      function T = superiorTypes()
         T = {'mechss'};
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
      
      function sys = mechss(varargin)
         ni = nargin;
         % Handle conversion MECHSS(SYS) where SYS is already MECHSS
         if ni>0 && isa(varargin{1},'mechss')
            if ni>1
               error(message('Control:ltiobject:construct1','mechss'))
            end
            sys = varargin{1};
            return
         end
         % Handle conversion MECHSS(ND ARRAY)
         if ni==1 && isnumeric(varargin{1}) && ~ismatrix(varargin{1})
            sys = mechss(ss(varargin{1}));
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
               error(message('Control:ltiobject:construct3','mechss'))
            elseif ni>0
               error(message('Control:general:InvalidSyntaxForCommand','mechss','mechss'))
            end
         elseif DataInputs>8
            error(message('Control:general:InvalidSyntaxForCommand','mechss','mechss'))
         end
         
         % Process numerical data
         try
            switch DataInputs
               case 0
                  if ni
                     error(message('Control:ltiobject:construct4','mechss'))
                  else
                     % Empty model
                     m = sparse(0,0);  c = sparse(0,0);  k = sparse(0,0);
                     b = sparse(0,0);  
                     f = sparse(0,0);  g = sparse(0,0);  d = sparse(0,0);
                  end
               case 1
                  % Gain matrix
                  m = sparse(0,0);  c = sparse(0,0);  k = sparse(0,0);
                  d = mechss.checkMatrix(varargin{1},'D');
                  [Ny,Nu,~] = size(d);
                  b = sparse(0,Nu);  f = sparse(Ny,0);  g = sparse(Ny,0);
                  % Optimization for fast pre-allocation
                  CheckData = ~allfinite(d);
               case 3
                  m = mechss.checkMatrix(varargin{1},'M');
                  c = mechss.checkMatrix(varargin{2},'C');
                  k = mechss.checkMatrix(varargin{3},'K');
                  nq = size(k,1);
                  b = speye(nq); f = speye(nq);  
                  g = sparse(nq,nq);  d = sparse(nq,nq);
                  CheckData = true;
               case {2,4}
                  error(message('Control:general:InvalidSyntaxForCommand','mechss','mechss'))
               otherwise
                  % M,C,K,B,F specified: validate data
                  m = mechss.checkMatrix(varargin{1},'M');
                  c = mechss.checkMatrix(varargin{2},'C');
                  k = mechss.checkMatrix(varargin{3},'K');
                  b = mechss.checkMatrix(varargin{4},'B');
                  f = mechss.checkMatrix(varargin{5},'F');
                  if DataInputs<6
                     g = [];
                  else
                     g = mechss.checkMatrix(varargin{6},'G');
                  end
                  if DataInputs<7
                     d = [];
                  else
                     d = mechss.checkMatrix(varargin{7},'D');
                  end
                  CheckData = true;
            end
            
            % Sample time
            if DataInputs==8
               % Discrete SS
               Ts = ltipack.utValidateTs(varargin{8});
            else
               Ts = 0;
            end
         catch ME
            throw(ME)
         end
         
         % Determine I/O and array size
         if ni>0
            Ny = max([size(f,1),size(g,1),size(d,1)]);
            Nu = max(size(b,2),size(d,2));
         else
            Ny = 0;  Nu = 0; 
         end
         sys.IOSize_ = [Ny Nu];
         
         % Create @mechdata object array
         sys.Data_ = ltipack.mechdata(m,c,k,b,f,g,d,Ts);
         
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
      
      function Value = get.M(sys)
         Value = localGetMatrix(sys.Data_,'m',[0,0]);
      end
      function Value = get.C(sys)
         Value = localGetMatrix(sys.Data_,'c',[0,0]);
      end
      function Value = get.K(sys)
         Value = localGetMatrix(sys.Data_,'k',[0,0]);
      end      
      function Value = get.B(sys)
         Value = localGetMatrix(sys.Data_,'b',[0,sys.IOSize_(2)]);
      end      
      function Value = get.F(sys)
         Value = localGetMatrix(sys.Data_,'f',[sys.IOSize_(1),0]);
      end
      function Value = get.G(sys)
         Value = localGetMatrix(sys.Data_,'g',[sys.IOSize_(1),0]);
      end
      function Value = get.D(sys)
         Value = localGetMatrix(sys.Data_,'d',sys.IOSize_);
      end
      
      function sys = set.M(sys,Value)
         sys = localSetMatrix(sys,'m',Value);
      end
      function sys = set.C(sys,Value)
         sys = localSetMatrix(sys,'c',Value);
      end
      function sys = set.K(sys,Value)
         sys = localSetMatrix(sys,'k',Value);
      end
      function sys = set.B(sys,Value)
         sys = localSetMatrix(sys,'b',Value);
      end
      function sys = set.F(sys,Value)
         sys = localSetMatrix(sys,'f',Value);
      end
      function sys = set.G(sys,Value)
         sys = localSetMatrix(sys,'g',Value);
      end
      function sys = set.D(sys,Value)
         sys = localSetMatrix(sys,'d',Value);
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
         if any(numq(sys)~=sum([S.Size]),'all')
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
            S = ltioptions.mechss;
         end
      end
      
      function sys = set.SolverOptions(sys,Value)
         if strcmp(class(Value),'ltioptions.mechss') %#ok<STISA>
            if isequal(Value,ltioptions.mechss)
               Value = [];  % storage optimization
            end
            Data = sys.Data_;
            for ct=1:numel(Data)
               Data(ct).SolverConfig = Value;
            end
            sys.Data_ = Data;
         else
            error(message('Control:ltiobject:sparss11','mechss'))
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
      
      function nq = numq(sys)
         % Size of q vector for each model
         Data = sys.Data_;
         nq = zeros(size(Data));
         for ct=1:numel(Data)
            nq(ct) = size(Data(ct).k,1);
         end
      end

      % MOR
      function BalInfo = runBT(sys,Options)
         % Called by PROCESS
         if Options.Offset~=0
            % Use Rayleigh damping for stabilization
            error(message('Control:transformation:BALROM30'))
         end
         BalInfo = hsvd(sys.Data_,Options);
      end

      function boo = isFirstOrder(sys)
         % Detect MECHSS model that are SPARSS in disguise
         boo = true;
         Data = sys.Data_;
         for ct=1:numel(Data)
            if isempty(Data(ct).m) || nnz(Data(ct).m)>0
               boo = false;   return
            end
         end
      end

   end
   
      
   methods (Access = protected)
      
      function boo = isSparse_(~)
         boo = true;
      end
            
      %% INPUTOUTPUTMODEL ABSTRACT INTERFACE
      function displaySize(sys,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         nq = numq(sys);
         if isempty(nq)
            nq = 0;
         end
         if length(sizes)==2
            disp(getString(message('Control:ltiobject:SizeMECHSS1',ny,nu,nq)))
         else
            ArrayDims = sprintf('%dx',sizes(3:end));
            if all(nq(:)==nq(1))
               disp(getString(message('Control:ltiobject:SizeMECHSS2',...
                  ArrayDims(1:end-1),ny,nu,nq(1))))
            else
               disp(getString(message('Control:ltiobject:SizeMECHSS3',...
                  ArrayDims(1:end-1),ny,nu,min(nq(:)),max(nq(:)))))
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
         D0 = ltipack.mechdata([],[],[],sparse(0,nu),sparse(ny,0),sparse(ny,0),sparse(ny,nu),sys.Ts);
         % Update data
         sys.Data_ = ltipack.reassignData(sys.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
      end
      
      function boo = hasCustomScalarMultiply_(~)
         % Supported for scalar A
         boo = true;
      end
      
      function sys = leftMultiplyByScalar_(sys,A)
         % Multiplies by a numeric scalar without adding extra states
         s = size(A);  s = [s ones(1,4-numel(s))];
         Data = sys.Data_;
         if (numel(A)==1 || isequal(s(3:end),size(Data)))
            for ct=1:numel(Data)
               FACT = sparse(A(:,:,min(ct,end)));
               aux = FACT * Data(ct).d;
               if allfinite(aux)
                  Data(ct).f = FACT * Data(ct).f;
                  Data(ct).g = FACT * Data(ct).g;
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
         if (numel(A)==1 || isequal(s(3:end),size(Data)))
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
            
      %% TRANSFORMATIONS
      function [sys,nx] = augstate_(sys)
         [sys,nx] = augstate_@ltipack.SystemArray(sys);
         ES = repmat({''},[nx 1]);
         sys = augmentOutput(sys,ES,ES);
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
         % Safe conversion to MECHSS.
         sys = mechss(X);
      end
      
      function sys = make(D,IOSize)
         % Constructs MECHSS model from ltipack.mechdata instance
         sys = mechss;
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
            if isa(V,'ltipack.mechdata')
               C{ct} = setTimeUnit_(mechss.make(V),TU);
            end
         end
      end

      function S = makeS(S,TU)
         % Applies sparss.make to each field of a struct array S.
         % Used by uncertainty analysis functions
         S = cell2struct(mechss.makeC(struct2cell(S),TU),fieldnames(S),1);
      end
                  
      function M = checkMatrix(M,MatrixName)
         % Checks matrix data is of proper type
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


function Value = localGetMatrix(Data,MATID,DefaultSize)
% Return value of model matrix.
if isempty(Data)
   % Empty array
   Value = zeros(DefaultSize);
elseif numel(Data)>1
   error(message('Control:ltiobject:sparss1',upper(MATID)))
else
   if hasInternalDelay(Data)
      warning(message('Control:ltiobject:sparss13'))
   end
   [~,c,k,b,f,g,d,m] = getMCKBFGD(Data);
   switch MATID
      case 'm'
         Value = m;
      case 'c'
         Value = c;
      case 'k'
         Value = k;
      case 'b'
         Value = b;
      case 'f'
         Value = f;
      case 'g'
         Value = g;
      case 'd'
         Value = d;
   end
end
end

%%%%%%%%
function sys = localSetMatrix(sys,Property,Value)
% SET function for M,C,K,...
Value = mechss.checkMatrix(Value,upper(Property));
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
