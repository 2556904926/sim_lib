classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        MinLoopGain < TuningGoal.BandLimited & TuningGoal.Unstable & ...
        TuningGoal.ScaledLoop & TuningGoal.SystemLevel
    % Minimum loop gain constraint for control system tuning.
    %
    %   This requirement is useful to enforce high loop gain in a particular
    %   frequency band.
    %
    %   R = TuningGoal.MinLoopGain(LOC,LOOPGAIN) creates a tuning requirement
    %   R for boosting the gain of a SISO or MIMO feedback loop. The string
    %   or string vector LOC specifies the loop opening location(s) where the
    %   open-loop response L is measured (see below). The magnitude of the
    %   SISO transfer function LOOPGAIN specifies the minimum gain of L as a
    %   function of frequency. You can use an FRD model to sketch the desired
    %   gain profile with just a few frequency points. For example,
    %      LG = frd([100 100 10],[0 1e-1 1]);
    %      R = TuningGoal.MinLoopGain('PILoop',LG)
    %   specifies a minimum gain of 100 (40 dB) below 0.1 rad/s and decreasing
    %   by -20 dB/decade thereafter. Only gain values greater than 1 are taken
    %   into account. For MIMO feedback loops, the specified gain profile is
    %   interpreted as a lower bound on the smallest singular value of L
    %   (minimum performance).
    %
    %   R = TuningGoal.MinLoopGain(LOC,FMIN,GMIN) specifies a minimum gain
    %   profile of the form LOOPGAIN=K/s (integral action) where K is chosen
    %   so that GMIN is the minimum gain (in absolute value) at the frequency
    %   FMIN (in rad/TimeUnit).
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
    %      R = TuningGoal.MinLoopGain('InnerLoop',1,5)
    %      R.Name = 'Min gain for inner loop'
    %      R.Openings = 'OuterLoop'
    %      R.Focus = [0 1]
    %      R.Models = 2
    %   names the requirement, specifies that the loop gain is measured with
    %   the outer loop open, and restricts the requirement to the frequency
    %   band [0,1] and to the second plant model. For details on individual
    %   properties, type "help TuningGoal.MinLoopGain.<property name>".
    %
    %   Use VIEWGOAL(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Algorithm: This goal is turned into a normalized gain constraint
    %      || wS * S ||oo < 1
    %   on the sensitivity function S. The frequency weighting function wS
    %   is derived from the specified min loop gain, see GETWEIGHT for
    %   details.
    %
    %   See also AnalysisPoint, getPoints, sigma, evalGoal, viewGoal, getWeight,
    %   TuningGoal.MaxLoopGain, TuningGoal.LoopShape, TuningGoal.Gain,
    %   TuningGoal.Margins, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Minimum loop gain (SISO ZPK model).
        %
        % This property specifies the minimum open-loop gain as a function of
        % frequency. You can specify a smooth gain profile using a transfer
        % function or sketch a piecewise gain profile using an FRD model. Both
        % are mapped to a ZPK model whose magnitude reflects the desired gain
        % profile.
        MinGain
    end

    methods

        % Constructor
        function this = MinLoopGain(Loc,varargin)
            narginchk(2,3)
            if nargin>2
                % MinLoopGain(LOC,FMIN,GMIN)
                fmin = varargin{1};
                gmin = varargin{2};
                if ~(isnumeric(fmin) && isscalar(fmin) && isreal(fmin) && isfinite(fmin) && fmin>0)
                    error(message('Control:tuning:MinLoopGainReq1'))
                elseif ~(isnumeric(gmin) && isscalar(gmin) && isreal(gmin) && isfinite(gmin) && gmin>0)
                    error(message('Control:tuning:MinLoopGainReq2'))
                end
                LoopGain = zpk([],0,fmin*gmin);
            else
                LoopGain = varargin{1};
            end
            try
                this.Location = Loc;
                this.MinGain = LoopGain;
            catch ME
                throw(ME)
            end
        end

        function this = set.MinGain(this,Value)
            % SET function for MinGain
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
            this.MinGain = Value;
        end

        function [wS,wc] = getWeight(this,Ts)
            % GETWEIGHT  Computes weighting function wS.
            %
            %   The MinLoopGain goal is enforced as an H-infinity norm constraint
            %      || wS * S ||oo < 1
            %   on the sensitivity function S. The frequency weighting function
            %   wS is derived from the specified min loop gain profile.
            %
            %   WS = getWeight(R,TS) returns the weighting function wS for
            %   the MinLoopGain goal R and tuning sample time TS. The gains
            %   of WS and R.MinGain roughly match for gain values ranging
            %   from -20 dB to +60 dB. For numerical reasons, WS levels off
            %   outside this range unless the specified gain profile changes
            %   slope outside this range. Because poles of WS close to s=0 or
            %   s=Inf can adversely impact the SYSTUNE solver, it is not
            %   recommended to specify gain profiles R.MinGain with very low-
            %   or very high-frequency dynamics.
            %
            %   See also TuningGoal.MinLoopGain, getSensitivity.
            wS = TuningGoal.resampleWeight(this.MinGain,Ts);
            % Well-posedness
            if getPeakGain(wS,1e-2)<1.01
                % |wS|<1 at all frequencies (ineffective)
                error(message('Control:tuning:MinLoopGainReq6'))
            end
            beta = abs(freqresp(wS,pi/Ts));
            if beta>1e8
                % Infinite loop gain at infinity
                error(message('Control:tuning:MinLoopGainReq7'))
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
            wS = getWeight(this,S.Ts);
            wS.TimeUnit = S.TimeUnit;
            H = wS * S;
            if nargout>1
                fObj = getPeakGain(H,1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [MinG,wS,Ts,TU] = viewSpecGoalData(this,CL)
            MinG = this.MinGain;
            MinG.Name = getString(message('Control:systunegui:TGPlotMinLoopGain'));
            if isequal(CL,[])
                Ts = MinG.Ts;
                TU = MinG.TimeUnit;
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
                MinG.TimeUnit = TU;
            end
            wS = getWeight(this,Ts);
            wS.TimeUnit = TU;
        end

        % Compute data for Design wave forms
        function [L0,invS,Ls] = viewSpecDesignData(this,CL)
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
            % Compute inv(S)
            invS = eye(size(L,1)) - L;
            invS.Name = getString(message('Control:systunegui:TGPlotInverseS'));
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            [~,wc] = getWeight(this,Ts);
            plotHandle.XLimitsFocus = {TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts,wc)};
            updateSingularValueFocus(plotHandle);
            YUnits = char(plotHandle.MagnitudeUnit);
            Ylim = plotHandle.YLimitsFocus{1};
            Ylim(1) = unitconv(-20,'dB',YUnits);
            Ylim(2) = min(max(Ylim(2),unitconv(40,'dB',YUnits)),unitconv(80,'dB',YUnits));
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [MinG,wS,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = sigmaplot(ax,MinG);
                h.Responses(1).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(1).LineStyle = "--";
            else
                [L0,invS,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    % No scaling
                    h = sigmaplot(ax,invS,L0,MinG);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
                    h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(3).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(3).LineStyle = "--";
                else
                    % Plot unscaled and scaled loop gains
                    h = sigmaplot(ax,invS,L0,Ls,MinG);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
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
            h.LegendVisible = true;
            % Title
            h.Title.String = getString(message('Control:tuning:strMinLoopGain1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            % Plot bounds for T (includes regularization and discretization
            % effects)
            addBoundResponse(h,wS,BoundType='lower',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotEffectiveBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=true,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
        end

        function GoalResponses = getGoalResponses(this,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.MinG = PlotHandle.Responses(1);
                GoalResponses.wS = PlotHandle.Responses(2);
            else
                [~,~,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    GoalResponses.MinG = PlotHandle.Responses(3);
                    GoalResponses.wS = PlotHandle.Responses(4);
                else
                    GoalResponses.MinG = PlotHandle.Responses(4);
                    GoalResponses.wS = PlotHandle.Responses(5);
                end
            end
        end

        function DesignResponses = getDesignResponses(this,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.SInverse = [];
                DesignResponses.L = [];
                DesignResponses.LScaled = [];
            else
                DesignResponses.SInverse = PlotHandle.Responses(1);
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
            DesignResponses = repmat(struct('SInverse',[],'L',[],'LScaled',[]),NDesigns,1);
            for ii = 1:NDesigns
                if isempty(Ls)
                    DesignResponses(ii).SInverse = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-1);
                    DesignResponses(ii).L = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign);
                else
                    DesignResponses(ii).SInverse = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-2);
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
            [MinG,wS,~,TU] = viewSpecGoalData(this,CL);
            % Update plotted goals
            GoalResponses.MinG.SourceData.Model = MinG;
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update wS
            GoalResponses.wS.Model = wS;
            GoalResponses.wS.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strMinLoopGain1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            [L0,invS,Ls] = viewSpecDesignData(this,CL);
            % Update L, inv(S) for design
            DesignResponses.SInverse.SourceData.Model = invS;
            DesignResponses.L.SourceData.Model = L0;
            if ~isempty(Ls)
                DesignResponses.LScaled.SourceData.Model = Ls;
                DesignResponses.LScaled.Name = Ls.Name;
            end
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [L0,invS,Ls] = viewSpecDesignData(this,Design);
            addResponse(PlotHandle,invS,Name=[getString(message('Control:systunegui:TGPlotInverseS')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(5,"quaternary").SemanticName;
            addResponse(PlotHandle,L0,Name=[getString(message('Control:systunegui:TGPlotLoopGain')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
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
            [aS,bS,cS,dS] = ssdata(getWeight(this,Ts));
            pW = eig(aS);
            if nL>1
                [aS,bS,cS,dS] = TuningGoal.repWeight(aS,bS,cS,dS,nL);
            end
            % Transform T -> E+F*T*G = S = I+T
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',eye(nL),'Poles',[]),...
                'F',1,'G',1,'h',[]);
            SPEC.WL = struct('a',aS,'b',bS,'c',cS,'d',dS,'Poles',pW);
        end

    end

end
