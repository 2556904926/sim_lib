classdef ResponseDataBrowser_ < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
    % Browser component for responses
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties (Access = private)
        Tool
        ResponseDataChangeListeners
        MenuOpen
        MenuDelete
        MenuPlot
    end
    
    methods
        function this = ResponseDataBrowser_(compName, Tool)
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                compName, getString(message('Control:systunegui:DataBrowserTitleResponses')));
            this.Tool = Tool;
            buildUI(this);
            connectUI(this);
            updateUI(this);
        end
        
        function updateUI(this)
            delete(this.ResponseDataChangeListeners); %Clear listeners
            this.ResponseDataChangeListeners=[];
            
            Responses = getResponse(this.Tool.ControlDesignData);
            this.Table.Data = cell(length(Responses),1);
            for ct = 1:length(Responses)
                L = addlistener(Responses(ct),'Response','PostSet',@(es,ed) updateUI(this));
                this.ResponseDataChangeListeners = [this.ResponseDataChangeListeners;L];
                this.Table.Data{ct,1} = getName(Responses(ct));
            end
            if this.Panel.Selected %Refresh Preview Panel
                SelectionCallback(this,this.Table.Selection);
            end
        end
        
        function val = getName(this, row)
            Responses = getResponse(this.Tool.ControlDesignData);
            val = Responses(row).getName();
        end
        
        function val = getData(this, row)
            Responses = getResponse(this.Tool.ControlDesignData);
            if length(Responses)>=row
                val = Responses(row);
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
            this.MenuPlot{1} = uimenu(this.Table.ContextMenu,...
                'label',getString(message('Control:systunegui:DataBrowserPlot')));
            
            % Add plot types dropdown
            PlotTypes = systuneapp.PlotEnum.getPlotTypes(false);
            for ct = 1:length(PlotTypes)
                this.MenuPlot{ct+1} = uimenu(this.MenuPlot{1},...
                    'label',PlotTypes(ct).Tag,...
                    'callback',@(src,data) PlotCallback(this,ct));
            end
        end
        
        function connectUI(this)
            L1 = addlistener(this.Tool.ControlDesignData,'ArchitectureChanged',...
                @(src,evt)clearSelection(this));
            L2 = addlistener(this.Tool.ControlDesignData,'Responses',...
                'PostSet',@(src,evt)updateUI(this));
            
            registerDataListeners(this,[L1 L2]);
            
            L3 = addlistener(this.Table.ContextMenu,'ContextMenuOpening',...
                @(src,data) updateContextMenu(this, src, data));
            L4 = addlistener(this.Panel,'PropertyChanged',...
                @(src,data) SelectionCallback(this,this.Table.Selection));
            
            registerUIListeners(this,[L3 L4]);
        end
        
        function DoubleClickCallback(this, row)
            sData.Name = this.Name;
            sData.Row = row;
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            OpenCallback(this);
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
        
        %% Get selected response
        function SelectedResponse = getSelectedResponse(this)
            rowIdx = this.Table.Selection;
            if rowIdx > 0
                Responses = getResponse(this.Tool.ControlDesignData);
                SelectedResponse = Responses(rowIdx);
            else
                SelectedResponse = [];
            end
        end
        
        %% Context menu callbacks
        function OpenCallback(this)
            SelectedResponse = getSelectedResponse(this);
            if systuneapp.util.openJavaApp
                editResponse(this.Tool.ControlDesignData,SelectedResponse);
            else
                editResponse(this.Tool.ControlDesignData,SelectedResponse,this.Tool.AppContainer,'center');
            end
        end
        
        function DeleteCallback(this)
            SelectedResponse = getSelectedResponse(this);
            removeResponse(this.Tool.ControlDesignData,SelectedResponse);
            delete(SelectedResponse)
        end
        
        function PlotCallback(this,PlotType)
            PlotTypes = systuneapp.PlotEnum.getPlotTypes(false);
            createResponsePlot(this.Tool.PlotManager,getSelectedResponse(this),PlotTypes(PlotType))
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
                    makeMenuVisible(this,false);
                else
                    % Select the right-clicked row if it is not selected
                    if ~any(this.Table.Selection==row)
                        this.Table.Selection = row;
                    end
                    makeMenuVisible(this,true);
                end
            end
            % Update preview panel
            SelectionCallback(this, this.Table.Selection);
        end
        
        function makeMenuVisible(this,visible)
            this.MenuOpen.Visible = visible;
            this.MenuDelete.Visible = visible;
            for ct = 1 : length(this.MenuPlot)
                this.MenuPlot{ct}.Visible = visible;
            end
        end
    end
    methods(Hidden)
        function qeOpenCallback(this)
            OpenCallback(this);
        end
    end
end