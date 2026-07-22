classdef (Hidden) ModalTruncationOptionsDialog < mrtool.dialogs.AbstractOptionsDialog
    % Modal Truncation Options Dialog of Model Reduction App
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc.    
    
    %% Properties
    properties(Access=protected)
        InputScaling
        OutputScaling
    end

    %% Constructor
    methods
        function this = ModalTruncationOptionsDialog(ToolData)
            arguments
                ToolData (1,1) mrtool.data.ModalTruncationData
            end
            DialogName = 'ModalTruncationOptionsDialog';            
            this = this@mrtool.dialogs.AbstractOptionsDialog(ToolData,DialogName);        
        end             
    end

    %% Public methods
    methods
        function updateUI(this)
            if issparse(this.ToolData.TargetSystem)
                return;
            end
            % Method
            MATCHDC = strcmpi(this.ToolData.Method,'matchDC');
            if this.Widgets.MethodCheckbox.Value ~= MATCHDC
                this.Widgets.MethodCheckbox.Value = MATCHDC;
            end
            R = this.ToolData.ReduceSpec;
            % Mode Only
            if this.Widgets.ModeOnlyCheckbox.Value ~= R.Options.ModeOnly
                this.Widgets.ModeOnlyCheckbox.Value = R.Options.ModeOnly;
            end
            % Input Scaling
            [ny,nu] = size(this.ToolData.TargetSystem);
            INPUTSCALING = ~isempty(R.Options.InputScaling);
            if this.Widgets.InputScalingCheckbox.Value ~= INPUTSCALING
                this.Widgets.InputScalingCheckbox.Value = INPUTSCALING;
            end
            cbInputScalingCheckboxChanged(this,INPUTSCALING);
            if INPUTSCALING
                if ~isequal(this.InputScaling,R.Options.InputScaling)
                    this.InputScaling = R.Options.InputScaling;
                    this.Widgets.InputScalingEditField.Value = mat2str(R.Options.InputScaling,2);
                end
            else
                this.InputScaling = ones(nu,1);
                if ~isequal(this.Widgets.InputScalingEditField.Value,mat2str(this.InputScaling))
                    this.Widgets.InputScalingEditField.Value = mat2str(this.InputScaling);
                end
            end
            % OutputScaling
            OUTPUTSCALING = ~isempty(R.Options.OutputScaling);
            if this.Widgets.OutputScalingCheckbox.Value ~= OUTPUTSCALING
                this.Widgets.OutputScalingCheckbox.Value = OUTPUTSCALING;
            end
            cbOutputScalingCheckboxChanged(this,OUTPUTSCALING);
            if OUTPUTSCALING
                if ~isequal(this.OutputScaling,R.Options.OutputScaling)
                    this.OutputScaling = R.Options.OutputScaling;
                    this.Widgets.OutputScalingEditField.Value = mat2str(R.Options.OutputScaling,2);
                end
            else
                this.OutputScaling = ones(ny,1);
                if ~isequal(this.Widgets.OutputScalingEditField.Value,mat2str(this.OutputScaling))
                    this.Widgets.OutputScalingEditField.Value = mat2str(this.OutputScaling);
                end
            end
            % DC Frequency
            if this.Widgets.DCFrequencyEditField.Value ~= R.Options.DCFrequency
                this.Widgets.DCFrequencyEditField.Value = R.Options.DCFrequency;
            end
            % SepTol
            if this.Widgets.SepTolEditField.Value ~= R.Options.SepTol
                this.Widgets.SepTolEditField.Value = R.Options.SepTol;
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function figureGrid = buildUI(this)
            % AbstractOptionsDialog
            figureGrid = buildUI@mrtool.dialogs.AbstractOptionsDialog(this);

            layout = uigridlayout(figureGrid,[6 3]);
            layout.Layout.Row = 1;
            layout.Layout.Column = 1;
            layout.RowHeight = {'fit','fit','fit','fit','fit','fit'};
            layout.ColumnWidth = {'fit','1x','fit'};

            % Title
            TitleLabel = uilabel(layout);
            TitleLabel.Layout.Row = 1;
            TitleLabel.Layout.Column = [1 3];
            TitleLabel.Text = getString(message('Control:mrtool:MTOptionsTitle'));
            TitleLabel.FontWeight = 'bold';
            TitleLabel.Tag = 'MR_MTOptions_TitleLabel'; 

            % Method
            MethodCheckbox = uicheckbox(layout);
            MethodCheckbox.Layout.Row = 2;
            MethodCheckbox.Layout.Column = [1 3];
            MethodCheckbox.Text = getString(message('Control:mrtool:OptionsMethodLabel'));
            MethodCheckbox.Tooltip = getString(message('Control:mrtool:OptionsMethodTooltip'));
            MethodCheckbox.Value = false;
            MethodCheckbox.Tag = 'MR_MTOptions_MethodCheckbox'; 

            % Mode Only
            ModeOnlyCheckbox = uicheckbox(layout);
            ModeOnlyCheckbox.Layout.Row = 3;
            ModeOnlyCheckbox.Layout.Column = [1 3];
            ModeOnlyCheckbox.Text = getString(message('Control:mrtool:MTOptionsModeOnlyLabel'));
            ModeOnlyCheckbox.Tooltip = getString(message('Control:mrtool:MTOptionsModeOnlyTooltip'));
            ModeOnlyCheckbox.Value = false;
            ModeOnlyCheckbox.Tag = 'MR_MTOptions_ModeOnlyCheckbox'; 

            % Input Scaling
            [ny,nu] = iosize(this.ToolData.TargetSystem);
            InputScalingCheckbox = uicheckbox(layout);
            InputScalingCheckbox.Layout.Row = 4;
            InputScalingCheckbox.Layout.Column = 1;
            InputScalingCheckbox.Text = getString(message('Control:mrtool:MTOptionsInputScaling'));
            InputScalingCheckbox.Value = false;
            InputScalingCheckbox.Tooltip = getString(message('Control:mrtool:MTOptionsInputScalingTooltip'));
            InputScalingCheckbox.Tag = 'MR_MTOptions_InputScalingCheckbox';
            InputScalingEditField = uieditfield(layout);
            InputScalingEditField.Layout.Row = 4;
            InputScalingEditField.Layout.Column = 3;
            this.InputScaling = ones(nu,1);
            InputScalingEditField.Value = mat2str(this.InputScaling);
            InputScalingEditField.Enable = 'off';
            InputScalingEditField.Tooltip = getString(message('Control:mrtool:MTOptionsOutputScalingTooltip2'));
            InputScalingEditField.Tag = 'MR_MTOptions_InputScalingEditField';

            % Output Scaling
            OutputScalingCheckbox = uicheckbox(layout);
            OutputScalingCheckbox.Layout.Row = 5;
            OutputScalingCheckbox.Layout.Column = 1;
            OutputScalingCheckbox.Text = getString(message('Control:mrtool:MTOptionsOutputScaling'));
            OutputScalingCheckbox.Value = false;
            OutputScalingCheckbox.Tooltip = getString(message('Control:mrtool:MTOptionsOutputScalingTooltip'));
            OutputScalingCheckbox.Tag = 'MR_MTOptions_OutputScalingCheckbox';
            OutputScalingEditField = uieditfield(layout);
            OutputScalingEditField.Layout.Row = 5;
            OutputScalingEditField.Layout.Column = 3;
            this.OutputScaling = ones(ny,1);
            OutputScalingEditField.Value = mat2str(this.OutputScaling);
            OutputScalingEditField.Enable = 'off';
            OutputScalingEditField.Tooltip = getString(message('Control:mrtool:MTOptionsOutputScalingTooltip2'));
            OutputScalingEditField.Tag = 'MR_MTOptions_OutputScalingEditField';

            %% Advanced
            AdvancedAccordian = matlab.ui.container.internal.Accordion('Parent',layout);
            AdvancedAccordian.Layout.Row = 6;
            AdvancedAccordian.Layout.Column = [1 3];
            AdvancedPanel = matlab.ui.container.internal.AccordionPanel('Parent',AdvancedAccordian);
            AdvancedPanel.Title = getString(message('Control:mrtool:OptionsAdvanced'));
            AdvancedPanel.Collapsed = true;
            advancedLayout = uigridlayout(AdvancedPanel,[2 3]);
            advancedLayout.RowHeight = {'fit','fit'};
            advancedLayout.ColumnWidth = {'fit','1x','fit'};

            % DC Frequency
            DCFrequencyLabel = uilabel(advancedLayout);
            DCFrequencyLabel.Layout.Row = 1;
            DCFrequencyLabel.Layout.Column = 1;
            DCFrequencyLabel.Text = sprintf('%s',getString(message('Control:mrtool:MTOptionsDCFrequency')));
            DCFrequencyLabel.Tag = 'MR_MTOptions_DCFrequencyLabel';
            DCFrequencyEditField = uieditfield(advancedLayout,'numeric');
            DCFrequencyEditField.Layout.Row = 1;
            DCFrequencyEditField.Layout.Column = 3;   
            DCFrequencyEditField.Value = 0;
            DCFrequencyEditField.Limits = [0 inf];
            DCFrequencyEditField.Tooltip = getString(message('Control:mrtool:MTOptionsDCFrequencyTooltip'));
            DCFrequencyEditField.Tag = 'MR_MTOptions_DCFrequencyEditField';

            % SepTol
            SepTolLabel = uilabel(advancedLayout);
            SepTolLabel.Layout.Row = 2;
            SepTolLabel.Layout.Column = 1;
            SepTolLabel.Text = sprintf('%s',getString(message('Control:mrtool:MTOptionsSepTol')));
            SepTolLabel.Tag = 'MR_MTOptions_SepTolLabel';
            SepTolEditField = uieditfield(advancedLayout,'numeric');
            SepTolEditField.Layout.Row = 2;
            SepTolEditField.Layout.Column = 3;   
            SepTolEditField.Value = 1e-12;
            SepTolEditField.Limits = [0 1];
            SepTolEditField.LowerLimitInclusive = 'off';
            SepTolEditField.UpperLimitInclusive = 'off';
            SepTolEditField.Tooltip = getString(message('Control:mrtool:MTOptionsSepTolTooltip'));
            SepTolEditField.Tag = 'MR_MTOptions_SepTolEditField';

            % add to widgets
            this.Widgets.TitleLabel = TitleLabel;
            this.Widgets.MethodCheckbox = MethodCheckbox;
            this.Widgets.ModeOnlyCheckbox = ModeOnlyCheckbox;
            this.Widgets.InputScalingCheckbox = InputScalingCheckbox;
            this.Widgets.InputScalingEditField = InputScalingEditField;
            this.Widgets.OutputScalingCheckbox = OutputScalingCheckbox;
            this.Widgets.OutputScalingEditField = OutputScalingEditField;
            this.Widgets.AdvancedPanel = AdvancedPanel;
            this.Widgets.DCFrequencyLabel = DCFrequencyLabel;
            this.Widgets.DCFrequencyEditField = DCFrequencyEditField;
            this.Widgets.SepTolLabel = SepTolLabel;
            this.Widgets.SepTolEditField = SepTolEditField;
        end

        function connectUI(this)
            connectUI@mrtool.dialogs.AbstractOptionsDialog(this)
            weakThis = matlab.lang.WeakReference(this);
            this.Widgets.InputScalingCheckbox.ValueChangedFcn = @(es,ed) cbInputScalingCheckboxChanged(weakThis.Handle,ed.Value);
            this.Widgets.OutputScalingCheckbox.ValueChangedFcn = @(es,ed) cbOutputScalingCheckboxChanged(weakThis.Handle,ed.Value);
            this.Widgets.InputScalingEditField.ValueChangedFcn = @(es,ed) cbInputScalingChanged(weakThis.Handle,ed);
            this.Widgets.OutputScalingEditField.ValueChangedFcn = @(es,ed) cbOutputScalingChanged(weakThis.Handle,ed);
        end 

        function cbHelpButtonPushed(this) %#ok<MANU>
           helpview('control','ModelReducerModalTruncationOptions','CSHelpWindow');            
        end

        function cbInputScalingCheckboxChanged(this,Selection)
            if Selection
                this.Widgets.InputScalingEditField.Enable = 1;
            else
                this.Widgets.InputScalingEditField.Enable = 0;
            end
        end

        function cbOutputScalingCheckboxChanged(this,Selection)
            if Selection
                this.Widgets.OutputScalingEditField.Enable = 1;
            else
                this.Widgets.OutputScalingEditField.Enable = 0;
            end
        end

        function cbInputScalingChanged(this,ed)
            oldScaling = this.InputScaling;
            try
                this.InputScaling = evalin('base',this.Widgets.InputScalingEditField.Value);
            catch ME
                this.Widgets.InputScalingEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                end
                return;
            end
            if ~isempty(this.InputScaling)
                this.InputScaling = this.InputScaling(:);
            end
            [~,nu] = iosize(this.ToolData.TargetSystem);
            if isempty(this.InputScaling) || ~(isnumeric(this.InputScaling) && isvector(this.InputScaling) &&...
                    isreal(this.InputScaling) && length(this.InputScaling) == nu)
                this.InputScaling = oldScaling;
                this.Widgets.InputScalingEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,getString(message('Control:mrtool:MTErrorOptionsInputScaling',nu)),...
                        getString(message('Control:mrtool:Error')))
                end
            end
        end

        function cbOutputScalingChanged(this,ed)
            oldScaling = this.OutputScaling;
            try
                this.OutputScaling = evalin('base',this.Widgets.OutputScalingEditField.Value);
            catch ME
                this.Widgets.OutputScalingEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                end
                return;
            end
            if ~isempty(this.OutputScaling)
                this.OutputScaling = this.OutputScaling(:);
            end
            [ny,~] = iosize(this.ToolData.TargetSystem);
            if isempty(this.OutputScaling) || ~(isnumeric(this.OutputScaling) && isvector(this.OutputScaling) &&...
                    isreal(this.OutputScaling) && length(this.OutputScaling) == ny)
                this.OutputScaling = oldScaling;
                this.Widgets.OutputScalingEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,getString(message('Control:mrtool:MTErrorOptionsOutputScaling',ny)),...
                        getString(message('Control:mrtool:Error')))
                end
            end
        end

        function cbOKButtonPushed(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            [CommenceProcess,Options] = setOptions(this);
            if CommenceProcess
                notify(this,'OptionsApplying');
                if Options.ModeOnly && strcmpi(this.ToolData.AnalysisPlot,'contrib')
                    selection = uiconfirm(this.UIFigure,getString(message('Control:mrtool:MTWarningDCContribUnavailable')),...
                        getString(message('Control:mrtool:Warning')),...
                        'Icon','warning','Options',getString(message('Control:mrtool:Ok'))); %#ok<NASGU>
                end
                oldSpec = this.ToolData.ReduceSpec;
                oldMethod = this.ToolData.Method;
                if this.Widgets.MethodCheckbox.Value
                    this.ToolData.Method = "matchDC";
                else
                    this.ToolData.Method = "truncate";
                end
                try
                    this.ToolDataListener.Enabled = false;
                    applyOptions(this.ToolData);
                    updateReducedSystem(this.ToolData);
                    close(this);
                    this.ToolDataListener.Enabled = true;
                catch ME
                    this.ToolData.Method = oldMethod;
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

        function [CommenceProcess,Options] = setOptions(this)
            CommenceProcess = true;
            Options = mor.ModalTruncationOptions;
            Options.ModeOnly = this.Widgets.ModeOnlyCheckbox.Value;
            if this.Widgets.InputScalingCheckbox.Value
                Options.InputScaling = this.InputScaling;
            end
            if this.Widgets.OutputScalingCheckbox.Value
                Options.OutputScaling = this.OutputScaling;
            end
            Options.DCFrequency = this.Widgets.DCFrequencyEditField.Value;
            Options.SepTol = this.Widgets.SepTolEditField.Value;
            try
                this.ToolData.Options = Options;
            catch ME
                uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')))
                CommenceProcess = false;
            end
        end
    end
end

