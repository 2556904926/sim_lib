classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        MaxLoopGain < TuningGoal.BandLimited & TuningGoal.Unstable & ...
        TuningGoal.ScaledLoop & TuningGoal.SystemLevel
    % Maximum loop gain constraint for control system tuning.
    %
    %   This requirement is useful to enforce small loop gain and adequate
    %   roll-off in a particular frequency band.
    %
    %   R = TuningGoal.MaxLoopGain(LOC,LOOPGAIN) creates a tuning requirement
    %   R for limiting the gain of a SISO or MIMO feedback loop. The string
    %   or string vector LOC specifies the loop opening location(s) where the
    %   open-loop response L is measured (see below). The magnitude of the
    %   SISO transfer function LOOPGAIN specifies the maximum gain of L as a
    %   function of frequency. You can use an FRD model to sketch the desired
    %   gain profile with just a few frequency points. For example,
    %      LG = frd([1 1e-1 1e-3],[1 10 100]);
    %      R = TuningGoal.MaxLoopGain('PILoop',LG)
    %   specifies a maximum gain of 1 (0 dB) at 1 rad/s, rolling off at
    %   -20 dB/dec up to 10 rad/s and at -40 dB/dec thereafter. Only gain
    %   values smaller than 1 are taken into account. For MIMO feedback loops,
    %   the specified gain profile is interpreted as an upper bound on the
    %   largest singular value of L (minimum roll-off).
    %
    %   R = TuningGoal.MaxLoopGain(LOC,FMAX,GMAX) specifies a maximum gain
    %   profile of the form LOOPGAIN=K/s (integral action) where K is chosen
    %   so that GMAX is the maximum gain (in absolute value) at the frequency
    %   FMAX (in rad/TimeUnit).
    %
    %   In MATLAB, use AnalysisPoint blocks to mark loop opening locations (LOC
    %   can contain any name listed in the "Location" property of such blocks).
    %   For example,
    %      AP = AnalysisPoint('PILoop');
    %      G = tf(1,[1 2]);
    %      C = tunablePID('C','pi');
    %      T = feedback(AP*G*C,1);
    %   creates a SISO PI loop with a "PILoop" switch at the plant output.
    %   You can then use LOC='PILoop' to refer to the open-loop response
    %   measured at the plant output. In Simulink, LOC can contain any
    %   Linear Analysis point marked in the model or flagged using the
    %   addPoint method of the slTuner interface.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.MaxLoopGain('InnerLoop',10,0.1)
    %      R.Name = 'Max gain for inner loop'
    %      R.Openings = 'OuterLoop'
    %      R.Focus = [10 Inf]
    %      R.Models = 2
    %   names the requirement, specifies that the loop gain is measured with
    %   the outer loop open, and restricts the requirement to the frequency
    %   band [10,Inf] and to the second plant model. For details on individual
    %   properties, type "help TuningGoal.MaxLoopGain.<property name>".
    %
    %   Use VIEWGOAL(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Algorithm: This goal is turned into a normalized gain constraint
    %      || wT * T ||oo < 1
    %   on the complementary sensitivity function T=1-S. The frequency
    %   weighting function wT is derived from the specified max loop gain,
    %   see GETWEIGHT for details.
    %
    %   See also AnalysisPoint, getPoints, sigma, evalGoal, viewGoal, getWeight,
    %   TuningGoal.MinLoopGain, TuningGoal.LoopShape, TuningGoal.Gain,
    %   TuningGoal.Margins, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Maximum loop gain (SISO ZPK model).
        %
        % This property specifies the maximum open-loop gain as a function of
        % frequency. You can specify a smooth gain profile using a transfer
        % function or sketch a piecewise gain profile using an FRD model. Both
        % are mapped to a ZPK model whose magnitude reflects the desired gain
        % profile.
        MaxGain
    end

    methods

        % Constructor
        function this = MaxLoopGain(Loc,varargin)
            narginchk(2,3)
            if nargin>2
                % MaxLoopGain(LOC,FMAX,GMAX)
                fmax = varargin{1};
                gmax = varargin{2};
                if ~(isnumeric(fmax) && isscalar(fmax) && isreal(fmax) && isfinite(fmax) && fmax>0)
                    error(message('Control:tuning:MaxLoopGainReq1'))
                elseif ~(isnumeric(gmax) && isscalar(gmax) && isreal(gmax) && isfinite(gmax) && gmax>0)
                    error(message('Control:tuning:MaxLoopGainReq2'))
                end
                LoopGain = zpk([],0,fmax*gmax);
            else
                LoopGain = varargin{1};
            end
            try
                this.Location = Loc;
                this.MaxGain = LoopGain;
            catch ME
                throw(ME)
            end
        end

        function this = set.MaxGain(this,Value)
            % SET function for MaxGain
            [Value,errCode] = TuningGoal.checkMagProfile(Value);
            switch errCode
                case 1
                    % Not scalar or SISO value
                    error(message('Control:tuning:MinLoopGainReq3'))
                case 2
                    % Cannot compute ZPK form
                    error(message('Control:tuning:MinLoopGainReq4'))
                case 3
                    % All zero profile
                    error(message('Control:tuning:MinLoopGainReq5'))
            end
            this.MaxGain = Value;
        end

        function [wT,wc] = getWeight(this,Ts)
            % GETWEIGHT  Computes weighting function wT.
            %
            %   The MaxLoopGain goal is enforced as an H-infinity norm constraint
            %      || wT * T ||oo < 1
            %   on the complementary sensitivity function T=1-S. The frequency
            %   weighting function wT is derived from the specified max loop
            %   gain profile.
            %
            %   WT = getWeight(R,TS) returns the weighting function wT for
            %   the MaxLoopGain goal R and tuning sample time TS. The gains
            %   of 1/WT and R.MaxGain roughly match for gain values ranging
            %   from +20 dB to -60 dB. For numerical reasons, WT levels off
            %   outside this range unless the specified gain profile changes
            %   slope outside this range. Because poles of WT close to s=0 or
            %   s=Inf can adversely impact the SYSTUNE solver, it is not
            %   recommended to specify gain profiles R.MaxGain with very low-
            %   or very high-frequency dynamics.
            %
            %   See also TuningGoal.MaxLoopGain, getSensitivity.
            wT = TuningGoal.resampleWeight(1/this.MaxGain,Ts);
            % Well-posedness
            if getPeakGain(wT,1e-2)<1.01
                % |wT|<1 at all frequencies (ineffective)
                error(message('Control:tuning:MaxLoopGainReq3'))
            end
            % Find gain crossovers
            wc = getGainCrossover(wT,1);
            if ~any(wc>0 & wc<pi/Ts)
                % |wT|>1 at all frequencies: adjust gain level for crossover
                g0 = abs(dcgain(wT));
                if g0>1e8
                    error(message('Control:tuning:MaxLoopGainReq4'))
                end
                wc = getGainCrossover(wT,1.25*g0); % could still be empty, e.g., for constant wT
            end
            % Regularize weight
            wT = TuningGoal.regularizeWeight1(wT,wc,this.Focus);
        end

    end

    methods (Access = protected)

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            S = getSensitivity(CL,this.Location,this.Openings,this.Models);
            S = sminreal(getValue(S));
            nL = size(S,1);
            T = eye(nL)-S;
            % Scaling
            T = applyLoopScaling(this,T,getTuningInfo(CL));
            % Evaluate goal
            wT = getWeight(this,T.Ts);
            wT.TimeUnit = T.TimeUnit;
            H = wT * T;
            if nargout>1
                fObj = getPeakGain(H,1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [MaxG,TBound,Ts,TU] = viewSpecGoalData(this,CL)
            MaxG = this.MaxGain;
            MaxG.Name = getString(message('Control:systunegui:TGPlotMaxLoopGain'));
            if isequal(CL,[])
                Ts = MaxG.Ts;
                TU = MaxG.TimeUnit;
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
                MaxG.TimeUnit = TU;
            end
            wT = getWeight(this,Ts);
            wT.TimeUnit = TU;
            TBound = 1/wT;
        end

        % Compute data for Design wave forms
        function [L0,T,Ls] = viewSpecDesignData(this,CL)
            % Compute L0
            L0 = getValue(getLoopTransfer(CL,this.Location,+1,this.Openings,this.Models),'usample');
            L0.Name = getString(message('Control:systunegui:TGPlotLoopGain'));
            % Compute scaled response Ls
            [L,ShowScaled] = applyLoopScaling(this,L0,getTuningInfo(CL));
            if ShowScaled
                Ls = L;
                Ls.Name = getString(message('Control:systunegui:TGPlotScaledLoopGain'));
            else
                Ls = [];
            end
            % Compute T
            T = feedback(L,eye(size(L,1)),+1);
            T.Name = getString(message('Control:systunegui:TGPlotT'));
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            [~,wc] = getWeight(this,Ts);
            plotHandle.XLimitsFocus = {TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts,wc)};
            updateSingularValueFocus(plotHandle);
            YUnits = char(plotHandle.MagnitudeUnit);
            Ylim = plotHandle.YLimitsFocus{1};
            Ylim(1) = max(min(Ylim(1),unitconv(-40,'dB',YUnits)),unitconv(-80,'dB',YUnits));
            Ylim(2) = unitconv(20,'dB',YUnits);
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [MaxG,TBound,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = sigmaplot(ax,MaxG);
                h.Responses(1).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(1).LineStyle = "--";
            else
                [L0,T,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    % No scaling
                    h = sigmaplot(ax,T,L0,MaxG);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
                    h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(3).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(3).LineStyle = "--";
                else
                    h = sigmaplot(ax,T,L0,Ls,MaxG);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
                    h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(6).SemanticName;
                    h.Responses(3).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(4).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(4).LineStyle = "--";
                end
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Legend
            h.LegendLocation = "southwest";
            h.LegendVisible = true;
            % Title
            h.Title.String = getString(message('Control:tuning:strMaxLoopGain1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            
            % Plot bounds for T (includes regularization and discretization
            % effects)
            addBoundResponse(h,TBound,BoundType='upper',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotEffectiveBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=true,FaceAlpha=0.3,EdgeAlpha=0.3);
           
            % Set style for bounds
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
        end

        function GoalResponses = getGoalResponses(this,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.MaxG = PlotHandle.Responses(1);
                GoalResponses.TBound = PlotHandle.Responses(2);
            else
                [~,~,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    GoalResponses.MaxG = PlotHandle.Responses(3);
                    GoalResponses.TBound = PlotHandle.Responses(4);
                else
                    GoalResponses.MaxG = PlotHandle.Responses(4);
                    GoalResponses.TBound = PlotHandle.Responses(5);
                end
            end
        end

        function DesignResponses = getDesignResponses(this,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.T = [];
                DesignResponses.L = [];
                DesignResponses.LScaled = [];
            else
                DesignResponses.T = PlotHandle.Responses(1);
                DesignResponses.L = PlotHandle.Responses(2);
                [~,~,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    DesignResponses.LScaled = [];
                else
                    DesignResponses.LScaled = PlotHandle.Responses(3);
                end
            end
        end

        function DesignResponses = getComparedResponses(this,CL,PlotHandle)
            [~,~,Ls] = viewSpecDesignData(this,CL);
            NRespPerDesign = 3-isempty(Ls);
            if isempty(CL)
                NDesigns = (length(PlotHandle.Responses)-2)/NRespPerDesign;
            else
                if isempty(Ls)
                    NDesigns = (length(PlotHandle.Responses)-4)/NRespPerDesign;
                else
                    NDesigns = (length(PlotHandle.Responses)-5)/NRespPerDesign;
                end
            end
            DesignResponses = repmat(struct('T',[],'L',[],'LScaled',[]),NDesigns,1);
            for ii = 1:NDesigns
                if isempty(Ls)
                    DesignResponses(ii).T = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-1);
                    DesignResponses(ii).L = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign);
                else
                    DesignResponses(ii).T = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-2);
                    DesignResponses(ii).L = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-1);
                    DesignResponses(ii).LScaled = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign);
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
            [MaxG,TBound,~,TU] = viewSpecGoalData(this,CL);
            % Update plotted goals
            GoalResponses.MaxG.SourceData.Model = MaxG;
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update TBound
            GoalResponses.TBound.Model = TBound;
            GoalResponses.TBound.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strMaxLoopGain1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            [L0,T,Ls] = viewSpecDesignData(this,CL);
            DesignResponses.T.SourceData.Model = T;
            DesignResponses.L.SourceData.Model = L0;
            if ~isempty(Ls)
                DesignResponses.LScaled.SourceData.Model = Ls;
                DesignResponses.LScaled.Name = Ls.Name;
            end
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [L0,T,Ls] = viewSpecDesignData(this,Design);
            addResponse(PlotHandle,T,Name=[getString(message('Control:systunegui:TGPlotT')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10,"quaternary").SemanticName;
            addResponse(PlotHandle,L0,Name=[getString(message('Control:systunegui:TGPlotLoopGain')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            if isempty(Ls)
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            else
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(6,"quaternary").SemanticName;
                addResponse(PlotHandle,Ls,Name=Name,LineStyle=LineStyle,LineWidth=1.75);
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            end
        end

    end

    methods (Hidden)

        function validateGoal(this,CL)
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
            SPEC.Stabilize = this.Stabilize;
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
            % Get weights
            [aT,bT,cT,dT] = ssdata(getWeight(this,Ts));
            pW = eig(aT);
            if nL>1
                [aT,bT,cT,dT] = TuningGoal.repWeight(aT,bT,cT,dT,nL);
            end
            SPEC.WL = struct('a',aT,'b',bT,'c',cT,'d',dT,'Poles',pW);
        end

    end

end
