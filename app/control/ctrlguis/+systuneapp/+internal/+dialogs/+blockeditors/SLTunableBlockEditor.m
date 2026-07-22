classdef SLTunableBlockEditor < systuneapp.internal.dialogs.blockeditors.AbstractTunableBlockEditor
    % SLTUNABLEBLOCKEDITOR Edit the parameterization of an MLTunableBlockEditor object

    %   Copyright 2013-2021 The MathWorks, Inc.
    
    %% Private Properties
    properties(Access = private)
        RateConversionPanel
        RateConversionDescription
        SampleTimeLabel
        SampleTimeValueLabel
        NonPIDOptionsLayout
        RateConversionMethodLabel
        RateConversionDropdown
        PrewarpFrequencyLabel
        PrewarpFrequencyEditfield
        PrewarpFrequencyUnitLabel
        PIDOptionsLayout
        IntegratorMethodLabel
        IntegratorMethodDropdown
        FilterMethodLabel
        FilterMethodDropdown
    end

    %% Public Methods
    methods
        function this = SLTunableBlockEditor(tunableBlock)
            this = this@systuneapp.internal.dialogs.blockeditors.AbstractTunableBlockEditor(tunableBlock);
            this.Name = sprintf('dlgSLTunableBlockEditor_%s', this.VariableName);
            this.Title = [getString(message('Controllib:gui:SLTunableBlock_DlgTitle')), ...
                ' - ',this.VariableName];
        end

        function updateVariableValue(this,variableValue)
            oldLTI = this.VariableValue;
            swapPanels = ~isequal(class(oldLTI),class(variableValue));
            this.InitialVariableValue = variableValue;
            updateLTIEditorPanel(this,swapPanels);
        end

        function updateUI(this)
            % LTI Editor
            updateLTIEditorPanel(this,true);
            % Rate Conversion
            updateRateConversionPanel(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function buildUI(this)
            figureGrid = uigridlayout(this.UIFigure,[3,1]);
            figureGrid.RowHeight = {'fit','1x','fit'};
            figureGrid.ColumnWidth = {'1x'};
            this.FigureGrid = figureGrid;

            % Name and Type Layout
            nameTypeGrid = uigridlayout(figureGrid,[1 6]);
            nameTypeGrid.ColumnWidth = {'fit','fit',10,'fit','fit','1x'};
            nameTypeGrid.RowHeight = {'fit'};
            nameTypeGrid.Padding = 0;
            % Name
            this.NameText = uilabel(nameTypeGrid,"Text",...
                getString(message('Controllib:gui:lblLTIBlockEditor_Name')),...
                "FontWeight",'bold');
            this.NameText.Layout.Row = 1;
            this.NameText.Layout.Column = 1;
            this.NameLabel = uilabel(nameTypeGrid,"Text",this.VariableValue.Name);
            this.NameLabel.Layout.Row = 1;
            this.NameLabel.Layout.Column = 2;
            
            % Type
            this.ParameterizationLabel = uilabel(nameTypeGrid,"Text",...
                getString(message('Controllib:gui:lblLTIBlockEditor_Parameterization')),...
                "FontWeight",'bold');
            this.ParameterizationLabel.Layout.Row = 1;
            this.ParameterizationLabel.Layout.Column = 4;
            this.ParameterizationDropdown = uidropdown(nameTypeGrid);
            this.ParameterizationDropdown.Layout.Row = 1;
            this.ParameterizationDropdown.Layout.Column = 5;
            this.ParameterizationDropdown.Items = getParameterizationDropdownItems(this);
            
            % Scrollable sub grid
            figureSubGrid = uigridlayout(figureGrid,[3 1]);
            figureSubGrid.RowHeight = {'fit','fit','fit'};
            figureSubGrid.ColumnWidth = {'1x'};
            figureSubGrid.Padding = 0;
            figureSubGrid.Layout.Row = 2;
            figureSubGrid.Layout.Column = 1;
            figureSubGrid.Scrollable = true;

            % Editor Grid
            this.EditorGrid = uigridlayout(figureSubGrid,[1 1]);
            this.EditorGrid.Layout.Row = 2;
            this.EditorGrid.Layout.Column = 1;
            this.EditorGrid.Padding = 0;
            this.EditorGrid.RowHeight = {'fit'};
            % Rate Conversion Panel
            accRateConversion = matlab.ui.container.internal.Accordion('Parent',figureSubGrid);
            accRateConversion.Layout.Row = 3;
            accRateConversion.Layout.Column = 1;
            this.RateConversionPanel = accRateConversion;
            pnlRateConversion = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accRateConversion,'Collapsed',true);
            pnlRateConversion.Title = ...
                getString(message('Controllib:gui:lblSLTunableBlock_RateConversionOptions'));
            rateConversionLayout = uigridlayout(pnlRateConversion,[3,2]);
            rateConversionLayout.RowHeight = {'fit','fit','fit'};
            rateConversionLayout.ColumnWidth = {'fit','1x'};
            rateConversionLayout.Padding = 0;
            this.RateConversionDescription = uilabel(rateConversionLayout,"Text",...
                getString(message('Controllib:gui:lblSLTunableBlock_RateConversionDescription')));
            this.RateConversionDescription.WordWrap = 'on';
            this.RateConversionDescription.Layout.Row = 1;
            this.RateConversionDescription.Layout.Column = [1 2];
            
            % Sample Time
            this.SampleTimeLabel = uilabel(rateConversionLayout,"Text",...
                getString(message('Controllib:gui:lblSLTunableBlock_SampleTime')));
            this.SampleTimeLabel.Layout.Row = 2;
            this.SampleTimeLabel.Layout.Column = 1;
            this.SampleTimeValueLabel = uilabel(rateConversionLayout);
            this.SampleTimeValueLabel.Layout.Row = 2;
            this.SampleTimeValueLabel.Layout.Column = 2;

            % Rate conversion methods
            items = getValidRateConversions(this.TunableBlock);
            items = systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor.getStringFromRateConversionMethod(items);
            [bool, idx] = ismember(getString(message('Controllib:gui:lblSLTunableBlock_Tustin')), items);
            % If tustin is included in the list, include tustin with
            % prewarping too
            if bool
                items = [items(1:idx); {getString(message('Controllib:gui:lblSLTunableBlock_TustinWithPreWarp'))}; items(idx+1:end)];
            end
            
            % Matched should be available only for siso systems
            [bool, idx] = ismember(getString(message('Controllib:gui:lblSLTunableBlock_Matched')), items);
            if bool && any(this.TunableBlock.iosize ~= [1 1])
                % If matched is found for a MIMO system
                items = [items(1:idx-1); items(idx+1:end)];
            end
            
            % Non PID Block options
            this.NonPIDOptionsLayout = uigridlayout(rateConversionLayout,[1 4]);
            this.NonPIDOptionsLayout.RowHeight = {'fit','fit'};
            this.NonPIDOptionsLayout.ColumnWidth = {'fit','fit','1x','fit'};
            this.NonPIDOptionsLayout.Padding = [10 0 10 0];
            this.NonPIDOptionsLayout.Visible = false;
            this.NonPIDOptionsLayout.Layout.Row = 3;
            this.NonPIDOptionsLayout.Layout.Column = [1 2];
            this.RateConversionMethodLabel = uilabel(this.NonPIDOptionsLayout,...
                "Text",getString(message('Controllib:gui:lblSLTunableBlock_RateConversionMechanism')));
            this.RateConversionMethodLabel.Layout.Row = 1;
            this.RateConversionMethodLabel.Layout.Column = 1;
            this.RateConversionDropdown = uidropdown(this.NonPIDOptionsLayout);
            this.RateConversionDropdown.Layout.Row = 1;
            this.RateConversionDropdown.Layout.Column = 2;
            this.RateConversionDropdown.Items = items;
