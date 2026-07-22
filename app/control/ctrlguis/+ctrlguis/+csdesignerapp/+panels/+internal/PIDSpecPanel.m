classdef PIDSpecPanel < ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel
%     Panel that is used to tune the compensators via PID Classical Methd
%     
%     To use the panel in a dialog
%     c = ctrlguis.csdesignerapp.panels.internal.PIDSpecPanel('Parent', uigridlayout)

    properties
        RobustString = getString(message('Control:designerapp:strPIDTuningMethod1'));
        ClassicString = getString(message('Control:designerapp:strPIDTuningMethod2'));
        FrequencyString = getString(message('Control:compDesignTask:strPIDOptionLabelFrequency'));
        TimeString = getString(message('Control:compDesignTask:strPIDOptionLabelTime'));
    end
    
    methods
        function this = PIDSpecPanel(Dialog, Parent, SpecData, varargin)
            
            % Superclass constructor
            this = this@ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel(Parent);
            
            % resassign property values
            this.Dlg = Dialog;
            this.Parent = Parent;
            this.Name = 'CSD_PIDSpecPanel';
            set(this, 'SpecData', SpecData);
            this.SpecData = SpecData;
            
            % build panel - gets called from Abstract Layer
            buildContainer(this)
            
        end

        function createWidgets(this)
            
            % reset layout options for parent panel
            this.Layout.ColumnWidth = {'fit', 'fit', 'fit','1x'};
            createDefaultSpecData(this);
            createTuningMethodAndCtrlType(this);
            updateTuningDropdown(this);

            % this.Dlg.getWidget.Position(3:4) = [470, 640];
            
        end
       
    end
    
    %% Protected Methods %%
    methods (Access = protected)
        %% UI Methods
        
        function createTuningMethodAndCtrlType(this)
            % creating dorpdowns/radiobuttongroup for Spec Panel
            this.Layout.Scrollable = 'off';
            
            % create dropdown for Tuning Method
            tuningLabel = uilabel(this.Layout, 'Text', ...
                                  getString(message('Control:designerapp:strPIDTuningMethod')));
            tuningLabel.Layout.Row = 1;
            tuningLabel.Layout.Column = 1;
            
            tuningDropDown = uidropdown(this.Layout);
            tuningDropDown.Layout.Row = 1;
            tuningDropDown.Layout.Column = 2;
            tuningDropDown.Items = {getString(message('Control:designerapp:strPIDTuningMethod1')), ...
                                    getString(message('Control:designerapp:strPIDTuningMethod2'))};
            
            % add to widgets
            this.Widgets.TuningLabel = tuningLabel;
            this.Widgets.TuningDropdown = tuningDropDown;
            this.Widgets.ClassicGroup = [];
            this.Widgets.RobustGroup = [];
        end
        
        function createRobustTuningWidgets(this)
            
            % create radiobuttons for controllers
            ctrlLabel = uilabel(this.Layout, 'Text', ...
                                  getString(message(...
                                  'Control:designerapp:strPIDTypeLabel')));
            ctrlLabel.Layout.Row = 2;
            ctrlLabel.Layout.Column = 1;
            
            ctrlDropDown = uidropdown(this.Layout);
            ctrlDropDown.Layout.Row = 2;
            ctrlDropDown.Layout.Column = 2;
            ctrlDropDown.Items = {'P', 'I', 'PI', 'PD', 'PID'};
            ctrlDropDown.Value = this.SpecData.PIDType;

            
            mainGrid = uigridlayout(this.Layout, [3 4]);
            mainGrid.RowHeight = {'fit', 'fit', 'fit'};
            mainGrid.ColumnWidth = {'fit', 'fit', 'fit', '1x'};
            mainGrid.Layout.Row = 3; 
            mainGrid.Layout.Column = [1 4];
            mainGrid.Scrollable = 'on';
            
            % create checkbox for 1st order filter
            ctrlCheckBox = uicheckbox(mainGrid);
            ctrlCheckBox.Text = getString(...
                message('Control:designerapp:strPIDFilter'));
            ctrlCheckBox.Layout.Row = 1;
            ctrlCheckBox.Layout.Column = 2;
            ctrlCheckBox.FontSize = 12;
            
            % create design mode dropdown
            label = getString(message(...
                'Control:designerapp:strPIDOptionLabel'));
            designLabel = uilabel(mainGrid, 'Text', label);
            designLabel.Layout.Row = 2;
            designLabel.Layout.Column = 1;
            
            designDropdown = uidropdown(mainGrid);
            designDropdown.Layout.Row = 2;
            designDropdown.Layout.Column = 2;
            designDropdown.Items = {getString(message('Control:compDesignTask:strPIDOptionLabelTime')), ...
                                    getString(message('Control:compDesignTask:strPIDOptionLabelFrequency'))};
            if strcmpi(this.SpecData.DesignDomain,'time')
                designDropdown.Value = getString(message('Control:compDesignTask:strPIDOptionLabelTime'));
            else
                designDropdown.Value = getString(message('Control:compDesignTask:strPIDOptionLabelFrequency'));
            end
                        
            % create the sliders and spinners
            subGrid = uigridlayout(mainGrid, [4 8]);
            % ROW SIZE
            % reason for 40px is due to the fact the labels on sliders get
            % trimmed if the default size used. This does cause the buttons
            % and the spinner to be expanded. The other way is to set
            % manual Position values, which might not scale well in local
            % machines. 
            buttonSize = 35; % in pixels 
            subGrid.RowHeight = {'fit','fit',10,'fit','fit'};
            subGrid.RowSpacing = 0;
            subGrid.ColumnWidth = {buttonSize,'fit','1x','fit','1x','fit',buttonSize,100};
            subGrid.Layout.Row = 3; subGrid.Layout.Column = [1 4];
            subGrid.Padding = 0; % to align all sub grids with main grid
            
            
            % create increase/decrease buttons
            increaseButton = uibutton(subGrid);
            matlab.ui.control.internal.specifyIconID(increaseButton,'chevronDoubleEastUI',16);
            increaseButton.Layout.Row = 1;
            increaseButton.Layout.Column = 7;
            increaseButton.Text = '';
            
            decreaseButton = uibutton(subGrid);
            matlab.ui.control.internal.specifyIconID(decreaseButton,'chevronDoubleWestUI',16);
            decreaseButton.Layout.Row = 1;
            decreaseButton.Layout.Column = 1;
            decreaseButton.Text = '';
            
            % sliders & spinners
            sliderGrid1 = uigridlayout(subGrid,[1 1]);
            sliderGrid1.Padding = 0;
            sliderGrid1.RowHeight = {'fit'};
            sliderGrid1.ColumnWidth = {'1x'};
            sliderGrid1.Layout.Row = 1;
            sliderGrid1.Layout.Column = [2 6];
            designSlider1 = uislider(sliderGrid1);
            % designSlider1.Layout.Row = 1;
            % designSlider1.Layout.Column = [2 6];
            designSlider1.MajorTickLabels = {};
            designSlider1.MajorTicks = [];

            lowerLabel1 = uilabel(subGrid);
            lowerLabel1.Layout.Row = 2;
            lowerLabel1.Layout.Column = 2;
            
            sliderLabel1 = uilabel(subGrid);
            sliderLabel1.Layout.Row = 2;
            sliderLabel1.Layout.Column = 4;

            upperLabel1 = uilabel(subGrid);
            upperLabel1.Layout.Row = 2;
            upperLabel1.Layout.Column = 6;
            upperLabel1.HorizontalAlignment = 'right';
            
            designSpinner1 = uispinner(subGrid);
            designSpinner1.Layout.Row = 1;
            designSpinner1.Layout.Column = 8;
            designSpinner1.Limits = [0 Inf];
            
            % swap limits 
            frequencyValue = getString(message('Control:compDesignTask:strPIDOptionLabelFrequency'));
            SpecData = get(this, 'SpecData');
            designSlider1.Limits = [SpecData.MinWC, SpecData.MaxWC];
            designSlider1.Value = SpecData.WC;
            designSlider1.MinorTicks = [SpecData.MinWC, (SpecData.MinWC + SpecData.MaxWC)/2, SpecData.MaxWC];
            designSlider1.MajorTicks = [];
            designSlider1.MajorTickLabels = {};

            if strcmp(designDropdown.Value, frequencyValue)
                % Bandwidth Slider - log scale?
                lowerLimit = SpecData.MinWC;
                upperLimit = SpecData.MaxWC;
                value = SpecData.WC;
                lblLowerLimit = string(lowerLimit);
                lblUpperLimit = string(upperLimit);
                lblSlider = {'';pidtool.utPIDgetStrings('cst',...
                        'strBandwidth')};
                % designSpinner1.Limits = [SpecData.MinWC, SpecData.MaxWC];
                designSpinner1.Value = SpecData.WC;
            else
                % Time Slider
                lowerLimit = SpecData.MinWC;
                upperLimit = SpecData.MaxWC;
                value = SpecData.WC;
                lblUpperLimit = getString(message('Control:designerapp:strFaster'));
                lblSlider = {'';getString(message('Control:designerapp:strResponseTime'))};
                lblLowerLimit = getString(message('Control:designerapp:strSlower'));
                % designSpinner1.Limits = [2/SpecData.MaxWC, 2/SpecData.MinWC];
                designSpinner1.Value = 2/SpecData.WC;
            end
                        
            lowerLabel1.Text = lblLowerLimit;
            sliderLabel1.Text = lblSlider;
            upperLabel1.Text = lblUpperLimit;
            % 1 and 50 - Spinner frequency value 
            
            sliderGrid2 = uigridlayout(subGrid,[1 1]);
            sliderGrid2.Padding = 0;
            sliderGrid2.RowHeight = {'fit'};
            sliderGrid2.ColumnWidth = {'1x'};
            sliderGrid2.Layout.Row = 4;
            sliderGrid2.Layout.Column = [2 6];
            designSlider2 = uislider(sliderGrid2);

            lowerLabel2 = uilabel(subGrid);
            lowerLabel2.Layout.Row = 5;
            lowerLabel2.Layout.Column = 2;
            
            sliderLabel2 = uilabel(subGrid);
            sliderLabel2.Layout.Row = 5;
            sliderLabel2.Layout.Column = 4;

            upperLabel2 = uilabel(subGrid);
            upperLabel2.Layout.Row = 5;
            upperLabel2.Layout.Column = 6;  
            upperLabel2.HorizontalAlignment = 'right';

            designSpinner2 = uispinner(subGrid);
            designSpinner2.Layout.Row = 4;
            designSpinner2.Layout.Column = 8;
            
            % swap limits 
            if strcmp(designDropdown.Value, frequencyValue)
                % Phase Margin
                lowerLimit = 0;
                upperLimit = 90;
                value = SpecData.PM;
                lblLowerLimit = string(lowerLimit);
                lblUpperLimit = string(upperLimit);
                lblSlider = {'';pidtool.utPIDgetStrings('cst',...
                        'strPhaseMargin')};
            else
                % Transient Behavior
                lowerLimit = 0;
                upperLimit = 0.9;
                value = SpecData.PM/100;
                lblLowerLimit = getString(message('Control:designerapp:strAggressive'));
                lblSlider = {'';getString(message('Control:designerapp:strTransientBehavior'))};
                lblUpperLimit = getString(message('Control:designerapp:strRobust'));
            end
            
            lowerLabel2.Text = lblLowerLimit;
            sliderLabel2.Text = lblSlider;
            upperLabel2.Text = lblUpperLimit;
            
            designSlider2.Limits = [lowerLimit upperLimit];
            designSlider2.Value = value;
            designSlider2.MinorTicks = [lowerLimit, (lowerLimit+upperLimit)/2, upperLimit];
            designSlider2.MajorTicks = [];
            designSlider2.MajorTickLabels = {};
            
            designSpinner2.Limits = [lowerLimit upperLimit];
            designSpinner2.Value = value;
            
            % reset button
            undoButtonGrid = uigridlayout(subGrid,RowHeight={'1x','fit','1x'},ColumnWidth={'1x'});
            undoButtonGrid.Padding = 0;
            undoButtonGrid.Layout.Row = [2 3]; % [1 3]
            undoButtonGrid.Layout.Column = 8;
            undoButton = uibutton(undoButtonGrid);
            undoButton.Layout.Row = 2;
            undoButton.Text = '';
            matlab.ui.control.internal.specifyIconID(undoButton,'restore',16);
            
            % add to widgets
            
            this.Widgets.RobustGroup.MainGrid = mainGrid;
            this.Widgets.RobustGroup.SubGrid = subGrid;
            this.Widgets.RobustGroup.PIDTypeLabel = ctrlLabel;
            this.Widgets.RobustGroup.PIDDropDown = ctrlDropDown;
            this.Widgets.RobustGroup.PIDFilter = ctrlCheckBox;
            this.Widgets.RobustGroup.PIDDesignLabel = designLabel;
            this.Widgets.RobustGroup.PIDDesignDropdown = designDropdown;
            this.Widgets.RobustGroup.IncButton = increaseButton;
            this.Widgets.RobustGroup.DecButton = decreaseButton; 
            this.Widgets.RobustGroup.Slider1 = designSlider1;
            this.Widgets.RobustGroup.Slider2 = designSlider2;
            this.Widgets.RobustGroup.Spinner1 = designSpinner1;
            this.Widgets.RobustGroup.Spinner2 = designSpinner2;
            this.Widgets.RobustGroup.LowerLabel1 = lowerLabel1;
            this.Widgets.RobustGroup.SliderLabel1 = sliderLabel1;
            this.Widgets.RobustGroup.UpperLabel1 = upperLabel1;
            this.Widgets.RobustGroup.LowerLabel2 = lowerLabel2;
            this.Widgets.RobustGroup.SliderLabel2 = sliderLabel2;
            this.Widgets.RobustGroup.UpperLabel2 = upperLabel2;
            this.Widgets.RobustGroup.UndoButton = undoButton;

            
            
        end
        
        function createClassicTuningWidgets(this)
            
            % create radiobuttons for controllers
            ctrlLabel = uilabel(this.Layout, 'Text', ...
                                  getString(message('Control:designerapp:strPIDTypeLabel')));
            ctrlLabel.Layout.Row = 2;
            ctrlLabel.Layout.Column = 1;
            
            
            ctrlDropDown = uidropdown(this.Layout);
            ctrlDropDown.Layout.Row = 2;
            ctrlDropDown.Layout.Column = 2;
            ctrlDropDown.Items = {'P', 'PI', 'PID', getString(message('Control:designerapp:strPIDDesignFilter'))};
            ctrlDropDown.ItemsData = {'P','PI','PID','pidf'};
            
            % create Formula dropdown
            % create design mode dropdown
            formulaLabel = uilabel(this.Layout, 'Text', ...
                                  getString(message('Control:designerapp:strPIDOptionLabel')));
            formulaLabel.Layout.Row = 3;
            formulaLabel.Layout.Column = 1;
            
            formulaDropdown = uidropdown(this.Layout);
            formulaDropdown.Layout.Row = 3;
            formulaDropdown.Layout.Column = 2;
            formulaDropdown.Items = {getString(message('Control:designerapp:strPIDFormula1')), ...
                                     getString(message('Control:designerapp:strPIDFormula2')), ...
                                     getString(message('Control:designerapp:strPIDFormula3')), ...
                                     getString(message('Control:designerapp:strPIDFormula4')), ...
                                     getString(message('Control:designerapp:strPIDFormula5')), ...
                                     getString(message('Control:designerapp:strPIDFormula6'))};
            
            % add to widgets
            this.Widgets.ClassicGroup.PIDTypeLabel = ctrlLabel;
            this.Widgets.ClassicGroup.PIDDropDown = ctrlDropDown;
            this.Widgets.ClassicGroup.FormulaLabel = formulaLabel;
            this.Widgets.ClassicGroup.FormulaDropdown = formulaDropdown;

            
        end
        
        function createDefaultSpecData(this)
            
            this.SpecData.Preference = 'RRT';
            this.SpecData.DesignDomain = 'time';
            this.SpecData.Formula = 'amigocl';
            this.SpecData.PIDType = 'PI';

            updateResetButton(this);
            
        end

        %% CALLBACKS 
        function connectUI(this)
            w = this.Widgets;
            % add listeners
            % Tuning Dropdown
            weakThis = matlab.lang.WeakReference(this);
            tuningPreferenceListener = addlistener(w.TuningDropdown,...
                               'ValueChanged', @(es,ed)updateTuningDropdown(weakThis.Handle));
            this.UIListeners{1} = tuningPreferenceListener;
            
            lenListeners = length(this.UIListeners);

            if ~isempty(w.RobustGroup) && (lenListeners < 2)
                addRobustListeners(this);
            end
            
            if ~isempty(w.ClassicGroup) && (lenListeners < 2)
                addClassicListeners(this);
            end
            
        end
        
        function addRobustListeners(this)
            weakThis = matlab.lang.WeakReference(this);
             w = this.Widgets;
            % listeners for Controller Type - P, PI,  etc
            robustPIDFilterListener = addlistener(w.RobustGroup.PIDFilter,...
                'ValueChanged', @(es,ed) cbPIDFilterCheckboxChanged(weakThis.Handle));
            robustPIDPreferenceListener = addlistener(w.RobustGroup.PIDDropDown, ...
                'ValueChanged', @(es, ed)updateControllerType(weakThis.Handle));
            filterListener = addlistener(w.RobustGroup.PIDDropDown, ...
                'ValueChanged', @(es, ed)updateControllerType(weakThis.Handle));

            % listeners for Design domain
            robustDesignDomainListener = addlistener(w.RobustGroup.PIDDesignDropdown, ...
                'ValueChanged', @(es, ed)updateDesignDomain(weakThis.Handle));
            
            % listeners for Sliders
            slider1Listener = addlistener(w.RobustGroup.Slider1, ...
                'ValueChanged', @(es, ed)cbSlider1ValueChanged(weakThis.Handle,es));
            slider1ChangingListener = addlistener(w.RobustGroup.Slider1,...
                'ValueChanging', @(es,ed) cbSlider1ValueChanging(weakThis.Handle,ed));
            slider2Listener = addlistener(w.RobustGroup.Slider2, ...
                'ValueChanged', @(es, ed)updateSliderAndSpinner2(weakThis.Handle, es.Value));
            slider2ChangingListener = addlistener(w.RobustGroup.Slider2,...
                'ValueChanging', @(es,ed) cbSlider2ValueChanging(weakThis.Handle,ed));

            % listeners for increase/decrease button
            % increaseButtonListener = addlistener(w.RobustGroup.IncButton,'ButtonPushed',...
            %     )

            % listeners for Spinners
            spinner1Listener = addlistener(w.RobustGroup.Spinner1, ...
                'ValueChanged', @(es, ed)cbSpinner1ValueChanged(weakThis.Handle,es));
            spinner2Listener = addlistener(w.RobustGroup.Spinner2, ...
                'ValueChanged', @(es, ed)updateSliderAndSpinner2(weakThis.Handle, es.Value));
            
            % listeners for inc/dec button
            increaseButtonListener = addlistener(w.RobustGroup.IncButton,...
                'ButtonPushed',@(es,ed) cbIncreaseButtonPushed(weakThis.Handle));
            decreaseButtonListener = addlistener(w.RobustGroup.DecButton,...
                'ButtonPushed',@(es,ed) cbDecreaseButtonPushed(weakThis.Handle));

            % listener for undo button
            undoButtonListener = addlistener(w.RobustGroup.UndoButton, ...
                'ButtonPushed', @(es, ed)updateResetButton(weakThis.Handle));
            
            % add all listeners to UIListener group 
            this.UIListeners{2} = robustPIDPreferenceListener;
            this.UIListeners{3} = filterListener;
            this.UIListeners{4} = robustDesignDomainListener;
            this.UIListeners{5} = slider1Listener;
            this.UIListeners{6} = slider2Listener;
            this.UIListeners{7} = spinner1Listener;
            this.UIListeners{8} = spinner2Listener;
            this.UIListeners{9} = undoButtonListener;
            this.UIListeners{10} = increaseButtonListener;
            this.UIListeners{11} = decreaseButtonListener;
            this.UIListeners{12} = slider1ChangingListener;
            this.UIListeners{13} = slider2ChangingListener;
            this.UIListeners{14} = robustPIDFilterListener;
        end

        function addClassicListeners(this)
             w = this.Widgets;
             weakThis = matlab.lang.WeakReference(this);
            classicPIDTypeListener = addlistener(w.ClassicGroup.PIDDropDown, ...
            'ValueChanged', @(es, ed)updateControllerType(weakThis.Handle));
            this.UIListeners{10} = classicPIDTypeListener;

            classicDesignDomainListener = addlistener(w.ClassicGroup.FormulaDropdown, ...
            'ValueChanged', @(es, ed)updateDesignDomain(weakThis.Handle));
            this.UIListeners{11} = classicDesignDomainListener;
        end

        function refreshUI(this)
            SpecData = get(this, 'SpecData');
            
            % Change TuningDropdown value if needed and run update
            if strcmp(SpecData.Preference,'RRT') && ~strcmp(this.Widgets.TuningDropdown.Value,this.RobustString)
                this.Widgets.TuningDropdown.Value = this.RobustString;
                updateTuningDropdown(this);
            elseif strcmp(SpecData.Preference,'Classical') && ~strcmp(this.Widgets.TuningDropdown.Value,this.ClassicString)
                this.Widgets.TuningDropdown.Value = this.ClassicString;
                updateTuningDropdown(this);
            elseif strcmp(this.Widgets.TuningDropdown.Value,this.RobustString)
                if strcmpi(SpecData.DesignDomain,'time')
                    this.Widgets.RobustGroup.PIDDesignDropdown.Value = this.TimeString;
                else
                    this.Widgets.RobustGroup.PIDDesignDropdown.Value = this.FrequencyString;
                end
                
            end

            if strcmp(this.Widgets.TuningDropdown.Value, this.RobustString)
                isDomainChanged = strcmp(this.Widgets.RobustGroup.PIDDesignDropdown.Value, ...
                    SpecData.DesignDomain);
                % min1 = SpecData.MinWC;
                % max1 = SpecData.MaxWC;
                % wcValue = SpecData.WC;
                % pmValue = SpecData.PM;
                
                if SpecData.MaxWC < getNyquistFreq(this)
                    this.Widgets.RobustGroup.IncButton.Enable = 'on';
                end
                
                % this.Widgets.RobustGroup.Slider1.Limits = [SpecData.MinWC, SpecData.MaxWC];
                % this.Widgets.RobustGroup.Slider1.Value = SpecData.WC;
                % this.Widgets.RobustGroup.Slider1.MinorTicks = ...
                %     [SpecData.MinWC, (SpecData.MinWC + SpecData.MaxWC)/2, SpecData.MaxWC];
                
                this.Widgets.RobustGroup.Spinner1.Limits = [0 getNyquistFreq(this)];

                [TimeUnitString, FreqUnitString] = this.utPIDgetUnitString('Seconds');
                if strcmp(TimeUnitString, 'minutes')
                    TimeUnitString = 'min.';
                    FreqUnitString = 'rad/min.';
                end

                if ~strcmpi(SpecData.DesignDomain,'time')
                    % min1 = SpecData.MinWC; max1 = SpecData.MaxWC;
                    % min2 = 0; max2 = 90;
                    % wcValue = SpecData.WC;
                    % pmValue = SpecData.PM;
                    % this.Widgets.RobustGroup.Spinner1.Limits = [SpecData.MinWC, SpecData.MaxWC];
                    this.Widgets.RobustGroup.Slider1.Limits = [SpecData.MinWC, SpecData.MaxWC];
                    this.Widgets.RobustGroup.Slider1.Value = SpecData.WC;
                    this.Widgets.RobustGroup.Slider1.MinorTicks = ...
                        [SpecData.MinWC, (SpecData.MinWC + SpecData.MaxWC)/2, SpecData.MaxWC];
                    this.Widgets.RobustGroup.Spinner1.Value = SpecData.WC;
                    this.Widgets.RobustGroup.Spinner1.Limits = [0 getNyquistFreq(this)];

                    this.Widgets.RobustGroup.Slider2.Limits = [0, 90];
                    this.Widgets.RobustGroup.Slider2.Value = SpecData.PM;
                    this.Widgets.RobustGroup.Spinner2.Limits = [0, 90];
                    this.Widgets.RobustGroup.Spinner2.Value = SpecData.PM;
                    this.Widgets.RobustGroup.LowerLabel1.Text = string(SpecData.MinWC);
                    this.Widgets.RobustGroup.UpperLabel1.Text = string(SpecData.MaxWC);

                    majorTickLabels1 = {string(this.SpecData.MinWC), [""; [pidtool.utPIDgetStrings('cst',...
                        'strBandwidth') ' (',FreqUnitString, ')']], string(this.SpecData.MaxWC)};
                    
                    majorTickLabels2 = {'0',{''; [pidtool.utPIDgetStrings('cst',...
                                                'strPhaseMargin'), ' (deg)']},'90'};
                    minorTicks = [0,45,90];

                else
                    % min1 = 2/SpecData.MaxWC; max1 = 2/SpecData.MinWC;
                    % min2 = 0; max2 = 0.9;
                    % wcValue = 2/SpecData.WC;
                    % pmValue = SpecData.PM/100;
                    this.Widgets.RobustGroup.Spinner1.Limits = [2/SpecData.MaxWC, 2/SpecData.MinWC];
                    this.Widgets.RobustGroup.Slider1.Limits = [SpecData.MinWC, SpecData.MaxWC];
                    this.Widgets.RobustGroup.Slider1.Value = SpecData.WC;
                    this.Widgets.RobustGroup.Slider1.MinorTicks = ...
                        [SpecData.MinWC, (SpecData.MinWC + SpecData.MaxWC)/2, SpecData.MaxWC];
                    
                    this.Widgets.RobustGroup.Spinner1.Value = 2/SpecData.WC;
                    this.Widgets.RobustGroup.Spinner1.Limits = [2/getNyquistFreq(this) Inf];

                    this.Widgets.RobustGroup.Slider2.Limits = [0, 0.9];
                    this.Widgets.RobustGroup.Slider2.Value = SpecData.PM/100;
                    this.Widgets.RobustGroup.Spinner2.Limits = [0, 0.9];
                    this.Widgets.RobustGroup.Spinner2.Value = SpecData.PM/100;

                    
                    
                    majorTickLabels1 = {string(pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_left')), ...
                        ["";string(pidtool.utPIDgetStrings('cst', 'strResponseTime'))], ...
                        string(pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_right'))};
                     % Transient Behavior
                    majorTickLabels2 = {getString(message('Control:designerapp:strAggressive')),...
                            {'';getString(message('Control:designerapp:strTransientBehavior'))},...
                            getString(message('Control:designerapp:strRobust'))};

                    minorTicks = [0,0.45,0.9];

                end

                this.Widgets.RobustGroup.LowerLabel1.Text = majorTickLabels1{1};
                this.Widgets.RobustGroup.SliderLabel1.Text = majorTickLabels1{2};
                this.Widgets.RobustGroup.UpperLabel1.Text = majorTickLabels1{3};

                this.Widgets.RobustGroup.LowerLabel2.Text = majorTickLabels2{1};
                this.Widgets.RobustGroup.SliderLabel2.Text = majorTickLabels2{2};
                this.Widgets.RobustGroup.UpperLabel2.Text = majorTickLabels2{3};
                this.Widgets.RobustGroup.Slider2.MinorTicks = minorTicks;
                
                % this.Widgets.RobustGroup.PIDDropDown.Value = SpecData.PIDType;
%                 wcValue = SpecData.WC;
%                 pmValue = SpecData.PM;

                % set values in the view
                % this.Widgets.RobustGroup.Slider1.Limits = [min1 max1];
                % this.Widgets.RobustGroup.Spinner1.Limits = [min1 max1];
                % this.Widgets.RobustGroup.Slider2.Limits = [min2 max2];
                % this.Widgets.RobustGroup.Spinner2.Limits = [min2 max2];
                % 
                % this.Widgets.RobustGroup.Slider1.Value = wcValue;
                % this.Widgets.RobustGroup.Spinner1.Value = wcValue;
                % 
                % this.Widgets.RobustGroup.Slider2.Value = pmValue;
                % this.Widgets.RobustGroup.Spinner2.Value = pmValue;

            else
                this.Widgets.ClassicGroup.PIDDropDown.Value = SpecData.PIDType;
                
                f1 = getString(message('Control:designerapp:strPIDFormula1'));
                f2 = getString(message('Control:designerapp:strPIDFormula2'));
                f3 = getString(message('Control:designerapp:strPIDFormula3'));
                f4 = getString(message('Control:designerapp:strPIDFormula4'));
                f5 = getString(message('Control:designerapp:strPIDFormula5'));
                f6 = getString(message('Control:designerapp:strPIDFormula6'));
                
                switch SpecData.Formula
                    case 'amigocl' 
                        this.Widgets.ClassicGroup.FormulaDropdown.Value = f1;
                    case 'amigool'
                        this.Widgets.ClassicGroup.FormulaDropdown.Value = f2;
                    case 'chr'
                        this.Widgets.ClassicGroup.FormulaDropdown.Value = f3;
                    case 'simc'
                        this.Widgets.ClassicGroup.FormulaDropdown.Value = f4;
                    case 'zncl'
                        this.Widgets.ClassicGroup.FormulaDropdown.Value = f5;
                    case 'znol'
                        this.Widgets.ClassicGroup.FormulaDropdown.Value = f6;
                end
            end
        end
        
        %% callbacks for Tuning Methods
        % selection - Classical vs Robust
        function updateTuningDropdown(this)
            
            lenListeners = length(this.UIListeners);
            for i = 2:lenListeners
                delete(this.UIListeners{i});
            end
            if ~isempty(this.Widgets)
                removeSubPanel(this);    
            end

            if isempty(this.Widgets.TuningDropdown) || ...
                    strcmp(this.Widgets.TuningDropdown.Value, this.RobustString)
                this.SpecData.Preference = 'RRT';
                if strcmpi(this.SpecData.PIDType,'pidf')
                    this.SpecData.PIDType = 'PID';
                end
                createRobustTuningWidgets(this);
                % if isempty(this.UIListeners)
                    addRobustListeners(this);
                % end
            elseif strcmp(this.Widgets.TuningDropdown.Value, this.ClassicString)
                this.SpecData.Preference = 'Classical';
                createClassicTuningWidgets(this);
                addClassicListeners(this);
            end
            
            this.notify('SpecDataChanged');
        end
        
        function removeSubPanel(this)

            if (strcmp(this.Widgets.TuningDropdown.Value, this.ClassicString)...
                    && ~isempty(this.Widgets.RobustGroup))
               
                delete(this.Widgets.RobustGroup.MainGrid);
                delete(this.Widgets.RobustGroup.PIDTypeLabel);
                delete(this.Widgets.RobustGroup.PIDDropDown);
                this.Widgets.RobustGroup = [];

            elseif (strcmp(this.Widgets.TuningDropdown.Value, this.RobustString)...
                    && ~isempty(this.Widgets.ClassicGroup))

                delete(this.Widgets.ClassicGroup.PIDTypeLabel)
                delete(this.Widgets.ClassicGroup.PIDDropDown)
                delete(this.Widgets.ClassicGroup.FormulaLabel)
                delete(this.Widgets.ClassicGroup.FormulaDropdown)
                this.Widgets.ClassicGroup = [];
            end

        end

        % ROBUST & CLASSICAL DESIGN PANEL
        % Controller Type - P, PI, PID with check for Filter
        function updateControllerType(this)

            if strcmp(this.Widgets.TuningDropdown.Value, this.RobustString)
                controllerDropdown = this.Widgets.RobustGroup.PIDDropDown;
                controllerFilter = this.Widgets.RobustGroup.PIDFilter;

                % check if the values are PD, PID
                isPD = strcmp(controllerDropdown.Value, ...
                    controllerDropdown.Items(4));
                isPID = strcmp(controllerDropdown.Value, ...
                    controllerDropdown.Items(5));
                if (controllerFilter.Value == 1 && (isPD || isPID))
                    text = [controllerDropdown.Value, 'F'];
                else
                    text = controllerDropdown.Value;
                    controllerFilter.Value = 0;
                end
            elseif strcmp(this.Widgets.TuningDropdown.Value, this.ClassicString)
                controllerDropdown = this.Widgets.ClassicGroup.PIDDropDown;
                text = controllerDropdown.Value;
                % if strcmp(text,getString(message('Control:designerapp:strPIDDesignFilter')))
                %     text = 'pidf';
                % end
            end
            this.SpecData.PIDType = text;
            this.notify('SpecDataChanged');
        end

        function cbPIDFilterCheckboxChanged(this)
            if strcmp(this.Widgets.TuningDropdown.Value, this.RobustString)
                controllerDropdown = this.Widgets.RobustGroup.PIDDropDown;
                controllerFilter = this.Widgets.RobustGroup.PIDFilter;

                % check if the values are PD, PID
                isPD = strcmp(controllerDropdown.Value, ...
                    controllerDropdown.Items(4));
                isPID = strcmp(controllerDropdown.Value, ...
                    controllerDropdown.Items(5));
                if isPD || isPID
                    if controllerFilter.Value
                        text = [controllerDropdown.Value, 'F'];
                    else
                        text = controllerDropdown.Value;
                    end
                    this.SpecData.PIDType = text;
                    this.notify('SpecDataChanged');
                end
            end
        end
        
        % Design Domain Selection - Frequency vs Time
        function updateDesignDomain(this)
            [TimeUnitString, FreqUnitString] = this.utPIDgetUnitString('Seconds');
            if strcmp(TimeUnitString, 'minutes')
                TimeUnitString = 'min.';
                FreqUnitString = 'rad/min.';
            end

            if strcmp(this.Widgets.TuningDropdown.Value, this.RobustString)
                if strcmp(this.Widgets.RobustGroup.PIDDesignDropdown.Value, ...
                    this.FrequencyString)
                    %add to SpecData
                    this.SpecData.DesignDomain = this.FrequencyString;
                    majorTickLabels1 = {string(this.SpecData.MinWC), [""; [pidtool.utPIDgetStrings('cst',...
                        'strBandwidth') ' (',FreqUnitString, ')']], string(this.SpecData.MaxWC)};
                    
                    majorTickLabels2 = {'0',{''; [pidtool.utPIDgetStrings('cst',...
                                                'strPhaseMargin'), ' (deg)']},'90'};
                    minorTicks = [0,45,90];
                else
                    this.SpecData.DesignDomain = 'Time';
                    majorTickLabels1 = {string(pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_left')), ...
                        ["";string(pidtool.utPIDgetStrings('cst', 'strResponseTime'))], ...
                        string(pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_right'))};
                     % Transient Behavior
                    majorTickLabels2 = {getString(message('Control:designerapp:strAggressive')),...
                            {'';getString(message('Control:designerapp:strTransientBehavior'))},...
                            getString(message('Control:designerapp:strRobust'))};

                    minorTicks = [0,0.45,0.9];
                end
                
                this.Widgets.RobustGroup.LowerLabel1.Text = majorTickLabels1{1};
                this.Widgets.RobustGroup.SliderLabel1.Text = majorTickLabels1{2};
                this.Widgets.RobustGroup.UpperLabel1.Text = majorTickLabels1{3};

                this.Widgets.RobustGroup.LowerLabel2.Text = majorTickLabels2{1};
                this.Widgets.RobustGroup.SliderLabel2.Text = majorTickLabels2{2};
                this.Widgets.RobustGroup.UpperLabel2.Text = majorTickLabels2{3};
                this.Widgets.RobustGroup.Slider2.MinorTicks = minorTicks;

                % update the sliders & spinner with values
                % updateSlidersAndSpinnersView(this);
                refreshUI(this);
            else
                switch this.Widgets.ClassicGroup.FormulaDropdown.Value
                    case getString(message('Control:designerapp:strPIDFormula1'))
                        this.SpecData.Formula = 'amigocl';
                    case getString(message('Control:designerapp:strPIDFormula2'))
                        this.SpecData.Formula = 'amigool';
                    case getString(message('Control:designerapp:strPIDFormula3'))
                        this.SpecData.Formula = 'chr';
                    case getString(message('Control:designerapp:strPIDFormula4'))
                        this.SpecData.Formula = 'simc';
                    case getString(message('Control:designerapp:strPIDFormula5'))
                        this.SpecData.Formula = 'zncl';
                    case getString(message('Control:designerapp:strPIDFormula6'))
                        this.SpecData.Formula = 'znol';
                end
            end

            this.notify('SpecDataChanged');

            
        end
        
        % Update Sliders and Spinners
        % function updateSlidersAndSpinnersView(this)
        % 
        %     SpecData = get(this, 'SpecData');
        % 
        %     [TimeUnitString, FreqUnitString] = this.utPIDgetUnitString('Seconds');
        %     if strcmp(TimeUnitString, 'minutes')
        %         TimeUnitString = 'min.';
        %         FreqUnitString = 'rad/min.';
        %     end
        % 
        %     if strcmp(SpecData.DesignDomain, this.FrequencyString)
        %         min1_ = SpecData.MinWC;
        %         max1_ = SpecData.MaxWC;
        %         val1_ = SpecData.WC;
        %         minmaxbounds1 = [realmin getNyquistFreq(this)];
        %         majorTickLabels1 = {string(min1_), [""; [pidtool.utPIDgetStrings('cst',...
        %             'strBandwidth') ' (',FreqUnitString, ')']], string(max1_)};
        % 
        %         min2_ = 0;
        %         max2_ = 90;
        %         val2_ = SpecData.PM;
        %         majorTickLabels2 = {string(min2_), [""; pidtool.utPIDgetStrings('cst',...
        %             'strPhaseMargin') ' (deg)'], string(max2_)};
        % 
        %     else
        %         min1_ = 2/SpecData.MaxWC;
        %         max1_ = 2/SpecData.MinWC;
        %         val1_ = 2/SpecData.WC;
        %         minmaxbounds1 = [2/getNyquistFreq(this) realmax];
        %         majorTickLabels1 = {string(pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_right')), ...
        %             ["";string(pidtool.utPIDgetStrings('cst', 'strResponseTime'))], ...
        %             string(pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_left'))};
        % 
        %         min2_ = 0;
        %         max2_ = 0.9;
        %         val2_ = SpecData.PM/100;
        % 
        %         majorTickLabels2 = {string(pidtool.utPIDgetStrings('cst', 'strAggressive')), ...
        %              ["";string(pidtool.utPIDgetStrings('cst', 'strTransientBehavior'))], ...
        %              string(pidtool.utPIDgetStrings('cst', 'strRobust'))};
        %     end
        % 
        %     MIN1_ = minmaxbounds1(1);
        %     MAX1_ = minmaxbounds1(2);
        %     min1_ = min(max(min1_, MIN1_), MAX1_);
        %     max1_ = max(min(max1_,MAX1_),MIN1_);
        % 
        %     ticks1 = [min1_, (min1_ + max1_)/2, max1_];
        %     ticks2 = [min2_, (min2_ + max2_)/2, max2_];
        % 
        %     if strcmp(SpecData.DesignDomain, this.FrequencyString)
        %         SpecData.MinWC = min1_;
        %         SpecData.MaxWC = max1_;
        %     else
        %         SpecData.MinWC = 2/max1_;
        %         SpecData.MaxWC = 2/min1_;
        %     end
        %     % SpecData.WC = val1_;
        %     % SpecData.PM = val2_;
        %     set(this, 'SpecData', SpecData);
        % 
        %     this.Widgets.RobustGroup.Slider1.MinorTicks = ticks1;
        %     % this.Widgets.RobustGroup.Slider1.MajorTickLabels = majorTickLabels1;
        %     this.Widgets.RobustGroup.Slider1.Limits(1) = min1_;
        %     this.Widgets.RobustGroup.Slider1.Limits(2) = max1_;
        %     this.Widgets.RobustGroup.Slider1.Value = val1_;
        %     this.Widgets.RobustGroup.LowerLabel1.Text = majorTickLabels1{1};
        %     this.Widgets.RobustGroup.SliderLabel1.Text = majorTickLabels1{2};
        %     this.Widgets.RobustGroup.UpperLabel1.Text = majorTickLabels1{3};
        % 
        %     this.Widgets.RobustGroup.Slider2.MinorTicks = ticks2;
        %     % this.Widgets.RobustGroup.Slider2.MajorTickLabels = majorTickLabels2;
        %     this.Widgets.RobustGroup.Slider2.Limits(1) = min2_;
        %     this.Widgets.RobustGroup.Slider2.Limits(2) = max2_;
        %     this.Widgets.RobustGroup.Slider2.Value = val2_;
        %     this.Widgets.RobustGroup.LowerLabel2.Text = majorTickLabels2{1};
        %     this.Widgets.RobustGroup.SliderLabel2.Text = majorTickLabels2{2};
        %     this.Widgets.RobustGroup.UpperLabel2.Text = majorTickLabels2{3};
        % 
        %     % update spinner values
        %     this.Widgets.RobustGroup.Spinner1.Limits = [min1_ max1_];
        %     this.Widgets.RobustGroup.Spinner2.Limits = [min2_ max2_];
        %     this.Widgets.RobustGroup.Spinner1.Value = val1_;
        %     this.Widgets.RobustGroup.Spinner2.Value = val2_;
        % 
        % end

        % function updateSliderAndSpinner1(this, Value)
        %     SpecData = get(this, 'SpecData');
        %     if strcmp(SpecData.DesignDomain, this.FrequencyString)
        %         SpecData.WC = Value;
        %     else
        %         SpecData.WC = 2/Value;
        %     end
        % 
        %     set(this, 'SpecData', SpecData);
        %     this.notify('SpecDataChanged');
        % 
        %     updateUI(this);
        % end

        function cbSlider1ValueChanged(this,es)
            SpecData = get(this,'SpecData');
            SpecData.WC = es.Value;
            set(this,'SpecData',SpecData);
            this.notify('SpecDataChanged');
            updateUI(this);
        end

        function cbSlider1ValueChanging(this,ed)
            if strcmp(this.SpecData.DesignDomain,this.FrequencyString)
                this.Widgets.RobustGroup.Spinner1.Value = ed.Value;
            else
                this.Widgets.RobustGroup.Spinner1.Value = 2/ed.Value;
            end
        end

        function cbSpinner1ValueChanged(this,es)
            SpecData = get(this,'SpecData');
            if strcmp(SpecData.DesignDomain,this.FrequencyString)
                value = es.Value;
            else
                value = 2/es.Value;
            end
            SpecData.WC = value;
            SpecData.MaxWC = min([10*value, getNyquistFreq(this)]);
            SpecData.MinWC = SpecData.MaxWC/100;
            set(this,'SpecData',SpecData);
            this.notify('SpecDataChanged');
            updateUI(this);
        end

        function cbSlider2ValueChanging(this,ed)
            this.Widgets.RobustGroup.Spinner2.Value = ed.Value;
        end

        function updateSliderAndSpinner2(this, Value)
            SpecData = get(this, 'SpecData');
            if strcmp(this.SpecData.DesignDomain, this.FrequencyString)
                SpecData.PM = Value;
            else
                SpecData.PM = 100*Value;
            end
            set(this, 'SpecData', SpecData);
            this.notify('SpecDataChanged');

            updateUI(this);

        end

        function cbIncreaseButtonPushed(this)
            this.SpecData.WC = 10*this.SpecData.WC;
            this.SpecData.MaxWC = 10*this.SpecData.MaxWC;
            this.SpecData.MinWC = 10*this.SpecData.MinWC;

            nyquistFreq = getNyquistFreq(this);
            if this.SpecData.MaxWC > nyquistFreq
                this.SpecData.MaxWC = nyqustFreq;
                this.SpecData.MinWC = (1/100)*nyquistFreq;
                this.SpecData.WC = (1/10)*nyquistFreq;
                this.Widgets.RobustGroup.IncButton.Enable = 'off';
            end
            updateUI(this);
        end

        function cbDecreaseButtonPushed(this)
            this.SpecData.WC = (1/10)*this.SpecData.WC;
            this.SpecData.MaxWC = (1/10)*this.SpecData.MaxWC;
            this.SpecData.MinWC = (1/10)*this.SpecData.MinWC;
            updateUI(this);
        end

        % Reset Button
        function updateResetButton(this)
            % get controller type
            Type = this.SpecData.PIDType;
            % get plant model
            Model = get(this, 'OpenLoopPlant');
            if isempty(Model)
                this.SpecData.PM = 60;
                this.SpecData.WC = 1;
            else
                % create data src object
                DataSrc = pidtool.DataSrcLTI(Model,Type,[]);
                % get WC
                options = pidtuneOptions;
                WC = DataSrc.oneclick(options.PhaseMargin);
                % initialize the design panel with correct frequency unit
                
                this.SpecData.PM = options.PhaseMargin;
                this.SpecData.WC = WC;
            end
            
            this.SpecData.MinWC = 0.1*this.SpecData.WC;
            this.SpecData.MaxWC = 10*this.SpecData.WC;
            updateUI(this);
            this.notify('SpecDataChanged');
        end

        function updateSpecData(this)
            SpecData = get(this, 'SpecData');
            
            % update values
            SpecData.MinWC = this.Widgets.RobustGroup.Slider1.Limits(1);
            SpecData.MaxWC = this.Widgets.RobustGroup.Slider1.Limits(2);
            SpecData.WC = this.Widgets.RobustGroup.Slider1.Value;
            SpecData.PM = this.Widgets.RobustGroup.Slider2.Value;

            set(this, 'SpecData', SpecData);
        end

        function NF = getNyquistFreq(this)
            Model = get(this, 'OpenLoopPlant');
            if Model.Ts > 0
                NF = 3.14159/Model.Ts;
            else
                NF = realmax;
            end
        end

    end

    methods (Static = true)
        function [TimeUnitMsg, FreqUnitMsg, FreqUnit] = utPIDgetUnitString(TimeUnit)
            % UTPIDGETUNITSTRING  Return time/freq unit strings for display and
            % frequency unit based on time unit.
            
            if strcmpi(TimeUnit,'seconds')
                FreqUnit = 'rad/s';
            else
                FreqUnit = ['rad/' lower(TimeUnit(1:end-1))];
            end
            strings = controllibutils.utGetValidTimeUnits;
            TimeUnitMsg = ctrlMsgUtils.message(strings{strcmpi(TimeUnit,strings(:,1)),2});
            strings = controllibutils.utGetValidFrequencyUnits;
            FreqUnitMsg = ctrlMsgUtils.message(strings{strcmp(FreqUnit,strings(:,1)),2});
        end
    end
end