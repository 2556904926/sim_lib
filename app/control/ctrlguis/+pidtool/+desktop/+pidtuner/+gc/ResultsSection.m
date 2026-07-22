classdef ResultsSection < handle
    %RESULTSSECTION
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TPComponent
        ExportButton
        ExportDialog
        TunerTC
    end
    events
        UpdateBlockParameters
    end
    methods
        function obj = ResultsSection(tunermodel)
            %RESULTSSECTION
            
            obj.TPComponent = matlab.ui.internal.toolstrip.Section(pidtool.utPIDgetStrings('cst','strResults'));
            obj.TPComponent.Tag = 'Results';
            obj.TPComponent.CollapsePriority = 10;
            obj.TunerTC = tunermodel;
            layout(obj);
        end
        function layout(this)
            %LAYOUT

            column1 = this.TPComponent.addColumn();
            this.ExportButton = matlab.ui.internal.toolstrip.SplitButton(pidtool.utPIDgetStrings('cst','strExport'),matlab.ui.internal.toolstrip.Icon('export_data'));
            this.ExportButton.ButtonPushedFcn = @(~,~) cbExportButton(this);
            this.ExportButton.Popup = buildPopupItemsList(this);
            this.ExportButton.Description = getString(message('Control:pidtool:ttipExportButton'));
            
            column1.add(this.ExportButton);
        end
        
        %% Build Popup Item List
        function popup = buildPopupItemsList(this)
            
            import matlab.ui.internal.toolstrip.*
            
            % Create popup list
            popup = PopupList();
            popup.Tag = 'icon_text_description';
            
            % Export Item
            item = ListItem(pidtool.utPIDgetStrings('cst', 'strExport'));
            item.Icon = Icon('export_ws3d');
            item.ItemPushedFcn = @(~,~) cbExportButton(this);
            item.Description = pidtool.utPIDgetStrings('cst', 'toolbar_tooltip_ep');
            popup.add(item);
            
            % Save as Baseline Item
            item = ListItem(pidtool.utPIDgetStrings('cst', 'strSaveBaselineTitle'));
            item.Icon = Icon('save_block');
            item.ItemPushedFcn = @(~,~) cbSaveBaseline(this);
            item.Description = pidtool.utPIDgetStrings('cst', 'strSaveBaselineDesc');
            popup.add(item);

        end
    end
end


%% Callbacks
function cbExportButton(this)
%CBEXPORTBUTTON
isRegisterDlg = false;
if isempty(this.ExportDialog)
    this.ExportDialog = pidtool.desktop.pidtuner.gc.ExportDialogGC(this.TunerTC);
    isRegisterDlg = true;
end
show(this.ExportDialog,this.ExportButton);
if isRegisterDlg
    registerDialog(this.TunerTC.DialogManager,this.ExportDialog);
end
centerDialog(this.TunerTC.DialogManager,this.ExportDialog.Name)

end

function cbSaveBaseline(this)
%CBSAVEBASELINE
this.TunerTC.ControllerList.BaselineController = this.TunerTC.ControllerList.TunedController;

end
