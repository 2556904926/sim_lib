classdef InitialTable < matlab.mixin.SetGet
    % Initial Table Panel for Linear Simulation Tool
    
    % Copyright 2020 The MathWorks, Inc.
    properties(Dependent)
        SelectedRows
        SelectedSystem
    end
    
    properties (GetAccess = public, SetAccess = private)
        Name
    end
    
    properties (Access = private)
        Parent
        Data
        Container
        
        ChannelNames_I = {''}
        
        SelectedSystemDropDown
        ImportStateVectorButton
        StatesTable
        NoStateSpaceLabel
     
        TableVariableNames = {m('Controllib:gui:strStateName'),...
            m('Controllib:gui:strInitialValue')};
        ImportStatesDlg
        
        SelectedCellStyle = uistyle('BackgroundColor',0.15*([0 0.6 1]) + 0.85*([1 1 1]))
        NonEditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input-readonly');
        EditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input');
        
        FixedGridSizeForTable = [241 200];
    end
    
    methods
        function this = InitialTable(hParent,data)
            this.Name = 'InitialStatesWidget';
            this.Parent = hParent;
            this.Data = data;
            this.Container = createContainer(this);
        end
        
        function updateUI(this)
            updateTableData(this);
            if ~isempty(this.ImportStatesDlg) && isvalid(this.ImportStatesDlg)
                updateUI(this.ImportStatesDlg)
            end
        end
        
        function widget = getWidget(this)
            widget = this.Container;
        end
        
        function delete(this)
            if ~isempty(this.ImportStatesDlg)
                delete(this.ImportStatesDlg);
                this.ImportStatesDlg = [];
            end
        end
        
        function updateState(this,state)
            idx = strcmp({this.Data.Systems.Name},this.SelectedSystemDropDown.Value);
            if length(state) == length(this.Data.Systems(idx).InitialStates)
                this.Data.Systems(idx).InitialStates = state(:);
                updateUI(this);
            end
        end
        
        function closeDialogs(this)
            if ~isempty(this.ImportStatesDlg) && isvalid(this.ImportStatesDlg)
                close(this.ImportStatesDlg);
            end
        end
        
        function setFixedTableSize(this)
            this.Container.ColumnWidth{3} = this.FixedGridSizeForTable(1);
            this.Container.RowHeight{5} = this.FixedGridSizeForTable(2);
        end
        
        function setAutoTableSize(this)
            this.Container.ColumnWidth{3} = '1x';
            this.Container.RowHeight{5} = '1x';
        end
    end
    
    methods %get/set
        % SelectedRow
        function selectedRows = get.SelectedRows(this)
            selectedRows = this.SignalsTable.Selection;
        end
        
        % SelectedSystem
        function selectedSystem = get.SelectedSystem(this)
            idx = strcmp({this.Data.Systems.Name},this.SelectedSystemDropDown.Value);
            if ~isempty(idx)
                selectedSystem = this.Data.Systems(idx);
            else
                selectedSystem = [];
            end
        end
        
        function set.SelectedSystem(this,system)
            idx = strcmp({this.Data.Systems.Name},this.SelectedSystemDropDown.Value);
            this.Data.Systems(idx) = system;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createContainer(this)
            widget = uigridlayout('Parent',this.Parent);
            widget.RowHeight = {'fit',1,'fit','fit','1x','fit'};
            widget.ColumnWidth = {'fit','fit','1x','fit'};
            widget.Scrollable = 'off';
            
            % System Selection
            label = uilabel(widget,'Text',m('Controllib:gui:strSelectedSystemLabel'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            dropdown = uidropdown(widget);
            dropdown.Layout.Row = 1;
            dropdown.Layout.Column = 2;
            stateIdx = cellfun(@(x) ~isempty(x),{this.Data.Systems.InitialStates});
            dropdown.Items = {this.Data.Systems(stateIdx).Name};
            dropdown.ValueChangedFcn = ...
                @(es,ed) cbSelectedSystemDropDownValueChanged(this,es,ed);
            this.SelectedSystemDropDown = dropdown;
            % Table header
            label = uilabel(widget,'Text',m('Controllib:gui:strSpecifyInitialStates'));
            label.Layout.Row = 3;
            label.Layout.Column = [1 3];
            label.FontWeight = 'bold';
            % Label for no state space systems
            label = uilabel(widget);
            label.Layout.Row = 4;
            label.Layout.Column = [1 4];
            label.HorizontalAlignment = 'center';
            label.Text = m('Controllib:gui:LsimNoStateSpaceSystems');
            this.NoStateSpaceLabel = label;
            % Table
            statestable = uitable('Parent',widget);
            statestable.Layout.Row = 5;
            statestable.Layout.Column = [1 4];
%             initialtable.SelectionType = 'row';
            statestable.RowStriping = 'off';
            statestable.ColumnEditable = [false,true];
            statestable.FontSize = 10;
            statestable.CellEditCallback = @(es,ed) cbCellEdited(this,es,ed);
            addStyle(statestable,this.NonEditableCellStyle,'column',1);
            addStyle(statestable,this.EditableCellStyle,'column',2);
            this.StatesTable = statestable;
            % Import Button
            button = uibutton(widget,'Text',m('Controllib:gui:strImportStateVectorLabel'));
            button.Layout.Row = 6;
            button.Layout.Column = 4;
            button.ButtonPushedFcn = @(es,ed) cbImportStateVectorButtonPushed(this,es,ed);
            this.ImportStateVectorButton = button;
            % Add Tags
            lsimgui.utils.internal.addTagsToWidgets(this);
        end
    end
    
    methods (Access = private)
        function updateTableData(this)
            sys = this.SelectedSystem;
            widget = getWidget(this);
            if ~isempty(sys)
                this.StatesTable.Data = table(sys.StateName,...
                    sys.InitialStates,...
                    'VariableNames',this.TableVariableNames);
                this.NoStateSpaceLabel.Visible = 'off';
                widget.RowHeight{4} = 0;
                this.ImportStateVectorButton.Enable = true;
            else
                this.StatesTable.Data = table([],[],...
                    'VariableNames',this.TableVariableNames);
                this.NoStateSpaceLabel.Visible = 'on';
                widget.RowHeight{4} = 'fit';
                this.ImportStateVectorButton.Enable = false;
            end
        end
        
        function cbSelectedSystemDropDownValueChanged(this,~,~)
            updateUI(this);
        end
        
        function cbImportStateVectorButtonPushed(this,~,~)
            if isempty(this.ImportStatesDlg) || ~isvalid(this.ImportStatesDlg)
                this.ImportStatesDlg = lsimgui.dialogs.internal.ImportState(this);
            end
            show(this.ImportStatesDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function cbCellEdited(this,es,ed)
            if isnan(ed.NewData) || ~isfinite(ed.NewData)
                es.Data{ed.Indices(1),ed.Indices(2)} = ed.PreviousData;
            else
                this.SelectedSystem.InitialStates = es.Data{:,2};
            end
        end
        
        function f = getParentUIFigure(this)
            w = getWidget(this);
            f = ancestor(w,'figure');
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.SelectedSystemDropDown = this.SelectedSystemDropDown;
            widgets.ImportStateVectorButton = this.ImportStateVectorButton;
            widgets.StatesTable = this.StatesTable;
            widgets.ImportStatesDlg = this.ImportStatesDlg;
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
