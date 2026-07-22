classdef (Hidden) ToolManager < handle & matlab.mixin.SetGet
    % this class manages the interaction between DB and the tools
    
    % Author(s): A. Ouellette
    % Copyright 2021-2024 The MathWorks, Inc.  

    %% Properties
    properties (Dependent,SetAccess=private)
        Tools
        DocTools
    end

    properties (Access = private)
        BTSparseInitDialog
        MTSparseInitDialog
        PODInitDialog
        PODSparseInitDialog

        ToolMap
        DocToolMap

        OpenToolQueue
        CurrentIDs
    end

    properties (SetAccess=private)
        BTDocToolMgr
        MTDocToolMgr
        PZDocToolMgr
        PODDocToolMgr
    end

    properties (Access=private,WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
    end

    properties (Access=private,Transient)
        ToolInitListeners
        CreateReducedModelListeners
        DocToolDeletedListeners
        ToolDeletedListeners
        ModelDeletedListeners
        ModelRenamedListeners
        SparseToolOpenedListener
        CancelCurrentProcessListener
    end

    %% Events
    events
        CreateReducedModel
    end

    %% Constructor/destructor
    methods
        function this = ToolManager(App)
            arguments
                App (1,1) mrtool.internal.ModelReducerApp
            end            
            this.App = App;

            % create tools - Balanced Truncation
            this.BTDocToolMgr = mrtool.internal.managers.DocumentToolManager( ...
                this.App.BTDocGrpTag, App.Container, getString(message( ...
                'Control:mrtool:BalancedTruncationTab')));
            % create tools - Proper Orthogonal Decomposition
            this.PODDocToolMgr = mrtool.internal.managers.DocumentToolManager( ...
                this.App.PODDocGrpTag, App.Container, getString(message( ...
                'Control:mrtool:ProperOrthogonalDecompositionTab')));
            % create tools - Modal Truncation
            this.MTDocToolMgr = mrtool.internal.managers.DocumentToolManager( ...
                this.App.MTDocGrpTag, App.Container, getString(message( ...
                'Control:mrtool:ModalTruncationTab')));
            % create tools - Pole-Zero Simplification
            this.PZDocToolMgr = mrtool.internal.managers.DocumentToolManager( ...
                this.App.PZDocGrpTag, App.Container, getString(message( ...
                'Control:mrtool:PoleZeroSimplificationTab')));

            % tool map to manage deletion and other ops
            this.ToolMap = configureDictionary("string","cell");
            this.DocToolMap = configureDictionary("string","cell");

            weakThis = matlab.lang.WeakReference(this);
            this.CancelCurrentProcessListener = addlistener(this.App,"CancelCurrentProcess",@(es,ed) cbCancelOpenTool(weakThis.Handle));
        end
                
        function delete(this)
            delete(this.BTSparseInitDialog);
            delete(this.PODInitDialog);
            delete(this.PODSparseInitDialog);
            delete(this.MTSparseInitDialog);
            delete(this.ToolInitListeners);
            delete(this.CreateReducedModelListeners);
            delete(this.SparseToolOpenedListener);
            delete(this.DocToolDeletedListeners);
            delete(this.ToolDeletedListeners)
            delete(this.ModelDeletedListeners);
            delete(this.ModelRenamedListeners);
            toolIDs = keys(this.ToolMap);
            for ii = 1:numel(toolIDs)
                removeTool(this, toolIDs(ii));
            end
        end
    end

    %% Get/Set
    methods
        % Tools
        function Tools = get.Tools(this)
            Tools = values(this.ToolMap);
        end

        % DocTools
        function DocTools = get.DocTools(this)
            DocTools = values(this.DocToolMap);
        end
    end

    %% Public methods
    methods
        % save/load
        function loadSession(this, sessionData)
            % number of data models in session
            n = numel(sessionData);
            for ii = 1:n
                LoadedOptions = struct.empty;
                if issparse(sessionData{ii}.Target.System)
                    LoadedOptions = struct('Options',sessionData{ii}.ReduceSpec.Options,...
                        'FreqVector',sessionData{ii}.PlotFreqVector,'Method',sessionData{ii}.Method);
                elseif strcmp(sessionData{ii}.ToolType,'ProperOrthogonalDecomposition')
                    LoadedOptions = struct('Options',sessionData{ii}.ReduceSpec.Options,...
                        'Method',sessionData{ii}.Method);
                end
                enqueueTool(this,sessionData{ii}.ToolType, ...
                    sessionData{ii}.Target, sessionData{ii}.Target.Name,LoadedOptions)
            end
            if n ~= 0
                openTools(this);
            end
            for ii = 1:n
                id = sessionData{ii}.ToolType+"-"+sessionData{ii}.Target.Name;
                tool = this.ToolMap{id};
                loadSession(tool,sessionData{ii});
            end
        end
        
        function ToolSaveData = saveSession(this)
            ToolSaveData = cell(length(this.Tools),1);
            for ct=1:length(ToolSaveData)
                ToolSaveData{ct} = saveSession(this.Tools{ct});
            end
        end

        function enqueueTool(this, type, model, id, LoadedOptions)
            arguments
                this (1,1) mrtool.internal.managers.ToolManager
                type (1,1) string {mustBeMember(type,["BalancedTruncation" "ModalTruncation" "PoleZeroSimplification" "ProperOrthogonalDecomposition"])}
                model (1,1) mrtool.data.ModelWrapper
                id (1,1) string
                LoadedOptions struct {mustBeScalarOrEmpty} = struct.empty
            end
            toolData = struct('Type',type,'Model',model,'ID',id,'LoadedOptions',struct.empty);
            if ~isempty(LoadedOptions)
                toolData.LoadedOptions = LoadedOptions;
            end
            this.OpenToolQueue = [this.OpenToolQueue;toolData];
        end
        
        function openTools(this)
            tool2open = this.OpenToolQueue(1);
            type = tool2open.Type;
            model = tool2open.Model;
            id = tool2open.ID;
            id = strcat(type, '-', id);
            if isKey(this.ToolMap, id)
                docTool = this.DocToolMap{id};
                docTool.Document.Selected = true;
                advanceOpenToolQueue(this);
            else
                if issparse(model.System)
                    openSparseTool(this);
                    return
                end
                switch type
                    case 'BalancedTruncation'
                        openingMsg = getString(message( ...
                            'Control:mrtool:StatusMessageOpenBTTool'));
                        setWaiting(this.App, true, openingMsg);
                        tool = mrtool.internal.tools.BalancedTruncationTool(this.App,model);
                    case 'ProperOrthogonalDecomposition'
                        openPODTool(this);
                        return;
                    case 'ModalTruncation'
                        openingMsg = getString(message( ...
                            'Control:mrtool:StatusMessageOpenMTTool'));
                        setWaiting(this.App, true, openingMsg);
                        tool = mrtool.internal.tools.ModalTruncationTool(this.App,model);
                    case 'PoleZeroSimplification'
                        openingMsg = getString(message( ...
                            'Control:mrtool:StatusMessageOpenPZTool'));
                        setWaiting(this.App, true, openingMsg);
                        tool = mrtool.internal.tools.PoleZeroSimplificationTool(this.App,model);
                end
                connectToolForInit(this,tool);
                build(tool.ToolData);
                addTool(this, id, type, tool);
            end
        end
    end

    %% Private methods
    methods (Access=private)
        function openSparseTool(this)
            tool2open = this.OpenToolQueue(1);
            type = tool2open.Type;
            model = tool2open.Model;
            id = tool2open.ID;
            id = strcat(type, '-', id);
            switch type
                case 'BalancedTruncation'
                    openingMsg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenBTTool'));
                case 'ProperOrthogonalDecomposition'
                    openingMsg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenPODTool'));
                case 'ModalTruncation'
                    openingMsg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenMTTool'));
            end
            setWaiting(this.App, true, openingMsg);
            if isempty(tool2open.LoadedOptions)
                openSparseDialog(this, type, model, id);
            else %loading
                switch type
                    case 'BalancedTruncation'
                        tool = mrtool.internal.tools.BalancedTruncationTool(this.App,model,tool2open.LoadedOptions);
                    case 'ProperOrthogonalDecomposition'
                        tool = mrtool.internal.tools.ProperOrthogonalDecompositionTool(this.App,model,tool2open.LoadedOptions);
                    case 'ModalTruncation'
                        tool = mrtool.internal.tools.ModalTruncationTool(this.App,model,tool2open.LoadedOptions);
                end
                td = tool.ToolData;
                build(td);
                addTool(this,id,type,tool);
            end
        end

        function openSparseDialog(this, type, model, id)
            switch type
                case 'BalancedTruncation'
                    toolData = mrtool.data.BalancedTruncationData(model);
                    if isempty(this.BTSparseInitDialog) || ~isvalid(this.BTSparseInitDialog)
                        this.BTSparseInitDialog = mrtool.dialogs.SparseBalancedTruncationOptionsDialog(toolData);
                    end
                    dlg = this.BTSparseInitDialog;
                case 'ProperOrthogonalDecomposition'
                    toolData = mrtool.data.ProperOrthogonalDecompositionData(model);
                    if isempty(this.PODSparseInitDialog) || ~isvalid(this.PODSparseInitDialog)
                        this.PODSparseInitDialog = mrtool.dialogs.SparseProperOrthogonalDecompositionOptionsDialog(toolData);
                    end
                    dlg = this.PODSparseInitDialog;
                case 'ModalTruncation'
                    toolData = mrtool.data.ModalTruncationData(model);
                    if isempty(this.MTSparseInitDialog) || ~isvalid(this.MTSparseInitDialog)
                        this.MTSparseInitDialog = mrtool.dialogs.SparseModalTruncationOptionsDialog(toolData);
                    end
                    dlg = this.MTSparseInitDialog;
            end
            dlg.ToolData = toolData;
            show(dlg,this.App.Container);
            pack(dlg,'topleft');
            updateUI(dlg);
            setInitMode(dlg);
            weakThis = matlab.lang.WeakReference(this);
            delete(this.SparseToolOpenedListener);
            this.SparseToolOpenedListener = addlistener(dlg,'DialogClosed', ...
                @(es,ed) cbSparseDialogClosed(weakThis.Handle, type, model, id));
        end

        function cbSparseDialogClosed(this, type, model, id)
            switch type
                case 'BalancedTruncation'
                    dlg = this.BTSparseInitDialog;
                case 'ProperOrthogonalDecomposition'
                    dlg = this.PODSparseInitDialog;
                case 'ModalTruncation'
                    dlg = this.MTSparseInitDialog;
            end
            if dlg.Initialized
                switch type
                    case 'BalancedTruncation'
                        tool = mrtool.internal.tools.BalancedTruncationTool(this.App,model,dlg.InitData);
                    case 'ProperOrthogonalDecomposition'
                        tool = mrtool.internal.tools.ProperOrthogonalDecompositionTool(this.App,model,dlg.InitData);
                    case 'ModalTruncation'
                        tool = mrtool.internal.tools.ModalTruncationTool(this.App,model,dlg.InitData);
                end
                connectToolForInit(this,tool);
                td = tool.ToolData;
                try
                    build(td);
                catch ME
                    %try again
                    delete(this.ToolInitListeners);
                    show(dlg,this.App.Container);
                    pack(dlg,'topleft');
                    throwInitFailedError(dlg,ME);
                    return;
                end
                addTool(this,id,type,tool);
            else
                advanceOpenToolQueue(this);
            end
        end

        function openPODTool(this)
            tool2open = this.OpenToolQueue(1);
            model = tool2open.Model;
            id = tool2open.ID;
            id = strcat('ProperOrthogonalDecomposition', '-', id);
            openingMsg = getString(message( ...
                'Control:mrtool:StatusMessageOpenPODTool'));
            setWaiting(this.App, true, openingMsg);
            if isempty(tool2open.LoadedOptions)
                openPODDialog(this, model, id);
            else %loading
                tool = mrtool.internal.tools.ProperOrthogonalDecompositionTool(this.App,model,tool2open.LoadedOptions);
                build(tool.ToolData);
                addTool(this,id,'ProperOrthogonalDecomposition',tool);
            end
        end

        function openPODDialog(this, model, id)
            toolData = mrtool.data.ProperOrthogonalDecompositionData(model);
            if isempty(this.PODInitDialog) || ~isvalid(this.PODInitDialog)
                this.PODInitDialog = mrtool.dialogs.ProperOrthogonalDecompositionOptionsDialog(toolData);
            end
            dlg = this.PODInitDialog;
            dlg.ToolData = toolData;
            show(dlg,this.App.Container);
            pack(dlg,'topleft');
            updateUI(dlg);
            setInitMode(dlg);
            weakThis = matlab.lang.WeakReference(this);
            delete(this.SparseToolOpenedListener);
            this.SparseToolOpenedListener = addlistener(dlg,'DialogClosed', ...
                @(es,ed) cbPODDialogClosed(weakThis.Handle, model, id));
        end

        function cbPODDialogClosed(this, model, id)
            dlg = this.PODInitDialog;
            if dlg.Initialized
                tool = mrtool.internal.tools.ProperOrthogonalDecompositionTool(this.App,model,dlg.InitData);
                connectToolForInit(this,tool);
                td = tool.ToolData;
                try
                    build(td);
                catch ME
                    %try again
                    delete(this.ToolInitListeners);
                    show(dlg,this.App.Container);
                    pack(dlg,'topleft');
                    throwInitFailedError(dlg,ME);
                    return;
                end
                addTool(this,id,'ProperOrthogonalDecomposition',tool);
            else
                advanceOpenToolQueue(this);
            end
        end

        function advanceOpenToolQueue(this)
            this.OpenToolQueue = this.OpenToolQueue(2:end);
            if ~isempty(this.OpenToolQueue) % load next tool
                openTools(this);
            else
                setWaiting(this.App, false);
            end
        end

        function connectToolForInit(this,tool)
            L1 = addlistener(tool,'ComputingTargetSystem',@(es,ed) setWaiting(...
                this.App,true,getString(message('Control:mrtool:StatusMessageComputingTargetResponse'))));
            L2 = addlistener(tool,'ComputingReducedSystem',@(es,ed) setWaiting(...
                this.App,true,getString(message('Control:mrtool:StatusMessageComputingReducedModel'))));
            L3 = addlistener(tool,'PrintToApp',@(es,ed) setWaiting(this.App,true,ed.Data.Msg));
            this.ToolInitListeners = [L1 L2 L3];
        end

        function addTool(this, id, type, tool)
            switch type
                case 'BalancedTruncation'
                    openingMsg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenBTTool'));
                    setWaiting(this.App, true, openingMsg);
                    mgr = this.BTDocToolMgr;
                case 'ProperOrthogonalDecomposition'
                    openingMsg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenPODTool'));
                    setWaiting(this.App, true, openingMsg);
                    mgr = this.PODDocToolMgr;
                case 'ModalTruncation'
                    openingMsg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenMTTool'));
                    setWaiting(this.App, true, openingMsg);
                    mgr = this.MTDocToolMgr;
                case 'PoleZeroSimplification'
                    openingMsg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenPZTool'));
                    setWaiting(this.App, true, openingMsg);
                    mgr = this.PZDocToolMgr;
            end
            createPlot(tool.Document);
            build(tool.Tab);
            model = tool.Target;
            docTool = addMRDocTool(mgr, tool.Tab, tool.Document);
            this.ToolMap{id} = tool;
            this.DocToolMap{id} = docTool;
            this.App.IsDirty = true;
            idx = length(this.DocToolDeletedListeners)+1;
            this.CurrentIDs = [this.CurrentIDs;string(id)];
            delete(this.ToolInitListeners);
            if issparse(model.System)
                model.SparseFreqVector = tool.ToolData.PlotFreqVector;
            end
            weakThis = matlab.lang.WeakReference(this);
            this.DocToolDeletedListeners = [this.DocToolDeletedListeners;...
                addlistener(getDocument(docTool),'ObjectBeingDestroyed',@(es,ed) cleanupTool(weakThis.Handle,idx))];
            this.ToolDeletedListeners = [this.ToolDeletedListeners;...
                addlistener(tool,'ObjectBeingDestroyed',@(es,ed) cleanupTool(weakThis.Handle,idx))];
            this.ModelDeletedListeners = [this.ModelDeletedListeners;...
                addlistener(model,'ObjectBeingDestroyed',@(es,ed) cleanupTool(weakThis.Handle,idx))];
            this.ModelRenamedListeners = [this.ModelRenamedListeners;...
                addlistener(model,'Name','PostSet',@(es,ed) renameTool(weakThis.Handle,idx,ed.AffectedObject.Name))];
            this.CreateReducedModelListeners = [this.CreateReducedModelListeners;...
                addlistener(tool, 'CreateReducedModel',@(es,ed) createReducedModel(this.App, es, ed))];
            advanceOpenToolQueue(this);
        end

        function removeTool(this, id)
            tool = this.ToolMap{id};
            removeMRDocTool(this.BTDocToolMgr,tool.ID);
            removeMRDocTool(this.PODDocToolMgr,tool.ID);
            removeMRDocTool(this.MTDocToolMgr,tool.ID);
            removeMRDocTool(this.PZDocToolMgr,tool.ID);
            this.ToolMap(id) = [];
            this.DocToolMap(id) = [];
        end

        function cleanupTool(this,idx)
            delete(this.CreateReducedModelListeners(idx));
            delete(this.DocToolDeletedListeners(idx));
            delete(this.ModelDeletedListeners(idx));
            delete(this.ModelRenamedListeners(idx));
            removeTool(this,this.CurrentIDs(idx));
        end

        function renameTool(this,idx,name)
            currentId = char(this.CurrentIDs(idx));
            dash = strfind(currentId,'-');
            newId = string([currentId(1:dash(1)) char(name)]);
            this.CurrentIDs(idx) = newId;
            tool = this.ToolMap{currentId};
            this.ToolMap(currentId) = [];
            this.ToolMap{newId} = tool;
            docTool = this.DocToolMap{currentId};
            this.DocToolMap(currentId) = [];
            this.DocToolMap{newId} = docTool;
        end

        function cbCancelOpenTool(this)
            
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgt = qeGetWidgets(this)
            wdgt.BTSparseInitDialog = this.BTSparseInitDialog;
            wdgt.MTSparseInitDialog = this.MTSparseInitDialog;
            wdgt.PODInitDialog = this.PODInitDialog;
            wdgt.PODSparseInitDialog = this.PODSparseInitDialog;
        end
    end
end