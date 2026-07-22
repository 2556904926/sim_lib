classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        ControllerPoles < TuningGoal.Generic
    % Constraint on the controller dynamics.
    %
    %   R = TuningGoal.ControllerPoles(BLOCKID,MINDECAY,MINDAMPING,MAXFREQ)
    %   creates a tuning requirement R for the controller dynamics. The string
    %   BLOCKID designates one of the tuned blocks making up the controller
    %   (see tunableBlock). The scalars MINDECAY, MINDAMPING, and MAXFREQ
    %   specify the minimum decay rate, minimum damping, and maximum natural
    %   frequency for the poles of the designated block. You can use this
    %   requirement to ensure that the controller is stable (MINDECAY>=0)
    %   and free of fast or resonant dynamics.
    %
    %   Example: If the "Compensator" block is parameterized as a second-order
    %   transfer function using tunableTF, the requirement
    %      R = TuningGoal.ControllerPoles('Compensator',0.1,0,30)
    %   restricts its poles to the region:
    %      Re(s) < -0.1,    |s| < 30
    %
    %   Use VIEWSPEC(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Note: When MINDECAY>=0, this requirement enforces stability of the
    %   specified tuned block. You can set MINDECAY<0 to allow for unstable
    %   controllers. The MINDAMPING setting is ignored in such case.
    %
    %   See also pole, evalGoal, viewGoal, TuningGoal.Poles, TuningGoal.Margins,
    %   systune, looptune, slTuner.

    %   Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Block name (string).
        %
        % This property specifies the name of the control element to which
        % this requirement applies.
        Block

        % Minimum decay rate of controller poles (default = 0).
        %
        % Constrains all poles of the control element to satisfy
        %       Re(s) < -alpha       (continuous)
        %    log(|z|) < -alpha*Ts    (discrete)
        % where alpha is the specified value. Use a nonnegative value to
        % ensure that the controller dynamics are stable.
        MinDecay = 0;

        % Minimum damping of controller poles (default = 0).
        %
        % The closed-loop poles must satisfy
        %    Re(s) < -zeta * |s|
        % where zeta is the specified minimum damping ratio (a value between
        % 0 and 1). In discrete time, the damping ratio is computed using
        % s=log(z)/Ts. This setting is ignored when the controller is allowed
        % to be unstable (MinDecay<0).
        MinDamping = 0;

        % Maximum natural frequency of controller poles (default = Inf).
        %
        % Constrains all poles of the tuned element to satisfy
        %         |s| < rho       (continuous)
        %    |log(z)| < rho*Ts    (discrete)
        % where rho>0 is the specified value. This is useful to prevent fast
        % controller dynamics.
        MaxFrequency = Inf;
    end

    methods

        % Constructor
        function this = ControllerPoles(BlockName,varargin)
            narginchk(1,4)
            ni = nargin;
            try
                this.Block = BlockName;
                if ni>1
                    this.MinDecay = varargin{1};
                end
                if ni>2
                    this.MinDamping = varargin{2};
                end
                if ni>3
                    this.MaxFrequency = varargin{3};
                end
            catch ME
                throw(ME)
            end
        end

        function this = set.Block(this,Value)
            % SET function for Block
            if ~(ischar(Value) && isrow(Value))
                error(message('Control:tuning:ControllerPoleReq2'))
            end
            this.Block = Value;
        end

        function this = set.MinDecay(this,Value)
            % SET function for MinDecay
            try
                checkMinDecay(this,Value)
            catch ME
                throw(ME)
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

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            H = getBlockValue(CL,this.Block);
            if nargout>1
                E = pole(H);
                Ts = abs(H.Ts);
                if Ts>0
                    E = log(E(E~=0))/Ts;
                end
                % Ignore integrators to produce consistent results for PIDs
                E = E(abs(E)>1e-7);
                if isempty(E)
                    fObj = 0;
                else
                    MinDecay = this.MinDecay;
                    fSpec = zeros(1,3);
                    if MinDecay<0
                        fSpec(1) = max(real(E))/(-MinDecay);
                    else
                        if MinDecay>0
                            fSpec(1) = NSOptUtil.SpectralPenalty(...
                                min(-real(E))/MinDecay);
                        end
                        if this.MinDamping>0
                            fSpec(1) = NSOptUtil.SpectralPenalty(...
                                min(-real(E)./abs(E))/this.MinDamping);
                        end
                    end
                    fSpec(3) = max(abs(E))/this.MaxFrequency;
                    fObj = max(fSpec);
                end
            end
        end

        function delta = getViewExtent_(this)
            % Compute extent for view
            delta = 8;
            if this.MaxFrequency<Inf
                delta = max(delta,1.1*this.MaxFrequency);
            end
            if this.MinDecay>0
                delta = max(delta,this.MinDecay);
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
        function CPoles = viewSpecDesignData(this,CL)
            H = evalSpec_(this,CL);
            p = pole(H);
            CPoles = zpk([],p,1,'Ts',CL.Ts,'TimeUnit',CL.TimeUnit);
            CPoles.Name = getString(message('Control:systunegui:TGPlotPoles'));
        end

        % Update limits
        function updateLimits(~,Ts,plotHandle,XLimitsFocus,YLimitsFocus)
            % Pick square Y limits that will show constraints if nearly active
            view = qeGetView(plotHandle);
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
            view.XLimitsFocus = {Xlim};
            view.YLimitsFocus = {Ylim};
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
                CPoles = viewSpecDesignData(this,CL);
                h = pzplot(ax,CPoles);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Title
            h.Title.String = getString(message('Control:tuning:strStableBlock1',this.Name,this.Block));
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
                DesignResponses.CPoles = [];
            else
                DesignResponses.CPoles = PlotHandle.Responses(1);
            end
        end

        function DesignResponses = getComparedResponses(~,CL,PlotHandle)
            if isempty(CL)
                NDesigns = length(PlotHandle.Responses)-1;
            else
                NDesigns = length(PlotHandle.Responses)-2;
            end
            DesignResponses = repmat(struct('CPoles',[]),NDesigns,1);
            for ii = 1:NDesigns
                DesignResponses(ii).CPoles = PlotHandle.Responses(length(PlotHandle.Responses)-NDesigns+ii);
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
            PlotHandle.Title.String = getString(message('Control:tuning:strStableBlock1',this.Name,this.Block));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            CPoles = viewSpecDesignData(this,CL);
            % Update design
            DesignResponses.CPoles.SourceData.Model = CPoles;
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,Color)
            % Compute data for design
            CPoles = viewSpecDesignData(this,Design);
            name = sprintf('%s: %s',getString(message('Control:systunegui:TGPlotPoles')),Name);
            % Add response
            addResponse(PlotHandle,CPoles,Name=name,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = Color;
        end

        function Type = getComparisonStyleType(~)
            Type = 'Color';
        end

    end

    methods (Hidden)

        function validateGoal(this,~)
            if this.MinDecay>=this.MaxFrequency
                error(message('Control:systunegui:PoleMinMax'))
            end
        end

        function SPEC = getSpecData(this,SPEC,bNames)
            % Builds standardized requirement description for SYSTUNE.
            MinDecay = this.MinDecay; %#ok<*PROPLC>
            if MinDecay>=this.MaxFrequency
                error(message('Control:tuning:PoleReq3',getID(this)))
            end
            SPEC.Type = 0;
            SPEC.Band = [0,Inf];
            SPEC.Stabilize = (MinDecay>=0);
            SPEC.Spectral = struct('MinDecay',MinDecay,...
                'MinDamping',this.MinDamping,'MaxFrequency',this.MaxFrequency);
            % Identify block
            iB = localResolveName(this.Block,bNames);
            if ~isscalar(iB)
                error(message('Control:tuning:PoleReq4',getID(this),this.Block))
            end
            SPEC.Model = iB;
            SPEC.Config = 0;
        end

    end

    methods (Access = protected)

        function checkMinDecay(~,Value)
            % Overloaded by subclass
            if ~(isnumeric(Value) && isscalar(Value) && ...
                    isreal(Value) && Value<Inf)
                error(message('Control:tuning:ControllerPoleReq1'))
            end
        end

    end


end


function iB = localResolveName(BlockID,BlockNames)
% Resolve block identifier against list of block names

% Simulink identifiers may contain /, blanks, etc. Turn such identifiers
% into valid block names in the same way this is done in slTuner.
BlockID = ltipack.createVarName(BlockID);

% Now look for exact match
iB = find(ltipack.strcmpEnd(BlockID,BlockNames));
end

