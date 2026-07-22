classdef BodeEditorData < ctrlguis.csdesignerapp.data.internal.GraphicalEditorData
    % Class to manage the data needed for graphical editors.
    
    properties
        % Frequency range for multimodel data
        MultiModelFrequency
        
        % Bode specific data properties
        Frequency % Frequency stored in rad/s
        Phase     % Phase stored in degrees
        Magnitude % Magnitude stored in abs
        FreqFocus % Frequency focus in rad/s
        
    end
    
    methods
        function this = BodeEditorData(Response, varargin)
            this = this@ctrlguis.csdesignerapp.data.internal.GraphicalEditorData(Response, varargin{:});
            
            if nargin >= 2
                Preferences = varargin{1};
                this.MultiModelFrequency = Preferences.getMultiModelFrequency;
            end
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
                this.Magnitude = GainFactor * this.Magnitude;
                
                % Set Edited Block to the compensator being edited
                this.EditedBlock = C;
            end
        end
        
        function Margins = getMargins(this)
            Margins = getMargins(this.Response);      
        end
        
        function update(this)
            % Turn off warnings
            sw = warning('off'); [lw, lwid] = lastwarn;
            isFRD = hasFRD(this.Response);
            if isFRD

                % For FRD Data, the normalized open-loop is computed in multiple stages
                % for compensator poles and zeros to be displayed correctly.
                % L = TunedFactors*TunedLFT
                % 1. Compute the TunedLFT (FRD)
                % 2. Compute the Normalized TunedFactors (ZPK)
                % 3. Interpolate TunedLFT using visual scale at pole/zero and resonance
                % 4. Compute FRD of ZPK and perform L = TunedFactors*TunedLFT
                
                % Note: The Open-Loop is defined as positive feedback because the loop is
                % defined by cutting a signal(i.e. all signs are lumped in the effective
                % plant). However because most users are used to designing with negative
                % feedback on such plots as root locus this function pulls out a negative
                % sign so that plots are presented as negative feedback.
                TunedLFT = -getTunedLFT(this.Response);
                
                % Compute TunedLFT Response
                [FRDMagnitude,FRDPhase,FRDFrequency,this.FreqFocus] = bode(this,TunedLFT);
                
                % Compute Contributions of TunedFactors Normalized by C(for compensator
                % gain mag=1)
                TunedFactors = getTunedFactors(this.Response);
                idx = find(this.EditedBlock == TunedFactors);
                TFactors = getPrivateData(zpk(1,'Ts',getTs(this.Response)));
                for ct = 1:length(TunedFactors)
                    if ct == idx
                        TFactors = TFactors * getZPKData(TunedFactors(ct),'normalized');
                    else
                        TFactors = TFactors * getZPKData(TunedFactors(ct));
                    end
                end
                
                % Determine additional freq points to add to the response
                if ~(isempty(TFactors.z{1}) && isempty(TFactors.p{1}))
                    [W0,Zeta] = damp([TFactors.z{1};TFactors.p{1}],TFactors.Ts);
                    
                    t = W0.^2 .* (1 - 2 * Zeta.^2);
                    Wpeak = sqrt(t(t>0,:));
                    wpz = [Wpeak;W0];
                    wpz = wpz((wpz<=FRDFrequency(end)) & (wpz>=FRDFrequency(1)));
                    
                    [FRDFrequency,FRDMagnitude,FRDPhase] = ...
                        LocalUpdateData(this,FRDFrequency,FRDMagnitude,FRDPhase,wpz);
                end
                % Compute frequency response of TunedFactors
                [TFMagnitude,TFPhase,TFFrequency] = bode(this,TFactors,FRDFrequency);
                
                % Use the intersection of frequency computed (0 frequency with infs or
                % NaNs removed)
                [~,ITF,IFRD] = intersect(TFFrequency,FRDFrequency);
                
                % Form product TunedFactors*TunedLFT
                this.Magnitude = TFMagnitude(ITF).*FRDMagnitude(IFRD);
                this.Phase = TFPhase(ITF)+FRDPhase(IFRD);
                this.Frequency = FRDFrequency(IFRD);
                this.Ts = TFactors.Ts;
            else
                NormOpenLoopNominal = getOpenLoop(this.Response, this.EditedBlock);
                this.SingularLoop = (~isfinite(NormOpenLoopNominal));
                
                if this.SingularLoop
                    return;
                end
                
                [this.Magnitude, this.Phase, this.Frequency, this.FreqFocus] = bode(this,NormOpenLoopNominal);

                % compute fixed poles and zeros
                computeFixedPZ(this);
                
                this.Ts = NormOpenLoopNominal.Ts;
            end
            
            [b,nsys] = isUncertain(this.Response);
            if ~b
                this.isUncertain = false;
                this.UncertainData = [];
                %                     this.UncertainData = struct(...
                %                         'Magnitude',[],...
                %                         'Phase', [], ...
                %                         'Frequency',[]);
            else
                this.isUncertain = true;
                if isFRD
                    uw=[];
                else
                    uw = this.MultiModelFrequency;
                    if this.Ts
                        uw = uw(uw<=pi/this.Ts);
                    end
                end
                % We assume that getOpenLoopPlant returns P of size 1x1xnx1
                for ct = 1:nsys
                    OpenLoop = getOpenLoop(this.Response, this.EditedBlock, ct);
                    [UMagnitude(:,ct),UPhase(:,ct),uw] = bode(this,OpenLoop,uw);
                end
                this.UncertainData = struct(...
                    'Magnitude',UMagnitude,...
                    'Phase', UPhase, ...
                    'Frequency',uw(:));
            end
            
            % Reset warnings
            warning(sw); lastwarn(lw, lwid)
        end
        
        function [m,p,w,Focus,SoftFocus] = bode(~,Dsys,w)
            if nargin == 2
                w = [];
            end
            % Compute grid and response
            [m,p,w,FocusInfo] =  freqresp(Dsys,3,w,true);
            p = (180/pi) * p;
            
            % Eliminate NaN/Inf values near w=0 (due to integrators)
            idx = find(cumsum(isfinite(m))>0);
            w = w(idx);  m = m(idx);  p = p(idx);
            
            % Focus data
            Focus = FocusInfo.Focus;
            SoftFocus = FocusInfo.Soft;
        end
        function updateMultiModelFrequency(this,ed)
            this.MultiModelFrequency = ed.AffectedObject.getMultiModelFrequency;
            this.notify('DataChanged');
        end
    end
    
    
