classdef ModelReducerApp < matlab.task.LiveTask
    % Reduce model order live task

    % Copyright 2018-2024 The MathWorks, Inc.

    %% Properties

    properties
        % App View
        View
    end

    properties (Dependent)
        % App State
        State
        Summary
    end

    properties (Transient,Hidden,Dependent,AbortSet)
        % Derived from state
        ReductionMethod
    end

    properties (Transient,Hidden,Dependent)
        CurrentData
        ReducedSystem
    end
    
    properties (Transient, Hidden)
        % UI Layouts
        ParentGrid                          matlab.ui.container.GridLayout
        ModelAndMethodGrid                  matlab.ui.container.GridLayout
        BalancedTruncationGrid              matlab.ui.container.GridLayout
        BalancedTruncationOptionsGrid       matlab.ui.container.GridLayout
        ModalTruncationGrid                 matlab.ui.container.GridLayout
        ModalTruncationOptionsGrid          matlab.ui.container.GridLayout
        PoleZeroSimplificationGrid          matlab.ui.container.GridLayout
        ComparisonAndAnalysisPlotGrid       matlab.ui.container.GridLayout
        ComparisonAndAnalysisPlotLayout     matlab.graphics.layout.TiledChartLayout
        OutputPlotGrid                      matlab.ui.container.GridLayout
                
        % UI Components
        ModelAndMethodComponents
        BalancedTruncationComponents
        ModalTruncationComponents             
        PoleZeroSimplificationComponents
        ComparisonPlotComponents
        AnalysisPlotComponents
        OutputPlotComponents

        % App Data
        Model
        ModelWrapper

        BalancedTruncationData
        ModalTruncationData
        PoleZeroSimplificationData
        
        OutputVariableName = "sysReduced";
    end

    properties (Transient,Hidden,Constant)
        InitialSystem = tf(1,[1 1]);

        BTComparisonPlotTypes = ["modelResponse","absError","relError"];
        BTAnalysisPlotTypes = "hsv";

        MTComparisonPlotTypes = ["modelResponse","absError","relError","modeCompare"];
        MTAnalysisPlotTypes = ["dcContrib","mode","damp"];

        PZSComparisonPlotTypes = ["modelResponse","absError","relError"];
        PZSAnalysisPlotTypes = "pz";

        ComparisonPlotTypes = ["modelResponse","absError","relError","modeCompare"];
        AnalysisPlotTypes = ["hsv","dcContrib","mode","damp","pz"];
        ComparsionPlotMap = dictionary(["modelResponse","absError","relError","modeCompare"],...
            {m('Control:mrtool:ResponsePlot'),m('Control:mrtool:AbsoluteErrorPlot'),...
            m('Control:mrtool:RelativeErrorPlot'),m('Control:mrtool:MTModeComparePlot')})
        AnalysisPlotMap = dictionary(["hsv","dcContrib","mode","damp","pz"],...
            {m('Control:mrtool:BTHSVPlot'),m('Control:mrtool:MTDCPlot'),m('Control:mrtool:MTModePlot'),...
            m('Control:embedded_apps:MTDampPlot'),m('Control:embedded_apps:PZSPZPlot')})

        OutputPlotTypes = ["none","step","impulse","bode","sigma","pz"];
    end

    properties (Access = private, Transient)
        FrequencySelectorListener
        BarSelectorListener
        DCContribListener
        PlotDataListener
        
        State_I
    end
    
    %% Constructor/destructor
    methods
        function app = ModelReducerApp(optionalInputs)
            arguments
                optionalInputs.Parent (1,1) matlab.ui.Figure = uifigure
            end
            app = app@matlab.task.LiveTask(Parent=optionalInputs.Parent);
        end
        
        function delete(app)
            delete(app.FrequencySelectorListener);
            delete(app.BarSelectorListener);
            delete(app.DCContribListener);
            delete(app.PlotDataListener);
            delete@matlab.task.LiveTask(app);
        end
    end

    %% Get/Set
    methods        
        % State        
        function state = get.State(app)
            state = app.State_I;
        end

        function set.State(app,state)
            if ~isfield(state,"CurrentAnalysisPlotType") %map pre-25a data
                switch state.Method
                    case 'balred'
                        state.Method = "balanced";
                    case 'freqsep'
                        state.Method = "modal";
                end
                state.BTReductionCriteria = "Order";
                state.BTReducedOrder = state.ReducedOrder;
                state = rmfield(state,"ReducedOrder");
                state.BTAlgorithm = "absolute";
                state.BTRegularization = "auto";
                state.BTFreqIntervals = [];
                state.BTOffset = 1e-8;
                state.BTSepTol = 10;

                state.MTDampingRange = [-1 1];
                state.MTMinDC = 0;
                state.MTModeOnly = false;
                state.MTDCFrequency = 0;
                state.MTSepTol = 1e-12;

                if state.PreserveDCGain
                    state.BTMethod = "matchDC";
                    state.MTMethod = "matchDC";
                else
                    state.BTMethod = "truncate";
                    state.MTMethod = "truncate";
                end
                state = rmfield(state,"PreserveDCGain");
                if state.FrequencyRangeSelected
                    state.BTFreqIntervals = state.FrequencyRange;
                else
                    state.BTFreqIntervals = [];
                end
                state.MTFrequencyRange = state.FrequencyRange;
                state = rmfield(state,"FrequencyRange");
                state = rmfield(state,"FrequencyRangeSelected");

                state.PZSTolerance = state.Tolerance;
                state = rmfield(state,"Tolerance");

                state.CurrentComparisonPlotType = state.CurrentResponsePlotType;
                state = rmfield(state,"CurrentResponsePlotType");

                state = rmfield(state,"GeneratePrescaleCode");
                state = rmfield(state,"FrequencyRangeUpperBound");
                state = rmfield(state,"OutputUpdated");

                switch state.Method
                    case "balanced"
                        state.CurrentAnalysisPlotType = "hsv";
                    case "modal"
                        state.CurrentAnalysisPlotType = "dcContrib";
                    case "minreal"
                        state.CurrentAnalysisPlotType = "pz";
                end
            end
            state.InputVariableName = string(state.InputVariableName);
            state.Method = string(state.Method);
            if ~isempty(state.BTFreqIntervals)
                state.BTFreqIntervals = state.BTFreqIntervals(:)';
            end
            state.CurrentOutputPlotType = string(state.CurrentOutputPlotType);
            state.CurrentComparisonPlotType = string(state.CurrentComparisonPlotType);
            app.State_I = state;

            if isempty(app.BalancedTruncationData) || ~isvalid(app.BalancedTruncationData)
                createData(app);
            end

            if ~contains(app.State_I.InputVariableName,string(app.ModelAndMethodComponents.ModelDropDown.Items))
                app.ModelAndMethodComponents.ModelDropDown.Items = [app.ModelAndMethodComponents.ModelDropDown.Items,{char(app.State_I.InputVariableName)}];
                app.ModelAndMethodComponents.ModelDropDown.ItemsData = [app.ModelAndMethodComponents.ModelDropDown.ItemsData,{char(app.State_I.InputVariableName)}];
            end
            app.ModelAndMethodComponents.ModelDropDown.Value = app.State_I.InputVariableName;
            updateModel(app);

            pushStateToData(app);

            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
            updatePreview(app);
        end
        
        % Summary
        function summary = get.Summary(app)
            summary = m('Control:embedded_apps:modelReducerStaticSummary');
            if app.State_I.InputVariableName ~= "" && ~isempty(app.ReducedSystem)
                methodIdx = strcmp(app.ModelAndMethodComponents.MethodDropDown.ItemsData,app.ReductionMethod);
                method = app.ModelAndMethodComponents.MethodDropDown.Items{methodIdx};
                summary = m('Control:embedded_apps:modelReducerDynamicSummary',app.State_I.InputVariableName, method);
            end
        end

        % ReductionMethod
        function ReductionMethod = get.ReductionMethod(app)
            ReductionMethod = app.State_I.Method;
        end

        function set.ReductionMethod(app,Method)
            arguments
                app (1,1) ctrlguis.embeddedapps.ModelReducerApp
                Method (1,1) string {mustBeMember(Method,["balanced","modal","minreal"])}
            end
            app.State_I.Method = Method;
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
            updatePreview(app);
        end

        % CurrentData
        function CurrentData = get.CurrentData(app)
            switch app.ReductionMethod
                case "balanced"
                    CurrentData = app.BalancedTruncationData;
                case "modal"
                    CurrentData = app.ModalTruncationData;
                case "minreal"
                    CurrentData = app.PoleZeroSimplificationData;
            end
        end

        % ReducedSystem
        function ReducedSystem = get.ReducedSystem(app)
            ReducedSystem = app.CurrentData.ReducedSystem;
        end
    end

    %% Public methods
    methods       
        function reset(app)
            app.ReductionMethod = "balanced";
            createData(app);
            pushDataToState(app);
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
            updatePreview(app);
        end
        
         %% Code and summary generation
        function [code, outputs] = generateCode(app)
            if app.State_I.InputVariableName == "" || isempty(app.ModelWrapper)
                code = '';
                outputs = {};
            else
                code = cell(0,1);
                outputs = {app.OutputVariableName};
                tempVariablesToClear = '';
                plotCommand = app.State_I.CurrentOutputPlotType;
                if plotCommand ~= "none"
                    plotCommand = plotCommand +"plot";
                end
                [codeFromData,localVariables] = generateMATLABCode(app.CurrentData,OutputName=app.OutputVariableName,...
                    PlotCommand=plotCommand,IsLiveEditor=true,AbsorbDelay=app.State_I.GenerateAbsorbDelayCode);
                code = [code;codeFromData];
                for ii = 1:length(localVariables)
                    tempVariablesToClear = [tempVariablesToClear, char(localVariables(ii)), ' ']; %#ok<AGROW>
                end
                if ~isempty(tempVariablesToClear)
                    code = controllib.internal.codegen.appendMATLABCode(code,' ');
                    code = controllib.internal.codegen.appendMATLABCode(code,['% ',m('Control:embedded_apps:clearVarComment')]);
                    code = controllib.internal.codegen.appendMATLABCode(code,['clear ',tempVariablesToClear]);
                end
                code = controllib.internal.codegen.cellstr2char(code);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function setup(app)
            initializeState(app);
            initializeView(app);
            createComponents(app);
            updateUIComponentVisibility(app,true);
            updateUIComponentValues(app);
            updatePreview(app);
        end
    end
    
    %% State and View
    methods (Access = private)
        function initializeState(app)
            app.Model = app.InitialSystem;
            app.ModelWrapper = mrtool.data.ModelWrapper("``",app.InitialSystem);
            state.InputVariableName = "";
            state.Method = "balanced";
            createData(app);

            state.BTReductionCriteria = "Order";
            state.BTReducedOrder = [];
            state.BTMethod = "truncate";
            state.BTAlgorithm = "absolute";
            state.BTRegularization = "auto";
            state.BTFreqIntervals = [];
            state.BTOffset = 1e-8;
            state.BTSepTol = 10;

            state.MTFrequencyRange = [];
            state.MTDampingRange = [-1 1];
            state.MTMinDC = 0;
            state.MTMethod = "truncate";
            state.MTModeOnly = false;
            state.MTDCFrequency = 0;
            state.MTSepTol = 1e-12;

            state.PZSTolerance = [];

            state.GenerateAbsorbDelayCode = false;

            state.CurrentComparisonPlotType = "modelResponse";
            state.CurrentAnalysisPlotType = "hsv";
            state.CurrentOutputPlotType = "none";

            app.State_I = state;
        end
        
        function initializeView(app)
            % Initialize the 'View' structure
            app.View.ComparisonPlotWidgets = cell(1,length(app.ComparisonPlotTypes));
            app.View.AnalysisPlotWidgets = cell(1,length(app.AnalysisPlotTypes));
            app.View.CurrentComparisonPlotWidget = [];
            app.View.CurrentAnalysisPlotWidget = [];
        end
    end
    
    %% UI Components creation
    methods(Access = private)
        function createComponents(app)
            createFigureAndGridComponents(app);
            createModelAndMethodComponents(app);
            createBalancedTruncationComponents(app);
            createModalTruncationComponents(app);
            createPoleZeroSimplificationComponents(app);
            createPlotComponents(app);
        end
        
        function createFigureAndGridComponents(app)
            app.ParentGrid = uigridlayout(app.LayoutManager,[6 1]);
            app.ParentGrid.RowHeight = {'fit','fit',0,0,'fit','fit'};
            app.ParentGrid.Padding = [0 0 0 0];
            
            ModelAccordian = matlab.ui.container.internal.Accordion('Parent',app.ParentGrid);
            ModelAccordian.Layout.Row = 1;
            ModelPanel = matlab.ui.container.internal.AccordionPanel('Parent',ModelAccordian);
            ModelPanel.Title = m('Control:embedded_apps:selectModelAndMethod');
            app.ModelAndMethodGrid = uigridlayout(ModelPanel,[1 4]);
            app.ModelAndMethodGrid.ColumnWidth = {'fit','fit','fit','fit'};
            
            BalancedTruncationAccordian = matlab.ui.container.internal.Accordion('Parent',app.ParentGrid);
            BalancedTruncationAccordian.Layout.Row = 2;
            BalancedTruncationPanel = matlab.ui.container.internal.AccordionPanel('Parent',BalancedTruncationAccordian);
            BalancedTruncationPanel.Title = m('Control:mrtool:BalancedTruncationToolTip');
            app.BalancedTruncationGrid = uigridlayout(BalancedTruncationPanel,[3 3]);
            app.BalancedTruncationGrid.RowHeight = {'fit','fit','fit'};
            app.BalancedTruncationGrid.ColumnWidth = {'fit','fit','1x'};

            ModalTruncationAccordian = matlab.ui.container.internal.Accordion('Parent',app.ParentGrid);
            ModalTruncationAccordian.Layout.Row = 3;
            ModalTruncationPanel = matlab.ui.container.internal.AccordionPanel('Parent',ModalTruncationAccordian);
            ModalTruncationPanel.Title = m('Control:mrtool:ModalTruncationToolTip');
            app.ModalTruncationGrid = uigridlayout(ModalTruncationPanel,[4 5]);
            app.ModalTruncationGrid.RowHeight = {'fit','fit','fit','fit'};
            app.ModalTruncationGrid.ColumnWidth = {'fit','fit','fit','fit','1x'};
            
            PoleZeroAccordian = matlab.ui.container.internal.Accordion('Parent',app.ParentGrid);
            PoleZeroAccordian.Layout.Row = 4;
            PoleZeroPanel = matlab.ui.container.internal.AccordionPanel('Parent',PoleZeroAccordian);
            PoleZeroPanel.Title = m('Control:mrtool:PoleZeroSimplificationToolTip');
            app.PoleZeroSimplificationGrid = uigridlayout(PoleZeroPanel,[1 5]);
            app.PoleZeroSimplificationGrid.ColumnWidth = {'fit','fit','fit','fit','fit'};
   
            PlotAccordian = matlab.ui.container.internal.Accordion('Parent',app.ParentGrid);
            PlotAccordian.Layout.Row = 5;
            PlotPanel = matlab.ui.container.internal.AccordionPanel('Parent',PlotAccordian);
            PlotPanel.Title = m('Control:embedded_apps:visualizeInput');
            app.ComparisonAndAnalysisPlotGrid = uigridlayout(PlotPanel,[2 4]);
            app.ComparisonAndAnalysisPlotGrid.RowHeight = {'fit',500};
            app.ComparisonAndAnalysisPlotGrid.ColumnWidth = {'fit','fit','fit','fit'};            
            panel = uipanel(app.ComparisonAndAnalysisPlotGrid);
            panel.Layout.Row = 2;
            panel.Layout.Column = [1 4];            
            panel.BorderType = 'none';
            app.ComparisonAndAnalysisPlotLayout = tiledlayout(panel,2,1);

            OutputAccordian = matlab.ui.container.internal.Accordion('Parent',app.ParentGrid);
            OutputAccordian.Layout.Row = 6;
            OutputPanel = matlab.ui.container.internal.AccordionPanel('Parent',OutputAccordian);
            OutputPanel.Title = m('Control:embedded_apps:visualizeResults');
            app.OutputPlotGrid = uigridlayout(OutputPanel,[1 2]);
            app.OutputPlotGrid.ColumnWidth = {'fit','fit'};
        end
        
        function createModelAndMethodComponents(app)    
            weakApp = matlab.lang.WeakReference(app);
            app.ModelAndMethodComponents.ModelDropDownLabel = uilabel(app.ModelAndMethodGrid);
            app.ModelAndMethodComponents.ModelDropDownLabel.Layout.Column = 1;
            app.ModelAndMethodComponents.ModelDropDownLabel.Text = m('Control:embedded_apps:model');
            
            app.ModelAndMethodComponents.ModelDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.ModelAndMethodGrid);
            app.ModelAndMethodComponents.ModelDropDown.Layout.Column = 2;
            app.ModelAndMethodComponents.ModelDropDown.FilterVariablesFcn = @(x) updateModelDropDownItems(x);
            app.ModelAndMethodComponents.ModelDropDown.ValueChangedFcn = @(es,ed) cbModelDropDownValueChanged(weakApp.Handle,ed);
            app.ModelAndMethodComponents.ModelDropDown.Tooltip = m('Control:embedded_apps:ModelDropDownTooltip');
            
            app.ModelAndMethodComponents.MethodDropDownLabel = uilabel(app.ModelAndMethodGrid);
            app.ModelAndMethodComponents.MethodDropDownLabel.Layout.Column = 3;
            app.ModelAndMethodComponents.MethodDropDownLabel.Text = m('Control:embedded_apps:method');
            
            app.ModelAndMethodComponents.MethodDropDown = uidropdown(app.ModelAndMethodGrid);
            app.ModelAndMethodComponents.MethodDropDown.Layout.Column = 4;
            app.ModelAndMethodComponents.MethodDropDown.Items = {m('Control:mrtool:BalancedTruncationTab'); ...
                m('Control:mrtool:ModalTruncationTab'); m('Control:mrtool:PoleZeroSimplificationTab')};
            app.ModelAndMethodComponents.MethodDropDown.ItemsData = {'balanced'; 'modal'; 'minreal'};
            app.ModelAndMethodComponents.MethodDropDown.ValueChangedFcn = @(es,ed) cbMethodDropDownValueChanged(weakApp.Handle,ed);
            app.ModelAndMethodComponents.MethodDropDown.Enable = 'off';
            app.ModelAndMethodComponents.MethodDropDown.Value = app.ReductionMethod;
            app.ModelAndMethodComponents.MethodDropDown.Tooltip = m('Control:embedded_apps:MethodDropDownTooltip');
        end
        
        function createBalancedTruncationComponents(app)
            weakApp = matlab.lang.WeakReference(app);
            app.BalancedTruncationComponents.ReductionCriteriaLabel = uilabel(app.BalancedTruncationGrid);
            app.BalancedTruncationComponents.ReductionCriteriaLabel.Layout.Row = 1;
            app.BalancedTruncationComponents.ReductionCriteriaLabel.Layout.Column = 1;
            app.BalancedTruncationComponents.ReductionCriteriaLabel.Text = m('Control:mrtool:BTReductionCriteriaLabel');

            app.BalancedTruncationComponents.ReductionCriteriaDropDown = uidropdown(app.BalancedTruncationGrid);
            app.BalancedTruncationComponents.ReductionCriteriaDropDown.Layout.Row = 1;
            app.BalancedTruncationComponents.ReductionCriteriaDropDown.Layout.Column = 2;
            app.BalancedTruncationComponents.ReductionCriteriaDropDown.Items = {m('Control:mrtool:BTOrderLabel');...
                m('Control:mrtool:BTMaxErrorLabel');m('Control:mrtool:BTMinEnergyLabel');m('Control:mrtool:BTMaxLossLabel')};
            app.BalancedTruncationComponents.ReductionCriteriaDropDown.ItemsData = {'Order','MaxError','MinEnergy','MaxLoss'};
            app.BalancedTruncationComponents.ReductionCriteriaDropDown.Tooltip = m('Control:mrtool:BTReductionCriteriaTooltip');
            app.BalancedTruncationComponents.ReductionCriteriaDropDown.ValueChangedFcn = ...
                @(es,ed) cbBTReductionCriteriaChanged(weakApp.Handle,ed);

            app.BalancedTruncationComponents.ReductionMethodLabel = uilabel(app.BalancedTruncationGrid);
            app.BalancedTruncationComponents.ReductionMethodLabel.Layout.Row = 2;
            app.BalancedTruncationComponents.ReductionMethodLabel.Layout.Column = 1;
            app.BalancedTruncationComponents.ReductionMethodLabel.Text = m('Control:embedded_apps:reducedOrder');
            
            app.BalancedTruncationComponents.ReductionMethodEditField = uieditfield(app.BalancedTruncationGrid,'numeric');
            app.BalancedTruncationComponents.ReductionMethodEditField.Layout.Row = 2;
            app.BalancedTruncationComponents.ReductionMethodEditField.Layout.Column = 2;
            app.BalancedTruncationComponents.ReductionMethodEditField.ValueChangedFcn = @(es,ed) cbBTReductionMethodEditFieldValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.ReductionMethodEditField.Tooltip = m('Control:mrtool:BTOrderTooltip');
            
            OptionsAccordian = matlab.ui.container.internal.Accordion('Parent',app.BalancedTruncationGrid);
            OptionsAccordian.Layout.Row = 3;
            OptionsAccordian.Layout.Column = [1 3];
            OptionsPanel = matlab.ui.container.internal.AccordionPanel('Parent',OptionsAccordian);
            OptionsPanel.Title = getString(message('Control:embedded_apps:specifyReductionOptions'));
            OptionsPanel.Collapsed = true;
            app.BalancedTruncationOptionsGrid = uigridlayout(OptionsPanel,[4 5]);
            app.BalancedTruncationOptionsGrid.RowHeight = {'fit','fit','fit','fit'};
            app.BalancedTruncationOptionsGrid.ColumnWidth = {'fit','fit','fit','fit','1x'};

            % Method
            app.BalancedTruncationComponents.MethodCheckbox = uicheckbox(app.BalancedTruncationOptionsGrid);
            app.BalancedTruncationComponents.MethodCheckbox.Layout.Row = 1;
            app.BalancedTruncationComponents.MethodCheckbox.Layout.Column = 1;
            app.BalancedTruncationComponents.MethodCheckbox.Value = false;
            app.BalancedTruncationComponents.MethodCheckbox.Text = m('Control:mrtool:OptionsMethodLabel');
            app.BalancedTruncationComponents.MethodCheckbox.ValueChangedFcn = @(es,ed) cbBTMethodCheckboxValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.MethodCheckbox.Tooltip = m('Control:mrtool:OptionsMethodTooltip');            
            
            % Algorithm
            app.BalancedTruncationComponents.AlgorithmCheckbox = uicheckbox(app.BalancedTruncationOptionsGrid);
            app.BalancedTruncationComponents.AlgorithmCheckbox.Layout.Row = 1;
            app.BalancedTruncationComponents.AlgorithmCheckbox.Layout.Column = 2;
            app.BalancedTruncationComponents.AlgorithmCheckbox.Text = m('Control:mrtool:BTOptionsAlgorithmLabel');
            app.BalancedTruncationComponents.AlgorithmCheckbox.ValueChangedFcn = @(es,ed) cbBTAlgorithmCheckboxValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.AlgorithmCheckbox.Tooltip = m('Control:mrtool:BTOptionsAlgorithmTooltip');            
            
            % FreqIntervals
            app.BalancedTruncationComponents.FrequencyRangeCheckbox = uicheckbox(app.BalancedTruncationOptionsGrid);
            app.BalancedTruncationComponents.FrequencyRangeCheckbox.Layout.Row = 2;
            app.BalancedTruncationComponents.FrequencyRangeCheckbox.Layout.Column = 1;
            app.BalancedTruncationComponents.FrequencyRangeCheckbox.Text = ...
                                    m('Control:embedded_apps:frequencyRange');
            app.BalancedTruncationComponents.FrequencyRangeCheckbox.ValueChangedFcn = ...
                @(es,ed) cbBTFrequencyRangeCheckboxValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.FrequencyRangeCheckbox.Tooltip = ...
                                    m('Control:embedded_apps:FreqRangeCheckTooltip');
            
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField = uieditfield(app.BalancedTruncationOptionsGrid,'numeric');
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Layout.Row = 2;
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Layout.Column = 2;
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Limits = [0 Inf];
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.UpperLimitInclusive = 'off';
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.ValueChangedFcn = ...
                @(es,ed) cbBTFrequencyRangeLowerEditFieldValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Tooltip = ...
                                    m('Control:embedded_apps:LowerFreqRangeTooltip');
            
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField = uieditfield(app.BalancedTruncationOptionsGrid,'numeric');
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Layout.Row = 2;
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Layout.Column = 3;
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Limits = [0 Inf];
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.LowerLimitInclusive = 'off';
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.ValueChangedFcn = ...
                @(es,ed) cbBTFrequencyRangeUpperEditFieldValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Tooltip = ...
                                    m('Control:embedded_apps:UpperFreqRangeTooltip');
            
            app.BalancedTruncationComponents.FrequencyUnitLabel = uilabel(app.BalancedTruncationOptionsGrid);
            app.BalancedTruncationComponents.FrequencyUnitLabel.Layout.Row = 2;
            app.BalancedTruncationComponents.FrequencyUnitLabel.Layout.Column = 4;
            app.BalancedTruncationComponents.FrequencyUnitLabel.Text = m('Control:embedded_apps:strFreqUnit');

            % Regularization
            app.BalancedTruncationComponents.RegularizationCheckbox = uicheckbox(app.BalancedTruncationOptionsGrid);
            app.BalancedTruncationComponents.RegularizationCheckbox.Layout.Row = 3;
            app.BalancedTruncationComponents.RegularizationCheckbox.Layout.Column = 1;
            app.BalancedTruncationComponents.RegularizationCheckbox.Text = m('Control:mrtool:BTOptionsRegularization');
            app.BalancedTruncationComponents.RegularizationCheckbox.Tooltip = m('Control:mrtool:BTOptionsRegularizationTooltip');
            app.BalancedTruncationComponents.RegularizationCheckbox.ValueChangedFcn = ...
                @(es,ed) cbBTRegularizationCheckboxValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.RegularizationEditField = uieditfield(app.BalancedTruncationOptionsGrid,'numeric');
            app.BalancedTruncationComponents.RegularizationEditField.Layout.Row = 3;
            app.BalancedTruncationComponents.RegularizationEditField.Layout.Column = 2;
            app.BalancedTruncationComponents.RegularizationEditField.Limits = [0 inf];
            app.BalancedTruncationComponents.RegularizationEditField.UpperLimitInclusive = 'off';
            app.BalancedTruncationComponents.RegularizationEditField.Tooltip = m('Control:mrtool:BTOptionsRegularizationTooltip2');
            app.BalancedTruncationComponents.RegularizationEditField.ValueChangedFcn = ...
                @(es,ed) cbBTRegularizationEditFieldValueChanged(weakApp.Handle,ed);

            AdvancedAccordian = matlab.ui.container.internal.Accordion('Parent',app.BalancedTruncationOptionsGrid);
            AdvancedAccordian.Layout.Row = 4;
            AdvancedAccordian.Layout.Column = [1 5];
            AdvancedPanel = matlab.ui.container.internal.AccordionPanel('Parent',AdvancedAccordian);
            AdvancedPanel.Title = getString(message('Control:mrtool:OptionsAdvanced'));
            AdvancedPanel.Collapsed = true;
            advancedLayout = uigridlayout(AdvancedPanel,[1 4]);
            advancedLayout.ColumnWidth = {'fit','fit','fit','fit'};

            % Offset
            app.BalancedTruncationComponents.OffsetLabel = uilabel(advancedLayout);
            app.BalancedTruncationComponents.OffsetLabel.Layout.Row = 1;
            app.BalancedTruncationComponents.OffsetLabel.Layout.Column = 1;
            app.BalancedTruncationComponents.OffsetLabel.Text = getString(message('Control:mrtool:BTOptionsOffset'));
            app.BalancedTruncationComponents.OffsetEditField = uieditfield(advancedLayout,'numeric');
            app.BalancedTruncationComponents.OffsetEditField.Layout.Row = 1;
            app.BalancedTruncationComponents.OffsetEditField.Layout.Column = 2;   
            app.BalancedTruncationComponents.OffsetEditField.Limits = [0 inf];
            app.BalancedTruncationComponents.OffsetEditField.LowerLimitInclusive = 'off';
            app.BalancedTruncationComponents.OffsetEditField.UpperLimitInclusive = 'off';
            app.BalancedTruncationComponents.OffsetEditField.ValueChangedFcn = ...
                @(es,ed) cbBTOffsetEditFieldValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.OffsetEditField.Tooltip = getString(message('Control:mrtool:BTOptionsOffsetTooltip'));

            % SepTol
            app.BalancedTruncationComponents.SepTolLabel = uilabel(advancedLayout);
            app.BalancedTruncationComponents.SepTolLabel.Layout.Row = 1;
            app.BalancedTruncationComponents.SepTolLabel.Layout.Column = 3;
            app.BalancedTruncationComponents.SepTolLabel.Text = getString(message('Control:mrtool:BTOptionsSepTol'));
            app.BalancedTruncationComponents.SepTolEditField = uieditfield(advancedLayout,'numeric');
            app.BalancedTruncationComponents.SepTolEditField.Layout.Row = 1;
            app.BalancedTruncationComponents.SepTolEditField.Layout.Column = 4;   
            app.BalancedTruncationComponents.SepTolEditField.Limits = [1 inf];
            app.BalancedTruncationComponents.SepTolEditField.LowerLimitInclusive = 'off';
            app.BalancedTruncationComponents.SepTolEditField.UpperLimitInclusive = 'off';
            app.BalancedTruncationComponents.SepTolEditField.ValueChangedFcn = ...
                @(es,ed) cbBTSepTolEditFieldValueChanged(weakApp.Handle,ed);
            app.BalancedTruncationComponents.SepTolEditField.Tooltip = getString(message('Control:mrtool:BTOptionsSepTolTooltip'));
        end

        function createModalTruncationComponents(app)     
            weakApp = matlab.lang.WeakReference(app);       
            % Frequency Range
            app.ModalTruncationComponents.FrequencyRangeLabel = uilabel(app.ModalTruncationGrid);
            app.ModalTruncationComponents.FrequencyRangeLabel.Layout.Row = 1;
            app.ModalTruncationComponents.FrequencyRangeLabel.Layout.Column = 1;
            app.ModalTruncationComponents.FrequencyRangeLabel.Text = m('Control:mrtool:FrequencyRangeLabel');
            
            app.ModalTruncationComponents.FrequencyRangeLowerEditField = uieditfield(app.ModalTruncationGrid,'numeric');
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.Layout.Row = 1;
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.Layout.Column = 2;
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.Limits = [0 Inf];
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.UpperLimitInclusive = 'off';
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.ValueChangedFcn = ...
                @(es,ed) cbMTFrequencyLowerEditFieldValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.Tooltip = ...
                                    m('Control:embedded_apps:freqRangeLower');
            
            app.ModalTruncationComponents.FrequencyRangeUpperEditField = uieditfield(app.ModalTruncationGrid,'numeric');
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.Layout.Row = 1;
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.Layout.Column = 3;
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.Limits = [0 Inf];
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.LowerLimitInclusive = 'off';
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.ValueChangedFcn = ...
                @(es,ed) cbMTFrequencyUpperEditFieldValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.Tooltip = ...
                                    m('Control:embedded_apps:freqRangeUpper');
            
            app.ModalTruncationComponents.FrequencyUnitLabel = uilabel(app.ModalTruncationGrid);
            app.ModalTruncationComponents.FrequencyUnitLabel.Layout.Row = 1;
            app.ModalTruncationComponents.FrequencyUnitLabel.Layout.Column = 4;
            app.ModalTruncationComponents.FrequencyUnitLabel.Text = m('Control:embedded_apps:strFreqUnit');          
                        
            % Damping Range
            app.ModalTruncationComponents.DampingRangeLabel = uilabel(app.ModalTruncationGrid);
            app.ModalTruncationComponents.DampingRangeLabel.Layout.Row = 2;
            app.ModalTruncationComponents.DampingRangeLabel.Layout.Column = 1;
            app.ModalTruncationComponents.DampingRangeLabel.Text = m('Control:mrtool:DampingRangeLabel');

            app.ModalTruncationComponents.DampingRangeLowerEditField = uieditfield(app.ModalTruncationGrid,'numeric');
            app.ModalTruncationComponents.DampingRangeLowerEditField.Layout.Row = 2;
            app.ModalTruncationComponents.DampingRangeLowerEditField.Layout.Column = 2;
            app.ModalTruncationComponents.DampingRangeLowerEditField.Limits = [-1 1];
            app.ModalTruncationComponents.DampingRangeLowerEditField.UpperLimitInclusive = 'off';
            app.ModalTruncationComponents.DampingRangeLowerEditField.ValueChangedFcn = ...
                @(es,ed) cbMTDampingLowerEditFieldValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.DampingRangeLowerEditField.Tooltip = ...
                                    m('Control:embedded_apps:dampRangeLower');
            
            app.ModalTruncationComponents.DampingRangeUpperEditField = uieditfield(app.ModalTruncationGrid,'numeric');
            app.ModalTruncationComponents.DampingRangeUpperEditField.Layout.Row = 2;
            app.ModalTruncationComponents.DampingRangeUpperEditField.Layout.Column = 3;
            app.ModalTruncationComponents.DampingRangeUpperEditField.Limits = [-1 1];
            app.ModalTruncationComponents.DampingRangeUpperEditField.LowerLimitInclusive = 'off';
            app.ModalTruncationComponents.DampingRangeUpperEditField.ValueChangedFcn = ...
                @(es,ed) cbMTDampingUpperEditFieldValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.DampingRangeUpperEditField.Tooltip = ...
                                    m('Control:embedded_apps:dampRangeUpper');

            % MinDC
            app.ModalTruncationComponents.MinDCLabel = uilabel(app.ModalTruncationGrid);
            app.ModalTruncationComponents.MinDCLabel.Layout.Row = 3;
            app.ModalTruncationComponents.MinDCLabel.Layout.Column = 1;
            app.ModalTruncationComponents.MinDCLabel.Text = m('Control:mrtool:MinDCLabel');
            
            app.ModalTruncationComponents.MinDCEditField = uieditfield(app.ModalTruncationGrid,'numeric');
            app.ModalTruncationComponents.MinDCEditField.Layout.Row = 3;
            app.ModalTruncationComponents.MinDCEditField.Layout.Column = 2;
            app.ModalTruncationComponents.MinDCEditField.Limits = [0 Inf];
            app.ModalTruncationComponents.MinDCEditField.LowerLimitInclusive = 'off';
            app.ModalTruncationComponents.MinDCEditField.ValueChangedFcn = ...
                @(es,ed) cbMTMinDCEditFieldValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.MinDCEditField.Tooltip = m('Control:mrtool:MinDCTooltip');

            OptionsAccordian = matlab.ui.container.internal.Accordion('Parent',app.ModalTruncationGrid);
            OptionsAccordian.Layout.Row = 4;
            OptionsAccordian.Layout.Column = [1 5];
            OptionsPanel = matlab.ui.container.internal.AccordionPanel('Parent',OptionsAccordian);
            OptionsPanel.Title = getString(message('Control:embedded_apps:specifyReductionOptions'));
            OptionsPanel.Collapsed = true;
            app.ModalTruncationOptionsGrid = uigridlayout(OptionsPanel,[2 3]);
            app.ModalTruncationOptionsGrid.RowHeight = {'fit','fit'};
            app.ModalTruncationOptionsGrid.ColumnWidth = {'fit','fit','1x'};

            % Method
            app.ModalTruncationComponents.MethodCheckbox = uicheckbox(app.ModalTruncationOptionsGrid);
            app.ModalTruncationComponents.MethodCheckbox.Layout.Row = 1;
            app.ModalTruncationComponents.MethodCheckbox.Layout.Column = 1;
            app.ModalTruncationComponents.MethodCheckbox.Value = false;
            app.ModalTruncationComponents.MethodCheckbox.Text = m('Control:mrtool:OptionsMethodLabel');
            app.ModalTruncationComponents.MethodCheckbox.ValueChangedFcn = ...
                @(es,ed) cbMTMethodCheckboxValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.MethodCheckbox.Tooltip = m('Control:mrtool:OptionsMethodTooltip'); 

            app.ModalTruncationComponents.ModeOnlyCheckbox = uicheckbox(app.ModalTruncationOptionsGrid);
            app.ModalTruncationComponents.ModeOnlyCheckbox.Layout.Row = 1;
            app.ModalTruncationComponents.ModeOnlyCheckbox.Layout.Column = 2;
            app.ModalTruncationComponents.ModeOnlyCheckbox.Text = m('Control:mrtool:MTOptionsModeOnlyLabel');
            app.ModalTruncationComponents.ModeOnlyCheckbox.ValueChangedFcn = ...
                @(es,ed) cbMTModeOnlyCheckboxValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.ModeOnlyCheckbox.Tooltip = m('Control:mrtool:MTOptionsModeOnlyTooltip'); 

            AdvancedAccordian = matlab.ui.container.internal.Accordion('Parent',app.ModalTruncationOptionsGrid);
            AdvancedAccordian.Layout.Row = 2;
            AdvancedAccordian.Layout.Column = [1 3];
            AdvancedPanel = matlab.ui.container.internal.AccordionPanel('Parent',AdvancedAccordian);
            AdvancedPanel.Title = getString(message('Control:mrtool:OptionsAdvanced'));
            AdvancedPanel.Collapsed = true;
            advancedLayout = uigridlayout(AdvancedPanel,[1 4]);
            advancedLayout.ColumnWidth = {'fit','fit','fit','fit'};   

            % DC Frequency
            app.ModalTruncationComponents.DCFrequencyLabel = uilabel(advancedLayout);
            app.ModalTruncationComponents.DCFrequencyLabel.Layout.Row = 1;
            app.ModalTruncationComponents.DCFrequencyLabel.Layout.Column = 1;
            app.ModalTruncationComponents.DCFrequencyLabel.Text = getString(message('Control:mrtool:MTOptionsDCFrequency'));
            app.ModalTruncationComponents.DCFrequencyEditField = uieditfield(advancedLayout,'numeric');
            app.ModalTruncationComponents.DCFrequencyEditField.Layout.Row = 1;
            app.ModalTruncationComponents.DCFrequencyEditField.Layout.Column = 2;   
            app.ModalTruncationComponents.DCFrequencyEditField.Limits = [0 inf];
            app.ModalTruncationComponents.DCFrequencyEditField.ValueChangedFcn = ...
                @(es,ed) cbMTDCFequencyEditFieldValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.DCFrequencyEditField.Tooltip = getString(message('Control:mrtool:MTOptionsDCFrequencyTooltip'));

            % SepTol
            app.ModalTruncationComponents.SepTolLabel = uilabel(advancedLayout);
            app.ModalTruncationComponents.SepTolLabel.Layout.Row = 1;
            app.ModalTruncationComponents.SepTolLabel.Layout.Column = 3;
            app.ModalTruncationComponents.SepTolLabel.Text = getString(message('Control:mrtool:MTOptionsSepTol'));
            app.ModalTruncationComponents.SepTolEditField = uieditfield(advancedLayout,'numeric');
            app.ModalTruncationComponents.SepTolEditField.Layout.Row = 1;
            app.ModalTruncationComponents.SepTolEditField.Layout.Column = 4;   
            app.ModalTruncationComponents.SepTolEditField.Limits = [0 1];
            app.ModalTruncationComponents.SepTolEditField.LowerLimitInclusive = 'off';
            app.ModalTruncationComponents.SepTolEditField.UpperLimitInclusive = 'off';
            app.ModalTruncationComponents.SepTolEditField.ValueChangedFcn = ...
                @(es,ed) cbMTSepTolEditFieldValueChanged(weakApp.Handle,ed);
            app.ModalTruncationComponents.SepTolEditField.Tooltip = getString(message('Control:mrtool:MTOptionsSepTolTooltip'));
        end
        
        function createPoleZeroSimplificationComponents(app) 
            weakApp = matlab.lang.WeakReference(app);
            app.PoleZeroSimplificationComponents.ToleranceLabel = uilabel(app.PoleZeroSimplificationGrid);
            app.PoleZeroSimplificationComponents.ToleranceLabel.Layout.Column = 1;
            app.PoleZeroSimplificationComponents.ToleranceLabel.Text = m('Control:embedded_apps:tolerance');
         
            app.PoleZeroSimplificationComponents.ToleranceLessLabel = uilabel(app.PoleZeroSimplificationGrid);
            app.PoleZeroSimplificationComponents.ToleranceLessLabel.Layout.Column = 2;
            app.PoleZeroSimplificationComponents.ToleranceLessLabel.Text = m('Control:embedded_apps:toleranceLess');
            app.PoleZeroSimplificationComponents.ToleranceLessLabel.HorizontalAlignment = 'right';
           
            app.PoleZeroSimplificationComponents.ToleranceSlider = uislider(app.PoleZeroSimplificationGrid);
            app.PoleZeroSimplificationComponents.ToleranceSlider.Layout.Column = 3;
            app.PoleZeroSimplificationComponents.ToleranceSlider.Limits = [-10 0];
            app.PoleZeroSimplificationComponents.ToleranceSlider.MajorTicks = [];
            app.PoleZeroSimplificationComponents.ToleranceSlider.MinorTicks = [];
            app.PoleZeroSimplificationComponents.ToleranceSlider.ValueChangedFcn = ...
                @(es,ed) cbToleranceSliderValueChanged(weakApp.Handle,ed);
            app.PoleZeroSimplificationComponents.ToleranceSlider.ValueChangingFcn = ...
                @(es,ed) cbToleranceSliderValueChanging(weakApp.Handle,ed);
            app.PoleZeroSimplificationComponents.ToleranceSlider.Tooltip = ...
                                    m('Control:mrtool:ToleranceTooltip');
            
            app.PoleZeroSimplificationComponents.ToleranceMoreLabel = uilabel(app.PoleZeroSimplificationGrid);
            app.PoleZeroSimplificationComponents.ToleranceMoreLabel.Layout.Column = 4;
            app.PoleZeroSimplificationComponents.ToleranceMoreLabel.Text = m('Control:embedded_apps:toleranceMore');
            app.PoleZeroSimplificationComponents.ToleranceMoreLabel.HorizontalAlignment = 'left';
            
            app.PoleZeroSimplificationComponents.ToleranceEditField = uieditfield(app.PoleZeroSimplificationGrid,'numeric');
            app.PoleZeroSimplificationComponents.ToleranceEditField.Layout.Column = 5;
            app.PoleZeroSimplificationComponents.ToleranceEditField.Limits = [1e-10 1];
            app.PoleZeroSimplificationComponents.ToleranceEditField.ValueChangedFcn = ...
                @(es,ed) cbToleranceEditFieldValueChanged(weakApp.Handle,ed);
            app.PoleZeroSimplificationComponents.ToleranceEditField.Tooltip = ...
                                    m('Control:mrtool:ToleranceTooltip');
        end
        
        function createPlotComponents(app)       
            weakApp = matlab.lang.WeakReference(app);
            app.ComparisonPlotComponents.ComparisonPlotLabel = uilabel(app.ComparisonAndAnalysisPlotGrid);
            app.ComparisonPlotComponents.ComparisonPlotLabel.Layout.Row = 1;
            app.ComparisonPlotComponents.ComparisonPlotLabel.Layout.Column = 1;
            app.ComparisonPlotComponents.ComparisonPlotLabel.Text = m('Control:mrtool:ComparisonPlot');
             
            app.ComparisonPlotComponents.ComparisonPlotDropDown = uidropdown(app.ComparisonAndAnalysisPlotGrid);
            app.ComparisonPlotComponents.ComparisonPlotDropDown.Layout.Row = 1;
            app.ComparisonPlotComponents.ComparisonPlotDropDown.Layout.Column = 2;
            app.ComparisonPlotComponents.ComparisonPlotDropDown.ValueChangedFcn = ...
                @(es,ed) cbComparisonPlotDropDownValueChangedFcn(weakApp.Handle,ed);
            app.ComparisonPlotComponents.ComparisonPlotDropDown.Tooltip = m('Control:mrtool:ComparisonPlotTooltip');

            app.AnalysisPlotComponents.AnalysisPlotLabel = uilabel(app.ComparisonAndAnalysisPlotGrid);
            app.AnalysisPlotComponents.AnalysisPlotLabel.Layout.Row = 1;
            app.AnalysisPlotComponents.AnalysisPlotLabel.Layout.Column = 3;
            app.AnalysisPlotComponents.AnalysisPlotLabel.Text = m('Control:mrtool:AnalysisPlot');
             
            app.AnalysisPlotComponents.AnalysisPlotDropDown = uidropdown(app.ComparisonAndAnalysisPlotGrid);
            app.AnalysisPlotComponents.AnalysisPlotDropDown.Layout.Row = 1;
            app.AnalysisPlotComponents.AnalysisPlotDropDown.Layout.Column = 4;
            app.AnalysisPlotComponents.AnalysisPlotDropDown.ValueChangedFcn = ...
                @(es,ed) cbAnalysisPlotDropDownValueChangedFcn(weakApp.Handle,ed);
            app.AnalysisPlotComponents.AnalysisPlotDropDown.Tooltip = m('Control:mrtool:AnalysisPlotTooltip');

            app.OutputPlotComponents.OutputPlotLabel = uilabel(app.OutputPlotGrid);
            app.OutputPlotComponents.OutputPlotLabel.Layout.Column = 1;
            app.OutputPlotComponents.OutputPlotLabel.Text = m('Control:embedded_apps:outputPlot');
            
            app.OutputPlotComponents.OutputPlotDropDown = uidropdown(app.OutputPlotGrid);
            app.OutputPlotComponents.OutputPlotDropDown.Layout.Column = 2;
            app.OutputPlotComponents.OutputPlotDropDown.Items = ...
                cellfun(@(x) m(['Control:embedded_apps:',x]), app.OutputPlotTypes,'UniformOutput',false);
            app.OutputPlotComponents.OutputPlotDropDown.ItemsData = app.OutputPlotTypes;
            app.OutputPlotComponents.OutputPlotDropDown.Value = app.State_I.CurrentOutputPlotType;
            app.OutputPlotComponents.OutputPlotDropDown.ValueChangedFcn = ...
                @(es,ed) cbOutputPlotDropDownValueChangedFcn(weakApp.Handle,ed);
        end
    end
    
    %% Update methods
    methods (Access = private)
        function updatePreview(app)
            weakApp = matlab.lang.WeakReference(app);
            switch app.ReductionMethod
                case "balanced"
                    validComparisonPlots = app.BTComparisonPlotTypes;
                    validAnalysisPlots = app.BTAnalysisPlotTypes;
                case "modal"
                    validComparisonPlots = app.MTComparisonPlotTypes;
                    validAnalysisPlots = app.MTAnalysisPlotTypes;
                    if app.ModalTruncationData.Options.ModeOnly
                        validAnalysisPlots = validAnalysisPlots(validAnalysisPlots~="dcContrib");
                    end
                case "minreal"
                    validComparisonPlots = app.PZSComparisonPlotTypes;
                    validAnalysisPlots = app.PZSAnalysisPlotTypes;
            end

            % Comparison Plot
            if ~isempty(app.View.CurrentComparisonPlotWidget) ...
                    && isvalid(app.View.CurrentComparisonPlotWidget)
                app.View.CurrentComparisonPlotWidget.Visible = false;
            end      
            if ~any(contains(validComparisonPlots,app.State_I.CurrentComparisonPlotType))
                app.State_I.CurrentComparisonPlotType = validComparisonPlots(1);
            end      

            idx = strcmp(app.ComparisonPlotTypes,app.State_I.CurrentComparisonPlotType);
            localWidgetHandle = app.View.ComparisonPlotWidgets{idx};
            if isempty(localWidgetHandle)
                switch app.State_I.CurrentComparisonPlotType
                    case "modelResponse"
                        localWidgetHandle = mrtool.internal.plots.MRModelResponsePlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                    case "absError"
                        localWidgetHandle = mrtool.internal.plots.MRAbsoluteErrorPlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                    case "relError"
                        localWidgetHandle = mrtool.internal.plots.MRRelativeErrorPlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                    case "modeCompare"
                        localWidgetHandle = mrtool.internal.plots.MRModeComparePlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                end
                localWidgetHandle.PlotHandle.Layout.Tile = 1;
            else
                % Update existing comparison widget data
                localWidgetHandle.ToolData = app.CurrentData;
            end
            localWidgetHandle.Visible = true;
            % Add frequency selector listener
            delete(app.FrequencySelectorListener);
            if any(contains(events(localWidgetHandle),"SelectorMoved"))
                switch app.ReductionMethod
                    case "balanced"
                        app.FrequencySelectorListener = addlistener(localWidgetHandle,'SelectorMoved',...
                            @(es,ed) cbBTFrequencyRangeSelectorMoved(weakApp.Handle,ed));
                    case "modal"
                        app.FrequencySelectorListener = addlistener(localWidgetHandle,'SelectorMoved',...
                            @(es,ed) cbMTFrequencyRangeSelectorMoved(weakApp.Handle,ed));
                end
            end
            app.View.CurrentComparisonPlotWidget = localWidgetHandle;
            app.View.ComparisonPlotWidgets{idx} = localWidgetHandle;

            % Analysis Plot
            if ~isempty(app.View.CurrentAnalysisPlotWidget) ...
                    && isvalid(app.View.CurrentAnalysisPlotWidget)
                app.View.CurrentAnalysisPlotWidget.Visible = false;
            end      
            if ~any(contains(validAnalysisPlots,app.State_I.CurrentAnalysisPlotType))
                app.State_I.CurrentAnalysisPlotType = validAnalysisPlots(1);
            end      
            idx = strcmp(app.AnalysisPlotTypes,app.State_I.CurrentAnalysisPlotType);
            localWidgetHandle = app.View.AnalysisPlotWidgets{idx};
            if isempty(localWidgetHandle)
                switch app.State_I.CurrentAnalysisPlotType
                    case "hsv"
                        localWidgetHandle = mrtool.internal.plots.MRHankelPlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                        localWidgetHandle.SelectorWidget.AllowMultiSelect = false;
                    case "dcContrib"
                        localWidgetHandle = mrtool.internal.plots.MRDCContribPlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                    case "mode"
                        localWidgetHandle = mrtool.internal.plots.MRModePlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                    case "damp"
                        localWidgetHandle = mrtool.internal.plots.MRDampPlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                    case "pz"
                        localWidgetHandle = mrtool.internal.plots.MRPZPlot(...
                            app.ComparisonAndAnalysisPlotLayout,...
                            app.CurrentData);
                end
                localWidgetHandle.PlotHandle.Layout.Tile = 2;
            else
                % Update existing analysis widget data
                localWidgetHandle.ToolData = app.CurrentData;
            end
            localWidgetHandle.Visible = true;
            % Add bar selector/y level listener
            delete(app.BarSelectorListener);
            delete(app.DCContribListener);
            if any(contains(events(localWidgetHandle),"BarSelected"))
                app.BarSelectorListener = addlistener(localWidgetHandle,'BarSelected',...
                    @(es,ed) cbBTReducedOrderBarSelected(weakApp.Handle,ed));
            end
            if any(contains(events(localWidgetHandle),"SelectorMoved"))
                app.DCContribListener = addlistener(localWidgetHandle,'SelectorMoved',...
                    @(es,ed) cbMTDCContribLevelSelectorMoved(weakApp.Handle,ed));
            end
            app.View.CurrentAnalysisPlotWidget = localWidgetHandle;
            app.View.AnalysisPlotWidgets{idx} = localWidgetHandle;

            % Add data listener
            delete(app.PlotDataListener)
            app.PlotDataListener = addlistener(app.CurrentData,'ToolDataChanged',...
                @(es,ed) updatePlotSelection(weakApp.Handle));
            updatePlotSelection(app);
        end

        function updatePlotSelection(app)
            switch app.State_I.CurrentComparisonPlotType
                case {'modelResponse','absError','relError'}
                    switch app.ReductionMethod
                        case "balanced"
                            if app.BalancedTruncationData.FreqIntervalsUsed
                                sel = app.BalancedTruncationData.Options.FreqIntervals;
                            else
                                sel = [];
                            end
                        case "modal"
                            sel = app.ModalTruncationData.FrequencyRange;
                        otherwise
                            sel = [];
                    end
                    app.View.CurrentComparisonPlotWidget.Selection = sel;
            end
            switch app.State_I.CurrentAnalysisPlotType
                case 'dcContrib'
                    app.View.CurrentAnalysisPlotWidget.Selection = app.ModalTruncationData.MinDC;
            end
        end
    end
    
    %% Component Value changed functions
    methods (Access = private)
        %% Model
        function cbModelDropDownValueChanged(app,ed)
            if strcmp(app.ModelAndMethodComponents.ModelDropDown.Value,'select variable')
                app.State_I.InputVariableName = "";
            else
                app.State_I.InputVariableName = ed.Value;
            end
            if app.State_I.InputVariableName == ""
                initializeState(app);
                updateUIComponentVisibility(app,true);
            else
                updateModel(app);
                updateUIComponentVisibility(app);
            end
            updateUIComponentValues(app);
        end

        function cbMethodDropDownValueChanged(app,ed)
            app.ReductionMethod = ed.Value;
        end
        
        %% BT

        function cbBTReductionCriteriaChanged(app,ed)
            switch ed.Value
                case 'Order'
                    app.BalancedTruncationData.ReductionCriteria = "Order";
                case 'MaxError'
                    app.BalancedTruncationData.ReductionCriteria = "MaxError";
                case 'MinEnergy'
                    app.BalancedTruncationData.ReductionCriteria = "MinEnergy";
                case 'MaxLoss'
                    app.BalancedTruncationData.ReductionCriteria = "MaxLoss";
            end
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
            updatePreview(app);
        end
        
        function cbBTReductionMethodEditFieldValueChanged(app,ed)
            app.BalancedTruncationData.ReductionValue = ed.Value;
            updateUIComponentValues(app);
        end
        
        function cbBTMethodCheckboxValueChanged(app,ed)
            if ed.Value
                method = "matchDC";
            else
                method = "truncate";
            end
            app.BalancedTruncationData.Method = method;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentValues(app);
        end
        
        function cbBTAlgorithmCheckboxValueChanged(app,ed)
            if ed.Value
                algorithm = "relative";
            else
                algorithm = "absolute";
            end
            app.BalancedTruncationData.Options.Algorithm = algorithm;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
        end        

        function cbBTFrequencyRangeCheckboxValueChanged(app, ed)
            fr = [];
            if ed.Value
                fr = [app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Value...
                    app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Value];
            end
            app.BalancedTruncationData.Options.FreqIntervals = fr;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
            updatePreview(app);
        end
        
        function cbBTFrequencyRangeLowerEditFieldValueChanged(app, ed)
            app.BalancedTruncationData.Options.FreqIntervals(1) = ed.Value;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentValues(app);
            updatePreview(app);
        end
        
        function cbBTFrequencyRangeUpperEditFieldValueChanged(app, ed)
            app.BalancedTruncationData.Options.FreqIntervals(2) = ed.Value;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentValues(app);
            updatePreview(app);
        end

        function cbBTRegularizationCheckboxValueChanged(app,ed)
            if ed.Value
                app.BalancedTruncationData.Options.Regularization = getRegularization(app.BalancedTruncationData);
            else
                app.BalancedTruncationData.Options.Regularization = "auto";
            end
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
        end

        function cbBTRegularizationEditFieldValueChanged(app,ed)
            app.BalancedTruncationData.Options.Regularization = ed.Value;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
        end

        function cbBTOffsetEditFieldValueChanged(app,ed)
            app.BalancedTruncationData.Options.Offset = ed.Value;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentValues(app);
        end

        function cbBTSepTolEditFieldValueChanged(app,ed)
            app.BalancedTruncationData.Options.SepTol = ed.Value;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);
            updateUIComponentValues(app);
        end

        function cbBTFrequencyRangeSelectorMoved(app,ed)
            persistent legendStatus
            fr = ed.Data.Range;
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Limits(2) = fr(2);
            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Value = fr(1);
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Limits(1) = fr(1);
            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Value = fr(2);
            switch ed.Data.Status
                case 'Init'
                    legendStatus = app.View.CurrentComparisonPlotWidget.PlotHandle.LegendVisible;
                    app.View.CurrentComparisonPlotWidget.PlotHandle.LegendVisible = false;
                case 'InProgress'
                    app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Editable = false;
                    app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Editable = false;
                    app.View.CurrentComparisonPlotWidget.PlotHandle.Responses(end).SemanticColor = "--mw-graphics-colorNeutral-line-primary";
                case 'Finished'
                    app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Editable = true;
                    app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Editable = true;
                    app.View.CurrentComparisonPlotWidget.PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
                    app.BalancedTruncationData.Options.FreqIntervals = fr;
                    applyOptions(app.BalancedTruncationData);
                    updateReducedSystem(app.BalancedTruncationData);
                    app.State_I.BTFreqIntervals = app.BalancedTruncationData.Options.FreqIntervals;
                    app.View.CurrentComparisonPlotWidget.PlotHandle.LegendVisible = legendStatus;
            end
        end        

        function cbBTReducedOrderBarSelected(app,ed)
            value = ed.Data;
            try
                app.BalancedTruncationData.ReducedOrder = value;
            catch
                ed.Source.SelectorWidget.SelectedValues = app.BalancedTruncationData.ReducedOrder;
                return;
            end
            switch app.BalancedTruncationData.ReductionCriteria
                case 'Order'
                    app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.ReducedOrder;
                case 'MaxError'
                    app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.MaximumError;
                case 'MinEnergy'
                    app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.MinimumEnergy;
                case 'MaxLoss'
                    app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.MaximumLoss;
            end
            updateUIComponentValues(app);
        end

        %% MT

        function cbMTFrequencyUpperEditFieldValueChanged(app, ed)
            app.ModalTruncationData.FrequencyRange(2) = ed.Value;
            updateUIComponentValues(app);
        end

        function cbMTFrequencyLowerEditFieldValueChanged(app, ed)
            app.ModalTruncationData.FrequencyRange(1) = ed.Value;
            updateUIComponentValues(app);
        end

        function cbMTDampingUpperEditFieldValueChanged(app, ed)
            app.ModalTruncationData.DampingRange(2) = ed.Value;
            updateUIComponentValues(app);
        end

        function cbMTDampingLowerEditFieldValueChanged(app, ed)
            app.ModalTruncationData.DampingRange(1) = ed.Value;
            updateUIComponentValues(app);
        end

        function cbMTMinDCEditFieldValueChanged(app, ed)
            app.ModalTruncationData.MinDC = ed.Value;
            updateUIComponentValues(app);
        end

        function cbMTMethodCheckboxValueChanged(app,ed)
            if ed.Value
                method = "matchDC";
            else
                method = "truncate";
            end
            app.ModalTruncationData.Method = method;
            applyOptions(app.ModalTruncationData);
            updateReducedSystem(app.ModalTruncationData);
            updateUIComponentValues(app);
        end

        function cbMTModeOnlyCheckboxValueChanged(app,ed)
            app.ModalTruncationData.Options.ModeOnly = ed.Value;
            applyOptions(app.ModalTruncationData);
            updateReducedSystem(app.ModalTruncationData);
            updateUIComponentVisibility(app);
            updateUIComponentValues(app);
            if app.State_I.CurrentAnalysisPlotType == "dcContrib"
                updatePreview(app);
            end
        end

        function cbMTDCFequencyEditFieldValueChanged(app,ed)
            app.ModalTruncationData.Options.DCFrequency = ed.Value;
            applyOptions(app.ModalTruncationData);
            updateReducedSystem(app.ModalTruncationData);
            updateUIComponentValues(app);
        end

        function cbMTSepTolEditFieldValueChanged(app,ed)
            app.ModalTruncationData.Options.SepTol = ed.Value;
            applyOptions(app.ModalTruncationData);
            updateReducedSystem(app.ModalTruncationData);
            updateUIComponentValues(app);
        end

        function cbMTFrequencyRangeSelectorMoved(app,ed)
            persistent legendStatus
            fr = ed.Data.Range;
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.Limits(2) = fr(2);
            app.ModalTruncationComponents.FrequencyRangeLowerEditField.Value = fr(1);
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.Limits(1) = fr(1);
            app.ModalTruncationComponents.FrequencyRangeUpperEditField.Value = fr(2);
            switch ed.Data.Status
                case 'Init'
                    legendStatus = app.View.CurrentComparisonPlotWidget.PlotHandle.LegendVisible;
                    app.View.CurrentComparisonPlotWidget.PlotHandle.LegendVisible = false;
                case 'InProgress'
                    app.ModalTruncationComponents.FrequencyRangeLowerEditField.Editable = false;
                    app.ModalTruncationComponents.FrequencyRangeUpperEditField.Editable = false;
                    if app.State_I.CurrentComparisonPlotType == "modeCompare"
                        controllib.plot.internal.utils.setColorProperty(...
                            app.View.CurrentComparisonPlotWidget.PlotHandle.Children(1),"Color","--mw-graphics-colorNeutral-line-primary");
                    else
                        app.View.CurrentComparisonPlotWidget.PlotHandle.Responses(end).SemanticColor = "--mw-graphics-colorNeutral-line-primary";
                    end
                case 'Finished'
                    app.ModalTruncationComponents.FrequencyRangeLowerEditField.Editable = true;
                    app.ModalTruncationComponents.FrequencyRangeUpperEditField.Editable = true;
                    if app.State_I.CurrentComparisonPlotType == "modeCompare"
                        controllib.plot.internal.utils.setColorProperty(...
                            app.View.CurrentComparisonPlotWidget.PlotHandle.Children(1),"Color",controllib.plot.internal.utils.GraphicsColor(10).SemanticName);
                    else
                        app.View.CurrentComparisonPlotWidget.PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
                    end
                    app.ModalTruncationData.FrequencyRange = fr;
                    app.State_I.MTFrequencyRange = app.ModalTruncationData.FrequencyRange;
                    app.View.CurrentComparisonPlotWidget.PlotHandle.LegendVisible = legendStatus;
            end
        end

        function cbMTDCContribLevelSelectorMoved(app,ed)
            app.ModalTruncationComponents.MinDCEditField.Value = ed.Data.Level;
            switch ed.Data.Status
                case 'InProgress'
                    app.ModalTruncationComponents.MinDCEditField.Editable = false;
                    if app.State_I.CurrentComparisonPlotType == "modeCompare"
                        controllib.plot.internal.utils.setColorProperty(...
                            app.View.CurrentComparisonPlotWidget.PlotHandle.Children(1),"Color","--mw-graphics-colorNeutral-line-primary");
                    else
                        app.View.CurrentComparisonPlotWidget.PlotHandle.Responses(end).SemanticColor = "--mw-graphics-colorNeutral-line-primary";
                    end
                case 'Finished'
                    app.ModalTruncationComponents.MinDCEditField.Editable = true;
                    if app.State_I.CurrentComparisonPlotType == "modeCompare"
                        controllib.plot.internal.utils.setColorProperty(...
                            app.View.CurrentComparisonPlotWidget.PlotHandle.Children(1),"Color",controllib.plot.internal.utils.GraphicsColor(10).SemanticName);
                    else
                        app.View.CurrentComparisonPlotWidget.PlotHandle.Responses(end).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
                    end
                    app.ModalTruncationData.MinDC = ed.Data.Level;
                    app.State_I.MTMinDC = app.ModalTruncationData.MinDC;
            end
        end

        %% PZS

        function cbToleranceSliderValueChanged(app, ed)
            app.PoleZeroSimplificationComponents.ToleranceEditField.Editable = true;
            app.PoleZeroSimplificationData.Tolerance = 10^ed.Value;
            updateUIComponentValues(app);
        end
        
        function cbToleranceSliderValueChanging(app,ed)
            app.PoleZeroSimplificationComponents.ToleranceEditField.Value = 10^ed.Value;
            app.PoleZeroSimplificationComponents.ToleranceEditField.Editable = false;
        end
        
        function cbToleranceEditFieldValueChanged(app, ed)
            app.PoleZeroSimplificationData.Tolerance = ed.Value;
            updateUIComponentValues(app);
        end        

        %% Plots

        function cbComparisonPlotDropDownValueChangedFcn(app, ed)
            app.State_I.CurrentComparisonPlotType = ed.Value;
            updatePreview(app);
        end
        
        function cbAnalysisPlotDropDownValueChangedFcn(app, ed)
            app.State_I.CurrentAnalysisPlotType = ed.Value;
            updatePreview(app);
        end

        function cbOutputPlotDropDownValueChangedFcn(app,ed)
            app.State_I.CurrentOutputPlotType = ed.Value;
        end
    end
        
    %% Local functions
    methods (Access = private)
        function updateUIComponentVisibility(app,showDefault)
            arguments
                app (1,1) ctrlguis.embeddedapps.ModelReducerApp
                showDefault (1,1) logical = false
            end
            btComponentNames = fieldnames(app.BalancedTruncationComponents);
            mtComponentNames = fieldnames(app.ModalTruncationComponents);
            pzsComponentNames = fieldnames(app.PoleZeroSimplificationComponents);
            if showDefault
                app.ComparisonAndAnalysisPlotGrid.RowHeight{2} = 0;
                app.ParentGrid.RowHeight(2:4) = {'fit',0,0};
                app.BalancedTruncationGrid.Visible = true;
                app.ModalTruncationGrid.Visible = false;
                app.PoleZeroSimplificationGrid.Visible = false;
                cellfun(@(x) set(app.BalancedTruncationComponents.(x),'Enable',false),btComponentNames);
                cellfun(@(x) set(app.ModalTruncationComponents.(x),'Enable',false),mtComponentNames);
                cellfun(@(x) set(app.PoleZeroSimplificationComponents.(x),'Enable',false),pzsComponentNames);
                app.ComparisonPlotComponents.ComparisonPlotLabel.Enable = false;
                app.ComparisonPlotComponents.ComparisonPlotDropDown.Enable = false;
                app.AnalysisPlotComponents.AnalysisPlotLabel.Visible = true;
                app.AnalysisPlotComponents.AnalysisPlotDropDown.Visible = true;
                app.AnalysisPlotComponents.AnalysisPlotLabel.Enable = false;
                app.AnalysisPlotComponents.AnalysisPlotDropDown.Enable = false;
                app.ComparisonAndAnalysisPlotLayout.Parent.Enable = false;
                app.OutputPlotComponents.OutputPlotLabel.Enable = false;
                app.OutputPlotComponents.OutputPlotDropDown.Enable = false;
                app.ModelAndMethodComponents.MethodDropDown.Enable = false;
            else
                app.ComparisonAndAnalysisPlotGrid.RowHeight{2} = 500;
                app.ComparisonPlotComponents.ComparisonPlotLabel.Enable = true;
                app.ComparisonPlotComponents.ComparisonPlotDropDown.Enable = true;
                app.AnalysisPlotComponents.AnalysisPlotLabel.Visible = true;
                app.AnalysisPlotComponents.AnalysisPlotDropDown.Visible = true;
                app.AnalysisPlotComponents.AnalysisPlotLabel.Enable = true;
                app.AnalysisPlotComponents.AnalysisPlotDropDown.Enable = true;
                app.ComparisonAndAnalysisPlotLayout.Parent.Enable = true;
                app.OutputPlotComponents.OutputPlotLabel.Enable = true;
                app.OutputPlotComponents.OutputPlotDropDown.Enable = true;
                app.ModelAndMethodComponents.MethodDropDown.Enable = true;
                switch app.ReductionMethod
                    case "balanced"
                        app.ParentGrid.RowHeight(2:4) = {'fit',0,0};
                        app.BalancedTruncationGrid.Visible = true;
                        app.ModalTruncationGrid.Visible = false;
                        app.PoleZeroSimplificationGrid.Visible = false;
                        cellfun(@(x) set(app.BalancedTruncationComponents.(x),'Enable',true),btComponentNames);
                        cellfun(@(x) set(app.ModalTruncationComponents.(x),'Enable',false),mtComponentNames);
                        cellfun(@(x) set(app.PoleZeroSimplificationComponents.(x),'Enable',false),pzsComponentNames);
                        app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Enable = app.BalancedTruncationData.FreqIntervalsUsed;
                        app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Enable = app.BalancedTruncationData.FreqIntervalsUsed;
                        app.BalancedTruncationComponents.RegularizationEditField.Enable = isnumeric(app.BalancedTruncationData.Options.Regularization);
                        if strcmp(app.BalancedTruncationData.Options.Algorithm,"absolute")
                            app.BalancedTruncationOptionsGrid.RowHeight(2:3) = {'fit',0};
                            app.BalancedTruncationComponents.FrequencyRangeCheckbox.Visible = true;
                            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Visible = true;
                            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Visible = true;
                            app.BalancedTruncationComponents.FrequencyUnitLabel.Visible = true;
                            app.BalancedTruncationComponents.RegularizationCheckbox.Visible = false;
                            app.BalancedTruncationComponents.RegularizationEditField.Visible = false;
                        else
                            app.BalancedTruncationOptionsGrid.RowHeight(2:3) = {0,'fit'};
                            app.BalancedTruncationComponents.FrequencyRangeCheckbox.Visible = false;
                            app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Visible = false;
                            app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Visible = false;
                            app.BalancedTruncationComponents.FrequencyUnitLabel.Visible = false;
                            app.BalancedTruncationComponents.RegularizationCheckbox.Visible = true;
                            app.BalancedTruncationComponents.RegularizationEditField.Visible = true;
                        end
                        app.AnalysisPlotComponents.AnalysisPlotLabel.Visible = false;
                        app.AnalysisPlotComponents.AnalysisPlotDropDown.Visible = false;
                    case "modal"
                        app.ParentGrid.RowHeight(2:4) = {0,'fit',0};
                        app.BalancedTruncationGrid.Visible = false;
                        app.ModalTruncationGrid.Visible = true;
                        app.PoleZeroSimplificationGrid.Visible = false;
                        cellfun(@(x) set(app.BalancedTruncationComponents.(x),'Enable',false),btComponentNames);
                        cellfun(@(x) set(app.ModalTruncationComponents.(x),'Enable',true),mtComponentNames);
                        cellfun(@(x) set(app.PoleZeroSimplificationComponents.(x),'Enable',false),pzsComponentNames);
                        app.ModalTruncationComponents.MinDCLabel.Visible = ~app.ModalTruncationData.Options.ModeOnly;
                        app.ModalTruncationComponents.MinDCEditField.Visible = ~app.ModalTruncationData.Options.ModeOnly;
                        if app.ModalTruncationData.Options.ModeOnly
                            app.ModalTruncationGrid.RowHeight{3} = 0;
                        else
                            app.ModalTruncationGrid.RowHeight{3} = 'fit';
                        end
                    case "minreal"
                        app.ParentGrid.RowHeight(2:4) = {0,0,'fit'};
                        app.BalancedTruncationGrid.Visible = false;
                        app.ModalTruncationGrid.Visible = false;
                        app.PoleZeroSimplificationGrid.Visible = true;
                        cellfun(@(x) set(app.BalancedTruncationComponents.(x),'Enable',false),btComponentNames);
                        cellfun(@(x) set(app.ModalTruncationComponents.(x),'Enable',false),mtComponentNames);
                        cellfun(@(x) set(app.PoleZeroSimplificationComponents.(x),'Enable',true),pzsComponentNames);
                        app.AnalysisPlotComponents.AnalysisPlotLabel.Visible = false;
                        app.AnalysisPlotComponents.AnalysisPlotDropDown.Visible = false;
                end
            end
        end
        
        function updateUIComponentValues(app)
            app.ModelAndMethodComponents.MethodDropDown.Value = app.ReductionMethod;

            switch app.ReductionMethod
                case "balanced"
                    app.BalancedTruncationComponents.ReductionCriteriaDropDown.Value = app.BalancedTruncationData.ReductionCriteria;
                    switch app.BalancedTruncationData.ReductionCriteria
                        case 'Order'
                            app.BalancedTruncationComponents.ReductionMethodLabel.Text = m('Control:embedded_apps:reducedOrder');
                            app.BalancedTruncationComponents.ReductionMethodEditField.Limits = [app.BalancedTruncationData.MinimumOrder app.BalancedTruncationData.MaximumOrder];
                            app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.ReducedOrder;
                            app.BalancedTruncationComponents.ReductionMethodEditField.RoundFractionalValues = true;
                            app.BalancedTruncationComponents.ReductionMethodEditField.Tooltip = m('Control:mrtool:BTOrderTooltip');
                        case 'MaxError'
                            app.BalancedTruncationComponents.ReductionMethodLabel.Text = m('Control:embedded_apps:maxError');
                            app.BalancedTruncationComponents.ReductionMethodEditField.Limits = [0 Inf];
                            app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.MaximumError;
                            app.BalancedTruncationComponents.ReductionMethodEditField.RoundFractionalValues = false;
                            app.BalancedTruncationComponents.ReductionMethodEditField.Tooltip = m('Control:mrtool:BTMaxErrorTooltip');
                        case 'MinEnergy'
                            app.BalancedTruncationComponents.ReductionMethodLabel.Text = m('Control:embedded_apps:minEnergy');
                            app.BalancedTruncationComponents.ReductionMethodEditField.Limits = [0 Inf];
                            app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.MinimumEnergy;
                            app.BalancedTruncationComponents.ReductionMethodEditField.RoundFractionalValues = false;
                            app.BalancedTruncationComponents.ReductionMethodEditField.Tooltip = m('Control:mrtool:BTMinEnergyTooltip');
                        case 'MaxLoss'
                            app.BalancedTruncationComponents.ReductionMethodLabel.Text = m('Control:embedded_apps:maxLoss');
                            app.BalancedTruncationComponents.ReductionMethodEditField.Limits = [0 Inf];
                            app.BalancedTruncationComponents.ReductionMethodEditField.Value = app.BalancedTruncationData.MaximumLoss;
                            app.BalancedTruncationComponents.ReductionMethodEditField.RoundFractionalValues = false;
                            app.BalancedTruncationComponents.ReductionMethodEditField.Tooltip = m('Control:mrtool:BTMaxLossTooltip');
                    end

                    app.BalancedTruncationComponents.MethodCheckbox.Value = strcmpi(app.BalancedTruncationData.Method,'matchDC');
                    app.BalancedTruncationComponents.AlgorithmCheckbox.Value = strcmpi(app.BalancedTruncationData.Options.Algorithm,'relative');
                    app.BalancedTruncationComponents.FrequencyRangeCheckbox.Value = app.BalancedTruncationData.FreqIntervalsUsed;
                    fr = app.BalancedTruncationData.Options.FreqIntervals;
                    if isempty(fr)
                        [~,w] = sigma(app.BalancedTruncationData.TargetSystem);
                        fr = mrtool.util.setSelectorFrequencyRange([w(1) w(end)]);
                    end
                    app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Limits(2) = fr(2);
                    app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Limits(1) = fr(1);
                    app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Limits(2) = pi/abs(app.BalancedTruncationData.TargetSystem.Ts);
                    app.BalancedTruncationComponents.FrequencyRangeLowerEditField.Value = fr(1);
                    app.BalancedTruncationComponents.FrequencyRangeUpperEditField.Value = fr(2);
                    if isnumeric(app.BalancedTruncationData.Options.Regularization)
                        app.BalancedTruncationComponents.RegularizationCheckbox.Value = true;
                        app.BalancedTruncationComponents.RegularizationEditField.Value = app.BalancedTruncationData.Options.Regularization;
                    else
                        app.BalancedTruncationComponents.RegularizationCheckbox.Value = false;
                        app.BalancedTruncationComponents.RegularizationEditField.Value = getRegularization(app.BalancedTruncationData);
                    end
                    app.BalancedTruncationComponents.OffsetEditField.Value = app.BalancedTruncationData.Options.Offset;
                    app.BalancedTruncationComponents.SepTolEditField.Value = app.BalancedTruncationData.Options.SepTol;

                    validComparisionPlots = app.BTComparisonPlotTypes;
                    validAnalysisPlots = app.BTAnalysisPlotTypes;
                case "modal"
                    fr = app.ModalTruncationData.FrequencyRange;
                    app.ModalTruncationComponents.FrequencyRangeLowerEditField.Limits(2) = fr(2);
                    app.ModalTruncationComponents.FrequencyRangeUpperEditField.Limits(1) = fr(1);
                    app.ModalTruncationComponents.FrequencyRangeLowerEditField.Value = fr(1);
                    app.ModalTruncationComponents.FrequencyRangeUpperEditField.Value = fr(2);

                    dr = app.ModalTruncationData.DampingRange;
                    app.ModalTruncationComponents.DampingRangeLowerEditField.Limits(2) = dr(2);
                    app.ModalTruncationComponents.DampingRangeUpperEditField.Limits(1) = dr(1);
                    app.ModalTruncationComponents.DampingRangeLowerEditField.Value = dr(1);
                    app.ModalTruncationComponents.DampingRangeUpperEditField.Value = dr(2);

                    app.ModalTruncationComponents.MinDCEditField.Value = app.ModalTruncationData.MinDC;

                    app.ModalTruncationComponents.MethodCheckbox.Value = strcmpi(app.ModalTruncationData.Method,'matchDC');
                    app.ModalTruncationComponents.ModeOnlyCheckbox.Value = app.ModalTruncationData.Options.ModeOnly;
                    app.ModalTruncationComponents.DCFrequencyEditField.Value = app.ModalTruncationData.Options.DCFrequency;
                    app.ModalTruncationComponents.SepTolEditField.Value = app.ModalTruncationData.Options.SepTol;

                    validComparisionPlots = app.MTComparisonPlotTypes;
                    validAnalysisPlots = app.MTAnalysisPlotTypes;
                    if app.ModalTruncationData.Options.ModeOnly
                        validAnalysisPlots = validAnalysisPlots(validAnalysisPlots~="dcContrib");
                    end
                case "minreal"
                    tol = app.PoleZeroSimplificationData.Tolerance;
                    app.PoleZeroSimplificationComponents.ToleranceSlider.Value = log10(tol);
                    app.PoleZeroSimplificationComponents.ToleranceEditField.Value = tol;

                    validComparisionPlots = app.PZSComparisonPlotTypes;
                    validAnalysisPlots = app.PZSAnalysisPlotTypes;
            end
         
            app.ComparisonPlotComponents.ComparisonPlotDropDown.Items = app.ComparsionPlotMap(validComparisionPlots);
            app.ComparisonPlotComponents.ComparisonPlotDropDown.ItemsData = validComparisionPlots;
            if any(contains(validComparisionPlots,app.State_I.CurrentComparisonPlotType))
                app.ComparisonPlotComponents.ComparisonPlotDropDown.Value = app.State_I.CurrentComparisonPlotType;
            end
            app.AnalysisPlotComponents.AnalysisPlotDropDown.Items = app.AnalysisPlotMap(validAnalysisPlots);
            app.AnalysisPlotComponents.AnalysisPlotDropDown.ItemsData = validAnalysisPlots;
            if any(contains(validAnalysisPlots,app.State_I.CurrentAnalysisPlotType))
                app.AnalysisPlotComponents.AnalysisPlotDropDown.Value = app.State_I.CurrentAnalysisPlotType;
            end
            app.OutputPlotComponents.OutputPlotDropDown.Value = app.State_I.CurrentOutputPlotType;

            pushDataToState(app);
        end
   end
    
    %% State/Data functions
    methods (Access = private)
        function createData(app)
            app.BalancedTruncationData = mrtool.data.BalancedTruncationData(app.ModelWrapper);
            build(app.BalancedTruncationData);
            app.ModalTruncationData = mrtool.data.ModalTruncationData(app.ModelWrapper);
            build(app.ModalTruncationData);
            app.PoleZeroSimplificationData = mrtool.data.PoleZeroSimplificationData(app.ModelWrapper);
            build(app.PoleZeroSimplificationData);
        end
        
        function updateModel(app)
            if app.State_I.InputVariableName == ""
                app.Model = app.InitialSystem;
                app.ModelWrapper = mrtool.data.ModelWrapper("``",app.Model);
            else
                localModel = evalin('base',app.State_I.InputVariableName);
                if hasdelay(localModel)
                    app.Model = absorbDelay(localModel);
                    app.State_I.GenerateAbsorbDelayCode = true;
                else
                    app.Model = localModel;
                    app.State_I.GenerateAbsorbDelayCode = false;
                end
                app.ModelWrapper = mrtool.data.ModelWrapper(app.State_I.InputVariableName,app.Model);
            end
            app.BalancedTruncationData.Target = app.ModelWrapper;
            build(app.BalancedTruncationData);
            app.ModalTruncationData.Target = app.ModelWrapper;
            build(app.ModalTruncationData);
            app.PoleZeroSimplificationData.Target = app.ModelWrapper;
            build(app.PoleZeroSimplificationData);
            updatePreview(app);
        end
                        
        function pushDataToState(app)
            app.State_I.BTReductionCriteria = app.BalancedTruncationData.ReductionCriteria;
            app.State_I.BTReducedOrder = app.BalancedTruncationData.ReducedOrder;
            app.State_I.BTMethod = app.BalancedTruncationData.Method;
            app.State_I.BTAlgorithm = string(app.BalancedTruncationData.Options.Algorithm);
            if isnumeric(app.BalancedTruncationData.Options.Regularization)
                app.State_I.BTRegularization = app.BalancedTruncationData.Options.Regularization;
            else
                app.State_I.BTRegularization = string(app.BalancedTruncationData.Options.Regularization);
            end
            app.State_I.BTFreqIntervals = app.BalancedTruncationData.Options.FreqIntervals;
            app.State_I.BTOffset = app.BalancedTruncationData.Options.Offset;
            app.State_I.BTSepTol = app.BalancedTruncationData.Options.SepTol;

            app.State_I.MTFrequencyRange = app.ModalTruncationData.FrequencyRange;
            app.State_I.MTDampingRange = app.ModalTruncationData.DampingRange;
            app.State_I.MTMinDC = app.ModalTruncationData.MinDC;
            app.State_I.MTMethod = app.ModalTruncationData.Method;
            app.State_I.MTModeOnly = app.ModalTruncationData.Options.ModeOnly;
            app.State_I.MTDCFrequency = app.ModalTruncationData.Options.DCFrequency;
            app.State_I.MTSepTol = app.ModalTruncationData.Options.SepTol;

            app.State_I.PZSTolerance = app.PoleZeroSimplificationData.Tolerance;
        end
        
        function pushStateToData(app)
            app.BalancedTruncationData.ReductionCriteria = app.State_I.BTReductionCriteria;
            app.BalancedTruncationData.ReducedOrder = app.State_I.BTReducedOrder;
            app.BalancedTruncationData.Method = app.State_I.BTMethod;
            app.BalancedTruncationData.Options.Algorithm = app.State_I.BTAlgorithm;
            app.BalancedTruncationData.Options.Regularization = app.State_I.BTRegularization;
            app.BalancedTruncationData.Options.FreqIntervals = app.State_I.BTFreqIntervals;
            app.BalancedTruncationData.Options.Offset = app.State_I.BTOffset;
            app.BalancedTruncationData.Options.SepTol = app.State_I.BTSepTol;
            applyOptions(app.BalancedTruncationData);
            updateReducedSystem(app.BalancedTruncationData);

            if isempty(app.State_I.MTFrequencyRange)
                app.State_I.MTFrequencyRange = app.ModalTruncationData.FrequencyRange;
            else
                app.ModalTruncationData.FrequencyRange = app.State_I.MTFrequencyRange;
            end
            app.ModalTruncationData.DampingRange = app.State_I.MTDampingRange;
            app.ModalTruncationData.MinDC = app.State_I.MTMinDC;
            app.ModalTruncationData.Method = app.State_I.MTMethod;
            app.ModalTruncationData.Options.ModeOnly = app.State_I.MTModeOnly;
            app.ModalTruncationData.Options.DCFrequency = app.State_I.MTDCFrequency;
            app.ModalTruncationData.Options.SepTol = app.State_I.MTSepTol;
            applyOptions(app.ModalTruncationData);
            updateReducedSystem(app.ModalTruncationData);

            if isempty(app.State_I.PZSTolerance)
                app.State_I.PZSTolerance = app.PoleZeroSimplificationData.Tolerance;
            else
                app.PoleZeroSimplificationData.Tolerance = app.State_I.PZSTolerance;
            end
        end
    end
    
    %% QE Methods
    methods (Hidden)        
        function qeSetModel(app,modelName)
            arguments
                app (1,1) ctrlguis.embeddedapps.ModelReducerApp
                modelName (1,1) string = ""
            end
            app.ModelAndMethodComponents.ModelDropDown.populateVariables();
            app.ModelAndMethodComponents.ModelDropDown.Value = modelName;
            app.State_I.InputVariableName = modelName;
            if app.State_I.InputVariableName == ""
                initializeState(app);
                updateUIComponentVisibility(app,true);
            else
                updateModel(app);
                updateUIComponentVisibility(app);
            end
            updateUIComponentValues(app);
        end
    end
end

%% Helper functions
function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end

function idx = updateModelDropDownItems(x)
% Generate cell arrays of all workspace variables and their
% values
idx = mrtool.util.isValidSystem({x}) && ~issparse(x) && isreal(x);
end