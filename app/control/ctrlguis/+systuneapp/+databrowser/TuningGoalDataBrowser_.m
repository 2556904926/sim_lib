classdef TuningGoalDataBrowser_ < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
    % Browser component for tuning goals
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties (Access = private)
        Tool
        TuningGoalDataChangeListeners
        MenuOpen
        MenuDelete
        MenuPlot
    end
    
    methods
        function this = TuningGoalDataBrowser_(compName, Tool)
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                compName, getString(message('Control:systunegui:DataBrowserTitleTuningGoals')));
            this.Tool = Tool;
            buildUI(this);
            connectUI(this);
            updateUI(this);
        end
        
        function updateUI(this)
            delete(this.TuningGoalDataChangeListeners); %Clear listeners
            this.TuningGoalDataChangeListeners=[];
            
            TuningGoals = getTuningGoal(this.Tool.ControlDesignData);
            this.Table.Data = cell(length(TuningGoals),1);
            for ct = 1:length(TuningGoals)
                L = addlistener(TuningGoals(ct),'TuningGoal','PostSet',@(es,ed) updateUI(this));
                this.TuningGoalDataChangeListeners = [this.TuningGoalDataChangeListeners;L];
                this.Table.Data{ct,1} = getName(TuningGoals(ct));
            end
            if this.Panel.Selected %Refresh Preview Panel
                SelectionCallback(this,this.Table.Selection);
            end
        end
        
        function val = getName(this, row)
            TuningGoals = getTuningGoal(this.Tool.ControlDesignData);
            val = TuningGoals(row).getName();
        end
        
        function val = getData(this, row)
            TuningGoals = getTuningGoal(this.Tool.ControlDesignData);
            if length(TuningGoals)>=row
                val = TuningGoals(row);
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
            this.MenuPlot = uimenu(this.Table.ContextMenu,...
                'label',getString(message('Control:systunegui:DataBrowserPlot')),...
                'callback',@(src,data) PlotCallback(this));
        end
        
        function connectUI(this)
            L1 = addlistener(this.Tool.ControlDesignData,'ArchitectureChanged',...
                @(src,evt)clearSelection(this));
            L2 = addlistener(this.Tool.ControlDesignData, 'TuningGoals',...
                'PostSet',@(es,ed) updateUI(this));
            
            registerDataListeners(this,[L1 L2]);
            
            L3 = addlistener(this.Table.ContextMenu,...
                'ContextMenuOpening',@(src, data) updateContextMenu(this, src, data));
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
        
        %% Context menu callbacks
        function OpenCallback(this)
            rowIdx = this.Table.Selection;
            TuningGoals = getTuningGoal(this.Tool.ControlDesignData);
            if systuneapp.util.openJavaApp
                TuningGoals(rowIdx).edit(this.Tool.ControlDesignData)
            else
                TuningGoals(rowIdx).edit(this.Tool.ControlDesignData,this.Tool.AppContainer,'center')
            end           
        end
        
        function DeleteCallback(this)
            rowIdx = this.Table.Selection;
            TuningGoals = getTuningGoal(this.Tool.ControlDesignData);
            TG = TuningGoals(rowIdx);
            removeTuningGoal(this.Tool.ControlDesignData,TG);
        end
        
        function PlotCallback(this)
            rowIdx = this.Table.Selection;
            TuningGoals = getTuningGoal(this.Tool.ControlDesignData);
            this.Tool.PlotManager.showTuningGoalPlot(TuningGoals(rowIdx))
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
            this.MenuPlot.Visible = visible;
        end
    end
end