end

%%%%%%%%%%%%%%%%%%%
% LocalUpdateData %
%%%%%%%%%%%%%%%%%%%
function [w,mag,phase] = LocalUpdateData(this,w,mag,phase,wpz)
% Updates mag and phase data by adding points for wpz
mag = [mag ; interpmag(this,w,mag,wpz)];
phase = [phase ; interpphase(this,w,phase,wpz)];
[w,iu] = LocalUniqueWithinTol([w;wpz],1e3*eps);  % sort + unique
mag = mag(iu);
phase = phase(iu);
end

%%%%%%%%%%%%%%%%%%%%%%%%
% LocalUniqueWithinTol %
%%%%%%%%%%%%%%%%%%%%%%%%
function [w,iu] = LocalUniqueWithinTol(w,rtol)
% Eliminates duplicates within RTOL (relative tolerance)
% Helps prevent reintroducing duplicates during unit conversions

% Sort W
[w,iu] = sort(w);

% Eliminate duplicates
lw = length(w);
dupes = find(w(2:lw)-w(1:lw-1)<=rtol*w(2:lw));
w(dupes,:) = [];
iu(dupes,:) = [];
end

function Phasei = interpphase(this,W,Phase,Wi)
%INTERPPhase  Interpolates phase data in the visual units.
% REVISIT: Give access to parent
% if strcmp(this.Parent.Axes.XScale,'log')
W = log2(W);
nz = (Wi>0);
Wi(nz) = log2(Wi(nz));
Wi(~nz) = -Inf;
% end

Phasei = utInterp1(W,Phase,Wi);
end

function Magi = interpmag(this,W,Mag,Wi)
% REVISIT: Give access to parent
%INTERPMAG  Interpolates magnitude data in the visual units.

%   Author(s): P. Gahinet
%   Copyright 1986-2007 The MathWorks, Inc.

% RE: MAG and MAGI are expressed in abs units. The interpolation occurs
%     in abs or log scale depending on the mag. scale and units

% if strcmp(this.Parent.Axes.XScale,'log')
W = log2(W);
nz = (Wi>0);
Wi(nz) = log2(Wi(nz));
Wi(~nz) = -Inf;
% end

% if strcmp(this.Parent.Axes.YUnits{1},'abs') && ...
%         strcmp(this.Parent.Axes.YScale{1},'linear')
%     % Interpolate natural magnitude
%     Magi = utInterp1(W,Mag,Wi);
% else
% Interpolate log of magnitude
Magi = pow2(utInterp1(W,log2(Mag),Wi));
% end
end


