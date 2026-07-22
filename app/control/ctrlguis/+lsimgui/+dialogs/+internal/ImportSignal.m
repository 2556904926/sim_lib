classdef ImportSignal < controllib.ui.internal.dialog.AbstractImportDialog
    % Import Signal Dialog for Linear Simulation Tool
    
    % Copyright 2020-2022 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = private)
        SourceType
        Source
        Signal
        FileNames
        InputSignalTable
    end
    
    properties(Access = private) % Change to private
        SourceWidget
        SourceSelectionLabel
        SourceSelectionDropDown
        FileSelectionWidget
        FileSelectionEditField
        FileSelectionButton
        XLSFileWidget
        XLSFileSheetLabel
        XLSFileSheetDropDown
        ASCIIFileWidget
        ASCIIFileDelimiterLabel
        ASCIIFileDelimiterDropDown
        PostImportWidget
        AssignChannelWidget
        AssignButtonGroup
        AssignColumnRadioButton
        AssignRowRadioButton
        AssignColumnEditField
        AssignRowEditField
        MissingDataWidget
        IgnorePriorHeaderRowEditField
        SubstitutionMethodDropDown
        
        FileTypes = {'workspace','mat','xls','csv','ascii'};
        XLSData
        CSVData
        ASCIIData
        Data
    end
    
    events
        SignalCreated
    end
    
    methods
        function this = ImportSignal(inputSignalTable)
            this = this@controllib.ui.internal.dialog.AbstractImportDialog;
            this.AllowMultipleRowSelection = false;
            this.AllowColumnSorting = true;
            this.AddTagsToWidgets = true;
            this.Name = 'ImportSignalDialog';
            this.Title = getString(message('Controllib:gui:strDataImport'));
            this.SourceType = 'workspace';
            this.Source = 'base';
            this.ShowRefreshButton = false;
            this.DialogSize = [430 400];
            if nargin > 0
                this.InputSignalTable = inputSignalTable;
            end
            % Initialize file names to ''
            for k = 1:length(this.FileTypes)
                this.FileNames.(this.FileTypes{k}) = '';
            end
            % Add listener to selection changed
            L = addlistener(this,'SelectionChanged',@(es,ed) cbSelectionChanged(this,es,ed));
            registerUIListeners(this,L,{'SelectionChanged'});
        end
    end
    
    methods(Access = protected)
        function buildCustomWidgets(this)
            % Source selection widget
            widget = uigridlayout('Parent',[]);
            widget.RowHeight = {'fit','fit'};
            widget.ColumnWidth = {'fit','fit','1x'};
            widget.Padding = 0;
            this.SourceSelectionLabel = uilabel(widget,'Text',...
                m('Controllib:gui:strImportFromLabel'));
            this.SourceSelectionDropDown = uidropdown(widget);
            this.SourceSelectionDropDown.Items = {m('Controllib:gui:strWorkspace'),...
                m('Controllib:gui:strMATFile'),...
                m('Controllib:gui:strXLSFile'),...
                m('Controllib:gui:strCSVFile'),...
                m('Controllib:gui:strASCIIFile')};
            this.SourceSelectionDropDown.ItemsData = this.FileTypes;
            this.SourceSelectionDropDown.ValueChangedFcn = ...
                @(es,ed) cbSourceSelectionDropDownValueChanged(this,es,ed);
            addWidget(this,widget,'abovetable');
            this.SourceWidget = widget;
            % MATFile Widget
            widget = uigridlayout('Parent',[]);
            widget.RowHeight = {'fit','fit'};
            widget.ColumnWidth = {'fit','1x','fit'};
            widget.Padding = 0;
            label = uilabel(widget,'Text',m('Controllib:gui:strFileLabel'));
            this.FileSelectionEditField = uieditfield(widget);
            this.FileSelectionEditField.Layout.Column = 2;
            this.FileSelectionEditField.ValueChangedFcn = ...
                @(es,ed) cbFileSelectionEditFieldValueChanged(this,es,ed);
            this.FileSelectionButton = uibutton(widget,'Text',m('Controllib:gui:strBrowseLabel'));
            this.FileSelectionButton.Layout.Column = 3;
            this.FileSelectionButton.ButtonPushedFcn = ...
                @(es,ed) cbFileSelectionButtonPushed(this,es,ed);
            this.FileSelectionWidget = widget;
            % XLS File Widget
            this.XLSFileWidget = uigridlayout('Parent',[]);
            this.XLSFileWidget.RowHeight = {'fit'};
            this.XLSFileWidget.ColumnWidth = {'fit','fit'};
            this.XLSFileWidget.Padding = 0;
            this.XLSFileSheetLabel = uilabel('Parent',this.XLSFileWidget,...
                'Text',m('Controllib:gui:strSelectSheetLabel'));
            this.XLSFileSheetDropDown = uidropdown('Parent',this.XLSFileWidget);
            this.XLSFileSheetDropDown.Items = {''};
            this.XLSFileSheetDropDown.ValueChangedFcn = ...
                @(es,ed) cbXLSFileSheetDropDownValueChanged(this,es,ed);
            % ASCII File Widgets
            this.ASCIIFileWidget = uigridlayout('Parent',[]);
            this.ASCIIFileWidget.RowHeight = {'fit'};
            this.ASCIIFileWidget.ColumnWidth = {'fit','fit'};
            this.ASCIIFileWidget.Padding = 0;
            this.ASCIIFileDelimiterLabel = uilabel('Parent',this.ASCIIFileWidget,...
                'Text',m('Controllib:gui:strSelectDelimiterCharacterLabel'));
            this.ASCIIFileDelimiterDropDown = uidropdown('Parent',this.ASCIIFileWidget);
            this.ASCIIFileDelimiterDropDown.Items = {m('Controllib:gui:strSpace'),...
                                                     ',',':',...
                                                     m('Controllib:gui:strTab'),...
                                                     m('Controllib:gui:strDefault')};
            this.ASCIIFileDelimiterDropDown.ItemsData = {' ',',',':','\t',''};
            this.ASCIIFileDelimiterDropDown.ValueChangedFcn = ...
                @(es,ed) cbASCIIFileDelimiterDropDownValueChanged(this,es,ed);
            % Post Import Widget
            widget = uigridlayout('Parent',[]);
            widget.RowHeight = {'fit'};
            widget.ColumnWidth = {'1x'};
            widget.Padding = 0;
            this.AssignChannelWidget = uigridlayout(widget);
            this.AssignChannelWidget.RowHeight = {22,22};
            this.AssignChannelWidget.ColumnWidth = {'1x','fit'};
            this.AssignChannelWidget.Padding = 0;
            this.AssignButtonGroup = uibuttongroup('Parent',[]);
            this.AssignButtonGroup.Parent = this.AssignChannelWidget;
            this.AssignButtonGroup.Layout.Row = [1 2];
            this.AssignButtonGroup.Layout.Column = 1;
            this.AssignButtonGroup.BorderType = 'none';
            this.AssignRowRadioButton = uiradiobutton(this.AssignButtonGroup);
            this.AssignRowRadioButton.Position = [2 0 300 25];
            this.AssignRowRadioButton.Text = m('Controllib:gui:strAssignRowsToChannelLabel');
            this.AssignColumnRadioButton = uiradiobutton(this.AssignButtonGroup);
            this.AssignColumnRadioButton.Position = [2 30 300 25];
            this.AssignColumnRadioButton.Text = m('Controllib:gui:strAssignColumnsToChannelLabel');
            this.AssignColumnEditField = uieditfield(this.AssignChannelWidget);
            this.AssignColumnEditField.Layout.Row = 1;
            this.AssignColumnEditField.Layout.Column = 2;
            this.AssignRowEditField = uieditfield(this.AssignChannelWidget);
            this.AssignRowEditField.Layout.Row = 2;
            this.AssignRowEditField.Layout.Column = 2;
            addWidget(this,widget,'belowtable');
            this.PostImportWidget = widget;
            % Text and Missing Data Widget
            this.MissingDataWidget = uigridlayout('Parent',[]);
            this.MissingDataWidget.RowHeight = {'fit','fit','fit'};
            this.MissingDataWidget.ColumnWidth = {'1x','fit'};
            this.MissingDataWidget.Padding = 0;
            headerlabel = uilabel(this.MissingDataWidget,'Text',m('Controllib:gui:strTextAndMissingData'));
            headerlabel.FontWeight = 'bold';
            headerlabel.Layout.Row = 1;
            headerlabel.Layout.Column = [1 2];
            ignorelabel = uilabel(this.MissingDataWidget,'Text',m('Controllib:gui:strIgnoreHeaderRowsLabel'));
            ignorelabel.Layout.Row = 2;
            ignorelabel.Layout.Column = 1;
            baddatalabel = uilabel(this.MissingDataWidget,'Text',m('Controllib:gui:strBadDataSubstitutionMethodLabel'));
            baddatalabel.Layout.Row = 3;
            baddatalabel.Layout.Column = 1;
            this.IgnorePriorHeaderRowEditField = uieditfield(this.MissingDataWidget,'numeric');
            this.IgnorePriorHeaderRowEditField.Layout.Row = 2;
            this.IgnorePriorHeaderRowEditField.Layout.Column = 3;
            this.SubstitutionMethodDropDown = uidropdown(this.MissingDataWidget);
            this.SubstitutionMethodDropDown.Layout.Row = 3;
            this.SubstitutionMethodDropDown.Layout.Column = 3;
            this.SubstitutionMethodDropDown.Items = {m('Controllib:gui:strSkipRows'),...
                                                     m('Controllib:gui:strSkipCells'),...
                                                     m('Controllib:gui:strLinearlyInterpolate'),...
                                                     m('Controllib:gui:strZeroOrderHold')};
            % Add Tags
            lsimgui.utils.internal.addTagsToWidgets(this);
        end

        function tableData = getTableData(this)
            switch this.SourceType
                case {'workspace','mat'}
                    tableData = lsimgui.utils.internal.createImportTableData(getFilteredData(this));
                    this.AllowMultipleRowSelection = false;
                case {'xls','csv','ascii'}
                    filename = this.FileNames.(this.SourceType);
                    if ~isempty(filename)
                        if strcmp(this.SourceType,'xls')
                            sheetname = this.XLSFileSheetDropDown.Value;
                            data = readtable(filename,'Sheet',sheetname,'UseExcel',false,...
                                                'PreserveVariableNames',true);
                        elseif strcmp(this.SourceType,'csv')
                            data = readtable(filename,'FileType','text','EmptyValue',0,...
                                                'PreserveVariableNames',true);
                        else
                            delimiter = this.ASCIIFileDelimiterDropDown.Value;
                            if ~isempty(delimiter)
                                data = readtable(filename,'FileType','text',...
                                    'EmptyValue',0,'Delimiter',delimiter,...
                                    'PreserveVariableNames',true);
                            else
                                data = readtable(filename,'FileType','text',...
                                    'EmptyValue',0,...
                                    'PreserveVariableNames',true);
                            end
                        end
                        this.Data.(this.SourceType) = table2array(data);
                        celldata = cell(width(data),2);
                        for k = 1:width(data)
                            celldata{k,1} = char('A'+k-1);
                            celldata{k,2} = data{:,k};
                        end
                    else
                        celldata = [];
                    end
                    this.AllowMultipleRowSelection = true;
                    tableData = lsimgui.utils.internal.createImportTableData(celldata);
                    tableData.Properties.VariableNames{1} = 'Column';
            end
        end
        
        function callbackActionButton(this)
            signal = [];
            switch this.SourceType
                case {'workspace','mat'}
                    data = getSelectedData(this);
                    if ~isempty(data)
                        signal.Data = data{2};
                        datasize = size(data{2});
                        if this.AssignButtonGroup.Buttons(1).Value
                            selectedRowColStr = this.AssignRowEditField.Value;
                            signal.Columns = 1:datasize(1);
                            signal.Data = signal.Data';
                            signal.Length = datasize(2);
                            signal.Transposed = true;
                        else
                            selectedRowColStr = this.AssignColumnEditField.Value;
                            signal.Columns = 1:datasize(2);
                            signal.Length = datasize(1);
                            signal.Transposed = false;
                        end
                        if ~isempty(selectedRowColStr)
                            try
                                selectedRowCol = eval(selectedRowColStr);
                            catch
                                uiconfirm(this.UIFigure,...
                                    m('Controllib:gui:errRowColumnSpecificationInvalidSyntax'), ...
                                    m('Controllib:gui:strMATFileImport'),'Icon','error');
                                return
                            end
                            if any(selectedRowCol < 1) || any(selectedRowCol > size(signal.Data,2))
                                uiconfirm(this.UIFigure,...
                                    m('Controllib:gui:errRowColumnSpecificationSizeMismatch'),...
                                    m('Controllib:gui:strMATFileImport'),'Icon','error');
                                return
                            else
                                signal.Columns = selectedRowCol;
                            end
                        end
                        signal.Source = this.SourceType;
                        signal.SubSource = data{1};
                        signal.Construction = this.FileNames.(this.SourceType);
                    end
                case {'xls','csv','ascii'}
                    idx = getSelectedIdx(this);
                    if ~isempty(idx)
                        signal.Data = this.Data.(this.SourceType)(:,idx);
                        signal.Source = this.SourceType;
                        signal.Construction = this.FileNames.(this.SourceType);
                        signal.Columns = idx;
                        signal.Transposed = false;
                        if strcmp(this.SourceType,'xls')
                            signal.SubSource = this.XLSFileSheetDropDown.Value;
                            headEnd = this.IgnorePriorHeaderRowEditField.Value;
                            interpStr = this.SubstitutionMethodDropDown.Value;
                            signal.Data = interpolateXLSData(this,headEnd,interpStr,idx);
                        elseif strcmp(this.SourceType,'csv')
                            signal.SubSource = '';
                        elseif strcmp(this.SourceType,'ascii')
                            signal.SubSource = this.ASCIIFileDelimiterDropDown.Value;
                        end
                        signal.Length = size(signal.Data,1);
                    end
            end
            % Error dialog if selection is empty
            if isempty(signal)
                uialert(getWidget(this),...
                    getString(message('Controllib:gui:errSelectVariableToImport')),...
                    getString(message('Controllib:gui:strLinearSimulationTool')),...
                    'Icon','error');
                return;
            else
                this.Signal = signal;
                if ~isempty(this.InputSignalTable) && isvalid(this.InputSignalTable)
