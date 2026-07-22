classdef ImportDialog < controllib.ui.internal.dialog.AbstractImportDialog
    % ImportDialog - Imports a selected system component as a part of Edit
    % Architecture dialog in Control System Designer App.
    
    %  Copyright 2020 The MathWorks, Inc.
    
    properties(SetAccess=private,GetAccess=public)
        % Name of block being tuned
        BlockName   
        
        % Architecture that contains the block
        Data        
    end
    
    properties(SetAccess=private,GetAccess=?matlab.unittest.TestCase)        
        % Custom widget components
        Widgets = struct(...
            'CustomWidgetLayout',[], ...
            'RadioButtonGroup',[], ...
            'BaseWSRadioButton',[], ...
            'MATFileRadioButton',[], ...
            'BrowserLayout',[], ...
            'MATFileBrowserButton',[], ...
            'MATFileEditField',[] ...
            );
        
        % Last browsed path.
        LastPath = '';
    end
    
    %% Constructor
    methods
        function dlg = ImportDialog(data, blockName)
            dlg.Data = data;
            dlg.BlockName = blockName;
            dlg.Title = getString(message('Control:designerapp:ImportDlgTitle', blockName));
            dlg.AllowMultipleRowSelection = false;
            dlg.ShowRefreshButton = false;
            dlg.DialogSize = [480 230];
        end
        
        function show(this,varargin)
            show@controllib.ui.internal.dialog.AbstractImportDialog(this,varargin{:});
        end
    end
    
    %% Events
    events
        % Event "ImportCompleted"
        %
        % The dialog sends this event after the execution of the
        % Export button callback, "callbackActionButton()"
        ImportCompleted
    end
    
    %% Protected methods.
    methods(Access=protected)
        function buildCustomWidgets(dlg)
            % Build a radio button group to switch between workspace and
            % MAT file sources.
                        
            % Add layout for the custom widget.
            layout = uigridlayout('Parent',[]);
            layout.RowHeight = {75};
            layout.ColumnWidth = {200,'1x'};
            layout.Padding = [0 0 0 0];
            
            dlg.Widgets.CustomWidgetLayout = layout;
            
            % Create radio button group.
            rbGroup = uibuttongroup(dlg.Widgets.CustomWidgetLayout);
            rbGroup.Title = getString(message('Control:designerapp:strImportFrom'));
            rbGroup.Layout.Row = 1;
            rbGroup.Layout.Column = 1;
            rbGroup.BorderType = 'none';
            rbGroup.SelectionChangedFcn =  ...
                @(source,event) cbSelectionChanged(dlg,event);
            
            % Add button for base worspace.
            baseWSRadioButton = uiradiobutton(rbGroup);
            baseWSRadioButton.Position(2) = 25;
            baseWSRadioButton.Position(3) = 125;
            baseWSRadioButton.Text = getString(message('Control:designerapp:strWorkspace'));
            baseWSRadioButton.Value = true;
            baseWSRadioButton.Tag = 'BaseWS';
            % Add button for MAT file.
            matFileRadioButton = uiradiobutton(rbGroup);
            matFileRadioButton.Position(2) = baseWSRadioButton.Position(2) - 25;
            matFileRadioButton.Text = getString(message('Control:designerapp:strMATFile'));
            matFileRadioButton.Value = false;
            matFileRadioButton.Tag = 'MATFile';
            
            dlg.Widgets.RadioButtonGroup = rbGroup;
            dlg.Widgets.BaseWSRadioButton = baseWSRadioButton;
            dlg.Widgets.MATFileRadioButton = matFileRadioButton;
            
            % Create layout for MAT file browser UI.
            browserLayout = uigridlayout(dlg.Widgets.CustomWidgetLayout,[1 2]);
            browserLayout.Layout.Row = 1;
            browserLayout.Layout.Column = 2;
            browserLayout.RowHeight = {'1x','1x','1x'};
            browserLayout.ColumnWidth = {'1x','fit'};
            browserLayout.Padding = [0 0 0 0];
            browserLayout.RowSpacing = 0;
            matFileEditField = uieditfield(browserLayout);
            matFileEditField.Layout.Row = 3;
            matFileEditField.Layout.Column = 1;
            matFileEditField.Enable = false;
            matFileEditField.ValueChangedFcn = ...
                @(source,event) cbMATFileEditFieldChanged(dlg,source);
            matFileBrowserButton = uibutton(browserLayout);
            matFileBrowserButton.Layout.Row = 3;
            matFileBrowserButton.Layout.Column = 2;
            matFileBrowserButton.Text = ...
                getString(message('Control:designerapp:strBrowseLabel'));
            matFileBrowserButton.Enable = false;
            matFileBrowserButton.ButtonPushedFcn = ...
                @(source,event) cbMATFileBrowserButtonClicked(dlg);
            
            dlg.Widgets.BrowserLayout = browserLayout;
            dlg.Widgets.MATFileEditField = matFileEditField;
            dlg.Widgets.MATFileBrowserButton = matFileBrowserButton;
            

            addWidget(dlg,dlg.Widgets.CustomWidgetLayout,'abovetable')
        end
        
        function cleanupCustomWidgets(dlg)
            % Cleanup custom widget components.
            
            % Delete the parent of the custom widget. This automatically
            % deletes the children.
            if ~isempty(dlg.Widgets.CustomWidgetLayout) && ...
                    isvalid(dlg.Widgets.CustomWidgetLayout)
                delete(dlg.Widgets.CustomWidgetLayout)
            end
            
            % Set references to the custom widget components to empty
            % (NULL).
            uiCompNames = fieldnames(dlg.Widgets);
            for i = 1:length(uiCompNames)
                dlg.Widgets.(uiCompNames{i}) = [];
            end
        end
        
        function tableData = getTableData(dlg)
            % Return table data to be displayed.
            
            % Create a default table with column headers.
            tableData = table({},{},{},'VariableNames',{...
                    getString(message('Control:designerapp:strAvailableModels')),...
                    getString(message('Control:designerapp:strType')),...
                    getString(message('Control:designerapp:strOrder'))...
                    });
                
            % Filter data according to supported system types.    
            filteredData = getFilteredData(dlg);
            
            % Create table data from the filtered data.
            if ~isempty(filteredData)
                dataModels = filteredData(:,2);
                numModels = numel(dataModels);                
                strType = cell(numModels,1);
                strOrder = cell(numModels,1);                
                for i = 1:numModels
                    sys = dataModels{i};
                    sysClass = class(sys);
                    sysOrder = size(sys,'order');
                    if nmodels(sys)>1
                        strModelArray = getString(message('Controllib:gui:strModelArray'));
                        strTo = getString(message('Controllib:gui:strTo'));
                        strType{i} = [sysClass,' (',strModelArray,')'];
                        
                        if length(sysOrder) > 1
                            strOrder{i} = [num2str(min(sysOrder)),' ',...
                                strTo,' ',num2str(max(sysOrder))];
                        else
                            strOrder{i} = num2str(sysOrder);
                        end
                    else
                        strType{i} = sysClass;
                        strOrder{i} = num2str(sysOrder);
                    end
                    if any(strcmp(sysClass, {'idpoly','idss','idarx'}))
                        strOrder{i} = '';
                    end
                end
                
                % Create the table.                
                tableData = table(filteredData(:,1),strType,strOrder, ...
                    'VariableNames',{...
                    getString(message('Control:designerapp:strAvailableModels')),...
                    getString(message('Control:designerapp:strType')),...
                    getString(message('Control:designerapp:strOrder'))...
                    });
            end
            
        end
        
        function callbackActionButton(dlg)
            % Update data with the imported value.
            
            try
                % Get the imported data.
                selectedData = getSelectedData(dlg);
                
                % Update the specified block with the imported data.
                if ~isempty(selectedData)                    
                    setBlockValue(dlg.Data,dlg.BlockName,selectedData{2})
                end
                notify(dlg,'ImportCompleted');
                
                % Hide the view.
                close(dlg)
            catch me
                % Show error dialog in case of an unexpected error.
                
                uialert(dlg.UIFigure,me.message,dlg.Title);
            end
            
        end
        
        function callbackHelpButton(~)
            % Load help for the import dialog.
            
            ctrlguihelp('CSD_ImportDialogHelp','CSHelpWindow')
        end
    end
    
    %% Private methods.
    methods(Access=private)        
        function filteredData = getFilteredData(dlg)
            % Filter data according to the supported system types.
            
            % First, get available systems from the selected source.
            data = getData(dlg);
            
            % Next, filter the data if it is nonempty.
            if isempty(data)
                filteredData = [];
                return
            end
            filteredData = data(isValidSystem(data(:,2)),:);
        end
    end

    %% Private callback methods.
    methods(Access=private)
        function cbSelectionChanged(dlg,event)
            % Update view according to the selected source type.
            
            if isequal(event.NewValue.Text,getString(message('Control:designerapp:strMATFile')))
                % Enable file browser UI when MAT file is selected.
                dlg.Widgets.MATFileEditField.Enable = true;
                dlg.Widgets.MATFileBrowserButton.Enable = true;
                
                % Update the source using the current file content. The
                % last browsed path is used as the location of the file.
                file = fullfile(dlg.LastPath,dlg.Widgets.MATFileEditField.Value);
                setSource(dlg,file,'matfile')
            else
                % Disable file browser UI when workspace is selected.
                dlg.Widgets.MATFileEditField.Enable = false;
                dlg.Widgets.MATFileBrowserButton.Enable = false;

                % Use base workspace as the source.
                setSource(dlg,'base','workspace')
            end
            
            % Update the view according to the selected source.
            updateUI(dlg)
        end
        
        function cbMATFileEditFieldChanged(dlg,source)
            % Get the current filename and update the view with the
            % contents of the file.
              
            file = fullfile(dlg.LastPath,source.Value);
            preDataSource = getSource(dlg);
            setSource(dlg,file,'matfile')
            
            try
                updateUI(dlg)
            catch me
                uialert(dlg.UIFigure,me.message,dlg.Title);
                setSource(dlg,preDataSource,'matfile');
                source.Value = preDataSource;
            end
            
        end
        
        function cbMATFileBrowserButtonClicked(dlg)
            % Open file browser, load the selected file, and update the
            % view.
            
            % CD to the directory browsed last time.
            currentPath = pwd;
            if ~isempty(dlg.LastPath)
                cd(dlg.LastPath)
            end
            
            % Open file browser.
            [fileName, filePath] = uigetfile('*.mat', ...
                getString(message('Controllib:gui:strImportFile')));
            
            % Restore the starting directory.
            if ~isempty(dlg.LastPath)
                cd(currentPath)
            end
            
            % Update view (edit field and table contents).
            if ~isequal(fileName,0)
                % Update file name in the edit field.
                dlg.Widgets.MATFileEditField.Value = fileName;
                
                % Store the last path name.
                dlg.LastPath = filePath;
                
                % Update available systems.
                setSource(dlg,fullfile(filePath,fileName),'matfile')
                updateUI(dlg)
            end
        end
    end
    
    %% Hidden QE methods
    methods (Hidden)
        function widgets = qeGetCustomWidgets(dlg)
            widgets = dlg.Widgets;
        end
    end

end
%% Local functions
function yes = isValidSystem(vars)
% Checks if given variable should be included in the import browser.

numVars = length(vars);
yes = false(numVars,1);
for ct=1:numVars
    varValue = vars{ct};
    yes(ct) = isValidType(varValue) && isValidSize(varValue);
end

end

function yes = isValidType(var)
% Check for valid type.
if any(strcmp(class(var),{'tf','ss','zpk','frd','idpoly','idss','idarx'}))
    yes = true;
else
    yes = false;
end

end

function yes = isValidSize(var)
% Check for valid size.

if any(strcmp(class(var),{'tf','ss','zpk','frd'}))
    sz = size(var);
    if isequal(length(sz),2)
        yes = isequal(sz,[1 1]);
    elseif isequal(length(sz),4)
        yes = any(sz(3:4)==1);
    else
        yes = false;
    end
elseif any(strcmp(class(var),{'idpoly','idss','idarx'}))
    sz = size(var);
    yes = isequal(sz([1 2]),[1 1]);
else
    yes = false;
end
end