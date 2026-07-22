classdef (Hidden) ExportModelDialog < controllib.ui.internal.dialog.AbstractExportDialog
    % Export model dialog for Model Reducer

    % Author(s): A. Ouellette
    % Copyright 2015-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = private)
        TableData
    end

    properties (SetAccess = private, WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
    end
    
    %% Constructor
    methods      
        function this = ExportModelDialog(app)
            arguments
                app (1,1) mrtool.internal.ModelReducerApp
            end
            Name = 'ExportModelDialog';
            Title = getString(message('Control:mrtool:TitleExportModelDialog'));
            this = this@controllib.ui.internal.dialog.AbstractExportDialog(Name,Title);
            this.App = app;
            this.AllowColumnSorting = true;
            this.AddTagsToWidgets = true;
            this.TableTitle  = getString(message('Control:mrtool:ExportModelTableLabel'));
            this.DialogSize = [410 270];
        end
    end  

    %% Protected methods
    methods(Access = protected)                            
        % Get Table Data
        function TableData = getTableData(this)
            % set table size
            TableLength = length(this.App.Models);
            TableWidth = 1;
            TableData = cell(TableLength,TableWidth);
            %SelectedModels = getSelectedModelinDataBrowser(this.AppData);
            % set table data
            for ct = 1:length(this.App.Models)
                % variable column
                TableData{ct,1} = this.App.Models(ct).Name;
            end
            TableData = cell2table(TableData,'VariableNames',...
                            {getString(message('Control:mrtool:ModelsExportModelDialog'))});
            this.TableData = TableData;
        end
        
        function postUpdateUI(this)
            selectedModels = this.App.SelectedModel;
            if ~isempty(selectedModels)
                selectVariables(this,cellstr([selectedModels.Name]));
            end
        end
        
        function val = getValueAt(this,array)
            val = this.App.Models(array).System;
        end
        
        function callbackHelpButton(this) %#ok<*MANU>
            helpview('control','ModelReducerExport','CSHelpWindow');            
        end                
    end 

    %% Hidden methods
    methods (Hidden)
        function Widgets = getWidgets(this)
            Widgets = qeGetWidgets(this);
            Widgets.ColumnNames = this.TableData.Properties.VariableNames;
            Widgets.TableData = this.TableData;
            Widgets.DialogName = this.Name;
            Widgets.DialogTitle = this.Title;
            Widgets.DialogTableTitle = this.TableTitle;
        end     
        
        function qeCallbackHelpButton(this)
            callbackHelpButton(this);            
        end        
    end
end
