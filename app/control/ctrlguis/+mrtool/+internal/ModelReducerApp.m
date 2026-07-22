classdef ModelReducerApp < controllib.ui.internal.dialog.DialogManager & ...
        matlab.mixin.SetGet
    % MODEL REDUCER APP 
    % Summary of this class goes here
    %
    % Copyright 2016 - 2024 The MathWorks, Inc.
    
    %% Properties
    properties (Hidden,SetObservable,SetAccess={?mrtool.internal.ModelReducerApp,...
            ?mrtool.internal.managers.PlotManager,...
            ?mrtool.internal.managers.ToolManager})
        % Dirty actions:
        % - import or remove model
        % - open tool
        % - create plot
        IsDirty
    end

    properties (Hidden,Constant)
        RespPlotDocGrpTag = "mr-document-plot-tab-group-"
        BTDocGrpTag = "mr-document-bt-tab-group-"
        PODDocGrpTag = "mr-document-pod-tab-group-"
        MTDocGrpTag = "mr-document-mt-tab-group-"
        PZDocGrpTag = "mr-document-pz-tab-group-"
    end

    properties (Hidden,SetAccess=immutable)
        % UUID for the App
        ID
    end
    
    properties (Hidden,SetAccess = private)
        % AppContainer
        Container
        QABHelpButton
        
        % Data
        Models
        
        % Managers
        ToolManager
        EventManager
        PlotManager
        
        % Tabs
        ReduceSystemTab
        PlotTab
        ContextualTabGroup
        DocumentGroup
        
        % Browsers
        ModelPanel
        
        % Dialogs
        ImportModelsDialog
        ExportModelsDialog
    end

    properties (Hidden,Dependent,SetAccess=private)
        SelectedModel
    end

    properties (Access=private)
        WaitBar
        WaitBarLocked = false
        WaitBarCanceledTimer
    end

    properties (Access = private, Transient)
        % Listeners
        ContainerListener
        DataChangedListeners
        ExportCompletedListener
    end
    
    %% Events
    events (Hidden)
        ModelsUpdated
        CancelCurrentProcess
    end

    %% Constructor/destructor
    methods
        function app = ModelReducerApp(ModelList)
            arguments
                ModelList (:,1) mrtool.data.ModelWrapper = mrtool.data.ModelWrapper.empty;
            end        
            app.ID = matlab.lang.internal.uuid;
            % create container to house Browser, Tabs, DocArea
            createAppContainer(app);
            updateTitleOnDirty(...
                controllib.ui.internal.dirtymgr.DirtyManager.getInstance(app.ID),...
                app.Container);
            
            % Create Dialog Manager
            attachDialogManagerToAppContainer(app, app.Container);
            
            % Create Plot Manager
            app.PlotManager = mrtool.internal.managers.PlotManager(app);            

            % create Tool Manager
            app.ToolManager = mrtool.internal.managers.ToolManager(app);

            % create Eventmanager
            app.EventManager = controllib.app.managers.eventmanager.internal.AppEventManager(app.Container);

            % create Data Browser components
            createDataBrowserManager(app);

            % create Reduced Tab and Plots Tab
            createPermanentTabs(app);           

            % create document groups
            createDocumentGroups(app);
 
            % create contextual tabs
            createContextualTabs(app);

            % create contextual help
            app.QABHelpButton = createContextualHelpButton(app);            
    
            connectUI(app);

            % Import models
            importModels(app, ModelList);
            if ~isempty(ModelList)
                selectModel(app.ModelPanel,1);
            end

            % Show App
            show(app);
            app.IsDirty = false;
            controllib.ui.internal.dirtymgr.DirtyManager.getInstance(app.ID).reset();
        end
        
        function delete(app)
            % Delete all existing components of the App     
            delete(app.ToolManager)
            delete(app.EventManager)
            delete(app.PlotManager)

            delete(app.ReduceSystemTab)
            delete(app.PlotTab)
            delete(app.ContextualTabGroup)
            delete(app.DocumentGroup)
            
            delete(app.ModelPanel)
            delete(app.Models)
            
            delete(app.ImportModelsDialog)
            delete(app.ExportModelsDialog)

            delete(app.WaitBar)
            if ~isempty(app.WaitBarCanceledTimer) && isvalid(app.WaitBarCanceledTimer)
                stop(app.WaitBarCanceledTimer);
                delete(app.WaitBarCanceledTimer);
            end

            delete(app.ExportCompletedListener)
            delete(app.ContainerListener)
            delete(app.DataChangedListeners)

            delete(app.Container)
        end   
    end

    %% Get/Set
    methods
        % SelectedModel
        function SelectedModel = get.SelectedModel(app)
            SelectedModel = app.ModelPanel.SelectedModel;
        end
        
        % IsDirty
        function set.IsDirty(app, flag)
            arguments
                app (1,1) mrtool.internal.ModelReducerApp
                flag (1,1) logical
            end
            app.IsDirty = flag;
            if flag
                setDirty(controllib.ui.internal.dirtymgr.DirtyManager.getInstance(app.ID)); %#ok<MCSUP>
            end
        end
    end

    %% Public Methods
    methods        
        %% UTILITIES        
        function show(app)
            app.Container.Visible = true;
        end
        
        function close(app)
            delete(app);
        end

        function setWaiting(app, flag, msg, cancelable)
            %% Shows progress bar in front of the app.
            arguments
                app (1,1) mrtool.internal.ModelReducerApp
                flag (1,1) logical
                msg (1,1) string = ""
                cancelable (1,1) logical = false
            end
            if ~app.WaitBarLocked
                if flag
                    newTimer = true;
                    if isempty(app.WaitBar) || ~isvalid(app.WaitBar)
                        app.WaitBar = uiprogressdlg(app.Container,...
                            Message=msg, ...
                            Title=app.Container.Title, ...
                            Indeterminate=true,...
                            Cancelable=cancelable);
                    else
                        app.WaitBar.Message = msg;
                        if app.WaitBar.Cancelable == cancelable
                            newTimer = false;
                        else
                            app.WaitBar.Cancelable = cancelable;
                        end
                    end
                    if cancelable && newTimer
                        if ~isempty(app.WaitBarCanceledTimer) && isvalid(app.WaitBarCanceledTimer)
                            stop(app.WaitBarCanceledTimer);
                            delete(app.WaitBarCanceledTimer);
                        end
                        weakApp = matlab.lang.WeakReference(app);
                        app.WaitBarCanceledTimer = timer;
                        app.WaitBarCanceledTimer.TimerFcn = @(es,ed) cbWaitBarCanceled(weakApp.Handle);
                        app.WaitBarCanceledTimer.ExecutionMode = 'fixedSpacing';
                        start(app.WaitBarCanceledTimer);
                    else
                        if ~isempty(app.WaitBarCanceledTimer) && isvalid(app.WaitBarCanceledTimer)
                            stop(app.WaitBarCanceledTimer);
                            delete(app.WaitBarCanceledTimer);
                        end
                    end
                else
                    if ~isempty(app.WaitBarCanceledTimer) && isvalid(app.WaitBarCanceledTimer)
                        stop(app.WaitBarCanceledTimer);
                        delete(app.WaitBarCanceledTimer);
                    end
                    delete(app.WaitBar);
                end
            end
        end
        
        %% IMPORT/EXPORT METHODS
        function importModels(app, data, isReducedModel)
            arguments
                app (1,1) mrtool.internal.ModelReducerApp
                data (:,1) mrtool.data.ModelWrapper
                isReducedModel (1,1) logical = false
            end
            for ct = 1:length(data)
                name = data(ct).Name;
                if isReducedModel
                    % check the word at the end is "Reduced"
                    newlabel = name+"Reduced"+mat2str(order(data.System));
                 else
                    newlabel = name;
                end
                if ~isempty(app.Models)                                      
                    name1 = matlab.lang.makeUniqueStrings( ...
                        newlabel, [app.Models.Name]);
                    if ~strcmpi(name,name1)
                        data(ct).Name = name1;                        
                    end
                end
                app.Models = [app.Models; data(ct)];
                weakApp = matlab.lang.WeakReference(app);
                app.DataChangedListeners = [app.DataChangedListeners...
                    addlistener(data(ct),'Name','PostSet',@(es,ed) notify(weakApp.Handle, 'ModelsUpdated'))];
            end 
            notify(app, 'ModelsUpdated');
            if ~app.Container.Busy % ignore while loading
                app.IsDirty = true;
            end
        end
        
        function removeModel(app, ModelArray)
            arguments
                app (1,1) mrtool.internal.ModelReducerApp
                ModelArray (:,1) mrtool.data.ModelWrapper
            end
            % ask whether to remove or cancel            
            for ii = 1:length(ModelArray)
                Model = ModelArray(ii);
                Tools = app.ToolManager.Tools;
                flag = zeros(size(Tools));
                for ct = 1:length(Tools)
                    flag(ct) = strcmp(Tools{ct}.Target.Name,Model.Name);
                end
                DeleteModel = true;

                if any(flag)
                    % ask question to remove tab
                    msg = getString(message('Control:mrtool:WarningRemoveModel', ...
                        Model.Name,Model.Name));
                    title = getString(message( ...
                        'Control:mrtool:WarningRemoveModelTitle'));
                    confirmOptions = {getString(message('Control:mrtool:Yes')), ...
                        getString(message('Control:mrtool:No')), ...
                        getString(message('Control:mrtool:Cancel'))};
                    selection = uiconfirm(app.Container, msg, title, ...
                        'Options', confirmOptions, 'DefaultOption', 1, ...
                        'CancelOption', 3);
                    switch selection
                        case getString(message('Control:mrtool:Yes'))
                            DeleteModel = true;
                        case getString(message('Control:mrtool:No'))
                            DeleteModel = false;
                        case getString(message('Control:mrtool:Cancel'))
                            DeleteModel = false;
                    end
                end
                % no open tab, we can delete safely
                if DeleteModel
                    delete(Model);
                    app.Models = app.Models(isvalid(app.Models));
                    notify(app, 'ModelsUpdated');
                    app.IsDirty = true;
                end
            end            
        end
    
        %% LOAD/SAVE SESSION
        % load
        function promptForLoadSession(app)
            [filename, pathname] = uigetfile( ...
                {'*.mat';'*.*'}, ...
                getString(message('Control:mrtool:OpenMRSession')));
            if ~isequal(filename,0) && ~isequal(pathname,0)
                % load the session file
                SessionFile = fullfile(pathname,filename);
                try
                    S = mrtool.util.validateSessionFile(SessionFile);
                catch ME
                    uialert(app.Container, ME.message, app.Container.Title);
                    return;
                end                    
             
                %% preload the session
                preLoadSession(app, S.ModelReducerSession,filename);
            end
        end

        function preLoadSession(app, SessionData, filename)
            % if tool is clean, open the session data on the existing app
            % if not, open the session data on a new app
            if ~app.IsDirty
                % Parse session data
                ToolSessionData = SessionData.Tools;
                for ii = 1:length(ToolSessionData)
                    %backwards compatibility
                    if strcmpi(ToolSessionData{ii}.ToolType,'ModeSelection')
                        ToolSessionData{ii}.ToolType = 'ModalTruncation';
                    end
                    ToolSessionData{ii}.ToolType = string(ToolSessionData{ii}.ToolType);
                    %license test
                    if strcmpi(ToolSessionData{ii}.ToolType,'BalancedTruncation')
                        data = ToolSessionData{ii};
                        if (isfield(data,'UseNCFTruncation') && data.UseNCFTruncation) &&...
                                (~license('test','Robust_Toolbox') || isempty(ver('robust')))
                            uialert(app.Container,...
                                getString(message('Control:mrtool:BTErrorLoadNeedsRobust'))...
                                ,getString(message('Control:mrtool:Error')))
                            return;
                        end
                    end
                end
                SessionData.Tools = ToolSessionData;
                % load message
                openingMsg = getString(message( ...
                    'Control:mrtool:StatusMessageOpeningSession', filename));
                % set App to be busy
                setWaiting(app, true, openingMsg);
                app.WaitBarLocked = true;
                % load session data
                try
                    loadSession(app, SessionData);
                    msg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenedSession',filename));
                catch ME
                    % set waiting bar and message
                    msg = getString(message( ...
                        'Control:mrtool:StatusMessageOpenSessionFailed',filename));
                    uialert(app.Container,ME.message,getString(message('Control:mrtool:Error')))
                end
                % set waiting bar and message
                app.WaitBarLocked = false;
                setWaiting(app, false);
                postActionStatus(app.EventManager, 'off', msg);
            else
                preLoadSession(modelReducer(), SessionData, filename);
            end
        end

        function loadSession(app, SessionData)
            % clear app
            app.Models=[];
            % load models  
            importModels(app, SessionData.Models);
            % load tools
            loadSession(app.ToolManager, SessionData.Tools);
            % load plot manager
            loadSession(app.PlotManager, SessionData.PlotManager);
            loadSession(app.PlotTab);
            % let others events to finish
            drawnow;
            app.IsDirty = false;
            controllib.ui.internal.dirtymgr.DirtyManager.getInstance(app.ID).reset();
        end

        % save
        function canAppClose = askForSaveSession(app)
            qstn = getString(message('Control:mrtool:SaveSessionQuestion'));
            name = getString(message('Control:mrtool:SaveSessionTitle'));
            yes = getString(message('Control:mrtool:Yes'));
            no = getString(message('Control:mrtool:No'));
            cancel = getString(message('Control:mrtool:Cancel'));
                    
            selection = uiconfirm(app.Container, ...
                qstn, name,'Options', {yes,no,cancel},'DefaultOption',yes);

            switch selection
                case getString(message('Control:mrtool:Yes'))
                    canAppClose = promptForSaveSession(app);
                case getString(message('Control:mrtool:No'))
                    canAppClose = true;
                case getString(message('Control:mrtool:Cancel'))
                    canAppClose = false;
                otherwise
                    canAppClose = true;
            end
        end     

        function hasSaved = promptForSaveSession(app)
            [filename, pathname] = uiputfile( ...
                {'*.mat';'*.*'}, ...
                getString(message('Control:mrtool:SaveMRSession')), ...
                getString(message('Control:mrtool:SessionName')));
            if ~isequal(filename,0) && ~isequal(pathname,0)
                ModelReducerSession = saveSession(app);
                save(fullfile(pathname, filename), 'ModelReducerSession');
                [~,name,~] = fileparts(filename);
                postActionStatus(app.EventManager, 'off', ...
                    getString(message('Control:mrtool:StatusMessageSavedSession',name)));
                output = true;
            else
                output = false;
            end
            hasSaved = output;
        end 

        function SessionData = saveSession(app)
            SessionData = mrtool.data.SessionData;
            % save session models
            SessionData.Models = app.Models;
            % save session for each open tool
            SessionData.Tools = saveSession(app.ToolManager);
            % save session for plot manager
            SessionData.PlotManager = saveSession(app.PlotManager);
            app.IsDirty = false;
            controllib.ui.internal.dirtymgr.DirtyManager.getInstance(app.ID).reset();
        end

        function openTools(app, methodName, models)
            arguments
                app (1,1) mrtool.internal.ModelReducerApp
                methodName (1,1) string {mustBeMember(methodName,["BalancedTruncation" "ModalTruncation" "PoleZeroSimplification" "ProperOrthogonalDecomposition"])}
                models (:,1) mrtool.data.ModelWrapper = app.SelectedModel
            end
            for ii = 1:numel(models)
                enqueueTool(app.ToolManager, methodName, models(ii), models(ii).Name);
            end
            openTools(app.ToolManager);
        end

        %% DIALOGS
         function showImportDialog(app)
            if isempty(app.ImportModelsDialog)
                app.ImportModelsDialog = mrtool.dialogs.ImportModelDialog( ...
                    app);
                show(app.ImportModelsDialog, app.Container, 'CENTER');
            else
                show(app.ImportModelsDialog, app.Container, 'CENTER');
                updateUI(app.ImportModelsDialog);
            end
         end

         function showExportDialog(app)
            if isempty(app.ExportModelsDialog)
                app.ExportModelsDialog = mrtool.dialogs.ExportModelDialog(app);
                weakApp = matlab.lang.WeakReference(app);
                app.ExportCompletedListener  = addlistener( ...
                    app.ExportModelsDialog,'ExportCompleted', ...
                    @(es,ed) cbExportCompletedPostMessage(weakApp.Handle,es,ed));
                show(app.ExportModelsDialog, app.Container, 'CENTER');
            else                
                show(app.ExportModelsDialog, app.Container, 'CENTER');
            end
         end

        function cbExportCompletedPostMessage(app,~,ed)
            names = ed.Data.VariableNames;
            Sentence = mrtool.util.createModelNameSentence(names);
            if isscalar(names)
                msg = getString(message('Control:mrtool:StatusMessageExportModel',Sentence));
            else
                msg = getString(message('Control:mrtool:StatusMessageExportModels',Sentence));
            end
            postActionStatus(app.EventManager,'off',msg);
        end
        
        %% Create Reduced Model
        function createReducedModel(this,~,ed)
            importModels(this, ed.Data.ReducedModel, true);
            msg = getString(message('Control:mrtool:StatusMessageReducedSystemCreated', ...
                ed.Data.ReducedModel.Name));
            postActionStatus(this.EventManager,'off',msg);
        end
    end
    
    %% Private Methods
    methods (Access = private)     
        %% Build UI Components
        function createAppContainer(app)
            appOptions.Title = getString(message('Control:mrtool:toolTitle'));
            appOptions.Tag = sprintf('model-reducer-%s',app.ID);
            appOptions.ToolstripEnabled = true;
            appOptions.DocumentPlaceHolderText = getString(message('Control:mrtool:toolDocPlaceholder'));
            appOptions.EnableTheming = true;
            app.Container = matlab.ui.container.internal.AppContainer(appOptions);
        end
        
        function createPermanentTabs(app)
            % creates perm tabs - home (model reducer), plot, view
            app.ReduceSystemTab = mrtool.internal.tabs.ReduceSystemTab(app);
            app.PlotTab = mrtool.internal.tabs.PlotTab(app);
            
            % create perm tab group
            tabGroup = matlab.ui.internal.toolstrip.TabGroup();
            tabGroup.Tag = sprintf('mr-permanent-tab-group-%s', app.ID);
           

            % add tabs to the group
            add(tabGroup,app.ReduceSystemTab.Tab);
            add(tabGroup,app.PlotTab.Tab);

            % add tab group to app container
            add(app.Container, tabGroup);
        end

        function createContextualTabs(app)
            contextualTabGroup = matlab.ui.internal.toolstrip.TabGroup();
            contextualTabGroup.Tag = sprintf('mr-contextual-tab-group-%s', app.ID);
            contextualTabGroup.Contextual = true;
            add(app.Container, contextualTabGroup);

            app.ContextualTabGroup = contextualTabGroup;
        end
        
        function createDocumentGroups(app)
            % Response plot document group
            groupOptions.Tag = sprintf(app.RespPlotDocGrpTag, app.ID);
            groupOptions.Title = getString(message('Control:mrtool:PlotTab'));
            DocGroup = matlab.ui.internal.FigureDocumentGroup(groupOptions);
            add(app.Container, DocGroup)
            app.DocumentGroup = DocGroup;
        end

        function helpButton = createContextualHelpButton(app)
            helpButton = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            helpButton.ButtonPushedFcn = @(es,ed) helpview('control','ModelReducerGeneral');
            app.Container.add(helpButton);
        end
        
        function createDataBrowserManager(app)            
            % create Model Browser
            app.ModelPanel = mrtool.internal.databrowser.ModelPanel(app);
            addToAppContainer(app.ModelPanel, app.Container);            
        end    
   
        %% Callbacks
        function connectUI(app)
            weakApp = matlab.lang.WeakReference(app);
            app.ContainerListener = addlistener(app.Container,'StateChanged',@(es,ed) cbAppContainerStateChanged(weakApp.Handle,es));
            app.Container.CanCloseFcn = @(es,ed) cbAppContainerCanClose(weakApp.Handle);            
        end

        function cbAppContainerStateChanged(app, es)
            if es.State == matlab.ui.container.internal.appcontainer.AppState.TERMINATED
                delete(app);
            end
        end

        function canAppClose = cbAppContainerCanClose(app)
            if app.IsDirty
                canAppClose = askForSaveSession(app);
            else
                canAppClose = true;
            end
        end          

        function cbWaitBarCanceled(app)
            if app.WaitBar.CancelRequested
                stop(app.WaitBarCanceledTimer);
                delete(app.WaitBarCanceledTimer);
                notify(app,'CancelCurrentProcess');
                setWaiting(app,false);
            end
        end
    end    

    %% Hidden methods
    methods (Hidden)
        function qeSetDirty(app,flag)
            app.IsDirty = flag;
        end

        function tools = qeGetOpenTools(app)
            tools = app.ToolManager.Tools;
        end

        function wdgts = qeGetWidgets(app)
            wdgts.Container = app.Container;
            wdgts.EventManager = app.EventManager;
            wdgts.PlotManager = app.PlotManager;
            wdgts.ModelPanel = app.ModelPanel;

            wdgts.Tools = app.ToolManager.Tools;

            wdgts.Dialogs.Import = app.ImportModelsDialog;
            wdgts.Dialogs.Export = app.ExportModelsDialog;

            wdgts.Tool.ReduceSystem = app.ReduceSystemTab;
            wdgts.Tool.Plot = app.PlotTab;

            wdgts.Tabs.ReduceSystemTab = app.ReduceSystemTab.Tab;
            wdgts.Tabs.PlotTab = app.PlotTab.Tab;
            
            wdgts.QABHelpButton = app.QABHelpButton;      
        end
    end
end

