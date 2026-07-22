classdef SimulinkArchitecture < ctrlguis.csdesignerapp.data.architectures.internal.AbstractArchitecture
    % Simulink Architecture for Control System Designer
    
    % Copyright 2014-2017 The MathWorks, Inc.
    
    % Private properties
    properties (Access = private)
        Data  % SLTUNER
        OPPicker
        LocalWorkspace
        BaseWorkspace
        ModelICViewer
        Tool
    end
    
    
    %% Implementation of Abstract Methods
    % Public : Implementation of Abstract Methods
    methods (Access = public)
        function b = isSimulink(this) %#ok<MANU>
            % Return true if architecture is simulink
            b = true;
        end
        
        function Config = getConfiguration(this)
            % Returns Configuration number
            % Simulink configuration is 0
            Config = 0;
        end
        
        function S = saveSession_(this,S)
            % SLTuner
            S.Data = this.Data;
            S.OPselection = [];
            if ~isempty(this.OPPicker)
                S.OPselection = saveSelection(this.OPPicker);
            end
        end
        
        function loadSession_(this,S)
            op_picker = getOPPicker(this);
            if ~isempty(op_picker) && ~isempty(S.OPselection)
                loadSelection(op_picker,S.OPselection);
            end
        end
        
        function CopiedArch = copyArch(this)
            CopiedArch = ctrlguis.csdesignerapp.data.architectures.internal.SimulinkArchitecture(this.Data);
            TB = getTunedBlocks(this);
            TBCopy = getTunedBlocks(CopiedArch);
            for ct=1:numel(TB)
               TBCopy(ct).setValue(TB(ct).getValue, 'NoEvent');
            end
        end
        
        function [Signals,ExpandedSignalList] = getAvailableSignals(this,~)
            if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.Name))
                load_system(this.Name);
            end
            % Return available signals for inputs outputs and locations
            Signals = getPoints(this.Data);
            Signals = unique(Signals);
            try
                ExpandedSignalList = getPointExpandedNames(this.Data);
            catch Ex
                % getPointExpandedNames converts to genss
                % if this fails, assume signals are added as (All)
                if isequal(Ex.identifier,'Slcontrol:linutil:ZOHD2CPoleAtZero') || ...
                        isequal(Ex.identifier,'Slcontrol:sltuner:GenssNoPoint')
                    ExpandedSignalList = Signals;
                elseif isequal(Ex.identifier,'SLControllib:opcond:OperatingPointNeedsUpdate')
                    % Update SLTuner OP if needed
                    arrayfun(@(x) update(x),this.Data.OperatingPoints);
                    ExpandedSignalList = getPointExpandedNames(this.Data);
                else
                    error(Ex.message);
                end
            end
            
        end
        function C = getSeriesCompensators(this,Definition,hasFeedback)
            if hasFeedback
                C = findSISOLoopBlocks(this.Data,Definition.Location,Definition.Openings);
            else
                C = findSISOPathBlocks(this.Data,Definition.Input,Definition.Output,Definition.Openings);
            end
            if isempty(C)
                % findSISOBlocks returns an empty cell array. Convert from
                % cell to double for further processing
                C = [];
            else
                SLTunableBlocks = this.Data.getSLTunableBlocks;
                TB = this.TunedBlocks;
                
                [b,idx]=ismember(C,{SLTunableBlocks.BlockPath});
                if b
                    C = TB(ismember(TB.getIdentifier,{SLTunableBlocks(idx).Name}));
                else
                    C = [];
                end
            end
        end
        %%
        function setLinearizationOptions(this, Options)
            try
                InitialOptions = this.Data.Options;
                this.Data.Options = Options;
                propagateSampleTime(this,InitialOptions.SampleTime);
                this.isDirty = true;
            catch ME
                this.Data.Options = InitialOptions;
                rethrow(ME);
            end
        end
        
        function propagateSampleTime(this, InitialTs)
            if strcmpi(this.Data.Options.RateConversionMethod,'prewarp')
                RateConversionMethod = {'prewarp', this.Data.Options.PreWarpFreq};
            else
                RateConversionMethod = {this.Data.Options.RateConversionMethod};
            end
            NewTs = this.Data.Options.SampleTime;
            SampleTimeChanged = ~isequal(NewTs,InitialTs);
            % Determine target domain
            if InitialTs == 0
                ToContinuous = false;
            else
                ToContinuous = isequal(NewTs,0);
            end
            if ToContinuous
                % D2C conversion
                ConvertFcn = 'd2c';
                Args = RateConversionMethod;
            else
                % C2D or D2D conversion
                Args(:,1) = {NewTs};
                if InitialTs,
                    % D2D conversion
                    ConvertFcn = 'd2d';
                    Args = [Args,RateConversionMethod];
                else
                    ConvertFcn = 'c2d';
                    Args = [Args,RateConversionMethod];
                end
            end
            for ct=1:numel(this.TunedBlocks)
