classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Passivity < TuningGoal.BandLimited & TuningGoal.GenericIO & ...
        TuningGoal.SystemLevel
    % Passivity constraints for control system tuning.
    %
    %   A system is passive if its input/output trajectories (u(t),y(t))
    %   satisfy
    %
    %      integral  y'(t) u(t) dt  > 0 .
    %
    %   For a linear system G(s), this is equivalent the positive realness
    %   condition
    %
    %      G(jw) + G'(jw) > 0  at all frequencies w.
    %
    %   TG = TuningGoal.Passivity(INPUTNAME,OUTPUTNAME) creates a tuning
    %   goal TG for enforcing passivity of the response from inputs
    %   INPUTNAME to outputs OUTPUTNAME.
    %
    %   TG = TuningGoal.Passivity(INPUTNAME,OUTPUTNAME,NU,RHO) creates a
    %   tuning goal for enforcing
    %
    %      integral y'(t) u(t) dt  >  NU * ||u||^2 + RHO * ||y||^2 .
    %
    %   This stipulates an excess of passivity when NU,RHO>0, and allows for
    %   a shortage of passivity when NU,RHO<0. The default is NU=RHO=0.
    %
    %   The strings or cell arrays of strings INPUTNAME and OUTPUTNAME specify
    %   the input and output signals by name. For MATLAB models, you can refer
    %   to the model inputs and outputs as well as any internal signal marked
    %   with an AnalysisPoint block. For Simulink models, you can refer to any
    %   Linear Analysis point marked in the model or specified with the addPoint
    %   method of the slTuner interface.
    %
    %   Set properties to further configure the requirement. For example,
    %      TG = TuningGoal.Passivity('u','y',0,0.1)
    %      TG.Name = 'Output strictly passive'
    %      TG.Focus = [0 10]
    %      TG.Openings = 'OuterLoop'
    %      TG.Models = 2
    %   names the requirement, specifies that it should be evaluated in the
    %   frequency band [0,10] rad/s with the outer loop open, and that it
    %   only applies to the second plant model. For details on individual
    %   properties, type "help TuningGoal.Passivity.<property name>".
    %
    %   Use VIEWGOAL(TG) to visualize this goal and use SYSTUNE to tune the
    %   control system parameters subject to this and other goals. For plain
    %   passivity, VIEWGOAL plots the R-index as a function of frequency,
    %   defined as the smallest R>0 such that
    %         (I-G(jw))'*(I-G(jw)) < R^2 (I+G(jw))'*(I+G(jw)).
    %   The I/O transfer is passive when the R-index is less than 1 at all
    %   frequencies.
    %
    %   See also isPassive, getPassiveIndex, TuningGoal.WeightedPassivity,
    %   TuningGoal.ConicSector, AnalysisPoint, slTuner/addPoint, getPoints,
    %   evalGoal, viewGoal, TuningGoal, systune, looptune, slTuner.

    %   Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Input passivity index (scalar, default = 0).
        %
        % Specifies the required amount of passivity NU at the system inputs:
        %
        %      integral y'(t) u(t) dt  >  NU * ||u||^2 .
        %
        % A positive value NU>0 specifies an excess of passivity at the
        % inputs, while a negative value NU<0 allows for a shortage of
        % passivity at the inputs. This index is related to the notions
        % of "input strictly passive" (ISP) and "input feedforward passivity"
        % (IFP).
        IPX = 0;
        % Output passivity index (scalar, default = 0).
        %
        % Specifies the required amount of passivity RHO at the system outputs:
        %
        %      integral y'(t) u(t) dt  >  RHO * ||y||^2 .
        %
        % A positive value RHO>0 specifies an excess of passivity at the
        % outputs, while a negative value RHO<0 allows for a shortage of
        % passivity at the outputs. This index is related to the notions
        % of "output strictly passive" (OSP) and "output feedback passivity"
        % (OFP).
        OPX = 0;
    end

    methods

        % Constructor
        function this = Passivity(InputName,OutputName,InputIndex,OutputIndex)
            ni = nargin;
            if ni>0
                narginchk(2,4)
                try
                    this.Input = InputName;
                    this.Output = OutputName;
                    if ni>2
                        this.IPX = InputIndex;
                    end
                    if ni>3
                        this.OPX = OutputIndex;
                    end
                catch ME
                    throw(ME)
                end
            end
        end

        function this = set.IPX(this,Value)
            % SET function for IPX index
            if ~(isnumeric(Value) && isscalar(Value) && isreal(Value) && isfinite(Value))
                error(message('Control:tuning:Passivity1'))
            end
            this.IPX = double(Value);
        end

        function this = set.OPX(this,Value)
            % SET function for OPX index
            if ~(isnumeric(Value) && isscalar(Value) && isreal(Value) && isfinite(Value))
                error(message('Control:tuning:Passivity2'))
            end
            this.OPX = double(Value);
        end

    end

    methods (Access = protected)

        function H = getClosedLoopTransfer_(this,CL,varargin)
            % Computes closed-loop transfer from inputs to outputs.
            H = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            [ny,nu] = iosize(H);
            if ny~=nu
                error(message('Control:tuning:Passivity4',getID(this)))
            end
            H = sminreal(getValue(H,varargin{:}));
        end

        function Q = getQ(this,nu)
            % Builds Q matrix for sector bound [G;I]'*Q*[G;I] < 0
            % NOTE: No scaling needed here because typically normalized, plus
            % scaling would create discrepancy with getPassiveIndex/sectorplot
            Q = kron([2*this.OPX , -1;-1 2*this.IPX],eye(nu));
        end

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            % NOTE: CL is a genss or slTuner object.
            H = getClosedLoopTransfer_(this,CL);
            if nargout>1
                nu = size(H,2);
                Q = getQ(this,nu);
                R = getSectorIndex([H;eye(nu)],Q,1e-6,this.Focus);
                fObj = 1./(1./R+1/TuningGoal.ConicSector.getRmax());
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
            Bound =  ss(1,'TimeUnit',TU,'Ts',Ts);
        end

        % Update limits
        function updateLimits(this,Ts,plotHandle,XLimitsFocus,YLimitsFocus)
            view = qeGetView(plotHandle);
            Xlim = TuningGoal.getFreqLims(XLimitsFocus{1},this.Focus,Ts);
            view.XLimitsFocus = {Xlim};
            Ylim = YLimitsFocus{1};
            Ylim(1) = min(Ylim(1),0.5);
            Ylim(2) = max(Ylim(2),2);
            view.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [Bound,~,TU] = viewSpecGoalData(this,CL);
            % Graphical validation of requirement
            h = controllib.chart.internal.utils.ltiplot("sector",ax);
            if isequal(CL,[])
                % Just show bounds
                h.IndexUnit = "abs";
                h.IndexScale = "log";
                h.YLabel.String = getString(message('Control:systunegui:TGPlotRIndex'));
            else
                [HS,QS] = viewSpecHelper(this,CL);
                addResponse(h,HS,QS,Name=getString(message('Control:systunegui:TGPlotRIndex')));
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                % Legend
                h.LegendVisible = true;
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Title
            h.Title.String = getString(message('Control:tuning:strPassivity1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            % Plot bounds
            addBoundResponse(h,Bound,BoundType='upper',...
                Focus=this.Focus*funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotNormalizedBound')),...
                FaceAlpha=0.3,EdgeAlpha=0.3);
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
            % Compute data for goal
            [Bound,~,TU] = viewSpecGoalData(this,CL);
            % Goal Focus
            tau = funitconv('rad/TimeUnit','rad/s',TU);
            wFocus = tau*this.Focus;
            % Update Bound
            GoalResponses.Bound.Model = Bound;
            GoalResponses.Bound.Focus = wFocus;
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strPassivity1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignWaveforms,CL)
            % Compute data for design
            [HS,QS] = viewSpecHelper(this,CL);
            DesignWaveforms.X.SourceData.Model = HS;
            DesignWaveforms.X.SourceData.Q = QS;
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [HS,QS] = viewSpecHelper(this,Design);
            name = sprintf(strcat(getString(message('Control:systunegui:TGPlotRIndex')),': %s'),Name);
            % Add responses
            addResponse(PlotHandle,HS,QS,Name=name,LineStyle=LineStyle,LineWidth=1.75);
            PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
        end

    end

    methods (Hidden)

        function [H,Q] = viewSpecHelper(this,CL)
            % Returns the state-space model H and matrices Q,W1,W2 needed to
            % plot the R-index. W1,W2 are related to Q by
            %    Q = W1*W1'-W2*W2'      W1'*W2=0
            % and the R-index is the smallest r>0 such that
            %    H' * (W1*W1'-r^2*W2*W2') * H < 0
            X = getClosedLoopTransfer_(this,CL,'usample');
            nu = size(X,2);
            H = [X ; eye(nu)];
            Q = getQ(this,nu);
        end

        function validateGoal(this,CL)
            % Goal validation for GUI
            H = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
            [ny,nu] = size(H);
            if ny~=nu
                error(message('Control:systunegui:IOMismatch',nu,ny))
            end
            if this.OPX * this.IPX >= 0.25
                error(message('Control:systunegui:Passivity1'))
            end
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
            if this.OPX * this.IPX >= 0.25
                warning(message('Control:tuning:Passivity16'))
            end
            % Builds standardized requirement description for SYSTUNE
            if isempty(this.Input) || isempty(this.Output)
                error(message('Control:tuning:TuningReq17',getID(this)))
            end
            SPEC.Type = 4;
            SPEC.Stabilize = true;
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
            if ny~=nu
                error(message('Control:tuning:Passivity4',getID(this)))
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
            % Build transform G -> [G;I]
            E = [zeros(nu) ; eye(nu)];
            F = [eye(nu) ; zeros(nu)];
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',E,'Poles',[]),...
                'F',F,'G',1,'h',[]);
            % Factorize Q and save factorization data
            [~,W1,W2] = ltipack.getSectorData(getQ(this,nu),[]);
            SPEC.Sector = struct('W1',W1,'W2',W2);
        end

    end

end

