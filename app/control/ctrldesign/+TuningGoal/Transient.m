classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Transient < TuningGoal.ScaledIO & TuningGoal.SystemLevel
    % Transient matching requirement for control system tuning.
    %
    %   R = TuningGoal.Transient(INPUTNAME,OUTPUTNAME,REFSYS) requires that
    %   the impulse response from INPUTNAME to OUTPUTNAME closely match the
    %   impulse response of the reference model REFSYS. The signal names
    %   INPUTNAME and OUTPUTNAME can be strings or cell arrays of strings
    %   for vector-valued signals.
    %
    %   R = TuningGoal.Transient(INPUTNAME,OUTPUTNAME,REFSYS,INPUTSIGNAL)
    %   seeks to match the response of REFSYS to a specific input signal.
    %   INPUTSIGNAL specifies the input signal either as one of the strings
    %   'impulse', 'step', 'ramp', or as a SISO transfer function whose
    %   impulse response is the desired signal and whose frequency response
    %   is the signal spectrum. Note that setting INPUTSIGNAL='step' is
    %   equivalent to using the "StepTracking" goal.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.Transient('r','u',tf(1,[1 1]))
    %      R.Name = 'Impulse response'
    %      R.Openings = 'OuterLoop'
    %      R.Models = [2 3]
    %   names the requirement, specifies that it should be evaluated with the
    %   outer loop open, and that it only applies to the second and third plant
    %   models. Type "help TuningGoal.Transient.<property name>" for details
    %   on individual properties.
    %
    %   Use EVALSPEC(R) to evaluate this requirement and use SYSTUNE and related
    %   commands to tune the control system parameters subject to this and other
    %   requirements.
    %
    %   See also evalGoal, viewGoal, TuningGoal.StepTracking,
    %   TuningGoal.StepRejection, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    % Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Reference model (SISO or MIMO state-space model).
        %
        % The desired transient response is the response of this model to the
        % specified input signal. The reference model must be stable and the
        % series connection of the reference model with the input shaping
        % filter must have no feedthrough term.
        ReferenceModel

        % Input shaping filter (SISO ZPK model, default = unit gain).
        %
        % Specifies the input signal as the impulse response of this filter.
        % The default value is a unit gain and the default input signal is
        % an impulse.
        InputShaping

        % Relative matching error (default = 0.1)
        %
        % Specifies the maximum relative gap between the reference and actual
        % transient responses. The relative gap is measured as
        %      || y(t) - yref(t) || / || yref_tr(t) ||
        % where y-yref is the response mismatch, yref_tr is the transient
        % portion of yref (deviation from steady-state value or trajectory),
        % and ||.|| denotes the signal energy (2-norm).
        RelGap = 0.1;
    end

    methods

        % Constructor
        function this = Transient(InputName,OutputName,RefModel,InputSignal)
            narginchk(3,4)
            try
                this.Input = InputName;
                this.Output = OutputName;
                this.ReferenceModel = RefModel;
                if nargin>3
                    if isa(InputSignal,'DynamicSystem')
                        this.InputShaping = InputSignal;
                    else
                        InputType = ltipack.matchKey(InputSignal,{'impulse','step','ramp'});
                        switch InputType
                            case 'impulse'
                                this.InputShaping = zpk(1);
                            case 'step'
                                this.InputShaping = zpk([],0,1);
                            case 'ramp'
                                this.InputShaping = zpk([],[0 0],1);
                            otherwise
                                error(message('Control:tuning:Transient1'))
                        end
                    end
                else
                    this.InputShaping = zpk(1);  % impulse
                end
            catch ME
                throw(ME)
            end
        end

        function this = set.InputShaping(this,Value)
            % SET function for InputShaping
            if isa(Value,'DynamicSystem') && isequal(size(Value),[1 1])
                % Convert to ZPK
                try
                    WU = zpk(Value);
                catch ME
                    error(message('Control:tuning:Transient3'))
                end
                % Validate
                if ~isproper(WU) || hasdelay(WU)
                    error(message('Control:tuning:Transient4'))
                end
                p = pole(WU);
                Ts = WU.Ts;
                if Ts==-1
                    error(message('Control:tuning:TuningReq19'))
                elseif (Ts==0 && any(real(p)>0)) || (Ts~=0 && any(abs(p)>1+1e-8))
                    error(message('Control:tuning:Transient4'))
                end
                this.InputShaping = WU;
            else
                error(message('Control:tuning:Transient2'))
            end
        end

        function this = set.ReferenceModel(this,Value)
            % SET function for ReferenceModel
            if isa(Value,'DynamicSystem') && nmodels(Value)==1 && ~hasdelay(Value)
                % Convert to state space
                try
                    refsys = ss(Value,'explicit');
                catch ME
                    error(message('Control:tuning:ReferenceModel3'))
                end
                % Validate
                if refsys.Ts==-1
                    error(message('Control:tuning:TuningReq19'))
                elseif ~isstable(refsys)
                    error(message('Control:tuning:Transient5'))
                end
                this.ReferenceModel = refsys;
            else
                error(message('Control:tuning:ReferenceModel1'))
            end
        end

        function this = set.RelGap(this,Value)
            % SET function for RelGap
            if (isnumeric(Value) && isreal(Value) && isscalar(Value) && Value>0 && Value<Inf)
                this.RelGap = double(Value);
            else
                error(message('Control:tuning:Transient6'))
            end
        end

    end

    methods (Access = protected)

        function [T,Di,Do] = getClosedLoopTransfer_(this,CL,varargin)
            % Computes (unscaled) closed-loop transfer from r to y
            T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            T = sminreal(getValue(T,varargin{:}));
            % Scalings
            Di = this.InputScaling;
            Do = this.OutputScaling;
            if ~(isempty(Di) && isempty(Do))
                [ny,nu] = iosize(T);
                Di = checkInputScaling(this,Di,nu);
                Do = checkOutputScaling(this,Do,ny);
            end
        end

        function [Tref,ISF,Ttr,wmin,pref] = getReference_(this,Ts,ny,nu,AppFlag)
            % Resample, format, and analyze reference model.
            %   * Tref: reference model
            %   * ISF: input shaping function (for simulation)
            %   * Ttr: stable transient dynamics
            %   * wmin: slowest natural frequency of Ttr.

            % Reference model
            Tref = this.ReferenceModel;
            [nyref,nuref] = iosize(Tref);
            if ~((nyref==ny && nuref==nu) || (nyref==1 && nuref==1))
                if AppFlag
                    error(message('Control:systunegui:RefIOMismatch'))
                else
                    error(message('Control:tuning:Transient7',getID(this)))
                end
            end
            try
                Tref = TuningGoal.resampleModel(Tref,Ts);
            catch ME
                if AppFlag
                    error(message('Control:systunegui:RefResampling'))
                else
                    error(message('Control:tuning:Transient8',getID(this)))
                end
            end
            pref = pole(Tref);

            % Input shaping filter (raw)
            try
                ISF = TuningGoal.resampleModel(ss(this.InputShaping),Ts);
            catch ME
                if AppFlag
                    error(message('Control:systunegui:InputResampling'))
                else
                    error(message('Control:tuning:Transient10',getID(this)))
                end
            end
            ISF.TimeUnit = Tref.TimeUnit;

            % Compute stable portion of Tref*WU (to compute transient energy
            % of reference signal)
            if isempty(pref)
                ZeroTol = 1e-6;
            else
                ZeroTol = 1e-4 * min(damp(pref,Ts));
            end
            if Ts>0
                Ttr = stabsep(Tref*ISF,ZeroTol*Ts);
            else
                Ttr = stabsep(Tref*ISF,ZeroTol);
                if norm(Ttr.d,1)>0
                    % When feedthrough is present, impulse response of Tref*WU
                    % has infinite energy and ||(T-Tref)*WU|| won't be finite
                    % when T(s) is strictly proper
                    if AppFlag
                        error(message('Control:systunegui:ZeroFeedthrough'))
                    else
                        error(message('Control:tuning:Transient9',getID(this)))
                    end
                end
            end
            % Compute slowest natural frequency of transient dynamics
            wn = damp(Ttr);
            if isempty(wn)
                wmin = 1e-3;
            else
                wmin = min(wn);
            end
            % Scalar expansion
            if nyref<ny
                Tref = Tref * eye(ny);
                Ttr = Ttr * eye(ny);
            end
        end

        function WU = getInputWeight_(this,Ts,wmin)
            % Get input weighting function
            WU = TuningGoal.resampleWeight(this.InputShaping,Ts);
            WU = TuningGoal.regularizeWeight3(WU,wmin);
        end

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            [T,Di,Do] = getClosedLoopTransfer_(this,CL);
            [ny,nu] = iosize(T);
            Ts = abs(T.Ts);
            % Reference model
            [Tref,~,Ttr,wmin] = getReference_(this,Ts,ny,nu,false); % Tref is SS
            Tref.TimeUnit = T.TimeUnit;
            % Get input weighting function
            WU = getInputWeight_(this,Ts,wmin);
            WU.TimeUnit = T.TimeUnit;
            % Compute outputs
            if isempty(Di) && isempty(Do)
                beta = this.RelGap * norm(Ttr);
                H = (T-Tref) * (WU/beta);
            else
                beta = this.RelGap * norm(diag(1./Do) * Ttr * diag(Di));
                H = (diag(1./Do) * (T-Tref) * diag(Di)) * (WU/beta);
            end
            if nargout>1
                % Prone to warnings due to cancellation near s=0 in WU*(T-Tref)
                hw = ctrlMsgUtils.SuspendWarnings('Control:transformation:StateSpaceScaling'); %#ok<NASGU>
                fObj = norm(H);
            end
        end

    end

    methods (Hidden) %% Tuning Goal Plot API
        % Compute data
        function [T,Tref,Ttr] = viewSpecHelper(this,CL)
            [T,Di,Do] = getClosedLoopTransfer_(this,CL,'usample');
            [ny,nu] = iosize(T);
            Ts = T.Ts;
            [Tref,ISF,Ttr] = getReference_(this,Ts,ny,nu,false);
            Tref.TimeUnit = T.TimeUnit;
            ISF.TimeUnit = T.TimeUnit;
            if ~(isempty(Di) && isempty(Do))
                T = diag(1./Do) * T * diag(Di);
                Tref = diag(1./Do) * Tref * diag(Di);
            end
            T = set(T*ISF,'InputName',T.InputName,'OutputName',T.OutputName);
            T.Name = getString(message('Control:systunegui:TGPlotActual'));
            Tref = Tref*ISF;
            Tref.Name = getString(message('Control:systunegui:TGPlotDesired'));
        end

        % Create plot
        function h = createPlot(this,CL,ax)
            % Graphical validation of requirement
            if isequal(CL,[])
                % Just plot impulse response of reference model
                Ts = this.ReferenceModel.Ts;
                [ny,nu] = size(this.ReferenceModel);
                [Tref,ISF,Ttr] = getReference_(this,Ts,ny,nu,false);
                Tref = Tref*ISF;
                Tref.Name = getString(message('Control:systunegui:TGPlotDesired'));
                h = impulseplot(ax,Tref,localGetSimHorizon(Ttr));
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(7).SemanticName;
                h.Responses(1).LineStyle = "--";
            else
                [T,Tref,Ttr] = viewSpecHelper(this,CL);
                h = impulseplot(ax,T,Tref,localGetSimHorizon(Ttr));
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(7).SemanticName;
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
            h.Title.String = getString(message('Control:tuning:strTransient1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
        end

        function GoalResponses = getGoalResponses(~,CL,PlotHandle)
            if isempty(CL)
                GoalResponses.Tref = PlotHandle.Responses(1);
            else
                GoalResponses.Tref = PlotHandle.Responses(2);
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
                NDesigns = length(PlotHandle.Responses)-2;
            end
            DesignResponses = repmat(struct('T',[]),NDesigns,1);
            for ii = 1:NDesigns
                DesignResponses(ii).T = PlotHandle.Responses(length(PlotHandle.Responses)-NDesigns+ii);
            end
        end

        function Ts = getTs(this,~)
            Ts = this.ReferenceModel.Ts;
        end

        function TU = getTU(~,~)
            TU = [];
        end

        % Update Goal wave forms
        function updateGoal(this,CL,PlotHandle)
            GoalResponses = getGoalResponses(this,CL,PlotHandle);
            % Compute data for goals
            [T,Tref,Ttr] = viewSpecHelper(this,CL);
            % Update Simulation horizon
            for ct=1:numel(PlotHandle.Responses)
                PlotHandle.Responses(ct).SourceData.TimeSpec = localGetSimHorizon(Ttr);
            end
            % Update Tref Model
            GoalResponses.Tref.SourceData.Model = Tref;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strTransient1',this.Name));
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
            getReference_(this,T.Ts,ny,nu,true);
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
            % Builds standardized requirement description for SYSTUNE
            if isempty(this.Input) || isempty(this.Output)
                error(message('Control:tuning:TuningReq17',getID(this)))
            end
            SPEC.Type = 2;
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
            % Get reference model data and build transform
            %    T(s) -> E(s)+F*T(s)*G = Do\(T(s)-Tref(s))*Di
            [Tref,~,Ttr,wmin,pREF] = getReference_(this,Ts,ny,nu,false);
            [ar,br,cr,dr] = ssdata(Tref);
            Di = this.InputScaling;
            Do = this.OutputScaling;
            if isempty(Di) && isempty(Do)
                F = 1;  G = 1;
            else
                Di = checkInputScaling(this,Di,nu); % may error
                Do = checkOutputScaling(this,Do,ny);
                br = lrscale(br,[],Di);
                cr = lrscale(cr,1./Do,[]);
                dr = lrscale(dr,1./Do,Di);
                F = diag(1./Do);  G = diag(Di);
                Ttr = diag(1./Do) * Ttr * diag(Di);
            end
            E = struct('a',ar,'b',br,'c',-cr,'d',-dr,'Poles',pREF);
            SPEC.Transform = struct('E',E,'F',F,'G',G,'h',[]);
            % Weight WU/beta
            WU = getInputWeight_(this,Ts,wmin);
            [aW,bW,cW,dW] = ssdata(WU);
            pWF = eig(aW);
            beta = this.RelGap * norm(Ttr);
            aux = sqrt(beta);
            if nu>1 && ny>1
                [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,min(ny,nu));
            end
            if nu<ny
                SPEC.WR = struct('a',aW,'b',bW/aux,'c',cW/aux,'d',dW/beta,'Poles',pWF);
            else
                SPEC.WL = struct('a',aW,'b',bW/aux,'c',cW/aux,'d',dW/beta,'Poles',pWF);
            end
        end

        function WU = getWeight(this,Ts)
            % FOR QE only
            [ny,nu] = size(this.ReferenceModel);
            [~,~,~,wmin] = getReference_(this,Ts,ny,nu,false);
            WU = getInputWeight_(this,Ts,wmin);
        end

    end

end


function Tf = localGetSimHorizon(Ttr)
% Compute simulation horizon for transient (needed when InputShaping is
% only marginally stable)
[~,t] = impulse(Ttr);
L = log10(t(end));
r = mod(L,1)+1;  % 10^r between 10 and 100
Tf = 5 * ceil(0.3*10^r) * 10^(L-r);
end
