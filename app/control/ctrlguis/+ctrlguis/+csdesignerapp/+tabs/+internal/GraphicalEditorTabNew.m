classdef GraphicalEditorTabNew < controllib.app.plottab.internal.FigureTool
    %GRAPHICALEDITORTAB Tab with controls for graphical editors
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        ToolsManager
        Widgets
        GraphicalEditor
        ParentToolGroup
        ZoomAndPanSection
        ModifyPZSection
        LegendWidget
        UIListeners
        EditModeListener
        FigureDeletedListener
    end
    
    methods
        function this = GraphicalEditorTabNew(GraphicalEditor, ToolsManager, Title)
            %Call parent constructor
            Fig = getHGParent(GraphicalEditor);
            tabGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(...
                GraphicalEditor.Type + "EditorTabGroup");
            tabGroup = getTabGroup(getAppContainer(ToolsManager),tabGroupTag);
            this = this@controllib.app.plottab.internal.FigureTool(Fig,tabGroup);
            this.ToolsManager = ToolsManager;
            % Assign inputs
            this.GraphicalEditor = GraphicalEditor;
            % create default tab
            this.addPlotTab('GraphicalEditorTab',Title);
            % append the tab to toolgroup
            this.addToHost(getAppContainer(ToolsManager));
            this.TabGroup.add(this.PlotTab);
            % add listener to figure deleted event
            weakThis = matlab.lang.WeakReference(this);
            this.FigureDeletedListener = addlistener(this.Figure, 'ObjectBeingDestroyed',...
                @(es,ed)toggleButtonStatus(weakThis.Handle,this.Widgets.ToggleButtons(1)));
            % add edit mode changed listener
            weakThis = matlab.lang.WeakReference(this);
            this.EditModeListener = addlistener(GraphicalEditor.ModeManager, 'Mode', 'PostSet', @(es,ed)cbEditModeChanged(weakThis.Handle));
        end
        
        function Widgets = getWidgets(this)
            Widgets = this.Widgets;
        end
        
        function addPlotTab(this, name, title)
            this.PlotTab = matlab.ui.internal.toolstrip.Tab(title);
            this.PlotTab.Tag = name;
        end
        
        function updateGraphicalEditor(this)
            appContainer = getAppContainer(this.ToolsManager);
            allGraphicalEditors = getPlotEditors(this.ToolsManager);
            selectedDocument = appContainer.LastSelectedDocument;
            idx = arrayfun(@(x) string(x.ContextualTag),allGraphicalEditors) == selectedDocument.tag;
            this.GraphicalEditor = allGraphicalEditors(idx);
            this.Figure = getHGParent(this.GraphicalEditor);
            delete(this.FigureDeletedListener);
            delete(this.EditModeListener);
            % add listener to figure deleted event
            weakThis = matlab.lang.WeakReference(this);
            this.FigureDeletedListener = addlistener(this.Figure, 'ObjectBeingDestroyed', ...
                @(es,ed) toggleButtonStatus(weakThis.Handle,this.Widgets.ToggleButtons(1)));
            % add edit mode changed listener
            weakThis = matlab.lang.WeakReference(this);
            this.EditModeListener = addlistener(this.GraphicalEditor.ModeManager, 'Mode', ...
                'PostSet', @(es,ed)cbEditModeChanged(weakThis.Handle));
        end
        
        %%%%% CALLBACKS %%%%%%%%
        
        function LocalEnterMode(this, es, EditMode, EditModeData)
            disableUIListeners(this);
            this.EditModeListener.Enabled = false;
            weakThis = matlab.lang.WeakReference(this);
            if es.Value
                % Set current editor to idle, and update graphical editor
                % based on currently selected document
                if isvalid(this.GraphicalEditor)
                    setEditModeAndData(this.GraphicalEditor,'idle',[]);
                end
                updateGraphicalEditor(this);
                % Set edit mode
                setEditModeAndData(this.GraphicalEditor,EditMode,EditModeData);
                if ~strcmp(EditModeData,'out')
                    toggleButtonStatus(weakThis.Handle, es);
                else
                    % This is for having zoomout as a push button now which
                    % resets axes limits
                    es.Value = false;
                end  
            else
                if all([this.Widgets.ToggleButtons.Value]) == false
                    this.Widgets.ToggleButtons(1).Value = true;
                end
                if isvalid(this.GraphicalEditor)
                    setEditModeAndData(this.GraphicalEditor,'idle',[]);
                end
            end
            this.EditModeListener.Enabled = true;
            enableUIListeners(this);
        end
        
        function cbEditModeChanged(this)
            disableUIListeners(this);
            if strcmpi(this.GraphicalEditor.EditMode, 'idle')
                this.Widgets.ToggleButtons(1).Value = true;
                toggleButtonStatus(this, this.Widgets.ToggleButtons(1));
            elseif strcmpi(this.GraphicalEditor.EditMode, 'addpz')
                if strcmpi(this.GraphicalEditor.EditModeData.Root, 'Pole') && strcmpi(this.GraphicalEditor.EditModeData.Group, 'Real')
                    this.Widgets.ToggleButtons(2).Value = true;
                    toggleButtonStatus(this, this.Widgets.ToggleButtons(2));
                elseif strcmpi(this.GraphicalEditor.EditModeData.Root, 'Zero') && strcmpi(this.GraphicalEditor.EditModeData.Group, 'Real')
                    this.Widgets.ToggleButtons(3).Value = true;
                    toggleButtonStatus(this, this.Widgets.ToggleButtons(3));
                elseif strcmpi(this.GraphicalEditor.EditModeData.Root, 'Pole') && strcmpi(this.GraphicalEditor.EditModeData.Group, 'Complex')
                    this.Widgets.ToggleButtons(4).Value = true;
                    toggleButtonStatus(this, this.Widgets.ToggleButtons(4));
                elseif strcmpi(this.GraphicalEditor.EditModeData.Root, 'Zero') && strcmpi(this.GraphicalEditor.EditModeData.Group, 'Complex')
                    this.Widgets.ToggleButtons(5).Value = true;
                    toggleButtonStatus(this, this.Widgets.ToggleButtons(5));
                end
            elseif strcmpi(this.GraphicalEditor.EditMode, 'deletepz')
                this.Widgets.ToggleButtons(6).Value = true;
                toggleButtonStatus(this, this.Widgets.ToggleButtons(6));
            elseif strcmpi(this.GraphicalEditor.EditMode, 'zoom')
                if strcmpi(this.GraphicalEditor.EditModeData,'in')
                    this.Widgets.ToggleButtons(7).Value = true;
                    toggleButtonStatus(this, this.Widgets.ToggleButtons(7));
                elseif strcmpi(this.GraphicalEditor.EditModeData,  'out')
                    this.Widgets.ToggleButtons(8).Value = false;
                    toggleButtonStatus(this, this.Widgets.ToggleButtons(8));
                end
            elseif strcmpi(this.GraphicalEditor.EditMode, 'pan')
                this.Widgets.ToggleButtons(9).Value = true;
                toggleButtonStatus(this, this.Widgets.ToggleButtons(9));
            end
            enableUIListeners(this);
        end
        
        %%%%% UTILITIES %%%%%%%%
        
        function toggleButtonStatus(this, ExcludedButton)
            for ct = 1:numel(this.Widgets.ToggleButtons)
                if this.Widgets.ToggleButtons(ct)~=ExcludedButton
                    this.Widgets.ToggleButtons(ct).Value = false;
                end
            end
        end
        
        function enableUIListeners(this)
            for ct = 1:numel(this.UIListeners)
                this.UIListeners(ct).Enabled = true;
            end
        end
        
        function disableUIListeners(this)
            if isvalid(this.UIListeners)
                for ct = 1:numel(this.UIListeners)
                    this.UIListeners(ct).Enabled = false;
                end
            end
        end
    end
    
    methods (Access = protected)
        
        function configureTabGroup(this)
            % Modify default plot tab
            import matlab.ui.internal.toolstrip.*
            % ModifyPZSection
            this.ModifyPZSection = Section(getString(message('Control:designerapp:modifyPolesAndZeros')));
            this.ModifyPZSection.Tag = 'ModifyPZ';
            % toggle buttons
            
            % Arrow icon (default mode)
            ArrowIcon = Icon('select');
            this.Widgets.ToggleButtons(1) = ToggleButton(ArrowIcon);
            this.Widgets.ToggleButtons(1).Tag = 'btnArrow';
            this.Widgets.ToggleButtons(1).Description = ...
                getString(message('Control:compDesignTask:ttDefaultMode'));
            column1 = Column();
            addEmptyControl(column1);
            add(column1, this.Widgets.ToggleButtons(1));
            addEmptyControl(column1);
            add(this.ModifyPZSection, column1);
            
            weakThis = matlab.lang.WeakReference(this);
            % Default mode
            this.Widgets.ToggleButtons(1).Value = true;
            this.UIListeners = [this.UIListeners; ...
                addlistener(this.Widgets.ToggleButtons(1), 'ValueChanged', ...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'idle', []))];
            
            % Create toggle buttons for Pole/Zero editing
            RPoleIcon = Icon('realPole');
            this.Widgets.ToggleButtons(2) = ToggleButton(RPoleIcon);
            this.Widgets.ToggleButtons(2).Tag = 'btnRealPole';
            this.Widgets.ToggleButtons(2).Description = ...
                getString(message('Control:compDesignTask:ttAddRealPole'));
            column2 = Column();
            addEmptyControl(column2);
            add(column2, this.Widgets.ToggleButtons(2));
            addEmptyControl(column2);
            add(this.ModifyPZSection, column2);
            this.UIListeners = [this.UIListeners; ...
                addlistener(this.Widgets.ToggleButtons(2), 'ValueChanged', ...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'addpz', struct('Root','Pole','Group','Real')))];
            
            RZeroIcon = Icon('realZero');
            this.Widgets.ToggleButtons(3) = ToggleButton(RZeroIcon);
            this.Widgets.ToggleButtons(3).Tag = 'btnRealZero';
            this.Widgets.ToggleButtons(3).Description = ...
                getString(message('Control:compDesignTask:ttAddRealZero'));
            column3 = Column();
            addEmptyControl(column3);
            add(column3, this.Widgets.ToggleButtons(3));
            addEmptyControl(column3);
            add(this.ModifyPZSection, column3);
            this.UIListeners = [this.UIListeners; ...
                addlistener(this.Widgets.ToggleButtons(3), 'ValueChanged', ...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'addpz', struct('Root','Zero','Group','Real')))];
            
            CPoleIcon = Icon('complexPole');
            this.Widgets.ToggleButtons(4) = ToggleButton(CPoleIcon);
            this.Widgets.ToggleButtons(4).Tag = 'btnComplexPole';
            this.Widgets.ToggleButtons(4).Description = ...
                getString(message('Control:compDesignTask:ttAddComplexPole'));
            column4 = Column();
            addEmptyControl(column4);
            add(column4, this.Widgets.ToggleButtons(4));
            addEmptyControl(column4);
            add(this.ModifyPZSection, column4);
            this.UIListeners = [this.UIListeners; ...
                addlistener(this.Widgets.ToggleButtons(4), 'ValueChanged', ...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'addpz', struct('Root','Pole','Group','Complex')))];
            
            CZeroIcon = Icon('complexZero');
            this.Widgets.ToggleButtons(5) = ToggleButton(CZeroIcon);
            this.Widgets.ToggleButtons(5).Tag = 'btnComplexZero';
            this.Widgets.ToggleButtons(5).Description = ...
                getString(message('Control:compDesignTask:ttAddComplexZero'));
            column5 = Column();
            addEmptyControl(column5);
            add(column5, this.Widgets.ToggleButtons(5));
            addEmptyControl(column5);
            add(this.ModifyPZSection, column5);
            this.UIListeners = [this.UIListeners; ...
                addlistener(this.Widgets.ToggleButtons(5), 'ValueChanged',...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'addpz', struct('Root','Zero','Group','Complex')))];
            
            EraseIcon = Icon('eraser');
            this.Widgets.ToggleButtons(6) = ToggleButton(EraseIcon);
            this.Widgets.ToggleButtons(6).Tag = 'btnDeletePZ';
            this.Widgets.ToggleButtons(6).Description = ...
                getString(message('Control:compDesignTask:ttDeletePoleZero'));
            column6 = Column();
            addEmptyControl(column6);
            add(column6, this.Widgets.ToggleButtons(6));
            addEmptyControl(column6);
            add(this.ModifyPZSection, column6);
            this.UIListeners = [this.UIListeners; ...
                addlistener(this.Widgets.ToggleButtons(6), 'ValueChanged',...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'deletepz', []))];
            
            add(this.PlotTab,this.ModifyPZSection);
            
            % Create the Zoom And Pan Tool Section
            this.Widgets.ZoomSection = Section(getString(message('Control:designerapp:strZoomAndPan')));
            this.Widgets.ZoomSection.Tag = 'zoom';
            
            zoominicon = Icon('zoomIn');
            ZoomInButton = ToggleButton(zoominicon);
            ZoomInButton.Tag = 'btnZoomIn';
            ZoomInButton.Description = ...
                ctrlMsgUtils.message('Controllib:gui:PlotTabZoomZoomIn');
            column7 = Column();
            addEmptyControl(column7);
            add(column7, ZoomInButton);
            addEmptyControl(column7);
            add(this.Widgets.ZoomSection, column7);
            
            zoomouticon = Icon('zoomOut');
            ZoomOutButton = ToggleButton(zoomouticon);
            ZoomOutButton.Tag = 'btnZoomOut';
            ZoomOutButton.Description = ...
                ctrlMsgUtils.message('Controllib:gui:PlotTabZoomZoomOut');
            column8 = Column();
            addEmptyControl(column8);
            add(column8, ZoomOutButton);
            addEmptyControl(column8);
            add(this.Widgets.ZoomSection, column8);
            
            panicon = Icon('pan');
            PanButton = ToggleButton(panicon);
            PanButton.Tag = 'btnPan';
            PanButton.Description = ...
                ctrlMsgUtils.message('Controllib:gui:PlotTabZoomPan');
            column9 = Column();
            addEmptyControl(column9);
            add(column9, PanButton);
            addEmptyControl(column9);
            add(this.Widgets.ZoomSection, column9);
            
            this.Widgets.ToggleButtons(7) = ZoomInButton;
            this.Widgets.ToggleButtons(8) = ZoomOutButton;
            this.Widgets.ToggleButtons(9) = PanButton;
            
            add(this.PlotTab,this.Widgets.ZoomSection);
            
            this.UIListeners = [this.UIListeners; ...
                addlistener(ZoomInButton, 'ValueChanged',...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'zoom', 'in-xy'))];
            this.UIListeners = [this.UIListeners; ...
                addlistener(ZoomOutButton,'ValueChanged',...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'zoom', 'out'))];
            this.UIListeners = [this.UIListeners; ...
                addlistener(PanButton,'ValueChanged',...
                @(es,ed)LocalEnterMode(weakThis.Handle, es, 'pan', []))];
        end
    end
end