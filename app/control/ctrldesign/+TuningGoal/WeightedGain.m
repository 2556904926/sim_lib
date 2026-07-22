classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        WeightedGain < TuningGoal.BandLimited & TuningGoal.Unstable & ...
        TuningGoal.GenericIO & TuningGoal.SystemLevel
    % Frequency-weighted gain constraint for control system tuning.
    %
    %   R = TuningGoal.WeightedGain(INPUTNAME,OUTPUTNAME,WL,WR) creates the
    %   tuning requirement
    %      || WL(s) H(s) WR(s) ||oo < 1
    %   for the closed-loop transfer function H(s) from inputs INPUTNAME to
    %   outputs OUTPUTNAME, where ||.||oo denotes the maximum gain across
    %   frequency (H-infinity norm). The signal names INPUTNAME and OUTPUTNAME
    %   can be strings or cell arrays of strings for vector-valued signals.
    %   The frequency-weighting functions WL and WR can be specified as scalars
    %   or LTI models. The value [] is interpreted as the identity. For example
    %       WL = tf(1,[1 0.01])
    %       WR = diag([1 10])
    %       R = TuningGoal.WeightedGain('d','y',WL,WR)
    %   creates a frequency-weighted gain constraint for the two-input
    %   closed-loop transfer function from d to y.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.WeightedGain('d','y',WL,WR)
    %      R.Name = 'Disturbance rejection'
    %      R.Focus = [0 10]
    %      R.Openings = 'OuterLoop'
    %      R.Models = 2
    %   names the requirement, specifies that it should be evaluated with
    %   the outer loop open, and restricts it to the frequency band [0,10]
    %   and the second plant model. For details on individual properties,
    %   type "help TuningGoal.WeightedGain.<property name>".
    %
    %   Use VIEWGOAL(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   See also sigma, getPeakGain, evalGoal, viewGoal, TuningGoal.Gain,
    %   TuningGoal.LoopShape, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

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
        function this = WeightedGain(InputName,OutputName,WL,WR)
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
                    WF = ss(TuningGoal.regularizeWeight2(WF,this.Focus,false));
                end
            end
        end

    end

    methods (Access = protected)

        function H = getClosedLoopTransfer_(this,CL,varargin)
            % Computes weighted closed-loop transfer from r to e=y-r
            H = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            H = sminreal(getValue(H,varargin{:}));
            Ts = abs(H.Ts);
            TU = H.TimeUnit;
            WL = getWeight(this,Ts,'WL');
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
        end

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            H = getClosedLoopTransfer_(this,CL);
            if nargout>1
                fObj = getPeakGain(H,1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [Bound,Ts,TU] = viewSpecGoalData(~,CL)
            if isequal(CL,[])
                Ts = 0;
                TU = 'seconds';
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
            end
            Bound = zpk(1,'Ts',Ts,'TimeUnit',TU);
        end

        % Compute data for Design wave forms
        function X = viewSpecDesignData(this,CL)
            X = getClosedLoopTransfer_(this,CL,'usample');
            X.Name = getString(message('Control:systunegui:TGPlotGain'));
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            plotHandle.XLimitsFocus = {TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts)};
            updateSingularValueFocus(plotHandle);
            YUnits = char(plotHandle.MagnitudeUnit);
            Ylim = plotHandle.YLimitsFocus{1};
            if all(isnan(Ylim))
                Ylim = [0 1];
            end
            Ylim(1) = min(max(Ylim(1),unitconv(-40,'dB',YUnits)),unitconv(-10,'dB',YUnits));
            Ylim(2) = min(max(Ylim(2),unitconv(10,'dB',YUnits)),unitconv(40,'dB',YUnits));
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [Bound,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = controllib.chart.internal.utils.ltiplot("sigma",ax);
            else
                X = viewSpecDesignData(this,CL);
                h = sigmaplot(ax,X);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Legend
            h.LegendVisible = true;
            % Title
            h.Title.String = getString(message('Control:tuning:strWeightedGain1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            % Plot bounds
            addBoundResponse(h,Bound,BoundType='upper',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotNormalizedBound')),...
                UseFrequencyFocus=true,UseMagnitudeFocus=false,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        end

        function GoalResponses = getGoalResponses(~,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.Bound = PlotHandle.Responses(1);
            else
                GoalResponses.Bound = PlotHandle.Responses(2);
            end
        end

        function DesignResponses = getDesignResponses(~,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.X = [];
            else
                DesignResponses.X = PlotHandle.Responses(1);
            end
        end

        function DesignResponses = getComparedResponses(~,CL,PlotHandle)        
            if isempty(CL)
                NDesigns = length(PlotHandle.Responses)-1;
            else
                NDesigns = length(PlotHandle.Responses)-2;
            end
            DesignResponses = repmat(struct('X',[]),NDesigns,1);
            for ii = 1:NDesigns
                DesignResponses(ii).X = PlotHandle.Responses(length(PlotHandle.Responses)-NDesigns+ii);
            end
        end

        function Ts = getTs(this,CL)
            [~,Ts,~] = viewSpecGoalData(this,CL);
        end

        function TU = getTU(this,CL)
            [~,~,TU] = viewSpecGoalData(this,CL);
        end

        % Update Goal waveforms
        function updateGoal(this,CL,PlotHandle)
            GoalResponses = getGoalResponses(this,CL,PlotHandle);
            % Compute data for goals
            [Bound,~,TU] = viewSpecGoalData(this,CL);
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update Bound
            GoalResponses.Bound.Model = Bound;
            GoalResponses.Bound.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strWeightedGain1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            X = viewSpecDesignData(this,CL);
            DesignResponses.X.SourceData.Model = X;
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            X = viewSpecDesignData(this,Design);
            % Add responses
            addResponse(PlotHandle,X,Name=Name,LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
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
            SPEC.Type = 1;
            SPEC.Stabilize = this.Stabilize;
            SPEC.Band = [this.Focus(1) , min(this.Focus(2),pi/Ts)];
            if diff(SPEC.Band)<=0
                error(message('Control:tuning:TuningReq15',getID(this)))
            end
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
            WL = getWeight(this,Ts,'WL'); %#ok<*PROPLC>
            if ~isempty(WL)
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
            WR = getWeight(this,Ts,'WR');
            if ~isempty(WR)
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
        end

    end

end