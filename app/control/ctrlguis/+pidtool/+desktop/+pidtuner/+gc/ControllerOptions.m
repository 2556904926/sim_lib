classdef ControllerOptions < controllib.ui.internal.dialog.AbstractDialog
    %CONTROLLEROPTIONS
    
    % Author(s): Baljeet Singh 14-Nov-2013
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TunerTC
        ShowBaselineCheckBox
        IFormulaComboBox
        DFormulaComboBox
        IFormulaLabel
        DFormulaLabel
        DesignFocusComboBox
        DesignFocusLabel
        HelpButton
    end
    properties (Dependent = true)
        SelectedIFormula
        SelectedDFormula
        SelectedDesignFocus
    end
    methods
        function this = ControllerOptions(tunertc)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            %CONTROLLEROPTIONS
            this.TunerTC = tunertc;
            this.Name = 'PIDTUNER_CONTROLLEROPTIONS';
            this.Title = pidtool.utPIDgetStrings('cst', 'strControllerOptions');
        end
        
        function updateUI(this)
           % ADD CODE HERE FOR VISIBILITY
           this.updateDisplaySettings([],[]);
           this.updateComboBoxView();
           if this.TunerTC.PlantList.SelectedPlantSampleTime ~=0
               this.enableDiscreteControllerOptions(true);
           else
               this.enableDiscreteControllerOptions(false);
           end
        end
        
        function Widgets = qeGetWidgets(this)
            Widgets = struct('ShowBaselineCheckBox',this.ShowBaselineCheckBox,...
                       'IFormulaComboBox',this.IFormulaComboBox,...
                       'DFormulaComboBox',this.DFormulaComboBox,...
                       'IFormulaLabel',this.IFormulaLabel,...
                       'DFormulaLabel',this.DFormulaLabel,...
                       'DesignFocusComboBox',this.DesignFocusComboBox,...
                       'DesignFocusLabel',this.DesignFocusLabel,...
                       'HelpButton',this.HelpButton);
        end
        
        %% Other Functions
        function formula = get.SelectedIFormula(this)
            %GET_SELECTEDIFORMULA
            formula = this.IFormulaComboBox.Value;
        end
        
        function set.SelectedIFormula(this, val)
            %SET_SELECTEDIFORMULA
            this.IFormulaComboBox.Value = val;
        end
        
        function formula = get.SelectedDFormula(this)
            %GET_SELECTEDDFORMULA
            formula = this.DFormulaComboBox.Value;
        end
        
        function set.SelectedDFormula(this, val)
            %SET_SELECTEDIFORMULA
            this.DFormulaComboBox.Value = val;
        end
        
        function designFocus = get.SelectedDesignFocus(this)
            %GET_SELECTEDDESIGNFOCUS
            designFocus = this.DesignFocusComboBox.Value;
        end
        
        function set.SelectedDesignFocus(this, val)
            %GET_SELECTEDIFORMULA
            this.DesignFocusComboBox.Value = val;
        end
        
        function enableDiscreteControllerOptions(this, val)
            %ENABLEOPTIONS
            if val
                this.IFormulaLabel.Enable = true;
                this.DFormulaLabel.Enable = true;
                this.IFormulaComboBox.Enable = true;
                this.DFormulaComboBox.Enable = true;
            else
                this.IFormulaLabel.Enable = false;
                this.DFormulaLabel.Enable = false;
                this.IFormulaComboBox.Enable = false;
                this.DFormulaComboBox.Enable = false;
            end
        end
        
        function callbackShowBaselineCheckBox(this, src, ~)
            this.TunerTC.DataSourcePlot.showBaseline = src.Value;
        end
        
        function callbackIFormulaComboBox(this,~,~)
            this.TunerTC.ControllerList.DesiredIFormula = this.SelectedIFormula;
        end
        
        function callbackDFormulaComboBox(this,~,~)
            selectedDFormula = this.SelectedDFormula;
            CurrentTs = this.TunerTC.PlantList.SelectedPlantSampleTime;
            CurrentType = this.TunerTC.ControllerList.DesiredType;
            if CurrentTs>0 && (strcmp(CurrentType,'pid') || strcmp(CurrentType,'pid2')) && strcmp(selectedDFormula,'Trapezoidal')
                this.updateComboBoxView();
                this.TunerTC.setStatusText(pidtool.utPIDgetStrings('cst','notsupportedpid'),'warn');
                return;
            end
            if ~strcmp(this.TunerTC.ControllerList.DesiredDFormula,this.SelectedDFormula)
                this.TunerTC.ControllerList.DesiredDFormula = this.SelectedDFormula;
            end
        end
        
        function callbackDesignFocusComboBox(this,~,~)
            this.TunerTC.DesignFocus = this.SelectedDesignFocus;
        end
        
        function updateDisplaySettings(this,~,~)
            this.ShowBaselineCheckBox.Enable = this.TunerTC.DataSourcePlot.hasBaseline;
            this.ShowBaselineCheckBox.Value = this.TunerTC.DataSourcePlot.showBaseline;
        end
        
        function cbHelpButton(this,~,~) %#ok<INUSD>
            %CBHELPBUTTON
            helpview('control','pidtuner_controlleroptionsdlg','CSHelpWindow');
        end
        
        function updateComboBoxView(this,~,~)
            if ~strcmp(this.TunerTC.ControllerList.DesiredIFormula,this.SelectedIFormula)
                this.SelectedIFormula = this.TunerTC.ControllerList.DesiredIFormula;
            end
            if ~strcmp(this.TunerTC.ControllerList.DesiredDFormula,this.SelectedDFormula)
                this.SelectedDFormula = this.TunerTC.ControllerList.DesiredDFormula;
            end
            if ~strcmp(this.TunerTC.DesignFocus,this.SelectedDesignFocus)
                this.SelectedDesignFocus = this.TunerTC.DesignFocus;
            end
        end
    end
    methods (Access=protected)
       function figureGrid = buildUI(this)
            % GridLayout
            this.UIFigure.Position(3:4) = [300 350];
            figureGrid = uigridlayout(this.UIFigure,[4 3]);
            figureGrid.RowHeight = {'fit','1x','1x','1x'};
            figureGrid.ColumnWidth = {'fit','fit','1x'};
            figureGrid.RowSpacing = 5;
            
            % Baseline Panel
            BaselinePanel = uipanel(figureGrid,'Title',...
                pidtool.utPIDgetStrings('cst','strDisplaySettings'));
            BaselinePanel.Layout.Row = 1;
            BaselinePanel.Layout.Column = [1 3];
            BaselinePanel.FontWeight = 'bold';
            BaselinePanel.BorderType = 'none';
            BaselineGrid = uigridlayout(BaselinePanel,[1 1]);
    
            % Show Baseline checkbox
            this.ShowBaselineCheckBox = uicheckbox(BaselineGrid,'Text',...
                pidtool.utPIDgetStrings('cst','strShowBaselineData'));
            
            % Design Focus Panel
            DesignFocusOptionsPanel = uipanel(figureGrid,'Title',...
                pidtool.utPIDgetStrings('cst','strDesignFocusOptions'));
            DesignFocusOptionsPanel.Layout.Row = 2;
            DesignFocusOptionsPanel.Layout.Column = [1 3];
            DesignFocusOptionsPanel.FontWeight = 'bold';
            DesignFocusOptionsPanel.BorderType = 'none';
            DesignFocusOptionsGrid = uigridlayout(DesignFocusOptionsPanel,[1 2]);
            DesignFocusOptionsGrid.RowHeight = {22,22};
            DesignFocusOptionsGrid.ColumnWidth = {'fit','1x'};
            
            % Focus Dropdown
            this.DesignFocusLabel = uilabel(DesignFocusOptionsGrid, ...
                'Text',pidtool.utPIDgetStrings('cst','strDesignFocusLabel'));
            this.DesignFocusLabel.Layout.Column = 1;
            this.DesignFocusComboBox = uidropdown(DesignFocusOptionsGrid,...
                'Items',{pidtool.utPIDgetStrings('cst','strDesignFocusCombo_1'),...
                pidtool.utPIDgetStrings('cst','strDesignFocusCombo_2'),...
                pidtool.utPIDgetStrings('cst','strDesignFocusCombo_3')});
            this.DesignFocusComboBox.ItemsData = {'balanced',...
                'reference-tracking','disturbance-rejection'};
            this.DesignFocusComboBox.Layout.Column = 2;

            % Discrete Options Panel
            DiscreteOptionsPanel = uipanel(figureGrid,'Title',...
                pidtool.utPIDgetStrings('cst','strDiscControllerOptions'));
            DiscreteOptionsPanel.Layout.Row = 3;
            DiscreteOptionsPanel.Layout.Column = [1 3];
            DiscreteOptionsPanel.FontWeight = 'bold';
            DiscreteOptionsPanel.BorderType = 'none';
            DiscreteOptionsGrid = uigridlayout(DiscreteOptionsPanel,[2 2]);
            DiscreteOptionsGrid.ColumnWidth = {'fit','1x'};
            DiscreteOptionsGrid.RowHeight = {'fit','fit'};
            
            % Integrator and Filter Formula Dropdowns
            this.IFormulaLabel = uilabel(DiscreteOptionsGrid,'Text',...
                pidtool.utPIDgetStrings('cst','prefdlg_iformula_label'));
            this.IFormulaLabel.Layout.Row = 1;
            this.IFormulaLabel.Layout.Column = 1;
            this.DFormulaLabel = uilabel(DiscreteOptionsGrid,'Text',...
                pidtool.utPIDgetStrings('cst','prefdlg_dformula_label'));
            this.DFormulaLabel.Layout.Row = 2;
            this.DFormulaLabel.Layout.Column = 1;

            this.IFormulaComboBox = uidropdown(DiscreteOptionsGrid,...
                'Items',{pidtool.utPIDgetStrings('cst','prefdlg_formula_combo1'),...
                pidtool.utPIDgetStrings('cst','prefdlg_formula_combo2'),...
                pidtool.utPIDgetStrings('cst','prefdlg_formula_combo3')});
            this.IFormulaComboBox.ItemsData = {'ForwardEuler',...
                'BackwardEuler','Trapezoidal'};
            this.IFormulaComboBox.Layout.Row = 1;
            this.IFormulaComboBox.Layout.Column = 2;
            this.DFormulaComboBox = uidropdown(DiscreteOptionsGrid,...
                'Items',{pidtool.utPIDgetStrings('cst','prefdlg_formula_combo1'),...
                pidtool.utPIDgetStrings('cst','prefdlg_formula_combo2'),...
                pidtool.utPIDgetStrings('cst','prefdlg_formula_combo3')});
            this.DFormulaComboBox.ItemsData = {'ForwardEuler',...
                'BackwardEuler','Trapezoidal'};
            this.DFormulaComboBox.Layout.Row = 2;
            this.DFormulaComboBox.Layout.Column = 2;
            
            % Button Panel
            ButtonPanel = uipanel(figureGrid,'Title',' ');
            ButtonPanel.Layout.Row = 4;
            ButtonPanel.Layout.Column = [1 3];
            ButtonPanel.BorderType = 'none';
            ButtonGrid = uigridlayout(ButtonPanel,[1 5]);
            ButtonGrid.ColumnWidth = {'fit','1x','fit','fit','fit'};
            ButtonGrid.RowHeight = 22;
            
            % help button
            this.HelpButton = uibutton(ButtonGrid);
            this.HelpButton.Layout.Row = 1;
            this.HelpButton.Layout.Column = 1;
            this.HelpButton.Text = getString(message('Controllib:gui:lblHelp'));

            this.updateDisplaySettings([],[]);
            this.updateComboBoxView();
       end 
       function connectUI(this)
            L1 = addlistener(this.ShowBaselineCheckBox, 'ValueChanged', @this.callbackShowBaselineCheckBox);
            L2 = addlistener(this.IFormulaComboBox, 'ValueChanged', @this.callbackIFormulaComboBox);
            L3 = addlistener(this.DFormulaComboBox, 'ValueChanged', @this.callbackDFormulaComboBox);
            L4 = addlistener(this.DesignFocusComboBox, 'ValueChanged', @this.callbackDesignFocusComboBox);
            L5 = addlistener(this.HelpButton, 'ButtonPushed', @this.cbHelpButton);
            L6 = addlistener(this.TunerTC.DataSourcePlot, 'hasBaseline', 'PostSet', @this.updateDisplaySettings);
            L7 = addlistener(this.TunerTC.DataSourcePlot, 'showBaseline', 'PostSet', @this.updateDisplaySettings);
            L8 = addlistener(this.TunerTC.ControllerList,'DesiredController','PostSet', @this.updateComboBoxView);
            L9 = addlistener(this.TunerTC,'DesignFocus','PostSet', @this.updateComboBoxView);
            registerUIListeners(this,[L1 L2 L3 L4 L5 L6 L7 L8 L9]);
       end
    end
end
