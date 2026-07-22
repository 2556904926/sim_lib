classdef LoopShapeSpecPanel < ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel
%     Panel that is used to tune the compensators via PID Classical Methd
%     
%     To use the panel in a dialog
%     c = ctrlguis.csdesignerapp.panels.internal.PIDClassicSpecPanel('Parent', uigridlayout)

    properties (SetAccess = private)
        hasRobustToolboxLicense = ~isempty(ver('robust')) || license('test','Robust_Toolbox');
        freeformLabel = getString(message( ...
                'Control:designerapp:strFreeForm'));
        fixedLabel = getString(message( ...
                'Control:designerapp:strFixed'));
        bandwidthLabel = getString(message( ...
            'Control:designerapp:strTuningTagetBandwidth'));
        loopshapeLabel = getString(message( ...
                'Control:designerapp:strTuningTargetLoopShape'));
    end
    
    methods
        function this = LoopShapeSpecPanel(Dialog, Parent, SpecData, varargin)
            
            % Superclass constructor
            this = this@ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel(Parent);
            
            % resassign property values
            this.Dlg = Dialog;
            this.Parent = Parent;
            this.Name = 'CSD_LoopShapeSpecPanel';
            set(this, 'SpecData', SpecData);
            this.SpecData = SpecData;
            
            % build panel
            buildContainer(this)
        end
        
        function createWidgets(this)
            
            % create UI components
            createStructureDropdown(this);
            
            mainGrid = uigridlayout(this.Layout, [3 3]);
            mainGrid.RowHeight = {'fit','fit','fit'};
            mainGrid.ColumnWidth = {'fit', 'fit', 'fit'};
            mainGrid.Layout.Row = 3; 
            mainGrid.Layout.Column = [1 2];
            
            this.Widgets.MainGrid = mainGrid;
            
            % create all components
            createLoopShapePreferences(this);
            createBandwidthPreferences(this);
            createSpinners(this);

            % create default spec data
            createDefaultSpecData(this)

            if strcmp(this.Widgets.StructureDropdown.Value, ...
                    'free')
                setVisibilitySpinners(this, 'on');
            else
                setVisibilitySpinners(this, 'off');
            end
            
            if strcmp(this.SpecData.Preference, this.loopshapeLabel)
                setVisibilityBandwidth(this, 'off');
                setVisibilityLoopshape(this, 'on');
            else
                setVisibilityBandwidth(this, 'on');
                setVisibilityLoopshape(this, 'off');
            end

            
        end
    
    end
    
    %% Protected Methods %%
    methods (Access = protected)
        %% Data 
        function createDefaultSpecData(this)
            if this.hasRobustToolboxLicense
                this.SpecData.Compensator = 'free';
            else
                this.SpecData.Compensator = 'fixed';
            end
            this.SpecData.Preference = this.bandwidthLabel;
            this.SpecData.BandWidth = '10';
            this.SpecData.LoopShape = 'tf(1,[1,1])';
            this.SpecData.FrequencyRange = '[1,1000]';
            if isempty(this.Response) || isempty(this.Compensator)
                this.SpecData.DesiredOrder = 1;
            else
                this.SpecData.DesiredOrder = utComputeCompensatorOrder(this);
            end
        end
        
        %% UI Methods
        
        function createStructureDropdown(this)
            
            % add additional rows
%             this.Layout.RowHeight = {'fit', 22, 22, 'fit', 'fit'};
            % reset lyaout ColumnWidth to ensure we pack all components
            this.Layout.RowHeight = {'fit',45,'fit','fit'};
            this.Layout.ColumnWidth = {'fit','fit','fit'};
            
            % creating dorpdowns
            structureLabel = uilabel(this.Layout, 'Text', ...
                getString(message('Control:designerapp:strCompStructure')));
            structureLabel.Layout.Row = 1;
            structureLabel.Layout.Column = 1;
            
            structureDropDown = uidropdown(this.Layout);
            structureDropDown.Layout.Row = 1;
            structureDropDown.Layout.Column = 2;
            structureDropDown.Items = {
                getString(message('Control:designerapp:strFreeForm')), ...
                getString(message('Control:designerapp:strFixed'))};
            structureDropDown.ItemsData = {'free','fixed'};
            
            
            
            % create dropdown for Controller response
            prefLabel = uilabel(this.Layout, 'Text', ...
                getString(message('Control:designerapp:strTuningPreferenceLabel')));
            prefLabel.Layout.Row = 2;
            prefLabel.Layout.Column = 1;
            prefLabel.VerticalAlignment = 'top';
            
            prefButtonGroup = uibuttongroup(this.Layout);
            prefButtonGroup.Layout.Row = 2;
            prefButtonGroup.Layout.Column = 2;
            prefButtonGroup.BorderType = 'none';
            weakThis = matlab.lang.WeakReference(this);
            prefButtonGroup.SelectionChangedFcn = @(es,ed) updateTuningPreference(weakThis.Handle, ed);
