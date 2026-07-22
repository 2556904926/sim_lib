classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Sensitivity < TuningGoal.BandLimited & TuningGoal.ScaledLoop & ...
        TuningGoal.SystemLevel
    % Sensitivity requirement for control system tuning.
    %
    %   Use this requirement to limit the sensitivity of a feedback loop
    %   to disturbances. The sensitivity should be smaller than one at
    %   frequencies where you need good disturbance rejection.
    %
    %   R = TuningGoal.Sensitivity(LOC,MAXSENS) creates a tuning requirement
    %   for limiting the sensitivity to disturbances entering at the location
    %   LOC. For MIMO feedback loops, "sensitivity" refers to the peak gain
    %   of the sensitivity function measured at LOC. The argument MAXSENS
    %   specifies the maximum sensitivity as a function of frequency. You can
    %   use an FRD model to sketch the desired sensitivity profile with just
    %   a few frequency points. For example,
    %      MaxSens = frd([0.01 1 1],[1 10 100]);
    %      R = TuningGoal.Sensitivity('u',MaxSens)
    %   specifies a maximum sensitivity of 0.01 (-40dB) at 1 rad/s, increasing
    %   to 1 (0dB) past 10 rad/s.
    %
    %   The location LOC is a string or a cell array of strings for MIMO loops.
    %   In MATLAB, use AnalysisPoint blocks to mark such locations. For example,
    %      S = AnalysisPoint('u');
    %      G = tf(1,[1 2]);
    %      C = tunablePID('C','pi');
    %      T = feedback(G*S*C,1);
    %   creates a PI loop with a loop switch marking the plant input "u". You
    %   can then use the string 'u' to refer to the sensitivity at the plant
    %   input. In Simulink, use Linear Analysis points or the addPoint method
    %   of the slTuner interface to mark the location LOC.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.Sensitivity('u',0.1);
    %      R.Name = 'Sensitivity at u';
    %      R.Focus = [0 5];
    %      R.Models = [2 3];
    %   specifies a maximum sensitivity of 0.1 (10%) in the frequency band
    %   [0,5] rad/s. The requirement is named "Sensitivity at u" and only
    %   applies to the second and third plant models. For details on each
    %   property, type "help TuningGoal.Sensitivity.<property name>".
    %
    %   Use VIEWGOAL(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Algorithm: This goal is turned into a normalized gain constraint
    %      || wS * S ||oo < 1
    %   on the sensitivity function S. The frequency weighting function wS
    %   is derived from the specified sensitivity profile, see GETWEIGHT for
    %   details.
    %
    %   See also AnalysisPoint, getPoints, evalGoal, viewGoal, getWeight,
    %   TuningGoal.Gain, TuningGoal.Rejection, TuningGoal.LoopShape, TuningGoal.MinLoopGain,
    %   TuningGoal.MaxLoopGain, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Maximum sensitivity as a function of frequency (SISO ZPK model).
        %
        % This property specifies the maximum sensitivity as a function of
        % frequency. You can specify a smooth sensitivity profile using a
        % transfer function or sketch a piecewise sensitivity profile using
        % an FRD model. Both are mapped to a ZPK model whose magnitude
        % reflects the desired sensitivity profile.
        MaxSensitivity
    end

    methods

        % Constructor
        function this = Sensitivity(SensLoc,MaxSens)
            narginchk(2,2)
            try
                this.Location = SensLoc;
                this.MaxSensitivity = MaxSens;
            catch ME
                throw(ME)
            end
        end

        function this = set.MaxSensitivity(this,Value)
            % SET function for MaxSensitivity
            [Value,errCode] = TuningGoal.checkMagProfile(Value);
            switch errCode
                case 1
                    % Not scalar or SISO value
                    error(message('Control:tuning:SensitivityReq2'))
                case 2
                    % Cannot compute ZPK form
                    error(message('Control:tuning:SensitivityReq3'))
                case 3
                    % All zero profile
                    error(message('Control:tuning:SensitivityReq4'))
            end
            this.MaxSensitivity = Value;
        end

        function [wS,wc] = getWeight(this,Ts)
            % GETWEIGHT  Computes weighting function wS.
            %
            %   The Sensitivity goal is enforced as an H-infinity norm constraint
            %      || wS * S ||oo < 1
            %   on the sensitivity function S. The frequency weighting function
            %   wS is derived from the specified max sensitivity profile.
            %
            %   WS = getWeight(R,TS) returns the weighting function wS for
            %   the Sensitivity goal R and tuning sample time TS. The gains
            %   of WS and 1/R.MaxSensitivity roughly match for gain values
            %   ranging from -20 dB to +60 dB. For numerical reasons, WS
            %   levels off outside this range unless the specified sensitivity
            %   profile changes slope outside this range. Because poles of WS
            %   close to s=0 or s=Inf can adversely impact the SYSTUNE solver,
            %   it is not recommended to specify sensitivity profiles with
            %   very low- or very high-frequency dynamics.
            %
            %   See also TuningGoal.Sensitivity, getSensitivity.
            wS = TuningGoal.resampleWeight(1/this.MaxSensitivity,Ts);
            % Well-posedness
            if getPeakGain(wS,1e-2)<1.01
                % Allow sensitivity bounds |S|<alpha with alpha>1.
                % No regularization here since |wS| is bounded
                wc = [];
            else
                beta = abs(freqresp(wS,pi/Ts));
                if beta>1e8
                    % Max sensitivity is zero at infinity
                    error(message('Control:tuning:SensitivityReq5'))
                end
                % Find crossovers (possibly 0) and regularize weight
                wc = getGainCrossover(wS,max(1,1.25*beta));
            end
            wS = TuningGoal.regularizeWeight1(wS,wc,this.Focus);
        end

    end

    methods (Access = protected)

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            S = getSensitivity(CL,this.Location,this.Openings,this.Models);
            S = sminreal(getValue(S));
            % Scaling
            S = applyLoopScaling(this,S,getTuningInfo(CL));
            % Evaluate goal
            WF = getWeight(this,S.Ts);
            WF.TimeUnit = S.TimeUnit;
            H = WF*S;
            if nargout>1
                fObj = getPeakGain(H,1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [maxS,SBound,Ts,TU] = viewSpecGoalData(this,CL)
            maxS = this.MaxSensitivity;
            maxS.Name = getString(message('Control:systunegui:TGPlotMaxSensitivity'));
            if isequal(CL,[])
                Ts = maxS.Ts;
                TU = maxS.TimeUnit;
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
                maxS.TimeUnit = TU;
            end
            wS = getWeight(this,Ts);
            wS.TimeUnit = TU;
            SBound = 1/wS;
        end

        % Compute data for Design wave forms
        function [S0,Ss] = viewSpecDesignData(this,CL)
            % Compute S0
            S0 = getValue(getSensitivity(CL,this.Location,this.Openings,this.Models),'usample');
            S0.Name = getString(message('Control:systunegui:TGPlotSensitivity'));
            % Compute scaled response Ss
            [Ss,ShowScaled] = applyLoopScaling(this,S0,getTuningInfo(CL));
            if ShowScaled
                Ss.Name = getString(message('Control:systunegui:TGPlotScaledSensitivity'));
            else
                Ss = [];
            end
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            [~,wc] = getWeight(this,Ts);
            plotHandle.XLimitsFocus = {TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts,wc)};
            updateSingularValueFocus(plotHandle);
            YUnits = char(plotHandle.MagnitudeUnit);
            Ylim = plotHandle.YLimitsFocus{1};
            Ylim(1) = min(Ylim(1),unitconv(-20,'dB',YUnits));
            Ylim(2) = unitconv(20,'dB',YUnits);
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [maxS,SBound,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = sigmaplot(ax,maxS);
                h.Responses(1).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(1).LineStyle = "--";
            else
                [S0,Ss] = viewSpecDesignData(this,CL);
                if isempty(Ss)
                    % No scaling
                    h = sigmaplot(ax,S0,maxS);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(2).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(2).LineStyle = "--";
                else
                    h = sigmaplot(ax,S0,Ss,maxS);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(6).SemanticName;
                    h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(3).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(3).LineStyle = "--";
                end
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Legend
            h.LegendVisible = true;
            % Scale, title, labels, grid
            h.Title.String = getString(message('Control:tuning:strSensitivityReq1',this.Name));
            h.Title.Interpreter = 'none';
            h.YLabel.String = getString(message('Control:systunegui:TGPlotSensitivity'));
            h.AxesStyle.GridVisible = true;
            % Plot bounds
            addBoundResponse(h,SBound,BoundType='upper',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotEffectiveBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=true,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        end

        function GoalResponses = getGoalResponses(this,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.maxS = PlotHandle.Responses(1);
                GoalResponses.SBound = PlotHandle.Responses(2);
            else
                [~,Ss] = viewSpecDesignData(this,CL);
                if isempty(Ss)
                    GoalResponses.maxS = PlotHandle.Responses(2);
                    GoalResponses.SBound = PlotHandle.Responses(3);
                else
                    GoalResponses.maxS = PlotHandle.Responses(3);
                    GoalResponses.SBound = PlotHandle.Responses(4);
                end
            end
        end

        function DesignResponses = getDesignResponses(this,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.S0 = [];
                DesignResponses.Ss = [];
            else
                [~,Ss] = viewSpecDesignData(this,CL);
                if isempty(Ss)
                    DesignResponses.S0 = PlotHandle.Responses(1);
                    DesignResponses.Ss = [];
                else
                    DesignResponses.S0 = PlotHandle.Responses(1);
                    DesignResponses.Ss = PlotHandle.Responses(2);
                end
            end
        end

        function DesignResponses = getComparedResponses(this,CL,PlotHandle)
            [~,Ss] = viewSpecDesignData(this,CL);
            NRespPerDesign = 2-isempty(Ss);
            if isempty(CL)
                NDesigns = (length(PlotHandle.Responses)-2)/NRespPerDesign;
            else
                if isempty(Ss)
                    NDesigns = (length(PlotHandle.Responses)-3)/NRespPerDesign;
                else
                    NDesigns = (length(PlotHandle.Responses)-4)/NRespPerDesign;
                end
            end
            DesignResponses = repmat(struct('S0',[],'Ss',[]),NDesigns,1);
            for ii = 1:NDesigns
                if isempty(Ss)
                    DesignResponses(ii).S0 = PlotHandle.Responses(length(PlotHandle.Responses)+ii-NDesigns);
                else
                    DesignResponses(ii).S0 = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-1);
                    DesignResponses(ii).Ss = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign);
                end
            end
        end

        function Ts = getTs(this,CL)
            [~,~,Ts,~] = viewSpecGoalData(this,CL);
        end

        function TU = getTU(this,CL)
            [~,~,~,TU] = viewSpecGoalData(this,CL);
        end

        % Update Goal waveforms
        function updateGoal(this,CL,PlotHandle)
            GoalResponses = getGoalResponses(this,CL,PlotHandle);
            % Compute data for goals
            [maxS,SBound,~,TU] = viewSpecGoalData(this,CL);
            % Update plotted goals
            GoalResponses.maxS.SourceData.Model = maxS;
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update TBound
            GoalResponses.SBound.Model = SBound;
            GoalResponses.SBound.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strSensitivityReq1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            [S0,Ss] = viewSpecDesignData(this,CL);
            DesignResponses.S0.SourceData.Model = S0;
            if ~isempty(Ss)
                DesignResponses.Ss.SourceData.Model = Ss;
                DesignResponses.Ss.Name = Ss.Name;
            end
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [S0,Ss] = viewSpecDesignData(this,Design);
            addResponse(PlotHandle,S0,Name=[getString(message('Control:systunegui:TGPlotSensitivity')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            if isempty(Ss)
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            else
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(6,"quaternary").SemanticName;
                addResponse(PlotHandle,Ss,Name=[getString(message('Control:systunegui:TGPlotScaledSensitivity')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            end
        end

    end

    methods (Hidden)

        function validateGoal(this,CL)
            % Goal validation for GUI
            % Note: Needed to validate Models selection
            S = getSensitivity(CL,this.Location,this.Openings,this.Models);
            getWeight(this,S.Ts);
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
            % Builds standardized requirement description for SYSTUNE.
            if isempty(this.Location)
                error(message('Control:tuning:TuningReq16',getID(this)))
            end
            SPEC.Type = 3;
            SPEC.Band = [this.Focus(1) , min(this.Focus(2),pi/Ts)];
            if diff(SPEC.Band)<=0
                error(message('Control:tuning:TuningReq15',getID(this)))
            end
            % Locate channels where loop transfer is measured
            [iLoop,MisMatch] = ltipack.resolveSignalID(this.Location,sNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
            SPEC.Input = numel(uNames) + iLoop;
            SPEC.Output = numel(yNames) + iLoop;
            nL = numel(iLoop);
            SPEC.DScaling.Static = (nL>1 && strcmp(this.LoopScaling,'on'));
            % Locate openings
            if isempty(this.Openings)
                iOpen = [];
            else
                [iOpen,MisMatch] = ltipack.resolveSignalID(this.Openings,sNames,true);
                error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
                % Ignore loop openings in locations where loop transfer is measured
                iOpen = setdiff(iOpen,iLoop);
            end
            [SPEC.Config,LoopConfigs] = ...
                TuningGoal.SystemLevel.getSwitchConfig(iOpen,LoopConfigs);
            % Build weight
            WF = getWeight(this,Ts);
            [aW,bW,cW,dW] = ssdata(WF);
            pWF = eig(aW);
            if nL>1
                [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,nL);
            end
            SPEC.WL = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWF);
            % Transform T -> E+F*T*G = I+T = S
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',eye(nL),'Poles',[]),...
                'F',1,'G',1,'h',[]);
        end

    end

end



