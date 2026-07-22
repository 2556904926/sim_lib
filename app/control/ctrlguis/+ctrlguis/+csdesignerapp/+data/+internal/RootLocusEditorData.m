classdef RootLocusEditorData < ctrlguis.csdesignerapp.data.internal.GraphicalEditorData
    % Class to manage the data needed for graphical editors.
    
    properties        
        % Root Locus specific data properties
        OpenLoopData    % Cached open loop locus info
        LocusRoots      % Locus roots
        LocusGains      % Locus gains
        ClosedPoles     % Closed loop poles

        UncertainCLPoles
        PadeOrder
    end
    
    methods
        function this = RootLocusEditorData(Response, varargin)
            this = this@ctrlguis.csdesignerapp.data.internal.GraphicalEditorData(Response, varargin{:});
        end
        
        function setEditedBlock(this,C)
            % Sets target block to C and recomputes normalized information
            
            if ~(C == this.EditedBlock);
                % Renormalize editors frequency repsonse with respect to new target
                % Re-Normalization factor
                GainC = getZPKGain(C);
                if isequal(GainC,0);
                    % Protect against GainC = 0 (not sure if this condition is possible
                    % though)
                    GainC = 1;
                end
                
                % Update Magnitude data of editor
                GainFactor = getZPKGain(this.EditedBlock)/GainC;
                this.LocusGains = GainFactor * this.LocusGains;
                
                % Set Edited Block to the compensator being edited
                this.EditedBlock = C;
            end
        end
        
        
        function updatePadeOrder(this,ed)
            this.PadeOrder = ed.AffectedObject.(ed.Source.Name);
        end
        
        function update(this)
            % Turn off warnings
            sw = warning('off'); [lw, lwid] = lastwarn;

            NormOpenLoop = getOpenLoop(this.Response, this.EditedBlock);         
            this.SingularLoop = (~isfinite(NormOpenLoop));
            
            if this.SingularLoop  || hasFRD(this.Response)
                % Reset warnings
                warning(sw); lastwarn(lw, lwid)
                % Open loop is not defined, e.g., when minor loop cannot be closed in config 4
                return;
            end
            
            GainMag = getZPKGain(this.EditedBlock,'mag');
            
            % Use pade to approximate delays compute delays
            NormOpenLoop = this.utApproxDelay(NormOpenLoop);
            
            % Compute root locus for normalized open-loop model and current closed-loop poles
            [Roots,Gains,RLInfo] = rlocus(NormOpenLoop);
            
            this.OpenLoopData = RLInfo;
            
            
            %%%%%%%%%%%%%%%%%
            RLInfoa = [];
            [b,nsys] = isUncertain(this.Response);
            if ~b
                this.isUncertain = false;
                this.UncertainData=[];
            else
                this.isUncertain = true;
                this.UncertainData=struct('OpenLoopData',[],'CLPolesa',[]);
                % We assume that getOpenLoopPlant returns P of size 1x1xnx1
                for ct = 1:nsys
                    OL = getOpenLoop(this.Response, this.EditedBlock,ct);
                    OL = this.utApproxDelay(OL);
                    [~,~,RLInfoa] = rlocus(OL);
                    this.UncertainData(ct).OpenLoopData=RLInfoa;
                end
            end
            
            updateGain(this, Gains, Roots, GainMag);
            
            
            % Compute the plant dynamics (fixed poles and zeros)
            % RE: Derive fixed dynamics from open-loop dynamics computed by RLOCUS
            % to ensure that the o and x's lie at the end of branches (see g297998)
            [zC,pC] = getPZ(this.EditedBlock,'Tuned');
            if RLInfo.InverseFlag
                this.FixedZeros = rootdiff(RLInfo.Pole,zC);
                this.FixedPoles = rootdiff(RLInfo.Zero,pC);
            else
                this.FixedZeros = rootdiff(RLInfo.Zero,zC);
                this.FixedPoles = rootdiff(RLInfo.Pole,pC);
            end
            
            this.Ts = NormOpenLoop.Ts;
            
            % Reset warnings
            warning(sw); lastwarn(lw, lwid)
        end
        
        function updateGain(this, Gains, Roots, GainMag)
            RLInfo = this.OpenLoopData;
            % CLPoles at ZPKGain
            CLpoles = fastrloc(RLInfo,GainMag);
            
            % Make sure the locus extends beyond the current CL poles
            [NewGain,RefRoot] = extendlocus(Gains,Roots,GainMag);
            
            if ~isempty(NewGain)
                % Extend locus
                NewRoot = matchlsq(RefRoot,fastrloc(RLInfo,NewGain));
                Roots = [NewRoot,Roots];
                [Gains,is] = sort([NewGain,Gains]);
                Roots = Roots(:,is);
            elseif ~isempty(Gains) && ~any(Gains==GainMag)
                % Insert current gain in locus data
                idx = find(Gains>GainMag);
                Gains = [Gains(:,1:idx(1)-1) , GainMag , Gains(:,idx(1):end)];
                Roots = [Roots(:,1:idx(1)-1) , ...
                    matchlsq(Roots(:,idx(1)-1),CLpoles) , Roots(:,idx(1):end)];
            end
            
            % Update locus data
            this.LocusRoots = Roots;
            this.LocusGains = Gains;
            this.ClosedPoles = CLpoles;  % triggers update of optimal X/Y lims
            
            % Multimodel update
            if ~isempty(this.UncertainData)
                CLPolesa = [];
                for ct = 1:length(this.UncertainData)
                    CLPolesa = [CLPolesa;fastrloc(this.UncertainData(ct).OpenLoopData,GainMag)];
                end
                this.UncertainCLPoles = CLPolesa;
            end
        end
        
        function m = utApproxDelay(this,m)
            % Helper function for approximating delays            
            if hasdelay(m)
                if isequal(m.Ts,0)
                    PO = this.PadeOrder;
                    m = pade(m,PO,PO,PO);
                else
                    m = elimDelay(m);
                end
            end
        end
    end
