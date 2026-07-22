classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
      WeightedPassivity < TuningGoal.Passivity
   % Frequency-weighted passivity constraints.
   %
   %   TG = TuningGoal.WeightedPassivity(INPUTNAME,OUTPUTNAME,WL,WR) creates
   %   a tuning goal TG for enforcing the passivity of
   %       H(s) = WL(s) * T(s) * WR(s)
   %   where T(s) is the closed-loop transfer function from inputs INPUTNAME
   %   to outputs OUTPUTNAME. The signal names INPUTNAME and OUTPUTNAME
   %   can be strings or cell arrays of strings for vector-valued signals.
   %   The frequency-weighting functions WL and WR can be specified as
   %   matrices or LTI models. They should be stable and minimum-phase.
   %   The value [] is interpreted as the identity. For example
   %       WL = tf(1,[1 0])   % 1/s
   %       WR = diag([1 10])
   %       R = TuningGoal.WeightedPassivity('d',{'y','z'},WL,WR)
   %   requires passivity of the transfer function
   %       [1 0;0 10] * T(s)/s
   %   where T(s) is the closed-loop transfer function from d to [y;z].
   %   See TuningGoal.Passivity for details on passivity constraints.
   %
   %   Set properties to further configure the tuning goal. For example,
   %      TG = TuningGoal.WeightedPassivity('d','y',WL)
   %      TG.Name = 'Weighted output passivity'
   %      TG.Focus = [0 10]
   %      TG.Openings = 'OuterLoop'
   %      TG.OPX = 0.1;
   %   names the requirement, specifies that it should be evaluated in the
   %   frequency band [0,10] rad/s with the outer loop open, and sets the
   %   desired output passivity index to 0.1. For details on individual 
   %   properties, type "help TuningGoal.WeightedPassivity.<property name>".
   %
   %   Use VIEWGOAL(TG) to visualize this goal and use SYSTUNE to tune the
   %   control system parameters subject to this and other goals.
   %
   %   See also isPassive, getPassiveIndex, TuningGoal.Passivity,
   %   TuningGoal.ConicSector, AnalysisPoint, slTuner/addPoint, getPoints, 
   %   evalGoal, viewGoal, TuningGoal, systune, looptune, slTuner.
   
   %   Author: P. Gahinet
   %   Copyright 2009-2015 The MathWorks, Inc.
   
   properties
      % Frequency weighting function (LTI model, default = [])
      %
      % This property specifies a SISO or MIMO weighting function for the
      % output channels of the closed-loop transfer function. For example,
      % you can enforce passivity of s*T or T/s by setting WL=s or WL=1/s.
      WL
      % Frequency weighting function (LTI model, default = [])
      %
      % This property specifies a SISO or MIMO weighting function for the
      % input channels of the closed-loop transfer function.
      WR
   end
   
   methods
      
      % Constructor
      function this = WeightedPassivity(InputName,OutputName,WL,WR)
         narginchk(3,4)
         try
            this.Input = InputName;
            this.Output = OutputName;
            this.WL = WL;
            if nargin>3
               this.WR = WR;
            end
         catch ME
            throw(ME)
         end
      end
            
      function this = set.WL(this,Value)
         % SET function for WL
         if isempty(Value)
            this.WL = [];
         else
            Value = localCheckWeight(Value,'WL');
            this.WL = Value;
         end
      end
      
      function this = set.WR(this,Value)
         % SET function for WR
         if isempty(Value)
            this.WR = [];
         else
            Value = localCheckWeight(Value,'WR');
            this.WR = Value;
         end
      end
         
      function WF = getWeight(this,Ts,WID)
         % Returns a stable, proper weight in state space form
         % WID is either 'WL' or 'invWR'
         switch WID
            case 'WL'
               WF = this.WL;  % SS or ZPK
            case 'invWR'
               if isempty(this.WR)
                  WF = [];
               else
                  WF = inv(this.WR,'min');  % SS or ZPK
               end
         end
         if ~isempty(WF)
            WF = TuningGoal.resampleWeight(WF,Ts);
            if issiso(WF)
               WF = ss(TuningGoal.regularizeWeight2(WF,this.Focus,true));
            end
         end
      end
      
   end
   
   methods (Access = protected)
            
      function [H1,H2] = getClosedLoopTransfer_(this,CL,varargin)
         % Computes closed-loop transfer from inputs to outputs.
         H = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
         [ny,nu] = iosize(H);
         if ny~=nu
            error(message('Control:tuning:Passivity4',getID(this)))
         end
         H1 = sminreal(getValue(H,varargin{:}));
         H2 = eye(nu);
         Ts = abs(H1.Ts);  TU = H1.TimeUnit;
         % Factor in weights
         WL = getWeight(this,Ts,'WL'); %#ok<*PROPLC>
         if ~isempty(WL)
            nio = size(WL,1);
            if nio>1 && nio~=ny
               error(message('Control:tuning:WeightedReq7',getID(this)))
            end
            WL.TimeUnit = TU;
            H1 = WL * H1;
         end
         invWR = getWeight(this,Ts,'invWR');
         if ~isempty(invWR)
            nio = size(invWR,1);
            if nio>1 && nio~=nu
               error(message('Control:tuning:WeightedReq6',getID(this)))
            end
            invWR.TimeUnit = TU;
            H2 = invWR * H2;
         end
      end
      
      function [H,fObj] = evalSpec_(this,CL)
         % Evaluates requirement for given closed-loop model
         % NOTE: CL is a genss or slTuner object.
         [H1,H2] = getClosedLoopTransfer_(this,CL);
         H = H1/H2;
         % Compute objective
         if nargout>1
            nu = size(H,2);
            Q = getQ(this,nu);
            R = getSectorIndex([H1;H2],Q,1e-6,this.Focus);
            fObj = 1./(1./R+1/TuningGoal.ConicSector.getRmax());
         end
      end
      
   end
   
   methods (Hidden)
      
      function [H,Q] = viewSpecHelper(this,CL)
         % Returns the state-space model H and matrices Q,W1,W2 needed to
         % plot the R-index. W1,W2 are related to Q by
         %    Q = W1*W1'-W2*W2'      W1'*W2=0
         % and the R-index is the smallest r>0 such that
         %    H' * (W1*W1'-r^2*W2*W2') * H < 0
         [H1,H2] = getClosedLoopTransfer_(this,CL,'usample');
         X = H1/H2;
         nu = size(X,2);
         H = [X ; eye(nu)];
         Q = getQ(this,nu);
      end
      
      function validateGoal(this,CL)
         % Goal validation for GUI
         H = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
         [ny,nu] = size(H);
         if ny~=nu
            error(message('Control:systunegui:IOMismatch',nu,ny))
         end
         if this.OPX * this.IPX >= 0.25
            error(message('Control:systunegui:Passivity1'))
         end
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
         [SPEC,LoopConfigs] = getSpecData@TuningGoal.Passivity(...
            this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts);
         nu = numel(SPEC.Input);
         % Set left weight to diag(WL,WR^-1)
         WL = getWeight(this,Ts,'WL');
         if isempty(WL)
            aWL = [];  bWL = zeros(0,nu);  cWL = zeros(nu,0);  dWL = eye(nu);
            pWL = zeros(0,1);
         else
            nio = size(WL,1);
            if nio>1 && nio~=nu
               error(message('Control:tuning:WeightedReq7',getID(this)))
            end
            [aWL,bWL,cWL,dWL] = ssdata(WL);
            pWL = eig(aWL);
            if nio==1 && nu>1
               [aWL,bWL,cWL,dWL] = TuningGoal.repWeight(aWL,bWL,cWL,dWL,nu);
            end
         end
         invWR = getWeight(this,Ts,'invWR');
         if isempty(invWR)
            aWR = [];  bWR = zeros(0,nu);  cWR = zeros(nu,0);  dWR = eye(nu);
            pWR = zeros(0,1);
         else
            nio = size(invWR,1);
            if nio>1 && nio~=nu
               error(message('Control:tuning:WeightedReq6',getID(this)))
            end
            [aWR,bWR,cWR,dWR] = ssdata(invWR);
            pWR = eig(aWR);
            if nio==1 && nu>1
               [aWR,bWR,cWR,dWR] = TuningGoal.repWeight(aWR,bWR,cWR,dWR,nu);
            end
         end
         SPEC.WL = struct('a',blkdiag(aWL,aWR),'b',blkdiag(bWL,bWR),...
            'c',blkdiag(cWL,cWR),'d',blkdiag(dWL,dWR),'Poles',[pWL;pWR]);
      end
      
   end
   
end


function WF = localCheckWeight(WF,WID)
% Checks that weight is bi-proper and bi-stable, or that it can be made so.
% Note: 
%   * WL*H*WR passive requires stable + minimum-phase (bi-stable)
%   * WR must be bi-proper to be invertible
%   * WL should also be bi-proper to allow for strict passivity (R<1) at w=Inf
WF = TuningGoal.checkWeight(WF,WID);
if issiso(WF)
   % SISO ZPK: Only need finite inverse, weight is made bi-stable and 
   % bi-proper by regularizeWeight2
   if WF.k==0
      error(message('Control:tuning:Passivity5',WID))
   end
else
   % MIMO SS: check that weight is bi-proper and bi-stable
   sw = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU>
   if ~(isproper(WF) && isstable(WF))
      % WF must be stable and proper when MIMO
      error(message('Control:tuning:WeightedReq5',WID))
   end
   [isp,invWF] = isproper(inv(WF));
   if ~isfinite(invWF)
      error(message('Control:tuning:Passivity5',WID))
   elseif ~(isp && isstable(invWF))
      error(message('Control:tuning:Passivity6',WID))
   end
end
end

