classdef (Hidden) LinearizationOptionsGC < controllib.ui.internal.dialog.AbstractDialog
    % Graphical component for linearization options of Control System Tuner App.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Access = protected)
        TCPeer
        
        RButtonGroup
        ContinuousRButton
        DiscreteRButton
        
        DiscreteEditField
        MethodDropdown
        UpsampleCheckbox
        PrewarpPanel
        PrewarpEditField
        
        HelpButton
        OKButton
        CancelButton
    end
    
    methods
        function this = LinearizationOptionsGC(tcpeer)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = 'CSTuner_LinearizationOptions';
            this.Title = getString(message('Control:systunegui:LinearizationOptionsTitle'));
            this.TCPeer = tcpeer;
        end
        
        function this = updateUI(this)
            Options = getOptions(this.TCPeer);
            
            % Update sample time field
            if Options.SampleTime > 0
                this.DiscreteRButton.Value = 1;
                this.ContinuousRButton.Value = 0;
                this.DiscreteEditField.Enable = true;
                this.DiscreteEditField.Value = Options.SampleTime;
            else
                this.DiscreteRButton.Value = 0;
                this.ContinuousRButton.Value = 1;
                this.DiscreteEditField.Enable = false;
            end
            
            % Update prewarp frequency
            this.MethodDropdown.Value = getRateConversionLabel(this,Options.RateConversionMethod);
            if contains(Options.RateConversionMethod,{'upsampling_zoh','upsampling_tustin','upsampling_prewarp'})
                this.UpsampleCheckbox.Value = true;
            else
                this.UpsampleCheckbox.Value = false;
            end
            setPrewarpPanel(this);
            this.PrewarpEditField.Value = Options.PreWarpFreq;
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % GridLayout
            FigureGrid = uigridlayout(this.UIFigure, [3 1]);
            FigureGrid.RowHeight = {120,'1x','fit'};
            FigureGrid.RowSpacing = 0;
            
            % Working Domain View
            DomainPanel = uipanel(FigureGrid,'Title',getString(message('Control:systunegui:LinearizationOptionsTuningDomain')));
            DomainPanel.Layout.Row = 1;
            DomainPanel.Layout.Column = 1;
            DomainPanel.FontWeight = 'bold';
            DomainPanel.BorderType = 'none';
            
            this.RButtonGroup = uibuttongroup(DomainPanel);
            this.RButtonGroup.SelectionChangedFcn = @(es,ed) switchContinuousDiscrete(this,es);
            this.RButtonGroup.BorderType = 'none';
            this.RButtonGroup.Position = [10 10 350 90];
            
            this.ContinuousRButton = uiradiobutton(this.RButtonGroup);
            this.ContinuousRButton.Text = getString(message('Control:systunegui:LinearizationOptionsContinuous'));
            this.ContinuousRButton.Position = [10 50 160 20];
            
            this.DiscreteRButton = uiradiobutton(this.RButtonGroup);
            this.DiscreteRButton.Text = getString(message('Control:systunegui:LinearizationOptionsDiscrete'));
            this.DiscreteRButton.Position = [10 10 160 20];
            
            this.DiscreteEditField = uieditfield(this.RButtonGroup,'Numeric');
            this.DiscreteEditField.Position = [170 10 110 20];
            this.DiscreteEditField.Value = 1;
            this.DiscreteEditField.Enable = false;
            this.DiscreteEditField.ValueDisplayFormat = '%11.4g s';
            this.DiscreteEditField.Limits = [0 Inf];
            this.DiscreteEditField.UpperLimitInclusive = 'off';
            this.DiscreteEditField.LowerLimitInclusive = 'off';
            
            % Rate Conversions View
            ConversionsPanel = uipanel(FigureGrid,'Title',getString(message('Control:systunegui:LinearizationOptionsRateConversions')));
            ConversionsPanel.Layout.Row = 2;
            ConversionsPanel.Layout.Column = 1;
            ConversionsPanel.FontWeight = 'bold';
            ConversionsPanel.BorderType = 'none';
            
            ConversionsGrid = uigridlayout(ConversionsPanel,[2 1]);
            ConversionsGrid.ColumnWidth = {'fit'};
            
            MethodGrid = uigridlayout(ConversionsGrid, [1 2]);
            MethodGrid.Padding = [0 5 0 0];
            MethodGrid.Layout.Row = 1;
            MethodGrid.Layout.Column = 1;
            MethodGrid.ColumnWidth = {'fit','1x','fit'};
            
            MethodLabel = uilabel(MethodGrid);
            MethodLabel.Layout.Row = 1;
            MethodLabel.Layout.Column = 1;
            MethodLabel.Text = getString(message('Control:systunegui:LinearizationOptionsRateConversionLabel'));
            
            this.MethodDropdown = uidropdown(MethodGrid);
            this.MethodDropdown.Layout.Row = 1;
            this.MethodDropdown.Layout.Column = 2;
            this.MethodDropdown.Items = { ...
                getString(message('Slcontrol:lintool:LinOptsRateConvZOH')),...
                getString(message('Slcontrol:lintool:LinOptsRateConvTustin')),...
                getString(message('Slcontrol:lintool:LinOptsRateConvTustinPreWarp'))};
            this.MethodDropdown.ValueChangedFcn = @(es,ed) setPrewarpPanel(this);
            
            this.UpsampleCheckbox = uicheckbox(MethodGrid,'Text',getString(message('Slcontrol:lintool:LinOptsUpsampleWhenPossible')));
            this.UpsampleCheckbox.Layout.Row = 1;
            this.UpsampleCheckbox.Layout.Column = 3;
            this.UpsampleCheckbox.Value = false;

            %Prewarp Frequency Panel
            this.PrewarpPanel = uipanel(ConversionsGrid,'Title','');
            this.PrewarpPanel.Layout.Row = 2;
            this.PrewarpPanel.Layout.Column = 1;
            this.PrewarpPanel.BorderType = 'none';
            
            PrewarpGrid = uigridlayout(this.PrewarpPanel, [1 2]);
            PrewarpGrid.Padding = [0 0 0 0];
            PrewarpGrid.ColumnWidth = {'fit','fit'};
            
            PrewarpLabel = uilabel(PrewarpGrid);
            PrewarpLabel.Layout.Row = 1;
            PrewarpLabel.Layout.Column = 1;
            PrewarpLabel.Text = getString(message('Control:systunegui:LinearizationOptionsPrewarpFrequencyLabel'));
            
            this.PrewarpEditField = uieditfield(PrewarpGrid,'numeric');
            this.PrewarpEditField.Layout.Row = 1;
            this.PrewarpEditField.Layout.Column = 2;
            this.PrewarpEditField.Value = 10;
            this.PrewarpEditField.Editable = true;
            this.PrewarpEditField.ValueDisplayFormat = '%11.4g rad/s';
            this.PrewarpEditField.Limits = [0 Inf];
            this.PrewarpEditField.UpperLimitInclusive = 'off';
            this.PrewarpEditField.LowerLimitInclusive = 'off';
            
            % Button Grid
            ButtonGrid = uigridlayout(FigureGrid,[1 5]);
            ButtonGrid.Layout.Row = 3;
            ButtonGrid.Layout.Column = 1;
            ButtonGrid.ColumnWidth = {'fit','1x','fit','fit','fit'};
            ButtonGrid.RowHeight = {'fit'};
            ButtonGrid.Padding = [0 0 0 0];
            
            this.HelpButton = uibutton(ButtonGrid);
            this.HelpButton.Layout.Row = 1;
            this.HelpButton.Layout.Column = 1;
            this.HelpButton.Text = getString(message('Controllib:gui:strHelp'));
            this.HelpButton.ButtonPushedFcn = @(~,~) callbackHelpButton(this);
            
            this.OKButton = uibutton(ButtonGrid);
            this.OKButton.Layout.Row = 1;
            this.OKButton.Layout.Column = 4;
            this.OKButton.Text = getString(message('Control:systunegui:ButtonPanelOKLabel'));
            this.OKButton.ButtonPushedFcn = @(~,~) callbackOKButton(this);
            
            this.CancelButton = uibutton(ButtonGrid);
            this.CancelButton.Layout.Row = 1;
            this.CancelButton.Layout.Column = 5;
            this.CancelButton.Text = getString(message('Control:systunegui:ButtonPanelCancelLabel'));
            this.CancelButton.ButtonPushedFcn = @(~,~) callbackCancelButton(this);
            
            % Set dialog size
            this.UIFigure.Position(3:4) = [425 260];
        end
        
        function connectUI(this)
            %TC Listener
            L1 = addlistener(this.TCPeer,'ComponentChanged', @(hSrc,hData) updateUI(this));
            L2 = addlistener(this.TCPeer,'ObjectBeingDestroyed', @(hSrc,hData) cleanupUI(this));
            registerUIListeners(this,[L1 L2]);
        end
        
        function callbackHelpButton(this) %#ok<MANU>
            helpview('control','LinearizationOptionsHelp','CSHelpWindow');
        end
        
        function callbackOKButton(this)
            CurrentOptions = copy(this.TCPeer.Data);
            disableUIListeners(this);
            try
                % Set sample time
                if this.ContinuousRButton.Value == 1
                    setOptionField(this.TCPeer,'SampleTime',0);
                else
                    SampleTime = this.DiscreteEditField.Value;
                    setSampleTime(this.TCPeer,SampleTime);
                end
                
                % Set rate conversion method
                selectedMethod = getRateConversionMethod(this,this.MethodDropdown.Value);
                if contains(selectedMethod,'prewarp')
                    PrewarpFrequency = this.PrewarpEditField.Value;
                    setPrewarpFrequency(this.TCPeer,PrewarpFrequency);
                end
                setOptionField(this.TCPeer,'RateConversionMethod',selectedMethod);
                
                % Check tuning goals are compatible with architecture
                validTGIndex = getTuningGoalIndexMatchingWithSampleTime(this.TCPeer.ControlDesignData,this.TCPeer.Data.SampleTime);
                removeTuningGoalFlag = [];
                if ~all(validTGIndex)
                    TuningGoals = this.TCPeer.ControlDesignData.getTuningGoal;
                    InvalidTuningGoals = TuningGoals(~validTGIndex);
                    InvalidTuningGoalNames = arrayfun(@(x) x.TuningGoal.Name,InvalidTuningGoals,'UniformOutput',false);
                    
                    str = [getString(message('Control:systunegui:SampleTimeMismatchDeleteTuningGoal')) newline];
                    for id=1:length(InvalidTuningGoalNames)
                        str = [str sprintf('- %s',InvalidTuningGoalNames{id}) newline];
                    end
                    
                    % There exists tuning goal with sample time mismatch
                    selection = uiconfirm(this.UIFigure,str,ctrlMsgUtils.message('Control:systunegui:toolName'), ...
                        'Options',{...
                        ctrlMsgUtils.message('Control:systunegui:YesLabel'),...
                        ctrlMsgUtils.message('Control:systunegui:NoLabel'),...
                        ctrlMsgUtils.message('Control:systunegui:CancelLabel')},...
                        'DefaultOption',1);
                    switch selection
                        case getString(message('Control:systunegui:YesLabel'))
                            removeTuningGoalFlag = true;
                            removeTuningGoal(this.TCPeer.ControlDesignData,InvalidTuningGoals);
                        case getString(message('Control:systunegui:NoLabel'))
                            removeTuningGoalFlag = false;
                        case getString(message('Control:systunegui:CancelLabel'))
                            removeTuningGoalFlag = false;
                        otherwise
                            removeTuningGoalFlag = false;
                    end
                end
                
                if isempty(removeTuningGoalFlag) || isequal(removeTuningGoalFlag,true)
                    % Set options to architecture (sltuner object)
                    setLinearizationOptions(this.TCPeer);
                    this.close();
                else
                    setOptions(this.TCPeer,CurrentOptions);
                    enableUIListeners(this);
                    updateUI(this);
                    return;
                end
            catch ME
                if strcmp(ME.identifier,'Control:systunegui:LinearizationOptionsErrorSampleTime')
                    setSampleTime(this.TCPeer,1);
                elseif strcmp(ME.identifier,'Control:systunegui:LinearizationOptionsErrorPrewarpFrequency')
                    setPrewarpFrequency(this.TCPeer,10);
                    setOptionField(this.TCPeer,'RateConversionMethod',getRateConversionMethod(this,selectedMethod));
                end
                enableUIListeners(this);
                updateUI(this);
                uialert(this.UIFigure,ME.message,getString(message('Control:systunegui:toolName')));
                return;
            end
        end
        
        function callbackCancelButton(this)
            this.close();
        end
        
        function switchContinuousDiscrete(this,~)
            if this.DiscreteEditField.Enable
                this.DiscreteEditField.Enable = false;
                this.DiscreteEditField.Editable = false;
            else
                this.DiscreteEditField.Enable = true;
                this.DiscreteEditField.Editable = true;
            end
        end
        
        function setPrewarpPanel(this)
            selectedMethod = getRateConversionMethod(this,this.MethodDropdown.Value);
            if contains(selectedMethod,'prewarp')
                this.PrewarpPanel.Visible = true;
            else
                this.PrewarpPanel.Visible = false;
            end
        end
        
        function label =  getRateConversionLabel(~,method)
            switch method
                case {'zoh','upsampling_zoh'}
                    label = getString(message('Slcontrol:lintool:LinOptsRateConvZOH'));
                case {'tustin','upsampling_tustin'}
                    label = getString(message('Slcontrol:lintool:LinOptsRateConvTustin'));
                case {'prewarp','upsampling_prewarp'}
                    label = getString(message('Slcontrol:lintool:LinOptsRateConvTustinPreWarp'));
                otherwise
                    label = '';
            end
        end
        
        function method = getRateConversionMethod(this,str)
            switch str
                case getString(message('Slcontrol:lintool:LinOptsRateConvZOH'))
                    if this.UpsampleCheckbox.Value
                        method = 'upsampling_zoh';
                    else
                        method = 'zoh';
                    end
                case getString(message('Slcontrol:lintool:LinOptsRateConvTustin'))
                    if this.UpsampleCheckbox.Value
                        method = 'upsampling_tustin';
                    else
                        method = 'tustin';
                    end
                case getString(message('Slcontrol:lintool:LinOptsRateConvTustinPreWarp'))
                    if this.UpsampleCheckbox.Value
                        method = 'upsampling_prewarp';
                    else
                        method = 'prewarp';
                    end
                otherwise
                    method = '';
            end
        end
    end
    
    methods (Hidden)
        function Widgets = qeGetWidgets(this)
            Widgets = struct('ContinuousRButton', this.ContinuousRButton,...
                'DiscreteRButton', this.DiscreteRButton,...
                'DiscreteEditField',this.DiscreteEditField,...
                'MethodDropdown',this.MethodDropdown,...
                'UpsampleCheckbox',this.UpsampleCheckbox,...
                'PrewarpEditField',this.PrewarpEditField,...
                'HelpButton',this.HelpButton,...
                'OKButton',this.OKButton,...
                'CancelButton',this.CancelButton );
        end
    end
end