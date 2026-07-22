classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Tracking < TuningGoal.BandLimited & TuningGoal.TrackIO & ...
        TuningGoal.SystemLevel
    % Reference tracking requirement for control system tuning.
    %
    %   R = TuningGoal.Tracking(INPUTNAME,OUTPUTNAME,MAXERROR) creates a tuning
    %   requirement R specifying tracking performance in the frequency domain.
    %   The output signal OUTPUTNAME must track the reference signal INPUTNAME,
    %   and the magnitude of the SISO transfer function MAXERROR specifies the
    %   maximum relative error as a function of frequency (gain from reference
    %   to tracking error). You can use an FRD model to sketch the desired error
    %   profile with just a few frequency points. For example,
    %      err = frd([0.01 0.01 1],[0 1 100]);
    %      R = TuningGoal.Tracking('theta_ref','theta',err)
    %   specifies a relative error of 0.01 (1%) in the frequency range [0,1]
    %   increasing to 1 (100%) at the frequency 100.
    %
    %   R = TuningGoal.Tracking(INPUTNAME,OUTPUTNAME,RESPTIME,DCERROR,PEAKERROR)
    %   specifies a first-order error profile MAXERROR with the following
    %   characteristics:
    %     * Response time RESPTIME (~ reciprocal of tracking bandwidth)
    %     * Maximum steady-state error DCERROR (default = 0.001 or 0.1%)
    %     * Peak error across frequency PEAKERROR (default = 1).
    %   For example,
    %      R = TuningGoal.Tracking('theta_ref','theta',2,0.01,1.1)
    %   specifies that the signal "theta" should track "theta_ref" with a response
    %   time of 2 (in the prevailing time units), steady-state error of 1%, and
    %   peak error of 1.1. Type "viewGoal(R)" to see the corresponding error
    %   profile.
    %
    %   The strings or cell arrays of strings INPUTNAME and OUTPUTNAME specify
    %   the input and output signals by name. For MATLAB models, you can refer
    %   to the model inputs and outputs as well as any internal signal marked
    %   with an AnalysisPoint block. For Simulink models, you can refer to any
    %   Linear Analysis point marked in the model or specified with the addPoint
    %   method of the slTuner interface.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.Tracking('r','u',5)
    %      R.Name = 'Tracking spec'
    %      R.Openings = 'OuterLoop'
    %      R.Models = [2 3]
    %   names the requirement, specifies that it should be evaluated with the
    %   outer loop open, and that it only applies to the second and third
    %   plant models. Type "help TuningGoal.Tracking.<property name>" for
    %   details on individual properties.
    %
    %   Use VIEWGOAL(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Algorithm: This goal is turned into a normalized gain constraint
    %      || WF * (T-eye(size(T))) ||oo < 1
    %   on the closed-loop transfer function T from reference to output.
    %   The frequency weighting function WF is derived from the specified
    %   max error profile, see GETWEIGHT for details.
    %
    %   See also AnalysisPoint, slTuner/addPoint, getPoints, evalGoal, viewGoal,
    %   getWeight, TuningGoal.StepTracking, TuningGoal.Overshoot, TuningGoal.Gain,
    %   TuningGoal.LoopShape, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    % Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Maximum error as a function of frequency (SISO ZPK model).
        %
        % This property specifies the maximum tracking error as a function of
        % frequency (maximum gain from reference signal to tracking error
        % signal). You can specify a smooth error profile using a transfer
        % function or sketch a piecewise error profile using an FRD model.
        % Both are mapped to a ZPK model whose magnitude reflects the desired
        % error profile.
        MaxError

        % REVISIT: Need to figure out best API for specifying decoupling goal
        % and derive appropriate scaling from it
        % Automatic I/O scaling (['on'|{'off'}]).
        %
        % For vector signals, poor scaling may artificially increase the amount
        % of cross-coupling between loops. Set AutoScaling = 'on' to automatically
        % rescale signals to minimize such coupling.
        % AutoScaling = 'off'
    end

    properties (Hidden, Dependent, Transient)
        % Renamed in R2013b
        ReferenceInput
        TrackingOutput
    end

    methods

        % Constructor
        function this = Tracking(InputName,OutputName,varargin)
            ni = nargin;
            narginchk(3,5)
            try
                this.Input = InputName;
                this.Output = OutputName;
                if isnumeric(varargin{1})
                    % Implicit specification in the time domain
                    RT = varargin{1};
                    if ~(isscalar(RT) && isreal(RT) && RT>0 && RT<Inf)
                        error(message('Control:tuning:TrackingReq3'))
                    end
                    if ni>3
                        DCError = varargin{2};
                        if ~(isnumeric(DCError) && isscalar(DCError) && ...
                                isreal(DCError) && DCError>=0 && DCError<1)
                            error(message('Control:tuning:TrackingReq4'))
                        end
                    else
                        DCError = 1e-3;  % default
                    end
                    if ni>4
                        PeakError = varargin{3};
                        if ~(isnumeric(PeakError) && isscalar(PeakError) && ...
                                isreal(PeakError) && PeakError>=1 && PeakError<Inf)
                            error(message('Control:tuning:TrackingReq9'))
                        end
                    else
                        PeakError = 1;
                    end
                    % Build default error profile
                    wc = 2.0/RT;  % consistent with PIDTOOL
                    this.MaxError = tf([PeakError wc*DCError],[1 wc]);
                else
                    % Frequency-domain specification
                    this.MaxError = varargin{1};
                end
            catch ME
                throw(ME)
            end
        end

        function this = set.MaxError(this,Value)
            % SET function for MaxError
            [Value,errCode] = TuningGoal.checkMagProfile(Value);
            switch errCode
                case 1
                    % Not scalar or SISO value
                    error(message('Control:tuning:TrackingReq2'))
                case 2
                    % Cannot compute ZPK form
                    error(message('Control:tuning:TrackingReq6'))
                case 3
                    % All zero profile
                    error(message('Control:tuning:TrackingReq8'))
            end
            this.MaxError = Value;
        end

        function [WF,wc] = getWeight(this,Ts)
            % GETWEIGHT  Computes weighting function WF.
            %
            %   The Tracking goal is enforced as an H-infinity norm constraint
            %      || WF * (T-eye(size(T))) ||oo < 1
            %   on the closed-loop transfer function T from reference to
            %   output. The frequency weighting function WF is derived from
            %   the specified max error profile.
            %
            %   WF = getWeight(R,TS) returns the weighting function WF for
            %   the Tracking goal R and tuning sample time TS. The gains
            %   of WF and 1/R.MaxError roughly match for gain values
            %   ranging from -20 dB to +60 dB. For numerical reasons, WF
            %   levels off outside this range unless the specified error
            %   profile changes slope outside this range. Because poles of WF
            %   close to s=0 or s=Inf can adversely impact the SYSTUNE solver,
            %   it is not recommended to specify error profiles with very
            %   low- or very high-frequency dynamics.
            %
            %   See also TuningGoal.Tracking, getIOTransfer.
            WF = TuningGoal.resampleWeight(1/this.MaxError,Ts);
            % Well-posedness
            if getPeakGain(WF,1e-2)<1.01
                % Allow error bounds |S|<alpha with alpha>1.
                % No regularization here since |WF| is bounded
                wc = [];
            else
                beta = abs(freqresp(WF,pi/Ts));
                if beta>1e8
                    % Max error is zero at infinity
                    error(message('Control:tuning:TrackingReq1'))
                end
                % Find crossovers (possibly 0) and regularize weight
                wc = getGainCrossover(WF,max(1,1.25*beta));
            end
            WF = TuningGoal.regularizeWeight1(WF,wc,this.Focus);
        end

        % Obsolete properties
        function Value = get.ReferenceInput(this)
            Value = this.Input;
        end
        function Value = get.TrackingOutput(this)
            Value = this.Output;
        end
        function this = set.ReferenceInput(this,Value)
            this.Input = Value;
        end
        function this = set.TrackingOutput(this,Value)
            this.Output = Value;
        end

    end

    methods (Access = protected)

        function S = getClosedLoopTransfer_(this,CL,varargin)
            % Computes scaled closed-loop transfer from r to e=y-r
            T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            T = sminreal(getValue(T,varargin{:}));
            [ny,nr] = iosize(T);
            if ny~=nr
                error(message('Control:tuning:TuningReq14',getID(this),nr,ny))
            end
            S = T - eye(ny);
            % Add scaling
            DS = this.InputScaling;
            if ~isempty(DS)
                DS = checkInputScaling(this,DS,nr); % may error
                S = diag(1./DS) * S * diag(DS);
            end
        end

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            S = getClosedLoopTransfer_(this,CL);
            WF = getWeight(this,S.Ts);
            WF.TimeUnit = S.TimeUnit;
            H = WF * S;
            if nargout>1
                fObj = getPeakGain(H,1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [MaxErr,Bound,Ts,TU] = viewSpecGoalData(this,CL)
            MaxErr = this.MaxError;
            MaxErr.Name = getString(message('Control:systunegui:TGPlotMaxError'));
            if isequal(CL,[])
                Ts = MaxErr.Ts;
                TU = MaxErr.TimeUnit;
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
                MaxErr.TimeUnit = TU;
            end
            wF = getWeight(this,Ts);
            wF.TimeUnit = TU;
            Bound = 1/wF;
        end

        % Compute data for Design wave forms
        function X = viewSpecDesignData(this,CL)
            X = getClosedLoopTransfer_(this,CL,'usample');
            X.Name = getString(message('Control:systunegui:TGPlotTrackingError'));
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,~)
            [~,wc] = getWeight(this,Ts);
            plotHandle.XLimitsFocus = {TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts,wc)};
            updateSingularValueFocus(plotHandle);
            YUnits = char(plotHandle.MagnitudeUnit);
            Ylim = plotHandle.YLimitsFocus{1};
            Ylim(1) = min(max(Ylim(1),unitconv(0.001,'abs',YUnits)),unitconv(0.1,'abs',YUnits));
            Ylim(2) = max(min(Ylim(2),unitconv(10,'abs',YUnits)),unitconv(1.5,'abs',YUnits));
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [MaxErr,Bound,~,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = sigmaplot(ax,MaxErr);
                h.Responses(1).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(1).LineStyle = "--";
            else
                X = viewSpecDesignData(this,CL);
                h = sigmaplot(ax,X,MaxErr);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                h.Responses(2).SemanticColor = "--mw-graphics-colorNeutral-line-secondary";
                h.Responses(2).LineStyle = "--";
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Legend
            h.LegendLocation = "southeast";
            h.LegendVisible = true;
            % Scale, title, labels, grid
            h.Title.String = getString(message('Control:tuning:strTrackingReq1',this.Name));
            h.Title.Interpreter = 'none';
            h.YLabel.String = getString(message('Control:systunegui:TGPlotTrackingYLabel'));
            h.AxesStyle.GridVisible = true;
            h.MagnitudeUnit = "abs";
            h.MagnitudeScale = "log";
            % Plot bounds
            addBoundResponse(h,Bound,BoundType='upper',...
                Focus=this.Focus * funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotEffectiveBound')),...
                UseFrequencyFocus=false,UseMagnitudeFocus=true,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        end

        function GoalResponses = getGoalResponses(~,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.MaxErr = PlotHandle.Responses(1);
                GoalResponses.Bound = PlotHandle.Responses(2);
            else
                GoalResponses.MaxErr = PlotHandle.Responses(2);
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
            [MaxErr,Bound,~,TU] = viewSpecGoalData(this,CL);
            % Update plotted goals
            GoalResponses.MaxErr.SourceData.Model = MaxErr;
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update Bound
            GoalResponses.Bound.Model = Bound;
            GoalResponses.Bound.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strTrackingReq1',this.Name));
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
            addResponse(PlotHandle,X,Name=[getString(message('Control:systunegui:TGPlotTrackingError')) ': ' Name],LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
        end

    end

    methods (Hidden)

        function validateGoal(this,CL)
            % Goal validation for GUI
            T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            [ny,nu] = size(T);
            if ny~=nu
                error(message('Control:systunegui:IOMismatch',nu,ny))
            end
            DS = this.InputScaling;
            if ~(isempty(DS) || numel(DS)==nu)
                error(message('Control:systunegui:RefScaling'))
            end
            getWeight(this,T.Ts);
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
            % Builds standardized requirement description for SYSTUNE
            if isempty(this.Input) || isempty(this.Output)
                error(message('Control:tuning:TuningReq17',getID(this)))
            end
            SPEC.Type = 1;
            SPEC.Band = [this.Focus(1) , min(this.Focus(2),pi/Ts)];
            if diff(SPEC.Band)<=0
                error(message('Control:tuning:TuningReq15',getID(this)))
            end
            % Locate inputs
            InputNames = [uNames;sNames];
            [indU,MisMatch] = ltipack.resolveSignalID(this.Input,InputNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq11',MisMatch,InputNames))
            % Locate outputs
            OutputNames = [yNames;sNames];
            [indY,MisMatch] = ltipack.resolveSignalID(this.Output,OutputNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq12',MisMatch,OutputNames))
            nu = numel(indU);
            ny = numel(indY);
            if nu~=ny
                error(message('Control:tuning:TuningReq14',getID(this),nu,ny))
            end
            SPEC.Input = indU;
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
            WF = getWeight(this,Ts);
            [aW,bW,cW,dW] = ssdata(WF);
            pWF = eig(aW);
            if ny>1
                [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,ny);
            end
            SPEC.WL = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWF);
            % Transform T -> E+F*T*G = T-I
            DS = this.InputScaling;
            if isempty(DS)
                F = 1;  G = 1;
            else
                DS = checkInputScaling(this,DS,nu); % may error
                F = diag(1./DS);  G = diag(DS);
            end
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',-eye(ny),'Poles',[]),'F',F,'G',G,'h',[]);
        end

    end

end
