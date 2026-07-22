classdef DesignDataBrowser_ < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
    % Browser component for designs
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties (Access = private)
        Tool
        DesignDataChangeListeners
        MenuOpen
        MenuDelete
        MenuRetrieve
        MenuCompare
    end
    
    methods
        function this = DesignDataBrowser_(compName, Tool)
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                compName, getString(message('Control:systunegui:DataBrowserTitleDesigns')));
            this.Tool = Tool;
            buildUI(this);
            connectUI(this);
            updateUI(this);
        end
        
        function updateUI(this)
            delete(this.DesignDataChangeListeners); %Clear listeners
            this.DesignDataChangeListeners=[];
            
            Designs = getDesign(this.Tool.ControlDesignData);
            this.Table.Data = cell(length(Designs),1);
            for ct = 1:length(Designs)
                L = addlistener(Designs(ct),'Name','PostSet',@(es,ed) updateUI(this));
                this.DesignDataChangeListeners = [this.DesignDataChangeListeners;L];
                this.Table.Data{ct,1} = getName(Designs(ct));
            end
            if this.Panel.Selected %Refresh Preview Panel
                SelectionCallback(this,this.Table.Selection);
            end
        end
        
        function val = getName(this, row)
            Designs = getDesign(this.Tool.ControlDesignData);
            val = Designs(row).getName();
        end
        
        function val = getData(this, row)
            Designs = getDesign(this.Tool.ControlDesignData);
            if length(Designs)>=row
                val = Designs(row);
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
            
            this.MenuOpen = uimenu(this.Table.ContextMenu,...
                'label',getString(message('Control:systunegui:DataBrowserOpenSelection')),...
                'callback',@(src,data) OpenCallback(this));
            this.MenuDelete = uimenu(this.Table.ContextMenu,...
                'label',getString(message('Control:systunegui:DataBrowserDelete')),...
                'callback',@(src,data) DeleteCallback(this));
            this.MenuRetrieve = uimenu(this.Table.ContextMenu,...
                'label',getString(message('Control:systunegui:DataBrowserRetrieve')),...
                'callback',@(src,data) RetrieveCallback(this));
            this.MenuCompare = uimenu(this.Table.ContextMenu,...
                'label',getString(message('Control:systunegui:DataBrowserCompare')),...
                'callback',@(src,data) CompareCallback(this));
        end
        
        function connectUI(this)
            L1 = addlistener(this.Tool.ControlDesignData,'ArchitectureChanged',...
                @(src,evt)clearSelection(this));
            L2 = addlistener(this.Tool.ControlDesignData,'Designs',...
                'PostSet',@(src,evt)updateUI(this));
            
            registerDataListeners(this,[L1 L2]);
            
            L3 = addlistener(this.Table.ContextMenu,'ContextMenuOpening',...
                @(src, data) updateContextMenu(this, src, data));
            L4 = addlistener(this.Panel,'PropertyChanged',...
                @(src,data) SelectionCallback(this,this.Table.Selection));
            
            registerUIListeners(this,[L3 L4]);
        end
        
        function DoubleClickCallback(this, row)
            sData.Name = this.Name;
            sData.Row = row;
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            OpenCallback(this)
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
        
        %% Get selected design
        function SelectedDesign = getSelectedDesign(this)
            rowIdx = this.Table.Selection;
            if rowIdx > 0
                Designs = getDesign(this.Tool.ControlDesignData);
                SelectedDesign = Designs(rowIdx);
            else
                SelectedDesign = [];
            end
        end
        
        %% Context menu callbacks
        function OpenCallback(this)
            SelectedDesign = getSelectedDesign(this);
            if systuneapp.util.openJavaApp
                openDisplayDialog(SelectedDesign);
            else
                openDisplayDialog(SelectedDesign,this.Tool.AppContainer,'center')
            end            
        end
        
        function DeleteCallback(this)
            SelectedDesign = getSelectedDesign(this);
            removeDesign(this.Tool.ControlDesignData,SelectedDesign);
            delete(SelectedDesign)
        end
        
        function RetrieveCallback(this)
            SelectedDesign = getSelectedDesign(this);
            retrieveDesign(this.Tool.ControlDesignData,SelectedDesign);
        end
        
        function CompareCallback(this)
            SelectedDesign = getSelectedDesign(this);
            if isDesignCompared(this.Tool.PlotManager,SelectedDesign)
                removeDesign(this.Tool.PlotManager,SelectedDesign);
            else
                showDesign(this.Tool.PlotManager,SelectedDesign);
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
                    if isDesignCompared(this.Tool.PlotManager,getSelectedDesign(this))
                        this.MenuCompare.Checked = true;
                    else
                        this.MenuCompare.Checked = false;
                    end
                end
            end
            % Update preview panel
            SelectionCallback(this, this.Table.Selection);
        end
        
        function makeMenuVisible(this,visible)
            this.MenuOpen.Visible = visible;
            this.MenuDelete.Visible = visible;
            this.MenuRetrieve.Visible = visible;
            this.MenuCompare.Visible = visible;
        end
    end
end