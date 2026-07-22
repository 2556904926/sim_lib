classdef (Hidden) SparseBalancedTruncationOptionsDialog < mrtool.dialogs.AbstractOptionsDialog
    % Sparse Balanced Truncation Options Dialog of Model Reduction App

    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc.   

    %% Properties
    properties (SetAccess=private)
        InitData
        Initialized = true
        InitMode = false
    end

    properties (Access = protected)
        Layout
        AdvancedLayout
        FreqVector (1,:)
        Focus
        CustomShift
    end

    %% Constructor
    methods
        function this = SparseBalancedTruncationOptionsDialog(ToolData)
            arguments
                ToolData (1,1) mrtool.data.BalancedTruncationData
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
            setSparseTarget(this);
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
            % MaxRank
            if this.Widgets.MaxRankSpinner.Value ~= R.Options.MaxRank
                this.Widgets.MaxRankSpinner.Value = R.Options.MaxRank;
            end
            switch class(this.ToolData.TargetSystem)
                case 'sparss'
                    % Offset
                    if this.Widgets.OffsetEditField.Value ~= R.Options.Offset
                        this.Widgets.OffsetEditField.Value = R.Options.Offset;
                    end
                case 'mechss'
                    RAYLEIGH = ~isempty(R.Options.Rayleigh);
                    % Use Rayleigh
                    if this.Widgets.RayleighCheckbox.Value ~= RAYLEIGH
                        this.Widgets.RayleighCheckbox.Value = RAYLEIGH;
                    end
                    % Rayleigh
                    if RAYLEIGH
                        if this.Widgets.RayleighFreqEditField.Value ~= R.Options.Rayleigh(1)
                            this.Widgets.RayleighFreqEditField.Value = R.Options.Rayleigh(1);
                        end
                        if this.Widgets.RayleighDampEditField.Value ~= R.Options.Rayleigh(2)
                            this.Widgets.RayleighDampEditField.Value = R.Options.Rayleigh(2);
                        end
                        this.Widgets.RayleighFreqEditField.Enable = true;
                        this.Widgets.RayleighDampEditField.Enable = true;
                    else
                        this.Widgets.RayleighDampEditField.Enable = false;
                        this.Widgets.RayleighFreqEditField.Enable = false;
                    end
            end
            % Custom Shift
            if ~isequal(this.CustomShift,R.Options.CustomShift)
                if isequal(R.Options.CustomShift,zeros(0,1))
                    this.Widgets.CustomShiftEditField.Value = '[]';
                else
                    this.Widgets.CustomShiftEditField.Value = mat2str(R.Options.CustomShift,2);
                end
                this.CustomShift = R.Options.CustomShift;
            end
            % LyapTol
            if this.Widgets.LyapTolEditField.Value ~= R.Options.LyapTol
                this.Widgets.LyapTolEditField.Value = R.Options.LyapTol;
            end
            % RankTol
            if this.Widgets.RankTolEditField.Value ~= R.Options.RankTol
                this.Widgets.RankTolEditField.Value = R.Options.RankTol;
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

            this.Layout = uigridlayout(figureGrid,[4 1]);
            this.Layout.Layout.Row = 1;
            this.Layout.Layout.Column = 1;
            this.Layout.RowHeight = {'fit',0,'fit','fit'};

            % Title
            TitleLabel = uilabel(this.Layout);
            TitleLabel.Layout.Row = 1;
            TitleLabel.Text = getString(message('Control:mrtool:SparseBTOptionsTitle'));
            TitleLabel.FontWeight = 'bold';
            TitleLabel.Tag = 'MR_SparseBTOptions_TitleLabel'; 

            % Init
            InitLabel = uilabel(this.Layout);
            InitLabel.Layout.Row = 2;
            InitLabel.Tag = 'MR_SparseBTOptions_InitLabel';
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
            FreqVectorLabel.Tag = 'MR_SparseBTOptions_FreqVectorLabel';
            FreqVectorEditField = uieditfield(visLayout);
            FreqVectorEditField.Layout.Column = 3;
            FreqVectorEditField.Value = 'logspace(-1,3,100)';
            FreqVectorEditField.Tag = 'MR_SparseBTOptions_FreqVectorEditField';
            this.FreqVector = logspace(-1,3,100);

            %% Reduction
            reducePanel = uipanel(this.Layout);
            reducePanel.Layout.Row = 4;
            reducePanel.Title = getString(message('Control:mrtool:SparseOptionsReduction'));
            reducePanel.FontWeight = 'bold';
            reducePanel.BorderType = 'none';
            reduceLayout = uigridlayout(reducePanel,[4 3]);
            reduceLayout.RowHeight = {'fit','fit','fit','fit'};
            reduceLayout.ColumnWidth = {'fit','1x','fit'};

            % Method
            MethodCheckbox = uicheckbox(reduceLayout);
            MethodCheckbox.Layout.Row = 1;
            MethodCheckbox.Layout.Column = [1 3];
            MethodCheckbox.Text = getString(message('Control:mrtool:OptionsMethodLabel'));
            MethodCheckbox.Tooltip = getString(message('Control:mrtool:OptionsMethodTooltip'));
            MethodCheckbox.Value = false;
            MethodCheckbox.Tag = 'MR_SparseBTOptions_MethodCheckbox'; 

            % Focus
            FocusLabel = uilabel(reduceLayout);
            FocusLabel.Text =  getString(message('Control:mrtool:SparseOptionsFocus'));
            FocusLabel.Layout.Row = 2;
            FocusLabel.Layout.Column = 1;
            FocusLabel.Tag = 'MR_SparseBTOptions_FocusLabel';
            FocusEditField = uieditfield(reduceLayout);
            FocusEditField.Layout.Row = 2;
            FocusEditField.Layout.Column = 3;
            FocusEditField.Value = '[0 Inf]';
            FocusEditField.Tooltip = getString(message('Control:mrtool:SparseOptionsFocusTooltip'));
            FocusEditField.Tag = 'MR_SparseBTOptions_FocusEditField';
            this.Focus = [0 Inf];

            % Max Rank
            MaxRankLabel = uilabel(reduceLayout);
            MaxRankLabel.Layout.Row = 3;
            MaxRankLabel.Layout.Column = 1;
            MaxRankLabel.Text = getString(message('Control:mrtool:SparseBTOptionsMaxRank'));
            MaxRankLabel.Tag = 'MR_SparseBTOptions_MaxRankLabel';
            MaxRankSpinner = uispinner(reduceLayout);
            MaxRankSpinner.Layout.Row = 3;
            MaxRankSpinner.Layout.Column = 3;   
            MaxRankSpinner.Value = 5000;
            MaxRankSpinner.Limits = [0 inf];
            MaxRankSpinner.LowerLimitInclusive = 'off';
            MaxRankSpinner.UpperLimitInclusive = 'off';
            MaxRankSpinner.RoundFractionalValues = 'on';
            MaxRankSpinner.Tooltip = getString(message('Control:mrtool:SparseBTOptionsMaxRankTooltip'));
            MaxRankSpinner.Tag = 'MR_SparseBTOptions_MaxRankSpinner';

            %% Advanced
            AdvancedAccordian = matlab.ui.container.internal.Accordion('Parent',reduceLayout);
            AdvancedAccordian.Layout.Row = 4;
            AdvancedAccordian.Layout.Column = [1 3];
            AdvancedPanel = matlab.ui.container.internal.AccordionPanel('Parent',AdvancedAccordian);
            AdvancedPanel.Title = getString(message('Control:mrtool:OptionsAdvanced'));
            AdvancedPanel.Collapsed = true;
            this.AdvancedLayout = uigridlayout(AdvancedPanel,[7 3]);
            this.AdvancedLayout.RowHeight = {'fit','fit','fit','fit','fit','fit','fit'};
            this.AdvancedLayout.ColumnWidth = {'fit','1x','fit'}; 

            % Offset
            OffsetLabel = uilabel(this.AdvancedLayout);
            OffsetLabel.Layout.Row = 1;
            OffsetLabel.Layout.Column = 1;
            OffsetLabel.Text = getString(message('Control:mrtool:SparseBTOptionsOffset'));
            OffsetLabel.Tag = 'MR_SparseBTOptions_OffsetLabel';
            OffsetEditField = uieditfield(this.AdvancedLayout,'numeric');
            OffsetEditField.Layout.Row = 1;
            OffsetEditField.Layout.Column = 3;   
            OffsetEditField.Value = 0;
            OffsetEditField.Limits = [0 inf];
            OffsetEditField.UpperLimitInclusive = 'off';
            OffsetEditField.Tooltip = getString(message('Control:mrtool:SparseBTOptionsOffsetTooltip'));
            OffsetEditField.Tag = 'MR_SparseBTOptions_OffsetEditField';

            % Rayleigh
            RayleighCheckbox = uicheckbox(this.AdvancedLayout);
            RayleighCheckbox.Layout.Row = 2;
            RayleighCheckbox.Layout.Column = [1 3];
            RayleighCheckbox.Text = getString(message('Control:mrtool:SparseBTOptionsUseRayleigh'));
            RayleighCheckbox.Tag = 'MR_SparseBTOptions_RayleighCheckbox'; 

            RayleighDampLabel = uilabel(this.AdvancedLayout);
            RayleighDampLabel.Layout.Row = 3;
            RayleighDampLabel.Layout.Column = 1;
            RayleighDampLabel.Text = getString(message('Control:mrtool:SparseBTOptionsRayleighDamp'));
            RayleighDampLabel.Tag = 'MR_SparseBTOptions_RayleighDampLabel';
            RayleighDampLabel.Enable = false;
            RayleighDampEditField = uieditfield(this.AdvancedLayout,'numeric');
            RayleighDampEditField.Layout.Row = 3;
            RayleighDampEditField.Layout.Column = 3;   
            RayleighDampEditField.Value = 0.001;
            RayleighDampEditField.Limits = [0 1];
            RayleighDampEditField.LowerLimitInclusive = 'off';
            RayleighDampEditField.Tooltip = getString(message('Control:mrtool:SparseBTOptionsRayleighDampTooltip'));
            RayleighDampEditField.Tag = 'MR_SparseBTOptions_RayleighDampEditField'; 
            RayleighDampEditField.Enable = false;
            
            RayleighFreqLabel = uilabel(this.AdvancedLayout);
            RayleighFreqLabel.Layout.Row = 4;
            RayleighFreqLabel.Layout.Column = 1;
            RayleighFreqLabel.Text = getString(message('Control:mrtool:SparseBTOptionsRayleighFreq'));
            RayleighFreqLabel.Tag = 'MR_SparseBTOptions_RayleighFreqLabel';
            RayleighFreqLabel.Enable = false;
            RayleighFreqEditField = uieditfield(this.AdvancedLayout,'numeric');
            RayleighFreqEditField.Layout.Row = 4;
            RayleighFreqEditField.Layout.Column = 3;   
            RayleighFreqEditField.Value = 1;
            RayleighFreqEditField.Limits = [0 Inf];
            RayleighFreqEditField.UpperLimitInclusive = 'off';
            RayleighFreqEditField.Tooltip = getString(message('Control:mrtool:SparseBTOptionsRayleighFreqTooltip'));
            RayleighFreqEditField.Tag = 'MR_SparseBTOptions_RayleighFreqEditField'; 
            RayleighFreqEditField.Enable = false;

            % CustomShift
            CustomShiftLabel = uilabel(this.AdvancedLayout);
            CustomShiftLabel.Text =  getString(message('Control:mrtool:SparseBTOptionsCustomShift'));
            CustomShiftLabel.Layout.Row = 5;
            CustomShiftLabel.Layout.Column = 1;
            CustomShiftLabel.Tag = 'MR_SparseBTOptions_CustomShiftLabel';
            CustomShiftEditField = uieditfield(this.AdvancedLayout);
            CustomShiftEditField.Layout.Row = 5;
            CustomShiftEditField.Layout.Column = 3;
            CustomShiftEditField.Value = '[]';
            CustomShiftEditField.Tooltip = getString(message('Control:mrtool:SparseBTOptionsCustomShiftTooltip'));
            CustomShiftEditField.HorizontalAlignment = 'right';
            CustomShiftEditField.Tag = 'MR_SparseBTOptions_CustomShiftEditField';
            this.CustomShift = zeros(0,1);

            % LyapTol
            LyapTolLabel = uilabel(this.AdvancedLayout);
            LyapTolLabel.Layout.Row = 6;
            LyapTolLabel.Layout.Column = 1;
            LyapTolLabel.Text = getString(message('Control:mrtool:SparseBTOptionsLyapTol'));
            LyapTolLabel.Tag = 'MR_SparseBTOptions_LyapTolLabel';
            LyapTolEditField = uieditfield(this.AdvancedLayout,'numeric');
            LyapTolEditField.Layout.Row = 6;
            LyapTolEditField.Layout.Column = 3;   
            LyapTolEditField.Value = 1e-8;
            LyapTolEditField.Limits = [0 1];
            LyapTolEditField.LowerLimitInclusive = 'off';
            LyapTolEditField.UpperLimitInclusive = 'off';
            LyapTolEditField.Tooltip = getString(message('Control:mrtool:SparseBTOptionsLyapTolTooltip'));
            LyapTolEditField.Tag = 'MR_SparseBTOptions_LyapTolEditField'; 

            % RankTol
            RankTolLabel = uilabel(this.AdvancedLayout);
            RankTolLabel.Layout.Row = 7;
            RankTolLabel.Layout.Column = 1;
            RankTolLabel.Text = getString(message('Control:mrtool:SparseBTOptionsRankTol'));
            RankTolLabel.Tag = 'MR_SparseBTOptions_RankTolLabel';
            RankTolEditField = uieditfield(this.AdvancedLayout,'numeric');
            RankTolEditField.Layout.Row = 7;
            RankTolEditField.Layout.Column = 3;   
            RankTolEditField.Value = 1e-8;
            RankTolEditField.Limits = [0 1];
            RankTolEditField.LowerLimitInclusive = 'off';
            RankTolEditField.UpperLimitInclusive = 'off';
            RankTolEditField.Tooltip = getString(message('Control:mrtool:SparseBTOptionsRankTolTooltip'));
            RankTolEditField.Tag = 'MR_SparseBTOptions_RankTolEditField'; 

            % add to widgets
            this.Widgets.TitleLabel = TitleLabel;
            this.Widgets.InitLabel = InitLabel;
            this.Widgets.FreqVectorLabel = FreqVectorLabel;
            this.Widgets.FreqVectorEditField = FreqVectorEditField;
            this.Widgets.MethodCheckbox = MethodCheckbox;
            this.Widgets.FocusLabel = FocusLabel;
            this.Widgets.FocusEditField = FocusEditField;
            this.Widgets.MaxRankLabel = MaxRankLabel;
            this.Widgets.MaxRankSpinner = MaxRankSpinner;
            this.Widgets.AdvancedPanel = AdvancedPanel;
            this.Widgets.OffsetLabel = OffsetLabel;
            this.Widgets.OffsetEditField = OffsetEditField;
            this.Widgets.RayleighCheckbox = RayleighCheckbox;
            this.Widgets.RayleighDampLabel = RayleighDampLabel;
            this.Widgets.RayleighDampEditField = RayleighDampEditField;
            this.Widgets.RayleighFreqLabel = RayleighFreqLabel;
            this.Widgets.RayleighFreqEditField = RayleighFreqEditField;
            this.Widgets.CustomShiftLabel = CustomShiftLabel;
            this.Widgets.CustomShiftEditField = CustomShiftEditField;
            this.Widgets.LyapTolLabel = LyapTolLabel;
            this.Widgets.LyapTolEditField = LyapTolEditField;
            this.Widgets.RankTolLabel = RankTolLabel;
            this.Widgets.RankTolEditField = RankTolEditField;
        end

        function connectUI(this)
            connectUI@mrtool.dialogs.AbstractOptionsDialog(this);
            weakThis = matlab.lang.WeakReference(this);
            this.Widgets.FreqVectorEditField.ValueChangedFcn = @(es,ed) cbFreqVectorChanged(weakThis.Handle,ed);
            this.Widgets.FocusEditField.ValueChangedFcn = @(es,ed) cbFocusChanged(weakThis.Handle,ed);
            this.Widgets.RayleighCheckbox.ValueChangedFcn = @(es,ed) cbRayleighCheckboxChanged(weakThis.Handle,ed.Value);
            this.Widgets.CustomShiftEditField.ValueChangedFcn = @(es,ed) cbCustomShiftChanged(weakThis.Handle,ed);
        end 

        function cbHelpButtonPushed(this) %#ok<MANU>
            helpview('control','ModelReducerSparseBalancedTruncationOptions','CSHelpWindow');            
        end

        function setSparseTarget(this)
            SPARSS = isa(this.ToolData.TargetSystem,'sparss');
            MECHSS = isa(this.ToolData.TargetSystem,'mechss');
            if SPARSS
                this.Widgets.OffsetLabel.Visible = 'on';
                this.Widgets.OffsetEditField.Visible = 'on';
                this.AdvancedLayout.RowHeight{1} = 'fit';
            else
                this.Widgets.OffsetLabel.Visible = 'off';
                this.Widgets.OffsetEditField.Visible = 'off';
                this.AdvancedLayout.RowHeight{1} = 0;
            end
            if MECHSS
                this.Widgets.RayleighCheckbox.Visible = 'on';
                this.Widgets.RayleighDampLabel.Visible = 'on';
                this.Widgets.RayleighDampEditField.Visible = 'on';
                this.Widgets.RayleighFreqLabel.Visible = 'on';
                this.Widgets.RayleighFreqEditField.Visible = 'on';
                this.AdvancedLayout.RowHeight{2} = 'fit';
                this.AdvancedLayout.RowHeight{3} = 'fit';
                this.AdvancedLayout.RowHeight{4} = 'fit';
            else
                this.Widgets.RayleighCheckbox.Visible = 'off';
                this.Widgets.RayleighDampLabel.Visible = 'off';
                this.Widgets.RayleighDampEditField.Visible = 'off';
                this.Widgets.RayleighFreqLabel.Visible = 'off';
                this.Widgets.RayleighFreqEditField.Visible = 'off';
                this.AdvancedLayout.RowHeight{2} = 0;
                this.AdvancedLayout.RowHeight{3} = 0;
                this.AdvancedLayout.RowHeight{4} = 0;
            end
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

        function cbRayleighCheckboxChanged(this,selection)
            if selection
                this.Widgets.RayleighDampLabel.Enable = 'on';
                this.Widgets.RayleighDampEditField.Enable = 'on';
                this.Widgets.RayleighFreqLabel.Enable = 'on';
                this.Widgets.RayleighFreqEditField.Enable = 'on';
            else
                this.Widgets.RayleighDampLabel.Enable = 'off';
                this.Widgets.RayleighDampEditField.Enable = 'off';
                this.Widgets.RayleighFreqLabel.Enable = 'off';
                this.Widgets.RayleighFreqEditField.Enable = 'off';
            end
        end

        function cbCustomShiftChanged(this,ed)
            oldShifts = this.CustomShift;
            try
                this.CustomShift = evalin('base',this.Widgets.CustomShiftEditField.Value);
            catch ME
                this.Widgets.CustomShiftEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                end
                return;
            end
            if isempty(this.CustomShift)
                this.CustomShift = zeros(0,1);
            end
            if ~(isnumeric(this.CustomShift) && isvector(this.CustomShift))
                this.CustomShift = oldShifts;
                this.Widgets.CustomShiftEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,getString(message('Control:mrtool:SparseBTErrorCustomShift')),getString(message('Control:mrtool:Error')));
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
            Options = mor.SparseBalancedTruncationOptions;
            Options.Focus = this.Focus;
            Options.MaxRank = this.Widgets.MaxRankSpinner.Value;
            Options.Offset = this.Widgets.OffsetEditField.Value;
            if this.Widgets.RayleighCheckbox.Value
                damp = this.Widgets.RayleighDampEditField.Value;
                freq = this.Widgets.RayleighFreqEditField.Value;
                Options.Rayleigh = [freq damp];
            end
            Options.CustomShift = this.CustomShift;
            Options.LyapTol = this.Widgets.LyapTolEditField.Value;
            Options.RankTol = this.Widgets.RankTolEditField.Value;
            try
                this.ToolData.SparseOptions = Options;
            catch ME
                uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')))
                CommenceProcess = false;
            end
        end
    end
end

