classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Rejection < TuningGoal.BandLimited & TuningGoal.ScaledLoop & ...
        TuningGoal.SystemLevel
    % Disturbance rejection requirement for control system tuning.
    %
    %   A measure of disturbance rejection is the ratio between the open-
    %   and closed-loop sensitivities to the disturbance. This attenuation
    %   factor varies with frequency and exceeds one only when the loop gain
    %   is larger than one (inside the control bandwidth).
    %
    %   R = TuningGoal.Rejection(DISTLOC,ATTFACT) creates a tuning requirement
    %   for rejecting a disturbance entering at the location DISTLOC. ATTFACT
    %   specifies the minimum attenuation factor as a function of frequency.
    %   You can use an FRD model to sketch the desired attenuation profile
    %   with just a few frequency points. For example,
    %      AttFact = frd([100 100 1 1],[0 1 10 100]);
    %      R = TuningGoal.Rejection('u',AttFact)
    %   specifies an attenuation factor of 100 (40dB) below 1 rad/s, gradually
    %   dropping to 1 (0dB) past 10 rad/s.
    %
    %   The disturbance input location DISTLOC can be a string or a cell array
    %   of strings for vector-valued signals. In MATLAB, use AnalysisPoint
    %   blocks to mark such locations. For example,
    %      S = AnalysisPoint('u');
    %      G = tf(1,[1 2]);
    %      C = tunablePID('C','pi');
    %      T = feedback(G*S*C,1);
    %   creates a PI loop with a loop switch marking the plant input "u". You
    %   can then use the string 'u' to refer to disturbances entering at the
    %   plant input. In Simulink, use Linear Analysis points or the addPoint
    %   method of the slTuner interface to mark the input location DISTLOC.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.Rejection('u',10);
    %      R.Name = 'Rejection spec';
    %      R.Focus = [0 5];
    %      R.Models = [2 3];
    %   specifies a factor 10 attenuation in the frequency band [0,5] rad/s.
    %   The requirement is named "Rejection spec" and only applies to the
    %   second and third plant models. For details on individual properties,
    %   type "help TuningGoal.Rejection.<property name>".
    %
    %   Use VIEWGOAL(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Algorithm: This goal is turned into a normalized gain constraint
    %      || wS * S ||oo < 1
    %   on the sensitivity function S. The frequency weighting function wS
    %   is derived from the specified attenuation profile, see GETWEIGHT for
    %   details.
    %
    %   See also AnalysisPoint, slTuner/addPoint, getPoints, evalGoal, viewGoal,
    %   getWeight, TuningGoal.StepRejection, TuningGoal.Gain, TuningGoal.Sensitivity,
    %   TuningGoal.LoopShape, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Minimum disturbance attenuation as a function of frequency (SISO ZPK model).
        %
        % This property specifies the minimum disturbance attenuation as a
        % function of frequency. The attenuation factor is the ratio between
        % the open- and closed-loop sensitivities to the disturbance. You can
        % specify a smooth attenuation profile using a transfer function or
        % sketch a piecewise attenuation profile using an FRD model. Both are
        % mapped to a ZPK model whose magnitude reflects the desired
        % attenuation profile.
        MinAttenuation
    end

    properties (Hidden, Dependent, Transient)
        % Obsoleted in R2014b
        % Note: Nothing to do at load time, set.DisturbanceInput will take care
        % of remapping data
        DisturbanceInput
    end

    methods

        % Constructor
        function this = Rejection(DistLoc,MinAttenuation)
            narginchk(2,2)
            try
                this.Location = DistLoc;
                this.MinAttenuation = MinAttenuation;
            catch ME
                throw(ME)
            end
        end

        function this = set.MinAttenuation(this,Value)
            % SET function for MinAttenuation
            [Value,errCode] = TuningGoal.checkMagProfile(Value);
            switch errCode
                case 1
                    % Not scalar or SISO value
                    error(message('Control:tuning:RejectionReq2'))
                case 2
                    % Cannot compute ZPK form
                    error(message('Control:tuning:RejectionReq3'))
                case 3
                    % All zero profile
                    error(message('Control:tuning:RejectionReq4'))
            end
            this.MinAttenuation = Value;
        end

        % Obsolete properties
        function this = set.DisturbanceInput(this,Value)
            this.Location = Value;
        end
        function Value = get.DisturbanceInput(this)
            Value = this.Location;
        end

        function [wS,wc] = getWeight(this,Ts)
            % GETWEIGHT  Computes weighting function wS.
            %
            %   The Rejection goal is enforced as an H-infinity norm constraint
            %      || wS * S ||oo < 1
            %   on the sensitivity function S. The frequency weighting function
            %   wS is derived from the specified min attenuation profile.
            %
            %   WS = getWeight(R,TS) returns the weighting function wS for
            %   the Rejection goal R and tuning sample time TS. The gains
            %   of WS and R.MinAttenuation roughly match for gain values
            %   ranging from -20 dB to +60 dB. For numerical reasons, WS
            %   levels off outside this range unless the specified attenuation
            %   profile changes slope outside this range. Because poles of WS
            %   close to s=0 or s=Inf can adversely impact the SYSTUNE solver,
            %   it is not recommended to specify attenuation profiles with
            %   very low- or very high-frequency dynamics.
            %
            %   See also TuningGoal.Rejection, getSensitivity.
            wS = TuningGoal.resampleWeight(this.MinAttenuation,Ts);
            % Well-posedness
            if getPeakGain(wS,1e-2)<1.01
                % Attenuation factor < 1.01 at all tuned frequencies
                error(message('Control:tuning:RejectionReq1'))
            end
            beta = abs(freqresp(wS,pi/Ts));
            if beta>1e8
                % Attenuation factor is infinite at infinity
                error(message('Control:tuning:RejectionReq5'))
            end
            % Find crossovers (possibly 0) and regularize weight
            wc = getGainCrossover(wS,max(1,1.25*beta));
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
        function [MinAtt,wS,Ts,TU] = viewSpecGoalData(this,CL)
            MinAtt = this.MinAttenuation;
            MinAtt.Name = getString(message('Control:systunegui:TGPlotMinAttenuation'));
            if isequal(CL,[])
                Ts = MinAtt.Ts;
                TU = MinAtt.TimeUnit;
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
                MinAtt.TimeUnit = TU;
            end
            wS = getWeight(this,Ts);
            wS.TimeUnit = TU;
        end

        % Compute data for Design wave forms
        function [X0,Xs] = viewSpecDesignData(this,CL)
            % Compute X0
            L = getValue(getLoopTransfer(CL,this.Location,+1,this.Openings,this.Models),'usample');
            nL = size(L,1);
            X0 = eye(nL)-L;
            X0.Name = getString(message('Control:systunegui:TGPlotAttenuation'));
            % Compute scaled response Xs
            [Xs,ShowScaled] = applyLoopScaling(this,X0,getTuningInfo(CL));
            if ShowScaled
                Xs.Name = getString(message('Control:systunegui:TGPlotScaledAttenuation'));
            else
                Xs = [];
            end
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            [~,wc] = getWeight(this,Ts);
            plotHandle.XLimitsFocus = {TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts,wc)};
            updateSingularValueFocus(plotHandle);
            YUnits = char(plotHandle.MagnitudeUnit);
            Ylim = plotHandle.YLimitsFocus{1};
            Ylim(1) = unitconv(0.1,'abs',YUnits);
            Ylim(2) = max(Ylim(2),unitconv(10,'abs',YUnits));
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [MinAtt,wS,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = sigmaplot(ax,MinAtt);
                h.Responses(1).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(1).LineStyle = "--";
            else
                [X0,Xs] = viewSpecDesignData(this,CL);
                if isempty(Xs)
                    % No scaling
                    h = sigmaplot(ax,X0,MinAtt);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(2).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(2).LineStyle = "--";
                else
                    h = sigmaplot(ax,X0,Xs,MinAtt);
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
            h.Title.String = getString(message('Control:tuning:strRejectionReq1',this.Name));
            h.Title.Interpreter = 'none';
            h.YLabel.String = getString(message('Control:systunegui:TGPlotAttenuationYLabel'));
            h.AxesStyle.GridVisible = true;
            h.MagnitudeUnit = "abs";
            h.MagnitudeScale = "log";
            % Plot bounds
            addBoundResponse(h,wS,BoundType='lower',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotEffectiveBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=true,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        end

        function GoalResponses = getGoalResponses(this,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.MinAtt = PlotHandle.Responses(1);
                GoalResponses.wS = PlotHandle.Responses(2);
            else
                [~,Xs] = viewSpecDesignData(this,CL);
                if isempty(Xs)
                    GoalResponses.MinAtt = PlotHandle.Responses(2);
                    GoalResponses.wS = PlotHandle.Responses(3);
                else
                    GoalResponses.MinAtt = PlotHandle.Responses(3);
                    GoalResponses.wS = PlotHandle.Responses(4);
                end
            end
        end

        function DesignResponses = getDesignResponses(this,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.X0 = [];
                DesignResponses.Xs = [];
            else
                [~,Xs] = viewSpecDesignData(this,CL);
                if isempty(Xs)
                    DesignResponses.X0 = PlotHandle.Responses(1);
                    DesignResponses.Xs = [];
                else
                    DesignResponses.X0 = PlotHandle.Responses(1);
                    DesignResponses.Xs = PlotHandle.Responses(2);
                end
            end
        end

        function DesignResponses = getComparedResponses(this,CL,PlotHandle)
            [~,Xs] = viewSpecDesignData(this,CL);
            NRespPerDesign = 2-isempty(Xs);
            if isempty(CL)
                NDesigns = (length(PlotHandle.Responses)-2)/NRespPerDesign;
            else
                if isempty(Xs)
                    NDesigns = (length(PlotHandle.Responses)-3)/NRespPerDesign;
                else
                    NDesigns = (length(PlotHandle.Responses)-4)/NRespPerDesign;
                end
            end
            DesignResponses = repmat(struct('X0',[],'Xs',[]),NDesigns);
            for ii = 1:NDesigns
                if isempty(Xs)
                    DesignResponses(ii).X0 = PlotHandle.Responses(length(PlotHandle.Responses)+ii-NDesigns);
                else
                    DesignResponses(ii).X0 = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-1);
                    DesignResponses(ii).Xs = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign);
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
            [MinAtt,wS,~,TU] = viewSpecGoalData(this,CL);
            % Update plotted goals
            GoalResponses.MinAtt.SourceData.Model = MinAtt;
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update TBound
            GoalResponses.wS.Model = wS;
            GoalResponses.wS.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strRejectionReq1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            [X0,Xs] = viewSpecDesignData(this,CL);
            DesignResponses.X0.SourceData.Model = X0;
            if ~isempty(Xs)
                DesignResponses.Xs.SourceData.Model = Xs;
                DesignResponses.Xs.Name = Xs.Name;
            end
        end

        % Add design
        function DesignWaveforms = addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [X0,Xs] = viewSpecDesignData(this,Design);
            addResponse(PlotHandle,X0,Name=[getString(message('Control:systunegui:TGPlotAttenuation')) ': ' Name]);
            PlotHandle.Responses(end).LineStyle = LineStyle;
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            PlotHandle.Responses(end).LineWidth = 1.75;
            if isempty(Xs)
                DesignWaveforms = struct('X0',PlotHandle.Responses(end));
            else
                addResponse(PlotHandle,Xs,Name=[getString(message('Control:systunegui:TGPlotScaledAttenuation')) ': ' Name]);
                PlotHandle.Responses(end).LineStyle = LineStyle;
                PlotHandle.Responses(end-1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(6,"quaternary").SemanticName;
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
                PlotHandle.Responses(end).LineWidth = 1.75;
                DesignWaveforms = struct('X0',PlotHandle.Responses(end-1),'Xs',PlotHandle.Responses(end));
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
