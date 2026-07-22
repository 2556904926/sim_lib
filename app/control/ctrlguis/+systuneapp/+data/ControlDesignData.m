classdef (Hidden) ControlDesignData < controllib.ui.internal.data.DesignDataInterface
    % Data Management Class for Control System Tuner App
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties(Access = public, SetObservable)
        Architecture
        TuningGoals     % TuningGoalWrapper with fields TuningGoal and MetaData
        Responses       % ResponseWrapper with fields ...
        Designs
    end
    properties (Hidden)
        IsDirty = false;
        SampleTime = [];
    end
    properties (Transient)
        DataChangedListener
        ConfigChangedListener
        TunableBlockListeners
        isTunableBlockListenersEnabled = true;
        TuningGoalDirtyListeners = cell(1,0);  % to detect editing for dirty algorithm
        ResponseDirtyListeners = cell(1,0);  % to detect editing for dirty algorithm
    end
    
    methods (Access = public)
        
        %% Constructor
        function this = ControlDesignData(ArchitectureToSet,TuningGoalWrappersToSet)
            
            % initialize architecture
            if nargin>0
                setArchitecture(this,ArchitectureToSet);
            else
                setArchitecture(this,[]);
            end
            
            % initialize tuning goals
            if nargin>1 && ~isempty(TuningGoalWrappersToSet)
                setTuningGoal(this,TuningGoalWrappersToSet);
            else
                setTuningGoal(this,[]);
            end
            
            setDesign(this,[]);
            setResponse(this,[]);
            setDirty(this,false); % data is fresh in constructor
        end
        
        function delete(this)
            delete(this.DataChangedListener);
            delete(this.ConfigChangedListener);
            delete(this.TunableBlockListeners);
            deleteTuningGoalDirtyListeners(this);
            deleteResponseDirtyListeners(this);
            delete(this.TuningGoals);
            delete(this.Responses);
            delete(this.Designs);
            % to delete the listeners in slTuner.
            if ~isempty(this.Architecture) && isvalid(this.Architecture)
                delete(this.Architecture);
            end
        end
        
        % event and listeners
        function firePlantValueChangedEvent(this)
            % Do not fire if model is closing
            if ~slInternal('isBDClosing',this.Architecture.Model)
                % Plant value changed -> deep plot update
                notify(this,'PlantValueChanged');
                if ~isequal(this.Architecture.Ts,this.SampleTime)
                    % Change in tuning sample time also blasts the tuned block
                    % parameterization
                    notify(this,'TunableBlocksListChanged');
                    this.SampleTime = this.Architecture.Ts;
                end
                setDirty(this,true);
            end
        end
        
        function addTunableBlockListeners(this)
            % Adds or refreshes listeners to change in tunable block
            % parameterization
            delete(this.TunableBlockListeners)
            this.TunableBlockListeners = [];
            TB = getTunableBlock(this);
            for ct = 1:numel(TB)
                this.TunableBlockListeners = [this.TunableBlockListeners;...
                    addlistener(TB(ct),'ParameterizationChanged',@(es,ed) fireCompensatorChanged(this))];
            end
        end
        
        function fireCompensatorChanged(this)
            if this.isTunableBlockListenersEnabled
                notify(this,'CompensatorValueChanged')
                setDirty(this,true);
            end
            % Reset the Tunable Block Listeners
            addTunableBlockListeners(this);
        end
        
        function removeDerivedData(this)
            setTuningGoal(this,[]);
            setDesign(this,[]);
            setResponse(this,[]);
            notify(this,'TunableBlocksListChanged')
            setDirty(this,true);
        end
        
        % query functions
        function b = isSimulink(this)
            b = isa(this.Architecture,'slTuner');
        end
        
        function bool = isCompatibleDesign(this,Design)
            CurrentTs = getTs(this);
            DesignTs = getTs(Design);  % design snapshot
            bool = (isempty(DesignTs) || DesignTs==CurrentTs);
            if ~bool
                % Pop error dialog
                if DesignTs==0
                    DesignSampleTime = getString(message('Control:systunegui:LinearizationOptionsContinuous'));
                else
                    DesignSampleTime = num2str(DesignTs,'%.3g');
                end
                errordlg(getString(message('Control:systunegui:GeneralDesignSampleTimeMismatch',...
                    DesignSampleTime)), getString(message('Control:systunegui:toolName')),'modal');
            end
        end
        
        function flag = isControlDesignDataFresh(this)
            if ~this.isSimulink
                if ~isempty(this.Architecture)
                    freshTunedBlocks = this.Architecture.isDataFresh;
                else
                    freshTunedBlocks = true; % empty is fresh
                end
                noTuningGoals = isempty(this.TuningGoals);
                noResponses = isempty(this.Responses);
                noDesigns = isempty(this.Designs);
                flag = freshTunedBlocks & noTuningGoals & noResponses & noDesigns;
            else % simulink case is not considered fresh data
                flag = false;
            end
        end
        function [bool,nOp,nParam] = isParamCompatible(this,param)
            [bool,nOp,nParam] = this.isOpParamCompatible(this.getOperatingPoints,param);
        end
        function [bool,nOp,nParam] = isOpCompatible(this,op)
            [bool,nOp,nParam] = this.isOpParamCompatible(op,this.getParameters);
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
        
        %% Architecture functions
        function setArchitecture(this,ArchitectureToSet)
            if ~isequal(this.Architecture, ArchitectureToSet)
                removeDerivedData(this)
                delete(this.Architecture);
                
                if isSimulink(this)
                    % When input is slTuner, we need to make a copy not to
                    % delete the one in workspace
                    this.Architecture = copy(ArchitectureToSet);
                else
                    this.Architecture = ArchitectureToSet;
                end
                
                notify(this,'ArchitectureChanged');
                
                if isSimulink(this)
                    this.DataChangedListener = [addlistener(this.Architecture,'BecameDirty',@(es,ed) firePlantValueChangedEvent(this));...
                        addlistener(this.Architecture,'BlockListUpdated',@(es,ed) fireBlockListChanged(this))];
                    this.SampleTime = this.Architecture.Ts;
                    % set the warning off for nontunable parameters, multi compilation
                    this.Architecture.Options.AreParamsTunable = false;
                else
                    this.DataChangedListener = addlistener(this.Architecture,'DataChanged',@(es,ed) fireCompensatorChanged(this));
                    this.ConfigChangedListener = addlistener(this.Architecture,'ConfigChanged',@(es,ed)  removeDerivedData(this));
                end
                addTunableBlockListeners(this)
            end
        end
        function Architecture = getArchitecture(this)
            Architecture = this.Architecture;
        end
        function CL = getCL(this,Design)
            % Returns the genss or slTuner
            Arch = getArchitecture(this);
            
            % Make copy and apply design if Design is specified
            if nargin == 2
                Arch = copy(Arch);
                applyDesign(this,Arch,Design);
            end
            
            if isSimulink(this)
                CL = Arch;
            else
                % Cast to genss on MATLAB case
                CL = genss(Arch);
            end
        end
        function [Signals,ExpandedSignalList] = getAvailableSignals(this,SignalType)
            if nargin == 1
                SignalType = 'All';
            end
            if this.isSimulink
                Signals = getPointNames(this.Architecture);
                try
                    ExpandedSignalList = getPointExpandedNames(this.Architecture);
                catch Ex
                    % getPointExpandedNames converts to genss
                    % if this fails, assume signals are added as (All)
                    ExpandedSignalList = Signals;
                end
            elseif isa(this.Architecture,'systuneapp.data.MatlabConfigData.Config1') || ...
                    isa(this.Architecture,'systuneapp.data.MatlabConfigData.AbstractConfig')
                ExpandedSignalList = getAvailableSignals(this.Architecture,SignalType);
                Signals = systuneapp.util.expandedSignalList2SignalList(ExpandedSignalList);
            end
        end
        function Ts = getTs(this)
            if isa(this.Architecture,'slTuner')
                Ts = this.Architecture.Ts;
            else % genss and config1
                Ts = getTs(this.Architecture);
            end
        end
        function setLinearizationOptions(this,Options)
            this.Architecture.Options = Options;
        end
        function Options = getLinearizationOptions(this)
            Options = copy(this.Architecture.Options);
        end
        function Params = getParameters(this)
            Params = this.Architecture.Parameters;
        end
        function OPs = getOperatingPoints(this)
            OPs = this.Architecture.OperatingPoints;
        end
        function setOperatingPoints(this,op)
            this.Architecture.OperatingPoints = op;
        end
        function setParameters(this,params)
            this.Architecture.Parameters = params;
        end
        function TimeUnit = getTimeUnit(this)
            if isSimulink(this)
                TimeUnit = this.Architecture.TimeUnit;
            else
                Architecture = this.Architecture.getCL;
                TimeUnit = Architecture.TimeUnit;
            end
        end
        function TimeUnitString = getTimeUnitString(this)
            TimeUnitString = controllibutils.utXlateUnitsString(getTimeUnit(this),'short');
            %             TimeUnit = getTimeUnit(this);
            %             % hard-coded since slTuner does not translate the units
            %             switch TimeUnit
            %                 % abbreviated units
            %                 case 'nanoseconds'
            %                     TimeUnitString = getString(message('Control:systunegui:nanosecondsShort'));
            %                 case 'microseconds'
            %                     TimeUnitString = getString(message('Control:systunegui:microsecondsShort'));
            %                 case 'milliseconds'
            %                     TimeUnitString = getString(message('Control:systunegui:millisecondsShort'));
            %                 case 'seconds'
            %                     TimeUnitString = getString(message('Control:systunegui:secondsShort'));
            %                 case 'minutes'
            %                     TimeUnitString = getString(message('Control:systunegui:minutesShort'));
            %                 case 'hours'
            %                     TimeUnitString = getString(message('Control:systunegui:hoursShort'));
            %                     % non-abbreviated units
            %                 case 'days'
            %                     TimeUnitString = getString(message('Controllib:gui:strDays'));
            %                 case 'weeks'
            %                     TimeUnitString = getString(message('Controllib:gui:strWeeks'));
            %                 case 'months'
            %                     TimeUnitString = getString(message('Controllib:gui:strMonths'));
            %                 case 'years'
            %                     TimeUnitString = getString(message('Controllib:gui:strYears'));
            %             end
        end
        
        %% TunableBlocks functions
        function TunableBlock = getTunableBlock(this)
            if isSimulink(this)
                if ~isempty(this.Architecture) && ~isempty(this.Architecture.TunedBlocks)
                    TunableBlock = getSLTunableBlocks(this.Architecture);
                else
                    TunableBlock = [];
                end
            else
                TunableBlock = this.Architecture.getTunableBlocks;
            end
        end
        
        function fireBlockListChanged(this)
            addTunableBlockListeners(this)
            notify(this,'TunableBlocksListChanged');
            notify(this,'CompensatorValueChanged');
            setDirty(this,true);
        end
        
        function addTunableBlock(this,TunableBlockToAdd)
            try
                addBlock(this.Architecture,TunableBlockToAdd);
                addTunableBlockListeners(this)
                notify(this,'TunableBlocksListChanged');
                setDirty(this,true);
            catch ME
                % if adding block errors, remove them and reassign
                % listeners
                removeBlock(this.Architecture,TunableBlockToAdd);
                addTunableBlockListeners(this)
                rethrow(ME);
            end
        end
        function removeTunableBlock(this,TunableBlockToDelete)
            % get blockpaths of all blocks to delete
            this.Architecture.removeBlock({TunableBlockToDelete.BlockPath});
            addTunableBlockListeners(this)
            notify(this,'TunableBlocksListChanged');
            setDirty(this,true);
        end
        function setBlockValue(this,ST)
            % Prevent multiple updates resulting from each compensator
            % value changing. use flag to prevent multiple
            % CompensatorValueChanged events from firing
            this.isTunableBlockListenersEnabled = false;
            setTuningInfo(this.Architecture,getTuningInfo(ST));
            setTunedValue(this.Architecture,getTunedValue(ST))
            this.notify('CompensatorValueChanged')
            this.isTunableBlockListenersEnabled = true;
            setDirty(this,true);
        end
        function warningMessage = updateSimulinkBlock(this,block)
            warningMessage = '';
            if ~isempty(this.Architecture.TunedBlocks)
                w = warning('off', 'Slcontrol:controldesign:writeBlockValue1');
                if nargin<2
                    writeBlockValue(this.Architecture);
                else
                    writeBlockValue(this.Architecture,block.BlockPath);
                end
                [msg,identifier] = lastwarn;
                if strcmp(identifier,'Slcontrol:controldesign:writeBlockValue1')
                    warningMessage = msg;
                    % warndlg(msg,getString(message('Control:systunegui:toolName')),'modal');
                end
                warning(w);
            else
                warningMessage = getString(message('Control:systunegui:UpdateBlocksNoBlock'));
                % warndlg(getString(message('Control:systunegui:UpdateBlocksNoBlock')),getString(message('Control:systunegui:toolName')),'modal');
            end
        end
        
        %% TuningGoals functions
        function TuningGoal = getTuningGoal(this)
            TuningGoal = this.TuningGoals;
        end
        function setTuningGoal(this,TuningGoal)
            deleteTuningGoalDirtyListeners(this);
            this.TuningGoals = TuningGoal;
            addTuningGoalDirtyListeners(this)
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','New','TuningGoalWrapper',TuningGoal));
            notify(this,'TuningGoalsListChanged',ed);
        end
        function addTuningGoal(this,TuningGoalWrappersToAdd)
            % get all tuning goals and add new ones if not in the list
            AllTuningGoalWrappers = this.getTuningGoal;
            AllTuningGoals = systuneapp.util.wrapperToData('TuningGoal',AllTuningGoalWrappers);
            TuningGoalsToAdd = systuneapp.util.wrapperToData('TuningGoal',TuningGoalWrappersToAdd);
            [NewTuningGoals,~,~,~,NewItemIndexinItems] = systuneapp.util.newOrCommonItemsInList(TuningGoalsToAdd,AllTuningGoals);
            
            if ~isempty(NewTuningGoals)
                % if there are added ones, update list
                if isempty(this.TuningGoals)
                    this.TuningGoals = TuningGoalWrappersToAdd(NewItemIndexinItems);
                    addTuningGoalDirtyListeners(this); % since all goals are new
                else
                    Index = length(AllTuningGoals)+(1:length(NewTuningGoals));
                    this.TuningGoals(Index,1)=TuningGoalWrappersToAdd(NewItemIndexinItems);
                    addTuningGoalDirtyListeners(this,Index)
                end
                ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','Add','TuningGoalWrapper',TuningGoalWrappersToAdd(NewItemIndexinItems)));
                notify(this,'TuningGoalsListChanged',ed);
                setDirty(this,true);
            end
        end
        function removeTuningGoal(this,TuningGoalWrappersToDelete)
            % get all tuning goals and remove ones in the list
            AllTuningGoals = systuneapp.util.wrapperToData('TuningGoal',this.getTuningGoal);
            TuningGoalsToDelete(:,1) = systuneapp.util.wrapperToData('TuningGoal',TuningGoalWrappersToDelete);
            
            [~,CommonTuningGoals,CommonTuningGoalsIndex] = systuneapp.util.newOrCommonItemsInList(TuningGoalsToDelete,AllTuningGoals);
            
            if ~isempty(CommonTuningGoals)
                TG = this.TuningGoals(CommonTuningGoalsIndex);
                ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','Remove','TuningGoalWrapper',TG));
                deleteTuningGoalDirtyListeners(this,CommonTuningGoalsIndex);
                this.TuningGoals(CommonTuningGoalsIndex) = []; % remove tuning goals
                notify(this,'TuningGoalsListChanged',ed);
                setDirty(this,true);
            end
        end
        function Names = getTuningGoalName(this)
            Names = arrayfun(@(x) x.TuningGoal.Name,this.getTuningGoal,'UniformOutput',false);
        end
        function deleteTuningGoalDirtyListeners(this,Index)
            if nargin<2 % remove listeners from all tuning goals
                Index = 1:length(this.TuningGoals);
            end
            if ~isempty(Index)
                if ~isempty(this.TuningGoalDirtyListeners) % not existing listeners from old session files
                    for ct=1:length(Index)
                        if ~isempty(this.TuningGoalDirtyListeners{Index(ct)})
                            if isvalid(this.TuningGoalDirtyListeners{Index(ct)})
                                delete(this.TuningGoalDirtyListeners{Index(ct)});
                            end
                        end
                    end
                    this.TuningGoalDirtyListeners(Index) = [];
                end
            end
        end
        function addTuningGoalDirtyListeners(this,Index)
            if nargin<2 % add listeners to all tuning goals
                Index = 1:length(this.TuningGoals);
            end
            if ~isempty(Index)
                for ct=Index
                    % listeners for isDirty in editing tuning goal
                    this.TuningGoalDirtyListeners{ct} = addlistener(this.TuningGoals(ct),'TuningGoal','PostSet',@(es,ed) setDirty(this,true));
                end
            end
        end
        function idx = getTuningGoalIndexMatchingWithSampleTime(this,Ts)
            AllTuningGoalWrappers = this.getTuningGoal;
            AllTuningGoals = systuneapp.util.wrapperToData('TuningGoal',AllTuningGoalWrappers);
            if isa(this.Architecture,'slTuner')
                Arch = this.Architecture;
            else % genss and config1
                Arch = this.Architecture.getCL;
            end
            ArchTemp = copy(Arch);
            ArchTemp.Ts = Ts;
            idx = false(size(AllTuningGoals));
            for ct=1:length(AllTuningGoals)
                try %#ok<TRYNC>
                    validateGoal(AllTuningGoals(ct),ArchTemp);
                    idx(ct) = true;
                end
            end
        end
        
        %% Designs functions
        function Design = getDesign(this)
            Design = this.Designs;
        end
        function setDesign(this,Design)
            this.Designs = Design;
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','NewList','Design',Design));
            notify(this,'DesignsListChanged',ed)
        end
        function addDesign(this,Design)
            this.Designs = [this.Designs; Design];
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','Add','Design',Design));
            notify(this,'DesignsListChanged',ed)
            setDirty(this,true);
        end
        function removeDesign(this,Design)
            idx = Design == this.Designs;
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','Remove','Design',Design));
            this.Designs(idx) = [];
            notify(this,'DesignsListChanged',ed);
            setDirty(this,true);
        end
        
        function Design = createDesign(this)
            CurrentDesigns = this.getDesign;
            if isempty(CurrentDesigns)
                n=1;
            else
                Names = [CurrentDesigns.Name];
                n = 1;
                while contains(Names,sprintf('Design%d',n))
                    n = n+1;
                end
            end
            Name = sprintf('Design%d',n);
            
            st = getArchitecture(this);
            for ct = numel(st.TunedBlocks):-1:1
                C(ct) = struct('ID', st.TunedBlocks{ct},...
                    'BlockParam',st.getBlockParam(st.TunedBlocks{ct}));
            end
            
            Design = systuneapp.data.DesignSnapshot(Name, C, getTuningInfo(st));
        end
        
        function retrieveDesign(this,IndexOrDesign)
            if isnumeric(IndexOrDesign)
                % Index into list
                Design = this.Designs(IndexOrDesign);
            else
                % Index is a design
                Design = IndexOrDesign;
            end
            if isCompatibleDesign(this,Design)
                % Note: Pops error dialog when design is incompatible
                applyDesign(this,getArchitecture(this),Design);
                this.notify('CompensatorValueChanged')
                setDirty(this,true);
            end
        end
        
        function applyDesign(this,Arch,Design)
            % Applies saved design data to architecture.
            % Apply saved tuning info
            setTuningInfo(Arch,Design.Info);
            % Prevent multiple firing of CompensatorValueChanged event
            this.isTunableBlockListenersEnabled = false;
            for ct = 1:length(Design.Data)
                try  %#ok<TRYNC>
                    % Block in design may no longer be part of tunable blocks
                    Arch.setBlockParam(Design.Data(ct).ID,Design.Data(ct).BlockParam)
                end
            end
            this.isTunableBlockListenersEnabled = true;
        end
        
        %% Responses functions
        function Response = getResponse(this)
            Response = this.Responses;
        end
        function setResponse(this,ResponseToSet)
            deleteResponseDirtyListeners(this);
            this.Responses = ResponseToSet;
            addResponseDirtyListeners(this)
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','NewList','Response',ResponseToSet));
            notify(this,'ResponsesListChanged',ed)
        end
        function addResponse(this,Response)
            Index = length(this.Responses)+(1:length(Response));
            this.Responses = [this.Responses;Response];
            addResponseDirtyListeners(this,Index);
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','Add','Response',Response));
            notify(this,'ResponsesListChanged',ed);
            setDirty(this,true);
        end
        function removeResponse(this,Response)
            Index = find(this.Responses == Response);
            deleteResponseDirtyListeners(this,Index)
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Action','Remove','Response',Response));
            this.Responses(Index) = []; % remove tuning goals
            notify(this,'ResponsesListChanged',ed);
            setDirty(this,true);
        end
        function [ResponseDialogGC,ResponseDialogTC] = createResponse(this,type,Anchor)
            if nargin == 2
                Anchor = [];
            end
            switch type
                case 'IOTransfer'
                    Names = '';
                    Responses = getResponse(this);
                    for ct = 1:length(Responses)
                        Names = [Names, Responses(ct).Response.Name];
                    end
                    n = 1;
                    while ~isempty(strfind(Names,sprintf('IOTransfer%d',n)))
                        n = n+1;
                    end
                    Name = sprintf('IOTransfer%d',n);
                    ResponseDialogTC = systuneapp.internal.panels.ResponseInputOutputTransferTC(this);
                    ResponseDialogTC.Name = Name;
                    ResponseDialogGC = createView(ResponseDialogTC);
                    ResponseDialogGC.show(Anchor,true);
                    update(ResponseDialogTC);
                case 'LoopTransfer'
                    Names = '';
                    Responses = getResponse(this);
                    for ct = 1:length(Responses)
                        Names = [Names, Responses(ct).Response.Name];
                    end
                    n = 1;
                    while ~isempty(strfind(Names,sprintf('LoopTransfer%d',n)))
                        n = n+1;
                    end
                    Name = sprintf('LoopTransfer%d',n);
                    ResponseDialogTC = systuneapp.internal.panels.ResponseLoopTransferTC(this);
                    ResponseDialogTC.Name = Name;
                    ResponseDialogGC = createView(ResponseDialogTC);
                    ResponseDialogGC.show(Anchor,true);
                    update(ResponseDialogTC);
                case 'SensitivityTransfer'
                    Names = '';
                    Responses = getResponse(this);
                    for ct = 1:length(Responses)
                        Names = [Names, Responses(ct).Response.Name];
                    end
                    n = 1;
                    while ~isempty(strfind(Names,sprintf('SensitivityTransfer%d',n)))
                        n = n+1;
                    end
                    Name = sprintf('SensitivityTransfer%d',n);
                    ResponseDialogTC = systuneapp.internal.panels.ResponseSensitivityTransferTC(this);
                    ResponseDialogTC.Name = Name;
                    ResponseDialogGC = createView(ResponseDialogTC);
                    ResponseDialogGC.show(Anchor,true);
                    update(ResponseDialogTC);
            end
        end
        function [ResponseDialogGC,ResponseDialogTC] = editResponse(this,ResponseWrapper,Anchor,Region)
            if nargin < 3
                Anchor = [];
            end
            if nargin < 4
                Region = 'SOUTH';
            end
            
            switch class(ResponseWrapper.Response)
                case 'systuneapp.data.response.IOTransfer'
                    ResponseDialogTC = systuneapp.internal.panels.ResponseInputOutputTransferTC(this,ResponseWrapper);
                case 'systuneapp.data.response.LoopTransfer'
                    ResponseDialogTC = systuneapp.internal.panels.ResponseLoopTransferTC(this,ResponseWrapper);
                case 'systuneapp.data.response.SensitivityTransfer'
                    ResponseDialogTC = systuneapp.internal.panels.ResponseSensitivityTransferTC(this,ResponseWrapper);
                case 'systuneapp.data.response.IOTransferEntireSystem'
                    ResponseDialogTC = systuneapp.internal.panels.ResponseEntireSystemTC(this,ResponseWrapper);
            end
            
            ResponseDialogGC = createView(ResponseDialogTC);
            ResponseDialogGC.ShowHelpButton = false;
            ResponseDialogGC.Padding = 0;
            ResponseDialogGC.RowSpacing = 10;
            if systuneapp.util.openJavaApp
                %ResponseDialogGC.show(Anchor,true,Region);
                show(ResponseDialogGC,[])
            else
                show(ResponseDialogGC,Anchor,Region)
            end
            update(ResponseDialogTC);
            
            ResponseWrapper.EditHandles = ResponseDialogGC;
        end
        function Names = getResponseName(this)
            Names = arrayfun(@(x) x.Response.Name,this.getResponse,'UniformOutput',false);
        end
        function System = convertToSystemWithShortNames(this, System)
            CurrentSystem = System;
            try
                if isSimulink(this)
                    LongInputNames = System.InputName;
                    LongOutputNames = System.OutputName;
                    LongNames = {LongInputNames{:} LongOutputNames{:}}';
                    SLTunerLongNames = strtok(LongNames, '(');
                    AvailableSignals = getPointNames(this.Architecture);
                    ShortNames = cell(size(SLTunerLongNames));
                    for ct = 1:numel(SLTunerLongNames)
                        idx = find(strcmp(SLTunerLongNames{ct},AvailableSignals));
                        if isempty(idx)
                            error('Cannot find signal %s in the model', SLTunerLongNames{ct});
                        else
                            p = getPoint(this.Architecture,idx);
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
                end
            catch
                System = CurrentSystem;
            end
            
        end
        function deleteResponseDirtyListeners(this,Index)
            if nargin<2 % remove listeners from all responses
                Index = 1:length(this.Responses);
            end
            if ~isempty(Index)
                if ~isempty(this.ResponseDirtyListeners) % not existing listeners from old session files
                    for ct=Index
                        if ~isempty(this.ResponseDirtyListeners{ct})
                            if isvalid(this.ResponseDirtyListeners{ct})
                                delete(this.ResponseDirtyListeners{ct});
                            end
                        end
                    end
                    this.ResponseDirtyListeners(Index) = [];
                end
            end
        end
        function addResponseDirtyListeners(this,Index)
            if nargin<2 % add listeners to all tuning goals
                Index = 1:length(this.Responses);
            end
            if ~isempty(Index)
                for ct=Index
                    % listeners for isDirty in editing tuning goal
                    this.ResponseDirtyListeners{ct} = addlistener(this.Responses(ct),'Response','PostSet',@(es,ed) setDirty(this,true));
                end
            end
        end
        
        %% Load/Save Session functions
        function S = saveSession(this)
            w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
            localArchitecture = localCopy(this.getArchitecture);
            warning(w);
            S = struct(...
                'Architecture',localArchitecture,...
                'Responses', localCopy(this.getResponse),...
                'TuningGoals', localCopy(this.getTuningGoal),...
                'Designs', localCopy(this.getDesign));
        end
        function loadSession(this,S)
            setTuningGoal(this,[]);
            setDesign(this,[]);
            setResponse(this,[]);
            w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
            setArchitecture(this,S.Architecture);
            warning(w);
            
            TuningGoals = localCopy(S.TuningGoals);
            for ct=1:length(TuningGoals)
                % in case of no MATLAB code, generate
                if ~isfield(TuningGoals(ct).MetaData,'MATLABCode') ...
                        || isempty(TuningGoals(ct).MetaData.MATLABCode)
                    TuningGoalType = systuneapp.util.getTuningGoalType(TuningGoals(ct).TuningGoal);
                    tc = systuneapp.util.getTuningGoalTC(TuningGoalType,this,TuningGoals(ct));
                    TuningGoals(ct).MetaData.MATLABCode = ...
                        tc.generateMATLABCode(TuningGoals(ct).MetaData);
                end
            end
            
            if isfield(S,'Info') % if field exist, Info could be multiple
                % change names: fBest and gBest
                if isfield(S.Info,'fBest')
                    [S.Info.f] = S.Info.fBest;
                    S.Info = rmfield(S.Info,'fBest');
                end
                if isfield(S.Info,'gBest')
                    [S.Info.g] = S.Info.gBest;
                    S.Info = rmfield(S.Info,'gBest');
                end
                if isfield(S.Info,'xBest')
                    [S.Info.x] = S.Info.xBest;
                    S.Info = rmfield(S.Info,'xBest');
                end
                setTuningInfo(this.Architecture,TuningGoal.selectBestRun(S.Info))
            end
            
            setTuningGoal(this,TuningGoals);
            setDesign(this,localCopy(S.Designs));
            setResponse(this,localCopy(S.Responses));
            
        end
        
        %% Systune function
        function cstAppSystune(this,SystuneTuningData)
            % Active TunableBlocks
            TunableBlocksList = SystuneTuningData.getTunableBlock;
            TunableBlocks = cat(1,TunableBlocksList{:,1});
            ActiveTunableBlocksIndex = cat(1,TunableBlocksList{:,2});
            
            % Active TuningGoals
            TuningGoalsList = SystuneTuningData.getTuningGoal;
            ActiveTuningGoalsIndex = cat(1,TuningGoalsList{:,2});
            ActiveTuningGoalsList = TuningGoalsList(ActiveTuningGoalsIndex,:);
            ActiveHardTuningGoalsIndex = cat(1,ActiveTuningGoalsList{:,3});
            ActiveHardTuningGoals = systuneapp.util.wrapperToData('TuningGoal',[ActiveTuningGoalsList{ActiveHardTuningGoalsIndex,1}])';
            ActiveSoftTuningGoals = systuneapp.util.wrapperToData('TuningGoal',[ActiveTuningGoalsList{~ActiveHardTuningGoalsIndex,1}])';
            
            % Options
            SystuneGUIOptions = SystuneTuningData.getOptions;
            SystuneGUIOptions.Hidden.Simulink = isSimulink(this);
            % if no display is set in options, set to final to show something when
            % tuning report is clicked.
            if strcmp(SystuneGUIOptions.Display,'off')
                SystuneGUIOptions.Display = 'final';
            end
            
            % Architecture
            CurrentArchitecture =this.Architecture;
            
            % Fold inactive tunable blocks into Architecture
            CL0 = genss(CurrentArchitecture);
            if ~all(ActiveTunableBlocksIndex)
                BlockNames = {TunableBlocks(~ActiveTunableBlocksIndex).Name};
                S = cell2struct(cell(size(BlockNames)),BlockNames,2);
                CL0 = replaceBlock(CL0,S);
            end
            
            % Tune controller parameters
            % Return slTuner interface with tuned values
            [NewArchitecture,fSoft,gHard,Info] = systune(CL0, ...
                ActiveSoftTuningGoals,ActiveHardTuningGoals, ...
                SystuneGUIOptions);
            
            % populate info data
            if isempty(fSoft)
                SystuneTuningData.TuningInfo.Soft.Values = {[]};
            else
                SystuneTuningData.TuningInfo.Soft.Values = num2cell(fSoft);
            end
            
            if isempty(gHard)
                SystuneTuningData.TuningInfo.Hard.Values = {[]};
            else
                SystuneTuningData.TuningInfo.Hard.Values = num2cell(gHard);
            end
            SystuneTuningData.TuningInfo.Iterations = sum([Info.Iterations]);
            
            this.setBlockValue(NewArchitecture);
        end

        %% Design data interface
        function ArchitectureName = getArchitectureName(this)
            if isa(this.Architecture,'slTuner')
                ArchitectureName = this.Architecture.Model;
            else
                ArchitectureName = getName(this.Architecture);
            end
        end
        
        function name = getAddSignalFcnName(this) %#ok<MANU> 
            name = 'addPoint';
        end
        
        function point = resolveSignalID(this,signalId,varargin)
            architecture = this.getArchitecture;
            points = getPoints(architecture);
            idx = slLinearizer.resolveSignalID(signalId,points);
            point = getPoint(architecture,idx);
        end
        
        function tunedBlockNames = getTunedBlockNames(this)
            tunedBlockNames = string(this.getArchitecture.TunedBlocks);
        end
        
        function tunableBlockPath = getTunableBlockPath(this)
            tunableBlock = this.getTunableBlock();
            tunableBlockPath = {tunableBlock.BlockPath}';
        end

    end
    methods (Hidden)
        function setDirty(this,flag)
            if islogical(flag)
                this.IsDirty = flag;
            end
        end
               
    end
    events
        ArchitectureChanged % configuration change
        PlantValueChanged
        % AnalysisPointsListChanged
        CompensatorValueChanged
        TunableBlocksListChanged
        TuningGoalsListChanged
        ResponsesListChanged
        DesignsListChanged
    end
end

function Data = localCopy(Data)
if ~isempty(Data)
    Data = copy(Data);
end
end
