classdef ControlSystemDesignerApp < controllib.ui.internal.dialog.DialogManager & controllib.ui.internal.assessment.TrainingServiceAssessmentInterface
    % Control System Designer App

    % Copyright 2013-2021 The MathWorks, Inc.

    properties (Access = private)
        % App Container
        AppContainer

        % Tabs
        HomeTab

        % Data
        DesignerData
        Preferences

        % Managers
        DataBrowserManager
        PlotsManager
        ToolsManager
        EventManager

        % DataBrowsers
        ControllerBrowser
        DesignBrowser
        ResponseBrowser
        PreviewPanel

        % Editorsedit
        CompensatorEditor
        ConstraintEditor

        % Dirty flag
        IsDirty = false

        WaitBar
        WaitBarLocked = false
    end

    properties (Access = private, Transient = true)
        AppContainerListener
    end

    methods
        %% Constructor
        function this = ControlSystemDesignerApp(Arch)
            % Control System Designer App
            % ControlSystemDesignerApp(Model)
            %    Model is a Simulink Model Name
            % ControlSystemDesignerApp(slTuner)
            %    slTuner is a slTuner object
            % ControlSystemDesignerApp(Architecture)
            %    Architecture is a MATLAB Architecture
            %             narginchk(1,1);

            % Main Data
            this.DesignerData = ctrlguis.csdesignerapp.data.internal.DesignerData(Arch);

            if isSimulink(this.DesignerData)
                setTool(this.DesignerData.getArchitecture,this);
            end
            % Initialize Preferences
            this.Preferences = ctrlguis.csdesignerapp.data.preferences.internal.Preferences(this);
            this.DesignerData.Preferences = this.Preferences;

            % Set preferences in designer deata
            setFormat(this.DesignerData, this.Preferences.CompensatorFormat);

            % Create constraint editor
            this.ConstraintEditor = ctrlguis.csdesignerapp.dialogs.internal.ConstraintEditor([]);

            % Create App Container
            createAppContainer(this)
            updateTitleOnDirty(...
                controllib.ui.internal.dirtymgr.DirtyManager.getInstance(this.DesignerData.UniqueName),...
                this.AppContainer);

            % Add contextual help
            addContextualHelpButton(this);

            % Create Dialog Manager
            attachDialogManagerToAppContainer(this,this.AppContainer);

            % DataBrowser
            addDataBrowserManager(this)

            % Plot Manager
            this.PlotsManager = ctrlguis.csdesignerapp.managers.internal.PlotsManager(this);

            % Eventmanager
            this.EventManager = controllib.app.managers.eventmanager.internal.AppEventManager(this.AppContainer);

            % Tools Manager
            this.ToolsManager = ctrlguis.csdesignerapp.managers.internal.ToolsManagerNew(...
                this, this.EventManager, this.PlotsManager, this.DesignerData, this.Preferences,@(Block) editCompensator(this,Block),this.ConstraintEditor);

            % Permanent Tabs (Home Tab Requires ToolsManager)
            createPermanentTabs(this)

            % Install client listeners
            installListeners(this);



            % Show GUI (Don't show before configuring plots)
            show(this);

            % Add undo/redo keyboard shortcut
            % REVISIT
            %             addUndoRedoKeyboardShortcuts(this.HomeTab);

            if isSimulink(Arch) && isempty(getTunedBlocks(Arch))
                openArchitectureDialog(this.HomeTab);
            end
        end

        function Data = getData(this)
            %% Return the designer app data
            Data = this.DesignerData;
        end

        function editCompensator(this,Block)
            idx = find(Block == getTunableBlocks(this.DesignerData));
            if isobject(this.CompensatorEditor) && isvalid(this.CompensatorEditor)
                % setTarget(this.CE,idx)
                
                % update the index
                set(this.CompensatorEditor, 'CompensatorIndex', idx);
                show(this.CompensatorEditor, this.AppContainer, 'CENTER');
            else
                % this.CE = ctrlguis.csdesignerapp.dialogs.internal.CompensatorEditor( ...
                %     this.DesignerData,this);
                % setTarget(this.CE,idx);
                this.CompensatorEditor = ctrlguis.csdesignerapp.dialogs. ...
                    internal.CompEditor(this, this.DesignerData, idx);
                
                show(this.CompensatorEditor, this.AppContainer, 'CENTER');

                % register with DialogManager
                registerDialog(this, this.CompensatorEditor);
                addlistener(this.CompensatorEditor, 'CloseEvent', ...
                            @(src, evt)deleteDialog(this, src.Name));
                
            end
        end

        function Pref = getPreferences(this)
            %% Return the preferences
            Pref = this.Preferences;
        end

        function EM = getEventManager(this)
            %% Return the event manager
            EM = this.EventManager;
        end

        function TM = getToolsManager(this)
            %% Return the tools manager
            TM = this.ToolsManager;
        end

        function DMM = getDialogManagerModel(this)
            DMM = this.DialogManagerModel;
        end

        %% Load/save
        function SessionData = saveSession(this)
            %% Save session data
            SessionData = ctrlguis.csdesignerapp.data.internal.SessionData;
            DD = saveSession(this.DesignerData);
            SessionData.LocalVariables = DD.LocalVariables;
            SessionData.DesignerData = DD;
            SessionData.PlotsManager = saveSession(this.PlotsManager);
            SessionData.ToolsManager = saveSession(this.ToolsManager);
            SessionData.Preferences = saveSession(this.Preferences);
            setToolDirty(this,false);
            controllib.ui.internal.dirtymgr.DirtyManager.getInstance(this.DesignerData.UniqueName).reset();

        end
        function loadSession(this,SavedSession)
            try
                setWaiting(this, true, getString(message('Control:designerapp:msgLoadingApp')));
                this.WaitBarLocked = true;

                % Remove already existing dialogs
                removeDialogs(this.ToolsManager);
                % Remove home tab and recreate

                %% Load session data
                isSimulink_Current = isSimulink(this.DesignerData);
                if isa(SavedSession, 'sisodata.design')
                    NewSession = ctrlguis.csdesignerapp.data.internal.SessionData;
                    [NewSession.DesignerData, ~, LoopIdxMapping] = upgradeToLatest(this.DesignerData, SavedSession);
                    loadSession(this.DesignerData,NewSession.DesignerData);
                    Responses = this.DesignerData.getResponses;
                    Design = SavedSession(1);
                    Loops = Design.Loops;
                    for ct = 1:numel(Loops)
                        NewIdx = LoopIdxMapping((LoopIdxMapping(:,1) == ct),2);
                        for ct2 = 1:numel(Design.(Loops{ct}).View)
                            createGraphicalEditor(this.ToolsManager, Design.(Loops{ct}).View{ct2},Responses(NewIdx));
                        end
                    end
                else
                    if isfield(SavedSession, 'Projects')
                        ME = MException('Control:designerapp:ErrorCETMSession',...
                            getString(message('Control:designerapp:ErrorCETMSession')));
                        throw(ME);
                    elseif isfield(SavedSession, 'ControlSystemDesignerSession')
                        % Latest version
                        SessionData = SavedSession.ControlSystemDesignerSession;
                    elseif isa(SavedSession, 'ctrlguis.csdesignerapp.data.internal.SessionData')
                        SessionData = SavedSession;
                    elseif isa(SavedSession, 'sisodata.session')
                        SessionData = LocalUpgradeToLatest(this,SavedSession);
                    elseif isfield(SavedSession,'SessionData')
                        SS = LocalUpgradeToCETM(this,SavedSession.SessionData);
                        SessionData = LocalUpgradeToLatest(this,SS);
                    else
                        % Older version to CETM
                        SS = LocalUpgradeToCETM(this,SavedSession);
                        % CETM to Latest version
                        SessionData = LocalUpgradeToLatest(this,SS);
                    end

                    % If loaded session is from Simulink and the Model
                    % property of the SLTuner object is empty (failed to
                    % load SLTuner object)
                    if isfield(SessionData.DesignerData.Architecture,'Data') && ...
                            SessionData.DesignerData.Architecture.Data.BadConstruction
                        throw(SessionData.DesignerData.Architecture.Data.ConstructionError);
                    end

                    loadSession(this.DesignerData,SessionData.DesignerData);
                    isSimulink_New = isSimulink(this.DesignerData);

                    if isSimulink_Current~=isSimulink_New
                        % Loading a ML session on a SL session or vice
                        % versa
                        recreateHomeTab(this);
                    end
                    %                     pause(2);
                    loadSession(this.PlotsManager,SessionData.PlotsManager);

                    Anchor = this.HomeTab.getWidgets.TuningMethodSection.TuningMethodButton;
                    loadSession(this.ToolsManager,SessionData.ToolsManager,Anchor);

                    if ~isempty(SessionData.Preferences)
                        loadSession(this.Preferences,SessionData.Preferences);
                    end

                    recreateCompensatorEditor(this);

                    %Update home tab (e.g. multi model button system data may have changed)
                    update(this.HomeTab);
                end
                % Tile documents if needed
                if ctrlguis.csdesignerapp.utils.internal.CustomSettings.getUseDocumentTiling
                    layoutPlotDocumentsWhenReady(this);
                end
                % Recreate the controller browser context menu
                resetContextMenu(this.ControllerBrowser);
                this.WaitBarLocked = false;
                setWaiting(this, false);
                setToolDirty(this,false);
            catch ME
                this.WaitBarLocked = false;
                setWaiting(this, false);
                rethrow(ME);
            end
        end
        
        function hasSaved = saveSessionPrompt(this,~)
            %% Save session prompt
            [filename, pathname] = uiputfile( ...
                {'*.mat';'*.*'}, ...
                getString(message('Control:designerapp:SaveCSDSession')), ...
                getString(message('Control:designerapp:CSDSessionName')));
            if ~isequal(filename,0) && ~isequal(pathname,0)
                ControlSystemDesignerSession = saveSession(this);
                save(fullfile(pathname, filename), getString(message('Control:designerapp:CSDSessionName')));
                hasSaved = true;
            else
                hasSaved = false;
            end
        end
        
        function askForSaveSession(this)
            % Ask if user would like to save the session
            uiconfirm(this.AppContainer,...
                getString(message('Control:designerapp:SaveSessionQuestion',this.getModel)),...
                getString(message('Control:designerapp:SaveSession')),...
                "Options",{getString(message('Control:designerapp:YesLabel')),...
                getString(message('Control:designerapp:NoLabel')),...
                getString(message('Control:designerapp:CancelLabel'))},...
                "DefaultOption",getString(message('Control:designerapp:YesLabel')),...
                "CloseFcn", @(es,ed) cbUIConfirmClosed(es,ed));
            
            function cbUIConfirmClosed(~,ed)
                % Save session if Yes selected
                switch ed.SelectedOption
                    case getString(message('Control:designerapp:YesLabel'))
                        canAppClose = saveSessionPrompt(this,true);
                    case getString(message('Control:designerapp:NoLabel'))
                        canAppClose = true;
                    case getString(message('Control:designerapp:CancelLabel'))
                        canAppClose = false;
                    otherwise
                        canAppClose = false;
                end
                % Close app (if Yes or No selected)
                if canAppClose
                    close(this);
                end
            end
        end


        %% Client Utilities
        function addFigure(this, fig)
            addFigure(this.AppContainer,fig);
        end

        function setWaiting(this,flag,msg)
            if flag
                this.WaitBar = uiprogressdlg(this.AppContainer,...
                    'Message',msg,...
                    'Title',getAppTitle(this),...
                    'Indeterminate',true);
            else
                if ~isempty(this.WaitBar) && isvalid(this.WaitBar)
                    close(this.WaitBar);
                end
            end
        end

        function flag = isWaiting(this)
            if ~isempty(this.WaitBar)
                flag = isvalid(this.WaitBar);
            else
                flag = false;
            end
        end

        function varname = getVariableName(this,prefix)
            % Get the local workspace
            localws = getLocalWorkspace(this);

            % Get the variable name
            varname = slctrlguis.lintool.getVariableName(localws,prefix);
        end

        %% Public Get API
        function mdl = getModel(this)
            %mdl = this.Model;
            mdl = getArchitectureName(this.DesignerData);
        end

        function AppContainer = getAppContainer(this)
            AppContainer = this.AppContainer;
        end

        function recreateCompensatorEditor(this)
            close(this.CompensatorEditor);
        end

        function recreateHomeTab(this)
            CurrentTab = getTab(this.HomeTab);
            homeTabGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("HomeTabGroup");
            tabgroup = getTabGroup(this.AppContainer,homeTabGroupTag);
            remove(tabgroup, CurrentTab);
            delete(this.HomeTab);
            this.HomeTab = ctrlguis.csdesignerapp.tabs.internal.HomeTabNew(this);
            add(tabgroup,getTab(this.HomeTab));
        end

        %% Listeners
        function installListeners(this)
            % Group events
            this.AppContainerListener = addlistener(this.AppContainer,'StateChanged',@(es,ed) cbAppContainerStateChanged(this,es,ed));
            this.AppContainer.CanCloseFcn = @(es,ed) cbAppContainerCanClose(this);
        end

        function cbAppContainerStateChanged(this,es,ed)
            if es.State == matlab.ui.container.internal.appcontainer.AppState.TERMINATED
                delete(this);
            end
        end

        function canAppClose = cbAppContainerCanClose(this)
            if isToolDirty(this)
                askForSaveSession(this);
                canAppClose = false;
            else
                canAppClose = true;
            end
        end

        %% Open/Close
        function show(this)
            this.AppContainer.Visible = true;
            %             pause(1);
        end

        function close(this)
            delete(this);
        end

        function delete(this)
            % Delete managers
            % Delete the data browser
            if ~isempty(this.DataBrowserManager) && isvalid(this.DataBrowserManager)
                delete(this.DataBrowserManager);
            end

            % Delete the Plot Manager
            if ~isempty(this.PlotsManager) && isvalid(this.PlotsManager)
                delete(this.PlotsManager);
            end

            % Delete the Tools Manager
            if ~isempty(this.ToolsManager) && isvalid(this.ToolsManager)
                delete(this.ToolsManager);
            end

            % Delete HomeTab
            if ~isempty(this.HomeTab) && isvalid(this.HomeTab)
                delete(this.HomeTab);
            end

            % Delete tool group
            if ~isempty(this.AppContainer) && isvalid(this.AppContainer)
                delete(this.AppContainer);
            end

            % Delete data
            if ~isempty(this.DesignerData) && isvalid(this.DesignerData)
                delete(this.DesignerData);
            end
        end



    end

    methods (Access = private)
        function createAppContainer(this)
            % Build App Container

            % AppContainer
            appOptions.Title = getAppTitle(this);
            appOptions.Tag = sprintf('ControlSystemDesigner(%s)',matlab.lang.internal.uuid);
            appOptions.ToolstripEnabled = true;
            appOptions.EnableTheming = true;
            this.AppContainer = matlab.ui.container.internal.AppContainer(appOptions);

            % PlotDocumentGroup
            groupOptions.Tag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(...
                "ResponsePlotDocumentGroup");
            groupOptions.Title = getString(message('Control:designerapp:strResponsePlot'));
            responsePlotDocumentGroup = matlab.ui.internal.FigureDocumentGroup(groupOptions);
            add(this.AppContainer,responsePlotDocumentGroup);

            % BodeEditorTabGroup
            bodeEditorTabGroup = matlab.ui.internal.toolstrip.TabGroup();
            bodeEditorTabGroup.Tag = ...
                ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("BodeEditorTabGroup");
            bodeEditorTabGroup.Contextual = true;
            add(this.AppContainer,bodeEditorTabGroup);

            % BodeEditorDocumentGroup
            groupOptions.Tag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(...
                "BodeEditorDocumentGroup");
            groupOptions.Title = getString(message('Control:designerapp:strBodeEditor'));
            groupOptions.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
            groupOptions.Context.ToolstripTabGroupTags = bodeEditorTabGroup.Tag;
            bodeEditorDocumentGroup = matlab.ui.internal.FigureDocumentGroup(groupOptions);
            add(this.AppContainer,bodeEditorDocumentGroup);

            % RootLocusEditorTabGroup
            rootLocusEditorTabGroup = matlab.ui.internal.toolstrip.TabGroup();
            rootLocusEditorTabGroup.Tag = ...
                ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("RootLocusEditorTabGroup");
            rootLocusEditorTabGroup.Contextual = true;
            add(this.AppContainer,rootLocusEditorTabGroup);

            % RootLocusEditorDocumentGroup
            groupOptions.Tag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(...
                "RootLocusEditorDocumentGroup");
            groupOptions.Title = getString(message('Control:designerapp:strRootLocusEditor'));
            groupOptions.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
            groupOptions.Context.ToolstripTabGroupTags = rootLocusEditorTabGroup.Tag;
            rootLocusEditorDocumentGroup = matlab.ui.internal.FigureDocumentGroup(...
                groupOptions);
            add(this.AppContainer,rootLocusEditorDocumentGroup);

            % NicholsEditorTabGroup
            nicholsEditorTabGroup = matlab.ui.internal.toolstrip.TabGroup();
            nicholsEditorTabGroup.Tag = ...
                ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("NicholsEditorTabGroup");
            nicholsEditorTabGroup.Contextual = true;
            add(this.AppContainer,nicholsEditorTabGroup);

            % NicholsEditorDocumentGroup
            groupOptions.Tag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(...
                "NicholsEditorDocumentGroup");
            groupOptions.Title = getString(message('Control:designerapp:strNicholsEditor'));
            groupOptions.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
            groupOptions.Context.ToolstripTabGroupTags = nicholsEditorTabGroup.Tag;
            nicholsEditorDocumentGroup = matlab.ui.internal.FigureDocumentGroup(...
                groupOptions);
            add(this.AppContainer,nicholsEditorDocumentGroup);
        end

        function ToolTitle = getAppTitle(this)
            % Get App Title
            if isSimulink(this.DesignerData)
                ToolTitle =  getString(message('Control:designerapp:strToolTitle',getModel(this)));
            else
                ToolTitle =  getString(message('Control:designerapp:strToolTitleShort'));
            end

        end

        function createPermanentTabs(this)
            %% Create Permenant Tabs
            % Home Tab
            this.HomeTab = ctrlguis.csdesignerapp.tabs.internal.HomeTabNew(this);
            tabgroup = matlab.ui.internal.toolstrip.TabGroup();
            tabgroup.Tag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("HomeTabGroup");
            tabgroup.add(getTab(this.HomeTab));
            add(this.AppContainer,tabgroup);
        end

        function addDataBrowserManager(this)
            import ctrlguis.csdesignerapp.databrowser.internal.*
            %% Add Data Browser Manager
            this.ControllerBrowser = ctrlguis.csdesignerapp.databrowser.internal.ControllerBrowser(this);
            addToAppContainer(this.ControllerBrowser,this.AppContainer);

            this.DesignBrowser = ctrlguis.csdesignerapp.databrowser.internal.DesignBrowser(this);
            addToAppContainer(this.DesignBrowser,this.AppContainer);

            this.ResponseBrowser = ctrlguis.csdesignerapp.databrowser.internal.ResponseBrowser(this);
            addToAppContainer(this.ResponseBrowser,this.AppContainer);

            this.PreviewPanel = ctrlguis.csdesignerapp.databrowser.internal.PreviewPanel(...
                'previewpanel',getString(message('Controllib:gui:DatabrowserPreview')));
            addToAppContainer(this.PreviewPanel,this.AppContainer);

            monitor(this.PreviewPanel,this.ControllerBrowser);
            monitor(this.PreviewPanel,this.DesignBrowser);
            monitor(this.PreviewPanel,this.ResponseBrowser);


        end

        function addContextualHelpButton(this)
            helpButton = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            helpButton.ButtonPushedFcn = @(varargin) ctrlguihelp('ControlSystemDesignerGeneralHelp');
            this.AppContainer.add(helpButton);
        end
    end

    methods (Hidden)
        function PManager = getPlotsManager(this)
            PManager = this.PlotsManager;
        end

        function createPlots(this, AnalysisView, DesignViews)
            Responses = getResponses(this.getData);
            if ~isempty(Responses)
                isL = isLoopTransfer(Responses);
                Loops = Responses(isL);
                ClosedLoop = Responses(~isL);

                TM = getToolsManager(this);

                [b,idx] = ismember('filter',DesignViews);
                if b
                    createGraphicalEditor(TM,'bode',ClosedLoop(1));
                end

                DesignViews = sort([DesignViews(1:idx-1);DesignViews(idx+1:end)]);

                for ct1=1:numel(Loops)
                    for ct2 = 1:numel(DesignViews)
                        if ~strcmpi(DesignViews{ct2},'filter')
                            createGraphicalEditor(TM,DesignViews{ct2},Loops(ct1));
                        end
                    end
                end

                PM = getPlotsManager(this);
                if AnalysisView && ~isa(ClosedLoop(1).getValue,'frd')
                    createResponsePlot(PM,ClosedLoop(1),ctrlguis.csdesignerapp.plot.internal.PlotEnum.Step);
                end

                PE = getPlotEditors(TM);
                AP = getPlotList(PM);

                TotalPlots = numel(PE)+numel(AP);
                if ctrlguis.csdesignerapp.utils.internal.CustomSettings.getUseDocumentTiling
                    layoutPlotDocumentsWhenReady(this);
                end
            end
        end

        function layoutPlotDocuments(this)
            % Get all plots
            PE = getPlotEditors(this.ToolsManager);
            AP = getPlotList(this.PlotsManager);
            TotalPlots = numel(PE)+numel(AP);
            % Layout has 2 columns
            nRows = max([ceil(TotalPlots/2),1]);
            if TotalPlots > 1
                nColumns = 2;
            else
                nColumns = 1;
            end
            this.AppContainer.DocumentGridDimensions = [nColumns,nRows];
            % Find Bode Editor
            isBode = arrayfun(@(x)isa(x,'ctrlguis.csdesignerapp.plot.internal.BodeEditorOL'),PE);
            if TotalPlots > 1 && mod(TotalPlots,2) % odd number of plots
                if any(isBode)
                    % Use 2 tiles for Bode Editor
                    idx = 1:TotalPlots;
                    idx = [idx(1:2),idx(1),idx(3:end)];
                else
                    idx = 1:TotalPlots+1;
                end
            else
                idx = 1:TotalPlots;
            end
            if ~isempty(idx)
                this.AppContainer.DocumentTileCoverage = reshape(idx',nColumns,nRows)';
            end
            % Select Response Plot
            document = getDocument(this.AppContainer,...
                ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("ResponsePlotDocumentGroup"),...
                "document1");
            if ~isempty(document)
                document.Selected = true;
                document.Showing = true;
            end
        end

        function layoutPlotDocumentsWhenReady(this)
            % Wait for "doc.Opened = true" for all documents.
            % Note that this will set MATLAB in busy state, and will need a
            % "Ctrl-C" if the document fails to open.
            docs = this.AppContainer.getDocuments();
            for i = 1:numel(docs)
                if docs{i}.Visible && ~docs{i}.Opened
                    waitfor(docs{i}, 'Opened', true);
                end
            end
            % Set the layout and tiling.
            layoutPlotDocuments(this);
        end

        function Editor = getConstraintEditor(this)
            Editor = this.ConstraintEditor;
        end

        function Editor = getCompensatorEditor(this)
            Editor = this.CompensatorEditor;
        end

        function Tabs = qeGetTabs(this)
            Tabs.HomeTab = this.HomeTab;
            Tabs.GraphicalEditorTab = qeGetTabs(this.ToolsManager);
            Tabs.ResponsePlotTab = qeGetTabs(this.PlotsManager);
            Tabs.SelectResponseToEditDialog = qeGetResponseSelectionDialog(this.ToolsManager);
        end

        function widgets = qeGetDataBrowserWidgets(this)
            % Access data browser widget objects for ControlSystemDesigner
            %   widgets = qeGetDataBrowserWidgets(app);
            %
            % To obtain data browser panels from AppContainer we can use
            % the "getPanel" method and the data browser title.
            %   appContainer = getAppContainer(app);
            %   controllerBrowserPanel = getPanel(appContainer,getString(message('Control:designerapp:strControllersAndFixedBlocks')));
            %   designBrowserPanel = getPanel(appContainer,getString(message('Control:designerapp:strDesigns')));
            %   responseBrowserPanel = getPanel(appContainer,getString(message('Control:designerapp:strResponses')));
            %   previewPanel = getPanel(appContainer,getString(message('Controllib:gui:DatabrowserPreview')));
            widgets.ControllerBrowser = this.ControllerBrowser;
            widgets.DesignBrowser = this.DesignBrowser;
            widgets.ResponseBrowser = this.ResponseBrowser;
            widgets.PreviewPanel = this.PreviewPanel;
        end

        function qeSelectTab(this,tabType)
            % qeSelectTab(csdApp,tabType)
            %   "tabType" is string or char with possible values below
            %       'Home'|'RootLocusEditor'|'BodeEditor'|'NicholsEditor'
            %
            % qeSelectTab(app,"RootLocusEditor")
            arguments
                this
                tabType char {mustBeMember(tabType,{'Home','RootLocusEditor',...
                    'BodeEditor','NicholsEditor'})}
            end
            pause(2);
            drawnow;
            tabType = string(tabType);
            tabGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(tabType+"TabGroup");
            tabTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(tabType+"Tab");
            tabGroup = getTabGroup(this.AppContainer,tabGroupTag);
            tab = getChildByTag(tabGroup,tabTag);
            tabGroup.SelectedTab = tab;
        end

        function qeSelectDocument(this,group,responseName)
            % qeSelectDocument(this,group,responseName)
            %   "group" : 'ResponsePlot'|'BodeEditor'|'RootLocusEditor'|'NicholsEditor'
            %   "responseName" : Name of response
            %
            % qeSelectDocument(app,"BodeEditor","LoopTransfer_C");
            arguments
                this
                group char {mustBeMember(group,{'ResponsePlot','BodeEditor',...
                    'RootLocusEditor','NicholsEditor'})}
                responseName
            end
            pause(2);
            drawnow;
            group = string(group);
            documentGroupTag = ...
                ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(group + "DocumentGroup");
            allDocuments = getDocuments(this.AppContainer);
            groupIdx = cellfun(@(x) isequal(x.DocumentGroupTag,documentGroupTag),allDocuments);
            documentsInGroup = allDocuments(groupIdx);
            tagIdx = cellfun(@(x) contains(x.Tag,responseName),documentsInGroup);
            document = documentsInGroup{tagIdx};
            document.Selected = true;
        end

        function qeBringToFront(this)
            bringToFront(this.AppContainer);
        end

        function flag = isToolDirty(this)
            flag = this.IsDirty | isDataDirty(this.DesignerData) | ...
                isDirty(this.PlotsManager) | isDirty(this.ToolsManager) | ...
                isDirty(this.Preferences);
        end

        function setToolDirty(this,flag)
            if islogical(flag)
                this.IsDirty = flag;
                % If flag == false, set DesignerData dirty to false
                if ~flag
                    setDataDirty(this.DesignerData,flag);
                    if isvalid(this.PlotsManager)
                        setDirty(this.PlotsManager,flag);
                    end
                    if isvalid(this.ToolsManager)
                        setDirty(this.ToolsManager,flag);
                    end
                    if isvalid(this.Preferences)
                        setDirty(this.Preferences,flag);
                    end
                end
                controllib.ui.internal.dirtymgr.DirtyManager.getInstance(this.DesignerData.UniqueName).setDirty(flag);
            end
        end
        function hasVariable = hasVariableInWorkspace(this, varname, wksname)
            % Validate input arguments
            arguments
                this
                varname {mustBeText(varname)}  
                wksname {mustBeMember(wksname,{'Compensator','DesignRequirements'})}
            end
            switch wksname
                case 'Compensator'
                    allCompList = getTunableBlocks(this.DesignerData);
                    hasVariable = any(arrayfun(@(x) strcmp(x.Name,varname),allCompList));
                case 'DesignRequirements'
                    hasVariable = hasRequirementData(this.ToolsManager,varname);
            end
        end
        function data = getVariableFromWorkspace(this, varname, wksname)
            % Validate input arguments
            arguments
                this
                varname {mustBeText(varname)}
                wksname {mustBeMember(wksname,{'Compensator','DesignRequirements'})}
            end
            switch wksname
                case 'Compensator'
                    allCompList = getTunableBlocks(this.DesignerData);
                    idx = arrayfun(@(x) strcmp(x.Name,varname),allCompList);
                    if any(idx) && nnz(idx) == 1
                        compensator = allCompList(idx);
                        Ts = getTs(compensator);
                        designSpec = cell(size(compensator.PZGroup));
                        for ii = 1:length(designSpec)
                            PZGroup = compensator.PZGroup(ii);
                            designSpec{ii} = struct();
                            switch PZGroup.Type
                                case 'Real'
                                    if isempty(PZGroup.Pole)
                                        Location = PZGroup.Zero;
                                        if (~Ts && Location ~= 0) || ( Ts && Location ~= 1)
                                            designSpec{ii}.Type = 'Real Zero';
                                        else
                                            designSpec{ii}.Type = 'Differentiator';
                                        end
                                    else
                                        Location = PZGroup.Pole;
                                        if (~Ts && Location ~= 0) || ( Ts && Location ~= 1)
                                            designSpec{ii}.Type = 'Real Pole';
                                        else
                                            designSpec{ii}.Type = 'Integrator';
                                        end
                                    end
                                case 'Complex'
                                    if isempty(PZGroup.Pole)
                                        designSpec{ii}.Type = 'Complex Zero';
                                    else
                                        designSpec{ii}.Type = 'Complex Pole';
                                    end
                                case 'LeadLag'
                                    if (Ts == 0 && PZGroup.Pole < PZGroup.Zero) || ...
                                            (Ts ~= 0 && abs(PZGroup.Pole) < abs(PZGroup.Zero))
                                        designSpec{ii}.Type = 'Lead';
                                    else
                                        designSpec{ii}.Type = 'Lag';
                                    end
                                case 'Notch'
                                    designSpec{ii}.Type = 'Notch';
                            end
                            if ~isempty(PZGroup.Zero)
                                designSpec{ii}.Zeros = PZGroup.Zero;
                            end
                            if ~isempty(PZGroup.Pole)
                                designSpec{ii}.Poles = PZGroup.Pole;
                            end
                            switch PZGroup.Type
                                case 'LeadLag'
                                    designSpec{ii}.Phase = rad2deg(PZGroup.PhaseMax);
                                    designSpec{ii}.Frequency = PZGroup.WMax;
                                case 'Notch'
                                    designSpec{ii}.Frequency = PZGroup.Wn;
                                    designSpec{ii}.DampingZero = PZGroup.ZetaZero;
                                    designSpec{ii}.DampingPole = PZGroup.ZetaPole;
                                    designSpec{ii}.Depth = mag2db(PZGroup.Depth);
                                    designSpec{ii}.Width = PZGroup.Width;
                            end
                        end
                        data = struct('Gain',compensator.Gain);
                        data.DesignSpec = designSpec;
                    else
                        data = [];
                    end
                case 'DesignRequirements'
                    data = getRequirementData(this.ToolsManager,varname);
            end
        end
    end
end

%--------------------------- Local Functions ----------------------
function NewSession = LocalUpgradeToLatest(this,OldSession,varargin)
NewSession = ctrlguis.csdesignerapp.data.internal.SessionData;
[NewSession.DesignerData, RespIdxMapping, LoopIdxMapping, BlockIdxMapping] = upgradeToLatest(this.DesignerData, OldSession.Designs,varargin{:});
NewSession.PlotsManager = upgradeToLatest(this.PlotsManager, OldSession.ViewerSettings, RespIdxMapping, BlockIdxMapping);
NewSession.ToolsManager = upgradeToLatest(this.ToolsManager, OldSession.EditorSettings, LoopIdxMapping);
end

% BACKWARD COMPATIBILITY FOR VERSIONS 1 and 2
function SessionObj = LocalUpgradeToCETM(this,SavedSession)
% Upgrade from previous versions
nviews = length(SavedSession.ViewerContent);
if SavedSession.Version<2
    % Upgrade to version 2.0
    % Added Input Disturbance and Output Disturbance entries to Analysis menu
    SavedSession.ResponseMenuState = ...
        [SavedSession.ResponseMenuState(1);{'off'};SavedSession.ResponseMenuState(3:5)];
    % New ViewerContent format
    if nviews>0
        vismod = cell(nviews,1);
        for ct=1:nviews
            vismod{ct} = [SavedSession.ViewerContent(ct).OpenLoop ; SavedSession.ViewerContent(ct).ClosedLoop];
        end
        SavedSession.ViewerContent = struct('PlotType',{SavedSession.ViewerContent.PlotType}',...
            'VisibleModels',vismod,'SelectedMenu',[]);
    end
    % Convert Title/Xlabel/Ylabel of all editors into version 2
    SavedSession.RootLocusEditor = localConvertEditorFields(SavedSession.RootLocusEditor);
    SavedSession.OpenLoopBodeEditor = localConvertEditorFields(SavedSession.OpenLoopBodeEditor);
    SavedSession.NicholsEditor = localConvertEditorFields(SavedSession.NicholsEditor);
    SavedSession.PrefilterBodeEditor = localConvertEditorFields(SavedSession.PrefilterBodeEditor);
end

    function editorSettings = localConvertEditorFields(editorSettings)
        % Split Title(Xlabel,Ylabel) into Title(Xlabel,Ylabel) and
        % TitleStyle(XlabelStyle,YlabelStyle)
        editorSettings.TitleStyle = ...
            localCopyStructFields(editorSettings.Title,'Color','FontAngle','FontSize','FontWeight');
        editorSettings.TitleStyle.Interpreter = 'tex';
        editorSettings.Title = editorSettings.Title.String;
        editorSettings.XlabelStyle = ...
            localCopyStructFields(editorSettings.Xlabel,'Color','FontAngle','FontSize','FontWeight');
        editorSettings.XlabelStyle.Interpreter = 'tex';
        editorSettings.Xlabel = editorSettings.Xlabel.String;
        editorSettings.YlabelStyle = ...
            localCopyStructFields(editorSettings.Ylabel,'Color','FontAngle','FontSize','FontWeight');
        editorSettings.YlabelStyle.Interpreter = 'tex';
        editorSettings.Ylabel = editorSettings.Ylabel.String;
    end

    function newstruct = localCopyStructFields(oldstruct,varargin)
        % Nested function to copy structure fields (used for
        % RootLocusEditor, OpenLoopBodeEditor, NicholsEditor,
        % PrefilterBodeEditor)
        nfields = length(varargin);
        for k = 1:nfields
            newstruct.(varargin{k}) = oldstruct.(varargin{k});
        end
    end

if SavedSession.Version <= 2
    %Convert from RespList strings to indices
    RespList = {...
        '$T_r2y', '$T_r2u', '$S_input', '$S_output', '$S_noise', ...
        '$L', '$C', '$F', '$G', '$H'};

    if ~isempty(SavedSession.ViewerContent)
        for ct = length(SavedSession.ViewerContent):-1:1
            [vis,idx] = intersect(SavedSession.ViewerContent(ct).VisibleModels,RespList);
            NewViewerContent(ct) = struct('PlotType',SavedSession.ViewerContent(ct).PlotType, ...
                'VisibleModels',idx,'SelectedMenu',SavedSession.ViewerContent(ct).SelectedMenu);
        end
        SavedSession.ViewerContent = NewViewerContent;
    end
end

% Upgrade to @session object
SessionObj = sisogui.session;
SessionObj.Preferences = SavedSession.Preferences;
if strcmpi(SessionObj.Preferences.FrequencyUnits, 'rad/sec')
    SessionObj.Preferences.FrequencyUnits = 'rad/s';
end
SessionObj.History = SavedSession.History;
% Editor settings
% RE: Actual conversion handled by editor's load method
s1 = SavedSession.RootLocusEditor;
s1.Class = 'sisogui.rleditor';
s1.EditedLoop = 1; s1.EditedBlock=1; s1.GainTargetBlock = 1;

s2 = SavedSession.OpenLoopBodeEditor;
s2.Class = 'sisogui.bodeditorOL';
s2.EditedLoop = 1; s2.EditedBlock=1; s2.GainTargetBlock = 1;

s3 = SavedSession.NicholsEditor;
s3.Class = 'sisogui.nicholseditor';
s3.EditedLoop = 1; s3.EditedBlock=1; s3.GainTargetBlock =1;

s4 = SavedSession.PrefilterBodeEditor;
if isequal(SavedSession.LoopData.Configuration,4)
    s4.Class = 'sisogui.bodeditorOL';
    s4.MarginVisible = 'on';
else
    s4.Class = 'sisogui.bodeditorF';
end
s4.EditedLoop = 2; s4.EditedBlock=2; s4.GainTargetBlock = 2;

SessionObj.EditorSettings = {s1;s2;s3;s4};
% Design data
LoopData = SavedSession.LoopData;
Config = LoopData.Configuration;
D = LocalUpgradeData(LoopData,Config);
for ct=1:length(LoopData.SavedDesigns)
    D(ct+1,1) = LocalUpgradeData(LoopData.SavedDesigns(ct),Config);
end
SessionObj.Designs = D;
% Viewer data
SessionObj.ViewerSettings.ViewerContents = SavedSession.ViewerContent;
SessionObj.ViewerSettings.ViewerData(1:numel(SavedSession.ViewerContent)) = ...
    struct('PlotCell',struct('Constraints',[]));
end

function Design = LocalUpgradeData(LoopData,Config)
% Upgrade design
Design = sisoinit(LoopData.Configuration);
if isfield(LoopData,'SystemName')
    Design.Name = LoopData.SystemName;
else
    Design.Name = LoopData.Name;
end
if Config<4
    Design.FeedbackSign = LoopData.FeedbackSign;
    Design.C.Name = LoopData.Compensator.Name;
    Design.C.Value = LoopData.Compensator.Model;
    Design.F.Name = LoopData.Filter.Name;
    Design.F.Value = LoopData.Filter.Model;
else
    Design.FeedbackSign = [LoopData.FeedbackSign,1];
    Design.C1.Name = LoopData.Compensator.Name;
    Design.C1.Value = LoopData.Compensator.Model;
    Design.C2.Name = LoopData.Filter.Name;
    Design.C2.Value = LoopData.Filter.Model;
end
Design.G.Name = LoopData.Plant.Name;
Design.G.Value = LoopData.Plant.Model;
Design.H.Name = LoopData.Sensor.Name;
Design.H.Value = LoopData.Sensor.Model;
end
