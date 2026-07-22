classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
      WeightedVariance < TuningGoal.GenericIO & TuningGoal.SystemLevel
   % Frequency-weighted H2 norm constraint for control system tuning.
   %
   %   This requirement constrains the weighted H2 norm
   %       || WL(s) H(s) WR(s) ||2
   %   of a transfer function H(s). The H2 norm (see NORM) measures the
   %   root-mean-square (RMS) value of the output of a system driven by
   %   unit-variance white noise. Use this requirement to tune the system 
   %   response to stochastic input signals with non-uniform PSD, for 
   %   example, colored noise or wind gusts. You can also use it to specify
   %   LQG-like performance objectives, see "Using Design Requirement 
   %   Objects" for an example.
   %
   %   R = TuningGoal.WeightedVariance(INPUTNAME,OUTPUTNAME,WL,WR) creates
   %   a tuning requirement R for limiting the weighted H2 norm of the 
   %   closed-loop transfer function H(s) from inputs INPUTNAME to outputs 
   %   OUTPUTNAME. The signal names INPUTNAME and OUTPUTNAME can be strings 
   %   or cell arrays of strings for vector-valued signals. The frequency-
   %   weigthing functions WL and WR can be specified as matrices or LTI 
   %   models, and the value [] is interpreted as the identity. For example
   %      WL = tf([1 1],[1 100])
   %      WR = diag([1 10])
   %      R = TuningGoal.WeightedVariance('n','y',WL,WR)
   %   creates a frequency-weighted H2 constraint for the two-input
   %   closed-loop transfer function from n to y.
   %
   %   NOTE: When tuning a control system in discrete time, the requirement
   %   uses the scaled H2 norm
   %      || WL(z) H(z) WR(z) ||2 / sqrt(Ts)    (Ts = sample time)
   %   to ensure consistent results with tuning in continuous time. To
   %   constrain the true discrete-time H2 norm, multiply either WL or WR 
   %   by the factor sqrt(Ts).
   %
   %   Set properties to further configure the requirement. For example,
   %      R = TuningGoal.WeightedVariance('n','y',WL,WR)
   %      R.Name = 'Noise attenuation'
   %      R.Openings = 'OuterLoop'
   %      R.Models = [2 3]
   %   names the requirement, specifies that it should be evaluated with
   %   the outer loop open, and restricts it to the second and third plant
   %   models. Type "help TuningGoal.WeightedVariance.<property name>"
   %   for details on individual properties. Use SYSTUNE and related
   %   commands to tune the control system parameters subject to this and
   %   other requirements.
   %
   %   See also DynamicSystem/norm, evalGoal, TuningGoal.Variance, 
   %   TuningGoal.LQG, TuningGoal.Gain, TuningGoal, systune, looptune, slTuner.
   
   % Author: P. Gahinet
   % Copyright 2009-2013 The MathWorks, Inc.
   
   properties
      % Frequency-weighting function at outputs (state-space model).
      %
      % This property specifies a SISO or MIMO weighting function for the
      % output channels of the closed-loop transfer function.
      WL
      
      % Frequency-weighting function at inputs (state-space model).
      %
      % This property specifies a SISO or MIMO weighting function for the
      % input channels of the closed-loop transfer function.
      WR
