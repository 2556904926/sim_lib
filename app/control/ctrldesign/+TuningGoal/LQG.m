classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
      LQG < TuningGoal.GenericIO & TuningGoal.SystemLevel
   % Linear-quadratic-Gaussian (LQG) goal for control system tuning.
   %
   %   This requirement lets you quantify control performance as an LQG cost.
   %   It is applicable to any control structure, not just the classical
   %   observer structure of optimal LQG control. The LQG cost is
   %         J = E ( z(t)' QZ z(t) )
   %   where z(t) is the system response to a white noise input vector w(t)
   %   with covariance
   %         E (w(t) w(t)') = QW .
   %   The vector w(t) typically consists of external inputs to the system
   %   such as noise, disturbances, or command, while the vector z(t)
   %   includes all system variables used to quantify performance (control
   %   signals, systems states and outputs). Note that J can also be written
   %   as an average over time:
   %                                     T
   %         J = lim    E( 1/T  Integral   z(t)' QZ z(t)  dt)
   %             T->oo                  0
   %
   %   R = TuningGoal.LQG(WNAME,ZNAME,QW,QZ) creates an LQG requirement R.
   %   The strings or cell arrays of strings WNAME and ZNAME specify the
   %   signals making up w(t) and z(t) by name. The matrices QW and QZ
   %   specify the noise covariance and performance weight. These matrices
   %   must be symmetric nonnegative definite. Use scalar values for QW and
   %   QZ to specify multiples of the identity matrix.
   %
   %   NOTE:
   %   1) When used as a hard goal (see SYSTUNE), this requirement imposes
   %      J<1. When used as a soft goal, it contributes J to the overall
   %      objective. Adjust QZ to properly scale these contributions.
   %   2) When tuning the control system in discrete time, the requirement
   %      assumes
   %            E(w[k]w[k]') = QW/Ts    (Ts = sample time)
   %      to ensure consistent results with tuning in the continuous domain.
   %      This assumes that w[k] is obtained by sampling continuous white noise
   %      w(t) with covariance QW. If w[k] is a truly discrete process with
   %      known covariance QWd, use the value QW = Ts*QWd in the requirement.
   %
   %   Set properties to further configure the requirement. For example,
   %      R = TuningGoal.LQG({'w','v'},{'y','u'},QWV,QYU)
   %      R.Name = 'LQG objective'
   %      R.Models = [2 3]
   %   names the requirement and restricts it to the second and third plant
   %   models. Type "help TuningGoal.LQG.<property name>" for details on
   %   individual properties. Use SYSTUNE and related commands to tune the
   %   control system parameters subject to this and other requirements.
   %
   %   See also TuningGoal.Variance, TuningGoal.WeightedVariance, DynamicSystem/norm,
   %   evalGoal, TuningGoal.Gain, TuningGoal, systune, looptune, slTuner.
   
   % Author: P. Gahinet
   % Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Noise covariance (matrix, default = identity).
      %
      % Specifies the covariance matrix QW of the noise inputs w(t):
      %      E (w(t) w(t)') = QW .
      % This must be a symmetric, nonnegative definite matrix with as many
      % rows as entries in the vector w(t). This matrix is diagonal if the
      % entries of w(t) are uncorrelated. A scalar value is interpreted as
      % a multiple of the identity matrix.
      NoiseCovariance = 1;
      
      % Performance weight (matrix, default = identity).
      %
      % Specifies the weight QZ for the performance signals z(t):
      %      J = E ( z(t)' QZ z(t) )
      % This must be a symmetric, nonnegative definite matrix with as many
      % rows as entries in the vector z(t). Use a diagonal matrix to
      % independently penalize or scale the contribution of each variable
      % in z. A scalar value is interpreted as a multiple of the identity
      % matrix.
      PerformanceWeight = 1;
   end
   
   methods
      
      % Constructor
      function this = LQG(InputName,OutputName,QW,QZ)
         narginchk(4,4)
         try
            this.Input = InputName;
            this.Output = OutputName;
            this.NoiseCovariance = QW;
            this.PerformanceWeight = QZ;
         catch ME
            throw(ME)
         end
      end
      
      function this = set.NoiseCovariance(this,Value)
         % SET function for NoiseCovariance
         if isempty(Value)
            this.NoiseCovariance = 1;
         else
            this.NoiseCovariance = localCheckWeight(Value,'QW');
         end
      end
      
      function this = set.PerformanceWeight(this,Value)
         % SET function for PerformanceWeight
         if isempty(Value)
            this.PerformanceWeight = 1;
         else
            this.PerformanceWeight = localCheckWeight(Value,'QZ');
         end
      end
      
   end
   
   methods (Access = protected)
      
      function boo = hasView_(~)
         boo = false;
      end
      
      function [H,fObj] = evalSpec_(this,CL)
         % Evaluates requirement for given closed-loop model
         H = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
         H = sminreal(getValue(H));
         [nz,nw] = size(H);
         Ts = abs(H.Ts);
         % Noise covariance
         QW = this.NoiseCovariance;
         if isscalar(QW)
            QW = QW * eye(nw);
         elseif size(QW,1)~=nw
            error(message('Control:tuning:LQG7'))
         end
         FW = localGetFactor(QW);
         % Performance weight
         QZ = this.PerformanceWeight;
         if isscalar(QZ)
            QZ = QZ * eye(nz);
         elseif size(QZ,1)~=nz
            error(message('Control:tuning:LQG8'))
         end
         FZ = localGetFactor(QZ);
         % Contruct outputs
         H = FZ' * H * FW;
         if Ts>0
            H = H/sqrt(Ts);
         end
         if nargout>1
            fObj = norm(H);
         end
      end
      
   end
   
   methods (Hidden)
      
      function validateGoal(this,CL)
         % Goal validation for GUI
         H = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
         [nz,nw] = size(H);
         QW = this.NoiseCovariance;
         QZ = this.PerformanceWeight;
         if ~(isscalar(QW) || size(QW,1)==nw)
            error(message('Control:systunegui:LQG1'))
         end
         if ~(isscalar(QZ) || size(QZ,1)==nz)
            error(message('Control:systunegui:LQG2'))
         end
      end
      
      function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
         % Builds standardized requirement description for SYSTUNE
         if isempty(this.Input) || isempty(this.Output)
            error(message('Control:tuning:TuningReq17',getID(this)))
         end
         SPEC.Type = 2;
         SPEC.Band = [0,pi/Ts];
         % Locate inputs
         InputNames = [uNames;sNames];
         [indW,MisMatch] = ltipack.resolveSignalID(this.Input,InputNames,true);
         error(resolveSignalError(this,'Control:tuning:TuningReq11',MisMatch,InputNames))
         SPEC.Input = indW;
         % Locate outputs
         OutputNames = [yNames;sNames];
         [indZ,MisMatch] = ltipack.resolveSignalID(this.Output,OutputNames,true);
         error(resolveSignalError(this,'Control:tuning:TuningReq12',MisMatch,OutputNames))
         SPEC.Output = indZ;
         % Locate openings
         if isempty(this.Openings)
            iOpen = [];
         else
            [iOpen,MisMatch] = ltipack.resolveSignalID(this.Openings,sNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
         end
         [SPEC.Config,LoopConfigs] = ...
            TuningGoal.SystemLevel.getSwitchConfig(iOpen,LoopConfigs);
         % Noise covariance
         nw = numel(indW);
         QW = this.NoiseCovariance;
         if isscalar(QW)
            G = sqrt(QW);
         elseif size(QW,1)~=nw
            error(message('Control:tuning:LQG5',getID(this)))
         else
            G = localGetFactor(QW);
         end
         % Performance weight
         nz = numel(indZ);
         QZ = this.PerformanceWeight;
         if isscalar(QZ)
            F = sqrt(QZ);
         elseif size(QZ,1)~=nz
            error(message('Control:tuning:LQG6',getID(this)))
         else
            F = localGetFactor(QZ)';
         end
         % Transform
         if Ts>0
            F = F/sqrt(Ts);
         end
         SPEC.Transform = struct(...
            'E',struct('a',[],'b',[],'c',[],'d',zeros(nz,nw),'Poles',[]),...
            'F',F,'G',G,'h',[]);
      end
      
   end
   
   
end

%------------------------------
function Q = localCheckWeight(Q,ID)
% Validate QW and QZ spec
ok = (isnumeric(Q) && ismatrix(Q) && isreal(Q) && size(Q,1)==size(Q,2));
% Check symmetry
if ok
   Q = double(Q);
   nQ = norm(Q,1);
   ok = (isfinite(nQ) && norm(Q-Q',1)<100*eps*nQ);
end
% Check non-negativeness
if ok
   % Check non-negativeness
   Q = (Q+Q')/2;
   ok = (min(eig(Q))>-100*eps*nQ);
end
if ~ok
   switch ID
      case 'QW'
         error(message('Control:tuning:LQG3'))
      case 'QZ'
         error(message('Control:tuning:LQG4'))
   end
end
end

function F = localGetFactor(Q)
% Factorizes Q = F*F'
[u,t] = schur(Q);
F = lrscale(u,[],sqrt(max(0,diag(t))));
end
