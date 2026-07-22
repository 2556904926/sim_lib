classdef (Hidden) SparseProperOrthogonalDecompositionOptionsDialog < mrtool.dialogs.AbstractOptionsDialog
    % Proper Orthogonal Decomposition Options Dialog of Model Reduction App
    
    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc.   

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
        InputWeight
        OutputWeight
    end
    
    %% Constructor/destructor
    methods
        function this = SparseProperOrthogonalDecompositionOptionsDialog(ToolData)
            arguments
                ToolData (1,1) mrtool.data.ProperOrthogonalDecompositionData
            end
            DialogName = 'SparseProperOrthogonalDecompositionOptionsDialog';            
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
            R = this.ToolData.ReduceSpec;
            % Focus
            this.Focus = R.Options.Focus;
            this.Widgets.FocusEditField.Value = mat2str(R.Options.Focus);
            % Excitation
            this.Widgets.ExcitationDropDown.Value = R.Options.Excitation;
            % Method
            MATCHDC = strcmpi(this.ToolData.Method,'matchDC');
            if this.Widgets.MethodCheckbox.Value ~= MATCHDC
                this.Widgets.MethodCheckbox.Value = MATCHDC;
            end
            % Algorithm
            [ny,nu] = iosize(this.ToolData.TargetSystem);
            if ny == nu
                this.Widgets.AlgorithmDropDown.Items = {getString(message('Control:mrtool:PODOptionsAlgorithmBalanced')),...
                    getString(message('Control:mrtool:PODOptionsAlgorithmGalerkin'))};
                this.Widgets.AlgorithmDropDown.ItemsData = {'balanced','galerkin'};
            else
                this.Widgets.AlgorithmDropDown.Items = {getString(message('Control:mrtool:PODOptionsAlgorithmBalanced')),...
                    getString(message('Control:mrtool:PODOptionsAlgorithmGalerkin')),...
                    getString(message('Control:mrtool:PODOptionsAlgorithmCompress'))};
                this.Widgets.AlgorithmDropDown.ItemsData = {'balanced','galerkin','compress'};
            end
            this.Widgets.AlgorithmDropDown.Value = R.Options.Algorithm;
            cbAlgorithmDropDownChanged(this,R.Options.Algorithm);
            % InputWeight
            this.InputWeight = R.Options.InputWeight;
            this.Widgets.InputWeightEditField.Value = mat2str(R.Options.InputWeight);
            % OutputWeight
            this.OutputWeight = R.Options.OutputWeight;
            this.Widgets.OutputWeightEditField.Value = mat2str(R.Options.OutputWeight);
            % Center
            this.Widgets.CenterCheckbox.Value = R.Options.Center;
            % RankTol
            this.Widgets.RankTolEditField.Value = R.Options.RankTol;
            % CompressTol
            this.Widgets.CompressTolEditField.Value = R.Options.CompressTol;
            % NumStep
            this.Widgets.NumStepEditField.Value = R.Options.NumStep;
            this.Widgets.NumStepEditField.Visible = ~isdt(this.ToolData.TargetSystem);
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
            TitleLabel.Text = getString(message('Control:mrtool:SparsePODOptionsTitle'));
            TitleLabel.FontWeight = 'bold';
            TitleLabel.Tag = 'MR_SparsePODOptions_TitleLabel'; 

            % Init
            InitLabel = uilabel(this.Layout);
            InitLabel.Layout.Row = 2;
            InitLabel.Tag = 'MR_SparsePOOptions_InitLabel';
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
            FreqVectorLabel.Tag = 'MR_SparsePOOOptions_FreqVectorLabel';
            FreqVectorEditField = uieditfield(visLayout);
            FreqVectorEditField.Layout.Column = 3;
            FreqVectorEditField.Value = 'logspace(-1,3,100)';
            FreqVectorEditField.Tag = 'MR_SparsePODOptions_FreqVectorEditField';
            this.FreqVector = logspace(-1,3,100);

            %% POD Data
            PODDataPanel = uipanel(this.Layout);
            PODDataPanel.Layout.Row = 4;
            PODDataPanel.Title = getString(message('Control:mrtool:PODOptionsPODData'));
            PODDataPanel.FontWeight = 'bold';
            PODDataPanel.BorderType = 'none';
            PODDataLayout = uigridlayout(PODDataPanel,[3 3]);
            PODDataLayout.RowHeight = {'fit','fit','fit'};
            PODDataLayout.ColumnWidth = {'fit','1x','fit'};

            PODDataLabel = uilabel(PODDataLayout);
            PODDataLabel.Layout.Row = 1;
            PODDataLabel.Layout.Column = [1 3];
            PODDataLabel.Text = getString(message('Control:mrtool:PODOptionsPODDataLabel'));

            % Focus
            FocusLabel = uilabel(PODDataLayout);
            FocusLabel.Text = getString(message('Control:mrtool:PODOptionsFocusLabel'));
            FocusLabel.Layout.Row = 2;
            FocusLabel.Layout.Column = 1;
            FocusLabel.Tag = 'MR_SparsePOOOptions_FocusLabel';
            FocusEditField = uieditfield(PODDataLayout);
            FocusEditField.Layout.Row = 2;
            FocusEditField.Layout.Column = 3;
            FocusEditField.Value = '[0.1 1000]';
            FocusEditField.Tooltip = getString(message('Control:mrtool:PODOptionsFocusTooltip'));
            FocusEditField.Tag = 'MR_SparsePOOOptions_FocusEditField';
            this.Focus = [0.1 1000];

            % Excitation
            ExcitationLabel = uilabel(PODDataLayout);
            ExcitationLabel.Text =  getString(message('Control:mrtool:PODOptionsExcitationLabel'));
            ExcitationLabel.Layout.Row = 3;
            ExcitationLabel.Layout.Column = 1;
            ExcitationLabel.Tag = 'MR_SparsePOOOptions_ExcitationLabel';
            ExcitationDropDown = uidropdown(PODDataLayout);
            ExcitationDropDown.Layout.Row = 3;
            ExcitationDropDown.Layout.Column = 3;
            ExcitationDropDown.Items = {getString(message('Control:mrtool:PODOptionsExcitationImpulse')),...
                getString(message('Control:mrtool:PODOptionsExcitationChirp')),...
                getString(message('Control:mrtool:PODOptionsExcitationPRBS'))};
            ExcitationDropDown.ItemsData = {'impulse','chirp','prbs'};
            ExcitationDropDown.Tooltip = getString(message('Control:mrtool:PODOptionsExcitationTooltip'));
            ExcitationDropDown.Tag = 'MR_SparsePOOOptions_ExcitationEditField';

            %% Reduction
            reducePanel = uipanel(this.Layout);
            reducePanel.Layout.Row = 5;
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
            MethodCheckbox.Tag = 'MR_SparsePOOOptions_MethodCheckbox'; 

            % Center
            CenterCheckbox = uicheckbox(reduceLayout);
            CenterCheckbox.Layout.Row = 2;
            CenterCheckbox.Layout.Column = [1 3];
            CenterCheckbox.Text = getString(message('Control:mrtool:PODOptionsCenter'));
            CenterCheckbox.Tooltip = getString(message('Control:mrtool:PODOptionsCenterTooltip'));
            CenterCheckbox.Value = false;
            CenterCheckbox.Tag = 'MR_SparsePOOOptions_Center'; 

            % Algorithm
            AlgorithmLabel = uilabel(reduceLayout);
            AlgorithmLabel.Layout.Row = 3;
            AlgorithmLabel.Layout.Column = 1;
            AlgorithmLabel.Text = getString(message('Control:mrtool:PODOptionsAlgorithmLabel'));
            AlgorithmLabel.Tag = 'MR_SparsePOOOptions_AlgorithmLabel';
            AlgorithmDropDown = uidropdown(reduceLayout);
            AlgorithmDropDown.Layout.Row = 3;
            AlgorithmDropDown.Layout.Column = 3;
            [ny,nu] = iosize(this.ToolData.TargetSystem);
            if ny == nu
                AlgorithmDropDown.Items = {getString(message('Control:mrtool:PODOptionsAlgorithmBalanced')),...
                    getString(message('Control:mrtool:PODOptionsAlgorithmGalerkin'))};
                AlgorithmDropDown.ItemsData = {'balanced','galerkin'};
            else
                AlgorithmDropDown.Items = {getString(message('Control:mrtool:PODOptionsAlgorithmBalanced')),...
                    getString(message('Control:mrtool:PODOptionsAlgorithmGalerkin')),...
                    getString(message('Control:mrtool:PODOptionsAlgorithmCompress'))};
                AlgorithmDropDown.ItemsData = {'balanced','galerkin','compress'};
            end
            AlgorithmDropDown.Tooltip = getString(message('Control:mrtool:PODOptionsAlgorithmTooltip'));
            AlgorithmDropDown.Tag = 'MR_SparsePOOOptions_AlgorithmDropDown';

            % Input Weight
            InputWeightLabel = uilabel(reduceLayout);
            InputWeightLabel.Layout.Row = 4;
            InputWeightLabel.Layout.Column = 1;
            InputWeightLabel.Text = getString(message('Control:mrtool:PODOptionsInputWeight'));
            InputWeightLabel.Tag = 'MR_SparsePOOOptions_InputWeightLabel';
            InputWeightEditField = uieditfield(reduceLayout);
            InputWeightEditField.Layout.Row = 4;
            InputWeightEditField.Layout.Column = 3;
            InputWeightEditField.Tooltip = getString(message('Control:mrtool:PODOptionsInputWeightTooltip'));
            InputWeightEditField.Tag = 'MR_SparsePOOOptions_InputWeightEditField';
            InputWeightEditField.Value = '[]';
            this.InputWeight = [];

            % Output Weight
            OutputWeightLabel = uilabel(reduceLayout);
            OutputWeightLabel.Layout.Row = 5;
            OutputWeightLabel.Layout.Column = 1;
            OutputWeightLabel.Text = getString(message('Control:mrtool:PODOptionsOutputWeight'));
            OutputWeightLabel.Tag = 'MR_SparsePOOOptions_OutputWeightLabel';
            OutputWeightEditField = uieditfield(reduceLayout);
            OutputWeightEditField.Layout.Row = 5;
            OutputWeightEditField.Layout.Column = 3;
            OutputWeightEditField.Tooltip = getString(message('Control:mrtool:PODOptionsOutputWeightTooltip'));
            OutputWeightEditField.Tag = 'MR_SparsePOOOptions_OutputWeightEditField';
            OutputWeightEditField.Value = '[]';
            this.OutputWeight = [];

            %% Advanced
            AdvancedAccordian = matlab.ui.container.internal.Accordion('Parent',reduceLayout);
            AdvancedAccordian.Layout.Row = 6;
            AdvancedAccordian.Layout.Column = [1 3];
            AdvancedPanel = matlab.ui.container.internal.AccordionPanel('Parent',AdvancedAccordian);
            AdvancedPanel.Title = getString(message('Control:mrtool:OptionsAdvanced'));
            AdvancedPanel.Collapsed = true;
            this.AdvancedLayout = uigridlayout(AdvancedPanel,[3 3]);
            this.AdvancedLayout.RowHeight = {'fit','fit','fit'};
            this.AdvancedLayout.ColumnWidth = {'fit','1x','fit'}; 

            % RankTol
            RankTolLabel = uilabel(this.AdvancedLayout);
            RankTolLabel.Layout.Row = 1;
            RankTolLabel.Layout.Column = 1;
            RankTolLabel.Text = getString(message('Control:mrtool:PODOptionsRankTolLabel'));
            RankTolLabel.Tag = 'MR_SparsePODOptions_RankTolLabel';
            RankTolEditField = uieditfield(this.AdvancedLayout,'numeric');
            RankTolEditField.Layout.Row = 1;
            RankTolEditField.Layout.Column = 3;   
            RankTolEditField.Value = 1e-6;
            RankTolEditField.Limits = [0 1];
            RankTolEditField.LowerLimitInclusive = 'off';
            RankTolEditField.UpperLimitInclusive = 'off';
            RankTolEditField.Tooltip = getString(message('Control:mrtool:PODOptionsRankTolTooltip'));
            RankTolEditField.Tag = 'MR_SparsePODOptions_RankTolEditField'; 

            % CompressTol
            CompressTolLabel = uilabel(this.AdvancedLayout);
            CompressTolLabel.Layout.Row = 2;
            CompressTolLabel.Layout.Column = 1;
            CompressTolLabel.Text = getString(message('Control:mrtool:PODOptionsCompressTolLabel'));
            CompressTolLabel.Tag = 'MR_SparsePODOptions_CompressTolLabel';
            CompressTolEditField = uieditfield(this.AdvancedLayout,'numeric');
            CompressTolEditField.Layout.Row = 2;
            CompressTolEditField.Layout.Column = 3;   
            CompressTolEditField.Value = 1e-3;
            CompressTolEditField.Limits = [0 1];
            CompressTolEditField.LowerLimitInclusive = 'off';
            CompressTolEditField.UpperLimitInclusive = 'off';
            CompressTolEditField.Tooltip = getString(message('Control:mrtool:PODOptionsCompressTolTooltip'));
            CompressTolEditField.Tag = 'MR_SparsePODOptions_CompressTolEditField'; 

            % NumStep
            NumStepLabel = uilabel(this.AdvancedLayout);
            NumStepLabel.Layout.Row = 3;
            NumStepLabel.Layout.Column = 1;
            NumStepLabel.Text = getString(message('Control:mrtool:PODOptionsNumStepLabel'));
            NumStepLabel.Tag = 'MR_SparsePODOptions_NumStepLabel';
            NumStepEditField = uieditfield(this.AdvancedLayout,'numeric');
            NumStepEditField.Layout.Row = 3;
            NumStepEditField.Layout.Column = 3;   
            NumStepEditField.Value = 100;
            NumStepEditField.Limits = [1 Inf];
            NumStepEditField.RoundFractionalValues = true;
            NumStepEditField.UpperLimitInclusive = 'off';
            NumStepEditField.Tooltip = getString(message('Control:mrtool:PODOptionsNumStepTooltip'));
            NumStepEditField.Tag = 'MR_SparsePODOptions_NumStepEditField'; 

            % add to widgets
            this.Widgets.TitleLabel = TitleLabel;
            this.Widgets.InitLabel = InitLabel;
            this.Widgets.FreqVectorLabel = FreqVectorLabel;
            this.Widgets.FreqVectorEditField = FreqVectorEditField;
            this.Widgets.MethodCheckbox = MethodCheckbox;
            this.Widgets.AlgorithmLabel = AlgorithmLabel;
            this.Widgets.AlgorithmDropDown = AlgorithmDropDown;
            this.Widgets.InputWeightLabel = InputWeightLabel;
            this.Widgets.InputWeightEditField = InputWeightEditField;
            this.Widgets.OutputWeightLabel = OutputWeightLabel;
            this.Widgets.OutputWeightEditField = OutputWeightEditField;
            this.Widgets.CenterCheckbox = CenterCheckbox;
            this.Widgets.PODDataLabel = PODDataLabel;
            this.Widgets.FocusLabel = FocusLabel;
            this.Widgets.FocusEditField = FocusEditField;
            this.Widgets.ExcitationLabel = ExcitationLabel;
            this.Widgets.ExcitationDropDown = ExcitationDropDown;
            this.Widgets.AdvancedPanel = AdvancedPanel;
            this.Widgets.RankTolLabel = RankTolLabel;
            this.Widgets.RankTolEditField = RankTolEditField;
            this.Widgets.CompressTolLabel = CompressTolLabel;
            this.Widgets.CompressTolEditField = CompressTolEditField;
            this.Widgets.NumStepLabel = NumStepLabel;
            this.Widgets.NumStepEditField = NumStepEditField;
        end

        function connectUI(this)
            connectUI@mrtool.dialogs.AbstractOptionsDialog(this);
            weakThis = matlab.lang.WeakReference(this);
            this.Widgets.FreqVectorEditField.ValueChangedFcn = @(es,ed) cbFreqVectorChanged(weakThis.Handle,ed);
            this.Widgets.AlgorithmDropDown.ValueChangedFcn = @(es,ed) cbAlgorithmDropDownChanged(weakThis.Handle,ed.Value);
            this.Widgets.FocusEditField.ValueChangedFcn = @(es,ed) cbFocusChanged(weakThis.Handle,ed);
            this.Widgets.InputWeightEditField.ValueChangedFcn = @(es,ed) cbInputWeightChanged(weakThis.Handle,ed);
            this.Widgets.OutputWeightEditField.ValueChangedFcn = @(es,ed) cbOutputWeightChanged(weakThis.Handle,ed);
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

        function cbAlgorithmDropDownChanged(this,value)
            switch value
                case 'compress'
                    this.AdvancedLayout.RowHeight{2} = 'fit';
                    this.Widgets.CompressTolLabel.Visible = 'on';
                    this.Widgets.CompressTolEditField.Visible = 'on';
                otherwise
                    this.AdvancedLayout.RowHeight{2} = 0;
                    this.Widgets.CompressTolLabel.Visible = 'off';
                    this.Widgets.CompressTolEditField.Visible = 'off';
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
                        isreal(this.Focus) && all(this.Focus>0) && all(isfinite(this.Focus)) &&...
                        length(this.Focus) == 2 && this.Focus(1) < this.Focus(2)))
                    this.Focus = oldFocus;
                    this.Widgets.FocusEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,getString(message('Control:mrtool:PODErrorFocus')),getString(message('Control:mrtool:Error')));
                    end
                end
            end
        end

        function cbInputWeightChanged(this,ed)
            oldWeight = this.InputWeight;
            try
                this.InputWeight = evalin('base',this.Widgets.InputWeightEditField.Value);
            catch ME
                this.Widgets.InputWeightEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                end
                return;
            end
            [~,nu] = iosize(this.ToolData.TargetSystem);
            if (isempty(this.InputWeight) ...
                    || ~(isnumeric(this.InputWeight) && ismatrix(this.InputWeight) && ...
                    isreal(this.InputWeight) && all(isfinite(this.InputWeight),'all') &&...
                    size(this.InputWeight,1)==nu))
                this.InputWeight = oldWeight;
                this.Widgets.InputWeightEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,getString(message('Control:mrtool:PODErrorInputWeight',nu)),getString(message('Control:mrtool:Error')));
                end
            end
        end

        function cbOutputWeightChanged(this,ed)
            oldWeight = this.OutputWeight;
            try
                this.OutputWeight = evalin('base',this.Widgets.OutputWeightEditField.Value);
            catch ME
                this.Widgets.OutputWeightEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                end
                return;
            end
            [ny,~] = iosize(this.ToolData.TargetSystem);
            if (isempty(this.OutputWeight) ...
                    || ~(isnumeric(this.OutputWeight) && ismatrix(this.OutputWeight) && ...
                    isreal(this.OutputWeight) && all(isfinite(this.OutputWeight),'all') &&...
                    size(this.OutputWeight,2)==ny))
                this.OutputWeight = oldWeight;
                this.Widgets.OutputWeightEditField.Value = ed.PreviousValue;
                if strcmp(this.UIFigure.Visible,'on')
                    uialert(this.UIFigure,getString(message('Control:mrtool:PODErrorOutputWeight',ny)),getString(message('Control:mrtool:Error')));
                end
            end
        end

        function cbHelpButtonPushed(this) %#ok<MANU>
            helpview('control','ModelReducerProperOrthogonalDecompositionOptions','CSHelpWindow');            
        end

        function cbCloseEvent(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            close(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
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
            Options = mor.ProperOrthogonalDecompositionOptions;
            Options.Algorithm = this.Widgets.AlgorithmDropDown.Value;
            Options.InputWeight = this.InputWeight;
            Options.OutputWeight = this.OutputWeight;
            Options.Center = this.Widgets.CenterCheckbox.Value;
            Options.RankTol = this.Widgets.RankTolEditField.Value;
            Options.CompressTol = this.Widgets.CompressTolEditField.Value;
            Options.Focus = this.Focus;
            Options.Excitation = this.Widgets.ExcitationDropDown.Value;
            Options.NumStep = this.Widgets.NumStepEditField.Value;
            try
                this.ToolData.Options = Options;
            catch ME
                uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')))
                CommenceProcess = false;
            end
        end
    end
end

