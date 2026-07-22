classdef ExportModelDialog < controllib.ui.internal.dialog.AbstractExportDialog
    % Export model dialog for Model Reducer

    % Copyright 2015-2020 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = private)
        AppData        
    end
    
    properties(Access = private)
        SelectDesignDropdown
        SelectDesignLabel
    end
    
    %% Public methods
    methods(Access = public)        
        %% constructor
        function this = ExportModelDialog(AppData)
            Name = 'ExportModelDialog';
            Title = getString(message('Control:designerapp:TitleExportModelDialog'));
            this = this@controllib.ui.internal.dialog.AbstractExportDialog(Name,Title);
            this.AppData = AppData;
            this.TableTitle  = getString(message('Control:designerapp:ExportModelTableLabel'));
            this.AllowColumnSorting = true;
            this.AddTagsToWidgets = true;
            this.DialogSize = [350 375];
        end                 
    end   
    
    %% Implementation of protected abstract or overloaded methods
    methods(Access = protected)                            
        % Get Table Data
        function TableData = getTableData(this)
            Sidx = find(strcmp(this.SelectDesignDropdown.Value,this.SelectDesignDropdown.Items));
            if isequal(Sidx,1)
                % set table size
                TunableBlocks = getTunableBlocks(this.AppData);
                FixedBlocks = getFixedBlocks(this.AppData);
                Responses = getResponses(this.AppData);
                TableLength = length(TunableBlocks)+length(FixedBlocks)+length(Responses);
                TableWidth = 1;
                TableData = cell(TableLength,TableWidth);
                % set table data
                idx = 0;
                for ct = 1:length(TunableBlocks)
                    idx = idx+1;
                    TableData{idx} = TunableBlocks(ct).Name;
                end
                for ct = 1:length(FixedBlocks)
                    idx = idx+1;
                    TableData{idx} = FixedBlocks(ct).Name;
                end
                for ct = 1:length(Responses)
                    idx = idx+1;
                    TableData{idx} = getName(Responses(ct));
                end
            else
                Designs = getDesigns(this.AppData);
                Data = fields(Designs(Sidx-1).getValueStructure);
                TableLength = length(Data);
                TableWidth = 1;
                TableData = cell(TableLength,TableWidth);
                % set table data
                idx = 0;
                for ct = 1:length(Data)
                    idx = idx+1;
                    TableData{idx} = sprintf('%s_%s',Data{ct},getName(Designs(Sidx-1)));
                end
            end
            TableData = table(TableData,'VariableName',...
                {getString(message('Control:designerapp:ModelsExportModelDialog'))});
        end   
        
        function val = getValueAt(this,array)
            Sidx = find(strcmp(this.SelectDesignDropdown.Value,this.SelectDesignDropdown.Items));
            if isequal(Sidx,1)
                TunableBlocks = getTunableBlocks(this.AppData);
                FixedBlocks = getFixedBlocks(this.AppData);
                Responses = getResponses(this.AppData);
                if array <= length(TunableBlocks)
                    val = getValue(TunableBlocks(array));
                elseif array <= (length(TunableBlocks)+length(FixedBlocks))
                    val = getValue(FixedBlocks(array-length(TunableBlocks)));
                else
                    val = getValue(Responses(array-length(TunableBlocks)-length(FixedBlocks)));
                end
            else
                Designs = getDesigns(this.AppData);
                Data = getValueStructure(Designs(Sidx-1));
                DataName = fields(Data);
                val = Data.(DataName{array});
            end
        end
        
        function callbackHelpButton(~)
            ctrlguihelp('CSD_ExportDialogHelp','CSHelpWindow');
        end      
        
        function connectUI(this)
            L = addlistener(this.AppData,'DesignsListChanged',...
                            @(es,ed) updateSelectDesignDropdown(this));
            registerUIListeners(this,L,'DesignListChangedListener');
            L = addlistener(this.AppData,'ResponsesListChanged',@(es,ed) updateUI(this));
            registerUIListeners(this,L,'ResponseListChangedListener');
        end
    end 
    
    
    methods(Access = protected)
        function postUpdateUI(this)
            updateSelectDesignDropdown(this);
        end
        
        function updateSelectDesignDropdown(this)
            % Update table after repopulating the dropdown if a design is
            % selected
            if ~strcmp(this.SelectDesignDropdown.Value,this.SelectDesignDropdown.Items{1})
                updateTableFlag = true;
            else
                updateTableFlag = false;
            end
            % Repopulate drowpdown
            currentSelection = this.SelectDesignDropdown.Value;
            this.SelectDesignDropdown.Items = {};
            this.SelectDesignDropdown.Items = ...
                {getString(message('Control:designerapp:CurrentDesign'))};
            Designs = getDesigns(this.AppData);
            for ct = 1:length(Designs)
                this.SelectDesignDropdown.Items = [this.SelectDesignDropdown.Items,...
                                                    {getName(Designs(ct))}];
            end
            % Do not change selected design if it still exists. Else,
            % select Current Design. 
            if any(ismember(this.SelectDesignDropdown.Items,currentSelection))
                this.SelectDesignDropdown.Value = currentSelection;
            end
            % Update table if needed
            if updateTableFlag
                updateTable(this);
            end
        end
        
        function buildCustomWidgets(this)
            % Build the top row to select design
            layout = uigridlayout('Parent',[]);
            layout.RowHeight = {'fit'};
            layout.ColumnWidth = {'fit','fit'};
            layout.Padding = [0 0 0 0];
            % Label
            this.SelectDesignLabel = uilabel(layout,'Text',...
                        getString(message('Control:designerapp:SelectDesignLabel')));
            % DropDown
            this.SelectDesignDropdown = uidropdown(layout);
            this.SelectDesignDropdown.Items = ...
                {getString(message('Control:designerapp:CurrentDesign'))};
            this.SelectDesignDropdown.ValueChangedFcn = @(es,ed) updateTable(this);
            % Add to grid
             addWidget(this,layout,'abovetable')
        end
    end
    %% Hidden methods
    methods (Hidden)
        function Widgets = qeGetCustomWidgets(this)
            Widgets.ColumnNames = this.VariableColumnName;
            Widgets.TableData = this.getTableData;
            Widgets.DialogName = this.Name;
            Widgets.DialogTitle = this.Title;
            Widgets.SelectDesignDropdown = this.SelectDesignDropdown;
            Widgets.SelectDesignLabel = this.SelectDesignLabel;
        end        
    end
end