%             ctrlButtonGroup.Position(4) = 42; %reduce the height of the button group
            
            bandwidthButton = uiradiobutton(prefButtonGroup, 'Text', ...
                this.bandwidthLabel, 'Position', [5 25 140 22]);
            
            loopshapeButton = uiradiobutton(prefButtonGroup, 'Text', ...
                this.loopshapeLabel, 'Position', [5 0 150 22]);
            
            % add to widgets
            this.Widgets.StructureDropdown = structureDropDown;
            this.Widgets.PreferencesButtonGroup = prefButtonGroup;
            this.Widgets.lblCompensatorStructure = structureLabel;
            this.Widgets.lblTuningPreference = prefLabel;
%             this.Widgets.BandwidthButton = bandwidthButton;
%             this.Widgets.LoopshapeButton = loopshapeButton;
        end
        
        function createBandwidthPreferences(this)
            % create slider for Measurement noise
            olBandwidthLabel = uilabel(this.Widgets.MainGrid, 'Text', ...
                getString(message('Control:designerapp:strTargetOLBandwidthLabel')));
            olBandwidthLabel.Layout.Row = 1;%3;
            olBandwidthLabel.Layout.Column = 1;
            bandwidthText = uieditfield(this.Widgets.MainGrid);
            bandwidthText.Layout.Row = 1;%3;
            bandwidthText.Layout.Column = [2 3];
            bandwidthText.Value = '10';

            % add to widgets
            this.Widgets.BandwidthLabel = olBandwidthLabel;
            this.Widgets.BandwidthText = bandwidthText;
                      
        end
        
        function createLoopShapePreferences(this)
            olLoopshapeLabel = uilabel(this.Widgets.MainGrid, 'Text', ...
                getString(message('Control:designerapp:strTargetOLLTILabel')));
            olLoopshapeLabel.Layout.Row = 1;%3;
            olLoopshapeLabel.Layout.Column = 1;

            loopshapeText = uieditfield(this.Widgets.MainGrid);
            loopshapeText.Layout.Row = 1;%3;
            loopshapeText.Layout.Column = [2 3];
            loopshapeText.Value = 'tf(1,[1,1])';
            
            frequencyLabel = uilabel(this.Widgets.MainGrid, 'Text', ...
                                  getString(message('Control:designerapp:strTargetOLFreqRangeLabel')));
            frequencyLabel.Layout.Row = 2;%4;
            frequencyLabel.Layout.Column = 1;
            frequencyText = uieditfield(this.Widgets.MainGrid);
            frequencyText.Layout.Row = 2;%4;
            frequencyText.Layout.Column = [2 3];
            frequencyText.Value = '[1,1000]';

            % add to Widgets
            this.Widgets.LoopshapeLabel = olLoopshapeLabel;
            this.Widgets.LoopshapeText = loopshapeText;
            this.Widgets.FrequencyRangeLabel = frequencyLabel;
            this.Widgets.FrequencyRange = frequencyText;
        end
        
        function createSpinners(this)
            
%             panel.Layout.ColumnWidth = {'fit', 'fit', 'fit'};
            orderLabel = uilabel(this.Widgets.MainGrid, 'Text', ...
                getString(message('Control:designerapp:AutomatedTuningDesiredOrderLabel')));
            orderLabel.Layout.Row = 3;%5;
            orderLabel.Layout.Column = 1;
            
            orderSpinner = uispinner(this.Widgets.MainGrid);
            orderSpinner.Layout.Row = 3;%5;
            orderSpinner.Layout.Column = [2 3];
            orderSpinner.Value = 3;
            orderSpinner.Limits = [1 10];

            % add to Widgets
            this.Widgets.OrderLabel = orderLabel;
            this.Widgets.OrderSpinner = orderSpinner;

            this.Widgets.OrderLabel.Visible = 'off';
            this.Widgets.OrderSpinner.Visible = 'off';
            
        end
        
        %% Callbacks
        
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            structureListener = addlistener(this.Widgets.StructureDropdown, ...
                'ValueChanged', ...
                @(es, ed)updateCompensatorFromDropDown(weakThis.Handle));

            orderListener = addlistener(this.Widgets.OrderSpinner, ...
                'ValueChanged', ...
                @(es, ed) updateOrder(weakThis.Handle, es.Value));
            
            bandwidthListener = addlistener(this.Widgets.BandwidthText, ...
                'ValueChanged', @(es, ed)updateBandWidth(weakThis.Handle,es.Value));

            loopShapeListener = addlistener(this.Widgets. ...
                LoopshapeText, 'ValueChanged', ...
                @(es, ed)updateLoopShape(weakThis.Handle, es.Value));
            
            frequencyRangeListener = addlistener(this.Widgets. ...
                FrequencyRange, 'ValueChanged', ...
                @(es, ed)updateFrequencyRange(weakThis.Handle, es.Value));

            this.UIListeners{end+1} = structureListener;
            this.UIListeners{end+1} = orderListener;
            this.UIListeners{end+1} = bandwidthListener;
            this.UIListeners{end+1} = loopShapeListener;
            this.UIListeners{end+1} = frequencyRangeListener;
        end

        function refreshUI(this)

            SpecData = get(this, 'SpecData');
            % Push data to widgets
            if ~isempty(this.Response) && ~isempty(this.Compensator) && this.Panel.Visible
