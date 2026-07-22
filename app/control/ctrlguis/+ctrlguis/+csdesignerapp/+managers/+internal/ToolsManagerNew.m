classdef ToolsManagerNew < handle
    % Tools manager class to open different tools in the appropriate
    % locations (tabs, dialogs (signleton and otherwise), plots)

    % Copyright 2014-2020 The MathWorks, Inc.

    properties (Access = private)
        Tool
        AppContainer
        DesignerData        % Data associated with each tool
        SingletonDialogs    % List of already created dialogs
        SingletonFigures    % List of already created singleton figures
        Figures             % List of already created figures (non-singleton) and their tabs
        ToolsList           % List of all tools with ID
        Preferences
        EventManager
        PlotsManager
        ResponseSelectionDlg
        PZEditor
        ConstraintEditor
        ToolDirtyFlag = true
    end

    methods (Access = public)
        % Public API
        function this = ToolsManagerNew(Tool,EventManager,PlotsManager,DesignerData,Preferences,varargin)
            this.Tool = Tool;
            this.AppContainer = getAppContainer(Tool);
            this.EventManager = EventManager;
            this.DesignerData = DesignerData;
            this.PlotsManager = PlotsManager;
            this.Preferences =  Preferences;
            if nargin==7
                this.PZEditor = varargin{1};
                this.ConstraintEditor = varargin{2};
            end
        end

        function delete(this)
            removeDialogs(this);
            if ~isempty(this.Figures)
                delete([this.Figures.Fig])
            end
        end

        function AppContainer = getAppContainer(this)
            AppContainer = this.AppContainer;
        end

        function ToolsList = getToolsList(this)
            % Returns a vector of structs containing details about the
            % tools. Each struct corresponds to a tool and has the
            % following fields:

            % ID
            % Name
            % Description
            % Icon
            % Category
            % Singleton

            if isempty(this.ToolsList)
                % Create list of tools if tools list is empty
                createToolsList(this);
            end

            % Get all tools
            ToolsList = this.ToolsList;

        end

        function openTool(this, ToolID, Anchor)
            % Used to open the tool that was requested based on an ID
            % match. According to the ID, the tool is either opened as a
            % tab or a dialog. All opened dialogs are stored in the
            % SingletonDialogs property
            tool = getToolFromList(this, ToolID);

            if nargin < 3
                Anchor = [];
            end

            if isempty(tool) || ~isscalar(tool)
                error(message('Controllib:general:UnexpectedError', 'No/ more than one Tool Exists'));
            end

            switch tool.ToolType
                case 'Dialog'
                    % If singleton, check if dialog already exists
                    if tool.Singleton
                        manageSingletonDialogs(this, ToolID, Anchor);
                    else
                        createDialog(this, ToolID, Anchor);
                    end
                case 'Figure'
                    % If singleton, check if figure already exists
                    if tool.Singleton
                        manageSingletonFigures(this, ToolID, Anchor);
                    else
                        createFigure(this, ToolID);
                    end
            end

        end

        function EM = getEventManager(this)
            EM = this.EventManager;
        end

        function addFigure(this, editor, tab)
            if nargin < 3
                tab = [];
            end
            this.Figures(end+1).Editor = editor;
            this.Figures(end).Tab = tab;
            this.Figures(end).Fig = editor.getHGParent;
            this.Figures(end).Listener = addlistener(this.Figures(end).Editor.getHGParent,'ObjectBeingDestroyed',@(es,ed)cleanupFigureList(this,es));
            this.notify('GraphicalEditorListChanged');
            setDirty(this,true);
        end

        function cleanupFigureList(this,Editor)
            Editors = getPlotEditors(this);
            figs = [];
            for ct=1:numel(Editors)
                figs = [figs; Editors(ct).getHGParent];
            end
            idx = (Editor==figs);
            this.Figures(idx) = [];
            this.notify('GraphicalEditorListChanged');
            setDirty(this,true);
        end

        function S = saveSession(this)
            Responses = getResponses(this.DesignerData);
            Compensators = this.DesignerData.getArchitecture.getTunedBlocks;
            GE = [];
            for ct = 1:numel(this.Figures)
                GE(ct,1).PlotData = saveSession(this.Figures(ct).Editor,Responses,Compensators);
            end
            S.GraphicalEditors = GE;
            if ~isempty(this.SingletonDialogs)
                [b,idx] = ismember('SRO',this.SingletonDialogs(:,1));
                if b
                    S.OptimizationSession = save(this.SingletonDialogs{idx,2});
                end
            end
        end

        function S = upgradeToLatest(this,OldEditor,LoopIdxMapping)
            GE = [];
            for ct = 1:numel(OldEditor)
                if strcmpi(OldEditor{ct}.Visible,'on')
                    GETemp.PlotData = OldEditor{ct};
                    OldIdx = OldEditor{ct}.EditedLoop;
                    NewIdx = LoopIdxMapping((LoopIdxMapping(:,1) == OldIdx),2);
                    GETemp.PlotData.Response = NewIdx;
                    switch OldEditor{ct}.Class
                        case 'sisogui.rleditor'
                            GETemp.PlotData.ToolID = 'RootLocus';
                        case {'sisogui.bodeditorOL','sisogui.bodeditorF'}
                            GETemp.PlotData.ToolID = 'Bode';
                            GETemp.PlotData.MarginVisible = 'on';
                        case 'sisogui.nicholseditor'
                            GETemp.PlotData.ToolID = 'Nichols';
                            GETemp.PlotData.MarginVisible = 'on';
                    end
                    GETemp.PlotData = rmfield(GETemp.PlotData, 'Class');
                    GETemp.PlotData = rmfield(GETemp.PlotData, 'EditedLoop');
                    GE = [GE; GETemp];
                end
            end
            S.GraphicalEditors = GE;
        end

        function loadSession(this,S,Anchor)
            DD = this.DesignerData;
            TB = getTunedBlocks(DD.getArchitecture);
            if isempty(DD.getArchitecture.SaveData)
                MappingIdx = 1:numel(TB);
            else
                MappingIdx = DD.getArchitecture.SaveData;
            end
            if ~isempty(S)
                RespList = getResponses(DD);
                for ct = 1:length(S.GraphicalEditors)
                    if ~isempty(S.GraphicalEditors(ct).PlotData.Response)
                        createGraphicalEditor(this,S.GraphicalEditors(ct).PlotData.ToolID,RespList(S.GraphicalEditors(ct).PlotData.Response));
                        S.GraphicalEditors(ct).PlotData.EditedBlock = TB(MappingIdx(S.GraphicalEditors(ct).PlotData.EditedBlock));
                        S.GraphicalEditors(ct).PlotData.GainTargetBlock = TB(MappingIdx(S.GraphicalEditors(ct).PlotData.GainTargetBlock));
                        loadSession(this.Figures(end).Editor,S.GraphicalEditors(ct).PlotData);
                    end
                end
                if isfield(S,'OptimizationSession') && ~isempty(S.OptimizationSession)
                    if (license('test','Simulink_Design_Optim') && ~isempty(ver('sldo')))
                        dlg = createDialog(this, 'SRO');
                        this.SingletonDialogs{end+1, 1} = 'SRO';
                        this.SingletonDialogs{end, 2} = dlg;
                        % MappingIdx is the mapping of current compensator list to the
                        % SaveData compensator list.
                        %    SaveDataTunedBlocksList = CurrentTunedBlocksList(MappingIdx)
                        % The sorted idx gives the reverse mapping.
                        %    CurrentTunedBlocksList = SaveDataTunedBlocksList(mapIdx_SaveDataToCurrent)
                        [~,mapIdx_SaveDataToCurrent] = sort(MappingIdx);
                        dlg.SaveData = reorderParameters(this,S.OptimizationSession,mapIdx_SaveDataToCurrent);
                        % showing dialog to force load during construction.
                        % Otherwise we could get into a bad state due to
                        % deletion of design requirement/ tuned blocks after
                        % initial load.

                        show(dlg,[],true);
                    else
                        uialert(this.AppContainer,...
                            getString(message('Control:compDesignTask:warnSDOTuningProductRequired')),...
                            getString(message('Control:designerapp:strToolTitleShort')),...
                            'Icon','warning');
                    end

                end
            end
        end

        function S = reorderParameters(this,S,mapIdx)
            nTB = length(mapIdx);
            % Changing the PZData and GainData order (if field exists)
            if isfield(S.Parameters,'PZData')
                % Convert flat structure into cell array based on nPZ of
                % each compensator
                nPZ = S.Parameters.idxData.nPZ;
                PZData = S.Parameters.PZData;
                nPZs = [0; cumsum(nPZ(:))];
                tmpPZData = cell(1,nTB);
                for k = 1:nTB
                    tmpPZData{k} = PZData(nPZs(k)+1:nPZs(k+1));
                end
                % Rearrange the cell array based on mapIdx
                tmpPZData = tmpPZData(mapIdx);
                % Convert rearranged cellarray back to flat structure
                S.Parameters.PZData = [tmpPZData{:}];
            end
            if isfield(S.Parameters,'GainData')
                nK = S.Parameters.idxData.nK;
                GainData = S.Parameters.GainData;
                nKs = [0; cumsum(nK(:))];
                tmpGainData = cell(1,nTB);
                for k = 1:nTB
                    tmpGainData{k} = GainData(nKs(k)+1:nKs(k+1));
                end
                tmpGainData = tmpGainData(mapIdx);
                S.Parameters.GainData = [tmpGainData{:}];
            end
            % Applying the mapping to reorder OptimizationSession Parameters
            S.Parameters.idxData.MultiCompFormat = S.Parameters.idxData.MultiCompFormat(mapIdx);
            S.Parameters.idxData.idxP = S.Parameters.idxData.idxP(mapIdx);
            S.Parameters.idxData.nP = S.Parameters.idxData.nP(mapIdx);
            S.Parameters.idxData.nPZ = S.Parameters.idxData.nPZ(mapIdx);
        end

        function removeDialogs(this)
            % Cleanup before load
            for ct=size(this.SingletonDialogs,1):-1:1
                % List of already created dialogs
                if isa(this.SingletonDialogs{ct,2},'srocsdgui_old.sropnl') || ...
                        isa(this.SingletonDialogs{ct,2},'srocsdgui.sropnl')
                    optimize(this.SingletonDialogs{ct,2},'stop');
                end
