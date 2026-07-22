classdef PlantListBrowser < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
%

%   Copyright 2013-2021 The MathWorks, Inc.

    properties
        PlantList
        MenuDelete
        MenuExport
        MenuSelectTuning
    end
    
    events
        ComponentRequest
    end
    
    methods
        
        %% constructor
        function this = PlantListBrowser(appData)
            % super
            this = this@matlab.ui.internal.databrowser.TableDataBrowser('PLANTLISTBROWSER', pidtool.utPIDgetStrings('cst','strPlantList'));
            % process data
            this.PlantList = appData;
            % customize widget and layout
            buildUI(this);
            % customize listeners and callbacks
            connectUI(this);
            % refresh UI
            updateUI(this);
            
            % Set height
            setPreferredHeight(this, 300)
        end
        
        %% overloaded UI methods
        function updateUI(this)
            % collect data from local workspace
            names = this.PlantList.PlantNames;
            classes = cellfun(@class,this.PlantList.Plants,'UniformOutput',false);
            this.Table.Data = [names classes];
        end
        
        %% preview panel interface methods
        function val = getName(this, idx)
            val = this.PlantList.PlantNames{idx};
        end
        
        function val = getData(this, idx)
            val = this.PlantList.Plants{idx};
        end
        
    end
    
    methods (Access = protected)
        
        %% overloaded UI methods
        function buildUI(this)
            % customize table
            ColNames = {getString(message('Control:pidtool:strName')), ...
                getString(message('Control:pidtool:strClass'))};
            this.Table.ColumnName = ColNames;
            this.Table.ColumnEditable = [true false];
            this.Table.ColumnFormat = {'char' 'char'};
            this.NameColumnIndex = 1;
            % allow multiple row selection
            this.SingleRowSelection = false;
            % add dynamic contextmenu
            this.Table.ContextMenu = uicontextmenu('parent',this.Figure);
            this.Table.ContextMenu.Tag = strcat('cmn',this.Name);
            
            this.MenuExport = uimenu(this.Table.ContextMenu,'label',...
                pidtool.utPIDgetStrings('cst','strExport'),'callback',@(src,x) localExportPlantCb(this,src));
            this.MenuSelectTuning = uimenu(this.Table.ContextMenu,'label',...
                pidtool.utPIDgetStrings('cst','strSelectForTuning'),'callback',@(src,x) localSelectPlantCb(this,src));
            this.MenuDelete = uimenu(this.Table.ContextMenu,'label',...
                getString(message('MATLAB:codetools:contextmenus:DeleteVariableAction')),'callback',@(src,data) DeleteCallback(this));
            % set preferred height
            this.setPreferredHeight(100);
        end
        
        function connectUI(this)
            L1 = addlistener(this.Table.ContextMenu,'ContextMenuOpening',@(src, data) updateContextMenu(this, src, data));
            L2 = addlistener(this.PlantList,'PlantsEvent',@(src, data) updateUI(this));
            registerUIListeners(this,L1,'ContextMenuOpeningListener');
            registerUIListeners(this,L2,'PlantsEventListener');
        end

        function cleanupUI(this)
%             if ~isempty(this.FigureDialog) && isvalid(this.FigureDialog)
%                 this.FigureDialog.SizeChangedFcn = [];
%                 delete(this.FigureDialog);
%             end
        end
        
        %% table callbacks
        function DoubleClickCallback(this, row) %#ok<INUSD>
            %NOTE: DO we want to have double click functionality?
        end
        
        function SelectionCallback(this, rows)
            % refresh preview panel
            eventdata = matlab.ui.internal.databrowser.PreviewEventData(rows);
            this.notify('PreviewRequested',eventdata);
        end
        
        function CellEditCallback(this,row,~,~,newdata)
            % change first column (checkbox)
            styleindex = find([this.Table.StyleConfigurations.TargetIndex{:}]==row);
            if ~isempty(styleindex)
                removeStyle(this.Table,styleindex);
            end
            if newdata 
                % checked
                s = uistyle('FontWeight','bold');
            else
                %unchecked
                s = uistyle('FontWeight','normal');
            end
            addStyle(this.Table,s,'row',row);                    
        end

        function RenameCallback(this,row,oldname,newname)
            this.PlantList.renamePlant(oldname,newname);
            % refresh preview panel 
            eventdata = matlab.ui.internal.databrowser.PreviewEventData(row);
            this.notify('PreviewRequested',eventdata);
        end
        
        %% context menu callbacks        
        function DeleteCallback(this)
            rows = this.Table.Selection;
            
            if ~isempty(rows)
                for ii=length(rows):-1:1
                    success = this.PlantList.removePlant(this.PlantList.PlantNames{rows(ii)});
                    if ~success
                        uiconfirm(this.Figure,pidtool.utPIDgetStrings('cst','strCannotRemovePlant'),'')
                    end
                    
                end
            end
            % refresh preview panel and change selection
            eventdata = matlab.ui.internal.databrowser.PreviewEventData([]);
            this.notify('PreviewRequested',eventdata);
        end
        
        function updateContextMenu(this, ~, data)
            % in this example, right-clicking does NOT select the row.
            interactionInformation = data.InteractionInformation;
            if data.ContextObject == this.Table ...
                && ~(interactionInformation.RowHeader || interactionInformation.ColumnHeader)
                row = interactionInformation.DisplayRow;
                col = interactionInformation.DisplayColumn;
                % React when a cell or the white space is clicked.
                if isempty([row col])
                    this.Table.Selection = [];
                    % only show "Add" menu
                    this.MenuDelete.Visible = false;
                    this.MenuExport.Visible = false;
                    this.MenuSelectTuning.Visible = false;
                else
                    rows = this.Table.Selection;
                    % Select Right-clicked row if it is not already
                    % selected
                    if ~any(rows==row)
                        this.Table.Selection = row;
                        rows = row;
                    end
                    if length(rows)~=1
                        % Multiple rows selected, do not display "Select
                        % For Tuning" and "Rename" items
                        this.MenuDelete.Visible = true;
                        this.MenuExport.Visible = true;
                        this.MenuSelectTuning.Visible = false;
                    else
                        % Only 1 row selected
                        this.MenuDelete.Visible = true;
                        this.MenuExport.Visible = true;
                        this.MenuSelectTuning.Visible = true;
                    end
                end
            end
        end
        
    end
    
end

function localExportPlantCb(this,~)
    selectedRows = this.Table.Selection;
    Variables = this.PlantList.PlantNames(selectedRows);
    notify(this,'ComponentRequest',pidtool.desktop.pidtuner.tc.PlantListBrowserEventData('export',Variables));
end

function localSelectPlantCb(this,~)
    selectedRows = this.Table.Selection;
    Variables = this.PlantList.PlantNames(selectedRows);

    % Don't select for tuning if more than 1 vairable is selected
    if length(Variables)<1.5
        notify(this,'ComponentRequest',pidtool.desktop.pidtuner.tc.PlantListBrowserEventData('select',Variables));
    end
end
