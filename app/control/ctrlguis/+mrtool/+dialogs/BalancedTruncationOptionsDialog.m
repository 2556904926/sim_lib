classdef (Hidden) BalancedTruncationOptionsDialog < mrtool.dialogs.AbstractOptionsDialog
    % Balanced Truncation Options Dialog of Model Reduction App
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc.

    %% Properties
    properties (Access = protected)
        Layout
        FocusLayout
        InputWeight
        OutputWeight
        Weights (1,1) ltioptions.ioweight = ltioptions.ioweight;
        WeightStrings (1,2) string = ["[]" "[]"];
    end
    
    %% Constructor
    methods
        function this = BalancedTruncationOptionsDialog(ToolData)
            arguments
                ToolData (1,1) mrtool.data.BalancedTruncationData
            end
            DialogName = 'BalancedTruncationOptionsDialog';            
            this = this@mrtool.dialogs.AbstractOptionsDialog(ToolData,DialogName);        
        end
    end

    %% Public methods
    methods
        function updateUI(this)
            if issparse(this.ToolData.TargetSystem)
                return;
            end            
            % NCF Truncation
            NCF = this.ToolData.UseNCFTruncation;
            if this.Widgets.NCFCheckbox.Value ~= NCF
                this.Widgets.NCFCheckbox.Value = NCF;
            end
            cbNCFTruncationChanged(this,NCF);
            % Method
            MATCHDC = strcmpi(this.ToolData.Method,'matchDC');
            if this.Widgets.MethodCheckbox.Value ~= MATCHDC
                this.Widgets.MethodCheckbox.Value = MATCHDC;
            end
            R = this.ToolData.ReduceSpec;
            if isa(R,'mor.BalancedTruncation')
                % Algorithm
                switch R.Options.Algorithm
                    case 'absolute'
                        if this.Widgets.AlgorithmCheckbox.Value
                            this.Widgets.AlgorithmCheckbox.Value = false;
                        end
                        cbAlgorithmCheckboxChanged(this,false);
                    case 'relative'
                        if ~this.Widgets.AlgorithmCheckbox.Value
                            this.Widgets.AlgorithmCheckbox.Value = true;
                        end
                        cbAlgorithmCheckboxChanged(this,true);
                end
                if isempty(R.Options.InputWeight) && isempty(R.Options.OutputWeight)
                    % Intervals
                    this.Widgets.UseIntervalsButtonGroup.SelectedObject = this.Widgets.UseIntervalsButton;
                    cbUseIntervalsRadioChanged(this,getString(message('Control:mrtool:BTOptionsIntervalsFocus')));
                    if ~isequal(this.Widgets.FreqIntervalsTable.Data,R.Options.FreqIntervals)
                        this.Widgets.FreqIntervalsTable.Data = round(R.Options.FreqIntervals,2,'significant');
                    end
                    if ~isequal(this.Widgets.TimeIntervalsTable.Data,R.Options.TimeIntervals)
                        this.Widgets.TimeIntervalsTable.Data = round(R.Options.TimeIntervals,2,'significant');
                    end
                else
                    % Weights
                    this.Widgets.UseIntervalsButtonGroup.SelectedObject = this.Widgets.UseWeightsButton;
                    cbUseIntervalsRadioChanged(this,getString(message('Control:mrtool:BTOptionsWeightsFocus')));
                    weightStrings = this.ToolData.WeightStrings;
                    if ~strcmpi(this.Widgets.InputWeightEditField.Value,weightStrings(1))
                        this.Widgets.InputWeightEditField.Value = weightStrings(1);
                        this.Weights.InputWeight = R.Options.InputWeight;
                    end
                    if ~strcmpi(this.Widgets.OutputWeightEditField.Value,weightStrings(2))
                        this.Widgets.OutputWeightEditField.Value = weightStrings(2);
                        this.Weights.OutputWeight = R.Options.OutputWeight;
                    end
                end
                % Regularization
                if isnumeric(R.Options.Regularization)
                    if ~this.Widgets.RegularizationCheckbox.Value
                        this.Widgets.RegularizationCheckbox.Value = true;
                        cbRegularizationCheckboxChanged(this,true);
                    end
                    if this.Widgets.RegularizationEditField.Value ~= R.Options.Regularization
                        this.Widgets.RegularizationEditField.Value = R.Options.Regularization;
                    end
                else
                    if this.Widgets.RegularizationCheckbox.Value
                        this.Widgets.RegularizationCheckbox.Value = false;
                        cbRegularizationCheckboxChanged(this,false);
                    end
                    if this.Widgets.RegularizationEditField.Value ~= getRegularization(this.ToolData)
                        this.Widgets.RegularizationEditField.UpperLimitInclusive = 'on';
                        this.Widgets.RegularizationEditField.Value = getRegularization(this.ToolData);
                        this.Widgets.RegularizationEditField.UpperLimitInclusive = 'off';
                    end
                end
                % Offset
                if this.Widgets.OffsetEditField.Value ~= R.Options.Offset
                    this.Widgets.OffsetEditField.Value = R.Options.Offset;
                end
                % SepTol
                if this.Widgets.SepTolEditField.Value ~= R.Options.SepTol
                    this.Widgets.SepTolEditField.Value = R.Options.SepTol;
                end
            end
        end 
        function freqSelectorChanged(this,row,column,data,finished)
            this.Widgets.FreqIntervalsTable.Data(row,column) = data;
            this.Widgets.FreqIntervalsTable.Enable = finished;
        end
    end

    %% Protected methods
    methods (Access=protected)
        function figureGrid = buildUI(this)
            % AbstractOptionsDialog
            figureGrid = buildUI@mrtool.dialogs.AbstractOptionsDialog(this);

            this.Layout = uigridlayout(figureGrid,[6 3]);
            this.Layout.Layout.Row = 1;
            this.Layout.Layout.Column = 1;
            this.Layout.RowHeight = {'fit','fit','fit','fit','fit','fit','fit'};
            this.Layout.ColumnWidth = {'fit','1x','fit'};

            % Title
            TitleLabel = uilabel(this.Layout);
            TitleLabel.Layout.Row = 1;
            TitleLabel.Layout.Column = [1 3];
            TitleLabel.Text = getString(message('Control:mrtool:BTOptionsTitle'));
            TitleLabel.FontWeight = 'bold';
            TitleLabel.Tag = 'MR_BTOptions_TitleLabel'; 

            % Normalize Coprime Factors
            NCFCheckbox = uicheckbox(this.Layout);
            NCFCheckbox.Layout.Row = 2;
            NCFCheckbox.Layout.Column = [1 3];
            NCFCheckbox.Text = getString(message('Control:mrtool:BTOptionsNCFLabel'));
            NCFCheckbox.Enable = license('test','Robust_Toolbox') & ~isempty(ver('robust'));
            if NCFCheckbox.Enable
                NCFCheckbox.Tooltip = getString(message('Control:mrtool:BTOptionsNCFTooltip'));
            else
                NCFCheckbox.Tooltip = getString(message('Control:mrtool:BTOptionsNCFNeedsRobustTooltip'));
            end
            NCFCheckbox.Value = false;
            NCFCheckbox.Tag = 'MR_BTOptions_NCFCheckbox'; 

            % Method
            MethodCheckbox = uicheckbox(this.Layout);
            MethodCheckbox.Layout.Row = 3;
            MethodCheckbox.Layout.Column = [1 3];
            MethodCheckbox.Text = getString(message('Control:mrtool:OptionsMethodLabel'));
            MethodCheckbox.Tooltip = getString(message('Control:mrtool:OptionsMethodTooltip'));
            MethodCheckbox.Value = false;
            MethodCheckbox.Tag = 'MR_BTOptions_MethodCheckbox'; 

            % Algorithm
            AlgorithmCheckbox = uicheckbox(this.Layout);
            AlgorithmCheckbox.Layout.Row = 4;
            AlgorithmCheckbox.Layout.Column = [1 3];
            AlgorithmCheckbox.Text = getString(message('Control:mrtool:BTOptionsAlgorithmLabel'));
            AlgorithmCheckbox.Tooltip = getString(message('Control:mrtool:BTOptionsAlgorithmTooltip'));
            AlgorithmCheckbox.Value = true;
            AlgorithmCheckbox.Tag = 'MR_BTOptions_AlgorithmCheckbox'; 

            %% Focus
            FocusPanel = uipanel(this.Layout);
            FocusPanel.Layout.Row = 5;
            FocusPanel.Layout.Column = [1 3];
            FocusPanel.Title = getString(message('Control:mrtool:BTOptionsFocus'));
            FocusPanel.FontWeight = 'bold';
            FocusPanel.BorderType = 'none';
            this.FocusLayout = uigridlayout(FocusPanel,[7 3]);
            this.FocusLayout.RowHeight = {40,'fit',99,'fit',99,'fit','fit'};
            this.FocusLayout.ColumnWidth = {'fit','1x','fit'};

            % UseIntervals
            UseIntervalsButtonGroup = uibuttongroup(this.FocusLayout);
            UseIntervalsButtonGroup.Layout.Row = 1;
            UseIntervalsButtonGroup.Layout.Column = [1 3];
            UseIntervalsButtonGroup.BorderType = 'none';
            UseIntervalsButtonGroup.Tag = 'MR_BTOptions_UseIntervalsButtonGroup'; 
            UseIntervalsButton = uiradiobutton(UseIntervalsButtonGroup);
            UseIntervalsButton.Text = getString(message('Control:mrtool:BTOptionsIntervalsFocus'));
            UseIntervalsButton.Tag = 'MR_BTOptions_UseIntervalsButton'; 
            UseWeightsButton = uiradiobutton(UseIntervalsButtonGroup);
            UseWeightsButton.Text = getString(message('Control:mrtool:BTOptionsWeightsFocus'));
            UseWeightsButton.Position = [UseIntervalsButton.Position(1)+UseIntervalsButton.Position(3)+10 UseIntervalsButton.Position(2:4)];
            UseWeightsButton.Tag = 'MR_BTOptions_UseWeightsButton'; 

            % Frequency Intervals
            FreqIntervalsLabel = uilabel(this.FocusLayout);
            FreqIntervalsLabel.Layout.Row = 2;
            FreqIntervalsLabel.Layout.Column = 1;
            FreqIntervalsLabel.Text = getString(message('Control:mrtool:BTOptionsFrequencyIntervals'));
            FreqIntervalsLabel.Tag = 'MR_BTOptions_FreqIntervalsLabel'; 
            freqButtonLayout = uigridlayout(this.FocusLayout,[1 2]);
            freqButtonLayout.Layout.Row = 2;
            freqButtonLayout.Layout.Column = 3;
            freqButtonLayout.ColumnWidth = {'1x','fit','fit'};
            FreqIntervalsRemoveButton = uibutton(freqButtonLayout);
            FreqIntervalsRemoveButton.Layout.Column = 2;
            FreqIntervalsRemoveButton.Text = '';
            FreqIntervalsRemoveButton.Tooltip = getString(message('Control:mrtool:BTOptionsRemoveIntervalTooltip'));
            FreqIntervalsRemoveButton.Tag = 'MR_BTOptions_FreqIntervalsRemoveButton'; 
            matlab.ui.control.internal.specifyIconID(FreqIntervalsRemoveButton,'delete',16);
            FreqIntervalsRemoveButton.Enable = 0; 
            FreqIntervalsAddButton = uibutton(freqButtonLayout);
            FreqIntervalsAddButton.Layout.Column = 3;
            FreqIntervalsAddButton.Text = '';
            FreqIntervalsAddButton.Tooltip = getString(message('Control:mrtool:BTOptionsAddIntervalTooltip'));
            FreqIntervalsAddButton.Tag = 'MR_BTOptions_FreqIntervalsAddButton'; 
            matlab.ui.control.internal.specifyIconID(FreqIntervalsAddButton,'add',16);
            FreqIntervalsTable = uitable(this.FocusLayout);
            FreqIntervalsTable.Layout.Row = 3;
            FreqIntervalsTable.Layout.Column = [1 3];
            FreqIntervalsTable.ColumnName = {getString(message('Control:mrtool:LowerCutoffLabel'))...
                getString(message('Control:mrtool:UpperCutoffLabel'))};
            FreqIntervalsTable.ColumnWidth = '1x';
            FreqIntervalsTable.ColumnEditable = [true true];
            FreqIntervalsTable.RowStriping = 'off';
            FreqIntervalsTable.Multiselect = true;
            FreqIntervalsTable.SelectionType = 'row';
            FreqIntervalsTable.Tag = 'MR_BTOptions_FreqIntervalsTable'; 

            % Time Intervals
            TimeIntervalsLabel = uilabel(this.FocusLayout);
            TimeIntervalsLabel.Layout.Row = 4;
            TimeIntervalsLabel.Layout.Column = 1;
            TimeIntervalsLabel.Text = getString(message('Control:mrtool:BTOptionsTimeIntervals'));
            TimeIntervalsLabel.Tag = 'MR_BTOptions_TimeIntervalsLabel'; 
            timeButtonLayout = uigridlayout(this.FocusLayout,[1 2]);
            timeButtonLayout.Layout.Row = 4;
            timeButtonLayout.Layout.Column = 3;
            timeButtonLayout.ColumnWidth = {'1x','fit','fit'};
            TimeIntervalsRemoveButton = uibutton(timeButtonLayout);
            TimeIntervalsRemoveButton.Layout.Column = 2;
            TimeIntervalsRemoveButton.Text = '';
            TimeIntervalsRemoveButton.Tooltip = getString(message('Control:mrtool:BTOptionsRemoveIntervalTooltip'));
            TimeIntervalsRemoveButton.Tag = 'MR_BTOptions_TimeIntervalsRemoveButton'; 
            TimeIntervalsRemoveButton.Enable = 0; 
            matlab.ui.control.internal.specifyIconID(TimeIntervalsRemoveButton,'delete',16);
            TimeIntervalsAddButton = uibutton(timeButtonLayout);
            TimeIntervalsAddButton.Layout.Column = 3;
            TimeIntervalsAddButton.Text = '';
            TimeIntervalsAddButton.Tooltip = getString(message('Control:mrtool:BTOptionsAddIntervalTooltip'));
            TimeIntervalsAddButton.Tag = 'MR_BTOptions_TimeIntervalsAddButton'; 
            matlab.ui.control.internal.specifyIconID(TimeIntervalsAddButton,'add',16);
            TimeIntervalsTable = uitable(this.FocusLayout);
            TimeIntervalsTable.Layout.Row = 5;
            TimeIntervalsTable.Layout.Column = [1 3];
            TimeIntervalsTable.ColumnName = {getString(message('Control:mrtool:LowerCutoffLabel'))...
                getString(message('Control:mrtool:UpperCutoffLabel'))};
            TimeIntervalsTable.ColumnWidth = '1x';
            TimeIntervalsTable.ColumnEditable = [true true];
            TimeIntervalsTable.RowStriping = 'off';
            TimeIntervalsTable.Multiselect = true;
            TimeIntervalsTable.SelectionType = 'row';
            TimeIntervalsTable.Tag = 'MR_BTOptions_TimeIntervalsTable'; 

            % Input Weight
            InputWeightLabel = uilabel(this.FocusLayout);
            InputWeightLabel.Layout.Row = 6;
            InputWeightLabel.Layout.Column = 1;
            InputWeightLabel.Text = getString(message('Control:mrtool:BTOptionsInputWeight'));
            InputWeightLabel.Tag = 'MR_BTOptions_InputWeightLabel';
            InputWeightEditField = uieditfield(this.FocusLayout);
            InputWeightEditField.Layout.Row = 6;
            InputWeightEditField.Layout.Column = 3;
            InputWeightEditField.Tooltip = getString(message('Control:mrtool:BTOptionsInputWeightTooltip'));
            InputWeightEditField.Tag = 'MR_BTOptions_InputWeightEditField';
            InputWeightEditField.Value = '[]';

            % Output Weight
            OutputWeightLabel = uilabel(this.FocusLayout);
            OutputWeightLabel.Layout.Row = 7;
            OutputWeightLabel.Layout.Column = 1;
            OutputWeightLabel.Text = getString(message('Control:mrtool:BTOptionsOutputWeight'));
            OutputWeightLabel.Tag = 'MR_BTOptions_OutputWeightLabel';
            OutputWeightEditField = uieditfield(this.FocusLayout);
            OutputWeightEditField.Layout.Row = 7;
            OutputWeightEditField.Layout.Column = 3;
            OutputWeightEditField.Tooltip = getString(message('Control:mrtool:BTOptionsOutputWeightTooltip'));
            OutputWeightEditField.Tag = 'MR_BTOptions_OutputWeightEditField';
            OutputWeightEditField.Value = '[]';
            
            % Regularization
            RegularizationCheckbox = uicheckbox(this.Layout);
            RegularizationCheckbox.Layout.Row = 6;
            RegularizationCheckbox.Layout.Column = 1;
            RegularizationCheckbox.Text = getString(message('Control:mrtool:BTOptionsRegularization'));
            RegularizationCheckbox.Value = false;
            RegularizationCheckbox.Tooltip = getString(message('Control:mrtool:BTOptionsRegularizationTooltip'));
            RegularizationCheckbox.Tag = 'MR_BTOptions_RegularizationCheckbox';
            RegularizationEditField = uieditfield(this.Layout,'numeric');
            RegularizationEditField.Layout.Row = 6;
            RegularizationEditField.Layout.Column = 3;
            RegularizationEditField.Value = 0;
            RegularizationEditField.Limits = [0 inf];
            RegularizationEditField.UpperLimitInclusive = 'off';
            RegularizationEditField.Enable = 'off';
            RegularizationEditField.Tooltip = getString(message('Control:mrtool:BTOptionsRegularizationTooltip2'));
            RegularizationEditField.Tag = 'MR_BTOptions_RegularizationEditField';

            %% Advanced
            AdvancedAccordian = matlab.ui.container.internal.Accordion('Parent',this.Layout);
            AdvancedAccordian.Layout.Row = 7;
            AdvancedAccordian.Layout.Column = [1 3];
            AdvancedPanel = matlab.ui.container.internal.AccordionPanel('Parent',AdvancedAccordian);
            AdvancedPanel.Title = getString(message('Control:mrtool:OptionsAdvanced'));
            AdvancedPanel.Collapsed = true;
            advancedLayout = uigridlayout(AdvancedPanel,[2 3]);
            advancedLayout.RowHeight = {'fit','fit'};
            advancedLayout.ColumnWidth = {'fit','1x','fit'};
            % Offset
            OffsetLabel = uilabel(advancedLayout);
            OffsetLabel.Layout.Row = 1;
            OffsetLabel.Layout.Column = 1;
            OffsetLabel.Text = getString(message('Control:mrtool:BTOptionsOffset'));
            OffsetLabel.Tag = 'MR_BTOptions_OffsetLabel';
            OffsetEditField = uieditfield(advancedLayout,'numeric');
            OffsetEditField.Layout.Row = 1;
            OffsetEditField.Layout.Column = 3;   
            OffsetEditField.Value = 1e-8;
            OffsetEditField.Limits = [-inf inf];
            OffsetEditField.LowerLimitInclusive = 'off';
            OffsetEditField.UpperLimitInclusive = 'off';
            OffsetEditField.Tooltip = getString(message('Control:mrtool:BTOptionsOffsetTooltip'));
            OffsetEditField.Tag = 'MR_BTOptions_OffsetEditField'; 
            % SepTol
            SepTolLabel = uilabel(advancedLayout);
            SepTolLabel.Layout.Row = 2;
            SepTolLabel.Layout.Column = 1;
            SepTolLabel.Text = getString(message('Control:mrtool:BTOptionsSepTol'));
            SepTolLabel.Tag = 'MR_BTOptions_SepTolLabel';
            SepTolEditField = uieditfield(advancedLayout,'numeric');
            SepTolEditField.Layout.Row = 2;
            SepTolEditField.Layout.Column = 3;   
            SepTolEditField.Value = 10;
            SepTolEditField.Limits = [0 inf];
            SepTolEditField.LowerLimitInclusive = 'off';
            SepTolEditField.UpperLimitInclusive = 'off';
            SepTolEditField.Tooltip = getString(message('Control:mrtool:BTOptionsSepTolTooltip'));
            SepTolEditField.Tag = 'MR_BTOptions_SepTolEditField';

            % add to widgets
            this.Widgets.TitleLabel = TitleLabel;
            this.Widgets.MethodCheckbox = MethodCheckbox;
            this.Widgets.NCFCheckbox = NCFCheckbox;
            this.Widgets.AlgorithmCheckbox = AlgorithmCheckbox;
            this.Widgets.FocusPanel = FocusPanel;            
            this.Widgets.UseIntervalsButtonGroup = UseIntervalsButtonGroup;
            this.Widgets.UseIntervalsButton = UseIntervalsButton;
            this.Widgets.UseWeightsButton = UseWeightsButton;
            this.Widgets.FreqIntervalsLabel = FreqIntervalsLabel;
            this.Widgets.FreqIntervalsRemoveButton = FreqIntervalsRemoveButton;
            this.Widgets.FreqIntervalsAddButton = FreqIntervalsAddButton;
            this.Widgets.FreqIntervalsTable = FreqIntervalsTable;
            this.Widgets.TimeIntervalsLabel = TimeIntervalsLabel;
            this.Widgets.TimeIntervalsRemoveButton = TimeIntervalsRemoveButton;
            this.Widgets.TimeIntervalsAddButton = TimeIntervalsAddButton;
            this.Widgets.TimeIntervalsTable = TimeIntervalsTable;
            this.Widgets.InputWeightLabel = InputWeightLabel;
            this.Widgets.InputWeightEditField = InputWeightEditField;
            this.Widgets.OutputWeightLabel = OutputWeightLabel;
            this.Widgets.OutputWeightEditField = OutputWeightEditField;
            this.Widgets.RegularizationCheckbox = RegularizationCheckbox;
            this.Widgets.RegularizationEditField = RegularizationEditField;
            this.Widgets.AdvancedPanel = AdvancedPanel;
            this.Widgets.OffsetLabel = OffsetLabel;
            this.Widgets.OffsetEditField = OffsetEditField;
            this.Widgets.SepTolLabel = SepTolLabel;
            this.Widgets.SepTolEditField = SepTolEditField;
        end

        function connectUI(this)
            connectUI@mrtool.dialogs.AbstractOptionsDialog(this)
            weakThis = matlab.lang.WeakReference(this);
            this.Widgets.NCFCheckbox.ValueChangedFcn = @(es,ed) cbNCFTruncationChanged(weakThis.Handle,ed.Value);
            this.Widgets.AlgorithmCheckbox.ValueChangedFcn = @(es,ed) cbAlgorithmCheckboxChanged(weakThis.Handle,ed.Value); 
            this.Widgets.UseIntervalsButtonGroup.SelectionChangedFcn = @(es,ed) cbUseIntervalsRadioChanged(weakThis.Handle,ed.NewValue.Text);
            this.Widgets.FreqIntervalsAddButton.ButtonPushedFcn = @(es,ed) cbFreqIntervalsAddButtonPushed(weakThis.Handle);
            this.Widgets.FreqIntervalsRemoveButton.ButtonPushedFcn = @(es,ed) cbFreqIntervalsRemoveButtonPushed(weakThis.Handle);
            this.Widgets.FreqIntervalsTable.SelectionChangedFcn = @(es,ed) enableFreqRemoveButton(weakThis.Handle,ed.Selection);
            this.Widgets.FreqIntervalsTable.CellEditCallback = @(es,ed) validateInterval(weakThis.Handle,es,ed,"freq");
            this.Widgets.TimeIntervalsAddButton.ButtonPushedFcn = @(es,ed) cbTimeIntervalsAddButtonPushed(weakThis.Handle);
            this.Widgets.TimeIntervalsRemoveButton.ButtonPushedFcn = @(es,ed) cbTimeIntervalsRemoveButtonPushed(weakThis.Handle);
            this.Widgets.TimeIntervalsTable.SelectionChangedFcn = @(es,ed) enableTimeRemoveButton(weakThis.Handle,ed.Selection);
            this.Widgets.TimeIntervalsTable.CellEditCallback = @(es,ed) validateInterval(weakThis.Handle,es,ed,"time");
            this.Widgets.RegularizationCheckbox.ValueChangedFcn = @(es,ed) cbRegularizationCheckboxChanged(weakThis.Handle,ed.Value);
            this.Widgets.InputWeightEditField.ValueChangedFcn = @(es,ed) setInputWeight(weakThis.Handle,ed);  
            this.Widgets.OutputWeightEditField.ValueChangedFcn = @(es,ed) setOutputWeight(weakThis.Handle,ed);  
        end 

        function validateInterval(this,es,ed,type)
            rowNum = ed.Indices(1);
            columnNum = ed.Indices(2);
            Value = ed.NewData;
            if isnan(Value)
                es.Data(rowNum,columnNum) = ed.PreviousData;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,getString(message('Control:mrtool:BTErrorIntervalMustBeNumeric')), ...
                        getString(message('Control:mrtool:Error')));
                end
            else
                switch columnNum
                    case 1
                        if Value < 0
                            es.Data(rowNum,columnNum) = ed.PreviousData;
                            if strcmp(this.UIFigure.Visible,'on')
                                uialert(this.UIFigure,getString(message('Control:mrtool:BTErrorIntervalGreaterThanZero')), ...
                                    getString(message('Control:mrtool:Error')));
                            end
                        elseif Value >= es.Data(rowNum,2)
                            es.Data(rowNum,columnNum) = ed.PreviousData;
                            if strcmp(this.UIFigure.Visible,'on')
                                uialert(this.UIFigure,getString(message('Control:mrtool:BTErrorIntervalLessThanUpperCutoff')), ...
                                    getString(message('Control:mrtool:Error')));
                            end
                        end
                    case 2
                        if Value <= es.Data(rowNum,1)
                            es.Data(rowNum,columnNum) = ed.PreviousData;
                            if strcmp(this.UIFigure.Visible,'on')
                                uialert(this.UIFigure,getString(message('Control:mrtool:BTErrorIntervalGreaterThanLowerCutoff')), ...
                                    getString(message('Control:mrtool:Error')));
                            end
                        elseif type == "freq" && Value > pi/abs(this.ToolData.TargetSystem.Ts)
                            es.Data(rowNum,columnNum) = ed.PreviousData;
                            if strcmp(this.UIFigure.Visible,'on')
                                uialert(this.UIFigure,getString(message('Control:mrtool:BTErrorIntervalExceedsNyquistFreq',num2str(pi/abs(this.ToolData.TargetSystem.Ts)))), ...
                                    getString(message('Control:mrtool:Error')));
                            end
                        end
                end
            end
        end

        function cbNCFTruncationChanged(this,Selection)
            if Selection
                this.Layout.RowHeight{3} = 0;
                this.Layout.RowHeight{4} = 0;
                this.Layout.RowHeight{5} = 0;
                this.Layout.RowHeight{6} = 0;
                this.Layout.RowHeight{7} = 0;
                this.Widgets.MethodCheckbox.Visible = 'off';
                this.Widgets.AlgorithmCheckbox.Visible = 'off';
                this.Widgets.FocusPanel.Visible = 'off';
                this.Widgets.RegularizationCheckbox.Visible = 'off';
                this.Widgets.RegularizationEditField.Visible = 'off';
                this.Widgets.AdvancedPanel.Visible = 'off';
                this.Widgets.AdvancedPanel.Collapsed = true;
            else
                this.Layout.RowHeight{3} = 'fit';
                this.Layout.RowHeight{4} = 'fit';
                this.Layout.RowHeight{7} = 'fit';
                this.Widgets.MethodCheckbox.Visible = 'on';
                this.Widgets.AlgorithmCheckbox.Visible = 'on';
                cbAlgorithmCheckboxChanged(this,this.Widgets.AlgorithmCheckbox.Value);
                this.Widgets.AdvancedPanel.Visible = 'on';
            end
        end

        function cbAlgorithmCheckboxChanged(this,Selection)
            if ~Selection
                this.Layout.RowHeight{5} = 'fit';
                this.Layout.RowHeight{6} = 0;
                this.Widgets.FocusPanel.Visible = 'on';
                cbUseIntervalsRadioChanged(this,this.Widgets.UseIntervalsButtonGroup.SelectedObject);
                this.Widgets.RegularizationCheckbox.Visible = 'off';
                this.Widgets.RegularizationEditField.Visible = 'off';
            else
                this.Layout.RowHeight{5} = 0;
                this.Layout.RowHeight{6} = 'fit';
                this.Widgets.FocusPanel.Visible = 'off';
                this.Widgets.RegularizationCheckbox.Visible = 'on';
                this.Widgets.RegularizationEditField.Visible = 'on';
                clearTableSelections(this);
            end
        end

        function cbUseIntervalsRadioChanged(this,Selection)
            switch Selection
                case getString(message('Control:mrtool:BTOptionsIntervalsFocus'))
                    this.FocusLayout.RowHeight{2} = 'fit';
                    this.FocusLayout.RowHeight{3} = 99;
                    this.FocusLayout.RowHeight{4} = 'fit';
                    this.FocusLayout.RowHeight{5} = 99;
                    this.FocusLayout.RowHeight{6} = 0;
                    this.FocusLayout.RowHeight{7} = 0;
                    this.Widgets.FreqIntervalsLabel.Visible = 'on';
                    this.Widgets.FreqIntervalsRemoveButton.Visible = 'on';
                    this.Widgets.FreqIntervalsAddButton.Visible = 'on';
                    this.Widgets.FreqIntervalsTable.Visible = 'on';
                    this.Widgets.TimeIntervalsLabel.Visible = 'on';
                    this.Widgets.TimeIntervalsRemoveButton.Visible = 'on';
                    this.Widgets.TimeIntervalsAddButton.Visible = 'on';
                    this.Widgets.TimeIntervalsTable.Visible = 'on';
                    this.Widgets.InputWeightLabel.Visible = 'off';
                    this.Widgets.InputWeightEditField.Visible = 'off';
                    this.Widgets.OutputWeightLabel.Visible = 'off';
                    this.Widgets.OutputWeightEditField.Visible = 'off';
                case getString(message('Control:mrtool:BTOptionsWeightsFocus'))
                    this.FocusLayout.RowHeight{2} = 0;
                    this.FocusLayout.RowHeight{3} = 0;
                    this.FocusLayout.RowHeight{4} = 0;
                    this.FocusLayout.RowHeight{5} = 0;
                    this.FocusLayout.RowHeight{6} = 'fit';
                    this.FocusLayout.RowHeight{7} = 'fit';
                    this.Widgets.FreqIntervalsLabel.Visible = 'off';
                    this.Widgets.FreqIntervalsRemoveButton.Visible = 'off';
                    this.Widgets.FreqIntervalsAddButton.Visible = 'off';
                    this.Widgets.FreqIntervalsTable.Visible = 'off';
                    this.Widgets.TimeIntervalsLabel.Visible = 'off';
                    this.Widgets.TimeIntervalsRemoveButton.Visible = 'off';
                    this.Widgets.TimeIntervalsAddButton.Visible = 'off';
                    this.Widgets.TimeIntervalsTable.Visible = 'off';
                    this.Widgets.InputWeightLabel.Visible = 'on';
                    this.Widgets.InputWeightEditField.Visible = 'on';
                    this.Widgets.OutputWeightLabel.Visible = 'on';
                    this.Widgets.OutputWeightEditField.Visible = 'on';
                    clearTableSelections(this);
            end
        end

        function cbFreqIntervalsAddButtonPushed(this)
            this.Widgets.FreqIntervalsTable.Data = [this.Widgets.FreqIntervalsTable.Data;0 pi/abs(this.ToolData.TargetSystem.Ts)];
        end

        function cbFreqIntervalsRemoveButtonPushed(this)
            this.Widgets.FreqIntervalsTable.Data(this.Widgets.FreqIntervalsTable.Selection,:) = [];
            if isempty(this.Widgets.FreqIntervalsTable.Selection)
                this.Widgets.FreqIntervalsRemoveButton.Enable = 0;
            end
        end

        function enableFreqRemoveButton(this,Selection)
            if isempty(Selection)
                this.Widgets.FreqIntervalsRemoveButton.Enable = 0;
            else
                this.Widgets.FreqIntervalsRemoveButton.Enable = 1;
            end
        end

        function cbTimeIntervalsAddButtonPushed(this)
            this.Widgets.TimeIntervalsTable.Data = [this.Widgets.TimeIntervalsTable.Data;0 Inf];
        end

        function cbTimeIntervalsRemoveButtonPushed(this)
            this.Widgets.TimeIntervalsTable.Data(this.Widgets.TimeIntervalsTable.Selection,:) = [];
            if isempty(this.Widgets.TimeIntervalsTable.Selection)
                this.Widgets.TimeIntervalsRemoveButton.Enable = 0;
            end
        end

        function enableTimeRemoveButton(this,Selection)
            if isempty(Selection)
                this.Widgets.TimeIntervalsRemoveButton.Enable = 0;
            else
                this.Widgets.TimeIntervalsRemoveButton.Enable = 1;
            end
        end

        function clearTableSelections(this)
            this.Widgets.FreqIntervalsTable.Selection = [];
            this.Widgets.TimeIntervalsTable.Selection = [];
            this.Widgets.FreqIntervalsRemoveButton.Enable = 0;
            this.Widgets.TimeIntervalsRemoveButton.Enable = 0;
        end

        function cbRegularizationCheckboxChanged(this,Selection)
            if Selection
                this.Widgets.RegularizationEditField.Enable = 1;
            else
                this.Widgets.RegularizationEditField.Enable = 0;
            end
        end

        function setInputWeight(this,ed)
            try
                weight = evalin('base',ed.Value);
            catch ME
                this.Widgets.InputWeightEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                end
                return;
            end
            oldWeight = this.Weights.InputWeight;
            try
                this.Weights.InputWeight = weight;
                validate(this.Weights,this.ToolData.TargetSystem);
                this.WeightStrings(1) = ed.Value;
            catch ME
                this.Widgets.InputWeightEditField.Value = ed.PreviousValue;
                this.Weights.InputWeight = oldWeight;
                if strcmp(this.UIFigure.Visible,'on')
                    msg = getString(message(ME.identifier,getString(message('Control:mrtool:BTOptionsInputWeight'))));
                    uialert(this.UIFigure,msg,getString(message('Control:mrtool:Error')));
                end
            end
        end

        function setOutputWeight(this,ed)
            try
                weight = evalin('base',ed.Value);
            catch ME
                this.Widgets.OutputWeightEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                end
                return;
            end
            oldWeight = this.Weights.InputWeight;
            try
                this.Weights.OutputWeight = weight;
                validate(this.Weights,this.ToolData.TargetSystem);
                this.WeightStrings(2) = ed.Value;
            catch ME
                this.Widgets.OutputWeightEditField.Value = ed.PreviousValue;
                this.Weights.OutputWeight = oldWeight;
                if strcmp(this.UIFigure.Visible,'on')
                    msg = getString(message(ME.identifier,getString(message('Control:mrtool:BTOptionsOutputWeight'))));
                    uialert(this.UIFigure,msg,getString(message('Control:mrtool:Error')));
                end
            end
        end

        function cbHelpButtonPushed(this) %#ok<MANU>
            helpview('control','ModelReducerBalancedTruncationOptions','CSHelpWindow');            
        end

        function cbCloseEvent(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            close(this);
            notify(this.ToolData,'FrequencyRangeChanged');
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end

        function cbOKButtonPushed(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            if ~this.Widgets.NCFCheckbox.Value
                CommenceProcess = setOptions(this);
            else
                CommenceProcess = true;
            end
            if CommenceProcess
                notify(this,'OptionsApplying');
                oldSpec = this.ToolData.ReduceSpec;
                oldStrings = this.ToolData.WeightStrings;
                oldMethod = this.ToolData.Method;
                oldNCF = this.ToolData.UseNCFTruncation;
                if this.Widgets.MethodCheckbox.Value
                    this.ToolData.Method = "matchDC";
                else
                    this.ToolData.Method = "truncate";
                end
                this.ToolData.UseNCFTruncation = this.Widgets.NCFCheckbox.Value;
                this.ToolData.WeightStrings = this.WeightStrings;
                try
                    this.ToolDataListener.Enabled = false;
                    applyOptions(this.ToolData);
                    updateReducedSystem(this.ToolData);
                    close(this);
                    this.ToolDataListener.Enabled = true;
                catch ME
                    this.ToolData.UseNCFTruncation = oldNCF;
                    this.ToolData.Method = oldMethod;
                    this.ToolData.WeightStrings = oldStrings;
                    unapplyOptions(this.ToolData,oldSpec);
                    this.ToolDataListener.Enabled = true;
                    uialert(this.UIFigure,ME.message,...
                        getString(message('Control:mrtool:Error')))
                end
                notify(this,'OptionsApplied');
            end
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end

        function CommenceProcess = setOptions(this)
            CommenceProcess = true;
            Options = mor.BalancedTruncationOptions;
            if ~this.Widgets.AlgorithmCheckbox.Value
                switch this.Widgets.UseIntervalsButtonGroup.SelectedObject
                    case this.Widgets.UseIntervalsButton
                        try
                            if ~isempty(this.Widgets.FreqIntervalsTable.Data)
                                [~,sortOrder] = sort(this.Widgets.FreqIntervalsTable.Data(:,1));
                                Options.FreqIntervals = this.Widgets.FreqIntervalsTable.Data(sortOrder,:);
                            end
                        catch
                            uialert(this.UIFigure,getString(message('Control:mrtool:BTErrorOptionsFreqIntervals')),...
                                getString(message('Control:mrtool:Error')))
                            CommenceProcess = false;
                        end
                        if CommenceProcess
                            try
                                if ~isempty(this.Widgets.TimeIntervalsTable.Data)
                                    [~,sortOrder] = sort(this.Widgets.TimeIntervalsTable.Data(:,1));
                                    Options.TimeIntervals = this.Widgets.TimeIntervalsTable.Data(sortOrder,:);
                                end
                            catch
                                uialert(this.UIFigure,getString(message('Control:mrtool:BTErrorOptionsTimeIntervals')),...
                                    getString(message('Control:mrtool:Error')))
                                CommenceProcess = false;
                            end
                        end
                        if CommenceProcess
                            if this.Widgets.MethodCheckbox.Value
                                lastwarn('');
                                st8 = warning('query','Control:transformation:BALROM8');
                                st9 = warning('query','Control:transformation:BALROM9');
                                st10 = warning('query','Control:transformation:BALROM10');
                                warning('off','Control:transformation:BALROM8');
                                warning('off','Control:transformation:BALROM9');
                                warning('off','Control:transformation:BALROM10');
                                warnMatchDCIntervals(Options)
                                warning(st8.state,'Control:transformation:BALROM8');
                                warning(st9.state,'Control:transformation:BALROM9');
                                warning(st10.state,'Control:transformation:BALROM10');
                                [~,ME] = lastwarn;
                                switch ME
                                    case 'Control:transformation:BALROM8'
                                        selection = uiconfirm(this.UIFigure,getString(message('Control:mrtool:BTWarningOptionsFreqIntervals')),...
                                            getString(message('Control:mrtool:Warning')),'Icon','warning');
                                        CommenceProcess = strcmpi(selection,'OK');
                                    case 'Control:transformation:BALROM9'
                                        selection = uiconfirm(this.UIFigure,getString(message('Control:mrtool:BTWarningOptionsTimeIntervals')),...
                                            getString(message('Control:mrtool:Warning')),'Icon','warning');
                                        CommenceProcess = strcmpi(selection,'OK');
                                    case 'Control:transformation:BALROM10'
                                        selection = uiconfirm(this.UIFigure,getString(message('Control:mrtool:BTWarningOptionsFreqAndTimeIntervals')),...
                                            getString(message('Control:mrtool:Warning')),'Icon','warning');
                                        CommenceProcess = strcmpi(selection,'OK');
                                    otherwise
                                        CommenceProcess = true;
                                end
                            end
                        end
                    case this.Widgets.UseWeightsButton
                        Options.InputWeight = this.Weights.InputWeight;
                        Options.OutputWeight = this.Weights.OutputWeight;
                end
            else
                Options.Algorithm = 'relative';
                if this.Widgets.RegularizationCheckbox.Value
                    Options.Regularization = this.Widgets.RegularizationEditField.Value;
                end
            end
            Options.Offset = this.Widgets.OffsetEditField.Value;
            Options.SepTol = this.Widgets.SepTolEditField.Value;
            if CommenceProcess
                try
                    this.ToolData.Options = Options;
                catch ME
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')))
                    CommenceProcess = false;
                end
            end
        end
    end
end

