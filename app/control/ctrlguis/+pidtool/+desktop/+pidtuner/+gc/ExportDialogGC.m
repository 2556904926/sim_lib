classdef ExportDialogGC < controllib.ui.internal.dialog.AbstractExportDialog
    %EXPORTDIALOGGC
    
    % Author(s): Baljeet Singh 18-Nov-2013
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TC
        ControllerNameTextField
        ControllerCheckbox
    end
    properties(Access = private)
        Listeners
    end
    methods
        function this = ExportDialogGC(tc)
            %EXPORTDIALOGGC
            Name = 'PIDTUNER_EXPORTDLG';
            Title = pidtool.utPIDgetStrings('cst', 'exportdlg_title');
            this = this@controllib.ui.internal.dialog.AbstractExportDialog(Name,Title);
            this.TC = tc;
            
            %Abstract Dialog Properties
            this.AllowMultipleRowSelection = true;
            this.TableTitle = pidtool.utPIDgetStrings('cst','exportdlg_label1');
            this.DialogSize = [440 300];
        end
    end
    methods(Access=protected)
         function buildCustomWidgets(this)
            % Number of Unstable Poles
            aboveTableGrid = uigridlayout('Parent',[]);
            aboveTableGrid.RowHeight = {22};
            aboveTableGrid.ColumnWidth = {'fit','1x'};
            aboveTableGrid.RowSpacing = 0;

            this.ControllerCheckbox = uicheckbox(aboveTableGrid,'Text',pidtool.utPIDgetStrings('cst','exportdlg_label2'));
            this.ControllerCheckbox.Layout.Row = 1;
            this.ControllerCheckbox.Layout.Column = 1;
            this.ControllerCheckbox.Tag = 'EXPORTPLANTDLG_CONTROLLERCHECKBOX';
            this.ControllerCheckbox.ValueChangedFcn = @(~,evt) cbCheckBoxSelected(this,evt);
            this.ControllerCheckbox.Value = true;
            this.ControllerNameTextField = uieditfield(aboveTableGrid,'Value','C');
            this.ControllerNameTextField.Tag = 'EXPORTPLANTDLG_CONTROLLERNAMETEXTFIELD';
            this.ControllerNameTextField.Layout.Row = 1;
            this.ControllerNameTextField.Layout.Column = 2;
            this.addWidget(aboveTableGrid,'abovetable','fit')
         end
         
         function tableData = getTableData(this)
            % Return the table to be displayed by AbstractExportDialog
            % Available Data,Type,Order
            
            VarNames = this.TC.PlantList.PlantNames;
            VarData = this.TC.PlantList.Plants;
            
            if ~isempty(VarNames)
                systemType = cellfun(@(x) class(x), VarData, 'UniformOutput',false);
                systemOrder = cellfun(@(x) size(x,'order'), VarData);
                tableData = table(VarNames,...
                    systemType,systemOrder,...
                    'VariableNames',...
                    {pidtool.utPIDgetStrings('cst','strPlantName'),...
                    pidtool.utPIDgetStrings('cst','importdlg_colname2'),...
                    pidtool.utPIDgetStrings('cst','importdlg_colname3')});
            else
                tableData = table([],[],[],...
                    'VariableNames',...
                    {pidtool.utPIDgetStrings('cst','strPlantName'),...
                    pidtool.utPIDgetStrings('cst','importdlg_colname2'),...
                    pidtool.utPIDgetStrings('cst','importdlg_colname3')});
            end
         end
         
        function val = getValueAt(this,idx)
            val = this.TC.PlantList.Plants{idx};
        end
        
        function callbackActionButton(this)
           % Method "callbackActionButton":
            try
                % Export Controller
                if this.ControllerCheckbox.Value
                    checkC = localExportController(this);
                    cExported = true;
                else
                    checkC = true;
                    cExported = false;
                end
                idx = getSelectedIdx(this);
                
                % Error if nothing selected
                if isempty(idx) && ~cExported
                    ErrorMessage = getString(message('MATLAB:uistring:export2wsdlg:YouMustCheckABoxToExportVariables'));
                    uialert(this.UIFigure,ErrorMessage,'');
                    return
                end

                % Get variable names
                variableNames = getExportVariableNames(this,idx);
                variableValues = arrayfun(@(k) getValueAt(this,k),idx,'UniformOutput',false);
                isExportDone = export(this,variableValues,variableNames);
                if isExportDone && checkC
                    close(this);
                else
                    return;
                end
            catch Ex
                ErrorMessage = Ex.message;
                uialert(this.UIFigure,ErrorMessage,this.Title);
            end 
        end

        function callbackHelpButton(this) %#ok<*MANU>
            %CBHELPBUTTON
            helpview('control','pidtool_exportdlg','CSHelpWindow');
        end
        
    end
end
function cbCheckBoxSelected(this,evt)
    %LOCALCHECKBOXSELECTED
    if evt.Value
        this.ControllerNameTextField.Enable = true;
    else
        this.ControllerNameTextField.Enable = false;
    end
end

function exportSuccessful = localExportController(this)
    %LOCALEXPORTCONTROLLER
    exportSuccessful = false;
    controllerName = this.ControllerNameTextField.Value;
    tunedC = this.TC.ControllerList.TunedController;
    try
        % NOTE: UPDATE WITH VARIABLE NAME
        isExportDone = export(this,{tunedC},{controllerName});
        if isExportDone
            exportSuccessful = true;
        end
    end
end

function Widgets = qeGetCustomWidgets()
    Widgets = struct('ControllerNameTextField',this.ControllerNameTextField,...
        'ControllerCheckbox',this.ControllerCheckbox);
end