end

function [NewGain,RefRoot] = extendlocus(Gains,Roots,CurrentGM)
%EXTENDLOCUS  Extends asymptotes if current gain (red square)
%             is nearing asymptote end point.

NewGain = [];
RefRoot = [];

ng = length(Gains);
iinf = find(any(isinf(Roots),1));  % roots at inf

if ~isempty(iinf)
   m = sum(isinf(Roots(:,iinf)));  % number of asymptotes
   factor2 = 2^m;   % must multiply max gain by 2^m to double asymptote length   
   switch iinf
   case 1
      % Asymptote at K=0
      if CurrentGM<2*Gains(2)
         NewGain = CurrentGM/factor2;
         RefRoot = Roots(:,2);
      end
   case ng
      % Asymptote at K=Inf
      if CurrentGM>Gains(ng-1)/2
         NewGain = factor2*CurrentGM;
         RefRoot = Roots(:,ng-1);
      end
   otherwise
      % Finite escape
      if CurrentGM>Gains(iinf-1) & CurrentGM<Gains(iinf+1) & CurrentGM~=Gains(iinf)
         NewGain = Gains(iinf) + (CurrentGM-Gains(iinf)) / factor2;
         RefRoot = Roots(:,iinf+1-2*(CurrentGM<Gains(iinf)));
      end
   end
end
end

function rG = rootdiff(rOL,rC)
% Set differencing with inexact matches

%   Author(s): P. Gahinet
%   Copyright 1986-2006 The MathWorks, Inc.
nC = length(rC);
nOL = length(rOL);
if nC>nOL
   % Should not happen
   rG = zeros(0,1);
else
   gaps = abs(rOL(:,ones(1,nC))-rC(:,ones(1,nOL)).');
   [junk,jC] = sort(min(gaps,[],1));
   % OL2C(i) = j if the ith-entry of rOL is matched with the j-th entry of rC
   OL2C = zeros(nOL,1);
   for ct=1:nC
      j = jC(ct);
      ifree = find(OL2C==0);
      [junk,imin] = min(gaps(ifree,j)); % find best match for j-th entry of C
      OL2C(ifree(imin)) = j;
   end
   rG = rOL(OL2C==0);
end
end
