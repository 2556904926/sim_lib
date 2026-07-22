classdef (Hidden) SparseModalTruncationOptionsDialog < mrtool.dialogs.AbstractOptionsDialog
    % Sparse Balanced Truncation Options Dialog of Model Reduction App

    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc.   

    %% Properties
    properties (SetAccess=private)
        InitData
        Initialized = false
        InitMode = false
    end

    properties (Access = protected)
        Layout
        FreqVector (1,:)
        Focus
        InputScaling
        OutputScaling
    end

    %% Constructor
    methods
        function this = SparseModalTruncationOptionsDialog(ToolData)
            arguments
                ToolData (1,1) mrtool.data.ModalTruncationData
            end
            DialogName = 'SparseBalancedTruncationOptionsDialog';            
            this = this@mrtool.dialogs.AbstractOptionsDialog(ToolData,DialogName); 
        end
    end

    %% Public methods
    methods
        function updateUI(this)
            if ~issparse(this.ToolData.TargetSystem)
                return;
            end
            % FreqVector
            this.FreqVector = this.ToolData.PlotFreqVector;
            if isempty(this.FreqVector)
                this.FreqVector = logspace(-1,3,100);
            end
            val = this.FreqVector;
            dval   = diff(val);
            val10  = log10(val);
            dval10 = diff(val10);
            tol    = 100*eps*max(abs(val));
            tol10  = 100*eps*max(abs(val10));
            if all(abs(dval-dval(1))<tol)
                freqVectorString = sprintf('%s:%s:%s',num2str(val(1)),num2str(dval(1)),num2str(val(end)));
            elseif all(abs(dval10-dval10(1))<tol10)
                freqVectorString = sprintf('logspace(%s,%s,%d)',num2str(val10(1)),num2str(val10(end)),length(val));
            else
                freqVectorString = mat2str(this.PlotFreqVector);
            end
            if ~isequal(this.Widgets.FreqVectorEditField.Value,freqVectorString)
                this.Widgets.FreqVectorEditField.Value = freqVectorString;
            end
            % Method
            MATCHDC = strcmpi(this.ToolData.Method,'matchDC');
            if this.Widgets.MethodCheckbox.Value ~= MATCHDC
                this.Widgets.MethodCheckbox.Value = MATCHDC;
            end
            R = this.ToolData.ReduceSpec;
            % Focus
            if ~isequal(this.Focus,R.Options.Focus)
                this.Widgets.FocusEditField.Value = mat2str(R.Options.Focus,2);
                this.Focus = R.Options.Focus;
            end
            % MaxOrder
            if this.Widgets.MaxOrderSpinner.Value ~= R.Options.MaxOrder
                this.Widgets.MaxOrderSpinner.Value = R.Options.MaxOrder;
            end
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
            % ModeTol
            if this.Widgets.ModeTolEditField.Value ~= R.Options.ModeTol
                this.Widgets.ModeTolEditField.Value = R.Options.ModeTol;
            end
        end

        function setInitMode(this)
            this.Widgets.InitLabel.Text = getString(message('Control:mrtool:SparseOptionsInit',this.ToolData.TargetName));
            this.Widgets.InitLabel.Visible = 'on';
            this.Layout.RowHeight{2} = 'fit';
            this.InitMode = true;
            this.InitData = [];
            this.Initialized = false;
        end

        function throwInitFailedError(this,ME)
            this.InitData = [];
            this.Initialized = false;
            uialert(this.UIFigure,ME.message,...
                getString(message('Control:mrtool:Error')));
        end
    end

    %% Protected methods
    methods (Access=protected)
        function figureGrid = buildUI(this)
            % AbstractOptionsDialog
            figureGrid = buildUI@mrtool.dialogs.AbstractOptionsDialog(this);

            this.Layout = uigridlayout(figureGrid,[5 1]);
            this.Layout.Layout.Row = 1;
            this.Layout.Layout.Column = 1;
            this.Layout.RowHeight = {'fit',0,'fit','fit','fit'};

            % Title
            TitleLabel = uilabel(this.Layout);
            TitleLabel.Layout.Row = 1;
            TitleLabel.Text = getString(message('Control:mrtool:SparseMTOptionsTitle'));
            TitleLabel.FontWeight = 'bold';
            TitleLabel.Tag = 'MR_SparseMTOptions_TitleLabel'; 

            % Init
            InitLabel = uilabel(this.Layout);
            InitLabel.Layout.Row = 2;
            InitLabel.Tag = 'MR_SparseMTOptions_InitLabel';
            InitLabel.Visible = 'off';

            %% Visualization
            visPanel = uipanel(this.Layout);
            visPanel.Layout.Row = 3;
            visPanel.Title = getString(message('Control:mrtool:SparseOptionsVisualization'));
            visPanel.FontWeight = 'bold';
            visPanel.BorderType = 'none';
            visLayout = uigridlayout(visPanel,[1 3]);
            visLayout.ColumnWidth = {'fit','1x','fit'};

            FreqVectorLabel = uilabel(visLayout);
            FreqVectorLabel.Text =  getString(message('Control:mrtool:SparseOptionsFreqVector'));
            FreqVectorLabel.Layout.Column = 1;
            FreqVectorLabel.Tag = 'MR_SparseMTOptions_FreqVectorLabel';
            FreqVectorEditField = uieditfield(visLayout);
            FreqVectorEditField.Layout.Column = 3;
            FreqVectorEditField.Value = 'logspace(-1,3,100)';
            FreqVectorEditField.Tag = 'MR_SparseMTOptions_FreqVectorEditField';
            this.FreqVector = logspace(-1,3,100);

            %% Reduction
            reducePanel = uipanel(this.Layout);
            reducePanel.Layout.Row = 4;
            reducePanel.Title = getString(message('Control:mrtool:SparseOptionsReduction'));
            reducePanel.FontWeight = 'bold';
            reducePanel.BorderType = 'none';
            reduceLayout = uigridlayout(reducePanel,[7 3]);
            reduceLayout.RowHeight = {'fit','fit','fit','fit','fit','fit','fit'};
            reduceLayout.ColumnWidth = {'fit','1x','fit'};

            % Method
            MethodCheckbox = uicheckbox(reduceLayout);
            MethodCheckbox.Layout.Row = 1;
            MethodCheckbox.Layout.Column = [1 3];
            MethodCheckbox.Text = getString(message('Control:mrtool:OptionsMethodLabel'));
            MethodCheckbox.Tooltip = getString(message('Control:mrtool:OptionsMethodTooltip'));
            MethodCheckbox.Value = false;
            MethodCheckbox.Tag = 'MR_SparseMTOptions_MethodCheckbox'; 

            % Focus
            FocusLabel = uilabel(reduceLayout);
            FocusLabel.Text =  getString(message('Control:mrtool:SparseOptionsFocus'));
            FocusLabel.Layout.Row = 2;
            FocusLabel.Layout.Column = 1;
            FocusLabel.Tag = 'MR_SparseMTOptions_FocusLabel';
            FocusEditField = uieditfield(reduceLayout);
            FocusEditField.Layout.Row = 2;
            FocusEditField.Layout.Column = 3;
            FocusEditField.Value = '[0 Inf]';
            FocusEditField.Tooltip = getString(message('Control:mrtool:SparseOptionsFocusTooltip'));
            FocusEditField.Tag = 'MR_SparseMTOptions_FocusEditField';
            this.Focus = [0 Inf];

            % Max Order
            MaxOrderLabel = uilabel(reduceLayout);
            MaxOrderLabel.Layout.Row = 3;
            MaxOrderLabel.Layout.Column = 1;
            MaxOrderLabel.Text = getString(message('Control:mrtool:SparseMTOptionsMaxOrder'));
            MaxOrderLabel.Tag = 'MR_SparseMTOptions_MaxOrderLabel';
            MaxOrderSpinner = uispinner(reduceLayout);
            MaxOrderSpinner.Layout.Row = 3;
            MaxOrderSpinner.Layout.Column = 3;   
            MaxOrderSpinner.Value = 1000;
            MaxOrderSpinner.Limits = [0 inf];
            MaxOrderSpinner.LowerLimitInclusive = 'off';
            MaxOrderSpinner.UpperLimitInclusive = 'off';
            MaxOrderSpinner.RoundFractionalValues = 'on';
            MaxOrderSpinner.Tooltip = getString(message('Control:mrtool:SparseMTOptionsMaxOrderTooltip'));
            MaxOrderSpinner.Tag = 'MR_SparseMTOptions_MaxOrderSpinner';

            % ModeOnly
            ModeOnlyCheckbox = uicheckbox(reduceLayout);
            ModeOnlyCheckbox.Layout.Row = 4;
            ModeOnlyCheckbox.Layout.Column = [1 3];
            ModeOnlyCheckbox.Text = getString(message('Control:mrtool:MTOptionsModeOnlyLabel'));
            ModeOnlyCheckbox.Tooltip = getString(message('Control:mrtool:MTOptionsModeOnlyTooltip'));
            ModeOnlyCheckbox.Tag = 'MR_SparseMTOptions_ModeOnlyCheckbox'; 

            [ny,nu] = size(this.ToolData.TargetSystem);
            % Input Scaling
            InputScalingCheckbox = uicheckbox(reduceLayout);
            InputScalingCheckbox.Layout.Row = 5;
            InputScalingCheckbox.Layout.Column = 1;
            InputScalingCheckbox.Text = getString(message('Control:mrtool:MTOptionsInputScaling'));
            InputScalingCheckbox.Value = false;
            InputScalingCheckbox.Tooltip = getString(message('Control:mrtool:MTOptionsInputScalingTooltip'));
            InputScalingCheckbox.Tag = 'MR_SparseMTOptions_InputScalingCheckbox';
            InputScalingEditField = uieditfield(reduceLayout);
            InputScalingEditField.Layout.Row = 5;
            InputScalingEditField.Layout.Column = 3;
            this.InputScaling = ones(nu,1);
            InputScalingEditField.Value = mat2str(this.InputScaling);
            InputScalingEditField.Enable = 'off';
            InputScalingEditField.Tooltip = getString(message('Control:mrtool:MTOptionsOutputScalingTooltip2'));
            InputScalingEditField.Tag = 'MR_SparseMTOptions_InputScalingEditField';

            % Output Scaling
            OutputScalingCheckbox = uicheckbox(reduceLayout);
            OutputScalingCheckbox.Layout.Row = 6;
            OutputScalingCheckbox.Layout.Column = 1;
            OutputScalingCheckbox.Text = getString(message('Control:mrtool:MTOptionsOutputScaling'));
            OutputScalingCheckbox.Value = false;
            OutputScalingCheckbox.Tooltip = getString(message('Control:mrtool:MTOptionsOutputScalingTooltip'));
            OutputScalingCheckbox.Tag = 'MR_SparseMTOptions_OutputScalingCheckbox';
            OutputScalingEditField = uieditfield(reduceLayout);
            OutputScalingEditField.Layout.Row = 6;
            OutputScalingEditField.Layout.Column = 3;
            this.OutputScaling = ones(ny,1);
            OutputScalingEditField.Value = mat2str(this.OutputScaling);
            OutputScalingEditField.Enable = 'off';
            OutputScalingEditField.Tooltip = getString(message('Control:mrtool:MTOptionsOutputScalingTooltip2'));
            OutputScalingEditField.Tag = 'MR_SparseMTOptions_OutputScalingEditField';

            %% Advanced
            AdvancedAccordian = matlab.ui.container.internal.Accordion('Parent',reduceLayout);
            AdvancedAccordian.Layout.Row = 7;
            AdvancedAccordian.Layout.Column = [1 3];
            AdvancedPanel = matlab.ui.container.internal.AccordionPanel('Parent',AdvancedAccordian);
            AdvancedPanel.Title = getString(message('Control:mrtool:OptionsAdvanced'));
            AdvancedPanel.Collapsed = true;
            advancedLayout = uigridlayout(AdvancedPanel,[3 3]);
            advancedLayout.RowHeight = {'fit','fit','fit'};
            advancedLayout.ColumnWidth = {'fit','1x','fit'}; 

            % DC Frequency
            DCFrequencyLabel = uilabel(advancedLayout);
            DCFrequencyLabel.Layout.Row = 1;
            DCFrequencyLabel.Layout.Column = 1;
            DCFrequencyLabel.Text = sprintf('%s',getString(message('Control:mrtool:MTOptionsDCFrequency')));
            DCFrequencyLabel.Tag = 'MR_SparseMTOptions_DCFrequencyLabel';
            DCFrequencyEditField = uieditfield(advancedLayout,'numeric');
            DCFrequencyEditField.Layout.Row = 1;
            DCFrequencyEditField.Layout.Column = 3;   
            DCFrequencyEditField.Value = 0;
            DCFrequencyEditField.Limits = [0 inf];
            DCFrequencyEditField.Tooltip = getString(message('Control:mrtool:MTOptionsDCFrequencyTooltip'));
            DCFrequencyEditField.Tag = 'MR_SparseMTOptions_DCFrequencyEditField';

            % SepTol
            SepTolLabel = uilabel(advancedLayout);
            SepTolLabel.Layout.Row = 2;
            SepTolLabel.Layout.Column = 1;
            SepTolLabel.Text = sprintf('%s',getString(message('Control:mrtool:MTOptionsSepTol')));
            SepTolLabel.Tag = 'MR_SparseMTOptions_SepTolLabel';
            SepTolEditField = uieditfield(advancedLayout,'numeric');
            SepTolEditField.Layout.Row = 2;
            SepTolEditField.Layout.Column = 3;   
            SepTolEditField.Value = 1e-12;
            SepTolEditField.Limits = [0 1];
            SepTolEditField.LowerLimitInclusive = 'off';
            SepTolEditField.UpperLimitInclusive = 'off';
            SepTolEditField.Tooltip = getString(message('Control:mrtool:MTOptionsSepTolTooltip'));
            SepTolEditField.Tag = 'MR_SparseMTOptions_SepTolEditField';

            % ModeTol
            ModeTolLabel = uilabel(advancedLayout);
            ModeTolLabel.Layout.Row = 3;
            ModeTolLabel.Layout.Column = 1;
            ModeTolLabel.Text = sprintf('%s',getString(message('Control:mrtool:SparseMTOptionsModeTol')));
            ModeTolLabel.Tag = 'MR_SparseMTOptions_ModeTolLabel';
            ModeTolEditField = uieditfield(advancedLayout,'numeric');
            ModeTolEditField.Layout.Row = 3;
            ModeTolEditField.Layout.Column = 3;   
            ModeTolEditField.Value = 1e-12;
            ModeTolEditField.Limits = [0 Inf];
            ModeTolEditField.LowerLimitInclusive = 'off';
            ModeTolEditField.UpperLimitInclusive = 'off';
            ModeTolEditField.Tooltip = getString(message('Control:mrtool:SparseMTOptionsModeTolTooltip'));
            ModeTolEditField.Tag = 'MR_SparseMTOptions_ModeTolEditField';

            % add to widgets
            this.Widgets.TitleLabel = TitleLabel;
            this.Widgets.InitLabel = InitLabel;
            this.Widgets.FreqVectorLabel = FreqVectorLabel;
            this.Widgets.FreqVectorEditField = FreqVectorEditField;
            this.Widgets.MethodCheckbox = MethodCheckbox;
            this.Widgets.FocusLabel = FocusLabel;
            this.Widgets.FocusEditField = FocusEditField;
            this.Widgets.MaxOrderLabel = MaxOrderLabel;
            this.Widgets.MaxOrderSpinner = MaxOrderSpinner;
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
            this.Widgets.ModeTolLabel = ModeTolLabel;
            this.Widgets.ModeTolEditField = ModeTolEditField;
        end

        function connectUI(this)
            connectUI@mrtool.dialogs.AbstractOptionsDialog(this);
            weakThis = matlab.lang.WeakReference(this);
            this.Widgets.FreqVectorEditField.ValueChangedFcn = @(es,ed) cbFreqVectorChanged(weakThis.Handle,ed);
            this.Widgets.FocusEditField.ValueChangedFcn = @(es,ed) cbFocusChanged(weakThis.Handle,ed);
            this.Widgets.InputScalingCheckbox.ValueChangedFcn = @(es,ed) cbInputScalingCheckboxChanged(weakThis.Handle,ed.Value);
            this.Widgets.OutputScalingCheckbox.ValueChangedFcn = @(es,ed) cbOutputScalingCheckboxChanged(weakThis.Handle,ed.Value);
            this.Widgets.InputScalingEditField.ValueChangedFcn = @(es,ed) cbInputScalingChanged(weakThis.Handle,ed);
            this.Widgets.OutputScalingEditField.ValueChangedFcn = @(es,ed) cbOutputScalingChanged(weakThis.Handle,ed);
        end 

        function cbHelpButtonPushed(this) %#ok<MANU>
            helpview('control','ModelReducerSparseModalTruncationOptions','CSHelpWindow');            
        end

        function cbFreqVectorChanged(this,ed)
            if isempty(ed.Value)
                this.Widgets.FreqVectorEditField.Value = ed.PreviousValue;
            else
                oldVector = this.FreqVector;
                try
                    this.FreqVector = evalin('base',this.Widgets.FreqVectorEditField.Value);
                catch ME
                    this.Widgets.FreqVectorEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                    end
                    return;
                end
                if (isempty(this.FreqVector) ...
                        || ~(isnumeric(this.FreqVector) && isvector(this.FreqVector) && ...
                        isreal(this.FreqVector) && numel(this.FreqVector) > 1 &&...
                        all(this.FreqVector>=0)) && all(diff(this.FreqVector)>0))
                    this.FreqVector = oldVector;
                    this.Widgets.FreqVectorEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,getString(message('Control:mrtool:SparseErrorFreqVector')),getString(message('Control:mrtool:Error')));
                    end
                else
                    this.FreqVector = sort(unique(this.FreqVector));
                end
            end
        end

        function cbFocusChanged(this,ed)
            if isempty(ed.Value)
                this.Widgets.FocusEditField.Value = ed.PreviousValue;
            else
                oldFocus = this.Focus;
                try
                    this.Focus = evalin('base',this.Widgets.FocusEditField.Value);
                catch ME
                    this.Widgets.FocusEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                    end
                    return;
                end
                if (isempty(this.Focus) ...
                        || ~(isnumeric(this.Focus) && isvector(this.Focus) && ...
                        isreal(this.Focus) && all(this.Focus>=0) && ...
                        length(this.Focus) == 2 && this.Focus(1) < this.Focus(2)))
                    this.Focus = oldFocus;
                    this.Widgets.FocusEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,getString(message('Control:mrtool:SparseErrorFocus')),getString(message('Control:mrtool:Error')));
                    end
                end
            end
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
            if this.InitMode
                if this.Widgets.MethodCheckbox.Value
                    method = "matchDC";
                else
                    method = "truncate";
                end
                this.InitData = struct('Options',Options,...
                    'Method',method,'FreqVector',this.FreqVector);
                this.Initialized = true;
                close(this);
            elseif CommenceProcess
                notify(this,'OptionsApplying');
                if Options.ModeOnly && strcmpi(this.ToolData.AnalysisPlot,'contrib')
                    selection = uiconfirm(this.UIFigure,getString(message('Control:mrtool:MTWarningDCContribUnavailable')),...
                        getString(message('Control:mrtool:Warning')),...
                        'Icon','warning','Options',getString(message('Control:mrtool:Ok'))); %#ok<NASGU>
                end
                oldSpec = this.ToolData.ReduceSpec;
                oldVector = this.ToolData.PlotFreqVector;
                oldMethod = this.ToolData.Method;
                if this.Widgets.MethodCheckbox.Value
                    this.ToolData.Method = "matchDC";
                else
                    this.ToolData.Method = "truncate";
                end
                this.ToolData.PlotFreqVector = this.FreqVector;
                try
                    this.ToolDataListener.Enabled = false;
                    applyOptions(this.ToolData);
                    updateReducedSystem(this.ToolData);
                    close(this);
                    this.ToolDataListener.Enabled = true;
                catch ME
                    this.ToolData.PlotFreqVector = oldVector;
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
            Options = mor.SparseModalTruncationOptions;
            Options.Focus = this.Focus;
            Options.MaxOrder = this.Widgets.MaxOrderSpinner.Value;
            Options.ModeOnly = this.Widgets.ModeOnlyCheckbox.Value;
            if this.Widgets.InputScalingCheckbox.Value
                Options.InputScaling = this.InputScaling;
            end
            if this.Widgets.OutputScalingCheckbox.Value
                Options.OutputScaling = this.OutputScaling;
            end
            Options.DCFrequency = this.Widgets.DCFrequencyEditField.Value;
            Options.SepTol = this.Widgets.SepTolEditField.Value;
            Options.ModeTol = this.Widgets.ModeTolEditField.Value;
            try
                this.ToolData.SparseOptions = Options;
            catch ME
                uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')))
                CommenceProcess = false;
            end
        end
    end
end

