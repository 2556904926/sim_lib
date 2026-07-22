classdef PIDTunerApp < matlab.task.LiveTask
    %PIDTUNERAPP Embedded app to tune a PID controller for an LTI object and
    %generate the corresponding source code.
    %
    % See also PIDTUNER

    % Copyright 2018-2022 The MathWorks, Inc.

    properties (Hidden, Access = public)
        UIAxes                          matlab.ui.control.UIAxes

        Accordion                       matlab.ui.container.internal.Accordion

        PlantDropDown                   matlab.ui.control.internal.model.WorkspaceDropDown
        BaselineControllerDropDown      matlab.ui.control.internal.model.WorkspaceDropDown

        FormDropDown                    matlab.ui.control.DropDown

        DegreesOfFreedomDropDown        matlab.ui.control.DropDown

        TypeDropDown                    matlab.ui.control.DropDown

        DomainDropDown                  matlab.ui.control.DropDown

        BandwidthEditField              matlab.ui.control.NumericEditField
        BandwidthSlider                 matlab.ui.control.Slider
        PhaseMarginEditField            matlab.ui.control.NumericEditField
        PhaseMarginSlider               matlab.ui.control.Slider
        ResponseTimeEditField           matlab.ui.control.NumericEditField
        ResponseTimeSlider              matlab.ui.control.Slider
        TransientBehaviorEditField      matlab.ui.control.NumericEditField
        TransientBehaviorSlider         matlab.ui.control.Slider

        DesignFocusDropDown             matlab.ui.control.DropDown
        IntegralFormulaDropDown         matlab.ui.control.DropDown
        FilterFormulaDropDown           matlab.ui.control.DropDown

        PlotSelectDropDown              matlab.ui.control.DropDown
        ShowBaselineDropDown            matlab.ui.control.DropDown
        ShowPerformanceCriteriaCheckbox

        DecreaseSliderRange             matlab.ui.control.Button
        IncreaseSliderRange             matlab.ui.control.Button

        OptionsButton
        OptionsGrid                     matlab.ui.container.GridLayout

        % Plot Settings
        PlotType(1,:) char = 'step'
        LoopType(1,:) char = 'r2y'

    end

    properties (Access = private)
        UIGridLayout                        matlab.ui.container.GridLayout
        PlantGrid                           matlab.ui.container.GridLayout
        ControllerSettingsGrid              matlab.ui.container.GridLayout
        PerformanceGoalsGrid                matlab.ui.container.GridLayout
        VisualizeGrid                       matlab.ui.container.GridLayout

        PlantAccordionPanel                 matlab.ui.container.internal.AccordionPanel
        ControllerSettingsAccordionPanel    matlab.ui.container.internal.AccordionPanel
        PerformanceGoalsAccordionPanel      matlab.ui.container.internal.AccordionPanel
        OptionsAccordionPanel               matlab.ui.container.internal.AccordionPanel
        VisualizeAccordionPanel             matlab.ui.container.internal.AccordionPanel

        PlantSelectSectionLabel             matlab.ui.control.Label
        ControllerInfoSectionLabel          matlab.ui.control.Label
        PerformanceInfoSectionLabel         matlab.ui.control.Label
        OutputPlotsSectionLabel             matlab.ui.control.Label

        PlantLabel                          matlab.ui.control.Label
        PlantDescription                    matlab.ui.control.Label

        BaselineControllerLabel             matlab.ui.control.Label

        FormLabel                           matlab.ui.control.Label

        DegreesOfFreedomLabel               matlab.ui.control.Label

        TypeLabel                           matlab.ui.control.Label

        DomainLabel                         matlab.ui.control.Label

        DesignFocusLabel                    matlab.ui.control.Label
        IntegralFormulaLabel                matlab.ui.control.Label
        FilterFormulaLabel                  matlab.ui.control.Label

        PlotLabel                           matlab.ui.control.Label

        WidgetListeners

        InitControl(1,1) logical = true

        DefaultState

        IsValidPlant(1,1) logical = false

        ShowPerformanceCriteria(1,1) logical = false

    end

    properties (Constant, Access = private)
        SelectLabel(1,:) char = 'select variable' % This is for ItemsData property
    end

    % Icons
    properties (Constant, Access = protected)
        CollapsedIcon = fullfile(matlabroot,'toolbox','shared','controllib','general','resources','collapsed.png')
        ExpandedIcon = fullfile(matlabroot,'toolbox','shared','controllib','general','resources','expanded.png')
    end

    properties (Access = public, SetObservable = true)
        Form(1,1) double{mustBeInteger, mustBePositive} = 1
        DegreesOfFreedom(1,1) double{mustBeInteger, mustBePositive} = 1
        Type(1,:) char = 'PI'
        Domain(1,1) double{mustBeInteger, mustBePositive} = 1
        Bandwidth(1,1) double {mustBeReal, mustBeFinite, mustBePositive} = 5
        PhaseMargin(1,1) double {mustBeReal, mustBeFinite, mustBeNonnegative} = 60
        DesignFocus(1,:) char = 'balanced'
        IntegralFormula(1,:) char = 'ForwardEuler'
        FilterFormula(1,:) char = 'ForwardEuler'

        Plant(:,:)
    end

    properties (Access = public, SetObservable = true, Dependent = true)
        Ts(1,1) double{mustBeReal, mustBeFinite, mustBeNonnegative}
    end

    properties
        State
        Summary
    end

    methods
        function app = PIDTunerApp

        end

        %% Live Tasks Common Functions
        function [code, outputs] = generateCode(app)
            % code - A char array of code in script form that corresponds to the
            % current state of the app
            % outputs - A cell array containing a subset of the  important output
            % variables Appears and executes as a part of the host script
            var = app.PlantDropDown.Value;
            if strcmp(var, app.SelectLabel) % No variable selected
                code = '';
                outputs = {};
            else
                % Generate business logic code
                [code, outputs] = generatePIDTuningCode(app);

                % Create visualization code
                visualizationCode = generateVisualizationCode(app);
                if ~isempty(visualizationCode)
                    code = [code newline newline visualizationCode];
                end
            end
        end

        function summary = get.Summary(app)
            % summary - A char array of summary line that captures the current
            % activity of the app presented to the user at the top of the app and
            % also when the app is collapsed
            var = app.PlantDropDown.Value;
            if strcmp(var, app.SelectLabel)
                summary = m('Control:embedded_apps:pidTunerStaticSummary');
            else
                if app.Form == 1
                    form = m('Control:embedded_apps:parallel');
                else
                    form = m('Control:embedded_apps:standard');
                end
                if app.IsValidPlant
                    [TimeUnitString, FreqUnitString] = pidtool.utPIDgetUnitString(app.Plant.TimeUnit);
                    if strcmp(TimeUnitString, 'minutes')
                        TimeUnitString = 'min.';
                        FreqUnitString = 'rad/min.';
                    end
                else
                    TimeUnitString = 'seconds';
                    FreqUnitString = 'rad/s';
                end
                if app.Domain == 1 % Time Domain
                    args = {app.Type, form, var, sprintf('%g',2/app.Bandwidth), TimeUnitString};
                    summary = m('Control:embedded_apps:pidTunerDynamicSummary_Time',args);
                else               % Frequency Domain
                    args = {app.Type, form, var, sprintf('%g',app.Bandwidth), FreqUnitString};
                    summary = m('Control:embedded_apps:pidTunerDynamicSummary_Frequency',args);
                end
            end
        end

        function code = generateVisualizationCode(app)
            % Get input arguments
            PlotType = app.PlotType;
            isShowPerf = app.ShowPerformanceCriteria;
            switch app.LoopType
                case 'plant'
                    LoopType = 'plant';
                case 'olsys'
                    LoopType = 'open-loop'; %#ok<*PROP>
                case 'r2y'
                    LoopType = 'closed-loop';
                case 'r2u'
                    LoopType = 'controller-effort';
                case 'id2y'
                    LoopType = 'input-disturbance';
                case 'od2y'
                    LoopType = 'output-disturbance';
                case 'none'
                    LoopType = 'NA';
            end

            % Don't generate visualization code if Plant is 'select variable'
            if strcmp(app.PlantDropDown.Value,app.SelectLabel)
                LoopType = 'NA';
            end

            % Don't plot baseline if checkbox is unchecked and/or baseline
            % controller is 'select variable'
            if strcmp(app.BaselineControllerDropDown.Value,app.SelectLabel) || ...
                    strcmp(app.ShowBaselineDropDown.Value,'none') || ...
                    strcmp(LoopType,'plant')
                isPlotBaseline = false;
            else
                isPlotBaseline = true;
            end

            % Initalize Response Argument
            ResponseArg1 = '';
            if strcmp(LoopType,'NA')
                code = '';
            else
                code3 = m('Control:embedded_apps:codeCommentPlot2');
                if strcmp(LoopType,'plant')
                    plotArg = sprintf('`%s`',app.PlantDropDown.Value);
                    if isPlotBaseline
                        plotArg = [plotArg ',''-'',' sprintf('%s',app.BaselineControllerDropDown),',''--'''];
                    end
                    code_plot = [code3 newline 'f=figure();'];
                    code_plot = [code_plot newline sprintf('%splot(f,%s)',PlotType,plotArg)];
                else
                    code1 = m('Control:embedded_apps:codeCommentPlot1');
                    if isPlotBaseline
                        ResponseArg1 = '_Tuned';
                    end
                    code2 = sprintf('%s = getPIDLoopResponse(C,`%s`,''%s'');',...
                        ['Response' ResponseArg1], app.PlantDropDown.Value,LoopType);

                    % Plotting Arguments
                    plotArg = ['Response' ResponseArg1];

                    if isPlotBaseline
                        code_baseline = sprintf('Response_Baseline = getPIDLoopResponse(`%s`,`%s`,''%s'');',...
                            app.BaselineControllerDropDown.Value, app.PlantDropDown.Value,LoopType);
                        code2 = [code2 newline code_baseline];

                        % Get Plotting Command
                        plotArg = [plotArg ',''-'', Response_Baseline, ''--'''];
                        code_legend = [newline sprintf('legend(''%s'', ''%s'');',...
                            m('Control:pidtool:plotpanel_tunedresp'), m('Control:pidtool:plotpanel_baseresp'))];
                    else
                        code_legend = '';
                    end
                    code_plot = [code1 newline code2 newline newline code3 newline 'f=figure();'];
                    code_plot = [code_plot newline sprintf('%splot(f,%s)',PlotType,plotArg) code_legend];
                end
                figtitle = app.getFigureTitle();
                code_plot = [code_plot newline sprintf('title(''%s'')',figtitle) newline 'grid on'];

                if isShowPerf

                    % Get System Characteristics Argument
                    isGetResponse = (~strcmp(LoopType,'closed-loop') && strcmp(PlotType,'step')) || (~strcmp(LoopType,'open-loop') && strcmp(PlotType,'bode'));
                    if isGetResponse
                        inputArg = 'Response';
                    else
                        inputArg = ['Response' ResponseArg1];
                    end

                    % Code for PID Info
                    switch PlotType
                        case 'step'
                            ResponseArg = 'closed-loop';
                            code_info = sprintf('disp(stepinfo(%s))',inputArg);
                        case 'bode'
                            ResponseArg = 'open-loop';
                            code_info = sprintf('disp(allmargin(%s))',inputArg);
                    end

                    % Get appropriate response for system info, if necessary
                    if isGetResponse
                        code_resp = [newline sprintf('Response = getPIDLoopResponse(C,`%s`,''%s'');',app.PlantDropDown.Value,ResponseArg)];
                    else
                        code_resp = '';
                    end
                    code_info = [newline newline m('Control:embedded_apps:codeCommentPlot3') code_resp newline code_info];
                else
                    code_info = '';
                end

                % Clear Temporary Variable Response, if applicable
                if contains(plotArg,'Response') || isShowPerf
                    if ~isempty(ResponseArg1)
                        if isShowPerf && isGetResponse
                            code_clear = 'clear f Response Response_Tuned Response_Baseline;';
                        else
                            code_clear = 'clear f Response_Tuned Response_Baseline;';
                        end
                    else
                        code_clear = 'clear f Response;';
                    end

                    code_clear = [newline newline  m('Control:embedded_apps:codeCommentClearVariables') newline code_clear];
                else
                    code_clear = [newline newline  m('Control:embedded_apps:codeCommentClearVariables') newline 'clear f;'];
                end

                % Get Final Code
                code = [code_plot code_info code_clear];
            end
        end

        function set.State(app, state)
            % UPDATESTATE
            app.InitControl = false; %#ok<*MCSUP>

            % Reset list of variables in dropdown
            app.PlantDropDown.populateVariables()

            % Honor Last User Selected Plant even if not valid
            valid = true;
            if ~any(contains(app.PlantDropDown.ItemsData,state.PlantName))
                app.PlantDropDown.Items = [app.PlantDropDown.Items {state.PlantName}];
                app.PlantDropDown.ItemsData = [app.PlantDropDown.ItemsData {state.PlantName}];
                valid = false;
            end
            valid = ~strcmp(state.PlantName, app.SelectLabel) && valid;
            app.IsValidPlant = valid;

            % Handle Invalid Plant
            app.PlantDropDown.Value = state.PlantName;
            if app.IsValidPlant
                app.Plant = evalin('base', state.PlantName);
            else
                app.Plant = [];
                app.DefaultState.SampleTime = state.SampleTime;
            end

            % Honor Last User Selected Baseline Controller even if not valid
            if ~any(contains(app.BaselineControllerDropDown.ItemsData,state.BaselineControllerName))
                app.BaselineControllerDropDown.Items = [app.BaselineControllerDropDown.Items {state.BaselineControllerName}];
                app.BaselineControllerDropDown.ItemsData = [app.BaselineControllerDropDown.ItemsData {state.BaselineControllerName}];
            end
            app.BaselineControllerDropDown.Value = state.BaselineControllerName;

            % Enable Widgets
            wdgtEnable = ~strcmp(state.PlantName, app.SelectLabel);
            app.enableAll(wdgtEnable);

            % Update Widgets
            if wdgtEnable
                app.updateWidgetValues(state)
            end

        end

        function state = get.State(app)
            % CURRENTSTATE
            state.Form = app.Form;
            state.DegreesOfFreedom = app.DegreesOfFreedom;
            state.Type = app.Type;
            state.Domain = app.Domain;
            state.Bandwidth = app.Bandwidth;
            state.PhaseMargin = app.PhaseMargin;
            state.DesignFocus = app.DesignFocus;
            state.IntegralFormula = app.IntegralFormula;
            state.FilterFormula = app.FilterFormula;
            state.PlantName = app.PlantDropDown.Value;
            state.SampleTime = app.Ts;
            state.PlotType = app.PlotType;
            state.LoopType = app.LoopType;
            state.BaselineControllerName = app.BaselineControllerDropDown.Value;
            state.ShowPerformanceCriteria = app.ShowPerformanceCriteria;
        end

        function reset(app)
            % RESET
            app.resetAppToDefault();
        end
    end

    %% Abstract methods
    methods (Access = protected)
        function setup(app)
            % Create and configure components
            createComponents(app)

            % Execute the startup function
            startupFcn(app)

            % Default Settings
            app.DefaultState.Form = 1;
            app.DefaultState.DegreesOfFreedom = 1;
            app.DefaultState.Type = 'PI';
            app.DefaultState.Domain = 1;
            app.DefaultState.Bandwidth = 5;
            app.DefaultState.PhaseMargin = 60;
            app.DefaultState.DesignFocus = 'balanced';
            app.DefaultState.IntegralFormula = 'ForwardEuler';
            app.DefaultState.FilterFormula = 'ForwardEuler';
            app.DefaultState.PlantName = app.SelectLabel;
            app.DefaultState.SampleTime = 0;
            app.DefaultState.PlotType = 'step';
            app.DefaultState.LoopType = 'r2y';
            app.DefaultState.BaselineControllerName = app.SelectLabel;
            app.DefaultState.ShowPerformanceCriteria = false;
        end
    end

    %% Private Methods
    methods (Access = private)
        %% Create Components
        function createComponents(app)
            % CREATECOMPONENTS
            app.createFigureGridComponents();
            app.createPlantSelectComponents();
            app.createControllerSettingsComponents();
            app.createPerformanceGoalsComponents();
            app.createOptionalSettingsComponents();
            app.createPlotComponents();
        end

        function createFigureGridComponents(app)
            % CREATEFIGUREGRIDCOMPONENTS

            % Create UIGridLayout
            app.LayoutManager.Padding = 0;
            app.UIGridLayout = uigridlayout(app.LayoutManager);
            app.UIGridLayout.ColumnWidth = {'1x'};
            app.UIGridLayout.RowHeight = {'fit'};

            % Initialize Accordian
            app.Accordion = matlab.ui.container.internal.Accordion('Parent', app.UIGridLayout);

            % Select Plant Section
            app.PlantAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            app.PlantAccordionPanel.Title = m('Control:embedded_apps:secPlantSelect');
            app.PlantGrid = uigridlayout(app.PlantAccordionPanel);
            app.PlantGrid.Padding = [20 15 0 10];
            app.PlantGrid.ColumnWidth = {'fit',140,'fit',140,'1x'};
            app.PlantGrid.RowHeight = {22};

            % Controller Settings Section
            app.ControllerSettingsAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            app.ControllerSettingsAccordionPanel.Title = m('Control:embedded_apps:secControllerSettings');
            app.ControllerSettingsGrid = uigridlayout(app.ControllerSettingsAccordionPanel);
            app.ControllerSettingsGrid.Padding = [20 15 0 10];
            app.ControllerSettingsGrid.ColumnWidth = {'fit',90,'fit',90,'fit',90,'1x'};
            app.ControllerSettingsGrid.RowHeight = {22};

            % Performance Goals Section
            app.PerformanceGoalsAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            app.PerformanceGoalsAccordionPanel.Title = m('Control:embedded_apps:secPerformanceSettings');
            app.PerformanceGoalsGrid = uigridlayout(app.PerformanceGoalsAccordionPanel);
            app.PerformanceGoalsGrid.Padding = [20 15 0 10];
            app.PerformanceGoalsGrid.ColumnWidth = {'fit',90,25,280,25,75,'1x'};
            app.PerformanceGoalsGrid.RowHeight = {22,10,22,10};

            % Options Section
            app.OptionsAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            app.OptionsAccordionPanel.Title = m('Control:embedded_apps:secOptionalParameters');
            app.OptionsAccordionPanel.Collapsed = true;
            app.OptionsGrid = uigridlayout(app.OptionsAccordionPanel);
            app.OptionsGrid.Padding = [20 15 0 10];
            app.OptionsGrid.ColumnWidth = {'fit',150,'fit',150,'1x'};
            app.OptionsGrid.RowHeight = {22,22};

            % Visualize Results Section
            app.VisualizeAccordionPanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            app.VisualizeAccordionPanel.Title = m('Control:embedded_apps:secOutputPlots');
            app.VisualizeGrid = uigridlayout(app.VisualizeAccordionPanel);
            app.VisualizeGrid.Padding = [20 15 0 10];
            app.VisualizeGrid.ColumnWidth = {'fit',250,'fit','1x'};
            app.VisualizeGrid.RowHeight = {22,22};

        end

        function createPlantSelectComponents(app)
            % CREATEPLANTSELECTCOMPONENTS

            % Plant Selection Widgets
            app.PlantLabel = uilabel(app.PlantGrid);
            app.PlantLabel.Layout.Row = 1;
            app.PlantLabel.Layout.Column = 1;
            app.PlantLabel.Text = m('Control:embedded_apps:plant');

            app.PlantDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.PlantGrid);
            app.PlantDropDown.Tooltip = m('Control:embedded_apps:tooltipPlant');
            app.PlantDropDown.Layout.Row = 1;
            app.PlantDropDown.Layout.Column = 2;
            app.PlantDropDown.FilterVariablesFcn = @(x) filterWorkspaceVariables(x);
            app.PlantDropDown.ValueChangedFcn = @(~,e)cbPlantDropDownValueChanged(app,e);

            app.PlantDescription = uilabel(app.PlantGrid);
            app.PlantDescription.Layout.Column = 3;
            app.PlantDescription.Visible = 'off';

        end

        function createControllerSettingsComponents(app)
            % CREATECONTROLLERSETTINGSCOMPONENTS

            % Form Dropdown
            app.FormLabel = uilabel(app.ControllerSettingsGrid);
            app.FormLabel.Layout.Row = 1;
            app.FormLabel.Layout.Column = 1;
            app.FormLabel.Text = m('Control:embedded_apps:form');

            app.FormDropDown = uidropdown(app.ControllerSettingsGrid);
            app.FormDropDown.Layout.Row = 1;
            app.FormDropDown.Layout.Column = 2;
            app.FormDropDown.Items = {m('Control:embedded_apps:parallel'); m('Control:embedded_apps:standard')};
            app.FormDropDown.ItemsData = {'parallel';'standard'};
            app.FormDropDown.Value = 'parallel';
            app.FormDropDown.ValueChangedFcn = @(~,evt)cbControllerForm(app,evt);

            % Degrees of Freedom Dropdown
            app.DegreesOfFreedomLabel = uilabel(app.ControllerSettingsGrid);
            app.DegreesOfFreedomLabel.Layout.Row = 1;
            app.DegreesOfFreedomLabel.Layout.Column = 3;
            app.DegreesOfFreedomLabel.Text = m('Control:embedded_apps:dof');

            app.DegreesOfFreedomDropDown = uidropdown(app.ControllerSettingsGrid);
            app.DegreesOfFreedomDropDown.Layout.Row = 1;
            app.DegreesOfFreedomDropDown.Layout.Column = 4;
            app.DegreesOfFreedomDropDown.Items = {m('Control:embedded_apps:dof_1');m('Control:embedded_apps:dof_2')};
            app.DegreesOfFreedomDropDown.ItemsData = {'1DOF';'2DOF'};
            app.DegreesOfFreedomDropDown.Value = '1DOF';
            app.DegreesOfFreedomDropDown.ValueChangedFcn = @(~,evt)cbDegreesOfFreedomCallback(app,evt);

            % Controller Type
            app.TypeLabel = uilabel(app.ControllerSettingsGrid);
            app.TypeLabel.Layout.Row = 1;
            app.TypeLabel.Layout.Column = 5;
            app.TypeLabel.Text = m('Control:embedded_apps:controllerType');

            app.TypeDropDown = uidropdown(app.ControllerSettingsGrid);
            app.TypeDropDown.Tooltip = m('Control:embedded_apps:tooltipControllerType');
            app.TypeDropDown.Layout.Row = 1;
            app.TypeDropDown.Layout.Column = 6;
            app.TypeDropDown.Items = {'P','I','PI','PD','PID','PDF','PIDF'};
            app.TypeDropDown.Value = 'PI';
            app.TypeDropDown.ValueChangedFcn = @(~,evt)cbControllerTypeDropDownValueChanged(app,evt);
        end

        function createPerformanceGoalsComponents(app)
            % CREATEPERFORMANCEGOALSCOMPONENTS

            % Domain Type Dropdown
            app.DomainLabel = uilabel(app.PerformanceGoalsGrid);
            app.DomainLabel.Layout.Row = 1;
            app.DomainLabel.Layout.Column = 1;
            app.DomainLabel.Text = m('Control:embedded_apps:domain');

            app.DomainDropDown = uidropdown(app.PerformanceGoalsGrid);
            app.DomainDropDown.Layout.Row = 1;
            app.DomainDropDown.Layout.Column = 2;
            app.DomainDropDown.Items = {m('Control:embedded_apps:time'); m('Control:embedded_apps:frequency')};
            app.DomainDropDown.ItemsData = {'time'; 'frequency'};
            app.DomainDropDown.Value = 'time';
            app.DomainDropDown.ValueChangedFcn = @(~,evt)cbDomainSelectCallback(app,evt);

            % Response Time
            app.ResponseTimeSlider = uislider(app.PerformanceGoalsGrid);
            app.ResponseTimeSlider.Tag = 'ResponseTimeSlider';
            app.ResponseTimeSlider.Layout.Row = [1,2];
            app.ResponseTimeSlider.Layout.Column = 4;
            app.ResponseTimeSlider.Limits = [0.2 2];
            app.ResponseTimeSlider.Value = 0.4;
            app.ResponseTimeSlider.MajorTicks = [0.2 1.1 2];
            app.ResponseTimeSlider.MinorTicks = [];
            app.ResponseTimeSlider.MajorTickLabels = {'0.2', m('Control:embedded_apps:responseTime'), '2'};
            app.ResponseTimeSlider.ValueChangedFcn = @(~,evt)cbResponseTimeSliderValueChanged(app,evt);

            app.ResponseTimeEditField = uieditfield(app.PerformanceGoalsGrid, 'numeric');
            app.ResponseTimeEditField.Tag = 'ResponseTimeEditField';
            app.ResponseTimeEditField.Tooltip = m('Control:embedded_apps:tooltipResponseTime');
            app.ResponseTimeEditField.Layout.Row = 1;
            app.ResponseTimeEditField.Layout.Column = 6;
            app.ResponseTimeEditField.Limits = [0 inf];
            app.ResponseTimeEditField.LowerLimitInclusive = 'off';
            app.ResponseTimeEditField.UpperLimitInclusive = 'off';
            app.ResponseTimeEditField.Value = 0.4;
            app.ResponseTimeEditField.ValueDisplayFormat = '%g';
            app.ResponseTimeEditField.ValueChangedFcn = @(~,evt)cbResponseTimeEditFieldValueChanged(app,evt);

            % Transient Behavior
            app.TransientBehaviorSlider = uislider(app.PerformanceGoalsGrid);
            app.TransientBehaviorSlider.Tag = 'TransientBehaviorSlider';
            app.TransientBehaviorSlider.Layout.Row = [3,4];
            app.TransientBehaviorSlider.Layout.Column = 4;
            app.TransientBehaviorSlider.Limits = [0 0.9];
            app.TransientBehaviorSlider.Value = 0.6;
            app.TransientBehaviorSlider.MajorTicks = [0 0.45 0.9];
            app.TransientBehaviorSlider.MinorTicks = [];
            app.TransientBehaviorSlider.MajorTickLabels = {'0', m('Control:embedded_apps:transientBehavior'), '0.9'};
            app.TransientBehaviorSlider.ValueChangedFcn = @(~,evt)cbTransientBehaviorSliderValueChanged(app,evt);

            app.TransientBehaviorEditField = uieditfield(app.PerformanceGoalsGrid, 'numeric');
            app.TransientBehaviorEditField.Tag = 'TransientBehaviorEditField';
            app.TransientBehaviorEditField.Tooltip = m('Control:embedded_apps:tooltipTransientBehavior');
            app.TransientBehaviorEditField.Layout.Row = 3;
            app.TransientBehaviorEditField.Layout.Column = 6;
            app.TransientBehaviorEditField.Limits = [0 0.9];
            app.TransientBehaviorEditField.Value = 0.6;
            app.TransientBehaviorEditField.ValueDisplayFormat = '%g';
            app.TransientBehaviorEditField.ValueChangedFcn = @(~,evt)cbTransientBehaviorEditFieldValueChanged(app,evt);

            % Bandwidth
            app.BandwidthSlider = uislider(app.PerformanceGoalsGrid);
            app.BandwidthSlider.Tag = 'BandwidthSlider';
            app.BandwidthSlider.Layout.Row = [1,2];
            app.BandwidthSlider.Layout.Column = 4;
            app.BandwidthSlider.Visible = 'off';
            app.BandwidthSlider.Limits = [1 10];
            app.BandwidthSlider.Value = 5;
            app.BandwidthSlider.MajorTicks = [1 5.5 10];
            app.BandwidthSlider.MinorTicks = [];
            app.BandwidthSlider.MajorTickLabels = {'1', m('Control:embedded_apps:bandwidth'), '10'};
            app.BandwidthSlider.ValueChangedFcn = @(~,evt)cbBandwidthSliderValueChanged(app,evt);

            app.BandwidthEditField = uieditfield(app.PerformanceGoalsGrid, 'numeric');
            app.BandwidthEditField.Tag = 'BandwidthEditField';
            app.BandwidthEditField.Tooltip = m('Control:embedded_apps:tooltipBandwidth');
            app.BandwidthEditField.Layout.Row = 1;
            app.BandwidthEditField.Layout.Column = 6;
            app.BandwidthEditField.Visible = 'off';
            app.BandwidthEditField.Limits = [0 inf];
            app.BandwidthEditField.LowerLimitInclusive = 'off';
            app.BandwidthEditField.UpperLimitInclusive = 'off';
            app.BandwidthEditField.Value = 5;
            app.BandwidthEditField.ValueDisplayFormat = '%g';
            app.BandwidthEditField.ValueChangedFcn = @(~,evt)cbBandwidthEditFieldValueChanged(app,evt);

            % Phase Margin
            app.PhaseMarginSlider = uislider(app.PerformanceGoalsGrid);
            app.PhaseMarginSlider.Tag = 'PhaseMarginEditField';
            app.PhaseMarginSlider.Layout.Row = [3,4];
            app.PhaseMarginSlider.Layout.Column = 4;
            app.PhaseMarginSlider.Visible = 'off';
            app.PhaseMarginSlider.Limits = [0 90];
            app.PhaseMarginSlider.Value = 60;
            app.PhaseMarginSlider.MajorTicks = [0 45 90];
            app.PhaseMarginSlider.MinorTicks = [];
            app.PhaseMarginSlider.MajorTickLabels = {'0', m('Control:embedded_apps:phaseMargin'), '90'};
            app.PhaseMarginSlider.ValueChangedFcn = @(~,evt)cbPhaseMarginSliderValueChanged(app,evt);

            app.PhaseMarginEditField = uieditfield(app.PerformanceGoalsGrid, 'numeric');
            app.PhaseMarginEditField.Tag = 'PhaseMarginEditField';
            app.PhaseMarginEditField.Tooltip = m('Control:embedded_apps:tooltipPhaseMargin');
            app.PhaseMarginEditField.Layout.Row = 3;
            app.PhaseMarginEditField.Layout.Column = 6;
            app.PhaseMarginEditField.Visible = 'off';
            app.PhaseMarginEditField.Limits = [0 90];
            app.PhaseMarginEditField.Value = 60;
            app.PhaseMarginEditField.ValueDisplayFormat = '%g';
            app.PhaseMarginEditField.ValueChangedFcn = @(~,evt)cbPhaseMarginEditFieldValueChanged(app,evt);

            % Range Buttons
            app.DecreaseSliderRange = uibutton(app.PerformanceGoalsGrid);
            app.DecreaseSliderRange.Text = '<<';
            app.DecreaseSliderRange.Tag = 'DecreaseSliderRange';
            app.DecreaseSliderRange.Tooltip = m('Control:embedded_apps:tooltipDecreaseSliderRange');
            app.DecreaseSliderRange.Layout.Row = 1;
            app.DecreaseSliderRange.Layout.Column = 3;
            app.DecreaseSliderRange.ButtonPushedFcn = @(~,evt)cbSliderButtonPressed(app,evt,'decrease');

            app.IncreaseSliderRange = uibutton(app.PerformanceGoalsGrid);
            app.IncreaseSliderRange.Text = '>>';
            app.IncreaseSliderRange.Tag = 'IncreaseSliderRange';
            app.IncreaseSliderRange.Tooltip = m('Control:embedded_apps:tooltipIncreaseSliderRange');
            app.IncreaseSliderRange.Layout.Row = 1;
            app.IncreaseSliderRange.Layout.Column = 5;
            app.IncreaseSliderRange.ButtonPushedFcn = @(~,evt)cbSliderButtonPressed(app,evt,'increase');
        end

        function createOptionalSettingsComponents(app)
            % CREATEOPTIONALSETTINGSCOMPONENTS

            % Design Focus Dropdown
            app.DesignFocusLabel = uilabel(app.OptionsGrid);
            app.DesignFocusLabel.Layout.Row = 1;
            app.DesignFocusLabel.Layout.Column = 1;
            app.DesignFocusLabel.Text = m('Control:embedded_apps:designFocusLabel');

            app.DesignFocusDropDown = uidropdown(app.OptionsGrid);
            app.DesignFocusDropDown.Layout.Row = 1;
            app.DesignFocusDropDown.Layout.Column = 2;
            app.DesignFocusDropDown.Items = {m('Control:embedded_apps:designFocusCombo_1'),...
                m('Control:embedded_apps:designFocusCombo_2'), m('Control:embedded_apps:designFocusCombo_3')};
            app.DesignFocusDropDown.ItemsData = {'balanced';'reference-tracking';'disturbance-rejection'};
            app.DesignFocusDropDown.Value = 'balanced';
            app.DesignFocusDropDown.ValueChangedFcn = @(~,evt)cbDesignFocus(app,evt);

            % Integrator Formula Dropdown
            app.IntegralFormulaLabel = uilabel(app.OptionsGrid);
            app.IntegralFormulaLabel.Layout.Row = 2;
            app.IntegralFormulaLabel.Layout.Column = 1;
            app.IntegralFormulaLabel.Text = m('Control:embedded_apps:iformula_label');

            app.IntegralFormulaDropDown = uidropdown(app.OptionsGrid);
            app.IntegralFormulaDropDown.Layout.Row = 2;
            app.IntegralFormulaDropDown.Layout.Column = 2;
            app.IntegralFormulaDropDown.Items = {m('Control:embedded_apps:formula_combo1'),...
                m('Control:embedded_apps:formula_combo2'), m('Control:embedded_apps:formula_combo3')};
            app.IntegralFormulaDropDown.ItemsData = {'ForwardEuler';'BackwardEuler';'Trapezoidal'};
            app.IntegralFormulaDropDown.Value = 'ForwardEuler';
            app.IntegralFormulaDropDown.ValueChangedFcn = @(~,evt)cbIntegralFormula(app,evt);

            % Filter Formula Dropdown
            app.FilterFormulaLabel = uilabel(app.OptionsGrid);
            app.FilterFormulaLabel.Layout.Row = 2;
            app.FilterFormulaLabel.Layout.Column = 3;
            app.FilterFormulaLabel.Text = m('Control:embedded_apps:dformula_label');

            app.FilterFormulaDropDown = uidropdown(app.OptionsGrid);
            app.FilterFormulaDropDown.Layout.Row = 2;
            app.FilterFormulaDropDown.Layout.Column = 4;
            app.FilterFormulaDropDown.Items = {m('Control:embedded_apps:formula_combo1'),...
                m('Control:embedded_apps:formula_combo2'), m('Control:embedded_apps:formula_combo3')};
            app.FilterFormulaDropDown.ItemsData = {'ForwardEuler';'BackwardEuler';'Trapezoidal'};
            app.FilterFormulaDropDown.Value = 'ForwardEuler';
            app.FilterFormulaDropDown.ValueChangedFcn = @(~,evt)cbFilterFormula(app,evt);
        end

        function createPlotComponents(app)
            % CREATEPLOTCOMPONENTS

            % Plot Select
            app.PlotLabel = uilabel(app.VisualizeGrid);
            app.PlotLabel.Layout.Row = 1;
            app.PlotLabel.Layout.Column = 1;
            app.PlotLabel.Text = m('Control:embedded_apps:outputPlot');

            app.PlotSelectDropDown = uidropdown(app.VisualizeGrid);
            app.PlotSelectDropDown.Layout.Row = 1;
            app.PlotSelectDropDown.Layout.Column = 2;
            app.PlotSelectDropDown.Items = {m('Control:embedded_apps:stepPlot_plant'); m('Control:embedded_apps:stepPlot_olsys');...
                m('Control:embedded_apps:stepPlot_r2y'); m('Control:embedded_apps:stepPlot_r2u');...
                m('Control:embedded_apps:stepPlot_id2y'); m('Control:embedded_apps:stepPlot_od2y');...
                m('Control:embedded_apps:bodePlot_plant'); m('Control:embedded_apps:bodePlot_olsys');...
                m('Control:embedded_apps:bodePlot_r2y'); m('Control:embedded_apps:bodePlot_r2u');...
                m('Control:embedded_apps:bodePlot_id2y'); m('Control:embedded_apps:bodePlot_od2y');...
                m('Control:embedded_apps:none')};
            app.PlotSelectDropDown.ItemsData = {'step_plant';'step_olsys';'step_r2y';'step_r2u';'step_id2y';'step_od2y';...
                'bode_plant';'bode_olsys';'bode_r2y';'bode_r2u';'bode_id2y';'bode_od2y';'none'};
            app.PlotSelectDropDown.Value = 'step_r2y';
            app.PlotSelectDropDown.ValueChangedFcn = @(~,evt)cbPlotSelectDropDownValueChanged(app,evt);

            % Show Performance Criteria Checkbox
            app.ShowPerformanceCriteriaCheckbox = uicheckbox(app.VisualizeGrid);
            app.ShowPerformanceCriteriaCheckbox.Layout.Row = 1;
            app.ShowPerformanceCriteriaCheckbox.Layout.Column = 3;
            app.ShowPerformanceCriteriaCheckbox.Text = m('Control:embedded_apps:showSysRespCharacteristics');
            app.ShowPerformanceCriteriaCheckbox.ValueChangedFcn = @(~,evt)cbShowPerformanceCriteria(app,evt);

            % Baseline Controller Widgets
            app.BaselineControllerLabel = uilabel(app.VisualizeGrid);
            app.BaselineControllerLabel.Layout.Row = 2;
            app.BaselineControllerLabel.Layout.Column = 1;
            app.BaselineControllerLabel.Text = m('Control:embedded_apps:baselineController');

            app.ShowBaselineDropDown = uidropdown(app.VisualizeGrid);
            app.ShowBaselineDropDown.Layout.Row = 2;
            app.ShowBaselineDropDown.Layout.Column = 2;
            app.ShowBaselineDropDown.Items = {m('Control:embedded_apps:none');m('Control:embedded_apps:selectFromWorkspace')};
            app.ShowBaselineDropDown.ItemsData = {'none';'fromworkspace'};
            app.ShowBaselineDropDown.Value = 'none';
            app.ShowBaselineDropDown.ValueChangedFcn = @(~,evt)cbShowBaseline(app,evt);

            app.BaselineControllerDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.VisualizeGrid);
            app.BaselineControllerDropDown.Tooltip = m('Control:embedded_apps:tooltipBaselineController');
            app.BaselineControllerDropDown.Layout.Row = 2;
            app.BaselineControllerDropDown.Layout.Column = 3;
            app.BaselineControllerDropDown.Items = {app.SelectLabel};
            app.BaselineControllerDropDown.Value = app.SelectLabel;
            app.BaselineControllerDropDown.Visible = false;
            app.BaselineControllerDropDown.FilterVariablesFcn = @(x) filterWorkspaceVariablesC0(x);
        end

        function startupFcn(app)
            % STARTUPFCN
            L1 = addlistener(app,'Domain','PostSet', @(~,evt)cbDomainSelectCallback(app,evt));
            app.WidgetListeners = L1;

            % Initialize widgets
            selected = app.PlantDropDown.Value;
            valid = ~strcmp(selected, app.SelectLabel);
            if ~valid
                app.enableAll(false);
            end
            app.updateControllerTypeDropDownItems();

            % Set Default for Controller Type
            app.TypeDropDown.Value = 'PI';
        end

        %% Widget Callbacks
        function cbPlantDropDownValueChanged(app, evt)
            value = evt.Value;
            valid = ~strcmp(value, app.SelectLabel);
            app.enableAll(valid);

            % Set flag for initial controller to true
            app.InitControl = true;

            if valid
                app.Plant = evalin('base', value);
                app.DefaultState.SampleTime = app.Plant.Ts;
            else
                app.Plant = [];
                app.DefaultState.SampleTime = 0;
            end
            app.IsValidPlant = valid;

            % Reset app when new plant is selected
            app.resetAppToDefault()

        end

        function cbDomainSelectCallback(app,evt)
            % Get Which Domain is Selected
            if isa(evt,'event.PropertyEvent')   % Triggered from Listener
                DomainSelected = app.Domain;
            else
                DomainSelected = strcmp(evt.Value,'frequency') + 1;
            end
            app.WidgetListeners(1).Enabled = false;
            app.Domain = DomainSelected;
            app.WidgetListeners(1).Enabled = true;

            updateSliderVisibilities(app)
        end

        function cbControllerForm(app,evt)
            % Get Which Domain is Selected
            ControllerForm = strcmp(evt.Value,'standard') + 1;
            app.Form = ControllerForm;

            % Update Dropdown for Controller Form
            ctrlType = app.TypeDropDown.Value;
            updateControllerTypeDropDownItems(app)

            % Use default controller type if I control was previously selected
            if strcmp(ctrlType,'I')
                app.TypeDropDown.Value = 'PI';
                app.Type = 'PI';
            end


        end

        function cbDegreesOfFreedomCallback(app,evt)
            % Get Which Domain is Selected
            DOF = strcmp(evt.Value,'2DOF') + 1;
            app.DegreesOfFreedom = DOF;

            % Update Dropdown for Controller Type
            ctrlType = app.TypeDropDown.Value;
            updateControllerTypeDropDownItems(app)

            % Update PID Type to 1DoF/2DoF equivalent otherwise use default
            switch DOF
                case 1
                    ctrlType = erase(ctrlType,'2');
                    app.TypeDropDown.Value = ctrlType;
                    app.Type = ctrlType;
                case 2
                    if length(ctrlType) == 1 % P or I control selected
                        app.TypeDropDown.Value = 'PI2';
                        app.Type = 'PI2';
                    else
                        app.TypeDropDown.Value = horzcat(ctrlType,'2');
                        app.Type = horzcat(ctrlType,'2');
                    end
            end
            app.updateSliderVisibilities()

        end

        function cbControllerTypeDropDownValueChanged(app,evt)
            value = evt.Value;
            app.Type = value;

            enableIntegralFilterMethods(app)
            updateSliderVisibilities(app)
        end

        function cbShowBaseline(app,evt)
            value = evt.Value;
            if strcmp(value,'none')
                app.BaselineControllerDropDown.Visible = false;
            else
                app.BaselineControllerDropDown.Visible = true;
            end
        end

        function cbShowPerformanceCriteria(app,evt)
            value = evt.Value;
            app.ShowPerformanceCriteria = value;
        end

        function cbDesignFocus(app,evt)
            value = evt.Value;
            app.DesignFocus = value;
        end

        function cbIntegralFormula(app,evt)
            value = evt.Value;
            app.IntegralFormula = value;
        end

        function cbFilterFormula(app,evt)
            value = evt.Value;
            app.FilterFormula = value;
        end

        function cbPlotSelectDropDownValueChanged(app,evt)
            % Get Plot
            PlotSelected = evt.Value;

            if ~strcmp(PlotSelected,evt.PreviousValue)
                if length(PlotSelected)>4
                    plotType = PlotSelected(1:4);
                    loopType = PlotSelected(6:end);
                else
                    plotType = 'none';
                    loopType = 'none';
                end

                if strcmp(plotType,'step')
                    % Check if current plant is FRD
                    if isa(app.Plant,'frd')
                        app.PlotType = 'bode';
                        app.PlotSelectDropDown.Value = horzcat('bode_',app.LoopType);
                        error(m('Control:embedded_apps:errorFRDModels'));
                    end
                end
                app.PlotType = plotType;
                app.LoopType = loopType;

                % Disable Show Baseline if no plot is selected or plant is
                % plotted
                if strcmp(plotType,'none') || strcmp(loopType,'plant')
                    app.ShowBaselineDropDown.Visible = false;
                    app.BaselineControllerDropDown.Visible = false;
                    app.BaselineControllerLabel.Visible = false;

                    % Adjust Grid
                    app.VisualizeGrid.RowHeight = {22,0};

                else
                    app.ShowBaselineDropDown.Visible = true;
                    app.BaselineControllerLabel.Visible = true;
                    tmp.Value = app.ShowBaselineDropDown.Value;
                    app.cbShowBaseline(tmp);

                    % Adjust Grid
                    app.VisualizeGrid.RowHeight = {22,22};
                end

                % Disable Performance Checkbox if no plot is selected
                if strcmp(plotType,'none')
                    app.ShowPerformanceCriteriaCheckbox.Enable = false;
                else
                    app.ShowPerformanceCriteriaCheckbox.Enable = true;
                end
            end
        end

        % Response Time Widget Linking
        function cbResponseTimeEditFieldValueChanged(app,evt)
            % Check bounds for Slider
            EditFieldValue = app.ResponseTimeEditField.Value;

            % Update Slider Limits
            updateSliderLimits(app,evt,EditFieldValue);

            % Update Response Time Slider Value
            RTSliderValue = EditFieldValue;

            % Update Values
            app.ResponseTimeSlider.Value = RTSliderValue;
            app.BandwidthSlider.Value = 2/EditFieldValue;
            app.BandwidthEditField.Value = 2/EditFieldValue;

            % Store Values
            app.Bandwidth = 2/EditFieldValue;
        end

        function cbResponseTimeSliderValueChanged(app,evt)
            SliderValue = evt.Value;
            RTValue = SliderValue;

            % Update Slider Limits
            updateSliderLimits(app,evt,RTValue);

            % Update Values
            app.ResponseTimeEditField.Value = RTValue;
            app.BandwidthEditField.Value = 2/RTValue;
            app.BandwidthSlider.Value = 2/RTValue;

            % Store Values
            app.Bandwidth = 2/RTValue;
        end

        % Transient Behavior Linking
        function cbTransientBehaviorEditFieldValueChanged(app,~)
            EditFieldValue = app.TransientBehaviorEditField.Value;
            app.TransientBehaviorSlider.Value = EditFieldValue;
            app.PhaseMarginEditField.Value = EditFieldValue*100;
            app.PhaseMarginSlider.Value = EditFieldValue*100;

            % Store Values
            app.PhaseMargin = EditFieldValue*100;
        end

        function cbTransientBehaviorSliderValueChanged(app,evt)
            SliderValue = evt.Value;
            app.TransientBehaviorEditField.Value = SliderValue;
            app.PhaseMarginEditField.Value = SliderValue*100;
            app.PhaseMarginSlider.Value = SliderValue*100;

            % Store Values
            app.PhaseMargin = SliderValue*100;
        end

        % Bandwidth Widget Linking
        function cbBandwidthEditFieldValueChanged(app,evt)
            % Check bounds for Slider
            EditFieldValue = app.BandwidthEditField.Value;

            % Update Slider Limits
            updateSliderLimits(app,evt,EditFieldValue);

            % Update Values
            RTEditFieldValue = 2/EditFieldValue;
            RTSliderValue = RTEditFieldValue;
            app.BandwidthSlider.Value = EditFieldValue;
            app.ResponseTimeSlider.Value = RTSliderValue;
            app.ResponseTimeEditField.Value = RTEditFieldValue;

            % Store Values
            app.Bandwidth = EditFieldValue;
        end

        function cbBandwidthSliderValueChanged(app,evt)
            SliderValue = evt.Value;

            % Update Slider Limits
            updateSliderLimits(app,evt,SliderValue);

            % Update Response Time Slider Value

            % Update Values
            RTEditFieldValue = 2/SliderValue;
            RTSliderValue = RTEditFieldValue;
            app.BandwidthEditField.Value = SliderValue;
            app.ResponseTimeEditField.Value = RTEditFieldValue;
            app.ResponseTimeSlider.Value = RTSliderValue;

            % Store Values
            app.Bandwidth = SliderValue;
        end

        % Phase Margin Linking
        function cbPhaseMarginEditFieldValueChanged(app,~)

            EditFieldValue = app.PhaseMarginEditField.Value;
            app.PhaseMarginSlider.Value = EditFieldValue;
            app.TransientBehaviorEditField.Value = EditFieldValue/100;
            app.TransientBehaviorSlider.Value = EditFieldValue/100;

            % Store Values
            app.PhaseMargin = EditFieldValue;
        end

        function cbPhaseMarginSliderValueChanged(app,evt)
            SliderValue = evt.Value;
            app.PhaseMarginEditField.Value = SliderValue;
            app.TransientBehaviorEditField.Value = SliderValue/100;
            app.TransientBehaviorSlider.Value = SliderValue/100;

            % Store Values
            app.PhaseMargin = SliderValue;
        end

        %% Update Slider Limits
        function cbSliderButtonPressed(app,evt,btnType)
            % Get val argument for UPDATESLIDERLIMITS

            % Handle Time Domain Case
            if app.Domain == 1 % Time Domain
                switch btnType
                    case 'decrease'
                        btnType = 'increase';
                    case 'increase'
                        btnType = 'decrease';
                end
            end

            switch btnType
                case 'decrease'
                    val = app.BandwidthSlider.Limits(1);
                    scale = 1/10;
                case 'increase'
                    val = app.BandwidthSlider.Limits(2);
                    scale = 10;
            end
            updateSliderLimits(app,evt,val)

            % Update Field Values
            BandwidthValue = app.Bandwidth;
            app.BandwidthEditField.Value = BandwidthValue*scale;
            app.BandwidthSlider.Value = BandwidthValue*scale;

            % Update Response Time Slider Value
            RTEditFieldValue = 2/(BandwidthValue*scale);
            RTSliderValue = RTEditFieldValue;

            app.ResponseTimeEditField.Value = RTEditFieldValue;
            app.ResponseTimeSlider.Value = RTSliderValue;
            app.Bandwidth = BandwidthValue*scale;
        end

        function updateSliderLimits(app,evt,val)
            % Slider1 is the current active slider and Slider2 is the invisible
            % slider (i.e. if in Time Domain, Slider1 corresponds to the
            % Response Time Slider and Slider2 the Bandwidth Slider)
            % Check bounds for Slider

            % Get Event Source
            WidgetSourceType = erase(evt.Source.Tag,{'EditField', 'Slider'});
            switch WidgetSourceType
                case 'ResponseTime'
                    Slider1 = app.ResponseTimeSlider;
                    Slider2 = app.BandwidthSlider;
                    ScaleFactor1 = 2;
                case 'Bandwidth'
                    Slider1 = app.BandwidthSlider;
                    Slider2 = app.ResponseTimeSlider;
                    ScaleFactor1 = 1;
                otherwise % From Button
                    Slider1 = app.BandwidthSlider;
                    Slider2 = app.ResponseTimeSlider;
                    ScaleFactor1 = 1;
            end

            % Update Slider Limits
            SliderLimits = Slider1.Limits;
            update = false;
            if val < SliderLimits(1)
                BaseValue = floor(log10(val/ScaleFactor1));
                NewSliderLimits1(1) = 10^BaseValue*ScaleFactor1;
                NewSliderLimits1(2) = 10^(BaseValue+1)*ScaleFactor1;
                update = true;
            elseif val == SliderLimits(1)
                BaseValue = floor(log10(SliderLimits(1)/ScaleFactor1))-1;
                NewSliderLimits1(1) = 10^BaseValue*ScaleFactor1;
                NewSliderLimits1(2) = 10^(BaseValue+1)*ScaleFactor1;
                update = true;
            end

            if val > SliderLimits(2)
                BaseValue = ceil(log10(val/ScaleFactor1));
                NewSliderLimits1(2) = 10^BaseValue*ScaleFactor1;
                NewSliderLimits1(1) = 10^(BaseValue-1)*ScaleFactor1;
                update = true;
            elseif val == SliderLimits(2)
                BaseValue = ceil(log10(SliderLimits(2)/ScaleFactor1))+1;
                NewSliderLimits1(2) = 10^BaseValue*ScaleFactor1;
                NewSliderLimits1(1) = 10^(BaseValue-1)*ScaleFactor1;
                update = true;
            end

            % Update Limits and Ticks, if necessary
            if update
                NewSliderLimits2 = sort(2./NewSliderLimits1);
                Slider1.Limits = NewSliderLimits1;
                Slider2.Limits = NewSliderLimits2;

                MidTick = (NewSliderLimits1(2) + NewSliderLimits1(1))/2;
                Slider1.MajorTicks = [NewSliderLimits1(1) MidTick NewSliderLimits1(2)];

                Slider1.MajorTickLabels{1} = num2str(NewSliderLimits1(1));
                Slider1.MajorTickLabels{3} = num2str(NewSliderLimits1(2));

                MidTick = (NewSliderLimits2(2) + NewSliderLimits2(1))/2;
                Slider2.MajorTicks = [NewSliderLimits2(1) MidTick NewSliderLimits2(2)];

                Slider2.MajorTickLabels{1} = num2str(NewSliderLimits2(1));
                Slider2.MajorTickLabels{3} = num2str(NewSliderLimits2(2));
            end
        end

        %% Widget Update Methods
        function enableAll(app, state)
            app.FormDropDown.Enable = state;
            app.DegreesOfFreedomDropDown.Enable = state;
            app.TypeDropDown.Enable = state;
            app.DomainDropDown.Enable = state;
            app.BandwidthEditField.Enable = state;
            app.BandwidthSlider.Enable = state;
            app.PhaseMarginEditField.Enable = state;
            app.PhaseMarginSlider.Enable = state;
            app.ResponseTimeEditField.Enable = state;
            app.ResponseTimeSlider.Enable = state;
            app.TransientBehaviorEditField.Enable = state;
            app.TransientBehaviorSlider.Enable = state;
            app.DecreaseSliderRange.Enable = state;
            app.IncreaseSliderRange.Enable = state;
            app.DesignFocusDropDown.Enable = state;
            app.IntegralFormulaDropDown.Enable = state;
            app.FilterFormulaDropDown.Enable = state;
            app.PlotSelectDropDown.Enable = state;
            app.ShowPerformanceCriteriaCheckbox.Enable = state;
            app.ShowBaselineDropDown.Enable = state;
        end

        function updateControllerTypeDropDownItems(app)
            PIDForm = app.Form;
            if app.DegreesOfFreedom == 1
                if PIDForm == 1 % Parallel
                    PIDTypeOptions = {'P','I','PI','PD','PID','PDF','PIDF'};
                else            % Standard
                    PIDTypeOptions = {'P','PI','PD','PID','PDF','PIDF'};
                end
            else
                PIDTypeOptions = {'PI2','PD2','PID2','PDF2','PIDF2'};
            end
            app.TypeDropDown.Items = PIDTypeOptions;

        end

        function enableIntegralFilterMethods(app)
            Type = app.Type;
            if contains(Type,'I') && (app.Ts ~= 0)
                app.IntegralFormulaDropDown.Enable = true;
            else
                app.IntegralFormulaDropDown.Enable = false;
            end

            if contains(Type,'F') && (app.Ts ~= 0)
                app.FilterFormulaDropDown.Enable = true;
            else
                app.FilterFormulaDropDown.Enable = false;
            end

        end

        function updateSliderVisibilities(app)
            %UPDATESLIDERVISIBILITIES

            DomainSelected = app.Domain;
            % Get State of Sliders/Edit Fields
            if DomainSelected == 2   % Frequency Domain
                StateTime = 'off';
                StateFreq = 'on';
            else                     % Time Domain
                StateTime = 'on';
                StateFreq = 'off';
            end
            app.ResponseTimeEditField.Visible = StateTime;
            app.ResponseTimeSlider.Visible = StateTime;

            app.BandwidthEditField.Visible = StateFreq;
            app.BandwidthSlider.Visible = StateFreq;

            if strcmp(app.Type,'P')
                app.TransientBehaviorSlider.Visible = false;
                app.TransientBehaviorEditField.Visible = false;
                app.PhaseMarginSlider.Visible = false;
                app.PhaseMarginEditField.Visible = false;

                app.IntegralFormulaLabel.Visible = false;
                app.IntegralFormulaDropDown.Visible = false;
                app.FilterFormulaLabel.Visible = false;
                app.FilterFormulaDropDown.Visible = false;

                % Adjust Rows
                app.PerformanceGoalsGrid.RowHeight = {22,10,0,0};
            else
                app.TransientBehaviorSlider.Visible = StateTime;
                app.TransientBehaviorEditField.Visible = StateTime;
                app.PhaseMarginSlider.Visible = StateFreq;
                app.PhaseMarginEditField.Visible = StateFreq;

                app.IntegralFormulaLabel.Visible = true;
                app.IntegralFormulaDropDown.Visible = true;
                app.FilterFormulaLabel.Visible = true;
                app.FilterFormulaDropDown.Visible = true;

                % Adjust Rows
                app.PerformanceGoalsGrid.RowHeight = {22,10,22,10};
            end

            % Adjust rows for Options Section
            if strcmp(app.Type,'P') || (app.Ts == 0)
                app.OptionsGrid.RowHeight = {22,0};
            else
                app.OptionsGrid.RowHeight = {22,22};
            end


        end

        function resetAppToDefault(app)
            % RESETAPPTODEFAULT
            state = app.DefaultState;

            plant = app.Plant;
            isFRD = isa(plant,'frd');

            % Property Values
            if isFRD
                state.Domain = 2;
                state.PlotType = 'bode';
                state.LoopType = 'olsys';
            end

            % Update Widgets
            app.updateWidgetValues(state)
        end

        function updateWidgetValues(app, state)
            % UPDATEWIDGETVALUES

            % Disable Widget Listeners
            app.WidgetListeners(1).Enabled = false;

            % Update stored variables
            app.Form = state.Form;
            app.DegreesOfFreedom = state.DegreesOfFreedom;
            app.Type = state.Type;
            app.Domain = state.Domain;
            app.PhaseMargin = state.PhaseMargin;
            app.DesignFocus = state.DesignFocus;
            app.IntegralFormula = state.IntegralFormula;
            app.FilterFormula = state.FilterFormula;
            app.PlotType = state.PlotType;
            app.LoopType = state.LoopType;
            app.ShowPerformanceCriteria = state.ShowPerformanceCriteria;

            % Widget Values
            switch state.Form
                case 1 % Parallel
                    app.FormDropDown.Value = 'parallel';
                case 2 % Standard
                    app.FormDropDown.Value = 'standard';
            end

            switch state.DegreesOfFreedom
                case 1 % 1DOF
                    app.DegreesOfFreedomDropDown.Value = '1DOF';
                case 2 % 2DOF
                    app.DegreesOfFreedomDropDown.Value = '2DOF';
            end
            app.updateControllerTypeDropDownItems()
            app.TypeDropDown.Value = state.Type;

            switch state.Domain
                case 1 % Time Domain
                    app.DomainDropDown.Value = 'time';
                case 2 % Frequency Domain
                    app.DomainDropDown.Value = 'frequency';
            end

            % Update optional options widgets
            app.DesignFocusDropDown.Value = app.DesignFocus;
            app.IntegralFormulaDropDown.Value = app.IntegralFormula;
            app.FilterFormulaDropDown.Value = app.FilterFormula;
            app.enableIntegralFilterMethods()

            % Plotting
            if strcmp(state.PlotType,'none')
                app.PlotSelectDropDown.Value = 'none';
                app.ShowPerformanceCriteriaCheckbox.Enable = false;
            else
                app.PlotSelectDropDown.Value = horzcat(state.PlotType,'_',state.LoopType);
                if ~strcmp(app.PlantDropDown.Value,app.SelectLabel)
                    app.ShowPerformanceCriteriaCheckbox.Enable = true;
                end
            end
            app.ShowPerformanceCriteriaCheckbox.Value = state.ShowPerformanceCriteria;

            % Disable Show Baseline if no plot is selected or plant is
            % plotted
            if strcmp(state.PlotType,'none') || strcmp(state.LoopType,'plant')
                app.ShowBaselineDropDown.Visible = false;
                app.BaselineControllerDropDown.Visible = false;
                app.BaselineControllerLabel.Visible = false;

                % Adjust Grid
                app.VisualizeGrid.RowHeight = {22,0};

            else
                app.ShowBaselineDropDown.Visible = true;
                app.BaselineControllerLabel.Visible = true;
                if strcmp(state.BaselineControllerName,app.SelectLabel)
                    app.ShowBaselineDropDown.Value = 'none';
                else
                    app.ShowBaselineDropDown.Value = 'fromworkspace';
                end
                tmp.Value = app.ShowBaselineDropDown.Value;
                app.cbShowBaseline(tmp);

                % Adjust Grid
                app.VisualizeGrid.RowHeight = {22,22};
            end

            % Handle FRD Object Case
            if isa(app.Plant,'frd')
                app.DomainDropDown.Tooltip = m('Control:embedded_apps:tooltipFRD');
                if state.Domain == 2
                    app.DomainDropDown.Enable = false;
                end
            else
                app.DomainDropDown.Tooltip = '';
            end

            % Update Phase Margin and Trainsient Behavior Sliders and Edit Fields
            app.PhaseMarginEditField.Value = state.PhaseMargin;
            app.PhaseMarginSlider.Value = state.PhaseMargin;
            app.TransientBehaviorEditField.Value = state.PhaseMargin/100;
            app.TransientBehaviorSlider.Value = state.PhaseMargin/100;
            app.updateSliderVisibilities()

            % Store Default Data if Initial Controller
            if app.InitControl && app.IsValidPlant
                % Extract plant variable within the scope of this function.
                eval(sprintf('%s = app.Plant;', app.PlantDropDown.Value));

                % Get Initial Controller
                code = app.generatePIDTuningCode();
                code = erase(code,'`');
                eval(code)

                app.Bandwidth = pidInfo.CrossoverFrequency;
                app.BandwidthEditField.Value = pidInfo.CrossoverFrequency;
                app.DefaultState.Bandwidth = pidInfo.CrossoverFrequency;
                app.DefaultState.SampleTime = app.Plant.Ts;
                app.InitControl = false;
            else
                app.Bandwidth = state.Bandwidth;
                app.BandwidthEditField.Value = state.Bandwidth;
                app.DefaultState.Bandwidth = state.Bandwidth;
                app.DefaultState.SampleTime = state.SampleTime;
            end
            evt.Source.Tag = 'Bandwidth';
            cbBandwidthEditFieldValueChanged(app,evt)

            % Update widget labels
            if app.IsValidPlant
                [TimeUnitString, FreqUnitString] = pidtool.utPIDgetUnitString(app.Plant.TimeUnit);
                if strcmp(TimeUnitString, 'minutes')
                    TimeUnitString = 'min.';
                    FreqUnitString = 'rad/min.';
                end
            else
                TimeUnitString = 'seconds';
                FreqUnitString = 'rad/s';
            end
            app.ResponseTimeSlider.MajorTickLabels{2} = [m('Control:embedded_apps:responseTime') ' (' TimeUnitString ')'];
            app.BandwidthSlider.MajorTickLabels{2} = [m('Control:embedded_apps:bandwidth') ' (' FreqUnitString ')'];

            % Re-enable Widget Listeners
            app.WidgetListeners(1).Enabled = true;
        end

        function UIFigureCloseRequest(app)
            delete(app);
        end

        %% Helper Methods
        function figtitle = getFigureTitle(app)
            %GETFIGURETITLE
            switch app.PlotType
                case 'step'
                    prefix = 'stepPlot';
                case 'bode'
                    prefix = 'bodePlot';
            end
            msgID = ['Control:embedded_apps:' prefix '_' app.LoopType];
            figtitle = m(msgID);
        end

        function [code, outputs] = generatePIDTuningCode(app)
            var = app.PlantDropDown.Value;
            if strcmp(var, app.SelectLabel) % No variable selected
                code = '';
                outputs = {};
            else
                form = app.Form;
                type = app.Type;
                dof = app.DegreesOfFreedom;
                wc = app.Bandwidth;
                PM = app.PhaseMargin;
                Ts = app.Ts;
                DesignFocus = app.DesignFocus;
                IFormula = app.IntegralFormula;
                DFormula = app.FilterFormula;
                clearVars = '';

                % Get pid,pidstd arguments if Integrator or Filter Formula is
                % not Default
                C0_formula = '';
                if ~strcmp(IFormula,'ForwardEuler') && contains(type,'I') && (Ts ~= 0)
                    C0_formula = sprintf('%s,''IFormula'',''%s''',C0_formula,IFormula);
                end
                if ~strcmp(DFormula,'ForwardEuler') && contains(type,'F') && (Ts ~= 0)
                    C0_formula = sprintf('%s,''DFormula'',''%s''',C0_formula,DFormula);
                end

                % Get C0 if using Standard Form or Integral/Filter Method
                if form == 2 || ~isempty(C0_formula)
                    C0args = '';
                    if contains(type,'P')
                        C0args = sprintf('%s,1',C0args);
                    elseif contains(type, 'F')
                        C0args = sprintf('%s,0',C0args);
                    end
                    if contains(type,'I')
                        C0args = sprintf('%s,1',C0args);
                    elseif contains(type, 'D')
                        if form == 1
                            C0args = sprintf('%s,0',C0args);
                        else
                            C0args = sprintf('%s,inf',C0args);
                        end
                    end
                    if contains(type,'D')
                        C0args = sprintf('%s,1',C0args);
                    end
                    if contains(type,'F')
                        C0args = sprintf('%s,100',C0args);
                    end
                    C0args = C0args(2:end);

                    % Check for Discrete vs Continuous
                    if Ts ~= 0
                        C0args = sprintf('%s,''Ts'',%g', C0args, Ts);
                    end

                    % Add formula, if applicable
                    if ~isempty(C0_formula)
                        C0_formula = C0_formula(2:end);
                        C0args = sprintf('%s,%s',C0args,C0_formula);
                    end

                    if form == 1 % parallel
                        if dof == 1
                            code_C0 = sprintf('pid(%s)',C0args);
                        else
                            code_C0 = sprintf('pid2(%s)',C0args);
                        end
                    else % Standard
                        if dof == 1
                            code_C0 = sprintf('pidstd(%s)',C0args);
                        else
                            code_C0 = sprintf('pidstd2(%s)',C0args);
                        end
                    end
                    code_C0 = [newline sprintf('C0 = %s;',code_C0)];
                    clearVars = [clearVars ' C0'];
                else
                    code_C0 = '';
                end

                % Convert from Time Domain parameters to Frequency Domain
                if ~app.InitControl && app.Domain==1 % Time Domain
                    % Convert from Response Time to Bandwidth, if necessary
                    comment1 = m('Control:embedded_apps:codeCommentWc1');
                    comment2 = m('Control:embedded_apps:codeCommentWc2');
                    comment = [comment1 newline comment2];
                    code_wc = sprintf('wc = 2/%g;', 2/wc);
                    clearVars = [clearVars ' wc'];
                    code_convert = [comment newline code_wc];
                    if PM ~= 60 && ~strcmp(type,'P')
                        comment1 = m('Control:embedded_apps:codeCommentPM1');
                        comment2 = m('Control:embedded_apps:codeCommentPM2');
                        comment = [comment1 newline comment2];
                        code_PM = sprintf('PM = 100*%g;', PM/100);
                        clearVars = [clearVars ' PM'];
                        code_convert = [code_convert newline newline comment newline code_PM];
                    end
                else
                    code_convert = '';
                end

                % Define Code for PIDTUNEOPTIONS
                comment = m('Control:embedded_apps:codeCommentPIDOptions');
                if (PM ~= 60 && ~strcmp(type,'P')) || ~strcmp(DesignFocus,'balanced')
                    args = '';
                    if PM ~= 60 && ~strcmp(type,'P')
                        if app.Domain==1 % Time Domain
                            args = sprintf('%s,''PhaseMargin'',PM',args);
                        else
                            args = sprintf('%s,''PhaseMargin'',%g',args,PM);
                        end
                    end
                    if ~strcmp(DesignFocus,'balanced')
                        args = sprintf('%s,''DesignFocus'',''%s''',args,DesignFocus);
                    end

                    args = args(2:end);
                    code_pidopts = sprintf('opts = pidtuneOptions(%s);',args);
                    code_pidopts = [comment newline code_pidopts];
                    clearVars = [clearVars ' opts'];
                else
                    code_pidopts = '';
                end
                if ~isempty(code_C0)
                    if ~isempty(code_pidopts)
                        code_opts = [code_pidopts code_C0];
                    else
                        code_opts = [comment code_C0];
                    end
                else
                    code_opts = code_pidopts;
                end


                % Define Code for PIDTUNE
                inputs = var;
                outputs = {'C','pidInfo'};
                args = '';
                comment = m('Control:embedded_apps:codeCommentPIDTune');

                % Add Type or Baseline C0 as input
                if isempty(code_C0)
                    args = sprintf('%s,''%s''', args, type);
                else % PID Object
                    args = sprintf('%s,C0', args);
                end

                % Add Bandwidth as Input
                if ~app.InitControl && app.Domain==2
                    args = sprintf('%s,%g', args, wc);
                elseif ~app.InitControl && app.Domain==1
                    args = sprintf('%s,wc', args);
                end

                % Add Options as input, if applicable
                if ~isempty(code_pidopts)
                    args = sprintf('%s,opts', args);
                end

                out = join(string(outputs), ',');
                in = join(string(inputs), ',');
                code_tune = sprintf('[%s] = pidtune(`%s`%s);', out, in, args);
                code_tune = [comment newline code_tune];

                % Get Clear Variables Code
                if ~isempty(clearVars)
                    comment = m('Control:embedded_apps:codeCommentClearVariables');
                    code_clear = sprintf('clear%s',clearVars);
                    code_clear = [comment newline code_clear];
                else
                    code_clear = '';
                end

                % Get Final Code
                if ~isempty(code_opts)
                    code = [code_opts newline newline code_tune];
                else
                    code = code_tune;
                end
                if ~isempty(code_convert)
                    code = [code_convert newline newline code];
                end
                if ~isempty(code_clear)
                    code = [code newline newline code_clear];
                end
            end
        end
    end

    %% QE Methods
    methods (Hidden)
        function outputNames = qeGetOutputVariableNames(~)
            outputNames = {'C','pidInfo'};
        end

        function model = qeGetModel(app)
            model = app.Plant;
        end

        function qeExpandCollapsePanel(app,panelName,isCollapsed)
            app.(panelName).Collapsed = isCollapsed;
        end

    end

    %% Dependent Parameters
    methods
        function value = get.Ts(app)
            % GET.TS
            if app.IsValidPlant
                value = app.Plant.Ts;
            else
                value = app.DefaultState.SampleTime;
            end
        end
    end
end

%% Static Methods
function msg = m(str,varargin)
if nargin==2
    args = varargin{:};
else
    args = varargin;
end
msg = getString(message(str,args{:}));
end

function valid = filterWorkspaceVariables(wsVar)
% Only use LTI Objects
valid = isa(wsVar,'lti');

% Do not allow PID Objects in list
if valid
    valid = ~(isa(wsVar,'pid') || isa(wsVar,'pid2') || ...
        isa(wsVar,'pidstd') || isa(wsVar,'pidstd2'));
end

% Get Only SISO Systems
if valid
    valid = issiso(wsVar);
end
end

function valid = filterWorkspaceVariablesC0(wsVar)

% Only allow PID Objects
valid = isa(wsVar,'pid') || isa(wsVar,'pid2') || ...
    isa(wsVar,'pidstd') || isa(wsVar,'pidstd2');

end
