classdef (Hidden) ModalTruncationData < mrtool.data.AbstractData
    % Modal Truncation Data Class for Modal Truncation Tool
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2023 The MathWorks, Inc. 
    
    properties (SetObservable)
        Method = "truncate"                 % user-selected checkbox
        Options (1,1) mor.ModalTruncationOptions = mor.ModalTruncationOptions()
        SparseOptions (1,1) mor.SparseModalTruncationOptions = mor.SparseModalTruncationOptions()
    end

    properties (SetObservable, AbortSet)
        FrequencyRange                     % user-selected range
        DampingRange                       % user-selected range
        MinDC                              % user-selected level
        ComparisonPlot = "modelResponse";  % user-selected plot
        AnalysisPlot = "contrib";          % user-selected plot
    end
    
    properties (SetAccess=private)
        ReduceSpec
    end

    properties (Access=private)
        MsgQueue (1,1) string
    end

    methods
        %% Constructor
        function this = ModalTruncationData(Target)
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
                this (1,1) mrtool.data.ModalTruncationData
                ComparisonPlot (1,1) string {mustBeMember(ComparisonPlot,["modelResponse","absoluteError","relativeError","modeCompare"])}
            end
            this.ComparisonPlot = ComparisonPlot;
        end

        % AnalysisPlot
        function set.AnalysisPlot(this,AnalysisPlot)
            arguments
                this (1,1) mrtool.data.ModalTruncationData
                AnalysisPlot (1,1) string {mustBeMember(AnalysisPlot,["mode","damp","contrib"])}
            end
            if this.ReduceSpec.Options.ModeOnly && AnalysisPlot == "contrib" %#ok<MCSUP>
                error(message('Control:mrtool:MTWarningDCContribUnavailable'));
            end
            this.AnalysisPlot = AnalysisPlot;
        end

        % Method
        function set.Method(this,Method)
            arguments
                this (1,1) mrtool.data.ModalTruncationData
                Method (1,1) string {mustBeMember(Method,["matchDC","truncate"])}
            end
            this.Method = Method;
        end

        % FrequencyRange
        function set.FrequencyRange(this,Range)
            arguments
                this (1,1) mrtool.data.ModalTruncationData
                Range (1,2) double {mustBeNonnegative,mrtool.data.ModalTruncationData.mustBeRange(Range)}
            end
            this.FrequencyRange = Range;
            if this.IsValid
                computeReducedSystem(this);
            end
        end

        % DampingRange
        function set.DampingRange(this,Range)
            arguments
                this (1,1) mrtool.data.ModalTruncationData
                Range (1,2) double {mustBeInRange(Range,-1,1),mrtool.data.ModalTruncationData.mustBeRange(Range)}
            end
            this.DampingRange = Range;
            if this.IsValid
                computeReducedSystem(this);
            end
        end

        % MinDC
        function set.MinDC(this,MinDC)
            arguments
                this (1,1) mrtool.data.ModalTruncationData
                MinDC (1,1) double {mustBeNonnegative}
            end
            this.MinDC = MinDC;
            if this.IsValid
                computeReducedSystem(this);
            end
        end
    end

    %% Public methods
    methods
        function build(this)
            if ~this.IsValid
                if issparse(this.TargetSystem)
                    options = this.SparseOptions;
                else
                    options = this.Options;
                end
                if any(isinf(dcgain(this.TargetSystem)),'all')
                    options.DCFrequency = 1;
                end
                [ny,nu] = iosize(this.TargetSystem);
                if ~isempty(options.InputScaling)
                    newScaling = options.InputScaling;
                    if length(options.InputScaling) > nu
                        newScaling = options.InputScaling(1:nu);
                    elseif length(options.InputScaling) < nu
                        newScaling = [options.InputScaling;ones(nu-length(options.InputScaling),1)];
                    end
                    options.InputScaling = newScaling;
                end
                if ~isempty(options.OutputScaling)
                    newScaling = options.OutputScaling;
                    if length(options.OutputScaling) > ny
                        newScaling = options.OutputScaling(1:ny);
                    elseif length(options.OutputScaling) < ny
                        newScaling = [options.OutputScaling;ones(ny-length(options.OutputScaling),1)];
                    end
                    options.OutputScaling = newScaling;
                end
                if issparse(this.TargetSystem)
                    this.SparseOptions = options;
                else
                    this.Options = options;
                end
                applyOptions(this);
                setDefaultCriteriaValues(this);
            end
            build@mrtool.data.AbstractData(this);
        end

        function [Text,localVariables] = generateMATLABCode(this,optionalInputs)
            arguments
                this (1,1) mrtool.data.ModalTruncationData
                optionalInputs.OutputName (1,1) string = "ReducedSystem"
                optionalInputs.PlotCommand (1,1) string = "bodeplot"
                optionalInputs.IsLiveEditor (1,1) logical = false
                optionalInputs.AbsorbDelay (1,1) logical = false
            end
            Text = cell(0,1);
            localVariables = strings(0,1);
            Text = controllib.internal.codegen.appendMATLABCode(Text,['%% ' getString(message('Control:mrtool:CodegenMTTitle'))]);
            Text = controllib.internal.codegen.appendMATLABCode(Text,' ');            
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenMTReduceCommand'))]);
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
            Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('R = reducespec(%s,''modal'');',SystemName));
            Text = mrtool.util.appendMATLABCodeForOptions(Text,this.ReduceSpec.Options);
            localVariables = [localVariables;"R"];
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenProcessMOR'))]);
            Text = controllib.internal.codegen.appendMATLABCode(Text,'R = process(R);');
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenGetromMOR'))]);
            reduceSysCommand = sprintf('%s = getrom(R',optionalInputs.OutputName);
            if ~isequal(this.FrequencyRange,[0 Inf])
                reduceSysCommand = [reduceSysCommand sprintf(',Frequency=%s',mat2str(this.FrequencyRange))];
            end
            if ~isequal(this.DampingRange,[-1 1])
                reduceSysCommand = [reduceSysCommand sprintf(',Damping=%s',mat2str(this.DampingRange))];
            end
            if ~this.ReduceSpec.Options.ModeOnly && this.MinDC ~= 0
                reduceSysCommand = [reduceSysCommand sprintf(',MinDC=%s',mat2str(this.MinDC))];
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
                this.ReduceSpec.Options = this.Options;
            end
            try
                this.ReduceSpec = process(this.ReduceSpec);
            catch ME
                this.ReduceSpec = oldSpec;
                throw(ME);
            end
            if this.ReduceSpec.Options.ModeOnly && strcmpi(this.AnalysisPlot,"contrib")
                this.AnalysisPlot = "mode";
            end
        end

        function unapplyOptions(this,reduceSpec)
            this.ReduceSpec = reduceSpec;
            this.IsValid = true;
            notify(this,'ToolDataChanged')
        end

        % Load/Save Session
        function loadSessionToolData(this,SessionData)
            if isfield(SessionData,'ReduceSpec')
                this.FrequencyRange = SessionData.FrequencyRange;
                this.DampingRange = SessionData.DampingRange;
                this.MinDC = SessionData.MinDC;
                this.Method = SessionData.Method;
                this.ComparisonPlot = SessionData.ComparisonPlot;
                this.AnalysisPlot = SessionData.AnalysisPlot;
                if issparse(this.TargetSystem)
                    this.SparseOptions = SessionData.ReduceSpec.Options;
                else
                    this.Options = SessionData.ReduceSpec.Options;
                end
            else
                % Pre 2024a data
                lowerCutoff = SessionData.LowerCutoff;
                upperCutoff = SessionData.UpperCutoff;
                this.FrequencyRange = [lowerCutoff upperCutoff];
                this.DampingRange = [-1 1];
                this.MinDC = 0;
                this.Method = 'truncate';
                FreqSepOptions = SessionData.Options;
                options = mor.ModalTruncationOptions();
                options.SepTol = FreqSepOptions.SepTol*1e-13;
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
                this.AnalysisPlot = "contrib";
            end
            applyOptions(this);
        end
        
        function SessionData = saveSessionToolData(this,SessionData)
            SessionData.ToolType = 'ModalTruncation';
            SessionData.ReduceSpec = this.ReduceSpec;            
            SessionData.FrequencyRange = this.FrequencyRange;
            SessionData.DampingRange = this.DampingRange;
            SessionData.MinDC = this.MinDC;
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
                if this.ReduceSpec.Options.ModeOnly
                    ReducedSystem = getrom(this.ReduceSpec,Frequency=this.FrequencyRange,Damping=this.DampingRange,Method=this.Method);
                else
                    ReducedSystem = getrom(this.ReduceSpec,Frequency=this.FrequencyRange,Damping=this.DampingRange,MinDC=this.MinDC,Method=this.Method);
                end
            catch ME
                delete(sw);
                throw(ME);
            end
            delete(sw);
        end

        function printToApp(this,s)
            arguments
                this (1,1) mrtool.data.ModalTruncationData
                s (1,1) string
            end
            s = strtrim(s);
            if ~isempty(s) && ~strcmp(s,'.')
                if contains(s,getString(message('Control:transformation:MODALROM22')))
                    this.MsgQueue = "";
                    s = s+newline;
                else % stack
                    s = this.MsgQueue+s+newline;
                end
                this.MsgQueue = s;
                data.Msg = s;
                ed = ctrluis.toolstrip.dataprocessing.GenericEventData(data);
                notify(this,'PrintToApp',ed);
            end
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function mustBeRange(Range)
            arguments
                Range (1,2) double
            end
            mustBeLessThan(Range(1),Range(2));
        end
    end

    %% Private methods
    methods (Access=private)
        function setDefaultCriteriaValues(this)
            if ~issparse(this.TargetSystem)
                [~,w] = sigma(this.TargetSystem);
            else
                w = this.PlotFreqVector;
            end
            this.FrequencyRange = mrtool.util.setSelectorFrequencyRange([w(1) w(end)]);
            this.DampingRange = [-1 1];
            g = this.ReduceSpec.DCGain;
            g = g(g~=0);
            if isempty(g)
                this.MinDC = 0;
            else
                this.MinDC = min(g)*0.999;
            end
        end

        function ReduceSpec = createReduceSpec(this)
            ReduceSpec = reducespec(this.TargetSystem,'modal');
        end
    end
end