%                 order(this.Compensator.FixedDynamics)
                if strcmp(SpecData.Compensator, 'free')
                    order = utComputeCompensatorOrder(this);
                    localResetCompensatorOrder(this, order);
                    setVisibilitySpinners(this, 'on');
                else
                    setVisibilitySpinners(this, 'off');
                end
                this.Widgets.StructureDropdown.Value = SpecData.Compensator;
                
                if strcmp(SpecData.Preference, this.bandwidthLabel)
                    buttonGroup = this.Widgets.PreferencesButtonGroup;
                    buttonGroup.SelectedObject = buttonGroup.Buttons(1);
                    
                    % reset visibility - all objects are created during init
                    setVisibilityLoopshape(this, 'off')
                    setVisibilityBandwidth(this, 'on');

                    % update values
                    this.Widgets.BandwidthText.Value = SpecData.BandWidth;
                    
                else
                    buttonGroup = this.Widgets.PreferencesButtonGroup;
                    buttonGroup.SelectedObject = buttonGroup.Buttons(2);
                   
                    % reset visibility - all objects are created during init
                    setVisibilityBandwidth(this, 'off');
                    setVisibilityLoopshape(this, 'on');
                    
                    % update values
                    this.Widgets.LoopshapeText.Value = SpecData.LoopShape;
                    this.Widgets.FrequencyRange.Value = SpecData.FrequencyRange;
                end
            end

        end

        function updateTuningPreference(this, ed)

            if strcmp(ed.NewValue.Text, this.bandwidthLabel)
                this.SpecData.Preference = this.bandwidthLabel;
            else
                this.SpecData.Preference = this.loopshapeLabel;
            end
            this.notify('SpecDataChanged');
            updateUI(this);
        end

        function setVisibilityBandwidth(this, value)
            this.Widgets.BandwidthLabel.Visible = value;
            this.Widgets.BandwidthText.Visible = value;
        end

        function setVisibilityLoopshape(this, value)
            % this.Widgets.LoopshapeText.Visible = value;
            % this.Widgets.LoopshapeLabel.Visible = value;
            % this.Widgets.FrequencyRangeLabel.Visible = value;
            % this.Widgets.FrequencyRange.Visible = value;

            if strcmp(value,'on')
                this.Widgets.LoopshapeText.Parent = this.Widgets.MainGrid;
                this.Widgets.LoopshapeLabel.Parent = this.Widgets.MainGrid;
                this.Widgets.FrequencyRangeLabel.Parent = this.Widgets.MainGrid;
                this.Widgets.FrequencyRange.Parent = this.Widgets.MainGrid;
            else
                this.Widgets.LoopshapeText.Parent = [];
                this.Widgets.LoopshapeLabel.Parent = [];
                this.Widgets.FrequencyRangeLabel.Parent = [];
                this.Widgets.FrequencyRange.Parent = [];
            end
        end

        function setVisibilitySpinners(this, value)
            this.Widgets.OrderLabel.Visible = value;
            this.Widgets.OrderSpinner.Visible = value;
        end
        
        function updateCompensatorFromDropDown(this)
            this.SpecData.Compensator = this.Widgets.StructureDropdown.Value;
            switch this.Widgets.StructureDropdown.Value
                case 'free'
                    setVisibilitySpinners(this, 'on');
                case 'fixed'
                    setVisibilitySpinners(this, 'off');
            end
            updateUI(this);
            this.notify('SpecDataChanged');
        end
        
        function updateOrder(this, Value)
            if isempty(Value) || all(isspace(Value))
                updateUI(this);
            else
                spinnerMinValue = this.Widgets.OrderSpinner.Limits(1);
                spinnerMaxValue = this.Widgets.OrderSpinner.Limits(2);
                if isnumeric(Value) && isreal(Value)
                    this.SpecData.DesiredOrder = Value;
                    if Value <= spinnerMaxValue && ...
                            Value >= spinnerMinValue
                        this.SpecData.DesiredOrder = Value;
                        this.Widgets.OrderSpinner.Value = Value;
                    elseif Value > spinnerMaxValue
                        this.SpecData.DesiredOrder = spinnerMaxValue;
                        this.Widgets.OrderSpinner.Value = spinnerMaxValue;
                    elseif  Value < spinnerMinValue
                        this.SpecData.DesiredOrder = spinnerMinValue;
                        this.Widgets.OrderSpinner.Value = spinnerMinValue;
                    end
                    this.notify('SpecDataChanged');
                else
                    updateUI(this);
                end
                
            end
            
        end
        
        function updateBandWidth(this,Value)
            if isempty(Value) || all(isspace(Value))
                updateUI(this);
            else
                try
                    numericalValue = evalin('base',Value);
                    if isscalar(numericalValue) && ~isnan(numericalValue) && isreal(numericalValue) && ...
                            numericalValue > 0
                        this.SpecData.BandWidth = Value;
                        this.notify('SpecDataChanged');
                    else
                        eMessage = getString(message( ...
                            'Control:designerapp:LoopSynInvalidTarget2'));
                        uialert(getWidget(this.Dlg), eMessage, this.Dlg.Title, ...
                        'Icon', 'error');
                        updateUI(this);
                    end
                catch ME
                    updateUI(this);
                    uialert(getWidget(this.Dlg), ME.message, this.Dlg.Title, ...
                        'Icon', 'error');
                end
            end
        end
        
        function updateFrequencyRange(this, Value)
            if isempty(Value) || all(isspace(Value))
                updateUI(this);
            else
                try
                    NewFrequencyRange = evalin('base', Value);
                    if isa(NewFrequencyRange,'double')
                        this.SpecData.FrequencyRange = Value;
                        this.notify('SpecDataChanged');
                    else
                        updateUI(this);
                    end
                catch ME
                    updateUI(this);
                    uialert(getWidget(this.Dlg), ME.message, this.Dlg.Title, ...
                        'Icon', 'error');
                end
            end
        end
        
        function updateLoopShape(this, Value)
            if isempty(Value) || all(isspace(Value))
                updateUI(this);
            else
                try
                    Model = Value;
                    NewLTI = evalin('base', Model);
                    if isa(NewLTI,'lti') && issiso(NewLTI)
                        this.SpecData.LoopShape = Model;
                        this.notify('SpecDataChanged');
                    else
                        updateUI(this);
                        eMessage = getString(message( ...
                            'Control:designerapp:LoopSynInvalidTarget1'));
                        uialert(getWidget(this.Dlg), eMessage, this.Dlg.Title, ...
                        'Icon', 'error')
                    end
                catch ME
                    uialert(getWidget(this.Dlg), ME.message, this.Dlg.Title, ...
                        'Icon', 'error');
                    updateUI(this);
                end
            end
        end


        function localResetCompensatorOrder(this, Order)
            % Order is double
            this.Widgets.OrderSpinner.Limits(1) = 1;
            this.Widgets.OrderSpinner.Limits(2) = Order;
            if str2double(this.SpecData.DesiredOrder) < Order
                this.Widgets.OrderSpinner.Value = Order;
            else
                this.Widgets.OrderSpinner.Value = Order;
                this.SpecData.DesiredOrder = Order;
                this.notify('SpecDataChanged');
            end
        end

        function Nk = utComputeCompensatorOrder(this)
            %utComputeCompensatorOrder Computes the order of the compensator based on G
            % and Gd (based on formula specified in the doc for loopsyn)

            Ny = 1;
            OL = get(this, 'OpenLoopPlant');
            G = this.Dlg.utApproxDelay(OL);

            if strcmp(this.SpecData.Preference, this.loopshapeLabel)
                Gd = evalin('base', this.SpecData.LoopShape);
            else
                B = evalin('base',this.SpecData.BandWidth);
                Gd = zpk([],0,B);
            end

            PolesG = pole(G);
            ZerosG = zero(G);
            PZG = [PolesG(:); ZerosG(:)];

            NGd = order(Gd);
            NG = length(PolesG);

            if isdt(G)
                NGrhp = length(PZG(abs(PZG) >= 1)) + length(PolesG) - length(ZerosG);
            else
                NGrhp = length(PZG(real(PZG) >= 0)) + length(PolesG) - length(ZerosG);
            end

            Nk = Ny*NGd + NGrhp + NG;
        end

    end

    methods(Access = public)

        function qeUpdateCompensatorFromDropDown(this)
            updateCompensatorFromDropDown(this)
        end

    end
end