end
   
   methods
      
      % Constructor
      function this = WeightedVariance(InputName,OutputName,WL,WR)
         narginchk(4,4)
         try
            this.Input = InputName;
            this.Output = OutputName;
            this.WL = WL;
            this.WR = WR;
         catch ME
            throw(ME)
         end
      end
                  
      function this = set.WL(this,Value)
         % SET function for WL
         if isempty(Value)
            this.WL = [];
         else
            Value = TuningGoal.checkWeight(Value,'WL');
            if ~issiso(Value) && ~(isstable(Value) && isproper(Value))
               % MIMO weights must be stable and proper
               error(message('Control:tuning:WeightedReq5','WL'))
            end
            this.WL = Value;
         end
      end
      
      function this = set.WR(this,Value)
         % SET function for WR
         if isempty(Value)
            this.WR = [];
         else
            Value = TuningGoal.checkWeight(Value,'WR');
            if ~issiso(Value) && ~(isstable(Value) && isproper(Value))
               % MIMO weights must be stable and proper
               error(message('Control:tuning:WeightedReq5','WR'))
            end
            this.WR = Value;
         end
      end
            
      function WF = getWeight(this,Ts,WID)
         % Returns a stable, proper weight in state space form
         WF = this.(WID);
         if ~isempty(WF)
            WF = TuningGoal.resampleWeight(WF,Ts);
            if issiso(WF)
               WF = ss(TuningGoal.regularizeWeight2(WF,[0,Inf],false));
            end
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
         Ts = abs(H.Ts);
         TU = H.TimeUnit;
         WL = getWeight(this,Ts,'WL'); %#ok<*PROPLC>
         if ~isempty(WL)
            nio = size(WL,1);
            if nio>1 && nio~=size(H,1)
               error(message('Control:tuning:WeightedReq7',getID(this)))
            end
            WL.TimeUnit = TU;
            H = WL * H;
         end
         WR = getWeight(this,Ts,'WR');
         if ~isempty(WR)
            nio = size(WR,1);
            if nio>1 && nio~=size(H,2)
               error(message('Control:tuning:WeightedReq6',getID(this)))
            end
            WR.TimeUnit = TU;
            H = H * WR;
         end
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
         [ny,nu] = size(H);
         Ts = abs(H.Ts);
         WL = this.WL;
         if ~isempty(WL)
            if ~(issiso(WL) || size(WL,1)==ny)
               error(message('Control:systunegui:SizeWL'))
            end
            TuningGoal.validateWeight(WL,Ts)
         end
         WR = this.WR;
         if ~isempty(WR)
            if ~(issiso(WR) || size(WR,1)==nu)
               error(message('Control:systunegui:SizeWR'))
            end
            TuningGoal.validateWeight(WR,Ts)
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
         [indU,MisMatch] = ltipack.resolveSignalID(this.Input,InputNames,true);
         error(resolveSignalError(this,'Control:tuning:TuningReq11',MisMatch,InputNames))
         SPEC.Input = indU;
         % Locate outputs
         OutputNames = [yNames;sNames];
         [indY,MisMatch] = ltipack.resolveSignalID(this.Output,OutputNames,true);
         error(resolveSignalError(this,'Control:tuning:TuningReq12',MisMatch,OutputNames))
         SPEC.Output = indY;
         % Locate openings
         if isempty(this.Openings)
            iOpen = [];
         else
            [iOpen,MisMatch] = ltipack.resolveSignalID(this.Openings,sNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
         end
         [SPEC.Config,LoopConfigs] = ...
            TuningGoal.SystemLevel.getSwitchConfig(iOpen,LoopConfigs);
         % Build weight
         ny = numel(indY);
         nu = numel(indU);
         WL = getWeight(this,Ts,'WL');
         WR = getWeight(this,Ts,'WR');
         LeftWeight = ~isempty(WL);
         RightWeight = ~isempty(WR);
         if LeftWeight
            [aW,bW,cW,dW] = ssdata(WL);
            if ~(isempty(aW) && isequal(dW,eye(size(dW))))
               pWL = eig(aW);
               if issiso(WL) && ny>1
                  [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,ny);
               elseif size(WL,1)~=ny
                  error(message('Control:tuning:WeightedReq7',getID(this)))
               end
               SPEC.WL = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWL);
            end
         end
         if RightWeight
            [aW,bW,cW,dW] = ssdata(WR);
            if ~(isempty(aW) && isequal(dW,eye(size(dW))))
               pWR = eig(aW);
               if issiso(WR) && nu>1
                  [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,nu);
               elseif size(WR,1)~=nu
                  error(message('Control:tuning:WeightedReq6',getID(this)))
               end
               SPEC.WR = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWR);
            end
         end
         % Sample time adjustment
         if Ts>0
            tau1 = sqrt(Ts);  tau2 = sqrt(tau1);
            if LeftWeight
               % Divide WL by sqrt(Ts)
               SPEC.WL.b = SPEC.WL.b/tau2;  SPEC.WL.c = SPEC.WL.c/tau2;  SPEC.WL.d = SPEC.WL.d/tau1;
            elseif RightWeight
               SPEC.WR.b = SPEC.WR.b/tau2;  SPEC.WR.c = SPEC.WR.c/tau2;  SPEC.WR.d = SPEC.WR.d/tau1;
            elseif ny<=nu
               SPEC.WL = struct('a',[],'b',zeros(0,ny),'c',zeros(ny,0),'d',(1/tau1)*eye(ny),'Poles',zeros(0,1));
            else
               SPEC.WR = struct('a',[],'b',zeros(0,nu),'c',zeros(nu,0),'d',(1/tau1)*eye(nu),'Poles',zeros(0,1));
            end
         end
      end
      
   end
   
   
end
