classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
      Variance < TuningGoal.ScaledIO & TuningGoal.SystemLevel
   % Noise amplification constraint for control system tuning.
   %
   %   This requirement limits the output variance in a linear system driven
   %   by white noise. Use this requirement for tuning the system response
   %   to white noise inputs. Use TuningGoal.WeightedVariance instead for
   %   colored noise inputs and LQG-like cost functions.
   %
   %   R = TuningGoal.Variance(INPUTNAME,OUTPUTNAME,MAXAMP) creates a tuning
   %   requirement R for limiting the noise amplification from inputs
   %   INPUTNAME to outputs OUTPUTNAME. The signal names INPUTNAME and
   %   OUTPUTNAME can be strings or cell arrays of strings for vector-valued
   %   signals. The scalar MAXAMP specifies the maximum noise amplification
   %   factor or H2 norm (see NORM). The H2 norm squared measures:
   %     * The ratio of output variance to noise variance
   %     * The average output power for unit-variance white noise inputs
   %     * The total energy of the impulse response.
   %
   %   NOTE: When you tune a control system in discrete time, this requirement
   %   assumes that the physical plant and noise process are continuous and
   %   interprets MAXAMP as a bound on the continuous-time H2 norm. This
   %   ensures that continuous- and discrete-time tuning give consistent
   %   results. If the plant and noise processes are truly discrete and you
   %   want to bound the discrete-time H2 norm instead, specify the value 
   %   MAXAMP/sqrt(Ts) as third input argument, where Ts is the sample time.
   %
   %   Set properties to further configure the requirement. For example,
   %      R = TuningGoal.Variance('n','y',0.1)
   %      R.Name = 'H2 constraint'
   %      R.Openings = 'OuterLoop'
   %      R.Models = 2
   %   names the requirement and specifies that it should be evaluated with
   %   the outer loop open and for the second plant model only. Type
   %   "help TuningGoal.Variance.<property name>" for details on individual
   %   properties.
   %
   %   Use SYSTUNE and related commands to tune the control system parameters
   %   subject to this and other requirements. When used as a soft constraint,
   %   this requirement contributes the term
   %      f(x) = || H(s) / MAXAMP ||2              (continuous time)
   %      f(x) = || H(z) / (MAXAMP*sqrt(Ts)) ||2   (discrete time)
   %   to the objective function where H(.) is the specified closed-loop
   %   transfer function.
   %
   %   See also DynamicSystem/norm, evalGoal, TuningGoal.WeightedVariance,
   %   TuningGoal.LQG, TuningGoal.Gain, TuningGoal, systune, looptune, slTuner.
   
   % Author: P. Gahinet
   % Copyright 2009-2013 The MathWorks, Inc.
   
   properties
      % Maximum variance amplification (scalar).
      %
      % This property specifies the maximum value of the output variance for
      % a unit-variance input signal and corresponds to the maximum H2 norm
      % from inputs to outputs.
      MaxAmplification
   end
   
   methods
      
      % Constructor
      function this = Variance(InputName,OutputName,MaxAmp)
         narginchk(3,3)
         try
            this.Input = InputName;
            this.Output = OutputName;
            this.MaxAmplification = MaxAmp;
         catch ME
            throw(ME)
         end
      end
      
      function this = set.MaxAmplification(this,Value)
         % SET function for MaxAmplification
         if isnumeric(Value) && isreal(Value) && isscalar(Value) && ...
               isfinite(Value) && Value>0
            this.MaxAmplification = double(Value);
         else
            error(message('Control:tuning:VarianceReq1'))
         end
      end
            
   end
   
   methods (Access = protected)

      function boo = hasView_(~)
         boo = false;
      end
      
      function T = getClosedLoopTransfer_(this,CL)
         % Computes scaled closed-loop transfer from inputs to outputs
         T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
         T = sminreal(getValue(T));
         % Add scaling
         Di = this.InputScaling;
         Do = this.OutputScaling;
         if ~(isempty(Di) && isempty(Do))
            [ny,nu] = iosize(T);
            Di = checkInputScaling(this,Di,nu);
            Do = checkOutputScaling(this,Do,ny);
            T = diag(1./Do) * T * diag(Di);
         end
      end

      function [H,fObj] = evalSpec_(this,CL)
         % Evaluates requirement for given closed-loop model
         T = getClosedLoopTransfer_(this,CL);
         Ts = abs(T.Ts);
         if Ts>0
            tau = this.MaxAmplification*sqrt(Ts);
         else
            tau = this.MaxAmplification;
         end
         H = (1/tau) * T;
         if nargout>1
            fObj = norm(H);
         end
      end
      
   end
   
   methods (Hidden)
      
      function validateGoal(this,CL)
         % Goal validation for GUI
         T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
         [ny,nu] = size(T);
         Di = this.InputScaling;
         Do = this.OutputScaling;
         if ~(isempty(Di) || numel(Di)==nu)
            error(message('Control:systunegui:InputScaling'))
         end
         if ~(isempty(Do) || numel(Do)==ny)
            error(message('Control:systunegui:OutputScaling'))
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
         nu = numel(indU);
         % Locate outputs
         OutputNames = [yNames;sNames];
         [indY,MisMatch] = ltipack.resolveSignalID(this.Output,OutputNames,true);
         error(resolveSignalError(this,'Control:tuning:TuningReq12',MisMatch,OutputNames))
         SPEC.Output = indY;
         ny = numel(indY);
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
         if Ts>0
            tau = this.MaxAmplification*sqrt(Ts);
         else
            tau = this.MaxAmplification;
         end
         if tau~=1            
            if ny<=nu
               SPEC.WL = struct('a',[],'b',zeros(0,ny),'c',zeros(ny,0),'d',(1/tau)*eye(ny),'Poles',zeros(0,1));
            else
               SPEC.WR = struct('a',[],'b',zeros(0,nu),'c',zeros(nu,0),'d',(1/tau)*eye(nu),'Poles',zeros(0,1));
            end
         end
         % I/O scaling
         Di = this.InputScaling;
         Do = this.OutputScaling;
         if ~(isempty(Di) && isempty(Do))
            Di = checkInputScaling(this,Di,nu); % may error
            Do = checkOutputScaling(this,Do,ny);
            SPEC.Transform = struct(...
               'E',struct('a',[],'b',[],'c',[],'d',zeros(ny,nu),'Poles',[]),...
               'F',diag(1./Do),'G',diag(Di),'h',[]);
         end
      end
                  
   end
   
   
end
