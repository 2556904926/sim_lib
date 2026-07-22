classdef ImportTime < controllib.ui.internal.dialog.AbstractImportDialog
    % Import Time Dialog for Linear Simulation Tool
    
    % Copyright 2020-2022 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = private)
        TimeVector
        TimeParametersWidget
    end
    
    events
        TimeVectorCreated
    end
    
    methods
        function this = ImportTime(timeParametersWidget)
            this = this@controllib.ui.internal.dialog.AbstractImportDialog();
            this.AllowMultipleRowSelection = false;
            this.AllowColumnSorting = true;
            this.ShowHelpButton = false;
            this.AddTagsToWidgets = true;
            this.Name = 'ImportTimeDialog'; 
            this.Title = getString(message('Controllib:gui:strImportTime'));
            this.TableTitle = getString(message('Controllib:gui:lblImportTimeFromWorkspace'));
            this.DialogSize = [460 200];
            this.TimeParametersWidget = timeParametersWidget;
        end
    end
    
    methods(Access = protected)
        function tableData = getTableData(this)
            tableData = lsimgui.utils.internal.createImportTableData(getFilteredData(this));
        end
        
        function callbackActionButton(this)
            % Get selected data from AbstractImportDialog helper method
            selectedData = getSelectedData(this);
            % Error dialog if selection is empty
            if isempty(selectedData)
                uiconfirm(getWidget(this),...
                    getString(message('Controllib:gui:errSelectVariableToImport')),...
                    getString(message('Controllib:gui:strLinearSimulationTool')),...
                    'Icon','error');
                return;
            else
                this.TimeVector = selectedData{2};
                updateTimeVector(this.TimeParametersWidget,this.TimeVector);
                notify(this,'TimeVectorCreated');
                close(this);
            end
        end
        
        function callbackHelpButton(this) %#ok<*MANU>
            
        end
    end
    
    methods(Hidden)
        function widgets = qeGetCustomWidgets(this)
            widgets.DialogName = this.Name;
            widgets.DialogTitle = this.Title;
            widgets.DialogTableTitle = this.TableTitle;
        end
    end
    
    methods(Access = private)
        function filteredData = getFilteredData(this)
            data = getData(this);
            if isempty(data)
                filteredData = data;
            else
                isValidType = cellfun(@(x) isnumeric(x) && isvector(x) && length(x)>2 && ...
                                            issorted(x),data(:,2));
                filteredData = data(isValidType,:);
            end
        end
    end
end
