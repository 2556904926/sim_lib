classdef (Hidden) ProperOrthogonalDecompositionData < mrtool.data.AbstractData
    % Proper Orthogonal Decomposition Data Class for
    % Proper Orthogonal Decomposition Tool

    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (SetObservable)
        Method = "truncate"                      % user-selected checkbox
        Options (1,1) mor.ProperOrthogonalDecompositionOptions = mor.ProperOrthogonalDecompositionOptions()
    end

    properties (SetObservable, AbortSet)
        ComparisonPlot = "modelResponse";        % user-selected plot
        AnalysisPlot = "sigma"                   % user-selected plot
    end

    properties (Dependent, SetObservable, AbortSet)
        ReductionCriteria                        % user-selected dropdown
        ReductionValue
        ReducedOrder                             % user-selected order
        MinimumEnergy                            % user-selected energy
        MaximumError                             % user-selected error
        MaximumLoss                              % user-selected loss
    end

    properties (SetAccess=private)
        ReduceSpec
        MinimumOrder
        MaximumOrder
    end

    properties (Access=private)
        ReductionCriteria_I = "Order"
        ReducedOrder_I
        MinimumEnergy_I
        MaximumError_I
        MaximumLoss_I
    end

    %% Constructor
    methods
        function this = ProperOrthogonalDecompositionData(Target)
            arguments
                Target (1,1) mrtool.data.ModelWrapper
            end
            this = this@mrtool.data.AbstractData(Target);
            this.ReduceSpec = createReduceSpec(this);
        end
    end

    %% Get/Set
    methods
        % ComparisonPlot
        function set.ComparisonPlot(this,ComparisonPlot)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                ComparisonPlot (1,1) string {mustBeMember(ComparisonPlot,["modelResponse","absoluteError","relativeError"])}
            end
            this.ComparisonPlot = ComparisonPlot;
        end

        % AnalysisPlot
        function set.AnalysisPlot(this,AnalysisPlot)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                AnalysisPlot (1,1) string {mustBeMember(AnalysisPlot,["sigma","energy","loss"])}
            end
            this.AnalysisPlot = AnalysisPlot;
        end

        % Method
        function set.Method(this,Method)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                Method (1,1) string {mustBeMember(Method,["matchDC","truncate"])}
            end
            this.Method = Method;
        end

        % ReductionCriteria
        function ReductionCriteria = get.ReductionCriteria(this)
            ReductionCriteria = this.ReductionCriteria_I;
        end
        
        function set.ReductionCriteria(this,Criteria)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                Criteria (1,1) string {mustBeMember(Criteria,["Order","MaxError","MinEnergy","MaxLoss"])}
            end
            this.ReductionCriteria_I = Criteria;
            switch this.ReductionCriteria
                case 'MaxError'
                    this.AnalysisPlot = "sigma";
                case 'MinEnergy'
                    this.AnalysisPlot = "energy";
                case 'MaxLoss'
                    this.AnalysisPlot = "loss";
            end
        end

        % ReductionValue
        function value = get.ReductionValue(this)
            switch this.ReductionCriteria
                case 'Order'
                    value = this.ReducedOrder;
                case 'MaxError'
                    value = this.MaximumError;
                case 'MinEnergy'
                    value = this.MinimumEnergy;
                case 'MaxLoss'
                    value = this.MaximumLoss;
            end

        end

        function set.ReductionValue(this,value)
            switch this.ReductionCriteria
                case 'Order'
                    try
                        this.ReducedOrder = value;
                    catch
                        if isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                            error(message('Control:mrtool:PODErrorDoF',mat2str(this.MinimumOrder),mat2str(this.MaximumOrder)));                            
                        else
                            error(message('Control:mrtool:PODErrorOrder',mat2str(this.MinimumOrder),mat2str(this.MaximumOrder)));
                        end
                    end
                case 'MaxError'
                    try
                        this.MaximumError = value;
                    catch
                        error(message('Control:mrtool:PODErrorMaxError'));
                    end
                case 'MinEnergy'
                    try
                        this.MinimumEnergy = value;
                    catch
                        error(message('Control:mrtool:PODErrorMinEnergy'));
                    end
                case 'MaxLoss'
                    try
                        this.MaximumLoss = value;
                    catch
                        error(message('Control:mrtool:PODErrorMaxLoss'));
                    end
            end
        end

        % ReducedOrder
        function ReducedOrder = get.ReducedOrder(this)
            ReducedOrder = this.ReducedOrder_I;
        end

        function set.ReducedOrder(this,Order)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                Order (1,:) double {mustBeInteger,mrtool.data.ProperOrthogonalDecompositionData.mustBeInOrderRange(this,Order)}
            end
            newOrders = unique(Order);
            this.ReducedOrder_I = newOrders;
            [newEnergy,newError,newLoss] = convertOrderToOtherCriteria(this,newOrders);
            this.MinimumEnergy_I = newEnergy;
            this.MaximumError_I = newError;
            this.MaximumLoss_I = newLoss;
            if this.IsValid
                computeReducedSystem(this);
            end
        end

        % Maximum error
        function MaximumError = get.MaximumError(this)
            MaximumError = this.MaximumError_I;
        end

        function set.MaximumError(this,MaxError)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                MaxError (1,:) double {mustBeNonnegative}
            end
            this.MaximumError_I = unique(MaxError);
            newOrders = zeros(size(this.MaximumError));
            for ii = 1:length(newOrders)
                ind = find(this.ReduceSpec.Error<=this.MaximumError(ii),1,'first')-1;
                if isempty(ind)
                    newOrders(ii) = this.MinimumOrder;
                else
                    newOrders(ii) = ind;
                end
            end
            this.ReducedOrder_I = newOrders;
            [newEnergy,~,newLoss] = convertOrderToOtherCriteria(this,newOrders);
            this.MinimumEnergy_I = newEnergy;
            this.MaximumLoss_I = newLoss;
            if this.IsValid
                computeReducedSystem(this);
            end
        end
        
        % Minimum energy
        function MinimumEnergy = get.MinimumEnergy(this)
            MinimumEnergy = this.MinimumEnergy_I;
        end

        function set.MinimumEnergy(this,MinEnergy)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                MinEnergy (1,:) double {mustBeNonnegative}
            end
            this.MinimumEnergy_I = unique(MinEnergy);
            newOrders = zeros(size(this.MinimumEnergy));
            for ii = 1:length(newOrders)
                ind = find(this.ReduceSpec.Energy<=this.MinimumEnergy(ii),1,'first')-1;
                if isempty(ind)
                    newOrders(ii) = this.MaximumOrder;
                else
                    newOrders(ii) = ind;
                end
            end
            this.ReducedOrder_I = newOrders;
            [~,newError,newLoss] = convertOrderToOtherCriteria(this,newOrders);
            this.MaximumError_I = newError;
            this.MaximumLoss_I = newLoss;
            if this.IsValid
                computeReducedSystem(this);
            end
        end

        % Maximum loss
        function MaximumLoss = get.MaximumLoss(this)
            MaximumLoss = this.MaximumLoss_I;
        end

        function set.MaximumLoss(this,MaxLoss)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                MaxLoss (1,:) double {mustBeNonnegative}
            end
            this.MaximumLoss_I = unique(MaxLoss);
            newOrders = zeros(size(this.MaximumLoss));
            for ii = 1:length(newOrders)
                ind = find(this.ReduceSpec.Loss<=this.MaximumLoss(ii),1,'first')-1;
                if isempty(ind)
                    newOrders(ii) = this.MinimumOrder;
                else
                    newOrders(ii) = ind;
                end
            end
            this.ReducedOrder_I = newOrders;
            [newEnergy,newError,~] = convertOrderToOtherCriteria(this,newOrders);
            this.MinimumEnergy_I = newEnergy;
            this.MaximumError_I = newError;
            if this.IsValid
                computeReducedSystem(this);
            end
        end
    end

    %% Public methods
    methods
        function build(this)
            if ~this.IsValid
                try
                    validate(this.Options,this.TargetSystem);
                catch
                    this.Options.InputWeight = [];
                    this.Options.OutputWeight = [];
                end
                applyOptions(this);
                computeOrderLimits(this);
                setDefaultCriteriaValues(this);
            end
            build@mrtool.data.AbstractData(this);
        end

        function [Text,localVariables] = generateMATLABCode(this,optionalInputs)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                optionalInputs.OutputName (1,1) string = "ReducedSystem"
                optionalInputs.PlotCommand (1,1) string = "bodeplot"
                optionalInputs.IsLiveEditor (1,1) logical = false
                optionalInputs.AbsorbDelay (1,1) logical = false
            end
            Text = cell(0,1);
            localVariables = strings(0,1);
            Text = controllib.internal.codegen.appendMATLABCode(Text,['%% ' getString(message('Control:mrtool:CodegenPODTitle'))]);
            Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenPODReduceCommand'))]);
            SystemName = ltipack.createVarName(this.TargetName);
            if optionalInputs.IsLiveEditor
                SystemName = "`"+SystemName+"`";
            end
            if optionalInputs.AbsorbDelay
                Text = controllib.internal.codegen.appendMATLABCode(...
                    Text,['% ',getString(message('Control:mrtool:CodegenAbsorbDelayComment'))]);
                Text = controllib.internal.codegen.appendMATLABCode(...
                    Text,sprintf('DelayAbsorbedSystem = absorbDelay(%s);',SystemName));
                Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
                SystemName = "DelayAbsorbedSystem";
                localVariables = [localVariables;"DelayAbsorbedSystem"];
            end
            Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('R = reducespec(%s,''pod'');',SystemName));
            Text = mrtool.util.appendMATLABCodeForOptions(Text,this.ReduceSpec.Options);
            localVariables = [localVariables;"R"];
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenProcessMOR'))]);
            Text = controllib.internal.codegen.appendMATLABCode(Text,'R = process(R);');
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenGetromMOR'))]);
            reduceSysCommand = sprintf('%s = getrom(R',optionalInputs.OutputName);
            switch this.ReductionCriteria
                case 'Order'
                    if isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                        rOrder = 2*this.ReducedOrder;
                    else
                        rOrder = this.ReducedOrder;
                    end
                    reduceSysCommand = [reduceSysCommand sprintf(',Order=%s',mat2str(rOrder))];
                case 'MaxError'
                    if ~all(this.MaximumError == 0)
                        reduceSysCommand = [reduceSysCommand sprintf(',MaxError=%s',mat2str(this.MaximumError))];
                    end
                case 'MinEnergy'
                    if ~all(this.MinimumEnergy == 0)
                        reduceSysCommand = [reduceSysCommand sprintf(',MinEnergy=%s',mat2str(this.MinimumEnergy))];
                    end
                case 'MaxLoss'
                    if ~all(this.MaximumLoss == 0)
                        reduceSysCommand = [reduceSysCommand sprintf(',MaxLoss=%s',mat2str(this.MaximumLoss))];
                    end
            end
            if strcmpi(this.Method,'Truncate')
                reduceSysCommand = [reduceSysCommand sprintf(',Method=''%s'');',this.Method)];
            else
                reduceSysCommand = [reduceSysCommand ');'];
            end
            Text = controllib.internal.codegen.appendMATLABCode(Text,reduceSysCommand);
            if optionalInputs.PlotCommand ~= "none"
                Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
                Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenCreatePlot'))]);
                Text = controllib.internal.codegen.appendMATLABCode(Text,'f = figure();');
                if issparse(this.TargetSystem)
                    val = this.PlotFreqVector;
                    dval   = diff(val);
                    val10  = log10(val);
                    dval10 = diff(val10);
                    tol    = 100*eps*max(abs(val));
                    tol10  = 100*eps*max(abs(val10));
                    if all(abs(dval-dval(1))<tol)
                        freqVectorString = sprintf('%s:%s:%s',num2str(val(1)),num2str(dval(1)),num2str(val(end)));
                    elseif all(abs(dval10-dval10(1))<tol10)
                        freqVectorString = sprintf('logspace(%s,%s,%d)',num2str(val10(1)),num2str(val10(end)),length(val));
                    else
                        freqVectorString = mat2str(this.PlotFreqVector);
                    end
                    Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('h = %s(f,%s,%s,%s);',optionalInputs.PlotCommand,SystemName,optionalInputs.OutputName,freqVectorString));
                else
                    Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('h = %s(f,%s,%s);',optionalInputs.PlotCommand,SystemName,optionalInputs.OutputName));
                end
                legendcode1 = sprintf('legend(h,[''%s ('',mat2str(order(%s)),'' states)''],...',...
                    getString(message('Control:mrtool:CodegenOriginalModel')),this.TargetName);
                legendcode2 = sprintf('         [''%s ('',mat2str(order(%s)),'' states)'']);',...
                    getString(message('Control:mrtool:CodegenReducedModel')),optionalInputs.OutputName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,legendcode1);
                Text = controllib.internal.codegen.appendMATLABCode(Text,legendcode2);
                Text = controllib.internal.codegen.appendMATLABCode(Text,'h.AxesStyle.GridVisible = true;');
                localVariables = [localVariables;"f";"h"];
            end
            if ~optionalInputs.IsLiveEditor
                controllib.internal.codegen.showGeneratedMATLABCode(Text,false);
            end
        end

        % Options
        function applyOptions(this)
            oldSpec = this.ReduceSpec;
            if ~isequal(getModel(this.ReduceSpec),this.TargetSystem)
                this.ReduceSpec = createReduceSpec(this);
            end
            this.ReduceSpec.Options = this.Options;
            weakThis = matlab.lang.WeakReference(this);
            this.ReduceSpec.Options.PrintFcn = @(s) printToApp(weakThis.Handle,s);
            try
                this.ReduceSpec = process(this.ReduceSpec);
            catch ME
                this.ReduceSpec = oldSpec;
                throw(ME);
            end
        end

        function unapplyOptions(this,reduceSpec)
            this.ReduceSpec = reduceSpec;
            this.IsValid = true;
            notify(this,'ToolDataChanged')
        end

        % Load/Save Session
        function loadSessionToolData(this,SessionData)
            this.ReductionCriteria = SessionData.ReductionCriteria;
            this.ReducedOrder = SessionData.ReducedOrder;
            this.Method = SessionData.Method;
            this.ComparisonPlot = SessionData.ComparisonPlot;
            this.AnalysisPlot = SessionData.AnalysisPlot;
            this.Options = SessionData.ReduceSpec.Options;
            applyOptions(this);
            % Regenerate dependent data
            computeOrderLimits(this);
        end

        function SessionData = saveSessionToolData(this,SessionData)
            SessionData.ToolType = 'ProperOrthogonalDecomposition';
            SessionData.ReduceSpec = this.ReduceSpec;          
            SessionData.ReductionCriteria = this.ReductionCriteria;  
            SessionData.ReducedOrder = this.ReducedOrder;
            SessionData.Method = this.Method;
            SessionData.AnalysisPlot = this.AnalysisPlot;
        end
    end

    %% Protected methods
    methods (Access = protected)

        function ReducedSystem = localComputeReducedSystem(this)
            % Ignore warnings related to options
            sw = ctrlMsgUtils.SuspendWarnings;
            try
                if isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                    rOrder = 2*this.ReducedOrder;
                else
                    rOrder = this.ReducedOrder;
                end
                ReducedSystem = getrom(this.ReduceSpec,Order=rOrder,Method=this.Method);
                delete(sw);
            catch ME
                delete(sw);
                throw(ME);
            end
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function mustBeInOrderRange(this,orders)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                orders (1,:) double
            end
            mustBeInRange(orders,this.MinimumOrder,this.MaximumOrder);
        end
    end

    %% Private methods
    methods (Access=private)
        function computeOrderLimits(this)
            opt = mor.getrom.ProperOrthogonalDecompositionOptions;
            cache = getCache(this.ReduceSpec);
            [~,minOrder,maxOrder] = resolveOrder(opt,cache,isa(this.TargetSystem,'mechss'));
            this.MinimumOrder = minOrder;
            this.MaximumOrder = maxOrder;
        end

        function setDefaultCriteriaValues(this)
            INF = isinf(this.ReduceSpec.Sigma);
            g = this.ReduceSpec.Sigma(~INF,:);
            if isempty(g) || all(g==0)
                % all unstable
                this.ReducedOrder = this.MinimumOrder;
            else
                % E(r) = total energy for order=r
                E = cumsum(g.^2);
                % Pick smallest order capturing 99% of energy
                this.ReducedOrder = this.MinimumOrder + find(E>0.99*E(end),1);
            end
        end

        function ReduceSpec = createReduceSpec(this)
            ReduceSpec = reducespec(this.TargetSystem,'pod');
        end

        function printToApp(this,s)
            arguments
                this (1,1) mrtool.data.ProperOrthogonalDecompositionData
                s (1,1) string
            end
            s = strtrim(s);
            if ~isempty(s) && ~strcmp(s,'.')
                data.Msg = s;
                ed = ctrluis.toolstrip.dataprocessing.GenericEventData(data);
                notify(this,'PrintToApp',ed);
            end
        end
        
        function [newEnergy,newError,newLoss] = convertOrderToOtherCriteria(this,newOrders)
            newEnergy = zeros(size(newOrders));
            newError = zeros(size(newOrders));
            newLoss = zeros(size(newOrders));
            for ii = 1:length(newOrders)
                if newOrders(ii) == this.MinimumOrder
                    newEnergy(ii) = Inf;
                    newError(ii) = Inf;
                    newLoss(ii) = Inf;
                elseif newOrders(ii) == this.MaximumOrder
                    newEnergy(ii) = 0;
                    newError(ii) = 0;
                    newLoss(ii) = 0;
                else
                    newEnergy(ii) = this.ReduceSpec.Energy(newOrders(ii))*0.5+this.ReduceSpec.Energy(newOrders(ii)+1)*0.5;
                    newError(ii) = this.ReduceSpec.Error(newOrders(ii))*0.5+this.ReduceSpec.Error(newOrders(ii)+1)*0.5;
                    newLoss(ii) = this.ReduceSpec.Loss(newOrders(ii))*0.5+this.ReduceSpec.Loss(newOrders(ii)+1)*0.5;
                end
            end
        end
    end
end