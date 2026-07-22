classdef ImportDialog < controllib.ui.internal.dialog.AbstractImportDialog
    % Class for the dialog to import systems into a Linear System Analyzer

    % Copyright 2024 The MathWorks, Inc.

    properties (Access=protected)
        App
        WorkspaceLabel
        WorkspaceDropDown
        FileNameEditField
        BrowseBtn
    end

    methods
        function this = ImportDialog(app)
            this = this@controllib.ui.internal.dialog.AbstractImportDialog();
            this.Name = 'LinearSystemAnalyzerImportDialog';
            this.Title = getString(message('Control:viewer:strImportSystemData'));
            this.App = app;
            this.AllowMultipleRowSelection = true;
            this.AllowColumnSorting = true;
            this.AddTagsToWidgets = true;
            this.TableTitle = getString(message('Control:viewer:strSystemsInWorkspace'));
            this.DialogSize = [500 270];
        end
    end
    methods (Access=protected)
        function buildCustomWidgets(this)
            % Create additional "Import from MAT file" option
            workspaceGrid = uigridlayout(this.UIFigure,[1 5]);
            workspaceGrid.ColumnWidth = {'fit','fit','fit','fit','1x'};
            this.WorkspaceLabel = uilabel(workspaceGrid);
            this.WorkspaceLabel.Layout.Column = 1;
            this.WorkspaceLabel.Text = getString(message('Control:viewer:lblImportFrom'));
            this.WorkspaceDropDown = uidropdown(workspaceGrid);
            this.WorkspaceDropDown.Layout.Column = 2;
            this.WorkspaceDropDown.Items = {getString(message('Control:viewer:strWorkspace')),...
                getString(message('Control:viewer:strMATFile'))};
            this.WorkspaceDropDown.ValueChangedFcn = @(es,ed) cbWorkspaceDropDownChanged(this,ed.Value);
            this.FileNameEditField = uieditfield(workspaceGrid);
            this.FileNameEditField.Layout.Column = 3;
            this.FileNameEditField.Enable = false;
            this.FileNameEditField.ValueChangedFcn = @(es,ed) cbFileNameEditFieldChanged(this,ed.Value);
            this.BrowseBtn = uibutton(workspaceGrid);
            this.BrowseBtn.Layout.Column = 4;
            this.BrowseBtn.Enable = false;
            this.BrowseBtn.Text = getString(message('Control:viewer:strBrowse'));
            this.BrowseBtn.ButtonPushedFcn = @(es,ed) cbBrowseBtnPushed(this);
            addWidget(this,workspaceGrid,'abovetable');
        end
        function tableData = getTableData(this)
            % Return the table to be displayed by AbstractImportDialog
            % Name,Size,Type
            variableNames = {getString(message( ...
                'Control:viewer:strModel')),...
                             getString(message( ...
                             'Control:viewer:strSize')),...
                             getString(message( ...
                             'Control:viewer:strClass'))};
            filteredData = getFilteredData(this);
            if ~isempty(filteredData)
                systemSize = strings(size(filteredData,1),1);
                systemType = strings(size(filteredData,1),1);
                for ii = 1:size(filteredData,1)
                    [size_str,VarClass] = localCreateStr(filteredData{ii,2});
                    systemType(ii) = VarClass;
                    systemSize(ii) = size_str;
                end
                tableData = table(filteredData(:,1),...
                    systemSize,systemType,...
                    'VariableNames',variableNames);
            else
                tableData = table([],[],[], ...
                    'VariableNames',variableNames);
            end

            function [size_str,VarClass] = localCreateStr(system)
                VarClass=class(system);
                wsize = size(system);
                if isequal(length(wsize),2)
                    s = mat2str(wsize);
                    s = strrep(s,' ','x');
                    size_str = s(2:end-1);
                else
                    size_str = [num2str(length(wsize)),'-D'];
                end
            end
        end
        function callbackActionButton(this)
            % Get selected data from AbstractImportDialog helper method
            selectedData = getSelectedData(this);
            % Error dialog if selection is empty
            if isempty(selectedData)
                uialert(this.UIFigure, getString(message('Control:viewer:errNoSystemsSelectedToImport')), ...
                        getString(message('Control:viewer:strLTIViewerImport')));
                return;
            end
            models = selectedData(:,2);
            for ii = 1:length(models)
                models{ii}.Name = selectedData{ii,1};
            end
            % Check for overwritten systems
            if isempty(this.App.Systems)
                names = string.empty;
            else
                names = cellfun(@(x) string(x.Model.Name),this.App.Systems);
            end
            [RefreshSysNames,~,ib] = intersect(names,string(selectedData(:,1)));
            if ~isempty(RefreshSysNames)
                overwrite = uiconfirm(this.UIFigure,getString(message('Control:viewer:msgImportOverwrite')),...
                    getString(message('Control:viewer:strOverwriteSystems')),'Options',{'Yes','No','Cancel'});
                switch overwrite
                    case 'Cancel'
                        return
                    case 'No'
                        models(ib) = [];
                end
            end
            hide(this);
            importSystems(this.App,models);
            % Display imported models in app status bar
            postStatus(this.App,getString(message('Control:viewer:msgImportCompleted',length(models))));
        end
        function callbackHelpButton(this) %#ok<MANU>
            helpview('control','viewer_import');
        end
    end
    methods(Access = private)
        function filteredData = getFilteredData(this)
            data = getData(this);
            if isempty(data)
                filteredData = data;
            else
                valid = false(size(data,1),1);
                for ii = 1:size(data,1)
                    var = data{ii,2};
                    if isa(var,'DynamicSystem') && ~isa(var,'lpvss') % cannot load parameter data
                        valid(ii) = true;
                    end
                end
                filteredData = data(valid,:);
            end
        end
        function cbWorkspaceDropDownChanged(this,value)
            widgets = qeGetContainerWidgets(this);
            TableTitle = widgets.UITableTitle;
            switch value
                case getString(message('Control:viewer:strWorkspace'))
                    this.FileNameEditField.Enable = false;
                    this.BrowseBtn.Enable = false;
                    TableTitle.Text = getString(message('Control:viewer:strSystemsInWorkspace'));
                    setSource(this,'base','workspace');
                case getString(message('Control:viewer:strMATFile'))
                    this.FileNameEditField.Enable = true;
                    this.BrowseBtn.Enable = true;
                    TableTitle.Text = getString(message('Control:viewer:lblSystemsInFile'));
                    setSource(this,this.FileNameEditField.Value,'matfile');
            end
            try
                updateTable(this);
            catch ME
                this.FileNameEditField.Value = '';
                setSource(this,'','matfile');
                uialert(this.UIFigure,ME.message,...
                    getString(message('Control:viewer:strImportWarning')),'Icon','Warning')
            end
        end
        function cbFileNameEditFieldChanged(this,value)
            setSource(this,value,'matfile');
            try
                updateTable(this);
            catch ME
                this.FileNameEditField.Value = '';
                setSource(this,'','matfile');
                uialert(this.UIFigure,ME.message,...
                    getString(message('Control:viewer:strImportWarning')),'Icon','Warning')
            end
        end
        function cbBrowseBtnPushed(this)
            [file,path] = uigetfile('*.mat',getString(message('Control:viewer:lblImportFile')));
            if file
                file = fullfile(path,file);
                this.FileNameEditField.Value = file;
                cbFileNameEditFieldChanged(this,file);
            end
        end
    end
    methods(Hidden)
        function customWidgets = qeGetCustomWidgets(this)
            % Method "qeGetCustomWidgets":
            %   Overload this method to return a struct of custom widgets.
            customWidgets.WorkspaceLabel = this.WorkspaceLabel;
            customWidgets.WorkspaceDropDown = this.WorkspaceDropDown;
            customWidgets.FileNameEditField = this.FileNameEditField;
            customWidgets.BrowseBtn = this.BrowseBtn;
        end
    end
end