%                 cleanup(this.SingletonDialogs{ct,2});
%                 cleanupUI(this.SingletonDialogs{ct,2});
                delete(this.SingletonDialogs{ct,2});
                this.SingletonDialogs(ct,:) = [];
            end
            delete(this.ResponseSelectionDlg)
            this.ResponseSelectionDlg = [];
        end

        function removeDocument(this,graphicalEditor)
            document = getDocument(graphicalEditor);
            if ~isempty(document) && isvalid(document) && ~graphicalEditor.IsPlotDeleted
                closeDocument(this.AppContainer,document.DocumentGroupTag,document.Tag);
            end
        end
    end

    methods (Hidden = true)
        function SingletonDialogs = qeGetSingletonDialogs(this)
            SingletonDialogs = this.SingletonDialogs;
        end

        function SingletonFigures = qeGetSingletonFigures(this)
            SingletonFigures = this.SingletonFigures;
        end

        function Tabs = qeGetTabs(this)
            Tabs = {};
            for ct = 1:numel(this.Figures)
                Tabs{ct} = this.Figures(ct).Tab;
            end
        end

        function Dlg = qeGetResponseSelectionDialog(this)
            Dlg = this.ResponseSelectionDlg;
        end

        % Required by Response Optimization
        function PE = getPlotEditors(this)
            PE = [];
            if ~isempty(this.Figures)
                PE = [this.Figures.Editor];
                PE = PE(:);
            end
        end

        function createGraphicalEditor(this,ToolID,Response) 
            setWaiting(this.Tool,true,getString(message('Control:designerapp:statusMessagePlotting')));
            switch ToolID
                case {'RootLocus', 'rlocus'}
                    RL = ctrlguis.csdesignerapp.plot.internal.RootLocusEditor(Response,this.Preferences,this.EventManager,this.PZEditor,this.ConstraintEditor);
                    update(RL)
                    setVisible(RL)
                    add(this.AppContainer,getDocument(RL));
                    addlistener(RL,'GraphicalEditorDeleted',...
                                @(es,ed) removeDocument(this,RL));
                    % Create contextual tab associated with graphical editor
                    tabTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("RootLocusEditorTab");
                    tabGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("RootLocusEditorTabGroup");
                    tabGroup = getTabGroup(this.AppContainer,tabGroupTag);
                    if isempty(tabGroup.Children)
                        tab = ctrlguis.csdesignerapp.tabs.internal.GraphicalEditorTabNew(RL,this,getString(message('Control:designerapp:strRootLocusEditor')));
                        tab.PlotTab.Tag = tabTag;
                        addFigure(this,RL,tab);
                    else
                        addFigure(this,RL);
                    end
                    % Add document group and document to AppContainer
                    %                     add(this.AppContainer,getDocumentGroup(RL));


                case {'Bode','bode','CLBode'}
                    BE = ctrlguis.csdesignerapp.plot.internal.BodeEditorOL(Response,this.Preferences,this.EventManager,this.PZEditor,this.ConstraintEditor);
                    update(BE)
                    setVisible(BE)
                    add(this.AppContainer,getDocument(BE));
                    addlistener(BE,'GraphicalEditorDeleted',...
                                @(es,ed) removeDocument(this,BE));
                    % Create contextual tab associated with graphical editor
                    tabTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("BodeEditorTab");
                    tabGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("BodeEditorTabGroup");
                    tabGroup = getTabGroup(this.AppContainer,tabGroupTag);
                    if isempty(tabGroup.Children)
                        tab = ctrlguis.csdesignerapp.tabs.internal.GraphicalEditorTabNew(BE,this,getString(message('Control:designerapp:strBodeEditor')));
                        tab.PlotTab.Tag = tabTag;
                        addFigure(this,BE,tab);
                    else
                        addFigure(this,BE);
                    end
                    % Add document group and document
                    %                     add(this.AppContainer,getDocumentGroup(BE));


                case {'Nichols','nichols'}
                    NE = ctrlguis.csdesignerapp.plot.internal.NicholsEditor(Response,this.Preferences,this.EventManager,this.PZEditor,this.ConstraintEditor);
                    update(NE)
                    setVisible(NE)
                    add(this.AppContainer,getDocument(NE));
                    addlistener(NE,'GraphicalEditorDeleted',...
                        @(es,ed) removeDocument(this,NE));
                    % Create tab associated with graphical editor
                    tabTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("NicholsEditorTab");
                    tabGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag("NicholsEditorTabGroup");
                    tabGroup = getTabGroup(this.AppContainer,tabGroupTag);
                    if isempty(tabGroup.Children)
                        tab = ctrlguis.csdesignerapp.tabs.internal.GraphicalEditorTabNew(NE,this,getString(message('Control:designerapp:strNicholsEditor')));
                        tab.PlotTab.Tag = tabTag;
                        addFigure(this,NE,tab);
                    else
                        addFigure(this,NE);
                    end
                    %                     add(this.AppContainer,getDocumentGroup(NE));


            end
            setWaiting(this.Tool,false);
            % Update the constraint list in constraint editor
            this.ConstraintEditor.ContainerList = this.getPlotEditors;
        end

        function val = isDirty(this)
            val = this.ToolDirtyFlag;
        end

        function setDirty(this,val)
            if islogical(val)
                this.ToolDirtyFlag = val;
                if val
                    controllib.ui.internal.dirtymgr.DirtyManager.getInstance(...
                        this.DesignerData.UniqueName).setDirty(val);
                end
            end
        end

    end

    methods (Access = private)
        %% Tool List
        function createToolsList(this)
            import matlab.ui.internal.toolstrip.*
            % Create a vector of structs containing details about the
            % tools. Each struct corresponds to a tool and has the
            % following tools:

            % ID
            % Name
            % Description
            % Icon
            % ToolType
            % Singleton

            ToolsList(1) = struct(...
                'ID',           'PID', ...
                'Name',         getString(message('Control:designerapp:strPIDTuning')), ...
                'Description',  getString(message('Control:designerapp:strPIDTuningDescription')), ...
                'Icon',         Icon('tuningPid'), ...
                'ToolType',     'Dialog', ...
                'Category',     'Automated',...
                'Singleton',    true);

            if (license('test','Simulink_Design_Optim') && ~isempty(ver('sldo')))
                ToolsList = [ToolsList; struct(...
                    'ID',           'SRO', ...
                    'Name',         getString(message('Control:designerapp:strOptimizationBasedTuning')), ...
                    'Description',  getString(message('Control:designerapp:strOptimizationBasedTuningDescription')), ...
                    'Icon',         Icon('tuningMethods'), ...
                    'ToolType',     'Dialog', ...
                    'Category',     'Automated',...
                    'Singleton',    true)];
            end

            ToolsList = [ToolsList; struct(...
                'ID',           'LQG', ...
                'Name',         getString(message('Control:designerapp:strLQGTuning')), ...
                'Description',  getString(message('Control:designerapp:strLQGTuningDescription')), ...
                'Icon',         Icon('tuningGoalLqg'), ...
                'ToolType',     'Dialog', ...
                'Category',     'Automated',...
                'Singleton',    true)];

            ToolsList = [ToolsList; struct(...
                'ID',           'LoopShape', ...
                'Name',         getString(message('Control:designerapp:strLoopShapeTuning')), ...
                'Description',  getString(message('Control:designerapp:strLoopShapeTuningDescription')), ...
                'Icon',         Icon('tuningGoalLoopShape'), ...
                'ToolType',     'Dialog', ...
                'Category',     'Automated',...
                'Singleton',    true)];

            ToolsList = [ToolsList; struct(...
                'ID',           'IMC', ...
                'Name',         getString(message('Control:designerapp:strIMCTuning')), ...
                'Description',  getString(message('Control:designerapp:strIMCTuningDescription')), ...
                'Icon',         Icon('tuningImc'), ...
                'ToolType',     'Dialog', ...
                'Category',     'Automated',...
                'Singleton',    true)];

            ToolsList = [ToolsList; struct(...
                'ID',           'Bode', ...
                'Name',         getString(message('Control:designerapp:strBodeEditor')), ...
                'Description',  getString(message('Control:designerapp:strBodeEditorDescription')), ...
                'Icon',         Icon('bodeEditor'), ...
                'ToolType',     'Figure', ...
                'Category',     'Graphical',...
                'Singleton',    false)];

            ToolsList = [ToolsList; struct(...
                'ID',           'CLBode', ...
                'Name',         getString(message('Control:designerapp:strCLBodeEditor')), ...
                'Description',  getString(message('Control:designerapp:strCLBodeEditorDescription')), ...
                'Icon',         Icon('bodeEditor'), ...
                'ToolType',     'Figure', ...
                'Category',     'Graphical',...
                'Singleton',    false)];

            ToolsList = [ToolsList; struct(...
                'ID',           'RootLocus', ...
                'Name',         getString(message('Control:designerapp:strRootLocusEditor')), ...
                'Description',  getString(message('Control:designerapp:strRootLocusEditorDescription')), ...
                'Icon',         Icon('rootLocusEditor'), ...
                'ToolType',     'Figure', ...
                'Category',     'Graphical',...
                'Singleton',    false)];

            ToolsList = [ToolsList; struct(...
                'ID',           'Nichols', ...
                'Name',         getString(message('Control:designerapp:strNicholsEditor')), ...
                'Description',  getString(message('Control:designerapp:strNicholsEditorDescription')), ...
                'Icon',         Icon('nicholsEditor'), ...
                'ToolType',     'Figure', ...
                'Category',     'Graphical',...
                'Singleton',    false)];

            this.ToolsList = ToolsList; %#ok<*PROP>
        end

        function Tool = getToolFromList(this, ToolID)
            % Get a tool from the tools list
            getToolsList(this);
            [bool, idx] = ismember(ToolID, {this.ToolsList.ID});
            if bool
                Tool = this.ToolsList(idx);
            else
                Tool = [];
            end
        end

        %% Dialogs
        function manageSingletonDialogs(this, ToolID, Anchor)
            % Create/ show dialog TC and GC for the given tool id
            % TC. If a dialog already exists for the ToolID, open the
            % dialog. If not, create the dialog.

            % SingletonDialogs stores {gc  ID} for each dialog that is open
            bool = false;

            if ~isempty(this.SingletonDialogs)
                [bool, idx] = ismember(ToolID, this.SingletonDialogs(:,1));
            end

            openExistingDialog = true;
            if ~bool
                openExistingDialog = false;
            elseif ~isvalid(this.SingletonDialogs{idx,2}) || ~this.SingletonDialogs{idx,2}.IsWidgetValid
                openExistingDialog = false;
                this.SingletonDialogs(idx,:) = [];
            end

            if openExistingDialog
                % Is dialog already open?
                Dlg = this.SingletonDialogs{idx,2};
                show(Dlg);
            else
                % If not, create it
                dlg = createDialog(this, ToolID);
                this.SingletonDialogs{end+1, 1} = ToolID;
                this.SingletonDialogs{end, 2} = dlg;
                if strcmp(ToolID,'SRO')
                    show(dlg,this.AppContainer);
                    registerDialog(this.Tool,dlg);
                else
                    show(dlg);
                    registerDialog(this.Tool, dlg);
                end
            end
        end
        
        function dlg = createDialog(this, ToolID)
            % Create and return the TC and GC for the given ToolID's dialog

            switch ToolID
                case 'PID'
