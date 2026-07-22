classdef ControllerSection < handle
    %CONTROLLERSECTION
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TunerGC
        TPComponent
        TunerTC
        ControllerTypeSelector
        ControllerFormComboBox
        OptionsButton
        ControllerOptionsPopup
    end
    properties (Access = private)
        Panel
    end
    methods
        function this = ControllerSection(tunertc)
            %CONTROLLERSECTION            
            this.TPComponent = matlab.ui.internal.toolstrip.Section(pidtool.utPIDgetStrings('cst','strController'));
            this.TPComponent.Tag = 'Controller';
            this.TPComponent.CollapsePriority = 2;
            this.TunerTC = tunertc;
            this.layout();
            this.initialize();
            this.update();
        end
        function layout(this)
            %LAYOUT
            import matlab.ui.internal.toolstrip.*
            column1 = this.TPComponent.addColumn();

            % Add Controller Type
            panel_ctype = Panel(); %#ok<*CPROP>
            controllertypeLabel = Label(pidtool.utPIDgetStrings('cst','strType'));
            column1_ctype = panel_ctype.addColumn();
            column2_ctype = panel_ctype.addColumn();
            column1_ctype.add(controllertypeLabel);
            
            % Controller type label and button         
            this.ControllerTypeSelector = pidtool.desktop.pidtuner.gc.ControllerTypeSelector(this.TunerTC.ControllerList);
            this.ControllerTypeSelector.ControllerTypeButton.Description = getString(message('Control:pidtool:ttipTypeDropdown'));
            column2_ctype.add(this.ControllerTypeSelector.ControllerTypeButton);

            % Controller form label and combobox
            panel_cform = Panel();
            controllerformLabel = Label(pidtool.utPIDgetStrings('cst','strForm'));
            column1_cform = panel_cform.addColumn();
            column2_cform = panel_cform.addColumn('width',100); % NOTE: temporary workaround due to issue with dynamic column sizing
            column1_cform.add(controllerformLabel);
            Values = {'parallel' pidtool.utPIDgetStrings('cst', 'form_combo1');'standard' pidtool.utPIDgetStrings('cst', 'form_combo2')};
            this.ControllerFormComboBox = DropDown(Values);
            this.ControllerFormComboBox.Tag= 'PIDTUNER_CONTROLLERFORM_DROPDOWN';
            this.ControllerFormComboBox.ValueChangedFcn = @(src, ~) controllerFormCallback(this, src);
            this.ControllerFormComboBox.Description = getString(message('Control:pidtool:ttipFormDropdown'));
            column2_cform.add(this.ControllerFormComboBox);
            
            % Options button
            this.OptionsButton = Button(pidtool.utPIDgetStrings('cst','strOptions'),Icon('settings'));
            this.OptionsButton.Tag = 'PIDTUNER_CONTROLLEROPTIONS_BUTTON';
            this.OptionsButton.ButtonPushedFcn = @(~,~) controllerOptionsCallback(this);
            this.OptionsButton.Description = getString(message('Control:pidtool:ttipOptionsButton'));

            % create main panel
            column1.add(panel_ctype);
            column1.add(panel_cform);
            column1.add(this.OptionsButton);
            this.update();
        end
        function initialize(this)
            %INITIALIZE
            addlistener(this.TunerTC.ControllerList,'DesiredController','PostSet',@(~, ~) this.update());
            addlistener(this.TunerTC.PlantList,'SelectedPlantIndex','PostSet',@(~, ~) this.update());
        end
        function update(this)
            %UPDATE widgets view
            
            % update controller form
            if strcmp(this.TunerTC.ControllerList.DesiredForm,'parallel')
                desiredid = 1;
            else
                desiredid = 2;
            end
            if desiredid ~= this.ControllerFormComboBox.SelectedIndex
                this.ControllerFormComboBox.SelectedIndex = desiredid;
            end
            % controller options
            this.updateOptionsVisibility();
        end
        function updateOptionsVisibility(this)
            %UPDATEOPTIONSVISIBILITY
            if ~isempty(this.ControllerOptionsPopup)
                if this.TunerTC.PlantList.SelectedPlantSampleTime ~=0
                    this.ControllerOptionsPopup.enableDiscreteControllerOptions(true);
                else
                    this.ControllerOptionsPopup.enableDiscreteControllerOptions(false);
                end
            end
        end
    end
end

function controllerFormCallback(this, src)
%CONTROLLERFORMCALLBACK
selectedform = src.SelectedItem;

if ~strcmp(this.TunerTC.ControllerList.DesiredForm,selectedform)
    this.TunerTC.ControllerList.DesiredForm = selectedform;
    this.update();
end
end

function controllerOptionsCallback(this)
%CONTROLLEROPTIONSCALLBACK
isRegisterDlg = false;
if isempty(this.ControllerOptionsPopup)
    this.ControllerOptionsPopup = pidtool.desktop.pidtuner.gc.ControllerOptions(this.TunerTC);
    this.updateOptionsVisibility();
    isRegisterDlg = true;
end
show(this.ControllerOptionsPopup,this.OptionsButton);
if isRegisterDlg
    registerDialog(this.TunerTC.DialogManager,this.ControllerOptionsPopup);
end
centerDialog(this.TunerTC.DialogManager,this.ControllerOptionsPopup.Name)

end
