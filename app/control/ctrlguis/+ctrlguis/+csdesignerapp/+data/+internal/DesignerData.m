classdef DesignerData < controllib.ui.internal.data.DesignDataInterface & matlab.mixin.SetGet
    % Data Management Class for Control System Tuner App
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties(Access = public, SetObservable)
        Architecture
        Responses       % ResponseWrapper with fields ...
        Designs
        Info
        Preferences
    end
    properties (Transient)
        DataChangedListener
        ConfigChangedListener
        ArchitectureDirtyListener
        ResponseDirtyListeners
        UniqueName
    end
    properties (Access = private)
        LocalWorkspace
        BaseWorkspace
        Format
        DataDirtyFlag
    end
    
    methods (Access = public)
        %% Constructor
        function this = DesignerData(Architecture)
            % Assign a unique name
            tmpName = tempname;
            idx     = regexp(tmpName,filesep);
            tmpName = tmpName(idx(end)+1:end);
            this.UniqueName = sprintf('ControlSystemDesigner(%s)',tmpName);
            
            % initialize architecture
            if nargin>0
                setArchitecture(this,Architecture);
                if isSimulink(this.Architecture)
                    addDefaultSimulinkResponse(this);
                else
                    addDefaultMatlabResponse(this);
                end
            else
                setArchitecture(this,[]);
            end
        end
        
        function delete(this)
            % must manually delete BaseWorkspaceAdapter to avoid memory
            % leak in MATLAB
            if ~isempty(this.BaseWorkspace) && isvalid(this.BaseWorkspace)
                delete(this.BaseWorkspace);
            end
        end
        
        %% Architecure functions
        function setArchitecture(this,ArchitectureToSet)
            if ~isequal(this.Architecture, ArchitectureToSet)
                delete(this.DataChangedListener);
                delete(this.ArchitectureDirtyListener);
                this.DataChangedListener = [];
                removeDerivedData(this);
                this.Architecture = ArchitectureToSet;
                if isSimulink(this.Architecture)
                    LocalWorkspace = getLocalWorkspace(this);
                    BaseWorkspace = getBaseWorkspace(this);
                    setWorkspace(this.Architecture,LocalWorkspace,BaseWorkspace);
                    getOPPicker(this.Architecture);
                    weakThis = matlab.lang.WeakReference(this);
                    this.DataChangedListener = [this.DataChangedListener; ...
                        addlistener(this.Architecture,'TunedBlockListChanged',@(es,ed)addDefaultSimulinkResponse(weakThis.Handle,ed))];
                end
                this.DataChangedListener = [this.DataChangedListener; ...
                    addlistener(this.Architecture,'SystemChanged',@(es,ed) notify(this,'PlantValueChanged'))];
                weakThis = matlab.lang.WeakReference(this);
                this.ArchitectureDirtyListener = addlistener(this.Architecture,"MarkedDirty",...
                    @(es,ed) set(weakThis.Handle,DataDirtyFlag=true));
                if ~isempty(this.Format)
                    setFormat(this.Architecture, this.Format);
                end
                this.notify('ArchitectureChanged');
                % Mark DesignerData dirty
                this.DataDirtyFlag = true;
            end
        end
        
        function setFormat(this,Format)
            this.Format = Format;
            setFormat(this.Architecture, Format);
        end
        
        function addDefaultMatlabResponse(this)
            TB = getTunedBlocks(this.Architecture);
            if ~isempty(TB)
                R  = [];
                TB = TB(cellfun(@(x)hasFeedbackLoop(this.Architecture,x),TB.getIdentifier));
                
                for ct = 1:numel(TB)
                    
                    % REVISIT
                    NewLocation = getLocationForBlock(this.Architecture, TB(ct).getIdentifier);
                    
                    % Create the response
                    L = ctrlguis.csdesignerapp.data.responses.internal.LoopTransfer(NewLocation);
                    L.Name = sprintf('LoopTransfer_%s', TB(ct).Name);
                    R = [R; ctrlguis.csdesignerapp.data.responses.internal.Response(L,this.Architecture)];
                end
                
                
                IOTransferResponses = getDefaultClosedLoops(this.Architecture);
                for ct=1:numel(IOTransferResponses)
                    
                    L = ctrlguis.csdesignerapp.data.responses.internal.IOTransfer(IOTransferResponses(ct).Input,IOTransferResponses(ct).Output);
                    L.Name = sprintf('IOTransfer_%s2%s', IOTransferResponses(ct).Input, IOTransferResponses(ct).Output);
                    R = [R; ctrlguis.csdesignerapp.data.responses.internal.Response(L,this.Architecture)];
                end
                
                setResponse(this,R);
            end
        end
        
        function addDefaultSimulinkResponse(this,ed)
            if nargin == 1
                ed.Data = this.Architecture.getTunedBlocks;
                ed.Type = 'add';
            end
            if ~isempty(ed.Data) && strcmpi(ed.Type,'add')
                R = [];
                Resp = getResponses(this);
                if isempty(Resp)
                    Loc = {};
                else
                    LT = Resp(isLoopTransfer(Resp));
                    Loc = arrayfun(@(x)(x.getDefinition.Location),LT);
                end
                if ~iscell(Loc)
                    Loc = {Loc};
                end
                for ct = 1:numel(ed.Data)
                    hasFeedback = hasFeedbackLoop(this.Architecture,ed.Data(ct).getIdentifier);
                    if ~ismember(getPath(ed.Data(ct)),Loc) && hasFeedback
                        % Create the response
                        L = ctrlguis.csdesignerapp.data.responses.internal.LoopTransfer(getPath(ed.Data(ct)));
                        L.Name = sprintf('LoopTransfer_%s', ed.Data(ct).Name);
                        R = ctrlguis.csdesignerapp.data.responses.internal.Response(L,this.Architecture);
                        addResponse(this,R);
                    end
                end
                
            end
            notify(this,'TunableBlocksListChanged');
            % Mark Designer Data Dirty
            this.DataDirtyFlag = true;
        end
        
        
        function removeDerivedData(this)
            delete(this.Responses);
            setDesigns(this,[]);
            setResponse(this,[]);
            notify(this,'TunableBlocksListChanged')
            % Mark DesignerData Dirty
            this.DataDirtyFlag = true;
        end
        function Architecture = getArchitecture(this)
            Architecture = this.Architecture;
        end
        function b = isSimulink(this)
            b = isSimulink(this.Architecture);
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
            % REVISIT
            [Signals,ExpandedSignalList] = getAvailableSignals(getArchitecture(this),SignalType);
        end
        
        %% FixedBlocks functions
        function FixedBlocks = getFixedBlocks(this)
            FixedBlocks = getFixedBlocks(this.Architecture);
        end
        
        
        %% TunableBlocks functions
        function TunableBlock = getTunableBlocks(this)
            TunableBlock = getTunedBlocks(this.Architecture);
        end
        
        
        function addTunableBlock(this,TunableBlockToAdd)
            w = warning('off','Slcontrol:sltuner:AddBlockMakesNonUnique');
            addBlock(this.Architecture,TunableBlockToAdd);
            warning(w);
            notify(this,'TunableBlocksListChanged');
            % Mark DesignerData Dirty
            this.DataDirtyFlag = true;
        end
        function removeTunableBlock(this,TunableBlockToDelete)
            this.Architecture.removeBlock(TunableBlockToDelete);
            notify(this,'TunableBlocksListChanged');
            % Mark DesignerData Dirty
            this.DataDirtyFlag = true;
        end
        function updateSimulinkBlock(this,Block)
            if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.Architecture.getName))
                load_system(this.Architecture.getName);
            end
            if nargin == 1
                updateSimulinkBlock(getArchitecture(this))
            else
                updateSimulinkBlock(getArchitecture(this),Block)
            end
            
            
        end
        
        
        %% Designs functions
        function Design = getDesigns(this)
            Design = this.Designs;
        end
        function setDesigns(this,Design)
            if isempty(Design)
                delete(this.Designs);
            end
            this.Designs = Design;
            ed = ctrlguis.csdesignerapp.data.internal.ListEventData('Change', Design);
            notify(this,'DesignsListChanged',ed);
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        function addDesign(this,Design)
            %% Add Design To List
            this.Designs = [this.Designs; Design];
            ed = ctrlguis.csdesignerapp.data.internal.ListEventData('Add', Design);
            notify(this,'DesignsListChanged',ed);
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        function removeDesign(this,Design)
            %% Remove Design From List
            [~,idx] = ismember(Design,this.Designs);
            ed = ctrlguis.csdesignerapp.data.internal.ListEventData('Remove', Design);
            this.Designs(idx) = [];
            notify(this,'DesignsListChanged',ed);
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        function storeDesign(this)
            %% Store a design (set of current compensator values)
            
            % Create Design
            Design = createDesign(this);
            
            % Add Design to list
            addDesign(this,Design);
        end
        function Design = createDesign(this)
            %% Create Design Snapshot
            Name = getUniqueDesignName(this);
            
            Design = exportDesign(getArchitecture(this));
            Design.Name = Name;
        end
        function retrieveDesign(this,IndexOrDesign)
            if isnumeric(IndexOrDesign)
                % Index into list
                Design = this.Designs(IndexOrDesign);
            else
                % Index is a design
                Design = IndexOrDesign;
            end
            applyDesign(this,getArchitecture(this),Design);
            % REVISIT: Should this event be on apply design?
            this.notify('CompensatorValueChanged')
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        function applyDesign(this,Arch,Design)
            % This should probably be a static method
            importDesign(Arch,Design)
            
        end
        function DesignName = getUniqueDesignName(this)
            CurrentDesigns = getDesigns(this);
            if isempty(CurrentDesigns)
                n=1;
            else
                Names = [CurrentDesigns.Name];
                n = 1;
                while ~isempty(strfind(Names,sprintf('Design%d',n)))
                    n = n+1;
                end
            end
            DesignName = sprintf('Design%d',n);
        end
        function setBlockValue(this,ST)
            % Prevent multiple updates resulting from each compensator
            % value changing. use flag to prevent multiple
            % CompensatorValueChanged events from firing
            this.isSLTunableBlockListenersEnabled = false;
            this.Architecture.setBlockValue(genss(ST))
            this.notify('CompensatorValueChanged')
            this.isSLTunableBlockListenersEnabled = true;
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        
        %% Responses functions
        function Response = getResponses(this)
            Response = this.Responses;
        end
        function setResponse(this,ResponseToSet)
            for ct = 1:numel(ResponseToSet)
                setArchitecture(ResponseToSet(ct),getArchitecture(this));
                % Add listener for response dirty
                weakThis = matlab.lang.WeakReference(this);
                this.ResponseDirtyListeners = [this.ResponseDirtyListeners; ...
                    addlistener(ResponseToSet(ct),"MarkedDirty",@(es,ed) set(weakThis.Handle,DataDirtyFlag=true))];
            end
            this.Responses = ResponseToSet(:);
            ed = ctrlguis.csdesignerapp.data.internal.ListEventData('Change', ResponseToSet);
            notify(this,'ResponsesListChanged',ed)
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        function addResponse(this,Response)
            for ct = 1:numel(Response)
                setArchitecture(Response(ct),getArchitecture(this));
                weakThis = matlab.lang.WeakReference(this);
                this.ResponseDirtyListeners = [this.ResponseDirtyListeners; ...
                    addlistener(Response(ct),"MarkedDirty",@(es,ed) set(weakThis.Handle,DataDirtyFlag=true))];
            end
            this.Responses = [this.Responses;Response(:)];
            ed = ctrlguis.csdesignerapp.data.internal.ListEventData('Add', Response);
            notify(this,'ResponsesListChanged',ed)
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        function removeResponse(this,Response)
            [~,idx] = ismember(Response,this.Responses);
            ed = ctrlguis.csdesignerapp.data.internal.ListEventData('Remove', Response);
            this.Responses(idx) = []; % removing responses
            delete(this.ResponseDirtyListeners(idx));
            this.ResponseDirtyListeners(idx) = [];

            % REVISIT: should this delete the response
            notify(this,'ResponsesListChanged',ed);
            % Mark DesignerData dirty
            this.DataDirtyFlag = true;
        end
        function [ResponseDialogGC,ResponseDialogTC] = createResponse(this,type,Anchor)
            if nargin == 2
                Anchor = [];
            end
            switch type
                case 'IOTransfer'
                    Names = '';
                    Responses = getResponses(this);
                    for ct = 1:length(Responses)
                        Names = [Names, Responses(ct).Response.Name];
                    end
                    n = 1;
                    while ~isempty(strfind(Names,sprintf('IOTransfer%d',n)))
                        n = n+1;
                    end
                    Name = sprintf('IOTransfer%d',n);
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseInputOutputTransferTC(this);
                    ResponseDialogTC.Name = Name;
                    ResponseDialogGC = createView(ResponseDialogTC);
                    ResponseDialogGC.show(Anchor,true);
                    update(ResponseDialogTC);
                case 'LoopTransfer'
                    Names = '';
                    Responses = getResponses(this);
                    for ct = 1:length(Responses)
                        Names = [Names, Responses(ct).Response.Name];
                    end
                    n = 1;
                    while ~isempty(strfind(Names,sprintf('LoopTransfer%d',n)))
                        n = n+1;
                    end
                    Name = sprintf('LoopTransfer%d',n);
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseLoopTransferTC(this);
                    ResponseDialogTC.Name = Name;
                    ResponseDialogGC = createView(ResponseDialogTC);
                    ResponseDialogGC.show(Anchor,true);
                    update(ResponseDialogTC);
                case 'SensitivityTransfer'
                    Names = '';
                    Responses = getResponses(this);
                    for ct = 1:length(Responses)
                        Names = [Names, Responses(ct).Response.Name];
                    end
                    n = 1;
                    while ~isempty(strfind(Names,sprintf('SensitivityTransfer%d',n)))
                        n = n+1;
                    end
                    Name = sprintf('SensitivityTransfer%d',n);
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseSensitivityTransferTC(this);
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
            
            switch class(getDefinition(ResponseWrapper))
                case 'ctrlguis.csdesignerapp.data.responses.internal.IOTransfer'
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseInputOutputTransferTC(this,ResponseWrapper);
                case 'ctrlguis.csdesignerapp.data.responses.internal.LoopTransfer'
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseLoopTransferTC(this,ResponseWrapper);
                case 'ctrlguis.csdesignerapp.data.responses.internal.SensitivityTransfer'
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseSensitivityTransferTC(this,ResponseWrapper);
            end
            
            ResponseDialogGC = createView(ResponseDialogTC);
            ResponseDialogGC.Padding = 0;
            ResponseDialogGC.RowSpacing = 10;
            ResponseDialogGC.show(Anchor,Region);
            update(ResponseDialogTC);
            
            ResponseWrapper.EditHandles = ResponseDialogGC;
        end
        function Names = getResponsesNames(this)
            Names = arrayfun(@(x) getName(x),getResponses(this),'UniformOutput',false);
        end
        
        function Names = getResponseName(this)
            % REVISIT
            Names = getResponsesNames(this);
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
        
        %% Load/Save Session functions
        function S = saveSession(this)
            w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
            localArchitecture = saveSession(this.getArchitecture);
            Resp = getResponses(this);
            R = [];
            for ct = 1:numel(Resp)
                R = [R; saveSession(Resp(ct))];
            end
            D = getDesigns(this);
            SavedDesigns = [];
            for ct = 1:numel(D)
                SavedDesigns = [SavedDesigns; saveSession(D(ct))];
            end
            warning(w);
            S = struct(...
                'Architecture',localArchitecture,...
                'Response', R,...
                'Designs',SavedDesigns);
            S.LocalVariables = saveVariablesInLocalWorkspace(this);
            % Mark DesignerData clean
            this.DataDirtyFlag = false;
        end
        
        function loadSession(this,S)
            removeDerivedData(this);
            %% Architecture
            %             w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
            switch S.Architecture.Config
                case 0
                    ST = copy(S.Architecture.Data);
                    Arch = ctrlguis.csdesignerapp.data.architectures.internal.SimulinkArchitecture(ST);
                    for ct = 1:numel(S.LocalVariables)
                        assignin(getLocalWorkspace(this), S.LocalVariables(ct).Name,S.LocalVariables(ct).Value);
                    end
                    if isfield(S,'OperatingPoint')
                    end
                otherwise
                    ntb = numel(S.Architecture.TunedBlocks);
                    for ct = 1:ntb
                        if isfield(S.Architecture.TunedBlocks(ct),'Ts')
                            sampleTime = S.Architecture.TunedBlocks(ct).Ts;
                        elseif isfield(S.Architecture.TunedBlocks(ct),'Value')
                            sampleTime = S.Architecture.TunedBlocks(ct).Value.Ts;
                        else
                            sampleTime = 0;
                        end
                        Input{ct,1} = ss(1,Ts=sampleTime);
                    end
                    for ct = 1:numel(S.Architecture.FixedBlocks)
                        Input{ct+ntb,1} = S.Architecture.FixedBlocks(ct).Value;
                        if isnumeric(Input{ct+ntb,1})
                            Input(ct+ntb,1) = ss(Input(ct+ntb,1));
                        end
                        if  isempty(Input{ct+ntb,1}.Name)
                            Input{ct+ntb,1}.Name = S.Architecture.FixedBlocks(ct).Description;
                        end
                    end
                    % Check for Input order in Config6
                    if S.Architecture.Config == 6
                        fixedBlocks = Input(ntb+1:end);
                        fixedBlockIdentifiers = {S.Architecture.FixedBlocks.Identifier};
                        [~,~,fixedBlockIdx] = intersect(fixedBlockIdentifiers,{'G1','G2','H1','H2'},'stable');
                        Input(ntb+1:end) = fixedBlocks(fixedBlockIdx);
                    end
                    ArchClass = sprintf('Config%dArchitecture',S.Architecture.Config);
                    Arch = ctrlguis.csdesignerapp.data.architectures.internal.(ArchClass)(Input{:});
            end
            setArchitecture(this,Arch);
            loadSession(Arch,S.Architecture);
            
            %             warning(w);
            
            %% Responses
            Resp = [];
            for ct = 1:numel(S.Response)
                switch S.Response(ct).Definition.Type
                    case 'IOTransfer'
                        if isSimulink(this.Architecture)
                            Input = S.Response(ct).Definition.Input;
                            Output = S.Response(ct).Definition.Output;
                            Openings = S.Response(ct).Definition.Openings;
                        else
                            Input = localuc2uC(S.Response(ct).Definition.Input);
                            Output = localuc2uC(S.Response(ct).Definition.Output);
                            Openings = localuc2uC(S.Response(ct).Definition.Openings);
                        end
                        Definition = ctrlguis.csdesignerapp.data.responses.internal.(S.Response(ct).Definition.Type)(Input,Output);
                        Definition.Openings = Openings;
                    case {'LoopTransfer', 'SensitivityTransfer'}
                        Openings = [];
                        if isstruct(S.Response(ct).Definition.Location)
                            if isSimulink(this.Architecture)
                                Location = sprintf('%s/%d',S.Response(ct).Definition.Location.BlockName,S.Response(ct).Definition.Location.PortNumber);
                                if isstruct(S.Response(ct).Definition.Openings)
                                    for ctO=1:numel(S.Response(ct).Definition.Openings)
                                        if S.Response(ct).Definition.Openings(ctO).Status == 1
                                            Openings = strcat(S.Response(ct).Definition.Openings(ctO).BlockName,['/', mat2str(S.Response(ct).Definition.Openings(ctO).PortNumber)]);
                                        end
                                    end
                                end
                            else
                                Location = getLocationForBlock(this.Architecture, S.Response(ct).Definition.Location.BlockName);
                                if isstruct(S.Response(ct).Definition.Openings)
                                    for ctO=1:numel(S.Response(ct).Definition.Openings)
                                        if S.Response(ct).Definition.Openings(ctO).Status == 1
                                            Openings = getLocationForBlock(this.Architecture, S.Response(ct).Definition.Openings.BlockName);
                                        end
                                    end
                                end
                            end
                        else
                            if isSimulink(this.Architecture)
                                Location = S.Response(ct).Definition.Location;
                                Openings = S.Response(ct).Definition.Openings;
                            else
                                Location = localuc2uC(S.Response(ct).Definition.Location);
                                Openings = localuc2uC(S.Response(ct).Definition.Openings);
                            end
                        end
                        
                        Definition = ctrlguis.csdesignerapp.data.responses.internal.(S.Response(ct).Definition.Type)(Location);
                        Definition.Openings = Openings;
                    case 'IOTransferEntireSystem'
                        Definition = ctrlguis.csdesignerapp.data.responses.internal.(S.Response(ct).Definition.Type);
                end
                %
                Definition.Models = S.Response(ct).Definition.Models;
                Definition.Name = S.Response(ct).Definition.Name;
                if isfield(S.Response(ct),'Identifier')
                    Resp = [Resp; ctrlguis.csdesignerapp.data.responses.internal.Response(Definition,Arch,S.Response(ct).Identifier)];
                else
                    Resp = [Resp; ctrlguis.csdesignerapp.data.responses.internal.Response(Definition,Arch)];
                end
            end
            
            setResponse(this,Resp);
            
            %% Designs
            Design = [];
            for ct = 1:numel(S.Designs)
                Design = [Design; ctrlguis.csdesignerapp.data.internal.Design(S.Designs(ct).Data,S.Designs(ct).Name)];
            end
            setDesigns(this,Design);
            % Mark DesignerData clean
            this.DataDirtyFlag = false;
        end
        
        function [NewDesignerData,RespIdxMapping,LoopIdxMapping, BlockIdxMapping] = upgradeToLatest(this,OldSession,varargin)
            %% Architecture and Responses
            OldArch = OldSession(1);
            if OldArch.Configuration == 0
                [NewArch, NewResp, RespIdxMapping, LoopIdxMapping, BlockIdxMapping] = OldArch.utExportStructure(false,varargin{:});
            else
                % Note: We do not support renaming of signals. Hence, the
                % singals from sisodata.design need to replaced with the
                % default signal names.
                DefaultDesign = sisoinit(OldArch.Configuration);
                OldArch.Input = DefaultDesign.Input;
                OldArch.Output = DefaultDesign.Output;
                [NewArch, NewResp, RespIdxMapping, LoopIdxMapping, BlockIdxMapping] = OldArch.utExportStructure(false, [DefaultDesign.Input(:); DefaultDesign.Output(:)]);
            end
            
            %% Designs
            NewDesigns = [];
            for ct = 2:numel(OldSession)
                Data = OldSession(ct).utExportStructure(true, []);
                
                NewDesigns = [NewDesigns; struct('Data', Data, ...
                    'Name', sprintf('Design%d',ct))];
            end
            %% Designer data
            NewDesignerData = struct('Architecture', NewArch, ...
                'Response', NewResp, ...
                'Designs', NewDesigns);
        end
        
        %% Preferences
        function Preferences = getPreferences(this)
            if isempty(this.Preferences)
                this.Preferences = ctrlguis.csdesignerapp.data.preferences.internal.Preferences(this);
            end
            Preferences = this.Preferences;
        end
        
        function LocalVariables = saveVariablesInLocalWorkspace(this)
            localwks = getLocalWorkspace(this);
            vars = who(localwks);
            if ~isempty(vars)
                LocalVariables = struct('Name',[],'Value',[]);
                for ct = 1:numel(vars)
                    LocalVariables(ct).Name = vars{ct};
                    LocalVariables(ct).Value = evalin(localwks,vars{ct});
                end
            else
                LocalVariables = [];
            end
        end
        %% Design data interface
        function ArchitectureName = getArchitectureName(this)
            ArchitectureName = getName(getArchitecture(this));
        end
        
        function name = getAddSignalFcnName(this) %#ok<MANU> 
            name = 'addSignal';
        end
        
        function point = resolveSignalID(this,signalId,varargin)
            point = this.Architecture.resolveSignalID(signalId,varargin{:});
        end

        function icon = getArchitectureIcon(this)
            arch = getArchitecture(this);
            icon = getArchitectureIcon(arch);
        end

        function tunedBlockNames = getTunedBlockNames(this)
            tunedBlock = this.getArchitecture.getTunedBlocks;
            tunedBlockNames = string({tunedBlock.Name});
        end
        
        function tunableBlock = getTunableBlock(this)
            tunableBlock = this.getArchitecture.getTunedBlocks;
        end

        function tunableBlockPath = getTunableBlockPath(this)
            tunableBlockPath = ctrlguis.csdesignerapp.utils.internal.getTunableBlockPaths(...
                this.getArchitecture.getTunedBlocks);
        end
    end

    methods
        function set.DataDirtyFlag(this,flag)
            this.DataDirtyFlag = flag;
            if flag
                controllib.ui.internal.dirtymgr.DirtyManager.getInstance(this.UniqueName).setDirty(flag);
            end
        end
    end
    
    methods (Hidden = true)
        % Needed by oppicker
        function WS = getLocalWorkspace(this)
            if isempty(this.LocalWorkspace)
                this.LocalWorkspace = toolpack.databrowser.LocalWorkspaceModel;
            end
            WS = this.LocalWorkspace;
        end
        function WS = getBaseWorkspace(this)
            if isempty(this.BaseWorkspace)
                this.BaseWorkspace = toolpack.databrowser.BaseWorkspaceAdapter;
            end
            WS = this.BaseWorkspace;
        end
        
        function flag = isDataDirty(this)
            isResponseDirty = any(arrayfun(@(x) x.isDirty,this.Responses));
            flag = this.DataDirtyFlag | isArchitectureDirty(this.Architecture) | ...
                isResponseDirty;
        end
        
        function setDataDirty(this,flag)
            if islogical(flag)
                this.DataDirtyFlag = flag;
                % Set Responses clean
                if ~flag
                    arrayfun(@(x) setDirty(x,flag),this.Responses);
                    setArchitectureDirty(this.Architecture,flag);
                end
            end
        end
        
    end
    
    
    events
        ArchitectureChanged
        TunableBlocksListChanged
        TuningGoalsListChanged
        AnalysisPointsListChanged
        ResponsesListChanged
        DesignsListChanged
        CompensatorValueChanged
        PlantValueChanged
    end
end

function Data = localCopy(Data)
if ~isempty(Data)
    Data = copy(Data);
end
end

function out = localuc2uC(in)
out = in;
if ~isempty(in)
    if ~iscell(in)
        in = {in};
    end
    out = cellfun(@(x) strrep(x,'uc','uC'),in,'UniformOutput',false);
end
end
