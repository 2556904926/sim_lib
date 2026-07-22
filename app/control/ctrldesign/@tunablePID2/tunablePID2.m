classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      tunablePID2 < tunableLTI
   %tunablePID2  Tunable two-degree-of-freedom PID controller.
   %
   %   BLK = tunablePID2(NAME,TYPE) creates the 2-DOF continuous-time
   %   PID block
   %       u = Kp (b*r-y) + Ki/s (r-y) + Kd*s/(1+Tf*s) (c*r-y)
   %   where r is the setpoint command and y is the measured response to
   %   this command.
   %
   %                     +-----------+
   %             r ----->|           |
   %                     |    BLK    |------>  u
   %             y ----->|           |
   %                     +-----------+
   %
   %   This block is parameterized by the scalar gains Kp,Ki,Kd, the
   %   filter time constant Tf, and the scalar weights b and c. The string
   %   NAME specifies the block name and the string TYPE specifies the PID
   %   structure among the following:
   %      'P'    proportional only control (Ki=Kd=0, Kp free)
   %      'PI'   proportional-integral control (Kd=0, Kp,Ki free)
   %      'PD'   proportional-derivative control (Ki=0, Kp,Kd,Tf free)
   %      'PID'  proportional-integral-derivative control (Kp,Ki,Kd,Tf free)
   %
   %   BLK = tunablePID2(NAME,TYPE,Ts) creates a discrete-time PID block
   %   with sample time Ts. The discrete PID equations are
   %      u = Kp (b*r-y) + Ki * IF(z) (r-y) + Kd/(Tf + DF(z)) (c*r-y)
   %   where IF(z) and DF(z) are the discrete integrator formulas for the
   %   integral and derivative terms. The default formulas are
   %      IF(z) = DF(z) = Ts/(z-1)    (Forward Euler).
   %   To use the Backward Euler or Trapezoidal formulas instead, set the
   %   "IFormula" and "DFormula" properties of BLK accordingly.
   %
   %   BLK = tunablePID2(NAME,SYS) uses the LTI model SYS to set the PID
   %   structure, sample time, and initial values of the block parameters.
   %   The model SYS must be compatible with the 2-DOF PID formulas above.
   %
   %   You can modify the PID structure by fixing or freeing any of the
   %   parameters Kp, Ki, Kd, Tf, b, c. For example, BLK.Tf.Free = false
   %   fixes Tf to its current value. Use SYSTUNE or LOOPTUNE to
   %   automatically tune the free parameters of BLK.
   %
   %   Example: Create a tunable 2-DOF PI controller with b=1, c=0.5, and
   %   a fixed derivative filter time constant Tf:
   %      blk = tunablePID2('demo','PI');
   %      blk.b.Value = 1;         % initialize b to 1
   %      blk.c.Value = 0.5;       % initialize c to 0.5
   %      blk.Tf.Value = 0.01;     % set Tf to 0.01
   %      blk.Tf.Free = false;     % fix Tf to this value
   %
   %   See also tunablePID, tunableTF, tunableSS, tunableBlock,
   %   pid2, pid, systune, looptune.
   
   %   Author(s): P. Gahinet
   %   Copyright 1986-2014 The MathWorks, Inc.
   
   % Note: The optimization interface uses the parameterization
   %         Kp + Ki * IF + Kd * N / (1 + N * DF)
   % where N = 1/Tf and IF,DF are the integrator formulas for the I and D
   % terms. This avoid the discontinuity at Tf=0 (PID becomes improper and
   % pole changes sign at Inf)
   
   properties (Access = public, Dependent)
      % Proportional gain (scalar parameter).
      %
      % Use this property to read the current value of the proportional gain Kp
      % or to initialize, fix, or free this tunable parameter.
      Kp
      % Integral gain (scalar parameter).
      %
      % Use this property to read the current value of the integral gain Ki
      % or to initialize, fix, or free this tunable parameter.
      Ki
      % Derivative gain (scalar parameter).
      %
      % Use this property to read the current value of the derivative gain Kd
      % or to initialize, fix, or free this tunable parameter.
      Kd
      % Time constant for derivative filter (scalar parameter).
      %
      % Use this property to read the current value of the time constant Tf
      % or to initialize, fix, or free this tunable parameter.
      Tf
      % Setpoint weight in proportional term (scalar parameter).
      %
      % Use this property to read the current value of the setpoint weight b
      % or to initialize, fix, or free this tunable parameter.
      b
      % Setpoint weight in derivative term (scalar parameter).
      %
      % Use this property to read the current value of the setpoint weight c
      % or to initialize, fix, or free this tunable parameter.
      c
      % Discrete integrator formula for integral term.
      %
      % Set this property to 'ForwardEuler', 'BackwardEuler' or 'Trapezoidal'
      % to select the formula Ts/(z-1), Ts*z/(z-1), or (Ts/2)*(z+1)/(z-1),
      % respectively.
      IFormula
      % Discrete integrator formula for derivative term.
      %
      % Set this property to 'ForwardEuler', 'BackwardEuler' or 'Trapezoidal'
      % to select the formula Ts/(z-1), Ts*z/(z-1), or (Ts/2)*(z+1)/(z-1),
      % respectively.
      DFormula
   end
   
   properties (Access = protected)
      Kp_
      Ki_
      Kd_
      Tf_
      b_
      c_
      IFormula_ = 'F';  % default = ForwardEuler
      DFormula_ = 'F';  % default = ForwardEuler
   end
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genss';
      end
      
      % Note: getAttributes never called (first converted to GENSS)
   end
   
   
   % CONSTRUCTION, INITIALIZATION, CONVERSION
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods
      
      function blk = tunablePID2(Name,varargin)
         ni = nargin;
         blk.IOSize_ = [1,2];
         if ni==0
            return
         end
         TypeSpec = (ni==2 || ni==3) && (ischar(varargin{1}) || isstring(varargin{1}));
         % Parse inputs
         try
            if TypeSpec
               % tunablePID2(name,type{,Ts})
               % Validate type
               Type = ltipack.matchKey(varargin{1},{'p','pi','pd','pid'});
               if isempty(Type)
                  ctrlMsgUtils.error('Control:lftmodel:ltiblockPID2DOF1')
               end
               if ni==2
                  Ts = 0;
               else
                  Ts = ltipack.utValidateTs(varargin{2});
               end
               [Kp,Ki,Kd,Tf,b,c] = localInitParameters(Type,Ts);
            elseif ni==2
               % tunablePID2(name,sys)
               sys = varargin{1};
               if ~isequal(size(sys),[1 2])
                  error(message('Control:lftmodel:ltiblockPID2DOF4'))
               elseif isnumeric(sys)
                  sys = tf(sys);
               end
               try
                  sys = pid2(sys);
               catch ME %#ok<*NASGU>
                  if strcmp(ME.identifier, 'Control:ltiobject:pid2DOFNegativeBC')
                     error(message('Control:lftmodel:ltiblockPID2DOF16'))
                  else
                     error(message('Control:lftmodel:ltiblockPID2DOF2'))
                  end
               end
               
               [Kp,Ki,Kd,Tf,b,c,Ts] = piddata2(sys);
               if Tf==0
                  % Improper PID not allowed
                  if Kd==0
                     Tf = (Ts==0) + 10*Ts;
                  else
                     error(message('Control:lftmodel:ltiblockPID2DOF3'))
                  end
               end
            else
               error(message('Control:general:InvalidSyntaxForCommand','tunablePID2','tunablePID2'))
            end
         catch ME
            throw(ME)
         end
         
         % Construct block
         blk.Kp_ = param.Continuous('Kp',Kp);
         blk.Ki_ = param.Continuous('Ki',Ki);
         blk.Kd_ = param.Continuous('Kd',Kd);
         blk.Tf_ = param.Continuous('Tf',Tf);
         % Constrain Tf to [0,Inf] so that 1/Tf varies in connected domain
         blk.Tf_.Minimum = 0;
         blk.b_ = param.Continuous('b',b);
         blk.b_.Minimum = 0;
         blk.c_ = param.Continuous('c',c);
         blk.c_.Minimum = 0;
         if TypeSpec
            % TYPE string determines formula
            blk.Ki_.Free = any(Type=='i');
            blk.Kd_.Free = any(Type=='d');
         else
            % Inherits metadata and formulas from PID object
            blk.Ki_.Free = (Ki~=0);
            blk.Kd_.Free = (Kd~=0);
            % Note: Overwrites Name!
            blk = copyMetaData(sys,blk);
            blk.TimeUnit = sys.TimeUnit;
            blk.IFormula = sys.IFormula;
            blk.DFormula = sys.DFormula;
         end
         blk.Tf_.Free = blk.Kd_.Free;
         blk.c_.Free = blk.Kd_.Free;
         try
            blk.Ts = Ts;      % errors if Ts=-1
            blk.Name = Name;  % errors if Name is not a variable name
         catch ME
            throw(ME)
         end
      end
      
      function Value = get.Kp(blk)
         % GET method for Kp property
         Value = blk.Kp_;
      end
      
      function Value = get.Ki(blk)
         % GET method for Ki property
         Value = blk.Ki_;
      end
      
      function Value = get.Kd(blk)
         % GET method for Kd property
         Value = blk.Kd_;
      end
      
      function Value = get.Tf(blk)
         % GET method for Tf property
         Value = blk.Tf_;
      end
      
      function Value = get.b(blk)
         % GET method for b property
         Value = blk.b_;
      end
      
      function Value = get.c(blk)
         % GET method for c property
         Value = blk.c_;
      end
      
      function Value = get.IFormula(blk)
         % GET method for IFormula property
         Value = ltipack.getPIDFormula(blk.IFormula_,blk.Ts_);
      end
      
      function Value = get.DFormula(blk)
         % GET method for DFormula property
         Value = ltipack.getPIDFormula(blk.DFormula_,blk.Ts_);
      end
      
      function blk = set.Kp(blk,Value)
         % SET method for Kp property
         blk.Kp_ = pmodel.checkParameter(Value,'Kp',[1 1]);
      end
      
      function blk = set.Ki(blk,Value)
         % SET method for Ki property
         blk.Ki_ = pmodel.checkParameter(Value,'Ki',[1 1]);
      end
      
      function blk = set.Kd(blk,Value)
         % SET method for Kd property
         blk.Kd_ = pmodel.checkParameter(Value,'Kd',[1 1]);
      end
      
      function blk = set.Tf(blk,pTf)
         % SET method for Tf property
         pTf = pmodel.checkParameter(pTf,'Tf',[1 1]);
         if pTf.Value==0
            error(message('Control:lftmodel:ltiblockPID5'))
         elseif pTf.Value<0 || pTf.Minimum<0 || pTf.Maximum<=0
            error(message('Control:lftmodel:ltiblockPID13'))
         end
         blk.Tf_ = pTf;
      end
      
      function blk = set.b(blk,Value)
         % SET method for b property
         p = pmodel.checkParameter(Value,'b',[1 1]);
         if p.Value<0 || p.Minimum<0 || p.Maximum<=0
            error(message('Control:lftmodel:ltiblockPID2DOF14'))
         end
         blk.b_ = p;
      end
      
      function blk = set.c(blk,Value)
         % SET method for c property
         p = pmodel.checkParameter(Value,'c',[1 1]);
         if p.Value<0 || p.Minimum<0 || p.Maximum<=0
            error(message('Control:lftmodel:ltiblockPID2DOF15'))
         end
         blk.c_ = p;
      end
      
      function blk = set.IFormula(blk,Value)
         % SET method for IFormula property
         blk.IFormula_ = ltipack.setPIDFormula(Value);
      end
      
      function blk = set.DFormula(blk,Value)
         % SET method for DFormula property
         blk.DFormula_ = ltipack.setPIDFormula(Value);
      end
      
      function T = getType(blk)
         % Controller type
         T = 'P';
         if isempty(blk.Ki_) || blk.Ki_.Value~=0 || blk.Ki_.Free
            T = [T 'I'];
         end
         if isempty(blk.Kd_) || blk.Kd_.Value~=0 || blk.Kd_.Free
            T = [T 'D'];
         end
      end
      
   end
   
   %% SUPERCLASS INTERFACES
   methods (Access=protected)
      
      function displaySize(blk,~)
         % Display for "size(sys)"
         disp(ctrlMsgUtils.message('Control:lftmodel:SizePID2',getType(blk)))
      end
      
      % PARAMETRIC BLOCK
      function np = nparams_(blk,varargin)
         % Number of parameters
         if nargin>1
            np = numel(find(isfree_(blk)));
         else
            np = 6;
         end
      end
      
      function isf = isfree_(blk)
         % True for free parameters
         isf = [blk.Kp_.Free ; blk.Ki_.Free ; blk.Kd_.Free ; ...
            blk.Tf_.Free ; blk.b_.Free ; blk.c_.Free];
      end
      
      function blk = zeroThru_(blk,mustZero)
         % Fix specified entries of block feedthrough to zero to eliminate
         % feedthrough term in H2 goals
         if mustZero
            if blk.Kp_.Free
               blk.Kp_.Value = 0;  blk.Kp_.Free = false;
            end
            if blk.Kd_.Free
               blk.Kd_.Value = 0;  blk.Kd_.Free = false;
            end
         end
      end
      
      function p = getp_(blk,varargin)
         % Get vector of parameter values
         % Note: p set to [Kp.;Ki;Kd;1/Tf;b;c] rather than [Kp.;Ki;Kd;Tf;b;c]
         p = [blk.Kp_.Value ; blk.Ki_.Value ; blk.Kd_.Value ; ...
            1/blk.Tf_.Value ; blk.b_.Value ; blk.c_.Value];
         if nargin>1
            p = p([blk.Kp_.Free ; blk.Ki_.Free ; blk.Kd_.Free ; ...
               blk.Tf_.Free ; blk.b_.Free ; blk.c_.Free]);
         end
      end
      
      function [pMin,pMax] = getpMinMax_(blk)
         % Get parameter bounds
         % Note: Tf.Minimum>0 required for reciprocal 1/Tf to vary in interval
         pMin = [blk.Kp_.Minimum ; blk.Ki_.Minimum ; blk.Kd_.Minimum ; ...
            1/blk.Tf_.Maximum ; blk.b_.Minimum ; blk.c_.Minimum];
         pMax = [blk.Kp_.Maximum ; blk.Ki_.Maximum ; blk.Kd_.Maximum ; ...
            1/blk.Tf_.Minimum ; blk.b_.Maximum ; blk.c_.Maximum];
      end
      
      function blk = setp_(blk,p,varargin)
         % Set vector of parameter values
         np = length(p);
         if nargin==2
            if np~=6
               ctrlMsgUtils.error('Control:pmodel:setp')
            end
            blk.Kp_.Value = p(1);
            blk.Ki_.Value = p(2);
            blk.Kd_.Value = p(3);
            blk.Tf_.Value = 1/p(4);
            blk.b_.Value = p(5);
            blk.c_.Value = p(6);
         else
            try %#ok<TRYNC>
               ip = 0;
               if blk.Kp_.Free
                  ip = ip+1; blk.Kp_.Value = p(ip);
               end
               if blk.Ki_.Free
                  ip = ip+1; blk.Ki_.Value = p(ip);
               end
               if blk.Kd_.Free
                  ip = ip+1; blk.Kd_.Value = p(ip);
               end
               if blk.Tf_.Free
                  ip = ip+1; blk.Tf_.Value = 1/p(ip);
               end
               if blk.b_.Free
                  ip = ip+1; blk.b_.Value = p(ip);
               end
               if blk.c_.Free
                  ip = ip+1; blk.c_.Value = p(ip);
               end
            end
            if ip~=np
               ctrlMsgUtils.error('Control:pmodel:setp')
            end
         end
      end
      
      function P = randp_(blk,N,varargin)
         % Generates random samples of model parameters.
         R = rand(6,N);
         P = [10.^(4*R(1,:)-2) ; 10.^(2*R([2 3],:)-2) ; 20*R(4,:) ; R(5:6,:)];
         % Enforce bounds
         [pMin,pMax] = getpMinMax(blk);
         ix = find(isfinite(pMin) | isfinite(pMax));
         P(ix,:) = pmodel.randBounded(N,pMin(ix),pMax(ix));
         if nargin>2
            P = P(isfree_(blk),:);
         end
      end
      
      function sys = pid2_(blk,Options)
         % Converts to @pid2
         D = ltipack_piddataP2(blk);
         if nargin>1
            D = pid2(D,Options);
         end
         sys = pid2.make(D);
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pidstd2_(blk,varargin)
         % Converts to @pidstd2
         sys = pidstd2.make(pidstd2(ltipack_piddataP2(blk),varargin{:}));
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function D = ltipack_piddataP2(blk)
         % Converts to ltipack.piddataP2 object
         [Kp,Ki,Kd,Tf,b,c,Ts] = piddata2_(blk); %#ok<*PROP>
         D = ltipack.piddataP2(Kp,Ki,Kd,Tf,b,c,Ts);
         if Ts~=0
            D.IFormula = blk.IFormula_;
            D.DFormula = blk.DFormula_;
         end
      end
   end
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      
      %% MODEL CHARACTERISTICS
      function boo = isreal_(blk,~)
         % Returns true if the current values of the PID coefficients are real
         boo = isreal(blk.Kp_.Value) && isreal(blk.Ki_.Value) && ...
            isreal(blk.Kd_.Value) && isreal(blk.Tf_.Value) && ...
            isreal(blk.b_.Value) && isreal(blk.c_.Value);
      end
      
      function boo = isstatic_(blk,~)
         % A PID block is static if its current value has no states. This
         % ensures ISSTATIC returns the same value for BLK and SS(BLK).
         boo = (blk.Ki_.Value==0 && blk.Kd_.Value==0);
      end
      
      function ns = order_(blk)
         % Number of states in current value of the block (same as ORDER(SS(BLK)))
         ns = (blk.Ki_.Value~=0) + (blk.Kd_.Value~=0);
      end
      
      function boo = isstable_(blk,varargin)
         boo = isstable(ltipack_ssdata(blk))==1;
      end
      
      function [A,B,C,D,Ts] = ssdata_(blk,varargin)
         % Explicit state-space data for current block value
         if ~isequal(1,1,varargin{:})
            ctrlMsgUtils.error('Control:ltiobject:access2')
         end
         Kp = blk.Kp_.Value; %#ok<*PROPLC>
         Ki = blk.Ki_.Value;
         Kd = blk.Kd_.Value;
         N = 1/blk.Tf_.Value;
         b = blk.b_.Value;
         c = blk.c_.Value;
         Ts = blk.Ts_;
         A = []; B = zeros(0,2); C = zeros(1,0); D = [Kp*b,-Kp]; %P
         if Ts==0
            % Continuous time
            if Ki~=0
               A = blkdiag(A, 0);  B = [B; 1 -1];  C = [C Ki];
            end
            if Kd~=0
               A = blkdiag(A, -N); B = [B; -N*c N]; C = [C Kd*N];
               D = D + [Kd*N*c , -Kd*N];
            end
         else
            % Discrete time
            alphas = [0 Ts Ts/2];  % for 'F','B','T' formulas
            if Ki~=0
               A = blkdiag(A, 1);  B = [B; Ts -Ts];  C = [C Ki];
               D = D + (Ki * alphas(blk.IFormula(1)=='FBT')) * [1 -1];
            end
            if Kd~=0
               beta = 1/N + alphas(blk.DFormula(1)=='FBT');  % 1/N + {0,Ts,Ts/2}
               aux1 = Ts/beta;
               aux2 = Kd/beta;
               A = blkdiag(A, 1-aux1); B = [B; aux1*[-c,1]]; C = [C aux2];
               D = D + aux2*[c,-1];
            end
         end
      end
      
      function [Kp,Ki,Kd,Tf,b,c,Ts] = piddata2_(blk,varargin)
         % Extract 2-DOF PID coefficients
         if ~isequal(1,1,varargin{:})
            ctrlMsgUtils.error('Control:ltiobject:access2')
         end
         Kp = blk.Kp_.Value;
         Ki = blk.Ki_.Value;
         Kd = blk.Kd_.Value;
         Tf = blk.Tf_.Value;
         b = blk.b_.Value;
         c = blk.c_.Value;
         Ts = blk.Ts_;
      end
      
      function [Kp,Ti,Td,N,b,c,Ts] = pidstddata2_(blk,varargin)
         % Extract 2-DOF PIDSTD coefficients
         if ~isequal(1,1,varargin{:})
            ctrlMsgUtils.error('Control:ltiobject:access2')
         else
            try
               D = pidstd2(ltipack_piddataP2(blk));
            catch ME
               ctrlMsgUtils.error('Control:ltiobject:pidstddata21')
            end
            Kp = D.Kp;  Ti = D.Ti;  Td = D.Td;  N = D.N;  b = D.b; c = D.c; Ts = blk.Ts_;
         end
      end
      
      %% ANALYSIS
      function [m,p,w,FocusInfo,sdm,sdp] = magphaseresp_(blk,grade,wspec)
         [m,p,w,FocusInfo] = magphaseresp_(tf_(blk),grade,wspec);
         sdm = []; sdp = []; % default for systems with no covariance info
      end
      
      function varargout = nyquistresp_(blk,wspec)
         [varargout{1:nargout}] = nyquistresp_(tf_(blk),wspec);
      end
      
      %% TRANSFORMATIONS & CONVERSIONS
      function blk = chgTimeUnit_(blk,newUnits)
         % Change time units without altering system behavior
         sf = tunitconv(blk.TimeUnit,newUnits);
         % Rescale gains according to tnew = sf * told
         blk.Ki.Value = blk.Ki.Value/sf;
         blk.Ki.Minimum = blk.Ki.Minimum/sf;
         blk.Ki.Maximum = blk.Ki.Maximum/sf;
         blk.Ki.Scale = blk.Ki.Scale/sf;
         blk.Kd.Value = sf * blk.Kd.Value;
         blk.Kd.Minimum = sf * blk.Kd.Minimum;
         blk.Kd.Maximum = sf * blk.Kd.Maximum;
         blk.Kd.Scale = sf * blk.Kd.Scale;
         blk.Tf.Value = sf * blk.Tf.Value;
         blk.Tf.Minimum = sf * blk.Tf.Minimum;
         blk.Tf.Maximum = sf * blk.Tf.Maximum;
         blk.Tf.Scale = sf * blk.Tf.Scale;
         % Update Ts and TimeUnit
         if blk.Ts_>0
            blk.Ts_ = sf * blk.Ts_;
         end
         blk.TimeUnit = newUnits; % direct set
      end
      
      function sys = ss_(blk,varargin)
         % Converts current block value to @ss
         sys = ss.make(ltipack_ssdata(blk));
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = getValue_(blk)
         % Returns current value
         sys = pid2(blk);
      end
      
      function blk = setValue_(blk,sys)
         Ts = blk.Ts_;
         if Ts>0 && isa(sys,'DynamicSystem') && sys.Ts<0
            % Resolve SYS.Ts=-1 to Ts to prevent error in CONVERT
            sys.Ts = Ts;
         end
         try
            % Safely convert to PID2 in the presence of tunable blocks,
            % double,...
            sys = pid2.convert(sys);  % safe in the presence of tunable sys
            sys = pid2(sys,'IFormula',blk.IFormula_,'DFormula',blk.DFormula_);
         catch ME
            error(message('Control:lftmodel:ltiblockPID2DOF11',blk.Name))
         end
         try
            sys = alignSampleTime(sys,Ts,blk.TimeUnit);
         catch ME
            error(message('Control:lftmodel:setValue1',blk.Name))
         end
         % Note: PIDDATA does not allow Tf<0 but may return Tf=0 (pure D)
         [Kp,Ki,Kd,Tf,b,c] = piddata2(sys);
         if Tf==0
            if Kd~=0
               error(message('Control:lftmodel:ltiblockPID12',blk.Name))
            else
               Tf = 1;  % Set Tf=1 when Kd=0
            end
         end
         blk.Kp_.Value = Kp;
         blk.Ki_.Value = Ki;
         blk.Kd_.Value = Kd;
         blk.b_.Value = b;
         blk.c_.Value = c;
         blk.Tf_.Value = Tf;
      end
      
      %% ANALYSIS
      function p = pole_(blk,varargin)
         % Poles of current block value
         p = zeros(0,1);
         Ts = blk.Ts_;
         if blk.Ki_.Value~=0
            p = [p ; (Ts~=0)];
         end
         if blk.Kd_.Value~=0
            Tf = blk.Tf_.Value;
            if Ts==0
               p = [p ; -1/Tf];
            else
               switch blk.DFormula_
                  case 'F'
                     p = [p ; 1-Ts/Tf];
                  case 'B'
                     p = [p ; Tf/(Tf+Ts)];
                  case 'T'
                     p = [p ; (2*Tf-Ts)/(2*Tf+Ts)];
               end
            end
         end
      end
      
   end
   
   
   %% HIDDEN INTERFACES
   methods (Hidden)
      
      %% CONTROLDESIGNBLOCK
      function Offset = getOffset(blk)
         % Feedthrough value
         Ts = blk.Ts_;
         if Ts==0
            Offset = blk.Kp_.Value * [blk.b_.Value , -1] + ...
               (blk.Kd_.Value / blk.Tf_.Value) * [blk.c_.Value , -1];
         else
            alphas = [0 Ts Ts/2];
            Offset = blk.Kp_.Value * [blk.b_.Value , -1] + ...
               blk.Ki_.Value * alphas(blk.IFormula(1)=='FBT') * [1 -1] + ...
               (blk.Kd_.Value / (blk.Tf_.Value + alphas(blk.DFormula(1)=='FBT'))) * [blk.c_.Value , -1];
         end
      end
      
      function D = ltipack_ssdata(blk,~,S)
         % Converts to ltipack.ssdata object
         [a,b,c,d,Ts] = ssdata_(blk);
         if nargin>1
            d = d-S;
         end
         D = ltipack.ssdata(a,b,c,d,[],Ts);
         if ~isempty(a)
            D.StateName = getStateName(blk);
         end
      end
      
      function str = getDescription(blk,ncopies)
         % Short description for block summary in LFT model display
         str = ctrlMsgUtils.message('Control:lftmodel:ltiblockPID2DOF6',...
            blk.Name,ncopies);
      end
      
      function [As,Bs,Cs,D0,Dsf] = sInfo(blk)
         % Structural information about (A,B,C,D) contribution of BLK-S
         % to the closed-loop model LFT(H(s),blkdiag(Bj-Sj)). Due to the
         % block offset S, the structure of the feedthrough D is captured
         % by its initial value D0 and its free (tunable) entries Dsf.
         [~,~,~,D0,Ts] = ssdata_(blk);
         As = false(0); Bs = false(0,2); Cs = false(1,0);
         % D = [Kp*b,-Kp], Dsf(1)=true iff Kp*b free
         Dsf = [isFreeProduct(blk.Kp_,blk.b_) , blk.Kp_.Free];
         nx = 0;
         % I term
         if sInfo(blk.Ki_)
            % Ki is not fixed to zero
            nx = nx+1;
            As(nx,nx) = (Ts~=0);  Bs(nx,:) = true(1,2);  Cs(1,nx) = true;
            if Ts>0 && any(blk.IFormula(1)=='BT')
               Dsf = Dsf | blk.Ki_.Free; % free Ki makes D tunable
            end
         end
         % D term
         if sInfo(blk.Kd_)
            % Kd not fixed to zero and Tf>0
            % B = (1/Tf)*[c,-1], C = Kd/Tf, D = D+Kd/Tf*[c,-1]
            nx = nx+1;
            As(nx,nx) = true;  Cs(1,nx) = true;
            aux = blk.Kd_.Free || blk.Tf_.Free;
            if sInfo(blk.c_)
               % c is not fixed to zero -> Kd,Tf,c all nonzero
               Bs(nx,:) = true(1,2);
               Dsf = Dsf | [aux || blk.c_.Free , aux];
            else
               % c fixed to 0
               Bs(nx,:) = [false,true];
               Dsf = Dsf | [false , aux];
            end
         end
      end
      
      %% OPTIMIZATION
      function ns = numState(blk)
         % Size of A matrix from p2ss (number of states in current
         % parameterization)
         ns =(blk.Ki_.Free || blk.Ki_.Value~=0) + ...
            (blk.Kd_.Free || blk.Kd_.Value~=0);
      end
      
      function [a,b,c,d] = p2ss(blk,p)
         % Constructs realization from parameter vector p=[Kp Ki Kd N b c]
         % where N = 1/Tf.
         % Note: Can't use change of variable R=Kd*N because this would
         % prevent independently fixing Kd and N.
         Ki = blk.Ki_;
         Kd = blk.Kd_;
         Ts = blk.Ts_;
         a = []; b = zeros(0,2); c = zeros(1,0); d = p(1)*[p(5),-1];
         nx = 0;
         if Ts==0
            % Continuous time
            if Ki.Free || Ki.Value~=0
               % I term
               nx = nx+1;
               a(nx,nx) = 0;  b(nx,:) = [1 -1];  c(1,nx) = p(2);
            end
            if Kd.Free || Kd.Value~=0
               % D term
               nx = nx+1;
               aux1 = p(3)*p(4);
               aux2 = [p(6) -1];
               a(nx,nx) = -p(4);  b(nx,:) = -p(4)*aux2;
               c(1,nx) = aux1;  d = d+aux1*aux2;
            end
         else
            alphas = [0 Ts Ts/2];  % for 'F','B','T' formulas
            if Ki.Free || Ki.Value~=0
               % I term
               nx = nx+1;
               a(nx,nx) = 1;  b(nx,:) = [Ts -Ts];  c(1,nx) = p(2);
               d = d + (p(2) * alphas(blk.IFormula(1)=='FBT')) * [1 -1];
            end
            if Kd.Free || Kd.Value~=0
               % D term
               nx = nx+1;
               beta = 1/p(4) + alphas(blk.DFormula(1)=='FBT');  % 1/N + {0,Ts,Ts/2}
               aux1 = Ts/beta;
               aux2 = p(3)/beta;
               a(nx,nx) = 1-aux1;  b(nx,:) = aux1*[-p(6),1];
               c(1,nx) = aux2;  d = d+aux2*[p(6),-1];
            end
         end
      end
      
      %------------------------------------------------
      function gj = gradUV(blk,p,u,v,j)
         % Computes the gradient of the inner product
         %    phi(p) = Re(Trace(U'*[A(p) B(p);C(p) D(p)]*V))
         % with respect to the block parameters p(j) where j is a vector
         % of indices. The real or complex matrices U and V must have the
         % same number of columns.
         % p = [Kp Ki Kd N b c]
         W = real(u*v');
         nx = size(u,1)-1;
         b = p(5);
         c = p(6);
         Ts = blk.Ts_;
         if Ts==0
            if nx==0
               % P control
               g = [b*W(1)-W(2);0;0;0;p(1)*W(1);0];
            elseif nx==2
               % PID control
               aux1 = c*W(3,3)+W(3,2)-W(3,4);  % u3*(c*v3+v2-v4)
               aux2 = c*W(2,3)+W(2,2)-W(2,4);  % u2*(c*v3+v2-v4)
               g = [b*W(3,3)-W(3,4);...
                  W(3,1);...
                  p(4)*aux1;
                  p(3)*aux1-aux2;
                  p(1)*W(3,3);
                  p(4)*(p(3)*W(3,3)-W(2,3))];
            else
               Ki = blk.Ki_;
               if Ki.Free || Ki.Value~=0
                  % PI control
                  g = [b*W(2,2)-W(2,3);W(2,1);0;0;p(1)*W(2,2);0];
               else
                  % PD control
                  aux1 = c*W(2,2)+W(2,1)-W(2,3);
                  aux2 = c*W(1,2)+W(1,1)-W(1,3);
                  g = [b*W(2,2)-W(2,3);...
                     0;...
                     p(4)*aux1;...
                     p(3)*aux1-aux2;...
                     p(1)*W(2,2);...
                     p(4)*(p(3)*W(2,2)-W(1,2))];
               end
            end
         else
            alphas = [0 Ts Ts/2];
            if nx==0
               % P control
               g = [b*W(1)-W(2);0;0;0;p(1)*W(1);0];
            elseif nx==2
               % PID control
               aux = c*W(3,3)+W(3,2)-W(3,4);  % u3*(cv3+v2-v4)
               theta = 1+p(4)*alphas(blk.DFormula(1)=='FBT');
               Ntheta = p(4)/theta;  % N/theta
               dI = alphas(blk.IFormula(1)=='FBT');
               g = [b*W(3,3)-W(3,4) ;...
                  W(3,1)+dI*(W(3,3)-W(3,4)) ;...
                  Ntheta*aux ;...
                  (p(3)*aux-Ts*(c*W(2,3)+W(2,2)-W(2,4)))/theta^2 ;...
                  p(1)*W(3,3) ; ...
                  Ntheta*(p(3)*W(3,3)-Ts*W(2,3))];
            else
               Ki = blk.Ki_;
               if Ki.Free || Ki.Value~=0
                  % PI control
                  g = [b*W(2,2)-W(2,3) ;...
                     W(2,1)+alphas(blk.IFormula(1)=='FBT')*(W(2,2)-W(2,3)) ;...
                     0 ; 0 ; p(1)*W(2,2) ; 0];
               else
                  % PD control
                  aux = c*W(2,2)+W(2,1)-W(2,3);
                  theta = 1+p(4)*alphas(blk.DFormula(1)=='FBT');
                  Ntheta = p(4)/theta;
                  g = [b*W(2,2)-W(2,3) ;...
                     0 ;...
                     Ntheta*aux ;...
                     (p(3)*aux-Ts*(c*W(1,2)+W(1,1)-W(1,3)))/theta^2 ;...
                     p(1)*W(2,2) ; ...
                     Ntheta*(p(3)*W(2,2)-Ts*W(1,2))];
               end
            end
         end
         gj = g(j);
      end
      
      % LFTBlockWrapper
      function SNU = getStateInfo(blk,Prop)
         % Get state names or units
         if strcmp(Prop,'StateName')
            SNU = getStateName(blk);
         else
            SNU = strings((blk.Ki_.Value~=0)+(blk.Kd_.Value~=0),1);
         end
      end
      
   end
   
   
   %% UTILITIES
   methods (Access=protected)
      
      function StateName = getStateName(blk)
         % Returns vector of state names
         StateName = strings(0,1);
         if blk.Ki_.Value~=0
            StateName = [StateName ; blk.Name + ".Integ"];
         end
         if blk.Kd_.Value~=0
            StateName = [StateName ; blk.Name + ".Deriv"];
         end
      end
      
   end
   
   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter for tunablePID2 objects
         blk = DynamicSystem.updateMetaData(s);
         blk.Version_ = ltipack.ver();
      end
      
   end
   
end

%-----------------------------------------------------------
% Utility Functions
%-----------------------------------------------------------
function [Kp,Ki,Kd,Tf,b,c] = localInitParameters(Type,Ts)
% Initialize the Value and Free properties of parameters P, I, D, N.
% Shape of PID response is independent of Ts, Kp is set to zero to avoid
% initial block offset.
Ts = Ts + (Ts==0);
Tf = Ts;
if any(Type=='i')
   Ki = 0.001;
else
   Ki = 0;
end
Kp = 0;  Kd = 0;  % satisfies zero feedthrough requirement
b = 1;  c = 1;    % corresponds to 1dof PID
end

function boo = isFreeProduct(x,y)
% Checks if x*y is free
boo = (x.Free && y.Free) || ...
   (x.Free && y.Value~=0) || (x.Value~=0 && y.Free);
end
