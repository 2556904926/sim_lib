classdef (Hidden) TuningGoalSelectorGC < ctrluis.AbstractGC   
    % Graphical component for Tuning Goal selection.
    
    % Copyright 2013-2021 The MathWorks, Inc.      
    
    properties
       EditTuningGoalButton
       HelpButton
       RemoveTuningGoalButton
       TuningGoalConfigTable
    end
    
    properties(GetAccess = protected, SetAccess = protected)
       TCListeners  %Tool-Component listeners 
    end
    
    properties(GetAccess = private, SetAccess = private)
        DlgConnectReq     % Handle to Connect Tuning Goals dialog
        
        SelectedRow = [];        % Selected TuningGoals table row
        Editor
        IsFirstOpen = true; %NOTE: Temporary for uitable not being drawn
    end
    
    methods
        function this = TuningGoalSelectorGC(tcpeer)
            % Construct TuningGoalSelectorGC graphical component            
            % Call parent constructor
            this = this@ctrluis.AbstractGC(tcpeer);
            this.Name = 'TuningGoalSelectorDialog';
            this.Title = getString(message('Control:systunegui:TuningGoalSelectorTitle'));
            this.DeleteOnClose = false;
        end

        function updateUI(this)
            disableTableListeners(this);
            
            %Set Data to display in OPtable
            data = getModelTBData(this);
            this.TuningGoalConfigTable.Data = data;
            % NOTE: Fix for uitable not being created properly when first
            % opened
            if this.IsFirstOpen
                pause(2)
            end
            % NOTE: Fix for uitable not honoring setting for ColumnEditable
            % if done in buildUI
            this.TuningGoalConfigTable.ColumnEditable = [true false true];
            setTableStatus(this);
            enableTableListeners(this);
            
            this.IsFirstOpen = false;
        end

        function Widgets = qeGetWidgets(this)
            Widgets = struct('EditTuningGoalButton',this.EditTuningGoalButton,...
                       'HelpButton',this.HelpButton,...
                       'RemoveTuningGoalButton',this.RemoveTuningGoalButton,...
                       'TuningGoalConfigTable',this.TuningGoalConfigTable,...
                       'Editor',this.Editor);
        end
        function row = qeGetSelectedRow(this)
            row = this.SelectedRow;
        end
    end
    
    methods(Access = protected)
        
        function buildUI(this)
                %BUILD
                % GridLayout
                this.UIFigure.Position(3:4) = [480 220];
                figureGrid = uigridlayout(this.UIFigure,[1 2]);
                figureGrid.RowSpacing = 0;
                figureGrid.RowHeight = {140,55};
                figureGrid.ColumnWidth = {'1x'};
                figureGrid.RowSpacing = 5;
    
                % Tuning Goals table
                HeaderStrings = {getString(message('Control:systunegui:TuningGoalSelectorActive')), ...
                    getString(message('Control:systunegui:TuningGoalSelectorTuningGoals')),...
                    getString(message('Control:systunegui:TuningGoalSelectorHard'))};
                this.TuningGoalConfigTable = uitable(figureGrid,'Data',[]);
                this.TuningGoalConfigTable.Layout.Row = 1;
                this.TuningGoalConfigTable.Layout.Column = 1;
                this.TuningGoalConfigTable.ColumnName = HeaderStrings;
                this.TuningGoalConfigTable.RowName = [];
                this.TuningGoalConfigTable.SelectionType = 'row';
                this.TuningGoalConfigTable.RowStriping = 'off';
                this.TuningGoalConfigTable.DisplayDataChangedFcn = @(~,~) tableChanged(this);
                this.TuningGoalConfigTable.CellSelectionCallback = @(~,evt) cbCellSelection(this,evt);
                
                % Button Panel
                ButtonPanel = uipanel(figureGrid,'Title',' ');
                ButtonPanel.Layout.Row = 2;
                ButtonPanel.Layout.Column = 1;
                ButtonPanel.BorderType = 'none';
                ButtonGrid = uigridlayout(ButtonPanel,[1 5]);
                ButtonGrid.ColumnWidth = {'fit','1x','fit','fit','fit'};
                ButtonGrid.RowHeight = 22;

                % Edit button
                this.EditTuningGoalButton = uibutton(ButtonGrid);
                this.EditTuningGoalButton.Layout.Row = 1;
                this.EditTuningGoalButton.Layout.Column = 4;
                this.EditTuningGoalButton.Text = getString(message('Control:systunegui:TuningGoalSelectorEdit'));
                this.EditTuningGoalButton.Tag = 'TuningGoalSelectorDialog:EditButton';
                this.EditTuningGoalButton.ButtonPushedFcn = @(~,~) editSelectedGoal(this);
                
                % Help Button
                this.HelpButton = uibutton(ButtonGrid);
                this.HelpButton.Layout.Row = 1;
                this.HelpButton.Layout.Column = 1;
                this.HelpButton.Text = getString(message('Controllib:gui:lblHelp'));
                this.HelpButton.Tag = 'TuningGoalSelectorDialog:HelpButton';
                this.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButton(this);

                % Remove Button
                this.RemoveTuningGoalButton = uibutton(ButtonGrid);
                this.RemoveTuningGoalButton.Layout.Row = 1;
                this.RemoveTuningGoalButton.Layout.Column = 5;
                this.RemoveTuningGoalButton.Text = getString(message('Control:systunegui:TuningGoalSelectorRemove'));
                this.RemoveTuningGoalButton.Tag = 'TuningGoalSelectorDialog:RemoveButton';
                this.RemoveTuningGoalButton.ButtonPushedFcn = @(~,~) removeSelectedGoal(this); 
        end

        %% Enable/Disable functions
        function disableButtons(this)
            this.EditTuningGoalButton.Enable = false;
            this.RemoveTuningGoalButton.Enable = false;
        end
        function enableButtons(this)
            this.EditTuningGoalButton.Enable = true;
            this.RemoveTuningGoalButton.Enable = true;
        end     
        function disableTableListeners(this)
            disableDataListeners(this);                    
        end
        function enableTableListeners(this)
            enableDataListeners(this);
        end
        function setTableStatus(this)
            if isempty(this.SelectedRow) || (this.SelectedRow <=0) || (this.SelectedRow > size(this.TuningGoalConfigTable.Data,1))
                disableButtons(this);
            else
                enableButtons(this);
            end    
        end
        
        %% Button Callbacks
        function removeSelectedGoal(this)
           TargetRow = this.SelectedRow;
           NumRows = size(this.TuningGoalConfigTable.Data,1);
           if TargetRow == NumRows
               this.SelectedRow = NumRows-1;               
           end                                
           TuningGoals = this.TCPeer.Data.getTuningGoal;
           this.TCPeer.Data.ControlDesignData.removeTuningGoal(TuningGoals{TargetRow,1});           
        end      
        function editSelectedGoal(this)
            TuningGoalWrappers = this.TCPeer.Data.ControlDesignData.getTuningGoal;            
            TuningGoalWrapperToEdit = TuningGoalWrappers(this.SelectedRow,1);
            % #CSTunerDialogManagement
            % Open in center of screen.
            TuningGoalWrapperToEdit.edit(this.TCPeer.Data.ControlDesignData);
            % Store Editor object
            this.Editor = TuningGoalWrapperToEdit.Editor.GC;            
        end      
        
        %% Action Functions
        function cbCellSelection(this,cellData)
            row = cellData.Indices(1,1);           
            this.SelectedRow = row;
            setTableStatus(this);
        end                                      
        function tableChanged(this)
            % TABLECHANGED Updates data in TCPeer when user interacts with
            % the table
            tbl = this.TuningGoalConfigTable;
            data = tbl.Data;
            currData = this.TCPeer.Data.TuningGoals;
            update = false;
            for ct=1:size(currData,1)
                if currData{ct,2} ~= data{ct,1}
                    currData{ct,2} = data{ct,1};
                    update = true;
                end
            end
            for ct=1:size(currData,1)
                if currData{ct,3} ~= data{ct,3}
                    currData{ct,3} = data{ct,3};
                    update = true;
                end
            end
            if update % if there update, update peer data
                disableTableListeners(this);
                setTuningGoalData(this.TCPeer,currData); 
                enableTableListeners(this);
            end
        end        
        function data = getModelTBData(this)
            %GETMODELREQDATA
            %
            
            rdata = this.TCPeer.Data.TuningGoals;
            data = cell(size(rdata,1),3);
            if ~isempty(data)
                for ct=1:size(rdata,1)
                    data{ct,1} = rdata{ct,2};
                    data{ct,2} = rdata{ct,1}.TuningGoal.Name;
                    data{ct,3} = rdata{ct,3};
                end
            end
        end        
        
        %% Others
        function cbHelpButton(this) %#ok<MANU>
            helpview('control','TuningGoalSelectorHelp','CSHelpWindow');
        end                    
    end   
end