%             this.PrewarpFrequencyLabel = uilabel(this.NonPIDOptionsLayout,"Text",...
%                 'PreWarping frequency');
%             this.PrewarpFrequencyLabel.Layout.Row = 2;
%             this.PrewarpFrequencyLabel.Layout.Column = 1;
            this.PrewarpFrequencyEditfield = uieditfield(this.NonPIDOptionsLayout);
            this.PrewarpFrequencyEditfield.Layout.Row = 1;
            this.PrewarpFrequencyEditfield.Layout.Column = 3;
            this.PrewarpFrequencyEditfield.Value = '10';
            this.PrewarpFrequencyUnitLabel = uilabel(this.NonPIDOptionsLayout,...
                "Text",'rad/s');
            this.PrewarpFrequencyUnitLabel.Layout.Row = 1;
            this.PrewarpFrequencyUnitLabel.Layout.Column = 4;
            
            % PID Block options
            this.PIDOptionsLayout = uigridlayout(rateConversionLayout,[1 4]);
            this.PIDOptionsLayout.RowHeight = {'fit'};
            this.PIDOptionsLayout.ColumnWidth = {'fit','1x','fit','1x'};
            this.PIDOptionsLayout.Padding = [10 0 10 0];
            this.PIDOptionsLayout.Visible = true;
            this.PIDOptionsLayout.Layout.Row = 3;
            this.PIDOptionsLayout.Layout.Column = [1 2];
            this.IntegratorMethodLabel = uilabel(this.PIDOptionsLayout,...
                "Text",getString(message('Controllib:gui:lblSLTunableBlock_RateConversionIF')));
            this.IntegratorMethodLabel.Layout.Row = 1;
            this.IntegratorMethodLabel.Layout.Column = 1;
            this.IntegratorMethodDropdown = uidropdown(this.PIDOptionsLayout);
            this.IntegratorMethodDropdown.Layout.Row = 1;
            this.IntegratorMethodDropdown.Layout.Column = 2;
            this.IntegratorMethodDropdown.Items = items;
            this.FilterMethodLabel = uilabel(this.PIDOptionsLayout,"Text",...
                getString(message('Controllib:gui:lblSLTunableBlock_RateConversionDF')));
            this.FilterMethodLabel.Layout.Row = 1;
            this.FilterMethodLabel.Layout.Column = 3;
            this.FilterMethodDropdown = uidropdown(this.PIDOptionsLayout);
            this.FilterMethodDropdown.Layout.Row = 1;
            this.FilterMethodDropdown.Layout.Column = 4;
            this.FilterMethodDropdown.Items = items;

            % Button Panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(figureGrid,["OK","Cancel","Help"]);
            widget = getWidget(this.ButtonPanel);
            widget.Layout.Row = 3;
            widget.Layout.Column = 1;

            % Size Dialog
            this.UIFigure.Position(3:4) = this.DialogSize;
        end

        function connectUI(this)
            connectUI@systuneapp.internal.dialogs.blockeditors.AbstractTunableBlockEditor(this);
            this.ParameterizationDropdown.ValueChangedFcn = ...
                @(es,ed) cbParameterizationDropdownValueChanged(this);
            this.RateConversionDropdown.ValueChangedFcn = ...
                @(es,ed) cbRateConversionDropdownValueChanged(this);
            
        end

        function updateLTIEditorPanel(this,swapPanels)
            % Change pointer to busy
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow('nocallbacks');
            try
                % Swap Panels if needed
                if swapPanels
                    % Delete current editor
                    delete(this.Editor);
                    % Create new editor based on class of tunable variable
                    switch class(this.InitialVariableValue)
                        case {'tunablePID','ltiblock.pid'}
                            this.Editor = systuneapp.internal.panels.blockeditors.PIDEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblPIDEditor_Type'));
                        case {'tunableSS','ltiblock.ss'}
                            this.Editor = systuneapp.internal.panels.blockeditors.SSEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblSSEditor_Type'));
                        case {'tunableTF','ltiblock.tf'}
                            this.Editor = systuneapp.internal.panels.blockeditors.TFEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblTFEditor_Type'));
                        case {'tunablePID2','ltiblock.pid2'}
                            this.Editor = systuneapp.internal.panels.blockeditors.PID2Editor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblPID2Editor_Type'));
                        case {'tunableGain','ltiblock.gain'}
                            this.Editor = systuneapp.internal.panels.blockeditors.GainEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblGainEditor_Type'));
                        case {'genss'}
                            this.Editor = systuneapp.internal.panels.blockeditors.GenssEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblCustomEditor_Type'));
                    end

                    % Create widget
                    getWidget(this.Editor);
                else
                    % Do not swap panel. Update existing panel.
                    this.Editor.VariableValue = this.InitialVariableValue;
                end
            catch ex
                controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
                drawnow('nocallbacks');
                throw(ex);
            end

            % Change pointer back to 'normal'
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow('nocallbacks');
        end

        function cbParameterizationDropdownValueChanged(this)
            oldLTI = this.VariableValue;
            switch this.ParameterizationDropdown.Value
                case getString(message('Controllib:gui:lblPIDEditor_Type'))
                    try
                        this.InitialVariableValue = tunablePID(this.TunableBlock.Name,oldLTI);
                    catch
                        this.InitialVariableValue = tunablePID(this.TunableBlock.Name, 'pid');
                    end
                case getString(message('Controllib:gui:lblPID2Editor_Type'))
                    try
                        this.InitialVariableValue = tunablePID2(this.TunableBlock.Name,oldLTI);
                    catch
                        this.InitialVariableValue = tunablePID2(this.TunableBlock.Name,'pid');
                    end
                case getString(message('Controllib:gui:lblSSEditor_Type'))
                    try
                        this.InitialVariableValue = tunableSS(this.TunableBlock.Name,oldLTI);
                    catch
                        this.InitialVariableValue = tunableSS(this.TunableBlock.Name,tf(ones(this.TunableBlock.iosize)));
                    end
                case getString(message('Controllib:gui:lblTFEditor_Type'))
                    try
                        this.InitialVariableValue = tunableTF(this.TunableBlock.Name,oldLTI);
                    catch
                        this.InitialVariableValue = tunableTF(this.TunableBlock.Name,tf(ones(this.TunableBlock.iosize)));
                    end
                case getString(message('Controllib:gui:lblGainEditor_Type'))
                    try
                        this.InitialVariableValue = tunableGain(this.TunableBlock.Name,oldLTI);
                    catch
                        this.InitialVariableValue = tunableGain(this.TunableBlock.Name,ones(this.TunableBlock.iosize));
                    end
                case getString(message('Controllib:gui:lblRealpEditor_Type'))
                    try
                        this.InitialVariableValue = realp(this.TunableBlock.Name,oldLTI);
                    catch
                        this.InitialVariableValue = realp(this.TunableBlock.Name,ones(this.TunableBlock.iosize));
                    end
                case getString(message('Controllib:gui:lblCustomEditor_Type'))
                    tempVal = genss(tf(ones(this.TunableBlock.iosize)));
                    tempVal.Name = this.TunableBlock.Name;
                    this.InitialVariableValue = tempVal;
            end
            swapPanels = ~isequal(oldLTI,this.InitialVariableValue);
            updateLTIEditorPanel(this,swapPanels);
        end

        function cbRateConversionDropdownValueChanged(this)
            if strcmpi(this.RateConversionDropdown.Value, ...
                    getString(message('Controllib:gui:lblSLTunableBlock_TustinWithPreWarp')))
                this.PrewarpFrequencyEditfield.Visible = 'on';
                this.PrewarpFrequencyUnitLabel.Visible = 'on';
            else
                this.PrewarpFrequencyEditfield.Visible = 'off';
                this.PrewarpFrequencyUnitLabel.Visible = 'off';
            end
        end

        function cbOKButton(this)
            try
                this.TunableBlockChangedListener.Enabled = false;
                variableValue = this.VariableValue;
                if ~isa(variableValue,'realp')
                    variableValue.UserData = generateMATLABCode(this.Editor,this.VariableName,false);
                end
                setParameterization(this.TunableBlock,variableValue);
                
                % Rate Conversion
                RC = getValidRateConversions(this.TunableBlock);
                isDiscretePID = isa(this.TunableBlock,'controldesign.blockconfig.GenericPID') && ~isequal(getTs(this.TunableBlock),0);
                if this.TunableBlock.Ts ~= getTs(this.TunableBlock) && ...
                        ~isempty(RC) && ~isstatic(this.TunableBlock) && ~isDiscretePID && ~isa(this.TunableBlock, 'controldesign.blockconfig.DTFRealZero')
                    if isa(this.TunableBlock,'controldesign.blockconfig.GenericPID')
                        % Special handling needed for PID
                        RC_IF = systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor.getRateConversionMethodFromString(...
                            this.IntegratorMethodDropdown.Value);
                        RC_DF = systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor.getRateConversionMethodFromString(...
                            this.FilterMethodDropdown.Value);
                        setRateConversion(this.TunableBlock, RC_IF, RC_DF);
                    else
                        % Get the rate conversion method and the pre-warp frequency
                        RateConversionMethod = ...
                            systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor.getRateConversionMethodFromString(...
                            this.RateConversionDropdown.Value);
                        if strcmpi(this.RateConversionDropdown.Value, getString(message('Controllib:gui:lblSLTunableBlock_TustinWithPreWarp')))
                            PreWarpFrequency = evalin('base',this.PrewarpFrequencyEditfield.Value);
                        else
                            PreWarpFrequency = 0;
                        end
                        setRateConversion(this.TunableBlock, RateConversionMethod, PreWarpFrequency);
                    end
                end
                close(this);
                delete(this);
            catch ex
                uialert(this.UIFigure,ex.message,getString(message('Controllib:gui:SLTunableBlock_DlgTitle')));
            end
        end

        function updateRateConversionPanel(this)
            % Rate conversion options are not applicable:
            %1. If the tuning sample time is equal to the block sample
            %time
            %2. For Model Discretizer blocks
            %3. For Gain blocks (Static)
            %4. For discrete PID Blocks (The rate conversion is
            %specified in the Simulink block mask and cannot be
            %modified here)
            
            
            % set rate conversion combo-box (Option is available for any
            % block that is not a Model Discretizer block or a  block.
            
            % this.TunableBlock.Ts is the sample time of the paramterized
            % value
            % getTs(this.TunableBlock) returns the sample time of the
            % original Simulink block

            RC = getValidRateConversions(this.TunableBlock);
            isDiscretePID = isa(this.TunableBlock,'controldesign.blockconfig.GenericPID') && ~isequal(getTs(this.TunableBlock),0);
            
            if this.TunableBlock.Ts ~= getTs(this.TunableBlock) && ...
                    ~isempty(RC) && ~isstatic(this.TunableBlock) && ~isDiscretePID && ~isa(this.TunableBlock, 'controldesign.blockconfig.DTFRealZero')
                
                if isa(this.TunableBlock,'controldesign.blockconfig.GenericPID')
                    [RC_IF,RC_DF] = getRateConversion(this.TunableBlock);
                    this.IntegratorMethodDropdown.Value = ...
                        systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor.getStringFromRateConversionMethod(RC_IF);
                    this.FilterMethodDropdown.Value = ...
                        systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor.getStringFromRateConversionMethod(RC_DF);
                    this.NonPIDOptionsLayout.Visible = 'off';
                    this.PIDOptionsLayout.Visible = 'on';
                else
                    [RateConversionMethod,PreWarpFreq] = getRateConversion(this.TunableBlock);
                    this.RateConversionDropdown.Value = ...
                        systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor.getStringFromRateConversionMethod(RateConversionMethod, PreWarpFreq);
                    cbRateConversionDropdownValueChanged(this);
                    % RateConversionOptions = this.TunableBlock.getRateConversionOptions;
                    if PreWarpFreq ~= 0
                        this.PrewarpFrequencyEditfield.Value = mat2str(PreWarpFreq);
                    end
                    this.NonPIDOptionsLayout.Visible = 'on';
                    this.PIDOptionsLayout.Visible = 'off';
                end
                this.RateConversionPanel.Visible = 'on';
                this.SampleTimeValueLabel.Text = [mat2str(this.TunableBlock.Ts), ' ', ...
                    getString(message('Controllib:gui:strSeconds'))];
            else
                this.RateConversionPanel.Visible = 'off';
            end
        end
    end

    methods (Static = true)
        function Method = getRateConversionMethodFromString(String)
            switch String
                case getString(message('Controllib:gui:lblSLTunableBlock_Trapezoidal'))
                    Method = 'Trapezoidal';
                case getString(message('Controllib:gui:lblSLTunableBlock_ForwardEuler'))
                    Method = 'ForwardEuler';
                case getString(message('Controllib:gui:lblSLTunableBlock_BackwardEuler'))
                    Method = 'BackwardEuler';
                case getString(message('Controllib:gui:lblSLTunableBlock_ZOH'))
                    Method = 'zoh';
                case getString(message('Controllib:gui:lblSLTunableBlock_FOH'))
                    Method = 'foh';
                case getString(message('Controllib:gui:lblSLTunableBlock_Tustin'))
                    Method = 'tustin';
                case getString(message('Controllib:gui:lblSLTunableBlock_TustinWithPreWarp'))
                    Method = 'tustin';
                case getString(message('Controllib:gui:lblSLTunableBlock_Matched'))
                    Method = 'matched';
            end
        end        
        
        function String = getStringFromRateConversionMethod(Method, varargin)
            String = cell(0,1);
            if ischar(Method)
                Method = {Method};
                CharOut = true;
            else
                CharOut = false;
            end
            for ct = 1:numel(Method)
                switch Method{ct}
                    case 'Trapezoidal'
                        String{ct,:} = getString(message('Controllib:gui:lblSLTunableBlock_Trapezoidal'));
                    case 'ForwardEuler'
                        String{ct} = getString(message('Controllib:gui:lblSLTunableBlock_ForwardEuler'));
                    case 'BackwardEuler'
                        String{ct,:} = getString(message('Controllib:gui:lblSLTunableBlock_BackwardEuler'));
                    case 'zoh'
                        String{ct,:} = getString(message('Controllib:gui:lblSLTunableBlock_ZOH'));
                    case 'foh'
                        String{ct,:} = getString(message('Controllib:gui:lblSLTunableBlock_FOH'));
                    case 'tustin'
                        String{ct,:} = getString(message('Controllib:gui:lblSLTunableBlock_Tustin'));
                        if nargin==2 && varargin{1} ~= 0
                            String{ct,:} = getString(message('Controllib:gui:lblSLTunableBlock_TustinWithPreWarp'));
                        end
                    case 'matched'
                        String{ct,:} = getString(message('Controllib:gui:lblSLTunableBlock_Matched'));
                end
            end
            if CharOut
                String = String{1,:};
            end
            
        end
    end

    methods (Access = private)
        function items = getParameterizationDropdownItems(this)
            iosize = this.TunableBlock.iosize;
            
            if isequal(iosize,[1 1]) || isa(this.TunableBlock,'controldesign.blockconfig.PIDBlock1DOF')
                items = {getString(message('Controllib:gui:lblPIDEditor_Type')),getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblTFEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type')), getString(message('Controllib:gui:lblCustomEditor_Type'))};
            elseif isequal(iosize,[1 2]) || isa(this.TunableBlock,'controldesign.blockconfig.PIDBlock2DOF')
                items = {getString(message('Controllib:gui:lblPID2Editor_Type')),getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type')), getString(message('Controllib:gui:lblCustomEditor_Type'))};
            else
                items = {getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type')), getString(message('Controllib:gui:lblCustomEditor_Type'))};
            end
        end

        function setParameterizationDropdownValue(this)
            switch class(this.VariableValue)

            end
        end
    end
    %% Hidden Methods
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets = qeGetWidgets@systuneapp.internal.dialogs.blockeditors.AbstractTunableBlockEditor(this);
            widgets.RateConversionPanel = this.RateConversionPanel;
            widgets.RateConversionDropdown = this.RateConversionDropdown;
            widgets.RateConversionDescription = this.RateConversionDescription;
            widgets.RateConversionMethodLabel = this.RateConversionMethodLabel;
            widgets.SampleTimeLabel = this.SampleTimeLabel;
            widgets.SampleTimeValueLabel = this.SampleTimeValueLabel;
            widgets.NonPIDOptionsLayout = this.NonPIDOptionsLayout;
            widgets.PIDOptionsLayout = this.PIDOptionsLayout;
            widgets.PrewarpFrequencyLabel = this.PrewarpFrequencyLabel;
            widgets.PrewarpFrequencyEditfield = this.PrewarpFrequencyEditfield;
            widgets.PrewarpFrequencyUnitLabel = this.PrewarpFrequencyUnitLabel;
            widgets.IntegratorMethodLabel = this.IntegratorMethodLabel;
            widgets.IntegratorMethodDropdown = this.IntegratorMethodDropdown;
            widgets.FilterMethodLabel = this.FilterMethodLabel;
            widgets.FilterMethodDropdown = this.FilterMethodDropdown;
        end

        function qeParameterizationDropdownValueChanged(this)
            cbParameterizationDropdownValueChanged(this)
        end

        function qeRateConversionDropdownValueChanged(this)
            cbRateConversionDropdownValueChanged(this)
        end
    end
end