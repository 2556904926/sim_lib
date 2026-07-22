classdef InputTable < matlab.mixin.SetGet & ...
                        controllib.ui.internal.dialog.MixedInUIListeners
    % Input Table Panel for Linear Simulation Tool
    
    % Copyright 2020 The MathWorks, Inc.
    properties(Dependent)
        SelectedRows
    end
    
    properties (Access = ?lsimgui.internal.LinearSimulationTool)
        CopiedSignal
        CutMenu
        CopyMenu
        PasteMenu
        InsertMenu
        DeleteMenu
    end
    
    properties (GetAccess = public, SetAccess = private)
        Name
        Data
        Parent
    end
    
    properties (Access = private)
        Container
        ImportSignalButton
        DesignSignalButton
        SignalsTable
        SummaryLabel
        
        TableVariableNames = {m('Controllib:gui:strChannels'),...
            m('Controllib:gui:strData'),...
            m('Controllib:gui:strVariableDimensions')};
        ImportSignalDlg
        DesignSignalDlg
        
        SelectedCellStyle = uistyle('BackgroundColor',0.15*([0 0.6 1]) + 0.85*([1 1 1]))
        
        NonEditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input-readonly');
        EditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input');

        FixedGridSizeForTable = [268 200];
    end
    
    methods
        function this = InputTable(hParent,data)
            this.Name = 'InputSignalsWidget';
            this.Parent = hParent;
            this.Data = data;
            this.Container = createContainer(this);
        end
        
        function updateUI(this)
            updateTableData(this);
            updateSummary(this);
        end
        
        function widget = getWidget(this)
            widget = this.Container;
        end
        
        function delete(this)
            if ~isempty(this.ImportSignalDlg)
                delete(this.ImportSignalDlg);
                this.ImportSignalDlg = [];
            end
            
            if ~isempty(this.DesignSignalDlg)
                delete(this.DesignSignalDlg);
                this.DesignSignalDlg = [];
            end
        end
        
        function closeDialogs(this)
            if ~isempty(this.ImportSignalDlg)
                close(this.ImportSignalDlg);
            end
            
            if ~isempty(this.DesignSignalDlg)
                close(this.DesignSignalDlg);
            end
        end
        
        function tableData = getSignalsTableData(this)
            tableData = this.SignalsTable.Data;
        end
        
        function setFixedTableSize(this)
            this.Container.ColumnWidth{2} = this.FixedGridSizeForTable(1);
            this.Container.RowHeight{3} = this.FixedGridSizeForTable(2);
        end
        
        function setAutoTableSize(this)
            this.Container.ColumnWidth{2} = '1x';
            this.Container.RowHeight{3} = '1x';
        end
    end
    
    methods %get/set
        % SelectedRow
        function selectedRows = get.SelectedRows(this)
            selectedRows = this.SignalsTable.Selection;
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createContainer(this)
            widget = uigridlayout('Parent',this.Parent);
            widget.RowHeight = {'fit','fit','1x',40,'fit'};
            widget.ColumnWidth = {'fit','1x','fit','fit'};
            widget.Scrollable = 'off';
            
            % Widget header label
            label = uilabel(widget,'Text',m('Controllib:gui:strSystemInputs'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            label.FontWeight = 'bold';
            
            % Table
            signaltable = uitable('Parent',widget);
            signaltable.Layout.Row = 3;
            signaltable.Layout.Column = [1 4];
            signaltable.SelectionType = 'row';
            %             signaltable.Data = rand(this.NumberOfInputs_I,3);
            signaltable.RowStriping = 'off';
            signaltable.ColumnEditable = [false,true,false];
            signaltable.FontSize = 10;
            signaltable.CellSelectionCallback = @(es,ed) cbCellSelectionChanged(this,es,ed);
            addStyle(signaltable,this.NonEditableCellStyle,'column',[1 3]);
            addStyle(signaltable,this.EditableCellStyle,'column',2);
            this.SignalsTable = signaltable;
            
            % Summary
            label = uilabel(widget);
            label.Layout.Row = 4;
            label.Layout.Column = [1 4];
            label.Text = m('Controllib:gui:msgUseImportDesignButtons');
%                         label.TextWrap = 'on';
            label.HorizontalAlignment = 'center';
            this.SummaryLabel = label;
            
            % Buttons
            button = uibutton(widget,'Text',m('Controllib:gui:strImportSignalLabel'));
            button.Layout.Row = 5;
            button.Layout.Column = 3;
            button.ButtonPushedFcn = @(es,ed) cbImportSignalButtonPushed(this,es,ed);
            this.ImportSignalButton = button;
            
            button = uibutton(widget,'Text',m('Controllib:gui:strDesignSignalLabel'));
            button.Layout.Row = 5;
            button.Layout.Column = 4;
            button.ButtonPushedFcn = @(es,ed) cbDesignSignalButtonPushed(this,es,ed);
            this.DesignSignalButton = button;
            
            % Add Tags
            lsimgui.utils.internal.addTagsToWidgets(this);
        end
    end
    
    methods(Access = {?lsimgui.dialogs.internal.ImportSignal, ...
                        ?lsimgui.dialogs.internal.DesignSignal})
        function updateSignals(this,signal)
            % Get selected rows and number of imported signals
            selectedRows = this.SelectedRows;
            importSignalLength = length(signal.Columns);
            selectedSignalLength = length(selectedRows);
            try
            selectedRows = checkSignalLengthValidity(this,...
                selectedRows,importSignalLength);
            if ~isempty(selectedRows)
                % Update signal structure
                inputSignals = repmat(lsimgui.utils.internal.createEmptySignal(),...
                                            1,importSignalLength);
                switch signal.Source(1:3)
                    case {'wor','mat'}
                        varName = signal.SubSource;
                        for k = 1:importSignalLength
                            inputSignals(k).Transposed = ...
                                signal.Transposed;
                            inputSignals(k).Source = ...
                                signal.Source(1:3);
                            inputSignals(k).SubSource = varName;
                            inputSignals(k).Value = ...
                                signal.Data(:,signal.Columns(k));
                            inputSignals(k).Construction = ...
                                signal.Construction;
                            inputSignals(k).Interval = ...
                                [1 length(inputSignals(k).Value)];
                            inputSignals(k).Column = ...
                                signal.Columns(k);
                            inputSignals(k).Name = varName;
                            inputSignals(k).Size = size(signal.Data);
                            inputSignals(k).Length = [];
                        end
                    case 'inp'
                        for k = 1:lenimport
                            inputdata(selectedRows(k)).source = copyStruc.tablesources{k}; %#ok<*AGROW> 
                            inputdata(selectedRows(k)).values = copyStruc.data{k};
                            inputdata(selectedRows(k)).subsource = copyStruc.subsource{k};
                            inputdata(selectedRows(k)).construction = copyStruc.construction{k};
                            inputdata(selectedRows(k)).interval = copyStruc.intervals(2*k-1:2*k);
                            inputdata(selectedRows(k)).column = copyStruc.columns{k};
                            inputdata(selectedRows(k)).name = copyStruc.names{k};
                            inputdata(selectedRows(k)).transposed = copyStruc.transposed(k);
                            inputdata(selectedRows(k)).size = copyStruc.size(2*k-1:2*k);
                        end
                    case {'xls','csv','asc'}
                        for k=1:length(signal.Columns)
                            inputSignals(k).Transposed = ...
                                signal.Transposed;
                            inputSignals(k).Source = ...
                                signal.Source(1:3);
                            inputSignals(k).SubSource = ...
                                signal.SubSource;
                            inputSignals(k).Value = signal.Data(:,k);
                            inputSignals(k).Construction = ...
                                signal.Construction;
                            inputSignals(k).Interval = ...
                                [1 length(inputSignals(k).Value)];
                            inputSignals(k).Column = ...
                                signal.Columns(k);
                            inputSignals(k).Name = ...
                                ['Column' char('A'+signal.Columns(k)-1)];
                            inputSignals(k).Size = ...
                                [length(inputSignals(k).Value) 1];
                            inputSignals(k).Length = [];
                        end
                    case 'sig'
                        for k=1:selectedSignalLength
                            inputSignals(k).Source = ...
                                signal.Source(1:3);
                            inputSignals(k).SubSource = ...
                                signal.SubSource;
                            inputSignals(k).Value = signal.Data;
                            inputSignals(k).Construction = ...
                                signal.Construction;
                            inputSignals(k).Interval = ...
                                [1 signal.Length];
                            inputSignals(k).Column = 1;
                            inputSignals(k).Name =  signal.SubSource;
                            inputSignals(k).Size = ...
                                [length(inputSignals(k).Value) 1];
                        end
                end
                oldSignals = this.Data.InputSignals;
                updateInputSignals(this.Data,inputSignals,selectedRows);
                if this.Data.MinimumSignalInterval < this.Data.SimulationSamples
                    strOK = getString(message('Control:general:strOK'));
                    strCancel = getString(message('Control:general:strCancel'));
                    qstr = getString(message('Controllib:gui:msgReduceDataSamples',...
                        num2str(this.Data.MinimumSignalInterval)));
                    continueimp = uiconfirm(getParentUIFigure(this),qstr, ...
                        getString(message('Controllib:gui:strLinearSimulationTool')),...
                        'Options',{strOK,strCancel},...
                        'DefaultOption',strOK);
                    if strcmp(continueimp,strCancel)
                        updateInputSignals(this.Data,oldSignals,selectedRows);
                    else
                        % force input signals to have the new shorter length
                        syncInputSignals(this.Data);
                    end
                end
                updateTableData(this);
                updateSummary(this);
            end
            
            catch
                
            end
        end
    end
    
    methods(Access = ?lsimgui.internal.LinearSimulationTool)
        function createTableContextMenu(this)
            if ~isempty(ancestor(this.Container,'figure')) && ...
                    isempty(this.SignalsTable.ContextMenu)
                % Context Menu
                this.SignalsTable.ContextMenu = ...
                    uicontextmenu(ancestor(this.Container,'figure'));
                L = addlistener(this.SignalsTable.ContextMenu,'ContextMenuOpening',...
                    @(es,ed) openContextMenu(this,es,ed));
                registerUIListeners(this,L,'ContextMenuOpeningListener');
                % Menu Items
                this.CutMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strCutSignal'),...
                    'Tag','cutsignal');
                this.CutMenu.MenuSelectedFcn = @(es,ed) cutSignal(this);
                this.CopyMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strCopySignal'),...
                    'Tag','copysignal');
                this.CopyMenu.MenuSelectedFcn = @(es,ed) copySignal(this);
                this.PasteMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strPasteSignal'),...
                    'Tag','pastesignal');
                this.PasteMenu.MenuSelectedFcn = @(es,ed) pasteSignal(this);
                this.InsertMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strInsertSignal'),...
                    'Tag','insertsignal');
                this.InsertMenu.MenuSelectedFcn = @(es,ed) insertSignal(this);
                this.DeleteMenu = uimenu(this.SignalsTable.ContextMenu,...
                    'Text',m('Controllib:gui:strDeleteSignal'),...
                    'Tag','deletesignal');
                this.DeleteMenu.MenuSelectedFcn = @(es,ed) deleteSignal(this);
            end
        end
        
        function openContextMenu(this,es,ed)
            if isa(es,'matlab.ui.container.Menu')
                cutMenu = findall(es,'Tag','CutMenu');
                copyMenu = findall(es,'Tag','CopyMenu');
                pasteMenu = findall(es,'Tag','PasteMenu');
                insertMenu = findall(es,'Tag','InsertMenu');
                deleteMenu = findall(es,'Tag','DeleteMenu');
            else
                cutMenu = this.CutMenu;
                copyMenu = this.CopyMenu;
                pasteMenu = this.PasteMenu;
                insertMenu = this.InsertMenu;
                deleteMenu = this.DeleteMenu;

                row = ed.InteractionInformation.DisplayRow;
                col = ed.InteractionInformation.DisplayColumn;
                if isempty([row col])
                    this.SignalsTable.Selection = [];
                else
                    this.SignalsTable.Selection = row;
                end
            end
            
            if ~isempty(this.SignalsTable.Selection)
                set(es.Children,'Enable',true);
                % Cut/Copy/Delete
                if isSelectedSignalEmpty(this)
                    copyMenu.Enable = false;
                    cutMenu.Enable = false;
                    deleteMenu.Enable = false;
                else
                    copyMenu.Enable = true;
                    cutMenu.Enable = true;
                    deleteMenu.Enable = true;
                end
                % Insert/Paste
                if isempty(this.CopiedSignal)
                    insertMenu.Enable = false;
                    pasteMenu.Enable = false;
                else
                    insertMenu.Enable = true;
                    pasteMenu.Enable = true;
                end
            else
                set(es.Children,'Enable',false);
            end
        end
        
        function cutSignal(this)
            this.CopiedSignal = this.Data.InputSignals(this.SelectedRows);
            resetSignal(this.Data,this.SelectedRows);
            updateTableData(this);
            updateSummary(this);
        end
        
        function copySignal(this,es,ed) %#ok<*INUSD> 
            this.CopiedSignal = this.Data.InputSignals(this.SelectedRows);
        end
        
        function pasteSignal(this,es,ed)
            copiedSignalLength = length(this.CopiedSignal);
            selectedRows = checkSignalLengthValidity(this,...
                                this.SelectedRows,copiedSignalLength);
            if ~isempty(this.CopiedSignal)
                this.Data.InputSignals(selectedRows) = this.CopiedSignal;
                updateTableData(this);
                updateSummary(this);
            end
        end
        
        function insertSignal(this,es,ed)
            copiedSignalLength = length(this.CopiedSignal);
            selectedRows = checkSignalLengthValidity(this,...
                                this.SelectedRows,copiedSignalLength);
            if ~isempty(selectedRows)
                this.Data.InputSignals(selectedRows) = this.CopiedSignal;
            end
        end
        
        function deleteSignal(this,es,ed)
            resetSignal(this.Data,this.SelectedRows);
            updateTableData(this);
            updateSummary(this);
        end
    end
    
    methods (Access = private)
        function updateTableData(this)
            n = this.Data.NumberOfInputs;
            channelNames = cell(n,1);
            dataString = repmat({''},n,1);
            variableDimensionsString = repmat({''},n,1);
            for k = 1:n
                % Channel Name Column
                if isempty(this.Data.ChannelNames{k})
                    channelNames{k} = num2str(k);
                else
                    channelNames{k} = this.Data.ChannelNames{k};
                end
                % Data Column
                
                if ~isempty(this.Data.InputSignals(k).Value)
                    startIdx = this.Data.InputSignals(k).Interval(1);
                    endIdx = this.Data.InputSignals(k).Interval(2);
                    if this.Data.InputSignals(k).Transposed
                        dataString{k} = [this.Data.InputSignals(k).Name,...
                            '(',num2str(this.Data.InputSignals(k).Column),',',...
                            num2str(startIdx),':',...
                            num2str(endIdx),')'];
                    else
                        dataString{k} = [this.Data.InputSignals(k).Name,...
                            '(',num2str(startIdx),':',...
                            num2str(endIdx),',',...
                            num2str(this.Data.InputSignals(k).Column),')'];
                    end
                    variableDimensionsString{k} = [num2str(this.Data.InputSignals(k).Size(1)),...
                        ' x ',num2str(this.Data.InputSignals(k).Size(2))];
                end
                % Variable Dimensions
                
            end
            tableData = table(channelNames,dataString,variableDimensionsString,...
                'VariableNames',{m('Controllib:gui:strChannels'),...
                m('Controllib:gui:strData'),...
                m('Controllib:gui:strVariableDimensions')});
            this.SignalsTable.Data = tableData;
        end
        
        function updateSummary(this)
            selectedinputs = this.SelectedRows;
            numselectedinputs = length(selectedinputs);
            selectedSignals = this.Data.InputSignals(selectedinputs);
            if numselectedinputs==1
                switch selectedSignals.Source
                    case 'xls'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom1',...
                            selectedSignals.SubSource, ...
                            selectedSignals.Construction,...
                            num2str(selectedSignals.Column));
                    case 'asc'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom2',...
                            selectedSignals.SubSource,...
                            selectedSignals.Construction,...
                            selectedSignals.Column);
                    case 'csv'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom3',...
                            selectedSignals.Construction,...
                            num2str(selectedSignals.Column));
                    case 'wor'
                        if selectedSignals.Transposed
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom4',...
                                selectedSignals.SubSource,...
                                num2str(selectedSignals.Column));
                        else
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom5',...
                                selectedSignals.SubSource,...
                                num2str(selectedSignals.Column));
                        end
                    case 'mat'
                        if selectedSignals.Transposed
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom6', ...
                                selectedSignals.SubSource,...
                                selectedSignals.Construction,...
                                num2str(selectedSignals.Column));
                        else
                            summaryString = m('Controllib:gui:msgOriginallyLoadedFrom7', ...
                                selectedSignals.SubSource,...
                                selectedSignals.Construction,...
                                num2str(selectedSignals.Column));
                        end
                    case 'sig'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom8', ...
                            selectedSignals.SubSource,...
                            selectedSignals.Construction);
                    case 'ini'
                        summaryString = m('Controllib:gui:msgOriginallyLoadedFrom9', ...
                            num2str(selectedSignals.Column));
                    otherwise
                        summaryString = m('Controllib:gui:msgUseImportDesignButtons');
                end
                
            elseif numselectedinputs > 1
                summaryString = m('Controllib:gui:strMultiSelect');
            else
                summaryString = m('Controllib:gui:strNoSelection');
            end
            this.SummaryLabel.Text = summaryString;
            
        end
        
        function cbImportSignalButtonPushed(this,es,ed)
            if isempty(this.ImportSignalDlg) || ~isvalid(this.ImportSignalDlg)
                this.ImportSignalDlg = lsimgui.dialogs.internal.ImportSignal(this);
            end
            show(this.ImportSignalDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function cbDesignSignalButtonPushed(this,es,ed)
            if length(this.Data.TimeVector) < 2
                uiconfirm(getParentUIFigure(this),...
                    m('Controllib:gui:LsimTimeVectorLength'),...
                    m('Controllib:gui:strLinearSimulationTool'),...
                    'Icon','error');
                return;
            end
            if isempty(this.DesignSignalDlg) || ~isvalid(this.DesignSignalDlg)
                this.DesignSignalDlg = lsimgui.dialogs.internal.DesignSignal(this);
            end
            show(this.DesignSignalDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function cbCellSelectionChanged(this,es,ed)
            updateSummary(this);
        end
        
        function signalEmpty = isSelectedSignalEmpty(this)
            signalEmpty = true;
            if ~isempty(this.SelectedRows)
                signalEmpty = isempty(this.Data.InputSignals(this.SelectedRows(1)).Value);
            end
        end
        
        function selectedRows = checkSignalLengthValidity(this,selectedRows,importSignalLength)
            % Error checks based on imported signal and selected rows
            selectedSignalLength = length(selectedRows);
            if importSignalLength ~= selectedSignalLength
                if selectedSignalLength == 1
                    % Check if sufficient room in table
                    if importSignalLength > this.Data.NumberOfInputs - selectedRows + 1
                        showError(this,m('Controllib:gui:errInsufficientRoomAddSignal'));
                    end
                    
                    if importSignalLength > 1
                        if ~all(cellfun(@isempty,...
                                {this.Data.InputSignals(selectedRows+1:(selectedRows+importSignalLength-1)).Name}))
                            strOK = m('Control:general:strOK');
                            strCancel = m('Control:general:strCancel');
                            f = getParentUIFigure(this);
                            f.WindowStyle = 'modal';
                            overwrite = uiconfirm(getParentUIFigure(this),...
                                m('Controllib:gui:errInsertSignalOverwrite'),...
                                m('Controllib:gui:strLinearSimulationTool'),...
                                'Options',{strOK,strCancel},...
                                'DefaultOption',strOK,...
                                'Icon','question');
                            f.WindowStyle = 'normal';
                            if strcmp(overwrite,strCancel)
                                selectedRows = [];
                                return;
                            end
                        end
                        selectedRows = selectedRows:selectedRows+importSignalLength-1;
                    end
                elseif importSignalLength == 0
%                     throw(MException('Control:lsimgui:NoInputsSelected',...
%                         m('Controllib:gui:errNoInputsSelected')));
                    showError(this,m('Controllib:gui:errNoInputsSelected'));
                else
                    errstr = m('Controllib:gui:errSizeMismatch',...
                        num2str(importSignalLength),num2str(selectedSignalLength));
%                     throw(MException('Control:lsimgui:SizeMismatch',errstr));
                    showError(this,errstr);
                end
            end
        end
        
        function showError(this,errorMessage)
            f = getParentUIFigure(this);
            currentWindowStyle = f.WindowStyle;
%             f.WindowStyle = 'modal';
            uialert(f,errorMessage,m('Controllib:gui:strLinearSimulationTool'),...
                            'Icon','error',...
                            'CloseFcn',@(es,ed) localSetWindowStyle(f,currentWindowStyle));
%             f.WindowStyle = currentWindowStyle;
%             error(errorMessage);
        end
        
        function f = getParentUIFigure(this)
            w = getWidget(this);
            f = ancestor(w,'figure');
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.ImportSignalButton = this.ImportSignalButton;
            widgets.DesignSignalButton = this.DesignSignalButton;
            widgets.SignalsTable = this.SignalsTable;
            widgets.SummaryLabel = this.SummaryLabel;
            widgets.ImportSignalDlg = this.ImportSignalDlg;
            widgets.DesignSignalDlg = this.DesignSignalDlg;
            widgets.CutMenu = this.CutMenu;
            widgets.CopyMenu = this.CopyMenu;
            widgets.PasteMenu = this.PasteMenu;
            widgets.InsertMenu = this.InsertMenu;
            widgets.DeleteMenu = this.DeleteMenu;
        end
    end
end

function localSetWindowStyle(f,currentWindowStyle)
% f.WindowStyle = currentWindowStyle;
end
function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
