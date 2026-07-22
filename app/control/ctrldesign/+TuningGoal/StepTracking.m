classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        StepTracking < TuningGoal.TrackIO & TuningGoal.SystemLevel
    % Step command following requirement for control system tuning.
    %
    %   R = TuningGoal.StepTracking(INPUTNAME,OUTPUTNAME,REFSYS) requires that
    %   the closed-loop step response from INPUTNAME to OUTPUTNAME match the
    %   step response of REFSYS. The reference model REFSYS must be stable
    %   and have unit DC gain. The signal names INPUTNAME and OUTPUTNAME can
    %   be strings or cell arrays of strings for vector-valued signals.
    %
    %   R = TuningGoal.StepTracking(INPUTNAME,OUTPUTNAME,TAU) specifies the
    %   desired step response as a first-order response with time constant
    %   TAU (in the prevailing time units).
    %
    %   R = TuningGoal.StepTracking(INPUTNAME,OUTPUTNAME,TAU,OS) specifies the
    %   desired step response as a second-order response with natural period
    %   TAU, natural frequency 1/TAU, and percent overshoot OS. For example,
    %      R = TuningGoal.StepTracking('r','y',3,5)
    %   specifies a second-order response with a natural period of 3 and with
    %   5% overshoot.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.StepTracking('r','u',tf(1,[1 1]))
    %      R.Name = 'Step following'
    %      R.Openings = 'OuterLoop'
    %      R.Models = [2 3]
    %   names the requirement, specifies that it should be evaluated with the
    %   outer loop open, and that it only applies to the second and third plant
    %   models. Type "help TuningGoal.StepTracking.<property name>" for details
    %   on individual properties.
    %
    %   Use EVALSPEC(R) to evaluate this requirement and use SYSTUNE and related
    %   commands to tune the control system parameters subject to this and other
    %   requirements. Note that the requirement value is proportional to the
    %   energy of the error signal yref-y (gap between the desired and actual
    %   step responses).
    %
    %   See also evalGoal, viewGoal, TuningGoal.Tracking, TuningGoal.Overshoot,
    %   TuningGoal.StepRejection, TuningGoal, systune, looptune, slTuner.

    % Author: P. Gahinet
    % Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Reference model (SISO or MIMO state-space model).
        %
        % The step response of this model specifies the desired step response.
        % The step response of the tuned system should match this target response
        % as closely as possible. The reference model must be stable and have unit
        % DC gain (zero steady-state error). For best results, it should also
        % include intrinsic system characteristics such as non-minimum-phase
        % zeros (undershoot).
        ReferenceModel

        % Relative matching error (default = 0.1)
        %
        % Specifies the maximum relative gap between the reference and actual
        % step responses. The relative gap is measured as
        %      || y(t) - yref(t) || / || 1 - yref(t) ||
        % where y-yref is the response mismatch, 1-yref is the step tracking error
        % for the reference model, and ||.|| denotes the signal energy (2-norm).
        RelGap = 0.1;
    end

    methods

        % Constructor
        function this = StepTracking(InputName,OutputName,varargin)
            ni = nargin;
            narginchk(3,4)
            try
                this.Input = InputName;
                this.Output = OutputName;
                if isnumeric(varargin{1})
                    tau = varargin{1};
                    if ~(isnumeric(tau) && isscalar(tau) && isreal(tau) && tau>0 && tau<Inf)
                        error(message('Control:tuning:StepTracking1'))
                    end
                    w0 = 1/tau;
                    if ni>3
                        % Second-order response 1/(tau^2 s^2 + 2 zeta tau s + 1)
                        OS = varargin{2};
                        if ~(isnumeric(OS) && isscalar(OS) && isreal(OS) && OS>=0 && OS<=100)
                            error(message('Control:tuning:StepTracking2'))
                        end
                        zeta = cos(atan2(pi,-log(OS/100)));
                        b1 = sqrt(w0);
                        b2 = zeta*b1;
                        refsys = ss(w0*[-zeta 1 ; zeta^2-1 -zeta],[b1;b2],[b2 -b1],0);
                    else
                        % First-order response
                        aux = sqrt(w0);
                        refsys = ss(-w0,aux,aux,0);
                    end
                elseif isa(varargin{1},'DynamicSystem')
                    refsys = varargin{1};
                else
                    error(message('Control:tuning:StepTracking8'))
                end
                this.ReferenceModel = refsys;
            catch ME
                throw(ME)
            end
        end

        function this = set.ReferenceModel(this,Value)
            % SET function for ReferenceModel
            if isa(Value,'DynamicSystem') && nmodels(Value)==1 && ~hasdelay(Value)
                dc = dcgain(Value);
                % Convert to state space
                try
                    refsys = ss(Value,'explicit');
                catch ME
                    error(message('Control:tuning:ReferenceModel3'))
                end
                % Validate
                if Value.Ts==-1
                    error(message('Control:tuning:TuningReq19'))
                elseif ~(isstable(refsys) && diff(size(dc))==0 && norm(dc-eye(size(dc)))<sqrt(eps))
                    error(message('Control:tuning:StepTracking4'))
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

        function T = getClosedLoopTransfer_(this,CL,varargin)
            % Computes (unscaled) closed-loop transfer from r to y
            T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            T = sminreal(getValue(T,varargin{:}));
            [ny,nu] = iosize(T);
            if ny~=nu
                error(message('Control:tuning:TuningReq14',getID(this),nu,ny))
            end
        end

        function [Tref,wmin,pref] = getReference_(this,Ts,ny,AppFlag)
            % Resample, format, and analyze reference model. Returns
            %   * Tref: reference model
            %   * wmin: slowest natural frequency of Tref.
            Tref = this.ReferenceModel;
            nyref = size(Tref,1);
            if ~(nyref==ny || nyref==1)
                if AppFlag
                    error(message('Control:systunegui:RefIOMismatch'))
                else
                    error(message('Control:tuning:Transient7',getID(this)))
                end
            end
            % Resample (easier before replicating scalar model)
            try
                Tref = TuningGoal.resampleModel(Tref,Ts);
            catch ME
                if AppFlag
                    error(message('Control:systunegui:RefResampling'))
                else
                    error(message('Control:tuning:Transient8',getID(this)))
                end
            end
            % Compute poles
            pref = pole(Tref);
            % Compute slowest natural frequency of transient dynamics
            wn = damp(Tref);
            if isempty(wn)
                wmin = 1e-3;
            else
                wmin = min(wn);
            end
            % Scalar expansion
            if nyref<ny
                Tref = Tref * eye(ny);
            end
        end

        function WI = getInputWeight_(~,Ts,wmin)
            % Get input weighting function
            WI = TuningGoal.resampleWeight(zpk([],0,1),Ts);
            WI = ss(TuningGoal.regularizeWeight3(WI,wmin));
        end

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            T = getClosedLoopTransfer_(this,CL);
            ny = size(T,1);
            Ts = abs(T.Ts);
            % Reference model
            [Tref,wmin] = getReference_(this,Ts,ny,false);
            Tref.TimeUnit = T.TimeUnit;
            % Integral weight
            WI = getInputWeight_(this,Ts,wmin);
            WI.TimeUnit = T.TimeUnit;
            % Compute outputs
            DS = this.InputScaling;
            if isempty(DS)
                beta = this.RelGap * norm(WI * (Tref-eye(ny)));
                H = (WI/beta) * (T-Tref);
            else
                DS = checkInputScaling(this,DS,ny);
                beta = this.RelGap * norm(WI * (diag(1./DS)*(Tref-eye(ny))*diag(DS)));
                H = (WI/beta) * (diag(1./DS) * (T-Tref) * diag(DS));
            end
            if nargout>1
                fObj = norm(H);
            end
        end

    end

    methods (Hidden) %% Tuning Goal Plot API

        % Compute data
        function [T,Tref] = viewSpecHelper(this,CL)
            T = getClosedLoopTransfer_(this,CL,'usample');
            T.Name = getString(message('Control:systunegui:TGPlotActual'));
            % Replace with short names for Simulink model
            try %#ok<TRYNC>
                if isa(CL,'slTuner')
                    [T.InputName,T.OutputName] = getShortNames(CL,T.InputName,T.OutputName);
                end
            end
            DS = this.InputScaling;
            if ~isempty(DS)
                DS = checkInputScaling(this,DS,size(T,2));
                T = set(diag(1./DS) * T * diag(DS),...
                    'InputName',T.InputName,'OutputName',T.OutputName);
            end
            % Reference model
            if nargout>1
                Tref = getReference_(this,T.Ts,size(T,1),false);
                Tref.TimeUnit = T.TimeUnit;
                Tref.Name = getString(message('Control:systunegui:TGPlotDesired'));
                if ~isempty(DS)
                    Tref = diag(1./DS) * Tref * diag(DS);
                end
            end
        end

        % Create plot
        function h = createPlot(this,CL,ax)
            % Graphical validation of requirement
            if isequal(CL,[])
                Tref = this.ReferenceModel;
                Tref.Name = getString(message('Control:systunegui:TGPlotDesired'));
                % Just plot step response of reference model
                h = stepplot(ax,Tref);
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(7).SemanticName;
                h.Responses(1).LineStyle = "--";
            else
                % Get viewspec data
                [T,Tref] = viewSpecHelper(this,CL);
                h = stepplot(ax,T,Tref,localGetSimHorizon(Tref));
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
            h.Title.String = getString(message('Control:tuning:strStepTracking1',this.Name));
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
            GoalResponses.Tref.SourceData.Model = Tref;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strStepTracking1',this.Name));
            % Set IO names for the plot
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
            if ny~=nu
                error(message('Control:systunegui:IOMismatch',nu,ny))
            end
            DS = this.InputScaling;
            if ~(isempty(DS) || numel(DS)==nu)
                error(message('Control:systunegui:StepScaling'))
            end
            getReference_(this,T.Ts,ny,true);
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
            % Get reference model data and build transform
            %    T(s) -> E(s)+F*T(s)*G = DS\(T(s)-Tref(s))*DS
            [Tref,wmin,pREF] = getReference_(this,Ts,ny,false);
            [ar,br,cr,dr] = ssdata(Tref);
            DS = this.InputScaling;
            if isempty(DS)
                F = 1;  G = 1;
            else
                DS = checkInputScaling(this,DS,nu); % may error
                br = lrscale(br,[],DS);
                cr = lrscale(cr,1./DS,[]);
                dr = lrscale(dr,1./DS,DS);
                F = diag(1./DS);  G = diag(DS);
            end
            SPEC.Transform = struct(...
                'E',struct('a',ar,'b',br,'c',-cr,'d',-dr,'Poles',pREF),'F',F,'G',G,'h',[]);
            % Integral weight
            WI = getInputWeight_(this,Ts,wmin);
            [aW,bW,cW,dW] = ssdata(WI);
            pWF = aW;  % scalar
            if ny>1
                [aW,bW,cW,dW] = TuningGoal.repWeight(aW,bW,cW,dW,ny);
            end
            % Form WI*DS\(Tref-I)*DS and evaluate normalizing factor
            [ax,bx,cx,dx] = ltipack.ssops('mult',aW,bW,cW,dW,[],ar,br,cr,dr-eye(ny),[]);
            beta = this.RelGap * norm(ss(ax,bx,cx,dx,Ts));
            aux = sqrt(beta);
            SPEC.WL = struct('a',aW,'b',bW/aux,'c',cW/aux,'d',dW/beta,'Poles',pWF);
        end

        function WI = getWeight(this,Ts)
            % FOR QE only
            [~,wmin] = getReference_(this,Ts,size(this.ReferenceModel,1),false);
            WI = getInputWeight_(this,Ts,wmin);
        end

    end

end


function Tf = localGetSimHorizon(Tref)
    % Compute simulation horizon for reference model
    [~,t] = step(Tref);
    L = log10(t(end));
    r = mod(L,1)+1;  % 10^r between 10 and 100
    Tf = 5 * ceil(0.2*10^r) * 10^(L-r);
end
