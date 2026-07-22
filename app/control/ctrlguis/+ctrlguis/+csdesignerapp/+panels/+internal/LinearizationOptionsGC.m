classdef LinearizationOptionsGC < controllib.ui.internal.dialog.AbstractContainer
    % Graphical component for linearization options of Control System Designer.
    
    % Copyright 2020-2022 The MathWorks, Inc.
    properties(Access = private)
        TCPeer
        Dlg
        Panel
        Widgets
        
        Parent
        Row
        Column
        
        SampleTimePanel
        SampleTimeLabel
        SampleTimeRadioButtonGroup
        ContinuousRadioButton
        DiscreteRadioButton
        DiscreteEditfield
        DiscreteUnitLabel
        RateConversionPanel
        RateConversionLabel
        RateConversionDropdown
        PrewarpPanel
        PrewarpLabel
        PrewarpEditfield
        PrewarpFrequencyUnit
    end
    
    methods
        function this = LinearizationOptionsGC(tcpeer,parentContainerOptions)
            arguments
                tcpeer ctrlguis.csdesignerapp.panels.internal.LinearizationOptionsTC
                parentContainerOptions.Parent = []
                parentContainerOptions.Row = []
                parentContainerOptions.Column = []
                parentContainerOptions.Dialog = []
            end
            this.TCPeer = tcpeer;
            this.Parent = parentContainerOptions.Parent;
            this.Row = parentContainerOptions.Row;
            this.Column = parentContainerOptions.Column;
            buildContainer(this);
            setDialog(this,parentContainerOptions.Dialog);
        end
        
        function setDialog(this,Dlg)
            this.Dlg = Dlg;
        end
    end
    
    methods(Access = protected)
        function container = createContainer(this)
            % Main Container
            container = uigridlayout(this.Parent,[3 1]);
            container.ColumnWidth = {'fit'};
            container.RowHeight = {'fit',1,'fit'};
            container.Padding = 0;
            if ~isempty(this.Row)
                container.Layout.Row = this.Row;
            end
            if ~isempty(this.Column)
                container.Layout.Column = this.Column;
            end
            
            % Sample Time Panel
            this.SampleTimePanel = uigridlayout(container,[3 3]);
            this.SampleTimePanel.RowHeight = {'fit',25,22};
            this.SampleTimePanel.ColumnWidth = {180,'fit','fit'};
            this.SampleTimePanel.Padding = 0;
            % Sample Time Label
            this.SampleTimeLabel = uilabel(this.SampleTimePanel);
            this.SampleTimeLabel.Layout.Column = [1 3];
            this.SampleTimeLabel.Layout.Row = 1;
            this.SampleTimeLabel.Text = ...
                getString(message('Control:designerapp:LinearizationOptionsTuningDomain'));
            this.SampleTimeLabel.FontWeight = 'bold';
            % Sample Time Radio Buttons
            this.SampleTimeRadioButtonGroup = uibuttongroup(this.SampleTimePanel);
            this.SampleTimeRadioButtonGroup.Layout.Row = [2 3];
            this.SampleTimeRadioButtonGroup.Layout.Column = 1;
            this.SampleTimeRadioButtonGroup.BorderType = 'none';
            this.SampleTimeRadioButtonGroup.SelectionChangedFcn = ...
                @(es,ed) switchContinuousDiscrete(this);
            this.ContinuousRadioButton = uiradiobutton(this.SampleTimeRadioButtonGroup);
            this.ContinuousRadioButton.Text = ...
                getString(message('Control:designerapp:LinearizationOptionsContinuous'));
            this.ContinuousRadioButton.Position(1:3) = [12 30 180];
            this.DiscreteRadioButton = uiradiobutton(this.SampleTimeRadioButtonGroup);
            this.DiscreteRadioButton.Text = ...
                getString(message('Control:designerapp:LinearizationOptionsDiscrete'));
            this.DiscreteRadioButton.Position(1:3) = [12 0 180];
            % Sample Time Edit Field
            this.DiscreteEditfield = uieditfield(this.SampleTimePanel);
            this.DiscreteEditfield.Layout.Row = 3;
            this.DiscreteEditfield.Layout.Column = 2;
            this.DiscreteEditfield.Value = '1';
            this.DiscreteEditfield.Enable = false;
            this.DiscreteEditfield.ValueChangedFcn = @(es,ed) setSampleTime(this);
            this.DiscreteUnitLabel = uilabel(this.SampleTimePanel);
            this.DiscreteUnitLabel.Layout.Row = 3;
            this.DiscreteUnitLabel.Layout.Column = 3;
            this.DiscreteUnitLabel.Text = ...
                getString(message('Control:designerapp:LinearizationOptionsSecLabel'));
            
            % Rate Conversion Panel
            this.RateConversionPanel = uigridlayout(container,[3 3]);
            this.RateConversionPanel.ColumnWidth = {1,'fit','fit'};
            this.RateConversionPanel.RowHeight = {'fit','fit','fit'};
            this.RateConversionPanel.Padding = 0;
            this.RateConversionPanel.Layout.Row = 3;
            % Rate Conversion Label
            this.RateConversionLabel = uilabel(this.RateConversionPanel);
            this.RateConversionLabel.Layout.Row = 1;
            this.RateConversionLabel.Layout.Column = [1 3];
            this.RateConversionLabel.Text = ...
                getString(message('Control:designerapp:LinearizationOptionsRateConversions'));
            this.RateConversionLabel.FontWeight = 'bold';
            % Rate Conversion Method Dropdown Row
            label = uilabel(this.RateConversionPanel);
            label.Layout.Row = 2;
            label.Layout.Column = 2;
            label.Text = getString(message('Control:designerapp:LinearizationOptionsRateConversionLabel'));
            this.RateConversionDropdown = uidropdown(this.RateConversionPanel);
            this.RateConversionDropdown.Layout.Row = 2;
            this.RateConversionDropdown.Layout.Column = 3;
            this.RateConversionDropdown.Items = ...
                { ...
                getString(message('Slcontrol:lintool:LinOptsRateConvZOH')),...
                getString(message('Slcontrol:lintool:LinOptsRateConvTustin')),...
                getString(message('Slcontrol:lintool:LinOptsRateConvTustinPreWarp'))};
            %             this.RateConversionDropdown.ItemsData = {'zoh','tustin','tustinPrewarp'};
            this.RateConversionDropdown.ValueChangedFcn = ...
                @(es,ed) setPrewarpPanel(this);
            % Prewarp Frequency Row
            this.PrewarpPanel = uigridlayout(this.RateConversionPanel,[1 3]);
            this.PrewarpPanel.ColumnWidth = {'fit','fit','fit'};
            this.PrewarpPanel.RowHeight = {'fit'};
            this.PrewarpPanel.Layout.Row = 3;
            this.PrewarpPanel.Layout.Column = [2 3];
            this.PrewarpPanel.Padding = 0;
            this.PrewarpLabel = uilabel(this.PrewarpPanel);
            this.PrewarpLabel.Text = ...
                getString(message('Control:designerapp:LinearizationOptionsPrewarpFrequencyLabel'));
            this.PrewarpEditfield = uieditfield(this.PrewarpPanel);
            this.PrewarpEditfield.Value = '10';
            this.PrewarpEditfield.ValueChangedFcn = @(es,ed) setPrewarpFrequency(this);
            this.PrewarpFrequencyUnit = uilabel(this.PrewarpPanel);
            this.PrewarpFrequencyUnit.Text = getString(message('Control:designerapp:LinearizationOptionsPrewarpFrequencyUnit'));
        end
        
        function connectUI(this)
            % Listener for TC
            L = addlistener(this.TCPeer,'ComponentChanged', @(hSrc,hData) update(this));
            registerUIListeners(this,L,'TCPeerComponentChanged');
            L = addlistener(this.TCPeer,'ObjectBeingDestroyed', @(hSrc,hData) cleanup(this));
            registerUIListeners(this,L,'TCPeerObjectBeingDestroyed');
        end
        
    end
    
    methods
        function addPrewarpFrequencyPanel(this)
            this.PrewarpPanel.Parent = this.RateConversionPanel;
            this.PrewarpPanel.Layout.Row = 3;
            this.PrewarpPanel.Layout.Column = [2 3];
            
            NF = 3.14159/str2double(this.DiscreteEditfield.Value);
            CurrentFrequency = str2double(this.PrewarpEditfield.Value);
            if CurrentFrequency>NF
                this.PrewarpEditfield.Value = mat2str(min(NF/2,10));
            end
        end
        
        function removePrewarpFrequencyPanel(this)
            this.PrewarpPanel.Parent = [];
        end
        
        %% update and callbacks
        function update(this)
            if isempty(this.Dlg) || ~isvalid(this.Dlg)
                return;
            end
            
            Options = getOptions(this.TCPeer);
            
            disableListeners(this);
            
            % update rate conversion method and prewarp frequency
            this.RateConversionDropdown.Value = ...
                getRateConversionLabel(Options.RateConversionMethod);
            this.Widgets.textfield.PrewarpFrequencyTextfield.Text = num2str(Options.PreWarpFreq);
            
            method = Options.RateConversionMethod;
            if strcmp(method,'prewarp') || strcmp(method,'upsampling_prewarp')
                this.addPrewarpFrequencyPanel;
            else
                this.removePrewarpFrequencyPanel;
            end
            if this.TCPeer.Data.SampleTime > 0
                NF = 3.14159/this.TCPeer.Data.SampleTime;
                CurrentFrequency = Options.PreWarpFreq;
                if CurrentFrequency>NF
                    setPrewarpFrequency(this.TCPeer,min(NF/2,10));
                    this.PrewarpEditfield.Value = num2str(min(NF/2,10));
                else
                    this.PrewarpEditfield.Value = num2str(Options.PreWarpFreq);
                end
            else
                this.PrewarpEditfield.Value = num2str(Options.PreWarpFreq);
            end
            
            % update sample time field
            if Options.SampleTime>0
                this.DiscreteRadioButton.Value = true;
                this.DiscreteEditfield.Enable = true;
                this.DiscreteEditfield.Value = num2str(Options.SampleTime);
            else
                this.ContinuousRadioButton.Value = true;
                this.DiscreteEditfield.Enable = false;
            end
            
            enableListeners(this);
        end
    end
    methods(Access = private)
        %% listeners
        function cleanup(this)
            if isvalid(this)
                disableListeners(this);
                deleteListeners(this);
                delete(this)
            end
        end
        function enableListeners(this)
            enableUIListeners(this);
        end
        function disableListeners(this)
            disableUIListeners(this);
        end
        function setListeners(this,flag)
            if flag
                enableUIListeners(this);
            else
                disableUIListeners(this);
            end
        end
        function deleteListeners(this)
            unregisterUIListeners(this);
        end
        
        %% set options
        function switchContinuousDiscrete(this)
            disableListeners(this);
            % Add a drawnow to update the value of ContinuousRadioButton.
            % Revisit
            drawnow;
            if this.DiscreteRadioButton.Value
                this.DiscreteEditfield.Enable = true;
            else
                this.DiscreteEditfield.Enable = false;
            end
            %% set sample time
            if this.ContinuousRadioButton.Value
                setContinuousSampleTime(this)
            else
                setSampleTime(this);
                NF = 3.14159/str2double(this.DiscreteEditfield.Value);
                CurrentFrequency = str2double(this.PrewarpEditfield.Value);
                if CurrentFrequency > NF
                    this.PrewarpEditfield.Value = mat2str(min(NF/2,10));
                end
            end
            %             updateBlocks(this.TCPeer.Parent);
            enableListeners(this);
        end
        
        function setContinuousSampleTime(this)
            try
                CurrentSampleTime = this.TCPeer.Data.SampleTime;
                setOptionField(this.TCPeer,'SampleTime',0);
                propagateSampleTime(this.TCPeer.Architecture,CurrentSampleTime);
                % Force compilation to verify validity
                this.TCPeer.Architecture.genss;
            catch ME
                setOptionField(this.TCPeer,'SampleTime',CurrentSampleTime);
                propagateSampleTime(this.TCPeer.Architecture,CurrentSampleTime);
                f = ancestor(this.Parent,'figure');
                uialert(f,ME.message,...
                    getString(message('Control:designerapp:strToolTitleShort')));
                update(this);
                this.SampleTimeRadioButtonGroup.SelectedObject = this.DiscreteRadioButton;
            end
        end
        
        function setPrewarpPanel(this)
            disableListeners(this);
            try
                CurrentOption = this.TCPeer.Data.RateConversionMethod;
                MethodLabel = this.RateConversionDropdown.Value;
                method = getRateConversionMethod(MethodLabel);
                if strcmp(method,'prewarp') || strcmp(method,'upsampling_prewarp')
                    addPrewarpFrequencyPanel(this);
                else
                    removePrewarpFrequencyPanel(this);
                end
                %% set rate conversion method
                method = getRateConversionMethod(this.RateConversionDropdown.Value);
                setOptionField(this.TCPeer,'RateConversionMethod',method);
                
                if strcmp(method,'prewarp') || strcmp(method,'upsampling_prewarp')
                    setPrewarpFrequency(this);
                else
                    % Force compilation to verify validity
                    this.TCPeer.Architecture.genss;
                end
                
            catch ME
                this.TCPeer.Data.RateConversionMethod = CurrentOption;
                f = ancestor(this.Parent,'figure');
                uialert(f,getString(message('Control:designerapp:LinearizationOptionsErrorSampleTime')),...
                    getString(message('Control:designerapp:strToolTitleShort')));
                update(this);
            end
            enableListeners(this);
        end
        
        function setSampleTime(this)
            SampleTimeString = this.DiscreteEditfield.Value;
            try
                InitialTs = this.TCPeer.getOptions.SampleTime;
                SampleTime = evalin('base',SampleTimeString);
                setSampleTime(this.TCPeer,SampleTime);
                % Force compilation to verify validity
                genss(this.TCPeer.Architecture);
                propagateSampleTime(this.TCPeer.Architecture,InitialTs);
                %                 updateBlocks(this.TCPeer.Parent);
            catch ME
                % if fails set to default
                setSampleTime(this.TCPeer,1);
                propagateSampleTime(this.TCPeer.Architecture,InitialTs);
                f = ancestor(this.Parent,'figure');
                uialert(f,ME.message,getString(message('Control:designerapp:strToolTitleShort')));
                update(this);
            end
        end
        
        function setPrewarpFrequency(this)
            disableListeners(this);
            PrewarpFrequencyString = this.PrewarpEditfield.Value;
            try
                PrewarpFrequency = evalin('base',PrewarpFrequencyString);
                setPrewarpFrequency(this.TCPeer,PrewarpFrequency);
                % Force compilation to verify validity
                this.TCPeer.Architecture.genss;
            catch ME
                % if fails set to default
                if strcmpi(ME.identifier, 'Control:designerapp:LinearizationOptionsErrorPrewarpFrequency')
                    % Always match prewarp frequency to pi/(Sample Time
                    % Text)
                    NF = 3.14159/str2double(this.DiscreteEditfield.Value);
                    setPrewarpFrequency(this.TCPeer,min(NF/2,10));
                else
                    if this.TCPeer.Data.SampleTime > 0
                        NF = 3.14159/str2double(this.DiscreteEditfield.Value);
                        setPrewarpFrequency(this.TCPeer,min(NF/2,10));
                    else
                        % Something else went wrong. Set to default
                        method = 'zoh';
                        setOptionField(this.TCPeer,'RateConversionMethod',method);
                    end
                end
                f = ancestor(this.Parent,'figure');
                uialert(f,ME.message,getString(message('Control:designerapp:strToolTitleShort')));
                update(this);
            end
            enableListeners(this);
        end
    end
    
    methods(Hidden)
        function w = qeGetWidgets(this)
            w.SampleTimePanel = this.SampleTimePanel;
            w.SampleTimeLabel = this.SampleTimeLabel;
            w.SampleTimeRadioButtonGroup = this.SampleTimeRadioButtonGroup;
            w.ContinuousRadioButton = this.ContinuousRadioButton;
            w.DiscreteRadioButton = this.DiscreteRadioButton;
            w.DiscreteEditfield = this.DiscreteEditfield;
            w.DiscreteUnitLabel = this.DiscreteUnitLabel;
            w.RateConversionPanel = this.RateConversionPanel;
            w.RateConversionLabel = this.RateConversionLabel;
            w.RateConversionDropdown = this.RateConversionDropdown;
            w.PrewarpPanel = this.PrewarpPanel;
            w.PrewarpLabel = this.PrewarpLabel;
            w.PrewarpEditfield = this.PrewarpEditfield;
            w.PrewarpFrequencyUnit = this.PrewarpFrequencyUnit;
        end
    end
