classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        StepRejection < TuningGoal.ScaledIO & TuningGoal.SystemLevel
    % Step disturbance rejection requirement for control system tuning.
    %
    %   R = TuningGoal.StepRejection(INPUTNAME,OUTPUTNAME,REFSYS) specifies
    %   how a step disturbance at INPUTNAME should affect the output variable
    %   OUTPUTNAME. The goal is to reject the disturbance as well as or better
    %   than the reference model REFSYS. This model must be stable and have
    %   zero DC gain for perfect steady-state rejection of the disturbance.
    %   The signal names INPUTNAME and OUTPUTNAME can be strings or cell arrays
    %   of strings for vector-valued signals.
    %
    %   R = TuningGoal.StepRejection(INPUTNAME,OUTPUTNAME,PEAK,ST) specifies
    %   an oscillation-free response with peak value PEAK and settling time
    %   ST (in the prevailing time units). For example,
    %      R = TuningGoal.StepRejection('r','y',4,10)
    %   specifies that y(t) should not exceed 4 in absolute value and should
    %   settle in less than 10 time units.
    %
    %   R = TuningGoal.StepRejection(INPUTNAME,OUTPUTNAME,PEAK,ST,ZETA) allows
    %   for damped oscillations with a damping ratio of at least ZETA (a value
    %   between 0 and 1). Omitting ZETA is the same as setting ZETA=1.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.StepRejection('d','y',tf([1 0],[1 2 1]))
    %      R.Name = 'Step rejection'
    %      R.Openings = 'OuterLoop'
    %      R.Models = [2 3]
    %   names the requirement, specifies that it should be evaluated with the
    %   outer loop open, and that it only applies to the second and third plant
    %   models. Type "help TuningGoal.StepRejection.<property name>" for details
    %   on individual properties.
    %
    %   Use EVALSPEC(R) to evaluate this requirement and use SYSTUNE and related
    %   commands to tune the control system parameters subject to this and other
    %   requirements.
    %
    %   Note: For best results, the reference model and the open-loop response
    %   from disturbance to output should have similar gains at the frequency
    %   FMAX where the reference model gain peaks. To compute FMAX, use
    %      [gmax,fmax] = getPeakGain(R.ReferenceModel)
    %
    %   Algorithm: This goal is turned into a gain constraint
    %      || WF * Tdy || < 1
    %   on the closed-loop transfer function Tdy from disturbance to output.
    %   The frequency weighting function WF is derived from the specified
    %   reference model, see GETWEIGHT for details.
    %
    %   See also evalGoal, viewGoal, getWeight, TuningGoal.StepTracking,
    %   TuningGoal.Rejection, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    % Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Reference model (SISO ZPK model).
        %
        % The step response of this model specifies how the output variables
        % should respond to the step disturbance. The tuned closed-loop
        % system should reject the disturbance as well or better than the
        % reference model. For best results, use the open-loop gain near
        % the crossover frequency to calibrate the peak amplitude and peak
        % gain of the reference model.
        ReferenceModel
    end


    methods

        % Constructor
        function this = StepRejection(InputName,OutputName,varargin)
            ni = nargin;
            narginchk(3,5)
            try
                this.Input = InputName;
                this.Output = OutputName;
                if ni>3
                    ymax = varargin{1};
                    if ~(isnumeric(ymax) && isscalar(ymax) && isreal(ymax) && ymax>0 && ymax<Inf)
                        error(message('Control:tuning:StepRejection1'))
                    end
                    tSettle = varargin{2};
                    if ~(isnumeric(tSettle) && isscalar(tSettle) && isreal(tSettle) && tSettle>0 && tSettle<Inf)
                        error(message('Control:tuning:StepRejection2'))
                    end
                    if ni>4
                        zeta = varargin{3};
                        if ~(isnumeric(zeta) && isscalar(zeta) && isreal(zeta) && zeta>0 && zeta<=1)
                            error(message('Control:tuning:StepRejection3'))
                        end
                    else
                        zeta = 1;
                    end
                    % Compute target response
                    refsys = localComputeRef(ymax,zeta,tSettle);
                else
                    refsys = varargin{1};
                end
                this.ReferenceModel = refsys;
            catch ME
                throw(ME)
            end
        end

        function this = set.ReferenceModel(this,Value)
            % SET function for ReferenceModel
            % Note: Do not allow delays (shift time response but leave gain unchanged)
            if isa(Value,'DynamicSystem') && nmodels(Value)==1 && ~hasdelay(Value)
                % Convert to ZPK
                try
                    refsys = zpk(Value);
                catch ME
                    error(message('Control:tuning:ReferenceModel4'))
                end
                gmax = getPeakGain(refsys);
                % Validate
                if ~(issiso(refsys) && isstable(refsys) && refsys.k~=0)
                    error(message('Control:tuning:StepRejection4'))
                elseif ~isfinite(gmax) || abs(dcgain(refsys))>0.001*gmax
                    error(message('Control:tuning:StepRejection6'))
                elseif refsys.Ts==-1
                    error(message('Control:tuning:TuningReq19'))
                end
                this.ReferenceModel = refsys;
            else
                error(message('Control:tuning:ReferenceModel1'))
            end
        end

        function WF = getWeight(this,Ts)
            % GETWEIGHT  Computes weighting function WF.
            %
            %   The StepRejection goal is enforced as a gain constraint
            %      || WF * Tdy || < 1
            %   on the closed-loop transfer function Tdy from disturbance to
            %   output. The frequency weighting function WF is derived from
            %   the specified reference model.
            %
            %   WF = getWeight(R,TS) returns the weighting function WF for
            %   the StepRejection goal R and tuning sample time TS. The gains
            %   of 1/WF and R.ReferenceModel roughly match for gain values
            %   within 60 dB of the peak gain. For numerical reasons, WF
            %   levels off outside this range unless the specified reference
            %   model changes slope outside this range. Because poles of WF
            %   close to s=0 or s=Inf can adversely impact the SYSTUNE solver,
            %   it is not recommended to specify reference models with very
            %   low- or very high-frequency dynamics.
            %
            %   See also TuningGoal.StepRejection, getIOTransfer.
            Tref = TuningGoal.resampleWeight(this.ReferenceModel,Ts);
            % Build and regularize weight
            gc = 0.8*getPeakGain(Tref);
            wc = getGainCrossover(Tref,gc);
            WF = TuningGoal.regularizeWeight1(gc/Tref,wc,[0,Inf])/gc;
        end

    end

    methods (Access = protected)

        function T = getClosedLoopTransfer_(this,CL,varargin)
            % Computes scaled closed-loop transfer from r to y
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
            T = getClosedLoopTransfer_(this,CL);
            WF = getWeight(this,T.Ts);
            WF.TimeUnit = T.TimeUnit;
            H = WF * T;
            if nargout>1
                fObj = getPeakGain(H,1e-6);
            end
        end

    end

    methods (Hidden) %% Tuning Goal Plot API

        % Compute data
        function [T,Tref] = viewSpecHelper(this,CL)
            T = getClosedLoopTransfer_(this,CL,'usample');
            T.Name = getString(message('Control:systunegui:TGPlotActual'));
            [ny,nu] = iosize(T);
            Tref = this.ReferenceModel;
            Tref = repmat(ss(Tref),[ny nu]);
            Tref.Name = getString(message('Control:systunegui:TGPlotWorst'));
        end

        % Create plot
        function h = createPlot(this,CL,ax)
            % Graphical validation of requirement
            if isequal(CL,[])
                Tref = this.ReferenceModel;
                Tref.Name = getString(message('Control:systunegui:TGPlotWorst'));
                % Just plot step response of reference model
                h = stepplot(ax,Tref);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(7).SemanticName;
                h.Responses(1).LineStyle = "--";
            else
                [T,Tref] = viewSpecHelper(this,CL);
                h = stepplot(ax,T,Tref,-Tref,localGetSimHorizon(Tref));
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(7).SemanticName;
                h.Responses(2).LineStyle = "--";
                h.Responses(3).SemanticColor = controllib.plot.internal.utils.GraphicsColor(7).SemanticName; 
                h.Responses(3).LineStyle = "--";               
                % Remove -Tref from legend
                h.Responses(3).LegendDisplay = 'off';
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Legend
            h.LegendLocation = "southeast";
            h.LegendVisible = true;
            % Scale, title, labels, grid
            h.Title.String = getString(message('Control:tuning:strStepRejection1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
        end

        function L = addLocalPlotListeners(~,CL,PlotHandle)
            if isempty(CL)
                L = [];
            else
                %Hide duplicate system and link to active system
                if numel(PlotHandle.Responses) >= 3
                    ContextMenu = qeGetContextMenu(PlotHandle);
                    tags = getMenuTags(PlotHandle);
                    ResponsesMenu = ContextMenu.Children(find(cellfun(@(x) strcmpi(x,'systems'),tags)));
                    ResponsesMenu.Children(end-2).Visible = false;
                    L = addlistener(PlotHandle.Responses(2),'Visible','PostSet',...
                        @(es,ed) cbTrefVisible(PlotHandle));
                end
            end

            function cbTrefVisible(h)
                h.Responses(3).Visible = h.Responses(2).Visible;
            end
        end

        function GoalResponses = getGoalResponses(~,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.Tref = PlotHandle.Responses(1);
            else
                GoalResponses.TrefTop = PlotHandle.Responses(2);
                GoalResponses.TrefBottom = PlotHandle.Responses(3);
            end
        end

        function DesignResponses = getDesignResponses(~,CL,PlotHandle)
            if isempty(CL)
                DesignResponses.T = [];
            else
                DesignResponses.T = PlotHandle.Responses(1);
            end
        end

        function DesignResponses = getComparedResponses(~,CL,PlotHandle)
            if isempty(CL)
                NDesigns = length(PlotHandle.Responses)-1;
            else
                NDesigns = length(PlotHandle.Responses)-3;
            end
            DesignResponses = repmat(struct('T',[]),NDesigns,1);
            for ii = 1:NDesigns
                DesignResponses(ii).T = PlotHandle.Responses(length(PlotHandle.Responses)-NDesigns+ii);
            end
        end

        function Ts = getTs(~,~)
            Ts = [];
        end

        function TU = getTU(~,~)
            TU = [];
        end

        % Update Goal wave forms
        function updateGoal(this,CL,PlotHandle)
            GoalResponses = getGoalResponses(this,CL,PlotHandle);
            % Compute data for goals
            [T,Tref] = viewSpecHelper(this,CL);
            % Update Simulation horizon
            for ct=1:numel(PlotHandle.Responses)
                PlotHandle.Responses(ct).SourceData.TimeSpec = localGetSimHorizon(Tref);
            end
            % Update Tref Model
            if isfield(GoalResponses,'Tref')
                GoalResponses.Tref.SourceData.Model = Tref;
            else
                GoalResponses.TrefTop.SourceData.Model = Tref;
                GoalResponses.TrefBottom.SourceData.Model = -Tref;
            end
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strStepRejection1',this.Name));
            % Set InputName and OutputName for the plot
            PlotHandle.InputNames = T.InputName;
            PlotHandle.OutputNames = T.OutputName;
        end

        % Update Design wave forms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            T = viewSpecHelper(this,CL);
            DesignResponses.T.SourceData.Model = T;
        end

        % Add Design wave forms
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            T = viewSpecHelper(this,Design);
            Name = sprintf('%s: %s',getString(message('Control:systunegui:TGPlotActual')),Name);
            addResponse(PlotHandle,T,Name=Name,LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
        end

        % Update limits
        function updateLimits(varargin)
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
            SPEC.Band = [0,pi/Ts];
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
            if ny>1 && nu>1
                [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,min(nu,ny));
            end
            if ny<=nu
                SPEC.WL = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWF);
            else
                SPEC.WR = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWF);
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

% -----------------------
function RefModel = localComputeRef(ymax,zeta,tS)
% Compute reference model from its time-domain characteristics.
% This model is of the form
%     H(s) = (beta*ymax)*w*s/(s^2+2*zeta*w*s+w^2)
phi0 = acos(zeta);
aux = sin(phi0);   % sqrt(1-zeta^2)
if phi0==0  % zeta=1
    beta = exp(1);
else
    beta = exp(phi0*zeta/aux);
end
% Compute value of theta=w*t for which envelope enters 2% settling band
yS = 0.02/beta;
if phi0==0
    thetaMin = 1;
else
    thetaMin = phi0/aux;
end
F = @(x) x*exp(-zeta*x)*localPSI(aux*x);  % envelope
thetaMax = 8*thetaMin;
while F(thetaMax)>yS
    thetaMax = 8*thetaMax;
end
thetaS = fzero(@(x) F(x)-yS,[thetaMin,thetaMax]);
% Build ref model
w = thetaS/tS;
RefModel = zpk(0,-w*complex(zeta,[aux,-aux]),beta*ymax*w);
end

function y = localPSI(x)
if x==0
    y = 1;
elseif x<pi/2
    y = sin(x)/x;
else
    y = 1/x;
end
end

function Tf = localGetSimHorizon(Tref)
% Compute simulation horizon for reference model
[~,t] = step(Tref);
L = log10(t(end));
r = mod(L,1)+1;  % 10^r between 10 and 100
Tf = 5 * ceil(0.3*10^r) * 10^(L-r);
end
