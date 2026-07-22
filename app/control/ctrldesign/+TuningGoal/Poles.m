classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Poles < TuningGoal.BandLimited & TuningGoal.GenericLoop & ...
        TuningGoal.SystemLevel
    % Constraint on closed-loop dynamics.
    %
    %   R = TuningGoal.Poles(MINDECAY,MINDAMPING,MAXFREQ) creates a tuning
    %   requirement R for constraining the closed-loop system dynamics. The
    %   scalars MINDECAY, MINDAMPING, and MAXFREQ specify the minimum decay
    %   rate, minimum damping, and maximum natural frequency for the
    %   closed-loop poles. Set MINDECAY=0, MINDAMPING=0, or MAXFREQ=Inf to
    %   skip any of these three constraints. You can use this requirement to
    %   increase damping and prevent slow or fast dynamics.
    %
    %   Use the "Openings" property of R to open some feedback loops and
    %   constrain the dynamics of the corresponding open-loop configuration.
    %   For example, for a control system with cascaded loops,
    %      R = TuningGoal.Poles(0,0.3,Inf)
    %      R.Openings = 'OuterLoop'
    %   requires that the system remain stable with a minimum damping of 0.3
    %   when the outer loop is open. In MATLAB, use an AnalysisPoint block
    %   to mark the loop opening location 'OuterLoop'. In Simulink, use a
    %   Linear Analysis point or the addPoint method of the slTuner interface
    %   to mark this location.
    %
    %   R = TuningGoal.Poles(LOC,MINDECAY,MINDAMPING,MAXFREQ) constrains the
    %   poles of the sensitivity function measured at the location LOC (see
    %   TuningGoal.Sensitivity for details). Use this syntax to narrow the
    %   scope of the requirement to a particular feedback loop. For the
    %   cascaded loop example above,
    %      R = TuningGoal.Poles('InnerLoop',0,0.5,50))
    %      R.Openings = 'OuterLoop'
    %   constrains the inner-loop dynamics when the outer loop is open. The
    %   dynamics of blocks that do not participate to the inner loop are
    %   ignored. The location 'InnerLoop' can be anywhere along the inner
    %   loop.
    %
    %   Use VIEWSPEC(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Note: This requirement implicitly enforces closed-loop stability for
    %   the specified Openings configuration.
    %
    %   See also pole, evalGoal, viewGoal, AnalysisPoint, getPoints,
    %   TuningGoal.ControllerPoles, TuningGoal.Margins, systune, looptune,
    %   slTuner.

    % Author: P. Gahinet
    % Copyright 2009-2016 The MathWorks, Inc.

    % Note: For the default settings, this requirement contributes nothing
    % to f(x) or g(x) but still enforces stability of the closed-loop
    % configuration specified by Openings. In other words, this requirement
    % always contributes to the fStab term.

    properties
        % Minimum decay rate of closed-loop poles (default = 0).
        %
        % The closed-loop poles must satisfy
        %       Re(s) < -alpha       (continuous)
        %    log(|z|) < -alpha*Ts    (discrete)
        % where alpha is the specified minimum decay rate (a nonnegative value).
        % This constraint only applies to poles with natural frequencies in the
        % range specified by the "Focus" property.
        MinDecay = 0;

        % Minimum damping of closed-loop poles (default = 0).
        %
        % The closed-loop poles must satisfy
        %    Re(s) < -zeta * |s|
        % where zeta is the specified minimum damping ratio (a value between 0
        % and 1). This constraint only applies to poles with natural frequencies
        % in the range specified by the "Focus" property. In discrete time, the
        % damping ratio is computed using s=log(z)/Ts.
        MinDamping = 0;

        % Maximum natural frequency of closed-loop poles (default = Inf).
        %
        % The closed-loop poles must satisfy
        %         |s| < rho       (continuous)
        %    |log(z)| < rho*Ts    (discrete)
        % where rho is the specified maximum natural frequency (also known
        % as the spectral radius). This is useful to prevent fast closed-loop
        % dynamics. This constraint only applies to poles with natural
        % frequencies in the range specified by the "Focus" property.
        MaxFrequency = Inf;
    end

    methods

        function this = Poles(varargin)
            narginchk(0,4)
            ni = nargin;
            if ni>0 && isnumeric(varargin{1})
                % Set LOCATION=0x1 cell
                varargin = [{cell(0,1)},varargin];  ni = ni+1;
            end
            try
                if ni>0
                    this.Location = varargin{1};
                end
                if ni>1
                    this.MinDecay = varargin{2};
                end
                if ni>2
                    this.MinDamping = varargin{3};
                end
                if ni>3
                    this.MaxFrequency = varargin{4};
                end
            catch ME
                throw(ME)
            end
        end

        function this = set.MinDecay(this,Value)
            % SET function for MinDecay
            if ~(isnumeric(Value) && isscalar(Value) && ...
                    isreal(Value) && isfinite(Value) && Value>=0)
                error(message('Control:tuning:PoleReq1'))
            end
            this.MinDecay = double(Value);
        end

        function this = set.MinDamping(this,Value)
            % SET function for MinDamping
            if ~(isnumeric(Value) && isscalar(Value) && ...
                    isreal(Value) && isfinite(Value) && Value>=0 && Value<=1)
                error(message('Control:tuning:PoleReq5'))
            end
            this.MinDamping = double(Value);
        end

        function this = set.MaxFrequency(this,Value)
            % SET function for MaxFrequency
            if ~(isnumeric(Value) && isscalar(Value) && ...
                    isreal(Value) && Value>0)
                error(message('Control:tuning:PoleReq2'))
            end
            this.MaxFrequency = double(Value);
        end

    end

    methods (Access = protected)

        function H = getClosedLoopTransfer_(this,CL,varargin)
            % Computes closed-loop transfer from inputs to outputs.
            if isempty(this.Location)
                % Return model(s) with no I/Os and same dynamics as closed loop
                % Note: Same as getDynamics, but supports uncertainty sampling
                CL = genss(CL); % slTuner does not handle empty I/Os
                H = getIOTransfer(CL,cell(0,1),cell(0,1),this.Openings,this.Models);
                H = getValue(H,varargin{:});
            else
                H = getSensitivity(CL,this.Location,this.Openings,this.Models);
                H = sminreal(getValue(H,varargin{:}));
            end
        end


        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            % Note: Requirement is normalized so that in the fObj range [0.25,4],
            % a violation of x% (fObj=1+0.01*x) corresponds to a x% violation
            % of the spectral requirement.
            H = getClosedLoopTransfer_(this,CL);
            if nargout>1
                Focus = this.Focus;
                sH = size(H);
                fObj = NaN([sH(3:end) 1 1]);
                Ts = abs(H.Ts);
                MINDECAY = 1e-7;
                WarnFlag = false;
                FiniteFlag = isfinite(H,'elem');
                for ct=1:numel(fObj)
                    if FiniteFlag(ct)
                        E = pole(H,ct);
                        if Ts>0
                            E = log(E(E~=0))/Ts;
                        end
                        absE = abs(E);
                        WarnFlag = WarnFlag || any(absE>=Focus(1) & absE<MINDECAY);
                        inFocus = (absE>=max(Focus(1),MINDECAY) & absE<=Focus(2));
                        if any(inFocus)
                            absE = absE(inFocus);
                            fSpec = zeros(1,3);
                            if this.MinDecay>0
                                fSpec(1) = NSOptUtil.SpectralPenalty(...
                                    min(-real(E(inFocus)))/this.MinDecay);
                            end
                            if this.MinDamping>0
                                fSpec(2) = NSOptUtil.SpectralPenalty(...
                                    min(-real(E(inFocus))./absE)/this.MinDamping);
                            end
                            fSpec(3) = max(absE)/this.MaxFrequency;
                            fObj(ct) = max(fSpec);
                        else
                            fObj(ct) = 0;
                        end
                    end
                end
                if WarnFlag
                    % Warn that quasi-integrators are ignored when computing FOBJ
                    % (for consistency with the way SYSTUNE ignored fixed integrators)
                    warning(message('Control:tuning:PoleReq6'))
                end
            end
        end

        function delta = getViewExtent_(this)
            % Compute extent for view
            delta = 8;
            if this.MaxFrequency<Inf
                delta = max(delta,1.1*this.MaxFrequency);
            end
            alpha = this.MinDecay;
            if alpha>0
                delta = max(delta,alpha);
                if this.MinDamping>1e-2
                    delta = max(delta,2*alpha*sqrt(1/this.MinDamping^2-1));
                end
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [Ts,TU] = viewSpecGoalData(~,CL)
            if isequal(CL,[])
                Ts = 0;
                TU = 'seconds';
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
            end
        end

        % Compute data for Design wave forms
        function Hp = viewSpecDesignData(this,CL)
            H = getClosedLoopTransfer_(this,CL,'usample');
            nsys = nmodels(H);  % array support
            Hp = zpk(ones(1,1,nsys),'Ts',H.Ts,'TimeUnit',H.TimeUnit);
            for ct=1:nsys
                p = pole(H,ct);
                wn = damp(p,H.Ts);
                p = p(wn>=this.Focus(1) & wn<=this.Focus(2));
                Hp(:,:,ct).p = p;
            end
            Hp.Name = getString(message('Control:systunegui:TGPlotPoles'));
        end

        % Update limits
        function updateLimits(~,Ts,plotHandle,XLimitsFocus,YLimitsFocus)
            % Pick square Y limits that will show constraints if nearly active
            Xlim = XLimitsFocus{1};
            Ylim = YLimitsFocus{1};
            if Ts==0
                xc = (Xlim(1)+Xlim(2))/2;
                delta = max(Xlim(2)-Xlim(1),Ylim(2)-Ylim(1));
                Xlim = [xc-delta,xc+delta];
                Ylim = [-delta,delta];
            else
                xc = 0;
                delta = max([2 Xlim(2)-Xlim(1) Ylim(2)-Ylim(1)]);
                Xlim = [xc-0.6*delta,xc+0.6*delta];
                Ylim = 0.6*[-delta,delta];
            end
            plotHandle.XLimitsFocus = {Xlim};
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [Ts,TU] = viewSpecGoalData(this,CL);
            if isequal(CL,[])
                % Just show bounds and target shape
                h = controllib.chart.internal.utils.ltiplot("pzmap",ax);
                delta = getViewExtent_(this);
                xc = -0.75*delta;
                h.XLimits = [xc-delta,xc+delta];
                h.YLimits = {[-delta,delta]};
            else
                Hp = viewSpecDesignData(this,CL);
                h = pzplot(ax,Hp);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Title
            h.Title.String = getString(message('Control:tuning:strPole1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            % Plot bounds
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            addBoundResponse(h,MinDecay=tau*this.MinDecay,MinDamping=this.MinDamping,...
                MaxFrequency=tau*this.MaxFrequency,Ts=Ts,...
                Name=getString(message('Control:systunegui:TGPlotBounds')),...
                FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        end

        function GoalResponses = getGoalResponses(~,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.Bounds = PlotHandle.Responses(1);
            else
                GoalResponses.Bounds = PlotHandle.Responses(2);
            end
        end

        function DesignResponses = getDesignResponses(~,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.Hp = [];
            else
                DesignResponses.Hp = PlotHandle.Responses(1);
            end
        end

        function DesignResponses = getComparedResponses(~,CL,PlotHandle)
            if isempty(CL)
                NDesigns = length(PlotHandle.Responses)-1;
            else
                NDesigns = length(PlotHandle.Responses)-2;
            end
            DesignResponses = repmat(struct('Hp',[]),NDesigns,1);
            for ii = 1:NDesigns
                DesignResponses(ii).Hp = PlotHandle.Responses(length(PlotHandle.Responses)-NDesigns+ii);
            end
        end

        function Ts = getTs(this,CL)
            [Ts,~] = viewSpecGoalData(this,CL);
        end

        function TU = getTU(this,CL)
            [~,TU] = viewSpecGoalData(this,CL);
        end

        % Update Goal waveforms
        function updateGoal(this,CL,PlotHandle)
            GoalResponses = getGoalResponses(this,CL,PlotHandle);
            % Compute data for goals
            [~,TU] = viewSpecGoalData(this,CL);
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            % Update plotted goals
            GoalResponses.Bounds.MaxFrequency = tau*this.MaxFrequency;
            GoalResponses.Bounds.MinDecay = tau*this.MinDecay;
            GoalResponses.Bounds.MinDamping = this.MinDamping;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strPole1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            Hp = viewSpecDesignData(this,CL);
            DesignResponses.Hp.SourceData.Model = Hp;
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,Color)
            % Compute data for design
            Hp = viewSpecDesignData(this,Design);
            name = sprintf('%s: %s',getString(message('Control:systunegui:TGPlotPoles')),Name);
            % Add response
            addResponse(PlotHandle,Hp,Name=name,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = Color;
        end

        function Type = getComparisonStyleType(~)
            Type = 'Color';
        end

    end

    methods (Hidden)

        function validateGoal(this,CL)
            % Note: Needed to validate Models selection
            if this.MinDecay>=this.MaxFrequency
                error(message('Control:systunegui:PoleMinMax'))
            end
            if isempty(this.Location)
                getDynamics(CL,this.Openings,this.Models);
            else
                getSensitivity(CL,this.Location,this.Openings,this.Models);
            end
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,~)
            % Builds standardized requirement description for SYSTUNE
            if this.MinDecay>=this.MaxFrequency
                error(message('Control:tuning:PoleReq3',getID(this)))
            end
            SPEC.Type = 0;
            SPEC.Band = this.Focus;
            SPEC.Spectral = struct(...
                'MinDecay',this.MinDecay,...
                'MinDamping',this.MinDamping,...
                'MaxFrequency',this.MaxFrequency);
            if ~isempty(this.Location)
                % Locate channels where sensitivity is measured
                [iLoop,MisMatch] = ltipack.resolveSignalID(this.Location,sNames,true);
                error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
                SPEC.Input = numel(uNames) + iLoop;
                SPEC.Output = numel(yNames) + iLoop;
            end
            % Locate openings
            if isempty(this.Openings)
                iOpen = [];
            else
                [iOpen,MisMatch] = ltipack.resolveSignalID(this.Openings,sNames,true);
                error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
            end
            [SPEC.Config,LoopConfigs] = ...
                TuningGoal.SystemLevel.getSwitchConfig(iOpen,LoopConfigs);
        end

    end

end
