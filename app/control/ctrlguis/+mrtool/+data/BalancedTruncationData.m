classdef (Hidden) BalancedTruncationData < mrtool.data.AbstractData
    % Balanced Truncation Data Class for Balanced Truncation Tool

    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc.

    %% Properties
    properties (SetObservable)
        Method = "truncate"                      % user-selected checkbox
        UseNCFTruncation = false                 % user-selected checkbox
        WeightStrings = ["[]" "[]"]              % derived from options
        Options (1,1) mor.BalancedTruncationOptions = mor.BalancedTruncationOptions()
        SparseOptions (1,1) mor.SparseBalancedTruncationOptions = mor.SparseBalancedTruncationOptions()
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

    properties (Dependent,SetAccess=private)
        FreqIntervalsUsed
    end

    properties (Access=private)
        ReductionCriteria_I = "Order"
        ReducedOrder_I
        MinimumEnergy_I
        MaximumError_I
        MaximumLoss_I
    end

    %% Events
    events
        FrequencyRangeChanged
    end

    %% Constructor
    methods
        function this = BalancedTruncationData(Target)
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
                this (1,1) mrtool.data.BalancedTruncationData
                ComparisonPlot (1,1) string {mustBeMember(ComparisonPlot,["modelResponse","absoluteError","relativeError"])}
            end
            this.ComparisonPlot = ComparisonPlot;
        end

        % AnalysisPlot
        function set.AnalysisPlot(this,AnalysisPlot)
            arguments
                this (1,1) mrtool.data.BalancedTruncationData
                AnalysisPlot (1,1) string {mustBeMember(AnalysisPlot,["sigma","energy","loss"])}
            end
            this.AnalysisPlot = AnalysisPlot;
        end

        % Method
        function set.Method(this,Method)
            arguments
                this (1,1) mrtool.data.BalancedTruncationData
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
                this (1,1) mrtool.data.BalancedTruncationData
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
                        error(message('Control:mrtool:BTErrorOrder',mat2str(this.MinimumOrder),mat2str(this.MaximumOrder)));
                    end
                case 'MaxError'
                    try
                        this.MaximumError = value;
                    catch
                        error(message('Control:mrtool:BTErrorMaxError'));
                    end
                case 'MinEnergy'
                    try
                        this.MinimumEnergy = value;
                    catch
                        error(message('Control:mrtool:BTErrorMinEnergy'));
                    end
                case 'MaxLoss'
                    try
                        this.MaximumLoss = value;
                    catch
                        error(message('Control:mrtool:BTErrorMaxLoss'));
                    end
            end
        end
        
        % ReducedOrder
        function ReducedOrder = get.ReducedOrder(this)
            ReducedOrder = this.ReducedOrder_I;
        end

        function set.ReducedOrder(this,Order)
            arguments
                this (1,1) mrtool.data.BalancedTruncationData
                Order (1,:) double {mustBeInteger,mrtool.data.BalancedTruncationData.mustBeInOrderRange(this,Order)}
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
                this (1,1) mrtool.data.BalancedTruncationData
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
                this (1,1) mrtool.data.BalancedTruncationData
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
                this (1,1) mrtool.data.BalancedTruncationData
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
        
        % UseNCF
        function set.UseNCFTruncation(this,Flag)
            arguments
                this (1,1) mrtool.data.BalancedTruncationData
                Flag (1,1) logical
            end
            if license('test','Robust_Toolbox') && ~isempty(ver('robust'))
                this.UseNCFTruncation = Flag;
            end
        end

        % Frequency Intervals
        function Flag = get.FreqIntervalsUsed(this)
            if isa(this.ReduceSpec,'mor.BalancedTruncation')
                Flag = ~isempty(this.ReduceSpec.Options.FreqIntervals);
            else
                Flag = false;
            end
        end
    end

    %% Public methods
    methods
        function build(this)
            if ~this.IsValid
                if issparse(this.TargetSystem)
                    if isa(this.TargetSystem,'sparss')
                        this.SparseOptions.Rayleigh = [];
                    else
                        this.SparseOptions.Offset = 0;
                    end
                else
                    if ~isempty(this.Options.InputWeight)
                        weights = ltioptions.ioweight;
                        weights.InputWeight = this.Options.InputWeight;
                        try
                            validate(weights,this.TargetSystem)
                        catch
                            this.Options.InputWeight = [];
                            this.WeightStrings(1) = "[]";
                        end
                    end
                    if ~isempty(this.Options.OutputWeight)
                        weights = ltioptions.ioweight;
                        weights.OutputWeight = this.Options.OutputWeight;
                        try
                            validate(weights,this.TargetSystem)
                        catch
                            this.Options.OutputWeight = [];
                            this.WeightStrings(2) = "[]";
                        end
                    end
                    if ~isempty(this.Options.FreqIntervals)
                        nyFreq = pi/abs(this.TargetSystem.Ts);
                        validIntervals = this.Options.FreqIntervals(:,1) < nyFreq;
                        if any(validIntervals)
                            this.Options.FreqIntervals = this.Options.FreqIntervals(validIntervals,:);
                            this.Options.FreqIntervals = min(this.Options.FreqIntervals,nyFreq);
                        else
                            this.Options.FreqIntervals = [];
                        end
                    end
                end
                applyOptions(this);
                computeOrderLimits(this);
                setDefaultCriteriaValues(this);
            end
            build@mrtool.data.AbstractData(this);
        end

        function [Text,localVariables] = generateMATLABCode(this,optionalInputs)
            arguments
                this (1,1) mrtool.data.BalancedTruncationData
                optionalInputs.OutputName (1,1) string = "ReducedSystem"
                optionalInputs.PlotCommand (1,1) string = "bodeplot"
                optionalInputs.IsLiveEditor (1,1) logical = false
                optionalInputs.AbsorbDelay (1,1) logical = false
            end
            Text = cell(0,1);
            localVariables = strings(0,1);
            Text = controllib.internal.codegen.appendMATLABCode(Text,['%% ' getString(message('Control:mrtool:CodegenBTTitle'))]);
            Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenBTReduceCommand'))]);
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
            if this.UseNCFTruncation && ~issparse(this.TargetSystem)
                Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('R = reducespec(%s,''ncf'');',SystemName));
            else
                Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('R = reducespec(%s,''balanced'');',SystemName));
                Text = mrtool.util.appendMATLABCodeForOptions(Text,this.ReduceSpec.Options,this.WeightStrings);
            end
            localVariables = [localVariables;"R"];
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenProcessMOR'))]);
            Text = controllib.internal.codegen.appendMATLABCode(Text,'R = process(R);');
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenGetromMOR'))]);
            reduceSysCommand = sprintf('%s = getrom(R',optionalInputs.OutputName);
            switch this.ReductionCriteria
                case 'Order'
                    reduceSysCommand = [reduceSysCommand sprintf(',Order=%s',mat2str(this.ReducedOrder))];
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
            if strcmpi(this.Method,'Truncate') && (~this.UseNCFTruncation || issparse(this.TargetSystem))
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
            Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
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
            if issparse(this.TargetSystem)
                this.ReduceSpec.Options = this.SparseOptions;
                weakThis = matlab.lang.WeakReference(this);
                this.ReduceSpec.Options.PrintFcn = @(s) printToApp(weakThis.Handle,s);
            else
                if (this.UseNCFTruncation && isa(this.ReduceSpec,'mor.BalancedTruncation')) ||...
                    (~this.UseNCFTruncation && isa(this.ReduceSpec,'mor.NCFBalancedTruncation'))
                    this.ReduceSpec = createReduceSpec(this);
                end
                if ~isa(this.ReduceSpec,'mor.NCFBalancedTruncation')
                    this.ReduceSpec.Options = this.Options;
                end
            end
            try
                this.ReduceSpec = process(this.ReduceSpec);
            catch ME
                this.ReduceSpec = oldSpec;
                throw(ME);
            end
            notify(this,'FrequencyRangeChanged')
        end

        function unapplyOptions(this,reduceSpec)
            this.ReduceSpec = reduceSpec;
            this.IsValid = true;
            notify(this,'ToolDataChanged')
        end

        % Load/Save Session
        function loadSessionToolData(this,SessionData)
            if isfield(SessionData,'ReduceSpec')
                this.ReductionCriteria = SessionData.ReductionCriteria;
                this.ReducedOrder = SessionData.ReducedOrder;
                this.WeightStrings = SessionData.WeightStrings;
                this.Method = SessionData.Method;
                this.UseNCFTruncation = SessionData.UseNCFTruncation;
                this.ComparisonPlot = SessionData.ComparisonPlot;
                if issparse(this.TargetSystem)
                    this.SparseOptions = SessionData.ReduceSpec.Options;
                elseif ~isempty(SessionData.ReduceSpec.Options)
                    this.Options = SessionData.ReduceSpec.Options;
                end
                notify(this,'FrequencyRangeChanged')
            else
                % Pre 2024a data
                this.ReductionCriteria = "Order";
                this.ReducedOrder = SessionData.ReducedOrder;
                this.WeightStrings = ["[]" "[]"];
                this.UseNCFTruncation = false;
                BalredOptions = SessionData.Options;
                if isfield(SessionData,'isFrequencyRangeSelected') && SessionData.isFrequencyRangeSelected
                    % Before 2021a, frequency range data was stored outside options
                    BalredOptions.FreqIntervals = SessionData.FrequencyRange;
                end
                this.Method = BalredOptions.StateProjection;
                options = mor.BalancedTruncationOptions();
                options.Algorithm = BalredOptions.ErrorBound;
                options.Regularization = BalredOptions.Regularization;
                options.FreqIntervals = BalredOptions.FreqIntervals;
                options.TimeIntervals = BalredOptions.TimeIntervals;
                options.SepTol = BalredOptions.SepTol;
                options.Offset = BalredOptions.Offset;
                this.Options = options;
                switch find(SessionData.Visualizations)
                    case 1
                        comparisonPlot = "modelResponse";
                    case 2
                        comparisonPlot = "absoluteError";
                    case 3
                        comparisonPlot = "relativeError";
                end
                this.ComparisonPlot = comparisonPlot;
            end
            applyOptions(this);
            % Regenerate dependent data
            computeOrderLimits(this);
        end

        function SessionData = saveSessionToolData(this,SessionData)
            SessionData.ToolType = 'BalancedTruncation';
            SessionData.ReduceSpec = this.ReduceSpec;          
            SessionData.ReductionCriteria = this.ReductionCriteria;  
            SessionData.ReducedOrder = this.ReducedOrder;
            SessionData.Method = this.Method;
            SessionData.UseNCFTruncation = this.UseNCFTruncation;
            SessionData.WeightStrings = this.WeightStrings;
        end

        function alpha = getRegularization(this)
            if isa(this.ReduceSpec,'mor.BalancedTruncation') && ~strcmpi(this.ReduceSpec.Options.Regularization,'auto')
                alpha = this.ReduceSpec.Options.Regularization;
            else
                alpha = getRegularization@mrtool.data.AbstractData(this);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function ReducedSystem = localComputeReducedSystem(this)
            % Ignore warnings related to options
            sw = ctrlMsgUtils.SuspendWarnings;
            try
                if isa(this.ReduceSpec,'mor.NCFBalancedTruncation')
                    % NCF does not use Method
                    ReducedSystem = getrom(this.ReduceSpec,Order=this.ReducedOrder);
                else
                    ReducedSystem = getrom(this.ReduceSpec,Order=this.ReducedOrder,Method=this.Method);
                end
            catch ME
                delete(sw);
                throw(ME);
            end
            delete(sw);
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function mustBeInOrderRange(this,orders)
            arguments
                this (1,1) mrtool.data.BalancedTruncationData
                orders (1,:) double
            end
            mustBeInRange(orders,this.MinimumOrder,this.MaximumOrder);
        end
    end

    %% Private methods
    methods (Access=private)
        function computeOrderLimits(this)
            opt = mor.getrom.BalancedTruncationOptions;
            cache = getCache(this.ReduceSpec);
            [~,minOrder,maxOrder] = resolveOrder(opt,cache,false);
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
                this.ReducedOrder = min(this.MinimumOrder + find(E>0.99*E(end),1),this.MaximumOrder);
            end
        end

        function ReduceSpec = createReduceSpec(this)
            if this.UseNCFTruncation && ~issparse(this.TargetSystem)
                ReduceSpec = reducespec(this.TargetSystem,'ncf');
            else
                ReduceSpec = reducespec(this.TargetSystem,'balanced');
            end
        end

        function printToApp(this,s)
            arguments
                this (1,1) mrtool.data.BalancedTruncationData
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