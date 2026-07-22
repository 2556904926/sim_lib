classdef (CaseInsensitiveProperties, TruncatedProperties, SupportExtensionMethods, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      lpvss < ltvss
   %LPVSS  Linear parameter-varying state-space model.
   %
   %  Construction:
   %    VSYS = LPVSS(ParamNames,FCN) creates a continuous-time LPV model of 
   %    the form
   % 
   %    E(t,p) dx/dt = dx0(t,p) + A(t,p) (x-x0(t,p)) + B(t,p) (u-u0(t,p))
   %               y =  y0(t,p) + C(t,p) (x-x0(t,p)) + D(t,p) (u-u0(t,p))
   %
   %    where 
   %       * p is a vector of time-dependent exogenous parameters
   %       * dx0,x0,u0,y0 are time-dependent offsets.
   %    The cell array ParamNames specifies a name for each entry of p. The
   %    function FCN specifies how to calculate the matrices and offsets for 
   %    given (t,p) values. Its syntax must follow the template
   %
   %       [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(t,p)
   %
   %    All output arguments except A,B,C,D can be set to [] when absent for 
   %    all (t,p) values. To specify fixed or varying delays at the inputs
   %    or outputs, use a struct "Delay" with fields "Input" and "Output".
   %    If an input or output delay is zero for all t, specify it as NaN.
   %
   %    VSYS = LPVSS(ParamNames,FCN,Ts) creates a discrete-time LPV model
   %    with sample time Ts. In discrete time, t is replaced by the index k 
   %    counting the elapsed sampling periods (clock time is k*Ts) and FCN 
   %    takes k instead ot t as input: 
   %       [A,B,C,D,E,dx0,x0,u0,y0,Delay] = FCN(k,p).
   %
   %    VSYS = LPVSS(ParamNames,FCN,Ts,t0,p0) uses FCN(t0,p0) to determine 
   %    the number of states, inputs, and outputs. By default, LPVSS uses 
   %    (t0,p0)=(0,0).
   %
   %    You can set additional model properties by using name/value pairs.
   %    For example,
   %       vsys = LPVSS(ParamNames,FCN,'InputName','torque',...
   %                                  'StateName','position')
   %    also sets the input and state names. Type "properties(lpvss)" 
   %    for a complete list of model properties, and type 
   %       help lpvss.<PropertyName>
   %    for help on a particular property. For example, "help lpvss.StateName" 
   %    provides information about the "StateName" property.
   %
   %  Conversion:
   %    VSYS = LPVSS(VSYS) converts the model VSYS to LPVSS.
   %
   %    See also SSINTERPOLANT, PSAMPLE, LTVSS, SS, DYNAMICSYSTEM.
   
%   Author(s): P. Gahinet, P. Seiler, R. Singh.
%   Copyright 2022-2024 The MathWorks, Inc.
   
   % Public properties with restricted value
   properties (Access = public, Dependent)
      % Parameter names.
      %
      % This property can be set to:
      %  * A char vector for first-order models, for example, 'position'
      %  * A cell array of char vectors for models with two or more states,
      %    for example, {'position' ; 'velocity'}
      % Use the empty char array '' for unnamed states.
      ParameterName
   end
      

   properties (Access = protected)
      % String vector
      ParameterName_ = strings(0,1);
      % Validation parameters
      p0_ = [];
   end

   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'lpvss';
      end

      function T = superiorTypes()
         T = {'lpvss'};
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
      
      function sys = lpvss(varargin)
                  
         % Quick exits
         ni = nargin;
         if ni==0
            sys.IOSize_ = [0 0];  return
         elseif ni==1
            arg = varargin{1};
            if isa(arg,'lpvss')
               sys = arg;   return
            elseif isnumeric(arg)
               sys = lpvss.convert(arg); return
            elseif isa(arg,'StaticModel')
               sys = copyMetaData(arg,lpvss.convert(arg)); return
            end
         elseif ni<2
            error(message('Control:general:InvalidSyntaxForCommand','lpvss','lpvss'))
         end            
         % Dissect input list
         pNames = varargin{1};
         DataFcn = varargin{2};
         PVStart = ni+1;
         for ct=3:ni
            nextarg = varargin{ct};
            if ischar(nextarg) || isstring(nextarg)
               PVStart = ct;   break
            end
         end
         if PVStart>6
            error(message('Control:general:InvalidSyntaxForCommand','lpvss','lpvss'))
         end
         
         % Populate object
         try
            % Parameter names
            pNames = ltipack.mustBeStringVector(pNames,'ParameterName',false);
            if any(pNames=="") || numel(unique(pNames))<numel(pNames)
               error(message('Control:ltiobject:LPV1'))
            end
            sys.ParameterName_ = pNames;

            % Sample time
            if PVStart>3
               sys.Ts = varargin{3};
            end

            % Test value t0
            if PVStart>4
               t0 = varargin{4};
               if ~(isnumeric(t0) && isreal(t0) && isscalar(t0) && isfinite(t0))
                  error(message('Control:ltiobject:LTV1'))
               end
               sys.t0_ = t0;
            end

            % Test value p0
            if PVStart>5
               p0 = varargin{5};
               if ~(isnumeric(p0) && isreal(p0) && isvector(p0) && ...
                     allfinite(p0) && numel(p0)==numel(sys.ParameterName_))
                  error(message('Control:ltiobject:LPV2'))
               end
            else
               p0 = zeros(size(sys.ParameterName_));
            end
            sys.p0_ = p0(:);

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
      
      function Value = get.ParameterName(sys)
         % GET method for ParameterName property
         Value = cellstr(sys.ParameterName_);
      end
      
      function sys = set.ParameterName(sys,Value)
         % SET method for ParameterName property
         Value = ltipack.mustBeStringVector(Value,'ParameterName',false);
         if any(Value=="") || numel(unique(Value))<numel(Value)
            error(message('Control:ltiobject:LPV1'))
         end
         sys.ParameterName_ = Value;
         if sys.CrossValidation_
            try
               sys = checkConsistency(sys);
            catch ME
               throw(ME)
            end
         end
      end
                        
   end
   
   
      
   methods (Access = protected)

      function sys = validateDataFcn(sys)
         % Validate data function and resolve model sizes
         try
            [A,B,C,D,E,dx0,x0,u0,y0,Delay] = sys.DataFunction_(sys.t0_,sys.p0_);
         catch ME
            error(message('Control:ltiobject:LPV3',sprintf('%.3g',sys.t0_),ME.message))
         end
         [sys.Nx_,ny,nu,sys.Nfd_] = ltvss.validateData(A,B,C,D,E,dx0,x0,u0,y0,Delay,sys.Ts_);
         sys.IOSize_ = [ny nu];
      end

      
      %% INPUTOUTPUTMODEL ABSTRACT INTERFACE
      function displaySize(sys,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         np = numel(sys.ParameterName_);
         disp(getString(message('Control:ltiobject:SizeLPVSS1',ny,nu,sys.Nx_,np)))
      end

      function sys = checkDataConsistency(sys)
         % Check consistency of p-related data
         np = numel(sys.ParameterName_);
         if numel(sys.p0_)~=np
            if any(sys.p0_)
               error(message('Control:ltiobject:LPV5'))
            else
               % Automatically adjust p=0
               sys.p0_ = zeros(np,1);
            end
         end
         % Delegate remaining checks to superclass
         sys = checkDataConsistency@ltvss(sys);
      end
      
      %% DATA ABSTRACTION INTERFACE

      function boo = isstatic_(sys,~)
         S = functions(sys.DataFunction);
         boo = startsWith(S.function,'@(t,p)ltvpack.staticDF');
      end

      %% BINARY OPERATIONS
      function sys = plus_(sys1,sys2)
         % Parallel connection
         [sys1,sys2] = matchAttributes(sys1,sys2);
         [pNames,p0,ix1,ix2] = ltvpack.mergeParameters(...
            sys1.ParameterName_,sys2.ParameterName_,sys1.p0_,sys2.p0_);
         DF = @(t,p) ltvpack.parallelDF(sys1,sys2,t,p(ix1),p(ix2));
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = lpvss(pNames,DF,getTs_(sys1),t0,p0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function sys = mtimes_(sys1,sys2,ScalarFlags)
         % Series connection
         [sys1,sys2] = matchAttributes(sys1,sys2);
         [pNames,p0,ix1,ix2] = ltvpack.mergeParameters(...
            sys1.ParameterName_,sys2.ParameterName_,sys1.p0_,sys2.p0_);
         DF = @(t,p) ltvpack.seriesDF(sys1,sys2,ScalarFlags,t,p(ix1),p(ix2));
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = lpvss(pNames,DF,getTs_(sys1),t0,p0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function [sys,SingularFlag] = feedback_(sys1,sys2,indu,indy,sign)
         % Feedback connection
         SingularFlag = false; % no way to tell
         [sys1,sys2] = matchAttributes(sys1,sys2);
         [pNames,p0,ix1,ix2] = ltvpack.mergeParameters(...
            sys1.ParameterName_,sys2.ParameterName_,sys1.p0_,sys2.p0_);
         indu = reshape(indu,[1 numel(indu)]);
         indy = reshape(indy,[1 numel(indy)]);
         DF = @(t,p) ltvpack.feedbackDF(sys1,sys2,indu,indy,sign,t,p(ix1),p(ix2));
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = lpvss(pNames,DF,getTs_(sys1),t0,p0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function [sys,SingularFlag] = lft_(sys1,sys2,indu1,indy1,indu2,indy2)
         % LFT connection
         SingularFlag = false; % no way to tell
         [sys1,sys2] = matchAttributes(sys1,sys2);
         [pNames,p0,ix1,ix2] = ltvpack.mergeParameters(...
            sys1.ParameterName_,sys2.ParameterName_,sys1.p0_,sys2.p0_);
         DF = @(t,p) ltvpack.lftDF(sys1,sys2,indu1,indy1,indu2,indy2,t,p(ix1),p(ix2));
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = lpvss(pNames,DF,getTs_(sys1),t0,p0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function sys = iocat_(dim,sys1,sys2)
         % Horizontal or vertical concatenation
         [sys1,sys2] = matchAttributes(sys1,sys2);
         [pNames,p0,ix1,ix2] = ltvpack.mergeParameters(...
            sys1.ParameterName_,sys2.ParameterName_,sys1.p0_,sys2.p0_);
         if dim==1
            DF = @(t,p) ltvpack.vertcatDF(sys1,sys2,t,p(ix1),p(ix2));
         else
            DF = @(t,p) ltvpack.horzcatDF(sys1,sys2,t,p(ix1),p(ix2));
         end
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = lpvss(pNames,DF,getTs_(sys1),t0,p0);
         sys = mergeInfo_(sys,sys1,sys2);
      end

      function sys = append_(sys1,sys2)
         % Horizontal or vertical concatenation
         [sys1,sys2] = matchAttributes(sys1,sys2);
         [pNames,p0,ix1,ix2] = ltvpack.mergeParameters(...
            sys1.ParameterName_,sys2.ParameterName_,sys1.p0_,sys2.p0_);
         DF = @(t,p) ltvpack.appendDF(sys1,sys2,t,p(ix1),p(ix2));
         t0 = ltvpack.reconcileValidationTimes(sys1.t0_,sys2.t0_);
         sys = lpvss(pNames,DF,getTs_(sys1),t0,p0);
         sys = mergeInfo_(sys,sys1,sys2);
      end
      
      %% TRANSFORMATIONS
      function sysOut = ltvss_(sys)
         if isempty(sys.ParameterName_)
            % LPV with no parameters
            DF = sys.DataFunction_;
            sysOut = ltvss(@(t) DF(t,[]),getTs_(sys),sys.t0_);
            sysOut.StateName_ = sys.StateName_;
            sysOut.StatePath_ = sys.StatePath_;
            sysOut.StateUnit_ = sys.StateUnit_;
            sysOut.TimeUnit_ = sys.TimeUnit_;
         else
            error(message('Control:transformation:LPV1'))
         end
      end

      function sys = uminus_(sys)
         if isstatic(sys)
            % Preserve static nature
            [~,~,~,D] = sys.DataFunction(0,0);
            sys = lpvss.convert(-D);
         else
            sys.DataFunction_ = @(t,p) ltvpack.uminusDF(sys,t,p);
         end
      end

   end
   
   methods (Hidden)

      function np = nparam(sys)
         np = numel(sys.ParameterName_);
      end

      function boo = isLPV(~)
         boo = true;
      end

   end

   %% STATIC METHODS
   methods(Static, Hidden)
      
      function sys = loadobj(sys)
         if isa(sys,'lpvss')
            sys.Version_ = ltipack.ver();
         end
      end
      
      function sys = convert(X)
         % Safe conversion to LTVSS.
         %
         %   X = LTVSS.CONVERT(X) safely converts the variable X to LTVSS.
         if isnumeric(X) || isa(X,'StaticModel')
            X = double(X);
            sys = lpvss(cell(0,1),@(t,p) ltvpack.staticDF(X));
         else
            sys = copyMetaData(X,lpvss_(X));
         end
      end

      function [A,B,C,D,E,dx0,x0,u0,y0,Delay] = constant(~,~,A,B,C,D,E,Delay)
         dx0 = [];  x0 = [];  u0 = [];  y0 = [];
      end
      
   end
   
end
