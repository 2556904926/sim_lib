classdef (Hidden) MLExport < controllib.ui.internal.dialog.AbstractExportDialog
    % Export model dialog for Control System Tuner

    % Copyright 2015-2021 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = private)
        AppData        
    end
    
    %% Public methods
    methods(Access = public)        
        %% constructor
        function this = MLExport(AppData)
            Name = 'DialogExportToML';
            Title = getString(message('Control:systunegui:MLExportDialogTitle'));
            this = this@controllib.ui.internal.dialog.AbstractExportDialog(Name,Title);
            this.AppData = AppData;
            
            %Abstract Dialog Properties
            this.AllowMultipleRowSelection = true;
            this.TableTitle = getString(message('Control:systunegui:MLExportTableLabel'));
            this.DialogSize = [360 200];
            this.DisplayedTableHeight = 60; % height of displayed table
            this.DisplayedTableWidth = 280;  % width of displayed table        
            
        end                 
    end   
    
    %% Implementation of protected abstract or overloaded methods
    methods(Access = protected)                            
        % Get Table Data
        function TableData = getTableData(this)
            % Get the compensators
            Compensators = this.AppData.getArchitecture.getTunableBlocks;
            Nsys = numel(Compensators); % number of compensators
            
            % set table data
            if Nsys > 0
                VarNames = cell(Nsys,1);
                for ct = 1: Nsys
                    sys = Compensators(ct).getParameterization;
                    VarNames{ct,1} = sys.Name;
                end
            else
                VarNames = [];
            end 
            
            if isa(this.AppData.getArchitecture,'systuneapp.data.MatlabConfigData.ConfigGenSS')
                % add table data
                myGenss = this.AppData.getArchitecture.System;
                myGenss.Name = 'myGenss';
                % genss
                VarNames{Nsys+1,1} = myGenss.Name;
            end
            
            TableData = table(VarNames,...
                    'VariableNames',...
                    {getString(message('Control:systunegui:MLExportModels'))});

        end
        
        function val = getValueAt(this,array)
            Models = this.AppData.getArchitecture.getTunableBlocks;
            if isa(this.AppData.getArchitecture,'systuneapp.data.MatlabConfigData.ConfigGenSS') && isequal(array,numel(Models)+1)
                val = this.AppData.getArchitecture.System;
            else
                val = getValue(Models(array));
            end
        end
        
        function callbackHelpButton(~)
            helpview('control','SystuneGUIExport','CSHelpWindow');
        end                
    end 
    
    %% Hidden methods
    methods (Hidden)
        function Widgets = qeGetWidgets(this)
            Widgets.ColumnNames = this.VariableColumnName;
            Widgets.TableData = this.getTableData;
            Widgets.DialogName = this.Name;
            Widgets.DialogTitle = this.Title;
            Widgets.DialogTableTitle = this.TableTitle; % REVISIT
        end        
    end
end
