classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        LoopShape < TuningGoal.BandLimited & TuningGoal.Unstable & ...
        TuningGoal.ScaledLoop & TuningGoal.SystemLevel
    % Target loop shape for control system tuning.
    %
    %   R = TuningGoal.LoopShape(LOC,LOOPGAIN) creates a tuning requirement R
    %   for shaping the open-loop response measured at the location(s) LOC.
    %   The string or string vector LOC specifies one or more loop opening
    %   locations (see below). The magnitude of the SISO transfer function
    %   LOOPGAIN specifies the target gain profile. You can use an FRD model
    %   to sketch the desired gain profile with just a few frequency points.
    %   For example,
    %      L = frd([100 1 0.0001],[0.01 1 100]);
    %      R = TuningGoal.LoopShape('PILoop',L)
    %   specifies a loop shape with integral action, gain crossover at 1, and
    %   roll-off of -40 dB/decade. For MIMO control loops, gain values greater
    %   than 1 are interpreted as lower bounds on the smallest singular value
    %   of the open-loop response L (minimum performance) and gain values
    %   smaller than 1 are interpreted as upper bounds on the largest singular
    %   value of L (minimum roll-off). See SIGMA for details on singular values
    %   of MIMO transfer functions.
    %
    %   R = TuningGoal.LoopShape(LOC,LOOPGAIN,CROSSTOL) further specifies a
    %   tolerance CROSSTOL (in decades) for the location of the gain crossover
    %   frequency. This tolerance is useful in MIMO control loops to allow
    %   different crossover frequencies for different loops/directions. For
    %   example, CROSSTOL=0.5 allows gain crossovers within half a decade on
    %   either side of the target crossover frequency specified by LOOPGAIN.
    %   The default value is CROSSTOL=0.1.
    %
    %   R = TuningGoal.LoopShape(LOC,WC) just specifies the target gain
    %   crossover frequency WC (in rad/TimeUnit) and is equivalent to using
    %   LOOPGAIN = WC/s (pure integrator).
    %
    %   R = TuningGoal.LoopShape(LOC,[WC1,WC2]) specifies a range [WC1,WC2]
    %   for the gain crossover frequency. This is equivalent to using the
    %   geometric mean of WC1,WC2 as crossover frequency (WC = sqrt(WC1*WC2))
    %   and setting CROSSTOL to the half-width of [WC1,WC2] in decades.
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
    %      R = TuningGoal.LoopShape('InnerLoop',tf(1,[1 0]))
    %      R.Name = 'Inner loop shape'
    %      R.Openings = 'OuterLoop'
    %      R.Focus = [0 30]
    %      R.Models = 2
    %   names the requirement, specifies that the target loop shape is with
    %   the outer loop open, and restricts the requirement to the frequency
    %   band [0,30] and to the second plant model. For details on individual
    %   properties, type "help TuningGoal.LoopShape.<property name>".
    %
    %   Use VIEWSPEC(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Note: Use the MinLoopGain and MaxLoopGain requirements when the
    %   loop shape near crossover is complex or unknown.
    %
    %   Algorithm: This goal is turned into a normalized gain constraint
    %      || [wS * S ; wT * T] ||oo < 1
    %   on the sensitivity functions S and T=1-S. The frequency weighting
    %   functions wS and wT are derived from the target loop shape, see
    %   GETWEIGHTS for details.
    %
    %   See also AnalysisPoint, getPoints, sigma, evalGoal, viewGoal, getWeights,
    %   TuningGoal.MinLoopGain, TuningGoal.MaxLoopGain, TuningGoal.Gain,
    %   TuningGoal.Margins, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    % Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Target loop shape (SISO ZPK model).
        %
        % This property specifies the desired open-loop gain as a function of
        % frequency. You can specify a smooth gain profile using a transfer
        % function or sketch a piecewise gain profile using an FRD model. Both
        % are mapped to a ZPK model whose magnitude reflects the desired loop
        % shape.
        LoopGain

        % Tolerance on gain crossover frequency (in decades, default = 0.1).
        %
        % In multi-loop or MIMO control systems, it is recommended to specify
        % a crossover region [wcmin,wcmax] rather than require the same gain
        % crossover frequency for all loops/directions. The "CrossTol" property
        % specifies the half-width of the crossover region in decades. Increase
        % this tolerance when you have difficulties getting all curves in the
        % open-loop SIGMA plot to cross the 0dB line at the same frequency.
        CrossTol = 0.1;
    end

    properties (Hidden, Dependent, Transient)
        % Obsoleted in R2013b
        % Note: Nothing to do at load time, set.LoopTransfer will take care
        %       of remapping data
        LoopTransfer
    end

    methods

        % Constructor
        function this = LoopShape(varargin)
            narginchk(1,3)
            arg1 = varargin{1};
            try
                if (isnumeric(arg1) || isa(arg1,'DynamicSystem'))
                    % Support LoopShape(LoopGain,CrossTol) for backward compatibility
                    narginchk(1,2)
                    this.LoopGain = arg1;
                    if nargin>1
                        this.CrossTol = varargin{2};
                    end
                else
                    % LoopShape(LOC,...)
                    narginchk(2,3)
                    this.Location = arg1;
                    arg2 = varargin{2};
                    if isnumeric(arg2)
                        % LoopShape(LOC,WC) or LoopShape(LOC,[WC1,WC2])
                        nwc = numel(arg2);
                        if ~(isreal(arg2) && (nwc==1 || nwc==2))
                            error(message('Control:tuning:LoopShapeReq13'))
                        elseif nwc==1
                            wcmin = arg2;   wcmax = arg2;
                        else
                            wcmin = arg2(1);  wcmax = arg2(2);
                        end
                        if wcmin<=0 || wcmin>wcmax
                            error(message('Control:tuning:LoopShapeReq14'))
                        end
                        this.LoopGain = zpk([],0,sqrt(wcmin*wcmax));
                        this.CrossTol = max(log10(wcmax/wcmin)/2,0.1);
                    else
                        this.LoopGain = arg2;
                        if nargin>2
                            this.CrossTol = varargin{3};
                        end
                    end
                end
            catch ME
                throw(ME)
            end
        end

        function this = set.LoopGain(this,Value)
            % SET function for LoopGain
            [Value,errCode] = TuningGoal.checkMagProfile(Value);
            switch errCode
                case 1
                    % Not scalar or SISO value
                    error(message('Control:tuning:LoopShapeReq1'))
                case 2
                    % Cannot compute ZPK form
                    error(message('Control:tuning:LoopShapeReq5'))
                case 3
                    % All zero profile
                    error(message('Control:tuning:LoopShapeReq6'))
            end
            if ~isproper(Value)
                error(message('Control:tuning:LoopShapeReq2'))
            end
            this.LoopGain = Value;
        end

        function this = set.CrossTol(this,Value)
            % SET function for CrossTol
            if ~(isnumeric(Value) && isscalar(Value) && isreal(Value) && ...
                    isfinite(Value) && Value>=0)
                error(message('Control:tuning:LoopShapeReq4'))
            end
            this.CrossTol = double(Value);
        end

        % Obsolete properties
        function this = set.LoopTransfer(this,Value)
            this.Location = Value;
        end
        function Value = get.LoopTransfer(this)
            Value = this.Location;
        end

        function [wS,wT,wc] = getWeights(this,Ts)
            % GETWEIGHT  Computes weighting function wS and wT.
            %
            %   The LoopShape goal is enforced as an H-infinity norm constraint
            %      || [wS * S ; wT * T] ||oo < 1
            %   on the sensitivity functions S and T=1-S. The frequency
            %   weighting functions wS and wT are derived from the specified
            %   target loop shape.
            %
            %   [WS,WT] = getWeights(R,TS) returns the weighting functions
            %   wS and wT for the LoopShape goal R and tuning sample time TS.
            %   The gains of WS and WT roughly match those of R.LoopGain and
            %   1/R.LoopGain for values ranging from -20 dB to +60 dB. For
            %   numerical reasons, WS and WT level off outside this range
            %   unless the specified loop gain profile changes slope for gains
            %   above +60 dB or below -60 dB. Because poles of WS or WT close
            %   to s=0 or s=Inf can adversely impact the SYSTUNE solver, it is
            %   not recommended to specify a gain profile R.LoopGain with very
            %   low- or very high-frequency dynamics.
            %
            %   See also TuningGoal.LoopShape, getSensitivity.
            LS = this.LoopGain;
            % Find 0dB gain crossovers
            wc = getGainCrossover(LS,1);
            wc = wc(wc>0 & wc<pi/Ts);
            if isempty(wc) || abs(freqresp(LS,pi/Ts))>=0.99
                error(message('Control:tuning:LoopShapeReq3'))
            end
            % Construct weights for S and T, taking CrossTol into account
            [wS,wT,wcS,wcT] = localComputeST(LS,wc,this.CrossTol);
            % Resample and regularize weights
            wS = TuningGoal.resampleWeight(wS,Ts);
            wS = TuningGoal.regularizeWeight1(wS,wcS,this.Focus);
            wT = TuningGoal.resampleWeight(wT,Ts);
            wT = TuningGoal.regularizeWeight1(wT,wcT,this.Focus);
        end

    end

    methods (Access = protected)

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            LoopChannels = this.Location;
            if isempty(LoopChannels)
                % Grab all loop channels
                error(message('Control:tuning:LoopShapeReq11'))
            end
            S = getSensitivity(CL,LoopChannels,this.Openings,this.Models);
            S = sminreal(getValue(S));
            TU = S.TimeUnit;
            % Scaling
            S = applyLoopScaling(this,S,getTuningInfo(CL));
            % Evaluate goal
            T = S - eye(size(S,1));
            [wS,wT] = getWeights(this,S.Ts);
            wS.TimeUnit = TU;   wT.TimeUnit = TU;
            H = [wS * S ; wT * T];
            if nargout>1
                fObj = getPeakGain(H,1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning Goal Plot API

        % Compute data for Goal wave forms
        function [TargetL,wS,wT,Ts,TU] = viewSpecGoalData(this,CL)
            % Target loop shape
            TargetL = this.LoopGain;
            if isequal(CL,[])
                Ts = TargetL.Ts;
                TU = TargetL.TimeUnit;
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
                TargetL.TimeUnit = TU;
            end
            TargetL.Name = getString(message('Control:systunegui:TGPlotTargetLoopShape'));
            % Goal bounds
            [wS,wT] = getWeights(this,Ts);
            wS.TimeUnit = TU;
            wT.TimeUnit = TU;
        end

        % Compute data for Design wave forms
        function [L0,S,T,Ls] = viewSpecDesignData(this,CL)
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
            % Compute S and T
            nL = size(L,1);
            S = feedback(eye(nL),L,+1);
            S.Name = getString(message('Control:systunegui:TGPlotS'));
            T = S - eye(nL);
            T.Name = getString(message('Control:systunegui:TGPlotT'));
        end

        % Create plot
        function h = createPlot(this, CL,ax)
            % Get viewGoal Goal data
            [TargetL,wS,wT,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = sigmaplot(ax,TargetL);
                % GoalWaveforms
                h.Responses(1).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(1).LineStyle = "--";
            else
                % Compute Design data
                [L0,S,T,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    % No scaling
                    h = sigmaplot(ax,S,T,L0,TargetL);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
                    h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
                    h.Responses(3).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(4).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(4).LineStyle = "--";
                else
                    % Plot unscaled and scaled loop gains
                    h = sigmaplot(ax,S,T,L0,Ls,TargetL);
                    h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
                    h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
                    h.Responses(3).SemanticColor = controllib.plot.internal.utils.GraphicsColor(6).SemanticName;
                    h.Responses(4).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                    h.Responses(5).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                    h.Responses(5).LineStyle = "--";
                end
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Legend
            h.LegendVisible = true;
            % Title
            h.Title.String = getString(message('Control:tuning:strLoopShapeReq2',...
                this.Name,sprintf('%0.3g',this.CrossTol)));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            % Plot bounds for S,T
            addBoundResponse(h,wS,BoundType='SBound',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotSBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=true,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
            addBoundResponse(h,wT,BoundType='TBound',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotTBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=true,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
        end

        function GoalResponses = getGoalResponses(this,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.TargetL = PlotHandle.Responses(1);
                GoalResponses.wS = PlotHandle.Responses(2);
                GoalResponses.wT = PlotHandle.Responses(3);
            else
                [~,~,~,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    GoalResponses.TargetL = PlotHandle.Responses(4);
                    GoalResponses.wS = PlotHandle.Responses(5);
                    GoalResponses.wT = PlotHandle.Responses(6);
                else
                    GoalResponses.TargetL = PlotHandle.Responses(5);
                    GoalResponses.wS = PlotHandle.Responses(6);
                    GoalResponses.wT = PlotHandle.Responses(7);
                end
            end
        end

        function DesignResponses = getDesignResponses(this,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.S = [];
                DesignResponses.T = [];
                DesignResponses.L = [];
                DesignResponses.LScaled = [];
            else
                DesignResponses.S = PlotHandle.Responses(1);
                DesignResponses.T = PlotHandle.Responses(2);
                DesignResponses.L = PlotHandle.Responses(3);
                [~,~,~,Ls] = viewSpecDesignData(this,CL);
                if isempty(Ls)
                    DesignResponses.LScaled = [];
                else
                    DesignResponses.LScaled = PlotHandle.Responses(4);
                end
            end
        end

        function DesignResponses = getComparedResponses(this,CL,PlotHandle)
            [~,~,~,Ls] = viewSpecDesignData(this,CL);
            NRespPerDesign = 4-isempty(Ls);
            if isempty(CL)
                NDesigns = (length(PlotHandle.Responses)-3)/NRespPerDesign;
            else
                if isempty(Ls)
                    NDesigns = (length(PlotHandle.Responses)-6)/NRespPerDesign;
                else
                    NDesigns = (length(PlotHandle.Responses)-7)/NRespPerDesign;
                end
            end
            DesignResponses = repmat(struct('S',[],'T',[],'L',[],'LScaled',[]),NDesigns,1);
            for ii = 1:NDesigns
                if isempty(Ls)
                    DesignResponses(ii).S = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-2);
                    DesignResponses(ii).T = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-1);
                    DesignResponses(ii).L = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign);
                else
                    DesignResponses(ii).S = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-3);
                    DesignResponses(ii).T = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-2);
                    DesignResponses(ii).L = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign-1);
                    DesignResponses(ii).LScaled = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*NRespPerDesign);
                end
            end
        end

        function Ts = getTs(this,CL)
            [~,~,~,Ts,~] = viewSpecGoalData(this,CL);
        end

        function TU = getTU(this,CL)
            [~,~,~,~,TU] = viewSpecGoalData(this,CL);
        end

        % Update Goal wave forms
        function updateGoal(this,CL,PlotHandle)
            GoalResponses = getGoalResponses(this,CL,PlotHandle);
            % Compute data for goals
            [TargetL,wS,wT,~,TU] = viewSpecGoalData(this,CL);
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update TargetL
            GoalResponses.TargetL.SourceData.Model = TargetL;
            % Update wS and wT
            GoalResponses.wS.Model = wS;
            GoalResponses.wS.Focus = wFocus;
            GoalResponses.wT.Model = wT;
            GoalResponses.wT.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strLoopShapeReq2',...
                this.Name,sprintf('%0.3g',this.CrossTol)));
        end

        % Update Design wave forms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            [L0,S,T,Ls] = viewSpecDesignData(this,CL);
            % Update L, T and S for design
            DesignResponses.L.SourceData.Model = L0;
            DesignResponses.T.SourceData.Model = T;
            DesignResponses.S.SourceData.Model = S;
            if ~isempty(Ls)
                DesignResponses.LScaled.SourceData.Model = Ls;
                DesignResponses.LScaled.Name = Ls.Name;
            end
        end

        % Add Design wave forms
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [L0,S,T,Ls] = viewSpecDesignData(this,Design);
            addResponse(PlotHandle,S,Name=[getString(message('Control:systunegui:TGPlotS')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(5,"quaternary").SemanticName;
            addResponse(PlotHandle,T,Name=[getString(message('Control:systunegui:TGPlotT')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10,"quaternary").SemanticName;
            addResponse(PlotHandle,L0,Name=[getString(message('Control:systunegui:TGPlotLoopGain')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            if isempty(Ls)
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            else
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(6,"quaternary").SemanticName;
                addResponse(PlotHandle,Ls,Name=Name,LineStyle=LineStyle,LineWidth=1.75);
                PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            end
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            [~,~,wc] = getWeights(this,Ts);
            gap = 10^this.CrossTol;
            wc = [wc(1)/gap , gap*wc(end)];
            Xlim = TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts,wc);
            plotHandle.XLimitsFocus = {Xlim};
            updateSingularValueFocus(plotHandle);
            YUnits = char(plotHandle.MagnitudeUnit);
            Ylim = plotHandle.YLimitsFocus{1};
            Ylim(1) = min(max(Ylim(1),unitconv(-40,'dB',YUnits)),unitconv(-20,'dB',YUnits));
            Ylim(2) = min(max(Ylim(2),unitconv(20,'dB',YUnits)),unitconv(40,'dB',YUnits));
            plotHandle.YLimitsFocus = {Ylim};
        end
    end

    methods (Hidden)

        function validateGoal(this,CL)
            % Note: Needed to validate Models selection
            S = getSensitivity(CL,this.Location,this.Openings,this.Models);
            getWeights(this,S.Ts);
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
            [wS,wT] = getWeights(this,Ts);
            [aS,bS,cS,dS] = ssdata(wS);
            [aT,bT,cT,dT] = ssdata(wT);
            pW = [eig(aS) ; eig(aT)];
            if nL>1
                [aS,bS,cS,dS] = TuningGoal.repWeight(aS,bS,cS,dS,nL);
                [aT,bT,cT,dT] = TuningGoal.repWeight(aT,bT,cT,dT,nL);
            end
            % Transform T -> E+F*T*G = [S;T] with S=I+T
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',[eye(nL);zeros(nL)],'Poles',[]),...
                'F',[eye(nL);eye(nL)],'G',1,'h',[]);
            % blkdiag(wS*eye(nL),wT*eye(nL))
            SPEC.WL = struct('a',blkdiag(aS,aT),'b',blkdiag(bS,bT),'c',...
                blkdiag(cS,cT),'d',blkdiag(dS,dT),'Poles',pW);
        end

    end

end

%------------

function [wS,wT,wcS,wcT] = localComputeST(LS,wc,CrossTol)
% Computes weights wS and wT from target loop shape LS
[z,p,k,Ts] = zpkdata(LS,'v');
nf = pi/Ts;
TU = LS.TimeUnit;
wnz = damp(z,Ts);
wnp = damp(p,Ts);
if Ts~=0
    % Put aside zeros and poles past Nyquist frequency
    zkeep = (wnz<nf);  zf = z(~zkeep);  z = z(zkeep);  wnz = wnz(zkeep);
    pkeep = (wnp<nf);  pf = p(~pkeep);  p = p(pkeep);  wnp = wnp(pkeep);
end
% Shift dynamics to create CrossTol gap
if numel(wc)>1
    [wShiftZ,wShiftP,wShiftC] = localComputeShifts(wc,wnz,wnp,CrossTol);
    if Ts==0
        tau = prod(wShiftZ)/prod(wShiftP);
        wS = zpk(z./wShiftZ,p./wShiftP,k*tau,'TimeUnit',TU);
        wT = zpk(p.*wShiftP,z.*wShiftZ,tau/k,'TimeUnit',TU);
    else
        [zS,pS,kS] = localApplyShifts(z,p,k,1./wShiftZ,1./wShiftP);
        wS = zpk([zf;zS],[pf;pS],kS,Ts,'TimeUnit',TU);
        [zT,pT,kT] = localApplyShifts(z,p,k,wShiftZ,wShiftP);
        wT = zpk([pf;pT],[zf;zT],1/kT,Ts,'TimeUnit',TU);
    end
else
    wShiftC = 10^CrossTol;
    if Ts==0
        tau = wShiftC^(numel(z)-numel(p));
        wS = zpk(z/wShiftC,p/wShiftC,k*tau,'TimeUnit',TU);
        wT = zpk(p*wShiftC,z*wShiftC,tau/k,'TimeUnit',TU);
    else
        [zS,pS,kS] = localApplyShifts(z,p,k,1/wShiftC,1/wShiftC);
        wS = zpk([zf;zS],[pf;pS],kS,Ts,'TimeUnit',TU);
        [zT,pT,kT] = localApplyShifts(z,p,k,wShiftC,wShiftC);
        wT = zpk([pf;pT],[zf;zT],1/kT,Ts,'TimeUnit',TU);
    end
    % [getGainCrossover(wT,1)/getGainCrossover(wS,1) 10^(2*CrossTol)]
end
% Shift crossover frequencies
wcS = wc./wShiftC;
wcT = wc.*wShiftC;
end

function [z,p,k] = localApplyShifts(z0,p0,k,alphaZ,alphaP)
% Applies frequency shifts to discrete-time data
if isscalar(alphaZ)
    alphaZ = repmat(alphaZ,size(z0));
end
NearOne = abs(z0-1)<1e-6;  % *(1-z^alpha)/(1-z)->alpha as z->1
z = z0.^alphaZ;
tauZ = prod(alphaZ(NearOne)) * prod((1-z(~NearOne))./(1-z0(~NearOne)));
if isscalar(alphaP)
    alphaP = repmat(alphaP,size(p0));
end
NearOne = abs(p0-1)<1e-6;
p = p0.^alphaP;
tauP = prod(alphaP(NearOne)) * prod((1-p(~NearOne))./(1-p0(~NearOne)));
k = k * real(tauP / tauZ);
end

function [wShiftZ,wShiftP,wShiftC] = localComputeShifts(wc,fz,fp,CrossTol)
% Compute shifts to apply to zeros and poles of wS and wT to account for
% CrossTol
nwc = numel(wc); % at least two
if any(wc(2:nwc)<wc(1:nwc-1)*10^(2*CrossTol))
    error(message('Control:tuning:LoopShapeReq16'))
end
% Direction of shift alternates with crossover
sgns = ones(nwc,1);
sgns(nwc-1:-2:1) = -1;
wShiftC = 10.^(CrossTol * sgns);
f = [wc ; sqrt(wc(1:nwc-1).*wc(2:nwc)) ; wc(1)/10 ; 10*wc(nwc)];
y = [sgns ; zeros(nwc-1,1) ; sgns([1 nwc-1])];
[f,is] = sort(f);
y = y(is);
% Use cubic interpolation to determine appropriate shift at pole/zero
% frequencies
fi = [fz;fp];
yi = interp1(log(f),y,log(fi),'pchip');
yi(fi<f(1)) = sgns(1);
yi(fi>f(end)) = sgns(end);
wShift = 10.^(CrossTol * yi);
nz = numel(fz);
wShiftZ = wShift(1:nz,:);
wShiftP = wShift(nz+1:end,:);
end

