classdef ControllerDataBrowser_ < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
    % Browser component for controllers
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties (Access = private)
        Tool
        MenuEdit
        MenuHighlight
        MenuDelete
        MenuUpdateBlock
        MenuUpdateAll
    end
    
    methods
        function this = ControllerDataBrowser_(compName, Tool)
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                compName, getString(message('Control:systunegui:DataBrowserTitleTunedBlocks')));
            this.Tool = Tool;
            buildUI(this);
            connectUI(this);
            updateUI(this);
        end
        
        function updateUI(this)
            Controllers = getTunableBlock(this.Tool.ControlDesignData);
            this.Table.Data = cell(length(Controllers),1);
            for ct = 1:length(Controllers)
                this.Table.Data{ct,1} = Controllers(ct).Name;
            end
            if this.Panel.Selected %Refresh Preview Panel
                SelectionCallback(this,this.Table.Selection);
            end
        end
        
        function val = getName(this, row)
            Controllers = getTunableBlock(this.Tool.ControlDesignData);
            val = Controllers(row).Name;
        end
        
        function val = getData(this, row)
            Controllers = getTunableBlock(this.Tool.ControlDesignData);
            if length(Controllers)>=row
                val = Controllers(row);
            else
                val = '';
            end
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % Error out if invalid name is specified
            this.GenerateValidVarName = false;
            % Add dynamic contextmenu
            this.Table.ContextMenu = uicontextmenu('parent',this.Figure);
            this.Table.ContextMenu.Tag = strcat('cmn',this.Name);
            this.Table.ColumnEditable = false;
            this.MenuEdit = uimenu(this.Table.ContextMenu,...
                'label',getString(message('Control:systunegui:DataBrowserOpenSelection')),...
                'callback',@(src,data) EditCallback(this));
            
            if this.Tool.ControlDesignData.isSimulink
                this.MenuHighlight = uimenu(this.Table.ContextMenu,...
                    'label',getString(message('Control:systunegui:DataBrowserHighlight')),...
                    'callback',@(src,data) HighlightCallback(this));
                this.MenuDelete = uimenu(this.Table.ContextMenu,...
                    'label',getString(message('Control:systunegui:DataBrowserDelete')),...
                    'callback',@(src,data) DeleteCallback(this));
                this.MenuUpdateBlock = uimenu(this.Table.ContextMenu,...
                    'label',getString(message('Control:systunegui:DataBrowserUpdateThisBlock')),...
                    'callback',@(src,data) UpdateBlockCallback(this));
                this.MenuUpdateAll = uimenu(this.Table.ContextMenu,...
                    'label',getString(message('Control:systunegui:DataBrowserUpdateAllBlocks')),...
                    'callback',@(src,data) UpdateAllCallback(this));
            end
        end
        
        function connectUI(this)
            L1 = addlistener(this.Tool.ControlDesignData,'ArchitectureChanged',...
                @(src,evt)clearSelection(this));
            L2 = addlistener(this.Tool.ControlDesignData,'TunableBlocksListChanged',...
                @(es,ed) updateUI(this));
            L3 = addlistener(this.Tool.ControlDesignData,'CompensatorValueChanged',...
                @(es,ed) updateUI(this));
            L4 = addlistener(this.Tool.ControlDesignData,'ArchitectureChanged',...
                @(es,ed) updateUI(this));
            
            registerDataListeners(this,[L1 L2 L3 L4]);
            
            L6 = addlistener(this.Table.ContextMenu,'ContextMenuOpening',...
                @(src, data) updateContextMenu(this, src, data));
            L7 = addlistener(this.Panel,'PropertyChanged',...
                @(src,data) SelectionCallback(this,this.Table.Selection));
            
            registerUIListeners(this,[L6 L7]);
        end
        
        function DoubleClickCallback(this, row)
            sData.Name = this.Name;
            sData.Row = row;
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            EditCallback(this)
        end
        
        function SelectionCallback(this, rows)
            % Refresh preview panel
            if this.Panel.Selected
                eventdata = matlab.ui.internal.databrowser.PreviewEventData(rows);
                this.notify('PreviewRequested',eventdata);
            end
        end
        
        function clearSelection(this)
            if ~isempty(this.Table.Selection)
                this.Table.Selection = [];
                % Clear current preview.
                if this.Panel.Selected
                    SelectionCallback(this,this.Table.Selection)
                end
            end
        end
        
        %% Getting the selected controller
        function SelectedController = getSelectedController(this)
            rowIdx = this.Table.Selection;
            if rowIdx > 0
                Controllers = getTunableBlock(this.Tool.ControlDesignData);
                SelectedController = Controllers(rowIdx);
            else
                SelectedController = [];
            end
        end
        
        %% Context menu callbacks
        function EditCallback(this)
            rowIdx = this.Table.Selection;
            Controllers = getTunableBlock(this.Tool.ControlDesignData);
            if systuneapp.util.openJavaApp
                EditTunableBlock(this.Tool.TunableBlockEditorsManager,Controllers(rowIdx));
            else
                EditTunableBlock(this.Tool.TunableBlockEditorsManager, ...
                    Controllers(rowIdx),this.Tool.AppContainer,'center');
            end
        end
        
        function HighlightCallback(this)
            rowIdx = this.Table.Selection;
            TunableBlock = getTunableBlock(this.Tool.ControlDesignData);
            hilite_system(TunableBlock(rowIdx).BlockPath,'find');
            pause(1);
            hilite_system(TunableBlock(rowIdx).BlockPath,'none');
        end
        
        function DeleteCallback(this)
            SelectedController = getSelectedController(this);
            removeTunableBlock(this.Tool.ControlDesignData,SelectedController);
        end
        
        function UpdateBlockCallback(this)
            SelectedController = getSelectedController(this);
            warningMessage = this.Tool.ControlDesignData.updateSimulinkBlock(SelectedController);
            if ~isempty(warningMessage)
                uialert(this.Tool.AppContainer,...
                    warningMessage,getString(message('Control:systunegui:toolName')),Icon="warning");
            end
        end
        
        function UpdateAllCallback(this)
            warningMessage = this.Tool.ControlDesignData.updateSimulinkBlock;
            if ~isempty(warningMessage)
                uialert(this.Tool.AppContainer,...
                    warningMessage,getString(message('Control:systunegui:toolName')),Icon="warning");
            end
        end
        
        function updateContextMenu(this, src, data) %#ok<INUSL>
            % Right-clicking also selects the row.
            interactionInformation = data.InteractionInformation;
            if data.ContextObject == this.Table ...
                && ~(interactionInformation.RowHeader || interactionInformation.ColumnHeader)
                row = interactionInformation.DisplayRow;
                col = interactionInformation.DisplayColumn;
                % React when a cell or the white space is clicked.
                if isempty([row col])
                    % Remove current row selections
                    this.Table.Selection = [];
                    makeMenuVisible(this,false)
                else
                    % Select the right-clicked row if it is not selected
                    if ~any(this.Table.Selection==row)
                        this.Table.Selection = row;
                    end
                    makeMenuVisible(this,true)
                end
            end
            % Update preview panel
            SelectionCallback(this, this.Table.Selection);
        end
        
        function makeMenuVisible(this,visible)
            this.MenuEdit.Visible = visible;
            if this.Tool.ControlDesignData.isSimulink
                this.MenuHighlight.Visible = visible;
                this.MenuDelete.Visible = visible;
                this.MenuUpdateBlock.Visible = visible;
                this.MenuUpdateAll.Visible = visible;
            end
        end
    end
end