end

function method = getRateConversionMethod(String)
switch String
    case getString(message('Slcontrol:lintool:LinOptsRateConvZOH'))
        method = 'zoh';
    case getString(message('Slcontrol:lintool:LinOptsRateConvTustin'))
        method = 'tustin';
    case getString(message('Slcontrol:lintool:LinOptsRateConvTustinPreWarp'))
        method = 'prewarp';
    case getString(message('Slcontrol:lintool:LinOptsRateConvUpSampZOH'))
        method = 'upsampling_zoh';
    case getString(message('Slcontrol:lintool:LinOptsRateConvUpSampTustin'))
        method = 'upsampling_tustin';
    case getString(message('Slcontrol:lintool:LinOptsRateConvUpSampTustinPreWarp'))
        method = 'upsampling_prewarp';
end
end
function label = getRateConversionLabel(method)
switch method
    case 'zoh'
        label = getString(message('Slcontrol:lintool:LinOptsRateConvZOH'));
    case 'tustin'
        label = getString(message('Slcontrol:lintool:LinOptsRateConvTustin'));
    case 'prewarp';
        label = getString(message('Slcontrol:lintool:LinOptsRateConvTustinPreWarp'));
    case 'upsampling_zoh'
        label = getString(message('Slcontrol:lintool:LinOptsRateConvUpSampZOH'));
    case 'upsampling_tustin'
        label = getString(message('Slcontrol:lintool:LinOptsRateConvUpSampTustin'));
    case 'upsampling_prewarp'
        label = getString(message('Slcontrol:lintool:LinOptsRateConvUpSampTustinPreWarp'));
end
end