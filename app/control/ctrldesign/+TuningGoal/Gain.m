classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Gain < TuningGoal.BandLimited & TuningGoal.Unstable & ...
        TuningGoal.ScaledIO & TuningGoal.SystemLevel
    % Gain constraint for control system tuning.
    %
    %   R = TuningGoal.Gain(INPUTNAME,OUTPUTNAME,GAINVALUE) creates a tuning
    %   requirement R for limiting the gain of the closed-loop transfer
    %   function from inputs INPUTNAME to outputs OUTPUTNAME. The scalar
    %   GAINVALUE specifies the maximum gain across frequency (H-infinity norm).
    %   For vector signals, "gain" refers to the largest singular value of the
    %   transfer function (see SIGMA). For example,
    %      R = TuningGoal.Gain('du','u',2)
    %   specifies that the gain from "du" to "u" should not exceed the value 2.
    %
    %   R = TuningGoal.Gain(INPUTNAME,OUTPUTNAME,GAINPROFILE) creates a
    %   frequency-dependent gain constraint. The magnitude of the SISO transfer
    %   function GAINPROFILE specifies the maximum gain as a function of
    %   frequency. You can use an FRD model to sketch the desired gain profile
    %   with just a few frequency points. For example,
    %      gmax = frd([1 1 0.01],[0 1 100]);
    %      R = TuningGoal.Gain('du','u',gmax)
    %   limits the gain from "du" to "u" to 1 in the frequency range [0,1]
    %   and imposes a -20 dB/decade roll-off at frequencies greater than 1.
    %
    %   The strings or cell arrays of strings INPUTNAME and OUTPUTNAME specify
    %   the input and output signals by name. For MATLAB models, you can refer
    %   to the model inputs and outputs as well as any internal signal marked
    %   with an AnalysisPoint block. For Simulink models, you can refer to any
    %   Linear Analysis point marked in the model or specified with the addPoint
    %   method of the slTuner interface.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.Gain('du','u',1.5)
    %      R.Name = 'Max input sensitivity'
    %      R.Focus = [0 10]
    %      R.Openings = 'OuterLoop'
    %      R.Models = 2
    %   names the requirement, specifies that it should be evaluated in the
    %   frequency band [0,10] rad/s with the outer loop open, and that it
    %   only applies to the second plant model. For details on individual
    %   properties, type "help TuningGoal.Gain.<property name>".
    %
    %   Use VIEWSPEC(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Algorithm: This goal is turned into a normalized gain constraint
    %      || WF * H ||oo < 1
    %   on the closed-loop transfer function H from inputs to outputs.
    %   The frequency weighting function WF is derived from the specified
    %   max gain profile, see GETWEIGHT for details.
    %
    %   See also sigma, getPeakGain, AnalysisPoint, slTuner/addPoint,
    %   getPoints, evalGoal, viewGoal, getWeight, TuningGoal.WeightedGain,
    %   TuningGoal.LoopShape, TuningGoal, systune, looptune, slTuner.

    %   Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Maximum gain as a function of frequency (SISO ZPK model).
        %
        % This property specifies the maximum input/output gain as a function
        % of frequency. You can specify a smooth gain profile using a transfer
        % function or sketch a piecewise gain profile using an FRD model. Both
        % are mapped to a ZPK model whose magnitude reflects the desired gain
        % upper limit.
        MaxGain
    end

    methods

        % Constructor
        function this = Gain(InputName,OutputName,GainSpec)
            narginchk(3,3)
            try
                this.Input = InputName;
                this.Output = OutputName;
                this.MaxGain = GainSpec;
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
                    error(message('Control:tuning:GainReq2'))
                case 2
                    % Cannot compute ZPK form
                    error(message('Control:tuning:GainReq3'))
                case 3
                    % All zero profile
                    error(message('Control:tuning:GainReq4'))
            end
            this.MaxGain = Value;
        end

        function WF = getWeight(this,Ts)
            % GETWEIGHT  Computes weighting function WF.
            %
            %   The Gain goal is enforced as an H-infinity norm constraint
            %      || WF * H ||oo < 1
            %   on the closed-loop transfer function H from inputs to outputs.
            %   The frequency weighting function WF is derived from the
            %   specified max gain profile.
            %
            %   WF = getWeight(R,TS) returns the weighting function WF for
            %   the Gain goal R and tuning sample time TS. The gains of WF
            %   and 1/R.MaxGain roughly match inside the frequency band
            %   R.Focus. WF is always stable and proper. Because poles of WF
            %   close to s=0 or s=Inf can adversely impact the SYSTUNE solver,
            %   it is not recommended to specify max gain profiles with very
            %   low- or very high-frequency dynamics.
            %
            %   See also TuningGoal.Gain, getIOTransfer.
            WF = TuningGoal.resampleWeight(1/this.MaxGain,Ts);
            % Make weight stable and proper
            WF = TuningGoal.regularizeWeight2(WF,this.Focus,false);
        end


    end

    methods (Access = protected)

        function T = getClosedLoopTransfer_(this,CL,varargin)
            % Computes scaled closed-loop transfer from inputs to outputs
            T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            T = sminreal(getValue(T,varargin{:}));
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
            % NOTE: CL is a genss or slTuner object.
            T = getClosedLoopTransfer_(this,CL);
            WF = getWeight(this,T.Ts);
            WF.TimeUnit = T.TimeUnit;
            H = WF * T;
            if nargout>1
                fObj = getPeakGain(H,1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [MaxG,Bound,Ts,TU] = viewSpecGoalData(this,CL)
            MaxG = this.MaxGain;
            MaxG.Name = getString(message('Control:systunegui:TGPlotMaxGain'));
            if isequal(CL,[])
                Ts = MaxG.Ts;
                TU = MaxG.TimeUnit;
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
                MaxG.TimeUnit = TU;
            end
            wF = getWeight(this,Ts);
            wF.TimeUnit = TU;
            Bound = 1/wF;
        end

        % Compute data for Design wave forms
        function X = viewSpecDesignData(this,CL)
            X = getClosedLoopTransfer_(this,CL,'usample');
            X.Name = getString(message('Control:systunegui:TGPlotGain'));
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            plotHandle.XLimitsFocus = {TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts)};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [MaxG,Bound,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = sigmaplot(ax,MaxG);
                h.Responses(1).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(1).LineStyle = "--";
            else
                X = viewSpecDesignData(this,CL);
                h = sigmaplot(ax,X,MaxG);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                h.Responses(2).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(2).LineStyle = "--";
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Legend
            h.LegendVisible = true;
            % Title
            h.Title.String = getString(message('Control:tuning:strMaxGainReq1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            % Plot bounds
            addBoundResponse(h,Bound,BoundType='upper',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotEffectiveBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=false,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        end

        function GoalResponses = getGoalResponses(~,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.MaxG = PlotHandle.Responses(1);
                GoalResponses.Bound = PlotHandle.Responses(2);
            else
                GoalResponses.MaxG = PlotHandle.Responses(2);
                GoalResponses.Bound = PlotHandle.Responses(3);
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
                NDesigns = length(PlotHandle.Responses)-2;
            else
                NDesigns = length(PlotHandle.Responses)-3;
            end
            DesignResponses = repmat(struct('X',[]),NDesigns,1);
            for ii = 1:NDesigns
                DesignResponses(ii).X = PlotHandle.Responses(length(PlotHandle.Responses)-NDesigns+ii);
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
            [MaxG,Bound,~,TU] = viewSpecGoalData(this,CL);
            % Update max gain curve
            GoalResponses.MaxG.SourceData.Model = MaxG;
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update Bound
            GoalResponses.Bound.Model = Bound;
            GoalResponses.Bound.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strMaxGainReq1',this.Name));
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
            WF = getWeight(this,Ts);
            [aW,bW,cW,dW] = ssdata(WF);
            if ~(isempty(aW) && dW==1)
                pWF = eig(aW);
                if ny>1 && nu>1
                    [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,min(nu,ny));
                end
                if ny<=nu
                    SPEC.WL = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWF);
                else
                    SPEC.WR = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWF);
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

