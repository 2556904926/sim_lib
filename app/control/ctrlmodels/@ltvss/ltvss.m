classdef (CaseInsensitiveProperties, TruncatedProperties, SupportExtensionMethods, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      ltvss < DynamicSystem & StateSpaceModel
   %LTVSS  Linear time-varying state-space model.
   %
   %  Construction:
   %    VSYS = LTVSS(FCN) creates a continuous-time LTV model of the form
   % 
   %       E(t) dx/dt = dx0(t) + A(t) (x(t)-x0(t)) + B(t) (u(t)-u0(t))
   %             y(t) = y0(t)  + C(t) (x(t)-x0(t)) + D(t) (u(t)-u0(t))
   %
   %    where dx0,x0,u0,y0 are time-dependent offsets. The function FCN 
   %    specifies how to calculate the matrices and offsets at any given
   %    time t. Its syntax must follow the template
   %
   %       [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(t) .
   %
   %    All output arguments except A,B,C,D can be set to [] when absent 
   %    for all times t. To specify fixed or varying delays at the inputs
   %    or outputs, use a struct "Delay" with fields "Input" and "Output".
   %    If an input or output delay is zero for all t, specify it as NaN.
   %
   %    VSYS = LTVSS(FCN,Ts) creates a discrete-time LTV model with sample 
   %    time Ts. In discrete time, t is replaced by the index k counting
   %    the elapsed sampling periods (clock time is k*Ts) and FCN takes k
   %    instead ot t as input: [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(k).
   %
   %    VSYS = LTVSS(FCN,Ts,t0) uses FCN(t0) to determine the number of
   %    states, inputs, and outputs. By default, LTVSS uses t0=0.
   %
   %    You can set additional model properties by using name/value pairs.
   %    For example,
   %       vsys = LTVSS(FCN,'InputName','torque','StateName','position')
   %    also sets the input and state names. Type "properties(ltvss)" 
   %    for a complete list of model properties, and type 
   %       help ltvss.<PropertyName>
   %    for help on a particular property. For example, "help ltvss.StateName" 
   %    provides information about the "StateName" property.
   %
   %  Conversion:
   %    VSYS = LTVSS(VSYS) converts the model VSYS to LTVSS.
   %
   %    See also SSINTERPOLANT, PSAMPLE, LPVSS, SS, DYNAMICSYSTEM.
   
%   Author(s): P. Gahinet, P. Seiler, R. Singh.
%   Copyright 2022-2024 The MathWorks, Inc.
   
   % Public properties with restricted value
   properties (Access = public, Dependent)
      % Data function.
      %
      % Function for calculating the model data. Its syntax is
      %
      %   [A,B,C,D,E,dx0,x0,u0,y0,Delay] = F(t)
      %
      % for LTV models and 
      %
      %   [A,B,C,D,E,dx0,x0,u0,y0,Delay] = F(t,p)
      %
      % for LPV models. All but the first four outputs can be set to [] 
      % when uniformly absent for all t or (t,p) values. Delay is a struct
      % with fields "Input" and "Output" specifying fixed or varying delays
      % at the inputs or outputs. In discrete time, t is replaced by the
      % time sample index k.
      DataFunction
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
   end
      

   properties (Access = protected)
      % Data function. Can take one or two arguments (t ot t,p)
      DataFunction_
      % State dimension
      Nx_ = 0;
      % Number of internal delays 
      Nfd_ = 0;
      % String vector, Nx-by-1 or 0-by-1 to mean ["";...;""]
      StateName_ = strings(0,1);
      % String vector, Nx-by-1 or 0-by-1 to mean ["";...;""]
      StateUnit_ = strings(0,1);
      % String vector, Nx-by-1 or 0-by-1 to mean ["";...;""]
      StatePath_ = strings(0,1);
      % Sample time
      Ts_ = 0;
      % Validation time
      t0_ = 0;
   end


   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'ltvss';
      end

      function T = superiorTypes()
         T = {'ltvss','lpvss'};
      end
      
      function A = getAttributes(A)
         % Override default attributes
         A.Structured = false;
         A.FRD = false;
         A.Sparse = false;
      end
            
      function T = toFRD()
         T = 'frd';
      end
            
   end
   
   
   methods
      
      function sys = ltvss(varargin)
                  
         % Quick exits
         ni = nargin;
         if ni==0
            sys.IOSize_ = [0 0];  return
         elseif ni==1
            arg = varargin{1};
            if isa(arg,'ltvss')
               sys = arg;   return
            elseif isnumeric(arg)
               sys = ltvss.convert(arg); return
            elseif isa(arg,'StaticModel')
               sys = copyMetaData(arg,ltvss.convert(arg)); return
            end
         end

         % Dissect input list
         DataFcn = varargin{1};
         PVStart = ni+1;
         for ct=2:ni
            nextarg = varargin{ct};
            if ischar(nextarg) || isstring(nextarg)
               PVStart = ct;   break
            end
         end
         if PVStart>4
            error(message('Control:general:InvalidSyntaxForCommand','ltvss','ltvss'))
         end
         
         % Populate object
         try
            % Sample time
            if PVStart>2
               sys.Ts = varargin{2};
            end

            % Test value t0
            if PVStart>3
               t0 = varargin{3};
               if ~(isnumeric(t0) && isreal(t0) && isscalar(t0) && isfinite(t0))
                  error(message('Control:ltiobject:LTV1'))
               end
               sys.t0_ = t0;
            end

            % Store data function
            if ischar(DataFcn) || isstring(DataFcn)
               DataFcn = str2func(DataFcn);
            end
            sys.DataFunction_ = DataFcn;

            % Process additional settings and validate system
            if PVStart<=ni
               sys = fastSet(sys,varargin{PVStart:ni});
            end

            % Check consistency (sets model sizes)
            sys = checkConsistency(sys);

         catch ME
            throw(ME)
         end

      end
      
      %---------------- GET/SET ------------------------------------------
      
      
      function Value = get.DataFunction(sys)
         % GET method for DataFunction property
         Value = sys.DataFunction_;
      end

      function Value = get.StateName(sys)
         % GET method for StateName property
         Value = sys.StateName_;
         if isempty(Value)
            Value = repmat({''},[sys.Nx_,1]);
         else
            Value = cellstr(Value);
         end
      end
      
      function Value = get.StatePath(sys)
         % GET method for StatePath property
         Value = sys.StatePath_;
         if isempty(Value)
            Value = repmat({''},[sys.Nx_,1]);
         else
            Value = cellstr(Value);
         end
      end
      
      function Value = get.StateUnit(sys)
         % GET method for StateUnit property
         Value = sys.StateUnit_;
         if isempty(Value)
            Value = repmat({''},[sys.Nx_,1]);
         else
            Value = cellstr(Value);
         end
      end
      
      function sys = set.DataFunction(sys,F)
         % SET method for DataFunction property
         if ischar(F) || isstring(F)
            F = str2func(F);
         end
         sys.DataFunction_ = F;
         if sys.CrossValidation_
            try
               sys = checkConsistency(sys);
            catch ME
               throw(ME)
            end
         end
      end

      function sys = set.StateName(sys,Value)
         % SET method for StateName property
         Value = ltipack.mustBeStringVector(Value,'StateName',false);
         if isempty(Value)
            sys.StateName_ = strings(0,1);
         elseif sys.CrossValidation_ && numel(Value)~=sys.Nx_
            error(message('Control:ltiobject:LTV15','StateName',sys.Nx_))
         else
            sys.StateName_ = Value;
         end
      end
      
      function sys = set.StatePath(sys,Value)
         % SET method for StatePath property
         Value = ltipack.mustBeStringVector(Value,'StatePath',false);
         % Replace carriage returns by blanks
         Value = regexprep(Value,'\n',' ');
         if isempty(Value)
            sys.StatePath_ = strings(0,1);
         elseif sys.CrossValidation_ && numel(Value)~=sys.Nx_
            error(message('Control:ltiobject:LTV15','StatePath',sys.Nx_))
         else
            sys.StatePath_ = Value;
         end
      end
      
      function sys = set.StateUnit(sys,Value)
         % SET method for StateUnit property
         Value = ltipack.mustBeStringVector(Value,'StateUnit',false);
         if isempty(Value)
            sys.StateUnit_ = strings(0,1);
         elseif sys.CrossValidation_ && numel(Value)~=sys.Nx_
            error(message('Control:ltiobject:LTV15','StateUnit',sys.Nx_))
         else
            sys.StateUnit_ = Value;
         end
      end

   end
   
         
   methods (Access = protected)
      
      function boo = isTimeVarying_(~)
         boo = true;
      end

      function boo = isstatic_(sys,~)
         S = functions(sys.DataFunction);
         boo = startsWith(S.function,'@(t)ltvpack.staticDF');
      end

      function boo = isreal_(~,~) %#ok<STOUT>
         error(message('Control:ltiobject:LTV18'))
      end

      function boo = isstable_(~,varargin) %#ok<STOUT>
         error(message('Control:analysis:isstable3'))
      end

      function Ts = getTs_(sys)
         Ts = sys.Ts_;
      end

      function sys = setTs_(sys,Ts)
         if sys.CrossValidation_ && Ts~=0 && sys.t0_~=round(sys.t0_)
            error(message('Control:ltiobject:LTV17'))
         end
         sys.Ts_ = Ts;
      end

      function sys = validateDataFcn(sys)
         % Validate data function and resolve model sizes
         try
            [A,B,C,D,E,dx0,x0,u0,y0,Delay] = sys.DataFunction_(sys.t0_);
         catch ME
            error(message('Control:ltiobject:LTV2',sprintf('%.3g',sys.t0_),ME.message))
         end
         [sys.Nx_,ny,nu,sys.Nfd_] = ltvss.validateData(A,B,C,D,E,dx0,x0,u0,y0,Delay,sys.Ts_);
         sys.IOSize_ = [ny nu];
      end
      
      %% INPUTOUTPUTMODEL ABSTRACT INTERFACE
      function displaySize(sys,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         disp(getString(message('Control:ltiobject:SizeLTVSS1',ny,nu,sys.Nx_)))
      end

      function sys = checkDataConsistency(sys)
         % Consistency checks
         % t0 should be an integer in discrete time
         if getTs_(sys)~=0
            k0 = sys.t0_;
            if abs(k0-round(k0))>1e-3*abs(k0)
               error(message('Control:ltiobject:LTV16'))
            else
               sys.t0_ = round(k0);
            end
         end
         % Validate data function
         sys = validateDataFcn(sys);
         % Check consistency of state metadata
         nx = sys.Nx_;
         if ~any(numel(sys.StateName_)==[0 nx])
            error(message('Control:ltiobject:LTV15','StateName',nx))
         end
         if ~any(numel(sys.StateUnit_)==[0 nx])
            error(message('Control:ltiobject:LTV15','StateUnit',nx))
         end
         if ~any(numel(sys.StatePath_)==[0 nx])
            error(message('Control:ltiobject:LTV15','StatePath',nx))
         end
      end
      
      %% DATA ABSTRACTION INTERFACE

      %% MODEL CHARACTERISTICS
      function ns = order_(sys)
         % Returns order of each array entry
         ns = sys.Nx_;
      end

      %% BINARY OPERATIONS
      function sys = plus_(sys1,sys2)
         % Parallel connection
         [sys1,sys2] = matchAttributes(sys1,sys2);
         DF = @(t) ltvpack.parallelDF(sys1,sys2,t);
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = ltvss(DF,getTs_(sys1),t0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function sys = mtimes_(sys1,sys2,ScalarFlags)
         % Series connection
         [sys1,sys2] = matchAttributes(sys1,sys2);
         DF = @(t) ltvpack.seriesDF(sys1,sys2,ScalarFlags,t);
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = ltvss(DF,getTs_(sys1),t0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function [sys,SingularFlag] = feedback_(sys1,sys2,indu,indy,sign)
         % Feedback connection
         SingularFlag = false; % no way to tell
         [sys1,sys2] = matchAttributes(sys1,sys2);
         indu = reshape(indu,[1 numel(indu)]);
         indy = reshape(indy,[1 numel(indy)]);
         DF = @(t) ltvpack.feedbackDF(sys1,sys2,indu,indy,sign,t);
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = ltvss(DF,getTs_(sys1),t0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function [sys,SingularFlag] = lft_(sys1,sys2,indu1,indy1,indu2,indy2)
         % LFT connection
         SingularFlag = false; % no way to tell
         [sys1,sys2] = matchAttributes(sys1,sys2);
         DF = @(t) ltvpack.lftDF(sys1,sys2,indu1,indy1,indu2,indy2,t);
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = ltvss(DF,getTs_(sys1),t0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function sys = iocat_(dim,sys1,sys2)
         % Horizontal or vertical concatenation
         [sys1,sys2] = matchAttributes(sys1,sys2);
         if dim==1
            DF = @(t) ltvpack.vertcatDF(sys1,sys2,t);
         else
            DF = @(t) ltvpack.horzcatDF(sys1,sys2,t);
         end
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = ltvss(DF,getTs_(sys1),t0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function sys = append_(sys1,sys2)
         % blkdiag concatenation
         [sys1,sys2] = matchAttributes(sys1,sys2);
         DF = @(t) ltvpack.appendDF(sys1,sys2,t);
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = ltvss(DF,getTs_(sys1),t0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function sys = mergeInfo_(sys,sys1,sys2)
         % Combines state names, paths, and units of SYS1 and SYS2
         if ~(isempty(sys1.StateName_) && isempty(sys2.StateName_))
            sys.StateName_ = [ltipack.fullstring(sys1.StateName_,sys1.Nx_) ; ltipack.fullstring(sys2.StateName_,sys2.Nx_)];
         end
         if ~(isempty(sys1.StatePath_) && isempty(sys2.StatePath_))
            sys.StatePath_ = [ltipack.fullstring(sys1.StatePath_,sys1.Nx_) ; ltipack.fullstring(sys2.StatePath_,sys2.Nx_)];
         end
         if ~(isempty(sys1.StateUnit_) && isempty(sys2.StateUnit_))
            sys.StateUnit_ = [ltipack.fullstring(sys1.StateUnit_,sys1.Nx_) ; ltipack.fullstring(sys2.StateUnit_,sys2.Nx_)];
         end
         sys.TimeUnit_ = sys1.TimeUnit_;
      end

      function [sys,SingularFlag] = connect_(sys,K,feedin,feedout,iu,iy,Options)
         % Close feedback loops
         SingularFlag = false;
         if ~isempty(K)
            sys = feedback(sys,K,feedin,feedout,+1);
         end
         % Select external I/Os
         sys = sys(iy,iu);
         if isempty(Options) || Options.Simplify
            sys = sminreal(sys);
         end
      end

      function sys = removeInputBranching_(sys,I,J)
         % See CONNECT
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(t) ltvpack.elimBranchingDF(sys,I,J,t);
         else
            sys.DataFunction_ = @(t,p) ltvpack.elimBranchingDF(sys,I,J,t,p);
         end
      end

      function sys = fixInput_(sys,indices,values)
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(t) ltvpack.fixInputDF(sys,indices,values,t);
         else
            sys.DataFunction_ = @(t,p) ltvpack.fixInputDF(sys,indices,values,t,p);
         end
      end

      %% ANALYSIS
      [y,t,focus,x,ysd,p] = timeresp_(sys,RespType,t,pSpec,Config)
      [yfinal,yinit] = getFinalValue_(sys,RespType,y,t,p,Config)
      varargout = lsim_(varargin)
      [op,SINGULAR] = findop_(sys,t,p,opspec)
      op = setop_(sys,t,p,opspec)

      %% TRANSFORMATIONS
      function sysOut = lpvss_(sys)
         DF = sys.DataFunction_;
         sysOut = lpvss(strings(0,1),@(t,p) DF(t),getTs_(sys),sys.t0_,zeros(0,1));
         sysOut.StateName_ = sys.StateName_;
         sysOut.StatePath_ = sys.StatePath_;
         sysOut.StateUnit_ = sys.StateUnit_;
         sysOut.TimeUnit_ = sys.TimeUnit_;
      end

      function sys = uminus_(sys)
         if isstatic(sys)
            % Preserve static nature to avoid sample time clashes
            [~,~,~,D] = sys.DataFunction(0);
            sys = ltvss.convert(-D);
         else
            sys.DataFunction_ = @(t) ltvpack.uminusDF(sys,t);
         end
      end

      function sys = indexref_(sys,indrow,indcol,~)
         % Indexing operations
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(t) ltvpack.ioselectDF(sys,indrow,indcol,t);
         else
            sys.DataFunction_ = @(t,p) ltvpack.ioselectDF(sys,indrow,indcol,t,p);
         end
      end

      function sys = repmat_(sys,s)
         % Replicate along I/O sizes
         if numel(s)>2
            error(message('Control:transformation:LTV3'))
         end
         indrow = ones(s(1),1);  indcol = ones(s(2),1);
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(t) ltvpack.ioselectDF(sys,indrow,indcol,t);
         else
            sys.DataFunction_ = @(t,p) ltvpack.ioselectDF(sys,indrow,indcol,t,p);
         end
      end      

      function [sys,xkeep] = sminreal_(sys,~)
         xkeep = true(sys.Nx_,1);
      end

      function sys = xperm_(sys,perm)
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(t) ltvpack.xpermDF(sys,perm,t);
         else
            sys.DataFunction_ = @(t,p) ltvpack.xpermDF(sys,perm,t,p);
         end
         if ~isempty(sys.StateName_)
            sys.StateName_ = sys.StateName_(perm,:);
         end
         if ~isempty(sys.StatePath_)
            sys.StatePath_ = sys.StatePath_(perm,:);
         end
         if ~isempty(sys.StateUnit_)
            sys.StateUnit_ = sys.StateUnit_(perm,:);
         end
      end

      function [sys,gic] = c2d_(sys,Ts,options)
         if ~strcmp(options.Method,'tustin')
            error(message('Control:transformation:c2d21'))
         elseif options.ThiranOrder>0
            % Size of x and w,z can't change over time
            error(message('Control:transformation:c2d22'))
         end
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(k) ltvpack.c2dDF(sys,Ts,options.PrewarpFrequency,k);
         else
            sys.DataFunction_ = @(k,p) ltvpack.c2dDF(sys,Ts,options.PrewarpFrequency,k,p);
         end
         sys.Ts_ = Ts;
         sys.StateName_ = strings(0,1);
         sys.StatePath_ = strings(0,1);
         sys.StateUnit_ = strings(0,1);
         gic = [];
      end

      function [sys,gic] = d2c_(sys,options)
         if ~strcmp(options.Method,'tustin')
            error(message('Control:transformation:c2d21'))
         end
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(t) ltvpack.d2cDF(sys,sys.Ts_,options.PrewarpFrequency,t);
         else
            sys.DataFunction_ = @(t,p) ltvpack.d2cDF(sys,sys.Ts_,options.PrewarpFrequency,t,p);
         end
         sys.Ts_ = 0;
         sys.StateName_ = strings(0,1);
         sys.StatePath_ = strings(0,1);
         sys.StateUnit_ = strings(0,1);
         gic = [];
      end

      function [sys,gic] = d2d_(sys,Ts,options)
         if ~strcmp(options.Method,'tustin')
            error(message('Control:transformation:c2d21'))
         end
         if nargin(sys.DataFunction_)==1
            sys.DataFunction_ = @(k) ltvpack.d2dDF(sys,Ts,options.PrewarpFrequency,k);
         else
            sys.DataFunction_ = @(k,p) ltvpack.d2dDF(sys,Ts,options.PrewarpFrequency,k,p);
         end
         sys.Ts_ = Ts;
         sys.StateName_ = strings(0,1);
         sys.StatePath_ = strings(0,1);
         sys.StateUnit_ = strings(0,1);
         gic = [];
      end

   end
   
   %% PLOT RESPONSE
   methods (Access = {?DynamicSystem,?controllib.chart.internal.data.response.ModelResponseDataSource})

      function [y,t,focus,yinit,yfinal] = getTimeResponseData_(sys,t,p,config,responseType,~)
         % Compute time response
         config = validate(config,size(sys,2));
         [y,t,focus,~,~,p] = timeresp_(sys,responseType,t,p,config);
         [yfinal,yinit] = getFinalValue_(sys,responseType,y,t,p,config);
      end

      % Linear simulation response
      function y = getSimulationData_(sys,u,t,p,xinit,~,~)
         y = lsim_(sys,u,t,xinit,p);
      end

      % Supported characteristic types
      function supportedCharacteristics = getSupportedCharacteristicsForResponseType_(sys,type)
         switch type
            case "step"
               supportedCharacteristics = ["PeakResponse","RiseTime","SettlingTime",...
                  "TransientTime","SteadyState"];
            case "bode"
               supportedCharacteristics = "FrequencyPeakResponse";
               if isiso(sys)
                  supportedCharacteristics = [supportedCharacteristics,...
                     "MinimumStabilityMargins","AllStabilityMargins"];
               end
         end
      end

   end
   
   methods (Hidden)

      function nfd = nfdelay(sys)
         % Default
         nfd = sys.Nfd_;
      end

      function Source = getPlotSource(sys, Name)
         % Default plot source for LTV/LPV systems
         Source = resppack.ltvsource(sys, 'Name', Name);
      end

      function [y,t,focus] = fastresp(sys,RespType,t,p,Config)
         % Gateway for response plots
         [y,t,focus] = timeresp_(sys,RespType,t,p,Config);
      end

      function [asys,offsets] = sample(sys,varargin)
         %SAMPLE  Sample LTV or LPV dynamics.
         %
         %   SAMPLE is deprecated, use PSAMPLE instead.
         %
         %   See also PSAMPLE.
         try
            asys = psample(sys,varargin{:});
         catch ME
            throw(ME)
         end
         if hasInternalDelay(asys)
            % Offsets meaningless + can't modify them
            error(message('Control:ltiobject:SAMPLE12'))
         end
         offsets = asys.Offsets;
         if isequal(offsets,[])
            offsets = struct('dx',cell(getArraySize(asys)),'x',[],'u',[],'y',[]);
         end
         asys.Offsets = [];
      end

   end

   %% STATIC METHODS
   methods(Static, Hidden)

      function sys = loadobj(sys)
         if isa(sys,'GriddedLTVSS') && sys.Version_<29
            % Update data function
            sys.DataFunction_ = ltvpack.interp.upgradeDF(sys.DataFunction_,false,sys.Version_);
         end
         if isa(sys,'ltvss')
            sys.Version_ = ltipack.ver();
         end
      end

      function sys = convert(X)
         % Safe conversion to LTVSS.
         %
         %   X = LTVSS.CONVERT(X) safely converts the variable X to LTVSS.
         if isnumeric(X) || isa(X,'StaticModel')
            X = double(X);
            sys = ltvss(@(t) ltvpack.staticDF(X));
         else
            sys = copyMetaData(X,ltvss_(X));
         end
      end

      function [nx,ny,nu,nfd] = validateData(A,B,C,D,E,dx0,x0,u0,y0,Delay,Ts)
         % Validate data from data function and acquire sizes.
         nx = size(A,1);
         if ~(isnumeric(A) && isequal(size(A),[nx nx]))
            error(message('Control:ltiobject:LTV3'))
         end
         if ~(isnumeric(D) && ismatrix(D))
            error(message('Control:ltiobject:LTV14'))
         end
         [nyz,nuw] = size(D);
         if (isempty(Delay) || ~isfield(Delay,'Internal'))
            nfd = 0;
         else
            nfd = numel(Delay.Internal);
         end
         ny = nyz-nfd;  nu = nuw-nfd;
         % Check consistency
         if ~(isnumeric(B) && isequal(size(B),[nx nuw]))
            error(message('Control:ltiobject:LTV4'))
         end
         if ~(isnumeric(C) && isequal(size(C),[nyz nx]))
            error(message('Control:ltiobject:LTV5'))
         end
         if ~(isempty(E) || (isnumeric(E) && isequal(size(E),[nx nx])))
            error(message('Control:ltiobject:LTV6'))
         end
         if ~(isempty(dx0) || (isnumeric(dx0) && isequal(size(dx0),[nx 1])))
            error(message('Control:ltiobject:LTV9',nx))
         end
         if ~(isempty(x0) || (isnumeric(x0) && isequal(size(x0),[nx 1])))
            error(message('Control:ltiobject:LTV10',nx))
         end
         % Note: In general, u0,y0 are actually [u0;w0],[y0;z0]
         if ~(isempty(u0) || (isnumeric(u0) && isequal(size(u0),[nuw 1])))
            error(message('Control:ltiobject:LTV11',nuw))
         end
         if ~(isempty(y0) || (isnumeric(y0) && isequal(size(y0),[nyz 1])))
            error(message('Control:ltiobject:LTV12',nyz))
         end
         % Delay
         if ~isempty(Delay)
            if isfield(Delay,'Input')
               tau = Delay.Input;
               if ~isequal(size(tau),[nu 1])
                  error(message('Control:ltiobject:LTV19'))
               elseif ~(isnumeric(tau) && isreal(tau) && all(isnan(tau) | (tau>=0 & tau<Inf)))
                  error(message('Control:ltiobject:LTV7'))
               elseif Ts~=0 && ~isequaln(tau,round(tau))
                  error(message('Control:ltiobject:LTV21'))                  
               end
            end
            if isfield(Delay,'Output')
               tau = Delay.Output;
               if ~isequal(size(tau),[ny 1])
                  error(message('Control:ltiobject:LTV20'))
               elseif ~(isnumeric(tau) && isreal(tau) && all(isnan(tau) | (tau>=0 & tau<Inf)))
                  error(message('Control:ltiobject:LTV8'))
               elseif Ts~=0 && ~isequaln(tau,round(tau))
                  error(message('Control:ltiobject:LTV21'))                  
               end
            end
         end
      end

      function [x0,xp0] = impulseStateUpdate(A,E,f,b,x0,~)
         % Integrates the DAE
         %    E x'(t) = A x(t) + f + b * delta(t) ,  x(0-) = x0
         % through a Dirac impulse. Returns X0=x(0+) and the new state
         % derivative XP0=x'(0+).
         if isempty(E)
            x0 = x0 + b;
            xp0 = A*x0+f;
         else
            x0 = x0 + matlab.internal.math.nowarn.mldivide(E,b);
            xp0 = matlab.internal.math.nowarn.mldivide(E,A*x0+f);
         end
      end

   end

end
