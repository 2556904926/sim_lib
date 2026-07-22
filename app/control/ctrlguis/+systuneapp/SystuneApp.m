classdef (Hidden) SystuneApp < controllib.ui.internal.dialog.DialogManager
    %% Control System Tuner App

    % Previously named as SystuneTool.

    % Copyright 2013-2022 The MathWorks, Inc.

    %% Properties
    properties(Access=private)
        % App container
        ToolGroup
        ToolGroupListener

        % Tabs
        HomeTab
        SystuneTab
        TrimTab
        SnapshotTab

        % Data browser & data
        BaseWorkspace
        LocalWorkspace
        DataBrowserModel

        % Model viewer
        ModelICViewer

        % Messages
        WarningMessageOnLoad string
    end

    properties(SetAccess=private,GetAccess=public,SetObservable,Hidden)
        QEStatusBarMessage string
    end

    properties(Hidden, SetAccess = private, GetAccess=public)
        AppContainer
        ControlDesignData
        PlotManager
        EventManager
        TunableBlockEditorsManager
        RespPlotDocGrpTag = "CASTAppResponsePlotDocumentGroup";
        TuningGoalDocGrpTag = "CASTAppTuningGoalDocumentGroup";
        ParameterVariationDocGrpTag = "CASTAppParameterVariationDocumentGroup";
        AppTitle
        HelpButton
    end

    properties(Access=private,Transient=true)
        AppContainerListener
    end

    properties(SetAccess = private, GetAccess= public)
        WaitBar
        WaitBarLocked = false
        StatusBar
        StatusProgressBar
        ProgressBarContext
        StatusLabelContext
        StatusLabelAndButtonContext
        ResponsePlotDocumentGroup
        ContextualTabGroup
        ParameterVariationDocumentGroup
        ContextualDocCloseListener
        ParameterVariationDocument
        ContextualDocPropChangeListener
        CurrentContextualTab
        CurrentContextualTabTag
        CurrentContextualDocumentTag
        FigureClosingListener
    end


    %% Constructor & destructor
    methods
        function this = SystuneApp(model,tuningGoals)
            %% Creates an instance of the app.

            narginchk(1,2);
            if nargin == 1
                tuningGoals = [];
            end

            this.ControlDesignData = systuneapp.data.ControlDesignData(...
                updateTunableModel(this,model),tuningGoals);

            addAppContainer(this)
            addContextualHelpButton(this)
            addDataBrowsers(this)
            addPermanentTabs(this)
            addContextualTabs(this)
            addDocumentGroup(this)

            this.TunableBlockEditorsManager = systuneapp.managers.TunableBlockEditorsManager(this.ControlDesignData);
            this.PlotManager = systuneapp.managers.PlotManager_(this);

            % create Eventmanager
            this.EventManager = controllib.app.managers.eventmanager.internal.AppEventManager(this.AppContainer);

            installListeners(this)

            show(this)

            if ~isempty(this.WarningMessageOnLoad)
                uialert(this.AppContainer,this.WarningMessageOnLoad,getString(message('Control:systunegui:toolName')));
            end
        end

        function close(this)
            %% Closes the app.

            delete(this);
        end

        function delete(this)
            %% Releases resources.

            delete(this.FigureClosingListener)
            delete(this.ContextualDocCloseListener)
            delete(this.ContextualDocPropChangeListener)

            % Delete managers
            delete(this.PlotManager)
            delete(this.TunableBlockEditorsManager)
            
            % Delete data browsers
            delete(this.LocalWorkspace)
            % Delete BaseWorkspaceAdapter to avoid memory leak in MATLAB
            delete(this.BaseWorkspace)
            delete(this.DataBrowserModel)
        
            % Delete tool group
            delete(this.AppContainerListener)
            delete(this.AppContainer)
            
            % Delete tabs
            delete(this.TrimTab)
            delete(this.SnapshotTab)
            delete(this.HomeTab)
            delete(this.SystuneTab)
            
            % Delete data
            delete(this.ControlDesignData)
        end
        
    end


    %% Public methods
    methods
        function hideContextualDocument(this)
            %%
                this.ParameterVariationDocument.UserData.Visible = false;
                this.ParameterVariationDocument.Visible = false;
                %this.ParameterVariationDocument.Showing = false;
            
        end

        function showContextualDocument(this)
            %%
                this.ParameterVariationDocument.UserData.Visible = true;
                this.ParameterVariationDocument.Visible = true;
                %this.ParameterVariationDocument.Showing = true;            
        end
        

        function closeDocFigure(this)
            %%

            delete(this.ParameterVariationDocument.UserData)
        end

        function removeClientTabGroup(this,varargin)
            %% Temporary method.

            if ~isempty(this.ParameterVariationDocument) && isvalid(this.ParameterVariationDocument)
              this.AppContainer.closeDocument(...
                  this.ParameterVariationDocument.DocumentGroupTag, ...
                  this.ParameterVariationDocument.Title)

               this.CurrentContextualDocumentTag = [];
               delete(this.FigureClosingListener)
               delete(this.ContextualDocCloseListener)
               delete(this.ContextualDocPropChangeListener)
            end
            
            if ~isempty(this.CurrentContextualTab) && isvalid(this.CurrentContextualTab)
                this.ContextualTabGroup.remove(this.CurrentContextualTab)
                delete(this.CurrentContextualTab)

                this.CurrentContextualDocumentTag = [];
            end
        end

        function addClientTabGroup(this,document,tab)
            %% Add a contextual tab and document for parameter variation.
            
            % Show tab/document and return if they already exist
            if ~isempty(this.ParameterVariationDocument) && isvalid(this.ParameterVariationDocument)
                showContextualDocument(this)
                return
            end
            
            % Add tab
            add(this.ContextualTabGroup,tab)
            this.CurrentContextualTab = tab;           
            
            % Add document
            document.DocumentGroupTag = this.ParameterVariationDocumentGroup.Tag;
            this.ParameterVariationDocument = document;
            add(this.AppContainer,document)
            
            % Store tags for contextual tab/document
            this.CurrentContextualTabTag = this.CurrentContextualTab.Tag;
            this.CurrentContextualDocumentTag = this.ParameterVariationDocument.Tag;
            
        end

        function updateFigVisibility(this,flag)
            %%

            if nargin == 1
                flag = this.ParameterVariationDocument.Visible && ...
                    this.ParameterVariationDocument.Showing;
            end
            this.ParameterVariationDocument.UserData.Visible = flag;
        end

        function setWaiting(this,flag,msg)
            %% Shows progress bar in front of the app.
            if flag
                if nargin <3
                    msg = getString(message('Control:systunegui:msgForDataProcessing'));
                end
                this.WaitBar = uiprogressdlg(this.AppContainer,...
                    'Message',msg,...
                    'Title',this.AppTitle,...
                    'Indeterminate',true);
            else
                if ~isempty(this.WaitBar) && isvalid(this.WaitBar)
                    close(this.WaitBar);
                    this.WaitBar = [];
                end
            end
        end

        
        function showError(this,msg)
            %% Shows modal error.

            uialert(this.AppContainer,msg,this.AppTitle)
        end

        function showWarning(this,msg)
            %% Shows modal warning.
            
            uialert(this.AppContainer,msg,this.AppTitle,'Icon','warning')            
        end
        
        function promptForLoadSession(this)
            %% Prompt for loading a session.

            [filename, pathname] = uigetfile( ...
                {'*.mat';'*.*'}, ...
                getString(message('Control:systunegui:OpenCSTSession')));
            if ~isequal(filename,0) && ~isequal(pathname,0)
                % load the session file
                SessionFile = fullfile(pathname,filename);
                try
                    S = systuneapp.util.loadValidateSessionFile(SessionFile);
                catch ME
                    showError(this,ME.message)                    
                    return;
                end

                % Preload the session.
                preLoadSession(this,S.ControlSystemTunerSession,filename);
            end
        end

        function preLoadSession(this,SessionData,filename)
            %% Session preload tasks.
            % session data types are ml and sl
            % fresh tool only ml case, (ml,sl) types are loaded on current one
            % non-fresh tool case:
            % tool: ml, session: ml -> question if dirty, load on current one
            % tool: ml, session: sl -> question if dirty, load on current one
            % tool: sl1, session: ml -> create new and load on that
            % tool: sl1, session: sl2 -> create new and load on that
            % tool: sl1, session: sl1 -> question if dirty, load on current one
            % for new ones, calls preLoadSession again for the existing
            % sessions
            if isToolFresh(this)
                if isToolAndSessionModelSame(this,SessionData)
                    % same: load the session data to current one
                    loadSession(this,SessionData,filename);
                else
                    % different: open new one and load the session data to
                    % new one, close old one
                    Tool = createNewToolBasedOnSessionData(this,SessionData);
                    preLoadSession(Tool,SessionData,filename);
                    close(this);
                end
            else
                % tool is not fresh
                if isToolAndSessionModelSame(this,SessionData)
                    if this.isToolDirty
                        % same: ask question for save session, load on current
                        selection = askForSaveSessionBeforeLoad(this);
                        switch selection
                            case getString(message('Control:systunegui:YesLabel'))
                                promptForSaveSession(this);
                            case getString(message('Control:systunegui:NoLabel'))
                            case getString(message('Control:systunegui:CancelLabel'))
                                return;
                            otherwise
                                return;
                        end
                    end
                    loadSession(this,SessionData,filename);
                else
                    % different: open new one and load the session data to
                    % new one
                    Tool = createNewToolBasedOnSessionData(this,SessionData);
                    preLoadSession(Tool,SessionData,filename);
                end
            end
        end

        function loadSession(this,SessionData,filename)
            %% Loads a session

            % Check architecture.
            try
                systuneapp.util.validateArchitecture(SessionData.ControlDesignData.Architecture);
            catch Ex
                if strcmp(Ex.identifier,'SLControllib:opcond:OperatingPointNeedsUpdate')
                    showWarning(this, ...
                        getString(message('Control:systunegui:GeneralOperatingPointMismatch')))
                    SessionData.ControlDesignData.Architecture.OperatingPoints = [];
                end
            end
            setWaiting(this,true,getString(message('Control:systunegui:msgForLoadingSession')))
            this.WaitBarLocked = true;

            try
                % load data
                this.ControlDesignData.loadSession(SessionData.ControlDesignData);
                loadVariablesIntoLocalWorkspace(this,SessionData)
                % load tabs
                this.HomeTab.loadSession(SessionData);
                this.SystuneTab.loadSession(SessionData.SystuneTab);
                % load plot manager
                this.PlotManager.loadSession(SessionData.PlotManager);
                drawnow;
                setToolDirty(this,false);
                msg = getString(message( ...
                    'Control:systunegui:StatusMessageOpenedSession',filename));
            catch ME
                msg = getString(message( ...
                    'Control:systunegui:StatusMessageOpenSessionFailed',filename));
                showError(this,ME.message)
            end

            this.WaitBarLocked = false;
            setWaiting(this,false);
            if ~isempty(filename)
                postActionStatus(this.EventManager,'off',msg)
            end
        end

        function selection = askForSaveSessionBeforeLoad(this)
            %% Prompt for saving a session before loading another session.

            % Explain the user that loading a project resets the current session and prompt for saving.
            msg =  ctrlMsgUtils.message('Control:systunegui:SaveBeforeLoadQuestion');
            name = ctrlMsgUtils.message('Control:systunegui:SaveSession');
            yes = ctrlMsgUtils.message('Control:systunegui:YesLabel');
            no = ctrlMsgUtils.message('Control:systunegui:NoLabel');
            cancel = ctrlMsgUtils.message('Control:systunegui:CancelLabel');

            selection = uiconfirm(this.AppContainer,msg,name, ...
                'Options',{yes,no,cancel},'DefaultOption',yes);
        end
               
        function LocalVariables = saveVariablesInLocalWorkspace(this)
            %% Sets a variable in the local workspace of the app.

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

        function loadVariablesIntoLocalWorkspace(this,SessionData)
            %% Loads a variable into the local workspace of the app.

            localWorkspace = getLocalWorkspace(this);
            if isfield(SessionData,'LocalVariables')
                for ct = 1:numel(SessionData.LocalVariables)
                    assignin(localWorkspace,SessionData.LocalVariables(ct).Name,SessionData.LocalVariables(ct).Value);
                end
            end
        end

        function varname = getVariableName(this,prefix)
            %% Returns a local workspace variable name.

            % Get the local workspace
            localws = getLocalWorkspace(this);

            % Get the variable name
            varname = slctrlguis.lintool.getVariableName(localws,prefix);
        end

        function mdl = getModel(this)
            %% Returns the model name of the architecture.

            mdl = getArchitectureName(this.ControlDesignData);
        end
        
        function opviewer = getModelICViewer(this)
            %% Returns the architecture model's initial condition viewer. 

            if isempty(this.ModelICViewer)
                this.ModelICViewer = createView(...
                    slctrlguis.lintool.dialogs.op.ModelInitialConditionTC(...
                    operpoint(getModel(this))));
            end
            opviewer = this.ModelICViewer;
        end

        %% Tabs
        function hideTab(this,tabenum)
            removeTab(this.ToolGroup,tabenum.Name);
        end

        function setSelectedTab(this,tabname)
            % Make this the selected tab
            this.ToolGroup.SelectedTab = tabname;
        end

        function showTab(this,tab)
            ts = this.ToolGroup;
            existingtabs = ts.TabNames;
            % Add the tab if it is trim or snapshot and not added yet.
            tabenum = slctrlguis.lintool.TabEnum.getTab(tab.Name);
            if ~any(strcmp(tabenum.Name,existingtabs))
                switch tabenum
                    case slctrlguis.lintool.TabEnum.Trim
                        hideTab(this,slctrlguis.lintool.TabEnum.Snapshot);
                        add(ts,tab,3);
                    case slctrlguis.lintool.TabEnum.Snapshot
                        hideTab(this,slctrlguis.lintool.TabEnum.Trim);
                        add(ts,tab,3);
                end
            end
            % Make this the selected tab
            setSelectedTab(this,tab.Name);
        end

        % operating point tabs
        function showOPTab(this,tabenum)
            switch tabenum
                case slctrlguis.lintool.TabEnum.Trim
                    if isempty(this.TrimTab)
                        try
                            this.TrimTab = createTrimTab(this);
                        catch Ex
                            slcontrollib.internal.utils.nagctlr(getModel(getParent(this)),...
                                ctrlMsgUtils.message('SLControllib:general:SimulinkControlDesignProduct'),...
                                ctrlMsgUtils.message('SLControllib:general:SCDOperatingPoints'),...
                                Ex);
                            return;
                        end
                    end
                    showTab(this,getToolTab(this.TrimTab));
                case slctrlguis.lintool.TabEnum.Snapshot
                    if isempty(this.SnapshotTab)
                        this.SnapshotTab = slctrlguis.lintool.tabs.Snapshot(this);
                    end
                    showTab(this,getToolTab(this.SnapshotTab));
            end
        end

        function trimtab = createTrimTab(this)
            trimtab = slctrlguis.lintool.tabs.Trim(this);
        end

        %% Operating points
        % variables access
        function vars = getLocalOperatingPoints(this)
            lwks = getLocalWorkspace(this);
            vars = slctrlguis.lintool.getVariablesOfType(lwks,'opcond.OperatingPoint');
            vars = [vars;slctrlguis.lintool.getVariablesOfType(lwks,'opcond.OperatingReport')];
            % Eliminate those at other models
            vars = LocalEliminateOpForOtherModels(vars,getModel(this));
        end
        function vars = getBaseOperatingPoints(this)
            bwks = getBaseWorkspace(this);
            vars = slctrlguis.lintool.getVariablesOfType(bwks,'opcond.OperatingPoint');
            vars = [vars;slctrlguis.lintool.getVariablesOfType(bwks,'opcond.OperatingReport')];
            % Eliminate those at other models
            vars = LocalEliminateOpForOtherModels(vars,getModel(this));
        end
        % approve op update for op picker
        function isCompatible = opUpdateApproved(this,OpSelection)
            op = systuneapp.tabs.HomeTabNew.getOperatingPointFromSelection(OpSelection);
            [isCompatible,nOp,nParam] = this.ControlDesignData.isOpCompatible(op);

            if ~isCompatible
                showError(this,getString(message('Control:systunegui:LinearizationIncompatibleOPError',nOp,nParam)))
            end
        end

        %% Workspace access
        function basews = getBaseWorkspace(this)
            basews = this.BaseWorkspace;
        end
        function localws = getLocalWorkspace(this)
            localws = this.LocalWorkspace;
        end
    end

    methods (Hidden)

        function HomeTab = getHomeTab(this)
            % Get HomeTab
            HomeTab = this.HomeTab;
        end

        function DataBrowserModel = qeGetDataBrowserWidgets(this)
            % Access data browser widget objects for SystuneApp
            %   widgets = qeGetDataBrowserWidgets(app);

            DataBrowserModel = this.DataBrowserModel;

        end

        function SystuneTab = getSystuneTab(this)
            % Get Systyne Tab
            SystuneTab = this.SystuneTab;
        end

        function flag = isToolFresh(this)
            % only matlab case opens new session on fresh tool
            flag = this.ControlDesignData.isControlDesignDataFresh;
        end

        function TG = getToolGroup(this)
            TG = this;%.AppContainer;
        end

        function flag = isToolDirty(this)
            % Dirty actions:
            % CONTROLDESIGNDATA
            % TunableBlocks: add, remove, edit, sync from model, active
            % TuningGoals: add, remove, edit, active, hard
            % Responses: add, remove, edit
            % Design: store, delete, retrieve, compare (thru plot update)
            % Options: edit
            % Linearization (SL) and Configuration Change (ML)
            %   SL: oppoints, linoptions
            %   ML: arch change, plant value change
            % Session: load, save
            % PLOTMANAGER
            % Plots: ADD, DELETE, UPDATE (goal and response)

            flag = (this.ControlDesignData.IsDirty || this.PlotManager.IsDirty);
        end
        function setToolDirty(this,flag)
            % overrides isDirty algorithm by user
            this.ControlDesignData.setDirty(flag);
            this.PlotManager.setDirty(flag);
        end

        function name = getLocalWorkspaceName(this) %#ok<MANU> 
            name = ctrlMsgUtils.message('Control:systunegui:LocalWorkspaceName');
        end

        function hasSaved = promptForSaveSession(this,~)
            %% Prompt for saving a session before closing the app.

            [filename, pathname] = uiputfile( ...
                {'*.mat';'*.*'}, ...
                getString(message('Control:systunegui:SaveCSTSession')), ...
                getString(message('Control:systunegui:CSTSessionName')));
            if ~isequal(filename,0) && ~isequal(pathname,0)
                ControlSystemTunerSession = saveSession(this); %#ok<NASGU> 
                saveSession(this);
                save(fullfile(pathname, filename), getString(message('Control:systunegui:CSTSessionName')));
                output = true;
            else
                output = false;
            end
            if nargout > 0
                hasSaved = output;
            end
        end
        
    end

    %% Private methods.
    methods(Access=private)
        function addAppContainer(this)
            %% Adds an app container for this app.

            if isSimulink(this.ControlDesignData)
                this.AppTitle =  getString(message('Control:systunegui:toolTitle',getModel(this)));
            else
                this.AppTitle =  getString(message('Control:systunegui:toolTitleShort'));
            end

            appOptions.Title = this.AppTitle;
            appOptions.Tag = sprintf('Systune(%s%s)',getModel(this),matlab.lang.internal.uuid);
            appOptions.ToolstripEnabled = true;
            appOptions.DocumentPlaceHolderText = getString(message('Control:systunegui:toolDocPlaceholder'));
            appOptions.EnableTheming = true;
            this.AppContainer = matlab.ui.container.internal.AppContainer(appOptions);
        end

        function addContextualHelpButton(this)
            %% Adds an contextual help button to the app container.

            this.HelpButton = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            this.HelpButton.ButtonPushedFcn = @(varargin) helpview('control','ControlSystemTunerGeneralHelp');
            this.AppContainer.add(this.HelpButton);
        end

        function addDataBrowsers(this)
            %% Adds data browsers to the app container.

            this.BaseWorkspace = toolpack.databrowser.BaseWorkspaceAdapter;
            this.LocalWorkspace = toolpack.databrowser.LocalWorkspaceModel;
            this.DataBrowserModel = systuneapp.databrowser.CustomDataBrowser_(this);
        end

        function addPermanentTabs(this)
            %% Adds permanent tabs.

            % Tab group
            tabgroup = matlab.ui.internal.toolstrip.TabGroup();
            tabgroup.Tag = "CSTPermanentTabGroup";

            % Home Tab
            this.HomeTab = systuneapp.tabs.HomeTabNew(this);
            tabgroup.add(getTab(this.HomeTab));

            % SystuneTab (and pass system tuning data)
            this.SystuneTab = systuneapp.tabs.SystuneTabNew( ...
                systuneapp.data.SystuneTuningData(this.ControlDesignData),this);
            tabgroup.add(getTab(this.SystuneTab));

            % Add tab group to the app container.
            addTabGroup(this.AppContainer,tabgroup);
        end
        
        function addContextualTabs(this)
            %% Add contextual tabs.

            % Tab group
            contextualTabGroup = matlab.ui.internal.toolstrip.TabGroup();
            contextualTabGroup.Tag = "CSTAppContextualTabGroup";
            contextualTabGroup.Contextual = true;
            add(this.AppContainer,contextualTabGroup);

            this.ContextualTabGroup = contextualTabGroup;
        end

        function show(this)
            %% Shows the app container.

            this.AppContainer.Visible = true;
        end

        function installListeners(this)
            %% Installs listeners.

            this.AppContainerListener = addlistener(this.AppContainer,'StateChanged',@(es,ed) cbAppContainerStateChanged(this,es));
            this.AppContainer.CanCloseFcn = @(es,ed) cbAppContainerCanClose(this);
        end

        function cbAppContainerStateChanged(this,es)
            %% Callback function app container's state changed event.

            if es.State == matlab.ui.container.internal.appcontainer.AppState.TERMINATED
                delete(this);
            end
        end

        function canAppClose = cbAppContainerCanClose(this)
            %% Callback function to systematically close the app.

            canAppClose = true;
            if isToolDirty(this)
                canAppClose = askForSaveSession(this);
            end
        end

        function addDocumentGroup(this)
            %% Adds document groups.

            % Response plot document group
            groupOptions.Tag = this.RespPlotDocGrpTag;
            groupOptions.Title = getString(message('Control:systunegui:ResponsePlotTab'));
            responsePlotDocumentGroup = matlab.ui.internal.FigureDocumentGroup(groupOptions);
            add(this.AppContainer,responsePlotDocumentGroup)
            this.ResponsePlotDocumentGroup = responsePlotDocumentGroup;

            % Tuning goal document group
            groupOptions.Tag = this.TuningGoalDocGrpTag;
            groupOptions.Title = getString(message('Control:systunegui:TuningGoalPlotTab'));
            responsePlotDocumentGroup = matlab.ui.internal.FigureDocumentGroup(groupOptions);
            add(this.AppContainer,responsePlotDocumentGroup)
            this.ResponsePlotDocumentGroup = responsePlotDocumentGroup;

            % Parameter variation document group
            groupOptions.Tag = this.ParameterVariationDocGrpTag;
            groupOptions.Title = 'Parameter Variation Documents';%getString(message('Control:systunegui:_'));
            groupOptions.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
            groupOptions.Context.ToolstripTabGroupTags = this.ContextualTabGroup.Tag;
            parameterVariationDocumentGroup = matlab.ui.internal.FigureDocumentGroup(groupOptions);
            add(this.AppContainer,parameterVariationDocumentGroup)
            this.ParameterVariationDocumentGroup = parameterVariationDocumentGroup;
        end

        function SessionData = saveSession(this)
            %%

            SessionData = systuneapp.data.SessionData;
            SessionData.ControlDesignData = saveSession(this.ControlDesignData);
            SessionData.LocalVariables = saveVariablesInLocalWorkspace(this);
            SessionData.PlotManager = saveSession(this.PlotManager);
            SessionData.SystuneTab = saveSession(this.SystuneTab);
            SessionData.HomeTab = saveSession(this.HomeTab);
            setToolDirty(this,false);
        end

        function canAppClose = askForSaveSession(this)
            %%

            name = getString(message('Control:systunegui:SaveSession'));
            msg = getString(message('Control:systunegui:SaveSessionQuestion',this.getModel));
            yes = getString(message('Control:systunegui:YesLabel'));
            no = getString(message('Control:systunegui:NoLabel'));
            cancel = getString(message('Control:systunegui:CancelLabel'));

            selection = uiconfirm(this.AppContainer, ...
                msg,name,'Options', {yes,no,cancel},'DefaultOption',yes);

            switch selection
                case getString(message('Control:systunegui:YesLabel'))
                    canAppClose = promptForSaveSession(this);
                otherwise
                    canAppClose = true;
            end
        end
        
        function flag = isToolAndSessionModelSame(this,SessionData)
            % simulink type is true
            % matlab type false
            % Tool:ML Session:ML -> flag = true;
            % Tool:ML Session:SL -> flag = false;
            % Tool:SL Session:ML -> flag = false;
            % Tool:SL Session:SL -> flag = true; (model names are same)
            % Tool:SL Session:SL -> flag = false; (model names are different)
            ToolType = this.ControlDesignData.isSimulink;
            SessionType = isa(SessionData.ControlDesignData.Architecture,'slTuner');

            % flag = true, tool and session type are same
            flag = ~xor(ToolType,SessionType);

            if flag && ToolType && SessionType % tool and session is simulink, check model names are same
                if ~strcmp(this.ControlDesignData.getArchitectureName, ...
                        SessionData.ControlDesignData.Architecture.Model)
                    flag = false;
                end
            end
        end
        
        function tool = createNewToolBasedOnSessionData(this,sessionData) %#ok<INUSL> 
            if isa(sessionData.ControlDesignData.Architecture,'slTuner')
                tool = systuneapp.SystuneToolManager.getSystuneTool(sessionData.ControlDesignData.Architecture.Model);
            else
                tool = controlSystemTuner();
            end
        end
    
        function outputModel = updateTunableModel(this,inputModel)
            %% Checks and updates model type.

            w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
            restoreWarning = onCleanup(@()warning(w));
            if isa(inputModel,'slTuner')
                outputModel = inputModel;
            elseif ischar(inputModel) || isa(inputModel,'slTunable')
                outputModel = slTuner(inputModel);
            elseif isa(inputModel,'systuneapp.data.MatlabConfigData.Config1') || ...
                    isa(inputModel,'systuneapp.data.MatlabConfigData.AbstractConfig')
                outputModel = inputModel;
            else
                error(message('Control:systunegui:errInvalidModel'))
            end

            if isa(outputModel,'slTuner')
                [flag,names]=systuneapp.util.isPermanentOpeningExist(outputModel.Model);
                if flag
                    % prepare text
                    str = sprintf('%s\n',getString(message('Control:systunegui:slTunerPermanentOpeningWarning')));
                    for ct=1:numel(names)
                        str = [str sprintf('- %s\n',names{ct})]; %#ok<AGROW>
                    end
                    this.WarningMessageOnLoad = str;
                end
            end
        end
    end
end
%% Local functions


function vars = LocalEliminateOpForOtherModels(vars,mdl)
%% Eliminate those that belong to another model.

ind = true(size(vars));
for ct = 1:numel(vars)
    val = getValue(vars(ct));
    ind(ct) = all(strcmp(mdl,get(val,'Model')));
end
vars = vars(ind);
end