%                     dlg = ctrlguis.csdesignerapp.dialogs.internal.PIDClassicTuningDlg(this.DesignerData, this.EventManager);
                    dlg = ctrlguis.csdesignerapp.dialogs.internal.PIDClassicTuningDlg(...
                        this.DesignerData, this.EventManager, ToolID);
                case 'SRO'
                    dlg = srocsdgui.sropnl(...
                        this.DesignerData, this.EventManager, this.PlotsManager, this);
                case 'LoopShape'
%                     dlg = ctrlguis.csdesignerapp.dialogs.internal.LoopShapeTuningDlg(this.DesignerData, this.EventManager);
                    dlg = ctrlguis.csdesignerapp.dialogs.internal.LoopShapeTuningDlg(this.DesignerData, this.EventManager, ToolID);
                case 'IMC'
%                     dlg = ctrlguis.csdesignerapp.dialogs.internal.IMCTuningDlg(this.DesignerData, this.EventManager);
                    dlg = ctrlguis.csdesignerapp.dialogs.internal.IMCTuningDlg(this.DesignerData, this.EventManager, ToolID);
                case 'LQG'
%                     dlg = ctrlguis.csdesignerapp.dialogs.internal.LQGTuningDlg(this.DesignerData, this.EventManager);
                    dlg = ctrlguis.csdesignerapp.dialogs.internal.LQGTuningDlg(...
                        this.DesignerData, this.EventManager, ToolID);
            end
        end
        
        %% Figures
        function manageSingletonFigures(this, ToolID)
            % Create/ show Figure TC and GC for the given tool id
            % TC. If a Figure already exists for the ToolID, open the
            % Figure. If not, create the Figure.
            
            if ~isempty(this.SingletonFigures)
                [bool, idx] = ismember(ToolID, this.SingletonFigures(:,1));
            end
            
            if bool && isvalid(this.SingletonFigures{idx,2})
                % Is dialog already open?
                show(this.SingletonFigures{idx,2},[],true);
            else
                % If not, create it
                gc = createDialog(this, ToolID);
                this.SingletonFigures{end+1, 1} = ToolID;
                this.SingletonFigures{end, 2} = gc;
                show(this.SingletonFigures{end, 2},[],true);
            end
        end
        
        function createFigure(this, ToolID)
            % Create and return the TC and GC for the given ToolID's Figure
            switch ToolID
                case {'RootLocus', 'Bode', 'CLBode', 'Nichols'}
                    this.ResponseSelectionDlg = ctrlguis.csdesignerapp.dialogs.internal.SelectResponseToEdit(this.DesignerData, this, ToolID);
                    show(this.ResponseSelectionDlg,this.AppContainer);
                    pack(this.ResponseSelectionDlg);
                    registerDialog(this.Tool,this.ResponseSelectionDlg);
                    addlistener(this.ResponseSelectionDlg,'CloseEvent',...
                            @(es,ed) deleteDialog(this.Tool,es.Name));
                otherwise
                    ctrlguis.csdesignerapp.utils.internal.utDisplayMessage('warning', 'Yet to be implemented');
            end
        end
    end
        
    methods (Hidden)
        function flag = hasRequirementData(this,loopName)
            [~, idx] = ismember('SRO', this.SingletonDialogs(:,1));
            if idx ~= 0
                dlg = this.SingletonDialogs{idx,2};
                pnl = getRequirementsPanel(dlg);
                tbl = getTable(pnl);
                tblAccordians = tbl.TableData.AccordionData;
                flag = any(arrayfun(@(x) strcmp(x.Name,loopName),tblAccordians));
            else
                flag = false;
            end
        end
        function data = getRequirementData(this,loopName)
            [~, idx] = ismember('SRO', this.SingletonDialogs(:,1));
            if idx ~= 0
                dlg = this.SingletonDialogs{idx,2};
                pnl = getRequirementsPanel(dlg);
                tbl = getTable(pnl);
                tblAccordions = tbl.TableData.AccordionData;
                idx = arrayfun(@(x) strcmp(x.Name,loopName),tblAccordions);
                if any(idx) && nnz(idx) == 1
                    rowData = tblAccordions(idx).RowData;
                    data = cell(length(rowData),3);
                    for ii = 1:length(rowData)
                        row = rowData{ii};
                        data{ii,1} = row{1};
                        data{ii,2} = strtrim(row{2});
                        data{ii,3} = strtrim(row{3});
                    end
                else
                    data = [];
                end
            else
                data = [];
            end
        end
    end

    events
        GraphicalEditorListChanged
    end
end