%                     try
                        updateSignals(this.InputSignalTable,signal);
%                     catch ex
%                         uiconfirm(this.UIFigure,ex.message,...
%                             m('Controllib:gui:strLinearSimulationTool'),...
%                             'Icon','error');
%                     end
                end
                notify(this,'SignalCreated');
            end
        end
        
        function callbackHelpButton(this) %#ok<*MANU>
            ctrlguihelp('lsim_importsignal');
        end
    end
    
    methods(Hidden)
        function widgets = qeGetCustomWidgets(this)
            widgets.DialogName = this.Name;
            widgets.DialogTitle = this.Title;
            widgets.DialogTableTitle = this.TableTitle;
            
            widgets.SourceSelectionDropDown = this.SourceSelectionDropDown;
            widgets.FileSelectionEditField = this.FileSelectionEditField;
            widgets.XLSFileSheetDropDown = this.XLSFileSheetDropDown;
            widgets.ASCIIFileDelimiterDropDown = this.ASCIIFileDelimiterDropDown;
            widgets.AssignColumnRadioButton = this.AssignColumnRadioButton;
            widgets.AssignRowRadioButton = this.AssignRowRadioButton;
            widgets.AssignColumnEditField = this.AssignColumnEditField;
            widgets.AssignRowEditField = this.AssignRowEditField;
            widgets.IgnorePriorHeaderRowEditField = this.IgnorePriorHeaderRowEditField;
            widgets.SubstitutionMethodDropDown = this.SubstitutionMethodDropDown;
        end
    end
    
    methods(Access = private)
        function filteredData = getFilteredData(this)
            data = getData(this);
            if isempty(data)
                filteredData = data;
            else
                isValidType = cellfun(@(x) isnumeric(x) & ~isscalar(x),data(:,2));
                filteredData = data(isValidType,:);
            end
        end
        
        function cbSourceSelectionDropDownValueChanged(this,es,ed)
            switch es.Value
                case 'workspace'
                    this.FileSelectionWidget.Parent = [];
                    this.AssignChannelWidget.Parent = this.PostImportWidget;
                    this.MissingDataWidget.Parent = [];
                    setSource(this,'base','workspace');
                    this.DisplayedTableHeight = 252;
                case 'mat'
                    this.FileSelectionWidget.Parent = this.SourceWidget;
                    this.FileSelectionWidget.Layout.Row = 2;
                    this.FileSelectionWidget.Layout.Column = [1 3];
                    this.XLSFileWidget.Parent = [];
                    this.ASCIIFileWidget.Parent = [];
                    this.AssignChannelWidget.Parent = this.PostImportWidget;
                    this.MissingDataWidget.Parent = [];
                    file = this.FileNames.(es.Value);
                    this.FileSelectionEditField.Value = file;
                    setSource(this,file,'matfile');
                    this.DisplayedTableHeight = 220;
                case 'xls'
                    this.FileSelectionWidget.Parent = this.SourceWidget;
                    this.FileSelectionWidget.Layout.Row = 2;
                    this.FileSelectionWidget.Layout.Column = [1 3];
                    this.XLSFileWidget.Parent = this.FileSelectionWidget;
                    this.XLSFileWidget.Layout.Row = 2;
                    this.XLSFileWidget.Layout.Column = [2 3];
                    this.ASCIIFileWidget.Parent = [];
                    this.MissingDataWidget.Parent = this.PostImportWidget;
                    this.AssignChannelWidget.Parent = [];
                    this.FileSelectionEditField.Value = this.FileNames.(es.Value);
                    this.DisplayedTableHeight = 162;
                case 'csv'
                    this.FileSelectionWidget.Parent = this.SourceWidget;
                    this.FileSelectionWidget.Layout.Row = 2;
                    this.FileSelectionWidget.Layout.Column = [1 3];
                    this.XLSFileWidget.Parent = [];
                    this.ASCIIFileWidget.Parent = [];
                    this.AssignChannelWidget.Parent = [];
                    this.MissingDataWidget.Parent = [];
                    this.FileSelectionEditField.Value = this.FileNames.(es.Value);
                    this.DisplayedTableHeight = 284;
                case 'ascii'
                    this.FileSelectionWidget.Parent = this.SourceWidget;
                    this.FileSelectionWidget.Layout.Row = 2;
                    this.FileSelectionWidget.Layout.Column = [1 3];
                    this.ASCIIFileWidget.Parent = this.FileSelectionWidget;
                    this.ASCIIFileWidget.Layout.Row = 2;
                    this.ASCIIFileWidget.Layout.Column = [2 3];
                    this.XLSFileWidget.Parent = [];
                    this.AssignChannelWidget.Parent = [];
                    this.MissingDataWidget.Parent = [];
                    this.FileSelectionEditField.Value = this.FileNames.(es.Value);
                    this.DisplayedTableHeight = 252;
            end
            this.SourceType = es.Value;
            refreshTable(this);
        end
        
        function cbFileSelectionButtonPushed(this,es,ed)
            oldfile = this.FileNames.(this.SourceType);
            switch this.SourceType
                case 'mat'
                    [filename,pathname] = uigetfile({'*.mat'});
                    if filename ~= 0
                        file = fullfile(pathname,filename);
                        setSource(this,file,'matfile');
                    else
                        return;
                    end
                case 'xls'
                    [filename,pathname] = uigetfile({'*.xls';'*.xlsx'});
                    if filename~=0
                        try
                            processXLSFile(this,fullfile(pathname,filename));
                        catch ex
                            uiconfirm(this.UIFigure,ex.message,...
                                getString(message('Controllib:gui:strExcelFileImport')),...
                                'Icon','error');
                            return;
                        end
                        file = fullfile(pathname,filename);
                    else
                        return;
                    end
                case 'csv'
                    [filename,pathname] = uigetfile({'*.csv'});
                    if filename~=0
                        file = fullfile(pathname,filename);
                    else
                        return;
                    end
                case 'ascii'
                    [filename,pathname] = uigetfile({'*.txt;*.tab;*.dlm;*.tab'});
                    if filename~=0
                        file = fullfile(pathname,filename);
                    else
                        return;
                    end
            end
            try
                this.FileNames.(this.SourceType) = file;
                refreshTable(this);
            catch ex
                this.FileNames.(this.SourceType) = oldfile;
                if strcmp(this.SourceType,'mat')
                    setSource(this,oldfile,'matfile');
                end
                uiconfirm(this.UIFigure,ex.message,...
                        m('Controllib:gui:strDataImport'),'Icon','error');
                return;
            end
            this.FileSelectionEditField.Value = file;
        end
        
        function cbFileSelectionEditFieldValueChanged(this,es,ed)
            oldfile = this.FileNames.(this.SourceType);
            file = es.Value;
            [pathname,~,ext] = fileparts(es.Value);
            if isempty(pathname) && ~isempty(file)
                file = fullfile(pwd,file);
            end
            switch this.SourceType
                case 'workspace'
                    
                case 'mat'
                    setSource(this,file,'matfile');
                case 'xls'
                    if isempty(ext)
                        file = [file '.xls'];
                    end
                    try
                        processXLSFile(this,file);
                    catch ex
                        uiconfirm(this.UIFigure,ex.message,...
                                getString(message('Controllib:gui:strExcelFileImport')),...
                                'Icon','error');
                        return;
                    end
                case 'csv'
                    
                case 'ascii'
                    
            end
            try
                this.FileNames.(this.SourceType) = file;
                refreshTable(this);
            catch ex
                this.FileNames.(this.SourceType) = oldfile;
                
                if strcmp(this.SourceType,'mat')
                    setSource(this,oldfile,'matfile');
                end
                uiconfirm(this.UIFigure,ex.message,...
                        m('Controllib:gui:strDataImport'),'Icon','error');
                es.Value = oldfile;
                return;
            end
        end
        
        function cbXLSFileSheetDropDownValueChanged(this,es,ed)
            try
                refreshTable(this);
            catch ex
                uiconfirm(this.UIFigure,ex.message,...
                        m('Controllib:gui:strDataImport'),'Icon','error');
                es.Value = ed.PreviousValue;
            end
        end
        
        function cbASCIIFileDelimiterDropDownValueChanged(this,es,ed)
            try
                refreshTable(this);
            catch ex
                uiconfirm(this.UIFigure,ex.message,...
                        m('Controllib:gui:strDataImport'),'Icon','error');
                es.Value = ed.PreviousValue;
            end
        end
        
        function cbSelectionChanged(this,es,ed)
            switch this.SourceType
                case {'workspace','mat'}
                    if ~isempty(ed.Data)
                        data = getSelectedData(this);
                        [nRows,nColumns] = size(data{2});
                        if nColumns > 1
                            this.AssignColumnEditField.Value = ['[1:',num2str(nColumns),']'];
                        else
                            this.AssignColumnEditField.Value = '1';
                        end
                        if nRows > 1
                            this.AssignRowEditField.Value = ['[1:',num2str(nRows),']'];
                        else
                            this.AssignRowEditField.Value = '1';
                        end
                    else
                        this.AssignColumnEditField.Value = '';
                        this.AssignRowEditField.Value = '';
                    end
            end
        end
        
        function processXLSFile(this,file)
            try
                fileerr = false;
                [status, sheetnames] = xlsfinfo(file);
            catch
                fileerr = true;
            end
            if fileerr || isempty(dir(file)) % should have the full path here
                ME = MException('lsimui:fileNotFound',...
                        getString(message('Controllib:gui:errFileNotFound')));
                throw(ME);
            end
            if ~isempty(status) && ~isempty(sheetnames)
                this.XLSFileSheetDropDown.Items = sheetnames;
            else
                ME = MException('lsimui:invalidWorkbook',...
                        getString(message('Controllib:gui:errInvalidWorkbook')));
                throw(ME);
            end
        end
        
        function outData = interpolateXLSData(this,headEnd,interpMethod,selectedCols)
            numdata = this.Data.xls;
            
            % find the start row for the numeric data
            numericStart = find(all(isnan(numdata)')'==false, 1);
            if isempty(numericStart) %no numeric data
                outData = [];
                return
            end
            
            % the specified header is smaller than the default used by xlsread
            if headEnd < numericStart
                if numericStart>1
                    uiconfirm(this.UIFigure,...
                        m('Controllib:gui:warnUsingMinValidHeaderSize',num2str(numericStart-1)), ...
                        m('Controllib:gui:strExcelFileImport'), ...
                        'Icon','warn')
                end
                thisData = numdata(numericStart:end,selectedCols);
            else
                thisData = numdata(headEnd:end,selectedCols);
            end
            outData = zeros(size(thisData));
            switch interpMethod
                case m('Controllib:gui:strSkipRows')
                    if min(size(thisData))>=2
                        goodRows = find(max(isnan(thisData)')'==0);
                    else
                        goodRows = find(isnan(thisData)==0);
                    end
                    outData = thisData(goodRows,:);
                case m('Controllib:gui:strSkipCells')
                    numericcells = ~isnan(thisData);
                    allowedLength = min(sum(numericcells));
                    if allowedLength>1
                        outData = zeros(allowedLength,size(thisData,2));
                        if allowedLength<max(sum(numericcells))
                            msg = m('Controllib:gui:warnDifferingLengths', allowedLength);
                            uiconfirm(this.UIFigure,msg,...
                                m('Controllib:gui:strExcelFileImport'), ...
                                'Icon','warn');
                        end
                    else
                        uiconfirm(this.UIFigure,...
                            m('Controllib:gui:errRequiresTwoValidRows'), ...
                            m('Controllib:gui:strExcelFileImport'), ...
                            'Icon','error');
                        return
                    end
                    % dimensions are shortest skipped column x all selected rows
                    for col=1:length(selectedCols)
                        I = find(numericcells(:,col));
                        outData(1:allowedLength,col) = thisData(I(1:allowedLength),col);
                    end
                case m('Controllib:gui:strLinearlyInterpolate')
                    for col=1:length(selectedCols)
                        I = isnan(thisData(:,col));
                        if I(1) == 1 || I(end) == 1
                            uiconfirm(this.UIFigure,...
                                m('Controllib:gui:errCannotExtrapolateNonNumeric'), ...
                                m('Controllib:gui:strExcelFileImport'),...
                                'Icon','error');
                            outData = [];
                            return
                        else
                            ind = find(I==0);
                            y = thisData(ind,col);
                            xraw = 1:size(thisData,1);
                            if length(xraw)>=2 && length(ind)>=2
                                outData(:,col) = interp1(ind,y,xraw,'linear')';
                            else
                                uiconfirm(this.UIFigure,...
                                    m('Controllib:gui:errInterpolateRequiresTwoPoints'), ...
                                    m('Controllib:gui:strExcelFileImport'), ...
                                    'Icon','error');
                                outData = [];
                            end
                        end
                    end
                case m('Controllib:gui:strZeroOrderHold')
                    for col=1:length(selectedCols)
                        I = isnan(thisData(:,col));
                        if I(1) == 1
                            uiconfirm(this.UIFigure,...
                                m('Controllib:gui:errCannotStartNonNumeric'),...
                                m('Controllib:gui:strExcelFileImport'), ...
                                'Icon','error');
                            return
                        else
                            temp = thisData(~I,col);
                            outData(:,col) = temp(cumsum(~I));
                        end
                    end
            end
            
            if isempty(outData) || min(size(outData))<1
                uiconfirm(this.UIFigure,...
                    m('Controllib:gui:errNoNumericDataAbortCopy'), ...
                    m('Controllib:gui:strExcelFileImport'), ...
                    'Icon','error')
                outData = [];
                return
            end
        end 
    end
end

function str = m(id,varargin)
str = getString(message(id,varargin{:}));
end
