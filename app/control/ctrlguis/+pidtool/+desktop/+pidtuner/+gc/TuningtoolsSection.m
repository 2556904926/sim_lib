classdef TuningtoolsSection < handle
    %TUNINGTOOLSSECTION

    % Copyright 2013-2021 The MathWorks, Inc.
    properties
        TPComponent
        TunerTC
        Slider1
        Slider2
        RefreshModeListeners
        ResetButton
        ParameterTableButton
        ParameterTable
        FrequencyDomain
    end
    properties (Access = private)
        Panel
    end
    methods
        function this = TuningtoolsSection(tunermodel)
            import matlab.ui.internal.toolstrip.*
            
            %TUNINGTOOLSSECTION
            this.TPComponent = Section(pidtool.utPIDgetStrings('cst','strTuningTools'));
            this.TPComponent.Tag = 'Tuning Tools';
            this.TPComponent.CollapsePriority = 9;
            this.TunerTC = tunermodel;
            column1 = this.TPComponent.addColumn();
            ColWidth = 360;
            column2 = this.TPComponent.addColumn('Width',ColWidth);
            column3 = this.TPComponent.addColumn();
            ColWidth = 70;
            column4 = this.TPComponent.addColumn('Width',ColWidth);
            column5 = this.TPComponent.addColumn();
            column6 = this.TPComponent.addColumn();
            %================================================================================================(Layout Widgets)
            
            % Sliders
            this.Slider1 = pidtool.desktop.pidtuner.gc.RichSlider_v2();
            this.Slider1.Scale = 'logarithmic';
            this.Slider1.SliderTPComponent.Ticks = 5;
            this.Slider1.SliderTPComponent.Tag = 'PIDTUNER_FREQUENCYSLIDER';
            this.Slider1.SpinnerTPComponent.Tag = 'PIDTUNER_FREQUENCYSPINNER';
            this.Slider1.RangeUpTPComponent.Tag = 'PIDTUNER_FREQUENCYRANGEUPBUTTON';
            this.Slider1.RangeDownTPComponent.Tag = 'PIDTUNER_FREQUENCYRANGEDOWNBUTTON';
            this.Slider1.SpinnerTPComponent.Limits = [realmin realmax];
            this.Slider1.RangeUpTPComponent.Description = getString(message('Control:pidtool:ttipRangeUpTime'));
            this.Slider1.RangeDownTPComponent.Description = getString(message('Control:pidtool:ttipRangeDownTime'));
            TPComponentSettings = struct('Min',0,'Max',90);
            this.Slider1.SpinnerTPComponent.Description = getString(message('Control:pidtool:ttipResponseTimeEdit'));
            this.Slider2 = pidtool.desktop.pidtuner.gc.RichSlider_v2(10,20,15,TPComponentSettings);
            this.Slider2.Resolution = 100;
            this.Slider2.SliderTPComponent.Ticks = 6;
            this.Slider2.SliderTPComponent.Tag = 'PIDTUNER_PHASEMARGINSLIDER';
            this.Slider2.SpinnerTPComponent.Tag = 'PIDTUNER_PHASEMARGINSPINNER';
            this.Slider2.SpinnerTPComponent.Description = getString(message('Control:pidtool:ttipTransientBehaviorEdit'));
            this.updateSlidersView([],[]);
            
            % Get proper slider widths
            SliderLabels = {pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_left') 0;...
                            pidtool.utPIDgetStrings('cst', 'strResponseTime') 50;...
                            pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_right') 100};
            this.Slider1.SliderTPComponent.Labels = SliderLabels;
            this.Slider1.SliderTPComponent.UseSmallFont = true;
            SliderLabels = {pidtool.utPIDgetStrings('cst', 'strAggressive') 0;...
                            pidtool.utPIDgetStrings('cst', 'strTransientBehavior') 50;...
                            pidtool.utPIDgetStrings('cst', 'strRobust') 100};
            this.Slider2.SliderTPComponent.Labels = SliderLabels;
            this.Slider2.SliderTPComponent.UseSmallFont = true;

            % Add slider widgets
            column1.add(this.Slider1.RangeDownTPComponent);
            column1.addEmptyControl();
            column1.addEmptyControl();
            column2.add(this.Slider1.SliderTPComponent);
            column2.add(this.Slider2.SliderTPComponent);
            column3.add(this.Slider1.RangeUpTPComponent);
            column3.addEmptyControl();
            column3.addEmptyControl();
            column4.add(this.Slider1.SpinnerTPComponent);
            column4.addEmptyControl();
            column4.add(this.Slider2.SpinnerTPComponent);

            % Reset Design Button
            this.ResetButton = Button(pidtool.utPIDgetStrings('cst', 'strResetDesign'),Icon('revert'));
            this.ResetButton.Tag = 'PIDTUNER_RESETDESIGNBUTTON';
            this.ResetButton.ButtonPushedFcn = @(~,~) resetButtonCallback(this);
            this.ResetButton.Description = getString(message('Control:pidtool:toolbar_tooltip_reset'));
            
            % Show Parameters Button
            this.ParameterTableButton = Button(pidtool.utPIDgetStrings('cst', 'strShowParams'),Icon('tableHeaderHighlighted'));
            this.ParameterTableButton.Tag = 'PIDTUNER_PARAMETERTABLEBUTTON';
            this.ParameterTableButton.ButtonPushedFcn = @(~,~) parameterTableCallback(this);
            this.ParameterTableButton.Description = getString(message('Control:pidtool:ttipShowParametersButton'));

            % Add components to section
            column5.add(this.ResetButton);
            column6.add(this.ParameterTableButton);

            %=====================================================================================================(Listeners)
            addlistener(this.TunerTC.InputVariables,'WC','PostSet', @this.updateSlider1Value);
            addlistener(this.TunerTC.InputVariables,'PM','PostSet', @this.updateSlider2Value);
            addlistener(this.TunerTC.InputVariables, 'DesignDomain', 'PostSet', @this.updateSlidersView);
            addlistener(this.TunerTC.InputVariables, 'WCLimitsReset', @this.updateSlidersView);
            addlistener(this.TunerTC.ControllerList, 'DesiredController','PostSet', @this.updateSlidersView);
            addlistener(this.Slider1,'Value','PostSet', @this.slider1ValueCallback);
            addlistener(this.Slider1,'MinimumValue','PostSet', @this.slider1LimitsCallback);
            addlistener(this.Slider1,'MaximumValue','PostSet', @this.slider1LimitsCallback);
            addlistener(this.Slider1,'DataChanged', @this.slider1DataChangeCallback);
            addlistener(this.Slider2,'Value','PostSet', @this.slider2ValueCallback);
            addlistener(this.Slider2,'DataChanged', @this.slider2ValueCallback);

        end
        %======================================================================================================(Sliders View)
        function updateSlidersView(this,~,~)
            %UPDATESLIDERSVIEW
            [TimeUnitString, FreqUnitString] = pidtool.utPIDgetUnitString(this.TunerTC.PlantList.SelectedPlantTimeUnit);
            if strcmp(TimeUnitString, 'minutes')
                TimeUnitString = 'min.';
                FreqUnitString = 'rad/min.';
            end
            inputvars = this.TunerTC.InputVariables;

            if strcmp(inputvars.DesignDomain, 'frequency')
                min1_ = inputvars.MinWC;
                max1_ = inputvars.MaxWC;
                val1_ = inputvars.WC;
                minmaxbounds1 = [realmin this.TunerTC.NyquistFreq];
                rightincreasing1 = true;
                ticks1 = {'value','tick',[pidtool.utPIDgetStrings('cst', 'strBandwidth') ' (',FreqUnitString, ')'] ,'tick','value'};
                labeltable1 = [];
                numTicks1 = [];
                
                min2_ = 0;
                max2_ = 90;
                val2_ = inputvars.PM;
                minmaxbounds2 =[0 90];
                rightincreasing2 = [];
                ticks2 = {'value','tick',[pidtool.utPIDgetStrings('cst', 'strPhaseMargin') ' (deg)'],'tick','value'};
                labeltable2 = [];
                numTicks2 = [];
                
                this.FrequencyDomain = true;
                
                this.Slider1.RangeUpTPComponent.Description = getString(message('Control:pidtool:ttipRangeUpFrequency'));
                this.Slider1.RangeDownTPComponent.Description = getString(message('Control:pidtool:ttipRangeDownFrequency'));
                this.Slider1.SpinnerTPComponent.Description = getString(message('Control:pidtool:ttipBandwidthEdit'));
                this.Slider2.SpinnerTPComponent.Description = getString(message('Control:pidtool:ttipPhaseMarginEdit'));
            else
                min1_ = inputvars.MinRT;
                max1_ = inputvars.MaxRT;
                val1_ = inputvars.ResponseTime;
                minmaxbounds1 = [2/this.TunerTC.NyquistFreq realmax];
                rightincreasing1 = false;
                ticks1 = [];
                labeltable1 = {pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_left') 0;...
                            [pidtool.utPIDgetStrings('cst', 'strResponseTime') ' (',TimeUnitString ,')'] 50;...
                            pidtool.utPIDgetStrings('cst', 'tunerdlg_respslider_right') 100};
                numTicks1 = 5;
                min2_ = 0;
                max2_ = 0.9;
                val2_ = inputvars.TransientBehavior;
                minmaxbounds2 =[0 0.9];
                rightincreasing2 = [];
                ticks2 = [];                
                labeltable2 = {pidtool.utPIDgetStrings('cst', 'strAggressive') 0;...
                            pidtool.utPIDgetStrings('cst', 'strTransientBehavior') 50;...
                            pidtool.utPIDgetStrings('cst', 'strRobust') 100};
                numTicks2 = 5;
                this.FrequencyDomain = false;
                
                this.Slider1.RangeUpTPComponent.Description = getString(message('Control:pidtool:ttipRangeUpTime'));
                this.Slider1.RangeDownTPComponent.Description = getString(message('Control:pidtool:ttipRangeDownTime'));
                this.Slider1.SpinnerTPComponent.Description = getString(message('Control:pidtool:ttipResponseTimeEdit'));
                this.Slider2.SpinnerTPComponent.Description = getString(message('Control:pidtool:ttipTransientBehaviorEdit'));
            end
            
            MIN1_ = minmaxbounds1(1);
            MAX1_ = minmaxbounds1(2);
            min1_ = min(max(min1_, MIN1_), MAX1_);
            max1_ = max(min(max1_,MAX1_),MIN1_);
            
            this.Slider1.atomicSet(min1_,max1_,val1_,minmaxbounds1,rightincreasing1,ticks1,labeltable1,numTicks1);
            this.Slider2.atomicSet(min2_,max2_,val2_,minmaxbounds2,rightincreasing2,ticks2,labeltable2,numTicks2);
            
            if strcmpi(this.TunerTC.ControllerList.DesiredType, 'p') || ...
                    strcmpi(this.TunerTC.ControllerList.DesiredType, 'i')
                this.Slider2.Free = false;
            else
                this.Slider2.Free = true;
            end
        end
        %===============================================================================================(Data -> View update)
        function updateSlider1Value(this,~,~)
            %UPDATESLIDER1VALUE
            if this.FrequencyDomain
                this.Slider1.Value =  this.TunerTC.InputVariables.WC;
            else
                this.Slider1.Value =  this.TunerTC.InputVariables.ResponseTime;
            end
        end
        function updateSlider1Limits(this)
            %UPDATESLIDER1LIMITS
            if this.FrequencyDomain
                this.Slider1.MinimumValue = this.TunerTC.InputVariables.MinWC;
                this.Slider1.MaximumValue = this.TunerTC.InputVariables.MaxWC;
            else
                this.Slider1.MinimumValue = this.TunerTC.InputVariables.MinRT;
                this.Slider1.MaximumValue = this.TunerTC.InputVariables.MaxRT;
            end
        end
        function updateSlider2Value(this,~,~)
            %UPDATESLIDER2VALUE
            if this.FrequencyDomain
                this.Slider2.Value =  this.TunerTC.InputVariables.PM;
            else
                this.Slider2.Value =  this.TunerTC.InputVariables.TransientBehavior;
            end
        end
        %==================================================================================================(Widget Callbacks)
        function slider1ValueCallback(this,~,~)
            %SLIDER1VALUECALLBACK
            % drawnow
            if this.FrequencyDomain
                this.TunerTC.InputVariables.WC = this.Slider1.Value;
            else
                this.TunerTC.InputVariables.ResponseTime = this.Slider1.Value;
            end
        end
        function slider2ValueCallback(this,~,~)
            %SLIDER2VALUECALLBACK
            % drawnow
            if this.FrequencyDomain
                this.TunerTC.InputVariables.PM = this.Slider2.Value;
            else
                this.TunerTC.InputVariables.TransientBehavior = this.Slider2.Value;
            end
        end
        function slider1LimitsCallback(this,~,~)
            %SLIDER1LIMITSCALLBACK
            if this.FrequencyDomain
                this.TunerTC.InputVariables.MinWC = this.Slider1.MinimumValue;
                this.TunerTC.InputVariables.MaxWC = this.Slider1.MaximumValue;
                this.Slider1.SliderTPComponent.Labels{1,1} = num2str(this.Slider1.MinimumValue);
                this.Slider1.SliderTPComponent.Labels{3,1} = num2str(this.Slider1.MaximumValue);
            else
                this.TunerTC.InputVariables.MinRT = this.Slider1.MinimumValue;
                this.TunerTC.InputVariables.MaxRT = this.Slider1.MaximumValue;
            end
        end
        function slider1DataChangeCallback(this,~,~)
            %SLIDER1DATACHANGECALLBACK
            slider1ValueCallback(this);
            slider1LimitsCallback(this);
        end
        function sliderRefreshModeCallback(this,~,~,val)
            %SLIDERREFRESHMODECALLBACK
            this.TunerTC.DataSourcePlot.QuickRefreshMode = val;
        end
        function parameterTableCallback(this,~, ~)
            %PARAMETERTABLECALLBACK
            isRegisterDlg = false;
            if isempty(this.ParameterTable)
                this.ParameterTable = pidtool.desktop.pidtuner.gc.ParameterTable(this.TunerTC.DataSourcePlot);
                isRegisterDlg = true;
            end
            show(this.ParameterTable,[]);
            if isRegisterDlg
                registerDialog(this.TunerTC.DialogManager,this.ParameterTable);
            end
            centerDialog(this.TunerTC.DialogManager,this.ParameterTable.Name)
            
        end
        function resetButtonCallback(this,~,~)
            %RESETBUTTONCALLBACK
            this.TunerTC.InputVariables.PM = 60;
            this.TunerTC.oneClick();
            this.TunerTC.DataSourcePlot.QuickRefreshMode = false;
            this.TunerTC.setStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_reset_info'),'info');
        end

    end
end
