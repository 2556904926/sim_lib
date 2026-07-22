classdef ModelRateConverterApp < matlab.task.LiveTask
    % Convert model rate live task

    % Copyright 2018-2022 The MathWorks, Inc.

    % Properties that correspond to app components
    properties (Access = public)
        % UIGrid Layout components
        Grid
        ModelGrid
        MethodGrid
        VisualizeGrid

        % Main input components
        ModelDropDownLabel
        ModelDropDown
        ModelTypeLabel
        ModelTypeValueLabel
        SampleTimeEditFieldLabel
        SampleTimeEditField
        MethodDropDownLabel
        MethodDropDown

        % Dynamic components that show up when 'tustin' method is selected
        PrewarpFrequencyEditFieldLabel
        PrewarpFrequencyEditField
        DelayOrderEditFieldLabel
        DelayOrderEditField

        % Plot components
        OutputPlotLabel
        OutputPlotDropDown                      
    end

    % Properties that maintain the current state of the app and the
    % current workspace data being used
    properties (Access = public)
        State
        Summary
    end

    % Private properties
    properties (Access = private)
        State_I
    end
    
    properties (Constant)
        DefaultState = struct(...
            'Model', 'select variable',...
            'ConversionFunction', '',...
            'SampleTime', 0.2,...
            'Method', 'zoh',...
            'DelayOrder', 0,...
            'PrewarpFrequency', 0,...
            'PlotType', 'bode',...
            'TimeUnit', 'seconds');
    end

    % Constructor and Destructor
    methods (Access = public)
        function app = ModelRateConverterApp            
            
        end

        function delete(app)
            delete(app.Parent);
        end
    end

    % Abstract methods
    methods (Access = protected)
        function setup(app)
            app.createComponents();
            app.State = app.DefaultState;
        end
    end

    % App state initialization and component building
    methods (Access = private)        
        function createComponents(app)
            app.createFigureAndGridComponents();
            app.createModelSelectionComponents();
            app.createSampleTimeComponents();
            app.createMethodSelectionComponents();
            app.createMatchedAndTustinDynamicComponents();
            app.createPlotComponents();
        end

        function createFigureAndGridComponents(app)
            app.LayoutManager.Padding = 0;
            app.Grid = uigridlayout(app.LayoutManager);
            app.Grid.ColumnWidth = {'1x'};
            app.Grid.RowHeight = {22,32,22,32,22,32};
            
            app.buildHeader(app.Grid,m('Control:embedded_apps:selectInputHeader'));
            app.ModelGrid = uigridlayout(app.Grid);
            app.ModelGrid.Padding = [0 10 0 0];
            app.ModelGrid.ColumnWidth = {'fit',120,'fit','fit','fit',70};
            app.ModelGrid.RowHeight = {22};
            
            app.buildHeader(app.Grid,m('Control:embedded_apps:selectMethodHeader'));
            app.MethodGrid = uigridlayout(app.Grid);
            app.MethodGrid.Padding = [0 10 0 0];
            app.MethodGrid.ColumnWidth = {'fit',200,'fit',50,'fit',50};
            app.MethodGrid.RowHeight = {22};            
            
            app.buildHeader(app.Grid,m('Control:embedded_apps:visualizeHeader'));
            app.VisualizeGrid = uigridlayout(app.Grid);
            app.VisualizeGrid.Padding = [0 10 0 0];
            app.VisualizeGrid.ColumnWidth = {'fit',90};
            app.VisualizeGrid.RowHeight = {22};
        end

        function createModelSelectionComponents(app)
            app.ModelDropDownLabel = uilabel(app.ModelGrid);
            app.ModelDropDownLabel.Text = m('Control:embedded_apps:model');

            app.ModelDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.ModelGrid);
            app.ModelDropDown.FilterVariablesFcn = @(x) isa(x,'lti') & ~isa(x,'frd') & ...
                         ~isa(x,'genlti') & ~isa(x,'idproc');
            app.ModelDropDown.ValueChangedFcn = @(~,e)ModelDropDownValueChanged(app,e);

            app.ModelTypeLabel = uilabel(app.ModelGrid);
            app.ModelTypeLabel.Text = m('Control:embedded_apps:type');

            app.ModelTypeValueLabel = uilabel(app.ModelGrid);
            app.ModelTypeValueLabel.Text = m('Control:embedded_apps:na');
        end

        function createSampleTimeComponents(app)
            app.SampleTimeEditFieldLabel = uilabel(app.ModelGrid);
            app.SampleTimeEditFieldLabel.Text = m('Control:embedded_apps:sampleTime');

            app.SampleTimeEditField = uieditfield(app.ModelGrid,'numeric');
            app.SampleTimeEditField.ValueDisplayFormat = '%11.4g';
            app.SampleTimeEditField.ValueChangedFcn = @(~,e)SampleTimeEditFieldValueChanged(app,e);
            app.SampleTimeEditField.Limits = [0 Inf];
            app.SampleTimeEditField.LowerLimitInclusive = 'off';
            app.SampleTimeEditField.UpperLimitInclusive = 'off';
        end

        function createMethodSelectionComponents(app)
            app.MethodDropDownLabel = uilabel(app.MethodGrid);
            app.MethodDropDownLabel.Layout.Row = 1;
            app.MethodDropDownLabel.Layout.Column = 1;
            app.MethodDropDownLabel.Text = m('Control:embedded_apps:method');

            app.MethodDropDown = uidropdown(app.MethodGrid);
            app.MethodDropDown.Layout.Row = 1;
            app.MethodDropDown.Layout.Column = 2;
            app.MethodDropDown.Items = {'Zero-order hold'};
            app.MethodDropDown.ItemsData = {'zoh'};
            app.MethodDropDown.ValueChangedFcn = @(~,e)MethodDropDownValueChanged(app,e);
        end

        function createMatchedAndTustinDynamicComponents(app)
            app.DelayOrderEditFieldLabel = uilabel(app.MethodGrid);
            app.DelayOrderEditFieldLabel.Layout.Row = 1;
            app.DelayOrderEditFieldLabel.Layout.Column = 3;
            app.DelayOrderEditFieldLabel.Text = m('Control:embedded_apps:delayOrder');

            app.DelayOrderEditField = uieditfield(app.MethodGrid,'numeric');
            app.DelayOrderEditField.ValueDisplayFormat = '%d';
            app.DelayOrderEditField.RoundFractionalValues = 'on';
            app.DelayOrderEditField.Limits = [0 Inf];
            app.DelayOrderEditField.UpperLimitInclusive = 'off';
            app.DelayOrderEditField.ValueChangedFcn =  @(~,e)DelayOrderEditFieldValueChanged(app,e);
            app.DelayOrderEditField.Tooltip = m('Control:embedded_apps:delayOrderTooltip');

            app.PrewarpFrequencyEditFieldLabel = uilabel(app.MethodGrid);
            app.PrewarpFrequencyEditFieldLabel.Text = m('Control:embedded_apps:prewarpFrequency');

            app.PrewarpFrequencyEditField = uieditfield(app.MethodGrid,'numeric');
            app.PrewarpFrequencyEditField.ValueChangedFcn = @(~,e)PrewarpFrequencyEditFieldValueChanged(app,e);
        end

        function createPlotComponents(app)
            app.OutputPlotLabel = uilabel(app.VisualizeGrid);
            app.OutputPlotLabel.Text = m('Control:embedded_apps:outputPlot');
            
            % Plot Type Drop Down
            app.OutputPlotDropDown = uidropdown(app.VisualizeGrid);
            app.OutputPlotDropDown.Items = {m('Control:embedded_apps:bode'),m('Control:embedded_apps:step'),m('Control:embedded_apps:impulse'),m('Control:embedded_apps:pz'),m('Control:embedded_apps:none')};
            app.OutputPlotDropDown.ItemsData = {'bode','step','impulse','pz','none'};            
            app.OutputPlotDropDown.ValueChangedFcn = @(~,e)OutputPlotDropDownValueChanged(app,e); 
        end
    end

    % Code and Summary generation
    methods
        function [code,outputs] = generateCode(app)
            conversionFunction = app.State_I.ConversionFunction;
            
            if isempty(conversionFunction)
                % If there is no input model selected, then produce empty
                % code along with no outputs
                code = '';
                outputs = {};
            else
                
                options = '';
                outputs = {'sysConverted'};
                localInputVariableName = ['`',app.State_I.Model,'`'];

                % Only generate the options code line if the chosen method
                % is not the default 'zoh'
                if ~strcmp(app.State_I.Method,'zoh')
                    options = ['options = ' conversionFunction 'Options(' ];
                    options = [options '''Method'',''' app.State_I.Method ''','];
                end

                % Only generate 'PrewarpFrequency' Name,Value pair if the
                % chosen frequency is not the default 0
                if strcmp(app.State_I.Method,'tustin') && app.State_I.PrewarpFrequency ~= 0
                    options = [options '''PrewarpFrequency'',' num2str(app.State_I.PrewarpFrequency) ','];
                end

                % Only generate 'FractDelayApproxOrder' Name,Value pair if
                % the conversion function is 'c2d' and the chosen delay
                % order is not the default 0
                if strcmp(conversionFunction,'c2d') && ((strcmp(app.State_I.Method,'tustin') || strcmp(app.State_I.Method,'matched')) && app.State_I.DelayOrder ~= 0)
                    options = [options '''FractDelayApproxOrder'',' num2str(app.State_I.DelayOrder) ','];
                end

                % If there were some options generated from the above
                % conditions then generate a comment line and append with a
                % closing paranthesis and new lines
                if ~isempty(options)
                    optionsComment = ['% ' m(['Control:embedded_apps:',conversionFunction 'Options'])];
                    options = [optionsComment newline options(1:end-1) ');' newline newline];
                end

                % Add a comment line for the corresponding conversion
                % function
                code = ['% ' m(['Control:embedded_apps:',conversionFunction]) newline];

                code = [code sprintf('sysConverted = %s(%s',conversionFunction,localInputVariableName)];

                % Append the Sample Time if the conversion function is not
                % 'd2c'
                if ~strcmp(conversionFunction,'d2c')
                    code = [code ',' num2str(app.State_I.SampleTime)];
                end

                % If there were options generated above, then append
                % the options as the last argument
                if ~isempty(options)
                    code = [options code ',options'];
                end

                % Close the function call
                code = [code ');'];
                
                % Clear the temporary variables if needed
                if ~isempty(options)
                    code = [code newline newline '% ' m('Control:embedded_apps:clearVarComment')];
                    code = [code newline 'clear options'];
                end 

                % Create visualization code
                visualizationCode = generateVisualizationCode(app);
                if ~isempty(visualizationCode)
                    code = [code newline newline visualizationCode];
                end
            end
        end
        
        function code = generateVisualizationCode(app)
            code = '';
            if ~isempty(app.State_I.ConversionFunction) && ~strcmp(app.State_I.PlotType, 'none')
                localInputVariableName = ['`' app.State_I.Model '`'];
                originalModelStr = m('Control:embedded_apps:originalModel');
                convertedModelStr = m('Control:embedded_apps:convertedModel');
                code = ['% ' m('Control:embedded_apps:visualizeTheResults')];
                code = [code newline 'f=figure();'];
                code = [code newline sprintf('%splot(f,%s,sysConverted);',app.State_I.PlotType,localInputVariableName)];
                code = [code newline ['legend(''',originalModelStr,''',''',convertedModelStr,''');']];
                code = [code newline 'grid on;'];
                code = [code newline 'clear f;'];
            end            
        end

        function summary = get.Summary(app)
            conversionFunction = app.State_I.ConversionFunction;
            
            if isempty(conversionFunction)
                summary = m('Control:embedded_apps:modelRateConverterStaticSummary');
            else    
                method = m(['Control:embedded_apps:',app.State_I.Method]);
                switch conversionFunction
                    case 'c2d'
                        strTimeUnit = getTimeUnitString(app.State_I.TimeUnit);
                        summary = m('Control:embedded_apps:discreteSummary',...
                            app.State_I.Model,num2str(app.State_I.SampleTime),strTimeUnit,method);
                    case 'd2c'
                        summary = m('Control:embedded_apps:continuousSummary',app.State_I.Model,method);
                    case 'd2d'
                        strTimeUnit = getTimeUnitString(app.State_I.TimeUnit);
                        summary = m('Control:embedded_apps:resampleSummary',...
                            app.State_I.Model,num2str(app.State_I.SampleTime),strTimeUnit,method);
                end
            end
        end
    end

    % State management
    methods
        function session = get.State(app)
            session = app.State_I;
        end

        function set.State(app,state)
            app.State_I = state; %#ok<*MCSUP>
            app.updateAll();
            
            app.SampleTimeEditField.Value = state.SampleTime;
            app.State_I.ConversionFunction = state.ConversionFunction;
            
            if ~any(find(strcmp(app.ModelDropDown.ItemsData, state.Model)))
                app.ModelDropDown.Items = [app.ModelDropDown.Items {state.Model}];
                app.ModelDropDown.ItemsData = [app.ModelDropDown.ItemsData {state.Model}];
            end
            
            app.ModelDropDown.Value = state.Model;
           
            app.DelayOrderEditField.Value = state.DelayOrder;
            app.PrewarpFrequencyEditField.Value = state.PrewarpFrequency;
            app.OutputPlotDropDown.Value = state.PlotType;
            
            app.MethodDropDown.Value = state.Method;
        end
        
        function reset(app)
            state = app.DefaultState;
            state.Model = app.State_I.Model;
            state.ConversionFunction = app.State_I.ConversionFunction;
            state.TimeUnit = app.State_I.TimeUnit;
            app.State = state;
        end
    end

    methods (Access = public)
       function updateAll(app)
            app.updatePrewarpFreqLimits();
            app.updateDisabledComponents();
            app.updateVisibleComponents();
            app.updateModelType();
            app.updateMethodDropDownItems();
            app.updateSampleTime();
       end
    end

    % Component Value changed functions
    methods (Access = private)
        function ModelDropDownValueChanged(app,~)
            app.State_I.Model = app.ModelDropDown.Value;
            if ~strcmp(app.State_I.Model,'select variable')
                app.State_I.TimeUnit = evalin('base',[app.State_I.Model,'.TimeUnit']);
                app.determineConversionFunction();
            else
                app.State_I.TimeUnit = 'seconds';
                app.State_I.ConversionFunction = '';
            end
            app.updateAll();
        end

        function SampleTimeEditFieldValueChanged(app,~)
            app.State_I.SampleTime = app.SampleTimeEditField.Value;
            app.determineConversionFunction();
            app.updateAll();
        end

        function MethodDropDownValueChanged(app,~)
            app.State_I.Method = app.MethodDropDown.Value;
            app.updateAll();
        end

        function PrewarpFrequencyEditFieldValueChanged(app,~)
            app.State_I.PrewarpFrequency = app.PrewarpFrequencyEditField.Value;
            app.updateAll();
        end

        function DelayOrderEditFieldValueChanged(app,~)
            app.State_I.DelayOrder = app.DelayOrderEditField.Value;
            app.updateAll();
        end

        function OutputPlotDropDownValueChanged(app,~)
            app.State_I.PlotType = app.OutputPlotDropDown.Value;
            app.updateAll();
        end
    end

    % Lifecycle
    methods (Access = private)
        function UIFigureCloseRequest(app,~)
            delete(app);
        end
    end
    
    % Helper functions
    methods (Access = private)
        function buildHeader(~,parent,title)    
            l = uilabel(parent);
            l.Text = title;
            l.FontWeight = 'bold';
        end
        
        function updatePrewarpFreqLimits(app)
            upperLimit = pi/app.State_I.SampleTime;
            
            if upperLimit == 0
                upperLimit = eps;
            end
            
            if upperLimit < app.State_I.PrewarpFrequency
                app.State_I.PrewarpFrequency = 0;
            end
                        
            app.PrewarpFrequencyEditField.Limits = [0 upperLimit];
            app.PrewarpFrequencyEditField.Value = app.State_I.PrewarpFrequency;
            
            strFreqUnit = getFrequencyUnitString(app.State_I.TimeUnit);
            app.PrewarpFrequencyEditFieldLabel.Text = ...
                [m('Control:embedded_apps:prewarpFrequency'),' (',strFreqUnit,')'];
        end
        
        function updateVisibleComponents(app)
            conversionFunction = app.State_I.ConversionFunction;

            app.DelayOrderEditFieldLabel.Visible = 'off';
            app.DelayOrderEditField.Visible = 'off';
            
            app.PrewarpFrequencyEditFieldLabel.Visible = 'off';
            app.PrewarpFrequencyEditField.Visible = 'off';

            if strcmp(conversionFunction,'c2d')
                if strcmp(app.State_I.Method,'tustin') || strcmp(app.State_I.Method,'matched')
                    app.DelayOrderEditFieldLabel.Visible = 'on';
                    app.DelayOrderEditField.Visible = 'on';
                    
                    app.DelayOrderEditFieldLabel.Layout.Row = 1;
                    app.DelayOrderEditFieldLabel.Layout.Column = 3;
                    app.DelayOrderEditField.Parent = app.MethodGrid;
                    app.DelayOrderEditField.Layout.Row = 1;
                    app.DelayOrderEditField.Layout.Column = 4;
                end

                if strcmp(app.State_I.Method,'tustin')
                    app.PrewarpFrequencyEditFieldLabel.Visible = 'on';
                    app.PrewarpFrequencyEditField.Visible = 'on';
                    
                    app.PrewarpFrequencyEditFieldLabel.Layout.Row = 1;
                    app.PrewarpFrequencyEditFieldLabel.Layout.Column = 5;
                    app.PrewarpFrequencyEditField.Parent = app.MethodGrid;
                    app.PrewarpFrequencyEditField.Layout.Row = 1;
                    app.PrewarpFrequencyEditField.Layout.Column = 6;
                end
            else
                if strcmp(app.State_I.Method,'tustin')
                    app.PrewarpFrequencyEditFieldLabel.Parent = app.MethodGrid;
                    app.PrewarpFrequencyEditFieldLabel.Layout.Row = 1;
                    app.PrewarpFrequencyEditFieldLabel.Layout.Column = 3;
                    app.PrewarpFrequencyEditField.Parent = app.MethodGrid;
                    app.PrewarpFrequencyEditField.Layout.Row = 1;
                    app.PrewarpFrequencyEditField.Layout.Column = 4;
                end
            end
        end

        function updateDisabledComponents(app)
            enable = ~strcmp(app.State_I.Model,'select variable');

            app.SampleTimeEditField.Enable = enable;
            app.MethodDropDown.Enable = enable;
            app.PrewarpFrequencyEditField.Enable = enable;
            app.DelayOrderEditField.Enable = enable;
            app.OutputPlotDropDown.Enable = enable;
        end

        function updateSampleTime(app)
            if strcmp(app.State_I.Model,'select variable')
                app.SampleTimeEditFieldLabel.Text = m('Control:embedded_apps:sampleTime');
            else
                strTimeUnit = getTimeUnitString(app.State_I.TimeUnit);
                app.SampleTimeEditFieldLabel.Text = ...
                    [m('Control:embedded_apps:sampleTime'),' (',strTimeUnit,')'];
            end
            if strcmp(app.State_I.ConversionFunction, 'c2d')
                if (app.State_I.SampleTime == 0)
                    app.State_I.SampleTime = 0.2;
                    app.SampleTimeEditField.Value = app.State_I.SampleTime;
                end

                % Don't allow choosing 0 as Sample Time
                app.SampleTimeEditField.LowerLimitInclusive = 'off';

                % Don't need the tooltip for coninuous model input
                app.SampleTimeEditField.Tooltip = '';
            else
                % Allow choosing 0 as Sample Time
                app.SampleTimeEditField.LowerLimitInclusive = 'on';
                app.SampleTimeEditField.Tooltip = m('Control:embedded_apps:sampleTimeTooltip');
            end            
        end

        function updateModelType(app)
            if isempty(app.State_I.ConversionFunction)
                app.ModelTypeValueLabel.Text = m('Control:embedded_apps:na');
            else
                if strcmp(app.State_I.ConversionFunction, 'c2d')
                    app.ModelTypeValueLabel.Text = m('Control:embedded_apps:continuous');
                else
                    app.ModelTypeValueLabel.Text = m('Control:embedded_apps:discrete');
                end
            end
        end

        function determineConversionFunction(app)
                if isct(app.ModelDropDown.WorkspaceValue)
                    conversionFunction = 'c2d';
                else
                    if app.State_I.SampleTime == 0
                        conversionFunction = 'd2c';
                    else
                        conversionFunction = 'd2d';
                    end
                end
            app.State_I.ConversionFunction = conversionFunction;
        end

        function updateMethodDropDownItems(app)
            conversionFunction = app.State_I.ConversionFunction;
            items = {''};
            itemsData = {''};

            if isempty(conversionFunction)
                return;
            end

            switch (conversionFunction)
                case 'c2d'
                    items = {m('Control:embedded_apps:zoh'),m('Control:embedded_apps:foh'),m('Control:embedded_apps:impulseInvariant'),m('Control:embedded_apps:tustin')};
                    itemsData = {'zoh','foh','impulse','tustin'};
                    if (~isempty(app.ModelDropDown.WorkspaceValue) && ...
                            issiso(app.ModelDropDown.WorkspaceValue))
                        % If model exists in workspace and is SISO
                        items = [items, {m('Control:embedded_apps:matched'), m('Control:embedded_apps:least-squares')}];
                        itemsData = [itemsData, {'matched','least-squares'}];
                    elseif isempty(app.ModelDropDown.WorkspaceValue) && ...
                            strcmp(app.State_I.Method,'matched')
                        % If model does not exist in workspace and existing
                        % method is 'matched'
                        items = [items, {m('Control:embedded_apps:matched')}];
                        itemsData = [itemsData, {'matched'}];
                    elseif isempty(app.ModelDropDown.WorkspaceValue) && ...
                            strcmp(app.State_I.Method,'least-squares')
                        % If model does not exist in workspace and existing
                        % method is 'least-squares'
                        items = [items, {m('Control:embedded_apps:least-squares')}];
                        itemsData = [itemsData, {'least-squares'}];
                    end
                case 'd2c'
                    items = {m('Control:embedded_apps:zoh'),m('Control:embedded_apps:foh'),m('Control:embedded_apps:tustin')};
                    itemsData = {'zoh','foh','tustin'};
                    if (~isempty(app.ModelDropDown.WorkspaceValue) && ...
                            issiso(app.ModelDropDown.WorkspaceValue))
                        % If model exists in workspace and is SISO
                        items = [items, {m('Control:embedded_apps:matched')}];
                        itemsData = [itemsData, {'matched'}];
                    elseif isempty(app.ModelDropDown.WorkspaceValue) && ...
                            strcmp(app.State_I.Method,'matched')
                        % If model does not exist in workspace and existing
                        % method is 'matched'
                        items = [items, {m('Control:embedded_apps:matched')}];
                        itemsData = [itemsData, {'matched'}];
                    end
                case 'd2d'
                    items = {m('Control:embedded_apps:zoh'),m('Control:embedded_apps:tustin')};
                    itemsData = {'zoh','tustin'};
            end

            oldMethod = app.State_I.Method;
            app.MethodDropDown.Items = items;
            app.MethodDropDown.ItemsData = itemsData;

            if ~any(strcmp(itemsData,oldMethod))
                app.MethodDropDown.Value = itemsData{1};
                app.State_I.Method = itemsData{1};
            else
                app.MethodDropDown.Value = oldMethod;
            end

            app.MethodDropDown.Tooltip = m(sprintf('Control:embedded_apps:%sTooltip',app.State_I.Method));
        end
    end
end


function s = m(id,varargin)
  % Reads strings from the resource bundle
  id = strrep(id, '-', '');
  m = message(id,varargin{:});
  s = m.getString;
end

function strTimeUnit = getTimeUnitString(timeUnit)
validTimeUnits = controllibutils.utGetValidTimeUnits;
idx = strcmp(validTimeUnits,timeUnit);
strTimeUnit = m(validTimeUnits{idx,2});
end

function strFreqUnit = getFrequencyUnitString(timeUnit)
if strcmp(timeUnit,'seconds')
    freqUnit = 'rad/s';
else
    freqUnit = ['rad/' timeUnit(1:end-1)];
end
validFreqUnits = controllibutils.utGetValidFrequencyUnits;
idx = strcmp(validFreqUnits,freqUnit);
strFreqUnit = m(validFreqUnits{idx,2});
end
