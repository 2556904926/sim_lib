classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
        ConicSector < TuningGoal.BandLimited & TuningGoal.GenericIO & ...
        TuningGoal.SystemLevel
    % Sector bound for control system tuning.
    %
    %   TG = TuningGoal.ConicSector(INPUTNAME,OUTPUTNAME,Q) creates a tuning
    %   goal TG for restricting the linear response H from inputs INPUTNAME
    %   to outputs OUTPUTNAME to the conic sector
    %
    %      integral[0,T] (Hu)(t)' Q (Hu)(t) dt < 0  for all T>=0   (1)
    %
    %   The sector geometry is specified by the symmetric matrix Q. This
    %   matrix should have as many negative eigenvalues as input channels
    %   in H, that is,
    %
    %      Q = W1*W1' - W2*W2' with W1'*W2=0 and size(W2,2)=size(H,2).
    %
    %   You can also use an LTI model Q satisfying Q(s)' = Q(-s) to specify
    %   frequency-dependent sector bounds.
    %
    %   The strings or string vectors INPUTNAME and OUTPUTNAME specify the
    %   input and output signals by name. For MATLAB models, you can refer
    %   to the model inputs and outputs as well as any internal signal marked
    %   with an AnalysisPoint block. For Simulink models, you can refer to
    %   any Linear Analysis point marked in the model or specified with the
    %   addPoint method of the slTuner interface.
    %
    %   Set properties to further configure the requirement. For example,
    %      TG = TuningGoal.ConicSector('u','y',[0.1 -1;-1 0])
    %      TG.Name = 'Output passive'
    %      TG.Focus = [0 10]
    %      TG.Openings = 'OuterLoop'
    %      TG.Models = 2
    %   names the requirement, specifies that it should be evaluated in the
    %   frequency band [0,10] rad/s with the outer loop open, and that it
    %   only applies to the second plant model. For details on individual
    %   properties, type "help TuningGoal.ConicSector.<property name>".
    %
    %   Use VIEWGOAL(TG) to visualize this goal and use SYSTUNE to tune the
    %   control system parameters subject to this and other goals. The
    %   "ConicSector" goal enforces the time-domain sector bound (1) as the
    %   equivalent frequency-domain conditions:
    %      (a) W2' * H(s) minimum phase
    %      (b) H(-jw)' * Q * H(jw) < 0 at all frequencies w.
    %   The R-index quantifies by how much (b) is satisfied or violated at
    %   each frequency (see getSectorIndex). The sector bound (1) is satisfied
    %   when the R-index is less than 1 at all frequencies. VIEWGOAL plots
    %   the R-index as a function of frequency.
    %
    %   Note: When the feedthrough term in H can become singular, it is
    %   numerically safer to enforce the regularized bound
    %       H(-jw)' * Q * H(jw) < - EPS^2 * I
    %   Use the "Regularization" property to set the EPS parameter, type
    %   "help TuningGoal.ConicSector.Regularization" for details.
    %
    %   See also getSectorIndex, AnalysisPoint, addPoint, getPoints, evalGoal,
    %   viewGoal, TuningGoal.Gain, TuningGoal, systune, looptune, slTuner.

    %   Author: P. Gahinet
    %   Copyright 2009-2016 The MathWorks, Inc.

    properties
        % Sector geometry (matrix or LTI model).
        %
        % This goal constrains the output trajectories y(t) to a quadratic
        % sector of the form
        %
        %    integral y(t)' * Q * y(t) dt  <  0
        %
        %  where Q is a symmetric matrix or an LTI model Q(s) that evaluates
        %  to a Hermitian matrix at each frequency. Use this property to
        %  specify the matrix or LTI model Q. Note that Q must be indefinite
        %  to have a well-defined conic sector.
        SectorMatrix
        % Regularization parameter (nonnegative scalar, default = 0).
        %
        % By default, the ConicSector goal enforces the sector bound
        %
        %    H(-jw)' * Q * H(jw) < 0   (1)
        %
        % at all frequencies w, where H is the closed-loop transfer from
        % inputs to outputs. This is well posed as long as the feedthrough
        % term in H has full rank. However, if some tuning goal drives the
        % solver toward a design point where this feedthrough term is rank
        % deficient, enforcing (1) becomes numerically intractable. To
        % prevent this, you can use the regularized bound
        %
        %    H(-jw)' * Q * H(jw) < - EPS^2 * I
        %
        % where the parameter EPS is a small fraction (e.g., 0.001) of the
        % typical norm of the feedthrough term in H.
        %
        % Use this property to specify the regularization parameter EPS.
        % For example, if you anticipate the norm of H.d to stay close to 1
        % during tuning, set
        %    R.Regularization = 1e-3;
        Regularization = 0;
    end

    properties (Access=protected, Transient)
        % Cached decomposition Q(s) = (diag(S)*W(s))' * QN * (diag(S)*W(s))
        % where QN has normalized rows and columns.
        Qfact_
    end

    properties (Dependent,Hidden)
        Q
    end

    methods

        % Constructor
        function this = ConicSector(InputName,OutputName,Q)
            narginchk(3,3)
            try
                this.Input = InputName;
                this.Output = OutputName;
                this.SectorMatrix = Q;
            catch ME
                throw(ME)
            end
        end

        function this = set.SectorMatrix(this,QV)
            % SET function for SectorMatrix matrix
            [ny,nu,nQ] = size(QV);
            if ~(ny>1 && ny==nu && nQ==1)
                error(message('Control:tuning:ConicSector7'))
            elseif isnumeric(QV)
                % Static Q
                if ~(isreal(QV) && isequal(QV,QV') && allfinite(QV))
                    error(message('Control:tuning:ConicSector1'))
                end
                QV = double(QV);
                % QN = diag(S) * Q * diag(S)
                [S,QN] = ltipack.util.symscale(QV);
                W = [];
            elseif isa(QV,'numlti')
                % Dynamic Q(s)
                try
                    QV = ss(QV);
                catch
                    error(message('Control:tuning:ConicSector8'))
                end
                if ~(isreal(QV) && isct(QV))
                    error(message('Control:tuning:ConicSector6'))
                end
                try
                    [W,M] = spectralfact(QV);
                catch ME
                    error(message('Control:tuning:ConicSector9',ME.message))
                end
                [S,QN] = ltipack.util.symscale(M);   % QN = diag(S) * M * diag(S)
            else
                error(message('Control:tuning:ConicSector5'))
            end
            this.SectorMatrix = QV;
            % Cache Q factorization data
            this.Qfact_ = struct('QN',QN,'W',W,'S',1./S); %#ok<MCSUP>
        end

        function this = set.Regularization(this,Value)
            if ~(isnumeric(Value) && isscalar(Value) && isreal(Value) && ...
                    isfinite(Value) && Value>=0)
                error(message('Control:tuning:ConicSector11'))
            end
            this.Regularization = double(Value);
        end

        % Obsolete
        function Value = get.Q(this)
            Value = this.SectorMatrix;
        end
        function this = set.Q(this,Value)
            try
                this.SectorMatrix = Value;
            catch ME
                throw(ME)
            end
        end

    end

    methods (Access = protected)

        function H = getClosedLoopTransfer_(this,CL,varargin)
            % Computes closed-loop transfer from inputs to outputs.
            % Note: If the same signal is used as both input and output, the
            %       corresponding I/O transfer is assumed to be IDENTITY.
            CL = genss(CL);  % so that vector signals are properly sized and indexed
            % Resolve signal names
            AP = getPoints(CL);
            SignalNames = [CL.InputName;AP];
            [~,MisMatch,Usel] = ltipack.resolveSignalID(this.Input,SignalNames,true);
            error(genlti.resolveSignalError('Control:lftmodel:getTransfer7',MisMatch,SignalNames))
            SignalNames = [Usel;AP;CL.OutputName];  % note: includes selected inputs
            [~,MisMatch,Ysel] = ltipack.resolveSignalID(this.Output,SignalNames,true);
            error(genlti.resolveSignalError('Control:lftmodel:getTransfer8',MisMatch,SignalNames))
            nu = numel(Usel);  ny = numel(Ysel);
            % Isolate output signals that are also inputs
            [isYU,iUsel] = ismember(Ysel,Usel);
            nyu = sum(isYU);
            if nyu>0
                % Note: Can't use getIOTransfer directly because transfer u->y2=u
                % evaluates to 0 or L/(1-L) (complementary sensitivity).
                % Transfer U->Y1 with U,Y1
                H = getIOTransfer(CL,Usel,Ysel(~isYU),this.Openings,this.Models);
                H = sminreal(getValue(H,varargin{:}));
                % Feedthrough U->Y2 with Y2=U(iUsel(isYU))
                FF = zeros(nyu,nu);
                FF(:,iUsel(isYU)) = eye(nyu);
                H = [H ; FF];
                % Restore original output order
                yperm([find(~isYU) ; find(isYU)],1) = (1:ny)';
                H = H(yperm,:);
                H.OutputName = Ysel;
            else
                H = getIOTransfer(CL,Usel,Ysel,this.Openings,this.Models);
                H = sminreal(getValue(H,varargin{:}));
            end
        end

        function [W,QW] = getWeight(this,Ts)
            % Computes W(s) such that H'*Q(s)*H = (W*H)' * QW * (W*H) and
            % discretizes Q(s) if necessary.
            S = this.Qfact_.S;
            W = this.Qfact_.W;
            QW = this.Qfact_.QN;
            if isempty(W)
                W = ss(diag(S),'Ts',Ts);
            else
                W = diag(S) * W;
                if Ts>0
                    % Refactor to enforce W.D = I (otherwise minimum-phase
                    % test gives unpredictable results)
                    [W,QW] = spectralfact(c2d(W,Ts,'tustin'),QW);
                end
            end
        end

        function [H,fObj] = evalSpec_(this,CL)
            % Evaluates requirement for given closed-loop model
            % NOTE: CL is a genss or slTuner object.
            QN = this.Qfact_.QN;
            H = getClosedLoopTransfer_(this,CL);
            [ny,nu] = size(H);
            if ny~=size(QN,1)
                error(message('Control:tuning:ConicSector3',getID(this)))
            elseif ny<nu
                error(message('Control:tuning:ConicSector4',getID(this)))
            end
            if nargout>1
                [W,QW] = getWeight(this,H.Ts);
                W.TimeUnit = H.TimeUnit;
                epsReg = this.Regularization;
                if epsReg>0
                    % W*H -> [W*H ; eps*I]    QN -> [QN 0;0 I]
                    R = getSectorIndex([W*H;epsReg*eye(nu)],...
                        blkdiag(QW,eye(nu)),1e-6,this.Focus);
                else
                    R = getSectorIndex(W*H,QW,1e-6,this.Focus);
                end
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
        function updateLimits(~,~,plotHandle,~,YLimitsFocus)
            Ylim = YLimitsFocus{1};
            Ylim(1) = min(Ylim(1),0.5);
            Ylim(2) = max(Ylim(2),2);
            plotHandle.YLimitsFocus = {Ylim};
        end

        function h = createPlot(this,CL,ax)
            % Create plot
            [Bound,~,TU] = viewSpecGoalData(this,CL);
            % Graphical validation of requirement
            h = controllib.chart.internal.utils.ltiplot("sector",ax);
            if isequal(CL,[])
                % Just show bounds and target shape
                h.IndexUnit = "abs";
                h.IndexScale = "log";
                h.YLabel.String = getString(message('Control:systunegui:TGPlotRIndex'));
            else
                [HN,QN] = viewSpecHelper(this,CL);
                addResponse(h,HN,QN,Name=getString(message('Control:systunegui:TGPlotRIndex')));
                h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
                % Legend
                h.LegendVisible = true;
            end
            % Thicker lines
            for ct=1:numel(h.Responses)
                h.Responses(ct).LineWidth = 1.75;
            end
            % Title
            h.Title.String = getString(message('Control:tuning:strConicSector1',this.Name));
            h.Title.Interpreter = 'none';
            h.AxesStyle.GridVisible = true;
            % Plot bounds
            addBoundResponse(h,Bound,BoundType='upper',...
                Focus=this.Focus*funitconv('rad/TimeUnit','rad/s',TU),...
                Name=getString(message('Control:systunegui:TGPlotMax')),...
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

        % Update Goal responses
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
            % setTitle(hPlot,getString(message('Control:tuning:strMaxRIndexReq1',this.Name))); %% REVISIT
            PlotHandle.Title.String = getString(message('Control:tuning:strConicSector1',this.Name));
        end

        % Update Design responses
        function updateDesign(this,DesignResponses,CL)
            % Note: Should be called when goal is changed because of normalization
            [HN,QN] = viewSpecHelper(this,CL);
            DesignResponses.X.SourceData.Model = HN;
            DesignResponses.X.SourceData.Q = QN;
        end

        % Add design
        function addDesign(this,PlotHandle,Design,Name,LineStyle)
            % Compute data for design
            [HN,QN] = viewSpecHelper(this,Design);
            name = sprintf(strcat(getString(message('Control:systunegui:TGPlotRIndex')),': %s'),Name);
            % Add responses
            addResponse(PlotHandle,HN,QN,Name=name,LineStyle=LineStyle,LineWidth=1.75);
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
            % This function is used by viewSpec_ and the Control System Tuner.
            X = getClosedLoopTransfer_(this,CL,'usample');
            [W,Q] = getWeight(this,X.Ts);
            W.TimeUnit = X.TimeUnit;
            H = W*X;
            % Regularization
            epsReg = this.Regularization;
            if epsReg>0
                nu = size(H,2);
                H = [H ; epsReg*eye(nu)];
                Q = blkdiag(Q,eye(nu));
            end
        end

        function validateGoal(this,CL)
            % Goal validation for GUI
            QN = this.Qfact_.QN;
            H = getClosedLoopTransfer_(this,CL);
            [ny,nu] = size(H);
            % Compute factorization QN = W1*W1'-W2*W2'
            [~,~,W2] = ltipack.getSectorData(QN,[]);
            if ny<nu
                error(message('Control:systunegui:ConicSector2'))
            elseif ny~=size(QN,1)
                error(message('Control:systunegui:ConicSector1'))
            elseif size(W2,2)~=nu
                error(message('Control:systunegui:ConicSector3'))
            end
        end

        function [SPEC,LoopConfigs] = getSpecData(this,SPEC,LoopConfigs,uNames,yNames,sNames,Ts)
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
            [indU,MisMatch,Usel] = ltipack.resolveSignalID(this.Input,InputNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq11',MisMatch,InputNames))
            SPEC.Input = indU;
            nu = numel(indU);
            % Locate outputs (include selected inputs as possible outputs)
            OutputNames = [yNames;sNames;Usel];
            [indY,MisMatch,Ysel] = ltipack.resolveSignalID(this.Output,OutputNames,true);
            error(resolveSignalError(this,'Control:tuning:TuningReq12',MisMatch,OutputNames))
            ny = numel(indY);
            if ny~=size(this.Qfact_.QN,1)
                error(message('Control:tuning:ConicSector3',getID(this)))
            elseif ny<nu
                error(message('Control:tuning:ConicSector4',getID(this)))
            end
            % Sector bounds often make use of inputs as outputs. Handle
            % this as a transformation on the I/O map
            [isYU,iUsel] = ismember(Ysel,Usel);
            nyu = sum(isYU);
            if nyu>0
                % Some outputs are also inputs. Assume direct feedthrough
                % U(iUsel(isYU)) -> Y(isYU)
                E = zeros(ny,nu);  E(isYU,iUsel(isYU)) = eye(nyu);
                F = zeros(ny,ny-nyu);  F(~isYU,:) = eye(ny-nyu);
                indY = indY(~isYU);
                % Warn if some analysis points were used as both input and
                % output (standard AP->AP transfer is 0 or L/(1-L), not I)
                APYU = intersect(Ysel(isYU),sNames);
                if ~isempty(APYU)
                    warning(message('Control:tuning:ConicSector2',sprintf('\n   %s',APYU{:})))
                end
            else
                E = zeros(ny,nu);  F = eye(ny);
            end
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
            % NOTE: The R-index is evaluated for the normalized QN matrix, i.e.,
            %    R = getSectorIndex(diag(S)*W*H,QN)
            % given
            %    Q(s) = (diag(S)*W(s))' * QN * (diag(S)*W(s))
            StaticQ = isempty(this.Qfact_.W);
            if StaticQ
                % Absorb scaling in transform
                S = this.Qfact_.S;
                E = lrscale(E,S,[]);  F = lrscale(F,S,[]);
                QW = this.Qfact_.QN;
            else
                % Combine scaling and spectral factor into WL weight
                [W,QW] = getWeight(this,Ts);
                [aW,bW,cW,dW] = ssdata(W);
                pWF = eig(aW);
            end
            % Compute factorization QN = W1*W1'-W2*W2'
            [~,W1,W2] = ltipack.getSectorData(QW,[]);
            if size(W2,2)~=nu
                error(message('Control:tuning:ConicSector10',getID(this)))
            end
            % Account for regularization
            epsReg = this.Regularization;
            if epsReg>0
                % H -> [H ; EPS*I]
                E = [E ; epsReg*eye(nu)];   F = [F ; zeros(nu,ny-nyu)];
                % QW -> blkdiag(QW,I)
                W1 = blkdiag(W1,eye(nu));   W2 = [W2 ; zeros(nu)];
                if ~StaticQ
                    % W -> blkdiag(W,I)
                    nxw = size(aW,1);
                    bW = [bW , zeros(nxw,nu)];
                    cW = [cW ; zeros(nu,nxw)];
                    dW = [dW zeros(ny,nu) ; zeros(nu,ny) eye(nu)];
                end
            end
            % Store data
            SPEC.Sector = struct('W1',W1,'W2',W2);
            SPEC.Transform = struct(...
                'E',struct('a',[],'b',[],'c',[],'d',E,'Poles',[]),'F',F,'G',1,'h',[]);
            if ~StaticQ
                SPEC.WL = struct('a',aW,'b',bW,'c',cW,'d',dW,'Poles',pWF);
            end
        end

    end

    methods (Static)

        function RMAX = getRmax()
            % Used in SYSTUNE rectification of R-index to prevent R=Inf
            RMAX = 1e6;
        end

        function this = loadobj(s)
            % Load filter
            if isstruct(s)
                % R2016b: Q was dependent and QData_ saved. From R2017a on,
                % save raw data rather than processed data to avoid numerical
                % discrepancies across platforms
                this = TuningGoal.ConicSector(s.Input,s.Output,s.Qdata_.Q);
                this.Focus = s.Focus;
                this.Models = s.Models;
                this.Openings = s.Openings;
                this.Name = s.Name;
            else
                this = s;
            end
        end

    end

end

