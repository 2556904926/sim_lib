classdef (CaseInsensitiveProperties, TruncatedProperties, SupportExtensionMethods, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      genss < genlti & StateSpaceModel
   %GENSS  Generalized state-space models.
   %
   %  Construction:
   %    Generalized state-space (GENSS) models arise when combining ordinary LTI 
   %    models (see LTI) with tunable blocks (see TUNABLEBLOCK). These 
   %    blocks support common control design tasks such as parameter studies and 
   %    performance tuning. GENSS models keep track of how the tunable blocks 
   %    interact with the fixed dynamics.
   %
   %    You can use SERIES, PARALLEL, FEEDBACK, LFT, or CONNECT to construct
   %    GENSS models from Control Design blocks and regular LTI models. You can
   %    also use the commands:
   %       GENSYS = TF(N,D)
   %       GENSYS = SS(A,B,C,D)
   %    where one or more of the input arguments is a generalized matrix (see
   %    GENMAT). This approach is helpful to create parametric models of tunable
   %    components. Finally, you can cast any LTI model or Control Design block 
   %    SYS to GENSS using
   %       GENSYS = GENSS(SYS)
   %
   %    GENSS models can be manipulated as ordinary state-space models. The
   %    "Blocks" property gives access to the Control Design blocks in the model
   %    and the SS, TF, ZPK commands evaluate the model by replacing each Control
   %    Design block with its current value.
   %
   %    Example: Create a closed-loop model of a SISO loop with a tunable PID
   %    block:
   %       G = tf(0.1,[1 0.1],'InputDelay',2)   % plant model
   %       C = tunablePID('C','pid')          % tunable PID compensator
   %       T = feedback(G*C,1)                  % closed-loop transfer
   %    Here T is a GENSS model depending on the Control Design block "PID". You
   %    can plot the step response for the current PID settings by
   %       step(T)
   %
   %    Example: Create the parametric plant model G = a/(s+a):
   %       a = realp('a',1)
   %       G = tf(a,[1 a])
   %    The resulting GENSS model G is parameterized by the REALP block "a".
   %    Plot the Bode response of G for ten values of "a" in [1,10]:
   %       Gs = replaceBlock(G,'a',1:10);  % 10x1 array of models
   %       bode(Gs)
   %    Change the current value of "a" from 1 to 10 and evaluate G:
   %       G.Blocks.a.Value = 10;
   %       tf(G)
   %    This returns 10/(s+10) as expected.
   %
   %  Conversion:
   %    M = GENSS(M) converts the input/output model M to a generalized
   %    state-space model of class @genss.
   %
   %  See also ss, tf, getValue, genmat, genlti, ControlDesignBlock, InputOutputModel.
   
   %   Author(s): P. Gahinet
   %   Copyright 2009-2012 The MathWorks, Inc.
   
   % Add static method to be included for compiler
   %#function genss.loadobj
   %#function genss.make
   %#function genss.convert
   
   %    Generalized state-space (GENSS) models arise when combining ordinary
   %    LTI models (see LTI) with Control Design blocks such as
   %    tunable compensators, uncertain elements, and nonlinear components
   %    (see CONTROLDESIGNBLOCK for details). These blocks support common
   %    control design tasks such as parameter studies, robustness analysis,
   %    and performance tuning. The GENSS object keeps track of what blocks the
   %    model depends on and where these blocks enter the model.
   %
   %    GENSS models can be manipulated as ordinary state-space models. The
   %    "Blocks" property gives access to the Control Design blocks in the model
   %    and the SS, TF, ZPK commands evaluate the model by replacing each Control
   %    Design block with its current, nominal, or linearized value.

   % Public properties
   properties (SetAccess=private, Dependent)
      % State matrix A (read-only).
      %
      % Models the dependency of the A matrix on tunable and uncertain parameters
      % (see REALP, UREAL, UCOMPLEX, UCOMPLEXM). This property evaluates to a
      % generalized or uncertain matrix (see GENMAT and UMAT) or a double array
      % when the A matrix is constant. All non-static Control Design blocks are
      % are fixed to their current or nominal value.
      A
      % Input-to-state matrix B (read-only).
      %
      % Models the dependency of the B matrix on tunable and uncertain parameters
      % (see REALP, UREAL, UCOMPLEX, UCOMPLEXM). This property evaluates to a
      % generalized or uncertain matrix (see GENMAT and UMAT) or a double array
      % when the B matrix is constant. All non-static Control Design blocks are
      % are fixed to their current or nominal value.
      B
      % State-to-output matrix C (read-only).
      %
      % Models the dependency of the C matrix on tunable and uncertain parameters
      % (see REALP, UREAL, UCOMPLEX, UCOMPLEXM). This property evaluates to a
      % generalized or uncertain matrix (see GENMAT and UMAT) or a double array
      % when the C matrix is constant. All non-static Control Design blocks are
      % are fixed to their current or nominal value.
      C
      % Feedthrough matrix D (read-only).
      %
      % Models the dependency of the D matrix on tunable and uncertain parameters
      % (see REALP, UREAL, UCOMPLEX, UCOMPLEXM). This property evaluates to a
      % generalized or uncertain matrix (see GENMAT and UMAT) or a double array
      % when the D matrix is constant. All non-static Control Design blocks are
      % are fixed to their current or nominal value.
      D
      % E matrix for implicit state-space models (read-only).
      %
      % This property always evaluates to a double matrix. The value E=[]
      % means that the generalized state-space equations are explicit, type
      % "help ss.E" for more details.
      E
   end
      
   properties (Dependent)
      % State names (string vector, default = empty string for all states).
      %
      % Lists the names of all states in a GENSS model, including states
      % from tunable blocks with dynamics. This matches the state names
      % obtained when first converting the GENSS model to state space (SS),
      % type "help ss.StateName" for details.
      %
      % Setting this property is not allowed when some states originate
      % from Control Design blocks.
      StateName
      % State units (string vector, default = empty string for all states).
      %
      % Lists the units of all states in a GENSS model, including states
      % from tunable blocks with dynamics. This matches the state units
      % obtained when first converting the GENSS model to state space (SS),
      % type "help ss.StateUnit" for details.
      %
      % Setting this property is not allowed when some states originate
      % from Control Design blocks.
      StateUnit
      % Internal delays (numeric vector, default = []).
      %
      % This property lists the delays internal to the GENSS model (same as
      % H.InternalDelay where H is the first output of GETLFTMODEL). You can 
      % modify individual entries of the InternalDelay vector but you cannot 
      % change the number of entries (structural property of the model).
      InternalDelay
   end
   
   properties (Access = private)
      % For caching Info structure from SYSTUNE
      TuningInfo_ = [];
   end

   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genss';
      end

      function T = superiorTypes()
         T = {'genss'};
      end
            
      function A = getAttributes(A)
         % Override default attributes
         A.Varying = false;
         A.FRD = false;
         A.Sparse = false;
      end
            
      function T = toVarying()
         T = 'ltvss';
      end

      function T = toFRD()
         T = 'genfrd';
      end
      
      function F = toABCD(~)
         F = @genmat.make;
      end
      
   end
   
   methods
      
      function sys = genss(D)
         if nargin==0
            % GENSS()
            sys.Data_ = ltipack.lftdataSS(ltipack.ssdata.default(),...
               ltipack.LFTBlockWrapper.emptyBlockList());
            sys.IOSize_ = [0 0];
         elseif strcmp(class(D),'genss') %#ok<STISA>
            % Handle conversion GENSS(SYS) where SYS is @genss
            sys = D;
         elseif isnumeric(D)
            % GENSS(numeric array)
            B = ltipack.LFTBlockWrapper.emptyBlockList();
            D = double(D);
            s = [size(D) ones(1,2)];
            Data = createArray(s(3:end),'ltipack.lftdataSS');
            for ct=1:numel(Data)
               Data(ct).IC = ltipack.ssdata([],zeros(0,s(2)),zeros(s(1),0),D(:,:,ct),[],0);
               Data(ct).Blocks = B;
            end
            sys.Data_ = Data;
            sys.IOSize_ = s(1:2);
         else
            error(message('Control:general:InvalidSyntaxForCommand','genss','genss'))
         end
      end
      
      function Value = get.A(sys)
         % GET method for A property
         Value = localGetABCD(sys.Data_,'a',[0 0],sys.toABCD);
      end
      
      function Value = get.B(sys)
         % GET method for B property
         [~,nu] = iosize(sys);
         Value = localGetABCD(sys.Data_,'b',[0 nu],sys.toABCD);
      end
      
      function Value = get.C(sys)
         % GET method for C property
         [ny,~] = iosize(sys);
         Value = localGetABCD(sys.Data_,'c',[ny 0],sys.toABCD);
      end
      
      function Value = get.D(sys)
         % GET method for D property
         [ny,nu] = iosize(sys);
         Value = localGetABCD(sys.Data_,'d',[ny nu],sys.toABCD);
      end
      
      function Value = get.E(sys)
         % GET method for E property
         Value = localGetE(sys.Data_);
      end
                        
      function Value = get.InternalDelay(sys)
         % GET method for InternalDelay property
         Data = sys.Data_;
         Nsys = numel(Data);
         if Nsys==0
            Value = zeros(0,1);
         elseif Nsys==1
            Value = Data.IC.Delay.Internal;
         else
            RefValue = Data(1).IC.Delay.Internal;
            ndf = length(RefValue);
            Value = zeros([ndf 1 size(Data)]);
            isUniform = true;
            for ct=1:Nsys
               Df = Data(ct).IC.Delay.Internal;
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
            IC = Data(ct).IC; % ltipack.lftdataSS
            if numel(NewValue)~=numel(IC.Delay.Internal)
               error(message('Control:ltiobject:setSS3'))
            elseif sys.CrossValidation_
               Data(ct).IC.Delay.Internal = ...
                  ltipack.util.checkInternalDelay(NewValue,IC.Ts);
            else
               Data(ct).IC.Delay.Internal = NewValue;
            end
         end
         sys.Data_ = Data;
      end
      
      function Locs = getLoopID(sys)
         % Renamed in R2013b
         Locs = getSwitches(sys);
      end
      
      function Value = get.StateName(sys)
         % GET method for StateName property
         Value = cellstr(ltipack.SystemArray.getStateInfo(sys.Data_,'StateName'));
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
            nx = size(Data(1).IC.a,1);
            ns = numel(Value);
            for ct=1:nsys
               if size(Data(ct).IC.a,1)~=nx
                  % Not supported for varying state dimension
                  error(message('Control:ltiobject:setSS2'))
               elseif order(Data(ct).Blocks)>0
                  error(message('Control:lftmodel:genss14'))
               elseif ns>0 && ns~=nx
                  error(message('Control:ltiobject:ssProperties3','StateName'))
               end
               Data(ct).IC.StateName = Value;
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
            nx = size(Data(1).IC.a,1);
            ns = numel(Value);
            for ct=1:nsys
               if size(Data(ct).IC.a,1)~=nx
                  % Not supported for varying state dimension
                  error(message('Control:ltiobject:setSS5'))
               elseif order(Data(ct).Blocks)>0
                  error(message('Control:lftmodel:genss15'))
               elseif ns>0 && ns~=nx
                  error(message('Control:ltiobject:ssProperties3','StateUnit'))
               end
               Data(ct).IC.StateUnit = Value;
            end
            sys.Data_ = Data;
         end
      end
            
    end
   
   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access=protected)
      
      function displaySize(sys,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         nx = order(sys);
         nb = nblocks(sys);
         if length(sizes)==2
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENSS1',ny,nu,nx,nb))
         else
            ArrayDims = sprintf('%dx',sizes(3:end));
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENSS2',ArrayDims(1:end-1)))
            if isempty(nx)
               nx = 0;  nb = 0;
            else
               nx = nx(:);  nb = nb(:);
            end
            if all(nx==nx(1))
               if all(nb==nb(1))
                  disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENSS3',ny,nu,nx(1),nb(1)))
               else
                  disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENSS4',ny,nu,nx(1),min(nb),max(nb)))
               end
            else
               if all(nb==nb(1))
                  disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENSS5',ny,nu,min(nx),max(nx),nb(1)))
               else
                  disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENSS6',ny,nu,min(nx),max(nx),min(nb),max(nb)))
               end
            end
         end
      end
      
   end
   
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access = protected)
      
      %% MODEL CHARACTERISTICS
      function varargout = isproper_(sys,varargin)
         % ISPROPER(SYS) is the same as ISPROPER(SS(SYS)) for GENSS SYS.
         [varargout{1:nargout}] = isproper_(ss(sys),varargin{:});
      end
      
      function sys = checkDataConsistency(sys)
         % Check data consistency
         D = sys.Data_; %#ok<*PROP>
         for ct=1:numel(D)
            D(ct).IC = checkDelay(D(ct).IC);
         end
         sys.Data_ = D;
      end
      
      function varargout = lftdata_(sys,varargin)
         % LFTDATA support for generalized LFT models
         [varargout{1:nargout}] = lftdata_(uss_(sys),varargin{:});
      end
      
      %% INDEXING
      function sys = indexasgn_(sys,indices,rhs,ioSize,ArrayMask)
         % Data management in SYS(indices) = RHS.
         % ioSize is the new I/O size and ArrayMask tracks which
         % entries in the resulting system array have been reassigned.
         
         % Construct template initial value for new entries in system array
         Dss = ltipack.ssdata([],zeros(0,ioSize(2)),zeros(ioSize(1),0),...
            zeros(ioSize),[],sys.Ts);
         D0 = ltipack.lftdataSS(Dss,ltipack.LFTBlockWrapper.emptyBlockList());
         % Update data
         sys.Data_ = ltipack.reassignData(sys.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
      end
      
      %% TRANSFORMATIONS
      function sys = chgTimeUnit_(sys,newUnits)
         % Changes time units without altering system behavior
         sys = chgTimeUnit_@genlti(sys,newUnits);
         % Align time units in tuning info
         Info = sys.TuningInfo_;
         if ~isempty(Info)
            F = fieldnames(Info.Blocks);
            for ct=1:numel(F)
               if isa(Info.Blocks.(F{ct}),'DynamicSystem')
                  Info.Blocks.(F{ct}) = chgTimeUnit_(Info.Blocks.(F{ct}),newUnits);
               end
            end
            Info.LoopScaling = chgTimeUnit_(Info.LoopScaling,newUnits);
            sys.TuningInfo_ = Info;
         end
      end
      
      function sys = getValue_(sys)
         % Returns current value
         sys = ss(sys);
      end
      
      function sys = getNominal_(sys)
         % Returns nominal value
         [sys,NoBlocks] = foldUncertainty_(sys);
         if NoBlocks
            sys = ss(sys);
         end
      end
      
      function varargout = canon_(sys,varargin) %#ok<STOUT>
         % Canonical realization
         error(message('Control:general:NotSupportedModelsofClass','canon',class(sys)))
      end
      
      function varargout = balreal_(sys,varargin) %#ok<STOUT>
         % Balanced realization
         error(message('Control:general:NotSupportedModelsofClass','balreal',class(sys)))
      end
      
   end
   
   %% PROTECTED METHODS
   methods (Access = protected)
      
      function s = getPropStruct(sys)
         % Move "Blocks" property to the top
         s = getPropStruct@InputOutputModel(sys);
         n = numel(fieldnames(s));
         s = orderfields(s,[n 1:n-1]);
      end
      
      function sys = setTimeUnit_(sys,TU)
         % Change TimeUnit value.
         sys = setTimeUnit_@genlti(sys,TU);
         % Align time units in  tuning info
         Info = sys.TuningInfo_;
         if ~isempty(Info)
            F = fieldnames(Info.Blocks);
            for ct=1:numel(F)
               if isa(Info.Blocks.(F{ct}),'DynamicSystem')
                  Info.Blocks.(F{ct}).TimeUnit = TU;
               end
            end
            Info.LoopScaling.TimeUnit = TU;
            sys.TuningInfo_ = Info;
         end
      end
      
   end
   
   %% HIDDEN METHODS
   methods (Hidden)
      
      % INTERFACE WITH SYSTUNE
      [SYSDATA,SPECDATA,FDATA,tInfo] = getTuningData(varargin)
      
      function M = setTuningInfo(M,Info)
         % Caches Info structure from SYSTUNE's best run
         M.TuningInfo_ = Info;
      end
      
      function Info = getTuningInfo(M)
         % Accesses cached Info structure (see evalGoal/viewGoal)
         Info = M.TuningInfo_;
      end
      
      function M = clearTuningInfo(M)
         % Clears cached Info structure
         M.TuningInfo_ = [];
      end
            
      % INTERFACE WITH HINFSTRUCT
      function [P,pInfo] = HINFSTRUCT_Interface(sysCL)
         % Extracts LFT and parameterization data for HINFSTRUCT from the
         % GENSS model SYS of the closed-loop transfer function.
         D = sysCL.Data_;  % assumed scalar
         % Fold non-parametric blocks
         isP = logicalfun(@isParametric,D.Blocks);
         if ~all(isP)
            if any(isP)
               D = foldBlocks(D,~isP);
            else
               error(message('Control:tuning:hinfstruct8'))
            end
         end
         % Extract optimization data
         [pInfo,bperm] = HINFSTRUCT_ParamInfo(D.Blocks);
         % Reflect block permutation in P:
         [rperm,cperm] = getRowColPerm(D.Blocks,bperm);
         ios = iosize(D.IC);
         nw = ios(2)-length(rperm);
         nz = ios(1)-length(cperm);
         P = ioperm(D.IC,[1:nz nz+cperm],[1:nw nw+rperm]);
      end
      
      % MUSYN support
      
      function T = sector2gain(T,F)
         % Transforms the problem
         %
         %    Tune T1 to enforce [T1(jw);I]' Q(jw) [T1(jw);I] < 0
         %
         % into the HINFSYN problem
         %
         %    Tune T2 to enforce || T2 ||oo < 1
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
         T.Data_ = sector2gain(T.Data_,getPrivateData(F));
      end
      
   end
   
   
   %% STATIC METHODS
   methods(Static, Hidden)
      
      function sys = make(D,IOSize)
         % Constructs GENSS model from nonempty ltipack.lftdataSS array
         sys = genss;
         sys.Data_ = D;
         if nargin>1
            sys.IOSize_ = IOSize;  % support for empty model arrays
         else
            sys.IOSize_ = iosize(D(1));
         end
      end
      
      function sys = convert(X)
         % Safe conversion to GENSS
         if isnumeric(X)
            sys = genss(X);
         else
            sys = copyMetaData(X,genss_(X));
         end
      end
      
      function sys = loadobj(s)
         % Load filter for GENSS objects
         if isa(s,'genss')
            sys = DynamicSystem.updateMetaData(s);
            sys.Version_ = ltipack.ver();
         end
      end
      
   end
   
end

%---------------------------------------
function ABCD = localGetABCD(Data,MatName,DefaultSize,MakeFcn)
% Retrieves A,B,C,D as a double array or generalized matrix.
ArraySize = size(Data);
if isempty(Data)
   % Empty array
   ABCD = zeros([DefaultSize,ArraySize]);
else
   % Allocate data array
   SData = createArray(ArraySize,'ltipack.lftdataM');
   nblk = 0;
   for ct=1:numel(Data)
      D = getABCD(Data(ct),MatName);
      if ct==1
         MatSize = iosize(D);
      elseif ~isequal(iosize(D),MatSize)
         % Matrix size is not uniform
         error(message('Control:ltiobject:get4',upper(MatName)))
      end
      nblk = max(nblk,numel(D.Blocks));
      SData(ct) = D;
   end
   % Format value
   if nblk>0
      % Static LFT model (GENMAT or UMAT)
      ABCD = feval(MakeFcn,SData);
   else
      % Numeric array
      ABCD = zeros([MatSize,size(SData)]);
      for ct=1:numel(SData)
         ABCD(:,:,ct) = double(SData(ct));
      end
   end
end
end


function E = localGetE(Data)
% Retrieves E matrices (always constant)
ArraySize = size(Data);
if isempty(Data)
   % Empty array
   E = zeros([0,0,ArraySize]);
elseif isscalar(Data)
   E = Data.IC.e;
else
   ValueArray = cell(ArraySize);
   EmptyFlag = true;
   for ct=1:numel(Data)
      es = Data(ct).IC.e;
      if ~isempty(es)
         ValueArray{ct} = es;  EmptyFlag = false;
      end
   end
   % Replace E=[] by identity of proper size if some E's are non-empty
   if ~EmptyFlag
      for ct=1:numel(Data)
         if isempty(ValueArray{ct})
            ValueArray{ct} = eye(size(Data(ct).IC.a));
         end
      end
   end
   % Turn into ND array
   if EmptyFlag
      E = zeros([0,0,ArraySize]);
   else
      try
         E = cat(3,ValueArray{:});
         E = reshape(E,[size(E,1) size(E,2) ArraySize]);
      catch %#ok<CTCH>
         % E cannot be represented as ND arrays
         error(message('Control:ltiobject:get4','E'))
      end
   end
end 
end





