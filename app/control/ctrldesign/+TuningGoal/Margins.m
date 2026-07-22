classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        Margins < TuningGoal.BandLimited & TuningGoal.GenericLoop & ...
        TuningGoal.SystemLevel
    % Stability margin requirement for control system tuning.
    %
    %   R = TuningGoal.Margins(LOC,GM,PM) creates a tuning requirement R for
    %   the gain and phase margins at the location LOC. The string or string
    %   vector LOC specifies one or more loop opening locations (see below).
    %   GM specifies the minimum gain margin in dB, and PM specifies the
    %   minimum phase margin in degrees. For example,
    %      R = TuningGoal.Margins('Velocity',5,40)
    %   stipulates 5 dB of gain margin and 40 degrees of phase margin for the
    %   "Velocity" loop. For MIMO feedback loops, GM and PM are based on the
    %   notion of disk margins (see DISKMARGIN) which guarantee stability
    %   for independent and concurrent gain and phase variations of +/-GM
    %   and +/-PM at the specified locations.
    %
    %   In MATLAB, use AnalysisPoint blocks to mark loop opening locations (LOC
    %   can contain any name listed in the "Location" property of such blocks).
    %   For example,
    %      AP = AnalysisPoint('PILoop');
    %      G = tf(1,[1 2]);
    %      C = tunablePID('C','pi');
    %      T = feedback(AP*G*C,1);
    %   creates a SISO PI loop with a "PILoop" switch at the plant output.
    %   You can then use LOC='PILoop' to refer to the open-loop response
    %   measured at the plant output. In Simulink, LOC can contain any
    %   Linear Analysis point marked in the model or flagged using the
    %   addPoint method of the slTuner interface.
    %
    %   Set properties to further configure the requirement. For example,
    %      R = TuningGoal.Margins('InnerLoop',5,40)
    %      R.Name = 'Inner loop margins'
    %      R.Openings = 'OuterLoop'
    %      R.Focus = [1 25]
    %      R.Models = 2
    %   names the requirement and specifies that the margins should be
    %   assessed in the frequency band [1,25] with the outer loop open
    %   using the second plant model. For details on individual properties,
    %   type "help TuningGoal.Margins.<property name>".
    %
    %   Use VIEWSPEC(R) to visualize this requirement and use SYSTUNE and
    %   related commands to tune the control system parameters subject to
    %   this and other requirements.
    %
    %   See also AnalysisPoint, getPoints, loopmargin, evalGoal, viewGoal,
    %   TuningGoal.Sensitivity, TuningGoal.LoopShape, TuningGoal.MinLoopGain,
    %   TuningGoal.MaxLoopGain, TuningGoal.Poles, TuningGoal, systune,
    %   looptune, slTuner.

    %   Author: P. Gahinet
    %   Copyright 2009-2021 The MathWorks, Inc.

    properties
        % Gain margin (in dB, default = 7.6).
        %
        % Required minimum gain margin. In MIMO feedback loops, stability is
        % guaranteed for simultaneous gain variations of this amount in all
        % feedback channels (at the sites where the open-loop transfer function
        % is measured).
        GainMargin = 7.6;

        % Phase margin (in degrees, default = 45).
        %
        % Required minimum phase margin. In MIMO feedback loops, stability is
        % guaranteed for simultaneous phase variations of this amount in all
        % feedback channels (at the sites where the open-loop transfer function
        % is measured).
        PhaseMargin = 45;

        % D-scaling order (default = 0).
        %
        % Controls the order (number of states) of the scalings involved in
        % computing MIMO stability margins. Static scalings are used by default.
        % Increasing the order may improve results at the expense of increased
        % computations. Use VIEWSPEC to assess the gap between optimized and
        % actual margins and consider increasing the scaling order if this gap
        % is too large.
        ScalingOrder = 0;
    end

    properties (Hidden, Dependent, Transient)
        % Obsoleted in R2013b
        % Note: Nothing to do at load time, set.LoopTransfer will take care
        %       of remapping data
        LoopTransfer
    end

    methods

        % Constructor: Margins(LT,GM,PM)
        function this = Margins(LT,GM,PM)
            narginchk(1,3)
            try
                this.Location = LT;
                if nargin>1
                    this.GainMargin = GM;
                    this.PhaseMargin = PM;
                end
            catch ME
                throw(ME)
            end
        end

        function this = set.GainMargin(this,value)
            % SET method for GainMargin option
            if ~(isnumeric(value) && isscalar(value) && isreal(value) && ...
                    isfinite(value) && value>0)
                error(message('Control:tuning:MarginReq1'))
            end
            this.GainMargin = double(value);
        end

        function this = set.PhaseMargin(this,value)
            % SET method for PhaseMargin option
            if ~(isnumeric(value) && isscalar(value) && isreal(value) && ...
                    isfinite(value) && value>0 && value<180)
                error(message('Control:tuning:MarginReq2'))
            end
            this.PhaseMargin = double(value);
        end

        function this = set.ScalingOrder(this,value)
            % SET method for ScalingOrder option
            if ~(isnumeric(value) && isscalar(value) && ...
                    isreal(value) && value>=0 && value<Inf && rem(value,1)==0)
                error(message('Control:tuning:systune6'))
            end
            this.ScalingOrder = double(value);
        end

        % Obsolete properties
        function this = set.LoopTransfer(this,Value)
            this.Location = Value;
        end
        function Value = get.LoopTransfer(this)
            Value = this.Location;
        end

    end

    methods (Access = protected)

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model.
            % Returns scaled closed-loop transfer H=alpha*(S-(1-e)/2*I) and
            % sets fObj to its peak gain when H is stable, NaN otherwise.
            [alpha,e] = getAlphaE(this);
            LoopChannels = this.Location;
            S0 = getSensitivity(CL,LoopChannels,this.Openings,this.Models);
            S = sminreal(getValue(S0));
            Info = getTuningInfo(CL);
            StableFlag = localCheckStability(S,Info,getTunableBlocks(S0));
            % Loop scaling
            nL = size(S,1);
            if nL>1 && ~isempty(Info)
                try %#ok<TRYNC>
                    % Note: Info.LoopScaling may contain full signal paths in Simulink
                    iL = ltipack.resolveSignalID(LoopChannels,Info.LoopScaling.InputName,true);
                    D = Info.LoopScaling(iL,iL);
                    S = D\S*D;
                end
            end
            H = alpha * (S - ((1-e)/2) * eye(nL));
            if nargout>1
                % fObj is NaN for NaN models, Inf for unstable closed loop, and
                % a finite value otherwise.
                isFinite = isfinite(H,'elem');
                fObj = NaN(size(isFinite));
                fObj(isFinite & ~StableFlag) = Inf;
                idx = find(isFinite & StableFlag);
                fObj(idx) = getPeakGain(H(:,:,idx),1e-6,this.Focus);
            end
        end

    end

    methods (Hidden) %% Tuning goal API

        % Compute data for Goal wave forms
        function [Ts,TU] = viewSpecGoalData(~,CL)
            % Graphical validation of requirement
            if isequal(CL,[])
                Ts = 0;
                TU = 'seconds';
            else
                Ts = CL.Ts;
                TU = CL.TimeUnit;
            end
        end

        % Update limits
        function updateLimits(varargin)
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [Ts,TU] = viewSpecGoalData(this,CL);
            % Create plot
            h = controllib.chart.internal.utils.ltiplot("diskmargin",ax);
            addBoundResponse(h,GM=this.GainMargin,PM=this.PhaseMargin,...
                Ts=Ts * tunitconv(TU,'seconds'),BoundType='lower',...
                Focus=this.Focus*funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:tuning:strMargin5')),...
                FaceAlpha=0.3,EdgeAlpha=0.3);
            h.Responses(end).SemanticFaceColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            h.Responses(end).SemanticEdgeColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
            % Plot margins
            if ~isequal(CL,[])
                % Show margins for supplied design
                [L,StableFlag] = getOpenLoopTransfer(this,CL);
                [~,e] = getAlphaE(this);
                TuningGoal.Margins.addDesignResponses(h,L,e,StableFlag,'-',false);
                % Legend
                h.LegendVisible = true;
            end
            % Adjust axes settings and make plot visible
            h.Title.String = getString(message('Control:tuning:strMargin1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
        end

        function GoalResponses = getGoalResponses(~,~,PlotHandle)
            GoalResponses.Bound = PlotHandle.Responses(1);
        end

        function DesignResponses = getDesignResponses(~,~,PlotHandle)
            if TuningGoal.Margins.hasRCTB()
                DesignResponses.Margins = PlotHandle.Responses(2);
                DesignResponses.LowerBound = PlotHandle.Responses(3);
            else
                DesignResponses.Margins = [];
                DesignResponses.LowerBound = PlotHandle.Responses(2);
            end
        end

        function DesignResponses = getComparedResponses(~,~,PlotHandle)   
            if TuningGoal.Margins.hasRCTB()
                NDesigns = (length(PlotHandle.Responses)-3)/2;
            else
                NDesigns = length(PlotHandle.Responses)-2;
            end
            DesignResponses = repmat(struct('Margins',[],'LowerBound',[]),NDesigns,1);
            for ii = 1:NDesigns
                if TuningGoal.Margins.hasRCTB()
                    DesignResponses(ii).Margins = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*2-1);
                    DesignResponses(ii).LowerBound = PlotHandle.Responses(length(PlotHandle.Responses)+(ii-NDesigns)*2);
                else
                    DesignResponses(ii).LowerBound = PlotHandle.Responses(length(PlotHandle.Responses)-NDesigns+ii);
                end
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
            [Ts,TU] = viewSpecGoalData(this,CL);
            % Update plotted goals
            GoalResponses.Bound.GM = this.GainMargin;
            GoalResponses.Bound.PM = this.PhaseMargin;
            GoalResponses.Bound.Ts = Ts*tunitconv(TU,'seconds');
            GoalResponses.Bound.Focus = this.Focus * funitconv('rad/TimeUnit','rad/s',TU);
            % Set Title for the plot
            PlotHandle.Title.String = getString(message('Control:tuning:strMargin1',this.Name));
        end

        % Update Design waveforms
        function updateDesign(this,DesignResponses,CL)
            % Compute data for design
            [L,StableFlag] = getOpenLoopTransfer(this,CL);
            % Update L for design
            % NOTE: Assumes E unchanged
            DesignResponses.LowerBound.SourceData.Model = L;
            DesignResponses.LowerBound.SourceData.IsStable = StableFlag;
            if TuningGoal.Margins.hasRCTB()
                DesignResponses.Margins.SourceData.Model = L;
                DesignResponses.Margins.SourceData.IsStable = StableFlag;
            end
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [L,StableFlag] = getOpenLoopTransfer(this,Design);
            % Create lines for new design
            L.Name = Name;
            [~,e] = getAlphaE(this);
            TuningGoal.Margins.addDesignResponses(PlotHandle,L,e,StableFlag,LineStyle,true);
        end

    end

    methods (Hidden)

        function this = checkGoal(this,Options)
            %  Applies obsolete "ScalingOrder" option to Margins goal
            if Options.ScalingOrder>0
                this.ScalingOrder = Options.ScalingOrder;
            end
        end

        function [alpha,e] = getAlphaE(this)
            % Computes disk margin ALPHA for stability margin constraint.
            %
            % The gain and phase margin requirements are converted into
            % uncertainty of the form
            %    (1+DELTA*(1-E)/2) / (1-DELTA*(1+E)/2) ,  |DELTA| < ALPHA
            % at the plant inputs or the plant outputs.
            %
            % Note: In the useful range PM in [0,60] deg and GM in [0,20] dB,
            % alpha is nearly linear in PM and GM so the achieved GM/PM is
            % close to f times the target value (f gives a good estimate of
            % the degree of satisfaction/violation).
            gm = min(db2mag(this.GainMargin),pow2(54));  % 4/eps
            DGM = getDGM(gm,this.PhaseMargin,'balanced');
            alpha = gm2dm(DGM);
            e = 0; % REVISIT
        end

        function [L,StableFlag] = getOpenLoopTransfer(this,CL)
            % Return scaled open-loop transfer L and a flag indicating when
            % closed loop is stable
            LoopChannels = this.Location;
            L0 = getLoopTransfer(CL,LoopChannels,-1,this.Openings,this.Models);
            L = sminreal(getValue(L0,'usample'));
            % Closed-loop stability
            nL = size(L,1);
            Info = getTuningInfo(CL);
            S = feedback(eye(nL),L);
            StableFlag = localCheckStability(S,Info,getTunableBlocks(L0));
            % Loop scaling
            if nL>1 && ~isempty(Info)
                try %#ok<TRYNC>
                    % Note: Info.LoopScaling may contain full signal paths in Simulink
                    iL = ltipack.resolveSignalID(LoopChannels,Info.LoopScaling.InputName,true);
                    D = Info.LoopScaling(iL,iL);
                    L = D\L*D;
                end
            end
        end

        function validateGoal(this,CL)
            % Note: Needed to validate Models selection
            getSensitivity(CL,this.Location,this.Openings,this.Models);
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
            % Builds standardized requirement description for SYSTUNE.
            if isempty(this.Location)
                error(message('Control:tuning:TuningReq16',getID(this)))
            end
            SPEC.Type = 3;
            SPEC.Band = [this.Focus(1) , min(this.Focus(2),pi/Ts)];
            if diff(SPEC.Band)<=0
                error(message('Control:tuning:TuningReq15',getID(this)))
            end
            % Locate channels where loop transfer is measured
            [iLoop,MisMatch] = ltipack.resolveSignalID(this.Location,sNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
            SPEC.Input = numel(uNames) + iLoop;
            SPEC.Output = numel(yNames) + iLoop;
            nL = numel(iLoop);
            SPEC.DScaling.Static = (nL>1);
            SPEC.DScaling.Dynamic = (nL>1)*this.ScalingOrder;
            % Locate openings
            if isempty(this.Openings)
                iOpen = [];
            else
                [iOpen,MisMatch] = ltipack.resolveSignalID(this.Openings,sNames,true);
                error(resolveSignalError(this,'Control:tuning:TuningReq8',MisMatch,sNames))
                % Ignore loop openings in locations where loop transfer is measured
                iOpen = setdiff(iOpen,iLoop);
            end
            [SPEC.Config,LoopConfigs] = ...
                TuningGoal.SystemLevel.getSwitchConfig(iOpen,LoopConfigs);
            % alpha * (S - ((1-e)/2)*I) = alpha * (T + (1+e)/2*I)  with S=I+T,
            % so transform T -> E+F*T*G = alpha*T + alpha*(1+e)/2*I
            % so transform T -> E+F*T*G = alpha*T + alpha*I = alpha*(S+T) with S=I+T
            [alpha,e] = getAlphaE(this);
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',(alpha*(1+e)/2)*eye(nL),'Poles',[]),...
                'F',alpha,'G',1,'h',[]);
        end

    end

    methods (Static, Hidden)

        function addDesignResponses(h,L,e,StableFlag,LineStyle,IsComparedDesign)
            % Create response(s) for a given open-loop response L.
            % H is the @diskmarginplot handle.
            DesignName = L.Name;
            DesignColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
            if IsComparedDesign
                DesignColor = controllib.plot.internal.utils.convertSemanticColor(DesignColor,"quaternary");
                LBColor = "--mw-graphics-colorNeutral-line-tertiary";
            else
                LBColor = "--mw-graphics-colorNeutral-line-secondary";
            end
            if TuningGoal.Margins.hasRCTB()
                % MUSSV available
                hinfstructOptions;
                r1Name = getString(message('Controllib:plots:strDiskMarginLegend'));
                if ~isempty(DesignName)
                    r1Name = sprintf('%s: %s',DesignName,r1Name);
                end
                r2Name = getString(message('Control:tuning:strMargin4'));
                if ~isempty(DesignName)
                    r2Name = sprintf('%s: %s',DesignName,r2Name);
                end
                addResponse(h,L,Skew=e,Name=r1Name,LineStyle=LineStyle,LineWidth=1.75)
                h.Responses(end).SourceData.IsStable = StableFlag;
                h.Responses(end).SemanticColor = DesignColor;
                addSigmaResponse(h,L,Skew=e,Name=r2Name,IsStable=StableFlag,LineStyle=LineStyle,LineWidth=1.75)
                h.Responses(end).SemanticColor = LBColor;
                %Hide lower bound from legend
                h.Responses(end).Visible = false;
                h.Responses(end).LegendDisplay = false;
                legend(h,'off');
                legend(h,'show');
            else
                rName = getString(message('Control:tuning:strMargin3'));
                if ~isempty(DesignName)
                    rName = sprintf('%s: %s',DesignName,rName);
                end
                addSigmaResponse(h,L,Skew=e,Name=rName,IsStable=StableFlag,LineStyle=LineStyle,LineWidth=1.75)
                h.Responses(end).SemanticColor = DesignColor;
            end
        end

        function flag = hasRCTB()
            flag = license('test','Robust_Toolbox') && ~isempty(ver('robust'));
        end

    end

end


function StableFlag = localCheckStability(S,Info,RefBlocks)
% Check stability, keeping an eye on cancelling integrators.
CurrentInfo = false;
if ~isempty(Info)
    C = struct2cell(Info.Blocks);
    n = numel(RefBlocks);
    RefBlockNames = cell(n,1);
    for ct=1:n
        RefBlockNames{ct} = RefBlocks{ct}.Name;
    end
    [~,ia,ib] = intersect(fieldnames(Info.Blocks),RefBlockNames);
    CurrentInfo = (numel(ia)==numel(RefBlocks)) && isequaln(C(ia),RefBlocks(ib));
end
if CurrentInfo
    % Note: When current, Info provides more reliable assessment of closed-loop
    % stability (ignores shaping filter modes, cancelling integrators, etc)
    StableFlag = repmat(Info.g<Inf,getArraySize(S)); % gBest=Inf -> failure to stabilize
else
    StableFlag = isstable(S,'elem');
end
end

