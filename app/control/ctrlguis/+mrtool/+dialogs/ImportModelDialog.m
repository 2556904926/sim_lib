classdef ImportModelDialog < controllib.ui.internal.dialog.AbstractImportDialog
    %   Import Model Dialog for the Model Reducer App
    
    % Author(s): A. Ouellette
    %   Copyright 2015-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = private)
        VEDialogs
    end
    
    properties (SetAccess = private, WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
    end

    %% Constructor
    methods
        function this = ImportModelDialog(app)
            arguments
                app (1,1) mrtool.internal.ModelReducerApp
            end
            this = this@controllib.ui.internal.dialog.AbstractImportDialog;
            this.App = app;
            this.AllowMultipleRowSelection = true;
            this.AllowColumnSorting = true;
            this.AddTagsToWidgets = true;
            this.Name = 'ImportModelDialog';
            this.Title = getString(message('Control:mrtool:TitleImportModelDialog'));
            this.TableTitle = getString(message('Control:mrtool:ImportModelTableLabel'));
            this.DialogSize = [500 270];
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function tableData = getTableData(this)
            % Return the table to be displayed by AbstractImportDialog
            % Name,Type,Order,NumInputs,NumOutputs
            variableNames = {getString(message( ...
                'Control:mrtool:ImportDialogModels')),...
                             getString(message( ...
                             'Control:mrtool:Type')),...
                             getString(message( ...
                             'Control:mrtool:ImportDialogOrder')),...
                             getString(message( ...
                             'Control:mrtool:ImportDialogInputs')),...
                             getString(message( ...
                             'Control:mrtool:ImportDialogOutputs'))};
            filteredData = getFilteredData(this);
            if ~isempty(filteredData)
                systemType = cellfun(@(x) class(x), ...
                    filteredData(:,2), 'UniformOutput',false);
                systemOrder = cellfun(@(x) order(x), filteredData(:,2));
                numInputs = cellfun(@(x) size(x,2), filteredData(:,2));
                numOutputs = cellfun(@(x) size(x,1), filteredData(:,2));
                tableData = table(filteredData(:,1),...
                    systemType,systemOrder,numInputs,numOutputs,...
                    'VariableNames',variableNames);
            else
                tableData = table([],[],[],[],[], ...
                    'VariableNames',variableNames);
            end
        end
        
        function callbackActionButton(this)
            % Get selected data from AbstractImportDialog helper method
            selectedData = getSelectedData(this);
            % Error dialog if selection is empty
            if isempty(selectedData)
                uialert(this.UIFigure, getString(message( ...
                        'Control:mrtool:ErrorNoImportModelSelected')), ...
                        getString(message('Control:mrtool:toolName')));
                return;
            end
            % Create ModelWrapper, hide dialog and import models
            sys = mrtool.util.createModelWrapper(selectedData(:,2),selectedData(:,1));
            hide(this);
            importModels(this.App, sys);
            % Display imported models in app status bar
            Sentence = mrtool.util.createModelNameSentence({sys.Name});
            if ~isscalar(sys)
                msg = getString(message( ...
                    'Control:mrtool:StatusMessageImportModels',Sentence));
            else
                msg = getString(message( ...
                    'Control:mrtool:StatusMessageImportModel',Sentence));
            end
            postActionStatus(this.App.EventManager,'off',msg);
        end
        
        function callbackHelpButton(this) %#ok<*MANU>
           helpview('control','ModelReducerImport','CSHelpWindow');
        end
    end    
    
    %% Private methods
    methods(Access = private)
        function filteredData = getFilteredData(this)
            data = getData(this);
            if isempty(data)
                filteredData = data;
            else
                [isValidType,~] = mrtool.util.isValidSystem(data(:,2));
                filteredData = data(isValidType,:);
            end
        end
    end

    %% Hidden methods
    methods(Hidden)
        function widgets = getWidgets(this)
            widgets = qeGetWidgets(this);
            widgets.DialogName = this.Name;
            widgets.DialogTitle = this.Title;
            widgets.DialogTableTitle = this.TableTitle;
            widgets.VEDialogs = this.VEDialogs;
        end
    end
end