%                 Value = this.TunedBlocks(ct).getValue;

                this.TunedBlocks(ct).C2DMethod = RateConversionMethod;
                this.TunedBlocks(ct).D2CMethod = RateConversionMethod;
                this.TunedBlocks(ct).Ts = NewTs;
                updateZPK(this.TunedBlocks(ct));
                
%                 if SampleTimeChanged
%                     if isTunable(this.TunedBlocks(ct))
%                         if isequal(NewTs,this.TunedBlocks(ct).TsOrig) && ~isempty(this.TunedBlocks(ct).getParameters)
%                             updateZPK(this.TunedBlocks(ct));
%                         else
%                             Value = feval(ConvertFcn,Value,Args{:});
%                             setValue(this.TunedBlocks(ct), Value, 'NoEvent');
%                         end
%                     elseif ~isempty(this.TunedBlocks(ct).getParameters)
%                         updateZPK(this.TunedBlocks(ct));
%                     end
%                 end
            end
            this.isDirty = true;
        end
        function Options = getLinearizationOptions(this)
            Options = this.Data.Options;
        end
        function Params = getParameters(this)
            Params = this.Data.Parameters;
        end
        function OPs = getOperatingPoints(this)
            OPs = this.Data.OperatingPoints;
        end
        function setOperatingPoints(this,op)
            this.Data.OperatingPoints = op;
            this.isDirty = true;
        end
        function setParameters(this,params)
            this.Data.Parameters = params;
        end
        function setOPPicker(this,OPPicker)
            this.OPPicker = OPPicker;
        end
        function OPPicker = getOPPicker(this)
            % if isempty(this.OPPicker)
            %     this.OPPicker = slctrlguis.lintool.widgets.OPPickerPanel(this, true);
            % end
            OPPicker = this.OPPicker;
        end
        function P = getOpenLoopPlant(this,TB,Openings,Input,Output)
            % REVISIT
            CL = this.System;
            S = CL.Blocks;
            AllBlocks = getTunedBlocks(this);
            BlocksNotInSeries = setdiff(AllBlocks,TB);
            for ct=1:length(BlocksNotInSeries)
                S.(getIdentifier(BlocksNotInSeries(ct))) = getValue(BlocksNotInSeries(ct));
            end
            for ct = 1:length(TB)
                %                 append(getValue(TB(ct)));
                S.(getIdentifier(TB(ct))) = 1;
            end
            sys = replaceBlock(CL,S);
            if nargin==5
                P = getIOTransfer(sys,Input,Output,Openings);
            else
                P = getLoopTransfer(sys,getPath(TB),Openings);
            end
        end
        function validateFixedBlocks(this)
            %             sys = P.Value;
            %             if ~isa(sys,'ss')
            %                 ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck07')
            %             elseif ~isreal(sys)
            %                 ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck08')
            %             end
            %
            %             % Check dimensions
            %             sizes = size(sys);
            %             if prod(sizes(3:end))~=1
            %                 ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck05')
            %             elseif any(sizes<=nC)
            %                 ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck09',nC+1)
            %             end
            %
        end
        
        function validateSampleTime(this)
            % Checks sample time and time unit consistency
            
            %             % Gather all models
            %             nG = 0;
            %             nC = length(this.TunedBlocks);
            %             AllModels = cell(nG+nC,1);
            %             for ct=1:nC
            %                 C = this.TunedBlocks(ct).getValue;
            %                 AllModels{nG+ct} = C;
            %             end
            %
            %             % Reconcile plant/sensor/prefilter/compensator sample times and time units
            %             % RE: The overall sample time is stored as this.Compensator.Ts
            %             try
            %                 [AllModels{1:nG+nC}] = matchSamplingTimeN(AllModels{:});
            %                 Ts = abs(AllModels{1}.Ts);
            %                 for ct=1:nC
            %                     CurrentValue = this.TunedBlocks(ct).getValue;
            %                     if CurrentValue.Ts ~=Ts
            %                         this.TunedBlocks(ct).setValue(AllModels{nG+ct});
            %                     end
            %                 end
            %             catch ME
            %                 ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck11')
            %             end
            
        end
        function sys = genss(this)
            load_system(this.Name);
            if isempty(this.Data) || isempty(this.Data.getPoints)
                sys = ss(1);
            else
                try
                    sys = genss(this.Data);
                catch ex
                    if strcmp(ex.identifier,'SLControllib:opcond:OperatingPointNeedsUpdate')
                        % Update OPPicker selection
                        LocalUpdateWorkspaceOP(this);
                        % Update SLTuner OP
                        arrayfun(@(x) update(x),this.Data.OperatingPoints);
                        % genss
                        sys = genss(this.Data);
                        % Throw warning dialog
                        mdlname = getModel(this);
                        warningText = getString(message('Control:designerapp:strUpdateOperatingPoint',mdlname));
                        warningTitle = getString(message('Control:designerapp:strUpdateOperatingPointDialogTitle'));
                        warndlg(warningText,warningTitle);                    
                    else
                        error(ex.message);
                    end
                end
            end
        end
        function LS = getLoopSign(this)
            LS = -1;
        end
    end
    % Protected : Implementation of Abstract Methods
    methods (Access = protected)
        function computeClosedLoop(this)
            if ~isempty(getPoints(this.Data))
                this.System = genss(this);
            end
        end
    end
    
    %% Public Methods
    methods (Access = public)
        
        function this = SimulinkArchitecture(hSLTuner)
            % Constructor takes in a slTuner object
            % Make copy since its a handle object and we dont want slTuner
            % object to be modified outside of tool
            w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
            this.Data = copy(hSLTuner);
            warning(w);
            % If the model is not compiled
            %             if strcmp(get_param(hSLTuner.Model,'SimulationStatus'),'stopped')
            %                 set_param(hSLTuner.Model, 'AnalyticLinearization', 'on');
            %                 feval(hSLTuner.Model, [], [], [], 'lincompile');
            %             end
            %                 io = getlinio(bdroot);
            %             J=linearize.jacobian.create(bdroot,linearize.createIOSpecStructure(io));
            %             Js = J.getJacobianStructure;
            %             [M,F,G] = linearize.jacobian.getBlockBasedGraph(Js);
            %             this.ConfigurationGraph = struct('AdjacencyMatrix',M, ...
            %                 'Locations',struct('Input',F,...
            %                 'Output',G), ...
            %                 'BlockNames',getfullname(Js.Mi.BlockHandles));
            %
            %             feval(bdroot, [], [], [], 'term');
            
            
            % Create tuned blocks
            TunedBlocks = getSLTunableBlocks(this.Data);
            
            if isempty(TunedBlocks)
                BlockID = {};
                this.isDirty = true;
            else
                BlockID = {TunedBlocks.BlockPath}';
            end
            addTunableBlock(this,BlockID);
            
            
            this.Name = this.Data.Model;
        end
        
        function Blocks = getFixedBlocks(this,ID) %#ok<INUSD>
            Blocks = [];
            if nargin == 2
                error(message('Controllib:general:UnexpectedError', ...
                    'No Block with the specified ID found'));
            end
        end
        
        function Value = getBlockValue(this, ID)
            Value = [];
            [DoesExist, Idx] = findTunedBlock(this, ID);
            if DoesExist
                Value = getValue(this.TunedBlocks(Idx));
                Value.Ts = this.Data.Ts;
            end
        end
        
        function setBlockValue(this, ID, Value)
            try
                % Push value to slTuner - checks if sample time of value is
                % compatible with slTuner sample time.
                setBlockValue(this.Data, ID, Value);
                Blk = getBlockValue(this.Data, ID);
                BlkName = Blk.Name;
                [DoesExist, Idx] = findTunedBlock(this, BlkName);
                
                if DoesExist
                    % Update the tuned block
                    this.TunedBlocks(Idx).setValue(Value);
                end
                this.isDirty = true;
            catch ME
                error(ME.message);
            end
        end
        
        function addTunableBlock(this, BlockID)
            try
                if ~isempty(BlockID)
                    w = warning('off','Slcontrol:sltuner:AddBlockMakesNonUnique');
                    if ~iscell(BlockID)
                        BlockID = {BlockID};
                    end
                    for ct = 1:numel(BlockID)
                        T = controllib.app.managers.eventmanager.internal.FunctionTransaction('Compensator Added');
                        addBlock(this.Data, BlockID{ct});
                        BlkValue = getBlockValue(this.Data, BlockID{ct});
                        [DoesExist, ~] = findTunedBlock(this, BlkValue.Name);
                        if ~DoesExist
                            % Create Tuned Block
                            TB = createSLTunedBlock(this, BlockID{ct});
                            weakThis = matlab.lang.WeakReference(this);
                            addlistener(TB,'ValueChanged',@(es,ed) setArchitectureDirty(weakThis.Handle,true));
                            addlistener(TB,'GainChanged',@(es,ed) setArchitectureDirty(weakThis.Handle,true));
                            this.TunedBlocks = [this.TunedBlocks; TB];
                        end
                    end
                    T.UndoFcn = {@LocalRemoveBlock this this.TunedBlocks(end).getPath};
                    T.RedoFcn = {@LocalAddBlock this this.TunedBlocks(end).getPath};
                    if ~isempty(this.Tool)
                        record(this.Tool.getEventManager, T);
                    end
                    addSignal(this,BlockID);
                    
                    warning(w);
                    this.isDirty = true;
                    
                    ed = ctrlguis.csdesignerapp.data.internal.ListEventData('add', this.TunedBlocks(end-numel(BlockID)+1:end));
                    this.notify('SystemChanged');
                    this.notify('TunedBlockListChanged',ed);
                end
            catch ME
                warning(w);
                throw(ME);
            end
        end
        
        function removeBlock(this, TunedBlocks)
            for ct = 1: size(TunedBlocks,1)
                try
                    Paths = arrayfun(@(x)getPath(x), [this.getTunedBlocks],'UniformOutput',false);
                    % Update the tuned block
                    if ischar(TunedBlocks(ct,:))
                        Path =  TunedBlocks(ct,:);
                    else
                        Path = TunedBlocks(ct,:).getPath;
                    end
                    
                    [b,idx] = ismember(Path,Paths);
                    if b
                        S = saveSession(this.TunedBlocks(idx));
                        
                        T = controllib.app.managers.eventmanager.internal.FunctionTransaction('Compensator Removed');
                        T.UndoFcn = {@LocalAddBlock this this.TunedBlocks(idx).getPath S};
                        T.RedoFcn = {@LocalRemoveBlock this this.TunedBlocks(idx).getPath};
                        
                        TBPath = Paths(idx);
                        delete(this.TunedBlocks(idx))
                        this.TunedBlocks(idx) = [];
                        
                        if ~isempty(this.Tool)
                            record(this.Tool.getEventManager, T);
                        end
                        
                        % remove from data
                        removeBlock(this.Data, TBPath);
                        this.isDirty = true;
                        this.notify('SystemChanged');
                        ed = ctrlguis.csdesignerapp.data.internal.ListEventData('remove', TBPath);
                        this.notify('TunedBlockListChanged',ed);
                    end
                catch ME
                    error(ME.message);
                end
            end
        end
        
        function addSignal(this, SignalID)
            try
                addPoint(this.Data, SignalID);
                this.isDirty = true;
                this.notify('SystemChanged');
            catch ME
                error(ME.message);
            end
        end
        
        function removeSignal(this, SignalID)
            try
                removePoint(this.Data, SignalID);
                this.isDirty = true;
                this.notify('SystemChanged');
            catch ME
                error(ME.message);
            end
        end
        
        function [Names, Points] = getPoints(this)
            [Names, Points] = getPoints(this.Data);
        end
        
        function Point = resolveSignalID(this,ID,varargin)
            if nargin == 3 && strcmpi(varargin{1},'Openings')
                % Openings
                Points = getOpenings(this.Data);
                idx = slLinearizer.resolveSignalID(ID,Points);
                Point = getOpening(this.Data,idx);
            else
                Points = getPoints(this.Data);
                idx = slLinearizer.resolveSignalID(ID,Points);
                Point = getPoint(this.Data,idx);
            end
        end
        
        function syncFromModel(this)
            for ct = 1:numel(this.Data.Blocks)
                setBlockParam(this.Data.Blocks(ct));
            end
            this.isDirty = true;
            this.notify('SystemChanged');
        end
        
        function SignalNames = refreshSignalNames(this)
            Pts = getPoints(this.Data);
            SignalNames = Pts;
            for ct = 1:numel(Pts)
                p = getPoint(this.Data, ct);
                ph = getPortHandle(p);
                SignalNames{ct} = slcontrollib.internal.utils.getUniqueSignalName(ph);
            end
            this.isDirty = true;
            this.notify('SystemChanged');
        end
        
        function Openings = getOpenings(this)
            Openings = getOpenings(this.Data);
        end
        
        function addOpening(this, OpeningName)
            try
                addOpening(this.Data, OpeningName);
                this.isDirty = true;
                this.notify('SystemChanged');
            catch ME
                error(ME.message);
            end
        end
        
        function removeOpening(this, OpeningName)
            try
                removeOpening(this.Data, OpeningName);
                this.isDirty = true;
                this.notify('SystemChanged');
            catch ME
                error(ME.message);
            end
        end
        
        function BP = getBlockPath(this, BlockName)
            Paths = {};
            Names = {};
            Blocks = getSLTunableBlocks(this.Data);
            for ct = 1:numel(Blocks)
                Names{ct} = Blocks(ct).Name;
                Paths{ct} = Blocks(ct).BlockPath;
            end
            
            if nargin==1
                BP = Paths;
            else
                [b, ix] = ismember(BlockName, Names);
                if b
                    BP = Blocks(ix).BlockPath;
                else
                    BP = [];
                end
            end
        end
        
        function bool = hasFeedbackLoop(this, BlkID)
            [bool,idx] = ismember(BlkID,arrayfun(@(x)x.Name,getSLTunableBlocks(this.Data),'UniformOutput',false));
            if bool
                this.Data.addPoint(this.Data.TunedBlocks(idx));
                BlocksInPath = this.Data.findSISOLoopBlocks(this.Data.TunedBlocks(idx));
                bool = ismember(this.Data.TunedBlocks(idx),BlocksInPath);
            end
        end
        
        function updateSimulinkBlock(this,Blocks)
            if nargin == 1
                Blocks = getTunedBlocks(this);
            end
            
            % Update the block parameters
            % REVISIT: Throw dialog with output of list?
            TaskOptions = struct('UseFullPrecision',true,'CustomPrecision','10');
            try
                List = ctrlguis.csdesignerapp.utils.internal.updateBlockParameters(Blocks,TaskOptions);
            catch ME
                error(ME.message);
            end
        end
        
        function Icon = getArchitectureIcon(this)
            % REVISIT
            Icon = [];
        end
        
        function [bool,nOp,nParam] = isParamCompatible(this,param)
            [bool,nOp,nParam] = this.isOpParamCompatible(this.getOperatingPoints,param);
        end
        
        function [bool,nOp,nParam] = isOpCompatible(this,op)
            [bool,nOp,nParam] = this.isOpParamCompatible(op,this.Data.Parameters);
        end
        
        function [bool,nOp,nParam] = isOpParamCompatible(this,op,param)
            % either op is equal to (length 1 or empty) or params is equal to empty
            % or lengths of op and params are equal
            nOp = length(op);
            if isempty(param)
                nParam = 0;
            else
                nParam = length(param(1).Value);
            end
            
            bool = (nOp<=1) || (nParam==0) || (nOp == nParam);
        end
        
        function System = convertToSystemWithShortNames(this,System)
            CurrentSystem = System;
            try
                LongInputNames = System.InputName;
                LongOutputNames = System.OutputName;
                LongNames = {LongInputNames{:} LongOutputNames{:}}';
                SLTunerLongNames = strtok(LongNames, '(');
                AvailableSignals = getPointNames(this.Data);
                ShortNames = cell(size(SLTunerLongNames));
                for ct = 1:numel(SLTunerLongNames)
                    idx = find(strcmp(SLTunerLongNames{ct},AvailableSignals));
                    if isempty(idx)
                        error('Cannot find signal %s in the model', SLTunerLongNames{ct});
                    else
                        p = getPoint(this.Data,idx);
                        ph = getPortHandle(p);
                        bph = get_param(p.Block, 'PortHandles');
                        if isempty(get(ph, 'Name'))
                            % If the signal is not named, use the block's name
                            ShortNames{ct} = slcontrollib.internal.utils.getUniqueBlockName(p.Block);
                            % If the block has more than one outpout port,
                            % append the port number to the name
                            if numel(bph.Outport) > 1
                                ShortNames{ct} = sprintf('%s/%d',ShortNames{ct},p.PortNumber);
                            end
                        else
                            % If the signal is named, use the signal name
                            ShortNames{ct} = slcontrollib.internal.utils.getUniqueSignalName(ph);
                        end
                        % Handle bus elements
                        if ~isempty(p.BusElement)
                            ShortNames{ct} = sprintf('%s/[%s]',ShortNames{ct},p.BusElement);
                        end
                        % Handle vector valued signals
                        if ~strcmp(LongNames{ct}, SLTunerLongNames{ct})
                            [~,Remain] = strtok(LongNames{ct}, '(');
                            ShortNames{ct} = sprintf('%s%s', ShortNames{ct}, Remain);
                        end
                    end
                end
                % The first set of signals are the input names
                ShortInputNames = {ShortNames{1:numel(LongInputNames)}}';
                % The last set of signals are the output names
                ShortOutputNames = {ShortNames{numel(LongInputNames)+1:end}}';
                System.InputName = ShortInputNames;
                System.OutputName = ShortOutputNames;
            catch
                System = CurrentSystem;
            end
        end
        
    end
    
    %% Private Methods
    methods (Access = private)
        function TunedBlocks = createSLTunedBlock(this,BlockPaths)
            
            % REVISIT Need to handle case of custom config functions, this should
            % really be done in the blockconfig side
            %  if strcmp(blockhandle.BlockType,'SubSystem') && ...
            %              ~isempty(blockhandle.SCDConfigFcn)
            
            BlockConfigs = getSLTunableBlocks(this.Data);
            [~,idx] = ismember(BlockPaths,{BlockConfigs.BlockPath}');
            if isempty(idx)
                
            else
                % Create the TunedBlock objects
                for ct = 1: length(idx)
                    if isa(BlockConfigs(idx(ct)), 'controldesign.blockconfig.CustomBlockConfiguration')
                        try
                            blockhandle = get_param(BlockConfigs(idx(ct)).BlockPath, 'Object');
                            blockfcn = blockhandle.SCDConfigFcn;
                            if strcmp(blockhandle.BlockType,'SubSystem') && ...
                                    ~isempty(blockfcn)
                                parameterdata = blockhandle.MaskWSVariables;
                                for ct2 = length(parameterdata):-1:1
                                    % If the parameter is not double valued make it
                                    % non-tunable
                                    if isa(parameterdata(ct2).Value,'double')
                                        parameterdata(ct2).Tunable = 'on';
                                    else
                                        parameterdata(ct2).Tunable = 'off';
                                    end
                                end
                                BlockStruct = feval(blockfcn,BlockConfigs(idx(ct)).BlockPath,parameterdata);
                                InitialValue = ss(BlockConfigs(idx(ct)).Parameterization);
                            end
                        catch ConfigFunctionNotFoundException
                            if strcmp(ConfigFunctionNotFoundException.identifier,'MATLAB:UndefinedFunction')
                                ctrlMsgUtils.error('Slcontrol:controldesign:ConfigFunctionNotFound',blockfcn,BlockConfigs(idx(ct)).BlockPath)
                            else
                                throwAsCaller(ConfigFunctionNotFoundException)
                            end
                        end
                    else
                        BlockStruct = getBlockStructure(BlockConfigs(idx(ct)));
                        InitialValue = getValue(BlockConfigs(idx(ct)),BlockConfigs(idx(ct)).Ts);
                    end
                    if isempty(BlockStruct.InvFcn)
                        TunedBlocks(ct) = ctrlguis.csdesignerapp.data.architectures.internal.TunedMask(BlockConfigs(idx(ct)).Name,...
                            InitialValue);
                        TunedBlocks(ct).Ts = InitialValue.Ts;
                    else
                        TunedBlocks(ct) = ctrlguis.csdesignerapp.data.architectures.internal.TunedLTI(BlockConfigs(idx(ct)).Name,...
                            InitialValue);
                    end
                    setFormat(TunedBlocks(ct),this.Format);
                    Options = this.Data.Options;
                    RateConversionMethod = {Options.RateConversionMethod, Options.PreWarpFreq};
                    intializeWithBlockConfig(TunedBlocks(ct),BlockConfigs(idx(ct)),RateConversionMethod,BlockStruct);
                    TunedBlocks(ct).updateZPK
%                     % Set value is needed here to update fixed dynamics based on
%                     % parameters
%                     if TunedBlocks(ct).isTunable && isequal(InitialValue.Ts,TunedBlocks(ct).TsOrig)
%                         setValue(TunedBlocks(ct),zpkTuned);
%                     end
                    
                end
            end
            
        end
    end
    
    %% Hidden Methods
    methods (Access = public, Hidden = true)
        function C = qeGetData(this)
            C = this.Data;
        end
        function Data = getData(this)
            Data = this.Data;
        end
    end
    
    methods (Hidden = true)
        %% Required by OPPicker
        function setWorkspace(this,LocalWorkspace,BaseWorkspace)
            this.LocalWorkspace = LocalWorkspace;
            this.BaseWorkspace = BaseWorkspace;
        end
        
        function WS = getLocalWorkspace(this)
            WS = this.LocalWorkspace;
        end
        
        function WS = getBaseWorkspace(this)
            WS = this.BaseWorkspace;
        end
        
        function Name = getLocalWorkspaceName(this)
            Name = ctrlMsgUtils.message('Control:designerapp:LocalWorkspaceName');
        end
        
        function Name = getBaseWorkspaceName(this)
            Name = this.BaseWorkspace.Name;
        end
        
        % variables access
        function vars = getLocalOperatingPoints(this)
            lwks = this.LocalWorkspace;
            vars = slctrlguis.lintool.getVariablesOfType(lwks,'opcond.OperatingPoint');
            vars = [vars;slctrlguis.lintool.getVariablesOfType(lwks,'opcond.OperatingReport')];
            % Eliminate those at other models
            vars = LocalEliminateOpForOtherModels(vars,getName(this));
        end
        
        function vars = getBaseOperatingPoints(this)
            bwks = this.BaseWorkspace;
            vars = slctrlguis.lintool.getVariablesOfType(bwks,'opcond.OperatingPoint');
            vars = [vars;slctrlguis.lintool.getVariablesOfType(bwks,'opcond.OperatingReport')];
            % Eliminate those at other models
            vars = LocalEliminateOpForOtherModels(vars,getName(this));
        end
        
        % approve op update for op picker
        function isCompatible = opUpdateApproved(this,OpSelection)
            try
                op = ctrlguis.csdesignerapp.dialogs.internal.SimulinkConfigurationDlg.getOperatingPointFromSelection(OpSelection);
                [isCompatible,nOp,nParam] = this.isOpCompatible(op);
                
                if ~isCompatible
                    error(this,getString(message('Control:designerapp:LinearizationIncompatibleOPError',nOp,nParam)));
                end
            catch ME
                isCompatible = false;
                uialert(getAppContainer(this.Tool),ME.message,getString(message('Control:designerapp:strToolTitleShort')));
            end
        end
        
        function Model = getModel(this)
            Model = getName(this);
        end
        
        function varname = getVariableName(this,prefix)
            % Get the local workspace
            localws = this.LocalWorkspace;
            
            % Get the variable name
            varname = slctrlguis.lintool.getVariableName(localws,prefix);
        end
        
        function opviewer = getModelICViewer(this)
            if isempty(this.ModelICViewer)
                % Optional input argument 'NoParent' for OP TearOff dialog
                % launched from a uifigure/AppContainer based app
                this.ModelICViewer = createView(...
                    slctrlguis.lintool.dialogs.op.ModelInitialConditionTC(...
                    operpoint(getModel(this))),'NoParent');
            end
            opviewer = this.ModelICViewer;
        end
        
        % Get frame
        function Frame = getFrame(this)
            Frame = getFrame(this.Tool);
        end
        
        function setTool(this,Tool)
            this.Tool = Tool;
        end
    end
    %% Events
    events
        TunedBlockListChanged
    end
end
function vars = LocalEliminateOpForOtherModels(vars,mdl)
% Eliminate those that belong to another model
ind = true(size(vars));
for ct = 1:numel(vars)
    val = getValue(vars(ct));
    ind(ct) = all(strcmp(mdl,get(val,'Model')));
end
vars = vars(ind);
end

function LocalUpdateWorkspaceOP(this)
currentState = this.LocalWorkspace.getState;
stateNames = fieldnames(currentState);

for k = 1:length(stateNames)
    state_k = currentState.(stateNames{k});
    if isa(state_k,'opcond.OperatingPoint')
        % For OperatingPoint (snapshot OP), update(OP)
        arrayfun(@(x) update(x),state_k);
    else
        % For OperatingReport (trim OP), extract OP and update, remove
        % OperatingReport
        OP = opcond.createOPFromSpecOrReport(state_k);
        currentState.(stateNames{k}) = update(OP);
    end    
end
this.LocalWorkspace.setState(currentState);
end

function LocalAddBlock(this, BlockID, S)
try
    if ~isempty(BlockID)
        w = warning('off','Slcontrol:sltuner:AddBlockMakesNonUnique');
        if ~iscell(BlockID)
            BlockID = {BlockID};
        end
        for ct = 1:numel(BlockID)
            addBlock(this.Data, BlockID{ct});
            BlkValue = getBlockValue(this.Data, BlockID{ct});
            [DoesExist, ~] = findTunedBlock(this, BlkValue.Name);
            if ~DoesExist
                % Create Tuned Block
                this.TunedBlocks = [this.TunedBlocks; ...
                    createSLTunedBlock(this, BlockID{ct})];
            end
        end
        addSignal(this,BlockID);
        if nargin>2
            loadSession(this.TunedBlocks(end),S);
        end
        warning(w);
        this.isDirty = true;
        
        ed = ctrlguis.csdesignerapp.data.internal.ListEventData('add', this.TunedBlocks(end-numel(BlockID)+1:end));
        this.notify('SystemChanged');
        this.notify('TunedBlockListChanged',ed);
    end
catch ME
    error(ME.message);
    warning(w);
end
end

function LocalRemoveBlock(this, TunedBlock)
try
    Paths = arrayfun(@(x)getPath(x), [this.getTunedBlocks],'UniformOutput',false);
    % Update the tuned block    
    [b,idx] = ismember(TunedBlock,Paths);
    if b
        TBPath = Paths(idx);
        delete(this.TunedBlocks(idx))
        this.TunedBlocks(idx) = [];
        
        % remove from data
        removeBlock(this.Data, TBPath);
        this.isDirty = true;
        this.notify('SystemChanged');
        ed = ctrlguis.csdesignerapp.data.internal.ListEventData('remove', TBPath);
        this.notify('TunedBlockListChanged',ed);
    end
catch ME
    error(ME.message);
end
end