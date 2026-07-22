classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Overshoot < TuningGoal.TrackIO & TuningGoal.SystemLevel
    % Overshoot constraint for control system tuning.
    %
    %   R = TuningGoal.Overshoot(INPUTS,OUTPUTS,MAXPERCENT) creates a tuning
    %   requirement R for limiting the overshoot in the step response from
    %   INPUTS to OUTPUTS. The signal names INPUTS and OUTPUTS can be strings
    %   or cell arrays of strings for vector-valued signals. The scalar
    %   MAXPERCENT specifies the maximum overshoot in percents. For example,
    %      R = TuningGoal.Overshoot('r','y',10)
    %   specifies that the overshoot in the step response from "r" to "y"
    %   should not exceed 10%.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.Overshoot('r','y',10)
    %      R.Name = 'Overshoot spec'
    %      R.Openings = 'OuterLoop'
    %      R.Models = 2
    %   names the requirement and specifies that it should be evaluated with
    %   the outer loop open and applies only to the second plant model. For
    %   details on properties, type "help TuningGoal.Overshoot.<property name>".
    %
    %   Use VIEWGOAL(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   Note: Overshoot constraints are mapped to peak gain constraints
    %   based on second-order system characteristics. This mapping is only
    %   approximate for higher-order systems. In addition, this requirement
    %   cannot reliably reduce the overshoot below 5%.
    %
    %   See also evalGoal, viewGoal, TuningGoal.Gain, TuningGoal.Sensitivity,
    %   TuningGoal, systune, looptune, slTuner.

    %   Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Maximum overshoot in percents (scalar).
        %
        % This property specifies the maximum overshoot in percents. For
        % example, the scalar 10 means the overshoot should not exceed 10%.
        % The requirement works best for target values of 5% and above.
        MaxOvershoot
    end

    methods

        % Constructor
        function this = Overshoot(InputName,OutputName,MaxPercent)
            narginchk(3,3)
            try
                this.Input = InputName;
                this.Output = OutputName;
                this.MaxOvershoot = MaxPercent;
            catch ME
                throw(ME)
            end
        end

        function this = set.MaxOvershoot(this,Value)
            % SET function for MaxOvershoot
            % Note: Choice of objective function effectively restricts MaxOvershoot
            %       to the interval [0.05,0.95]
            if ~(isnumeric(Value) && isreal(Value) && isscalar(Value) && Value>=0)
                error(message('Control:tuning:OvershootReq1'))
            end
            this.MaxOvershoot = double(Value);
        end

    end

    methods (Access = protected)

        function T = getClosedLoopTransfer_(this,CL,varargin)
            % Computes scaled closed-loop transfer from inputs to outputs
            T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            T = sminreal(getValue(T,varargin{:}));
            [ny,nr] = iosize(T);
            if ny~=nr
                error(message('Control:tuning:TuningReq14',getID(this),nr,ny))
            end
            % Add scaling
            DS = this.InputScaling;
            if ~isempty(DS)
                DS = checkInputScaling(this,DS,nr);
                T = diag(1./DS) * T * diag(DS);
            end
        end

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            H = getClosedLoopTransfer_(this,CL);
            if nargout>1
                [nu0,tau0] = TuningGoal.Overshoot.SecondOrderTargets(this.MaxOvershoot);
                tau = getPeakGain(H,1e-6);  % actual ||T||
                fObj = zeros(size(tau));
                for ct=1:numel(tau)
                    fObj(ct) = TuningGoal.Overshoot.PG2F(tau(ct),0,tau0,nu0);
                end
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [Bound,Ts,TU] = viewSpecGoalData(this,CL)
            [~,tau0] = TuningGoal.Overshoot.SecondOrderTargets(this.MaxOvershoot);
            if isequal(CL,[])
                Ts = 0;
                TU = 'seconds';
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
            end
            Bound = zpk(tau0,'Ts',Ts,'TimeUnit',TU);
        end

        % Compute data for Design wave forms
        function X = viewSpecDesignData(this,CL)
            X = getClosedLoopTransfer_(this,CL,'usample');
            X.Name = getString(message('Control:systunegui:TGPlotCurrentValue'));
        end

        % Update limits
        function updateLimits(this,~,plotHandle,~,~)
            [~,tau0] = TuningGoal.Overshoot.SecondOrderTargets(this.MaxOvershoot);
            tau = localGetPeakGain(plotHandle.Responses(1));
            YUnits = char(plotHandle.MagnitudeUnit);
            updateSingularValueFocus(plotHandle);
            Ylim = plotHandle.YLimitsFocus{1};
            Ylim(1) = unitconv(-20,'dB',YUnits);
            Ylim(2) = max(min(Ylim(2),unitconv(mag2db(1.5*tau),'dB',YUnits)),unitconv(mag2db(2*tau0),'dB',YUnits));
            plotHandle.YLimitsFocus = {Ylim};
            ax = getChartAxes(plotHandle);
            ht = findobj(ax,'Tag','OSstring');
            setTextPosition(ax,ht);
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [Bound,~,~] = viewSpecGoalData(this,CL);
            % Graphical validation of requirement
            if isequal(CL,[])
                % Just show bounds and target shape
                h = controllib.chart.internal.utils.ltiplot("sigma",ax);
            else
                X = viewSpecDesignData(this,CL);
                h = sigmaplot(ax,X);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                h.Responses(1).UseMaximumSingularValue = true;
                % Add text
                tau = localGetPeakGain(h.Responses(1));
                str = localGetText(tau,this.MaxOvershoot);
                view = qeGetView(h);
                ht = text(ax,0,0,str,FontSize=view.Style.Axes.FontSize,...
                    Units='pixels',HorizontalAlignment='right',Tag='OSstring');
                setTextPosition(ax,ht);
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Title
            h.Title.String = getString(message('Control:tuning:strOvershootReq1',this.Name));
            h.Title.Interpreter = 'none';
            h.YLabel.String = getString(message('Control:systunegui:TGPlotOvershootYLabel'));
            h.AxesStyle.GridVisible = true;
            % Plot bounds
            addBoundResponse(h,Bound,BoundType='upper',...
                Focus=[0 Inf],...
                Name=getString(message('Control:systunegui:TGPlotMax')),...
                UseFrequencyFocus=true,UseMagnitudeFocus=false,FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        end

        function L = addLocalPlotListeners(~,CL,PlotHandle)
            if isempty(CL)
                L = [];
            else
                ax = getChartAxes(PlotHandle);
                ht = findobj(ax,'Tag','OSstring');
                if ~isempty(ht)
                    weakAx = matlab.lang.WeakReference(ax);
                    weakText = matlab.lang.WeakReference(ht);
                    L = addlistener(ancestor(PlotHandle,'figure'),...
                        'SizeChanged',@(x,y) setTextPosition(weakAx.Handle,weakText.Handle));
                end
            end
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
                DesignResponses.TextHandle = [];
            else
                DesignResponses.X = PlotHandle.Responses(1);
                ax = getChartAxes(PlotHandle);
                ht = findobj(ax,'Tag','OSstring');
                DesignResponses.TextHandle = ht;
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
            [Bound,~,~] = viewSpecGoalData(this,CL);
            % Update plotted goals
            GoalResponses.Bound.Model = Bound;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strOvershootReq1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL) %% REVISIT
            % Compute data for design
            X = viewSpecDesignData(this,CL);
            DesignResponses.X.SourceData.Model = X;
            DesignResponses.X.UseMaximumSingularValue = true;
            % Update text
            tau = localGetPeakGain(DesignResponses.X);
            % Update text
            if ~isempty(DesignResponses.TextHandle)
                str = localGetText(tau,this.MaxOvershoot);
                DesignResponses.TextHandle.String = str;
            end
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            X = viewSpecDesignData(this,Design);
            % Add responses
            addResponse(PlotHandle,X,Name=Name,LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
            PlotHandle.Responses(end).UseMaximumSingularValue = true;
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
                error(message('Control:systunegui:StepScaling'))
            end
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
            % Builds standardized requirement description for SYSTUNE
            if isempty(this.Input) || isempty(this.Output)
                error(message('Control:tuning:TuningReq17',getID(this)))
            end
            SPEC.Type = 1;
            SPEC.Band = [0,pi/Ts];
            % Locate inputs
            InputNames = [uNames;sNames];
            [indU,MisMatch] = ltipack.resolveSignalID(this.Input,InputNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq11',MisMatch,InputNames))
            % Locate outputs
            OutputNames = [yNames;sNames];
            [indY,MisMatch] = ltipack.resolveSignalID(this.Output,OutputNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq12',MisMatch,OutputNames))
            ny = numel(indY);
            nu = numel(indU);
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
            % Transform T -> E+F*T*G when using input scaling
            DS = this.InputScaling;
            if isempty(DS)
                F = 1;  G = 1;
            else
                DS = checkInputScaling(this,DS,nu); % may error
                F = diag(1./DS);  G = diag(DS);
            end
            % Note: Rectifying function ||T|| -> h(||T||)
            [nu0,tau0] = TuningGoal.Overshoot.SecondOrderTargets(this.MaxOvershoot);
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',zeros(ny),'Poles',[]),...
                'F',F,'G',G,'h',@(x,task) TuningGoal.Overshoot.PG2F(x,task,tau0,nu0));
        end

    end

    methods (Static)

        function [nu0,tau0] = SecondOrderTargets(OS)
            % Given the user-specified max percent overshoot OS, computes overshoot
            % target NU0 and corresponding peak gain TAU0 of T(s) based on second-order
            % characteristics. Note that NU0 always lies in [0.05,0.95] because for
            % a second-order system,
            %    * ||T||=1 for 0 < OS < 100*exp(-pi) ~= 5%
            %    * ||T||=Inf (zero damping) corresponds to 100% overshoot
            nu0 = max(0.05,min(0.95,OS/100));
            aux = -log(nu0)/pi;
            tau0 = (aux+1/aux)/2;
        end

        function y = PG2F(tau,task,tau0,nu0)
            % Evaluates the rectifying function f=h(tau), its derivative, and the
            % inverse function tau = h^-1(f) given the overshoot target nu0>exp(-pi)
            % and the corresponding value tau0>1 of tau=||T||. The objective f is the
            % ratio of the actual to desired overshoot. Note that h(tau0) = 1.

            % h(tau) = exp(s*(1/tau0-1/tau))            if tau<tau0
            %          exp(-pi/(tau+sqrt(tau^2-1))/nu0  otherwise
            switch task
                case 0
                    % Evaluate f=h(tau)
                    if tau<tau0
                        % Compute S to ensure smoothness at tau=tau0
                        aux1 = tau0^2;
                        aux2 = sqrt(aux1-1);  % sqrt(tau0^2-1)
                        s = pi*aux1/aux2/(tau0+aux2);
                        y = exp(s*(1/tau0-1/tau));
                    else
                        y = exp(-pi/(tau+sqrt(tau^2-1)))/nu0;
                    end
                case 1
                    % Evaluate h'(tau)
                    if tau<tau0
                        aux1 = tau0^2;
                        aux2 = sqrt(aux1-1);  % sqrt(tau0^2-1)
                        s = pi*aux1/aux2/(tau0+aux2);
                        y = exp(s*(1/tau0-1/tau)) * s/tau^2;
                    else
                        aux1 = sqrt(tau^2-1);
                        aux2 = tau+aux1;
                        y = (pi/nu0) * exp(-pi/aux2)/aux2/aux1;
                    end
                case -1
                    % Evaluate tau=h^-1(f)
                    f = tau;
                    if f<1
                        aux1 = tau0^2;
                        aux2 = sqrt(aux1-1);  % sqrt(tau0^2-1)
                        s = pi*aux1/aux2/(tau0+aux2);
                        y = 1/(1/tau0-log(f)/s);
                    else
                        aux = abs(log(min(1,nu0*f)))/pi;
                        y = 0.5*(aux+1/aux);
                    end
            end
        end

    end

end

function str = localGetText(tau,MaxOvershoot)
% Set text for plot
str = getString(message('Control:tuning:strOvershootReq2',...
    sprintf('%.3g',100*exp(-pi/(tau+sqrt(tau^2-1)))),... % note: tau>=1
    sprintf('%.3g',MaxOvershoot)));
end

function setTextPosition(ax,ht)
% Get limits
if ~isempty(ht)
    axPos = controllibutils.getPosition(ax,'pixels');
    % Update position in pixels
    xt = ht.Extent;
    ht.Position = [axPos(3)-10 axPos(4)-xt(4) 0];
end
end

function tau = localGetPeakGain(r)
% Keeps only max singular value and returns its peak value
tau = 1;
tau = max(tau,getMaximumValue(r));
end