classdef DesignSignal < controllib.ui.internal.dialog.AbstractDialog
    % Deisgn Signal Dialog for Linear Simulation Tool
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        SelectedRow
        StartTime = 0
        Interval = 0.1
        EndTime = 10
    end
    
    properties (GetAccess = public, SetAccess = private)
        Signal
        InputSignalTable
    end
    
    properties (Access = private)
        ParentGrid
        SignalTypeDropDown
        HelpButton
        InsertButton
        CancelButton
        
        DefaultNames = struct('SineSignal','Sine1',...
                              'SquareSignal','Square1',...
                              'StepSignal','Step1',...
                              'NoiseSignal','Noise1');
        SineWaveWidget
        SineWaveNameEditField
        SineWaveFrequencyEditField
        SineWaveAmplitudeEditField
        SineWaveDurationEditField
        
        SquareWaveWidget
        SquareWaveNameEditField
        SquareWaveFrequencyEditField
        SquareWaveAmplitudeEditField
        SquareWaveDurationEditField
        
        StepFunctionWidget
        StepFunctionNameEditField
        StepFunctionStartingLevelEditField
        StepFunctionStepSizeEditField
        StepFunctionTransitionTimeEditField
        StepFunctionDurationEditField
        
        WhiteNoiseWidget
        WhiteNoiseNameEditField
        WhiteNoiseMeanEditField
        WhiteNoiseStandardDeviationEditField
        WhiteNoiseProbDensityDropDown
        WhiteNoiseDurationEditField
    end
    
    events
        SignalCreated
    end
    
    methods
        function this = DesignSignal(inputSignalTable)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = 'DesignSignalDialog';
            this.Title = m('Controllib:gui:strSignalDesigner');
            this.CloseMode = 'hide';
            if nargin > 0
                this.InputSignalTable = inputSignalTable;
                this.EndTime = inputSignalTable.Data.StartTime + ...
                    inputSignalTable.Data.Interval*(inputSignalTable.Data.SimulationSamples - 1);
            end
        end
        
        function updateUI(this)
            
        end
    end
    
    methods (Access=protected)
        function buildUI(this)
            this.UIFigure.Position(3:4) = [280 290];
            parentGrid = uigridlayout(this.UIFigure);
            parentGrid.RowHeight = {'fit',1,'fit','1x',1,'fit'};
            parentGrid.ColumnWidth = {10,'1x'};
            parentGrid.Scrollable = 'on';
            this.ParentGrid = parentGrid;
            
            % Signal Type Selection
            widget = uigridlayout(parentGrid);
            widget.Layout.Row = 1;
            widget.Layout.Column = [1 2];
            widget.RowHeight = {'fit'};
            widget.ColumnWidth = {'fit','fit'};
            widget.Padding = 0;
            label = uilabel(widget,'Text',m('Controllib:gui:lblSignalType'));
            this.SignalTypeDropDown = uidropdown(widget);
            this.SignalTypeDropDown.Items = {m('Controllib:gui:strSineWave'),...
                m('Controllib:gui:strSquareWave'),...
                m('Controllib:gui:strStepFunction'),...
                m('Controllib:gui:strWhiteNoise')};
            this.SignalTypeDropDown.ItemsData = {'sine','square','step','whitenoise'};
            this.SignalTypeDropDown.ValueChangedFcn = ...
                @(es,ed) cbSignalTypeDropDownValueChanged(this,es,ed);
            
            % Signal Panel title
            label = uilabel(parentGrid,'Text',m('Controllib:gui:lblSignalAttributes'));
            label.Layout.Row = 3;
            label.Layout.Column = [1 2];
            %             label.FontWeight = 'bold';
            
            % Signal Attributes Widgets
            this.SineWaveWidget = createSineWaveWidget(this);
            this.SineWaveWidget.Parent = parentGrid;
            this.SineWaveWidget.Layout.Row = 4;
            this.SineWaveWidget.Layout.Column = 2;
            
            this.SquareWaveWidget = createSquareWaveWidget(this);
            this.StepFunctionWidget = createStepFunctionWidget(this);
            this.WhiteNoiseWidget = createWhiteNoiseWidget(this);
            
            % Buttons
            widget = uigridlayout(parentGrid);
            widget.Layout.Row = 6;
            widget.Layout.Column = [1 2];
            widget.RowHeight = {'fit'};
            widget.ColumnWidth = {'fit','1x','fit','fit'};
            widget.Padding = 0;
            this.HelpButton = uibutton(widget,'Text',m('Controllib:gui:lblHelp'));
            this.HelpButton.Layout.Column = 1;
            this.HelpButton.ButtonPushedFcn = ...
                @(es,ed) cbHelpButtonPushed(this,es,ed);
            this.InsertButton = uibutton(widget,'Text',m('Controllib:gui:strInsert'));
            this.InsertButton.Layout.Column = 3;
            this.InsertButton.ButtonPushedFcn = ...
                @(es,ed) cbInsertButtonPushed(this,es,ed);
            this.CancelButton = uibutton(widget,'Text',m('Controllib:gui:lblCancel'));
            this.CancelButton.Layout.Column = 4;
            this.CancelButton.ButtonPushedFcn = ...
                @(es,ed) cbCancelButtonPushed(this,es,ed);
            
            % Add Tags
            lsimgui.utils.internal.addTagsToWidgets(this);
        end
        
        function connectUI(this)
            
        end
        
    end
    
    methods (Access = private)
        function widget = createSineWaveWidget(this)
            widget = uigridlayout('Parent',[]);
            widget.RowHeight = {'fit','fit','fit','fit'};
            widget.ColumnWidth = {'fit','1x'};
            widget.Padding = 0;
            widget.Scrollable = 'on';
            % Labels
            label = uilabel(widget,'Text',m('Controllib:gui:lblName'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblFrequencyHz'));
            label.Layout.Row = 2;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblAmplitude'));
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblDurationSecs'));
            label.Layout.Row = 4;
            label.Layout.Column = 1;
            % Name
            editfieldwidget = uieditfield(widget);
            editfieldwidget.Layout.Row = 1;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Value = this.DefaultNames.SineSignal;
            editfieldwidget.ValueChangedFcn = ...
                @(es,ed) cbSineSignalNameValueChanged(this,es,ed);
            this.SineWaveNameEditField = editfieldwidget;
            % Frequency
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 2;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [0 Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';
            editfieldwidget.Value = 0.1;
            this.SineWaveFrequencyEditField = editfieldwidget;
            % Amplitude
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 3;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [0 Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.Value = 1;
            this.SineWaveAmplitudeEditField = editfieldwidget;
            % Duration
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 4;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [this.InputSignalTable.Data.Interval Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';            
            editfieldwidget.Value = this.EndTime;
            this.SineWaveDurationEditField = editfieldwidget;
        end
        
        function widget = createSquareWaveWidget(this)
            widget = uigridlayout('Parent',[]);
            widget.RowHeight = {'fit','fit','fit','fit'};
            widget.ColumnWidth = {'fit','1x'};
            widget.Padding = 0;
            widget.Scrollable = 'on';
            % Labels
            label = uilabel(widget,'Text',m('Controllib:gui:lblName'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblFrequencyHz'));
            label.Layout.Row = 2;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblAmplitude'));
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblDurationSecs'));
            label.Layout.Row = 4;
            label.Layout.Column = 1;
            % Name
            editfieldwidget = uieditfield(widget);
            editfieldwidget.Layout.Row = 1;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Value = this.DefaultNames.SquareSignal;
            editfieldwidget.ValueChangedFcn = ...
                @(es,ed) cbSquareSignalNameValueChanged(this,es,ed);
            this.SquareWaveNameEditField = editfieldwidget;
            % Frequency
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 2;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [0 Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';
            editfieldwidget.Value = 0.1;
            this.SquareWaveFrequencyEditField = editfieldwidget;
            % Amplitude
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 3;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [0 Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.Value = 1;
            this.SquareWaveAmplitudeEditField = editfieldwidget;
            % Duration
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 4;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [this.InputSignalTable.Data.Interval Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';            
            editfieldwidget.Value = this.EndTime;
            this.SquareWaveDurationEditField = editfieldwidget;
        end
        
        function widget = createStepFunctionWidget(this)
            widget = uigridlayout('Parent',[]);
            widget.RowHeight = {'fit','fit','fit','fit','fit'};
            widget.ColumnWidth = {'fit','1x'};
            widget.Padding = 0;
            widget.Scrollable = 'on';
            % Label
            label = uilabel(widget,'Text',m('Controllib:gui:lblName'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblStartingLevel'));
            label.Layout.Row = 2;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblStepSize'));
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblTransitionTimeSecs'));
            label.Layout.Row = 4;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblDurationSecs'));
            label.Layout.Row = 5;
            label.Layout.Column = 1;
            % Name
            editfieldwidget = uieditfield(widget);
            editfieldwidget.Layout.Row = 1;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Value = this.DefaultNames.StepSignal;
            editfieldwidget.ValueChangedFcn = ...
                @(es,ed) cbStepSignalNameValueChanged(this,es,ed);
            this.StepFunctionNameEditField = editfieldwidget;
            % Starting Level
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 2;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';
            editfieldwidget.Value = 0;
            this.StepFunctionStartingLevelEditField = editfieldwidget;
            % Step Size
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 3;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';
            editfieldwidget.Value = 1;
            this.StepFunctionStepSizeEditField = editfieldwidget;
            % Transition Time
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 4;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [0 this.EndTime];
            editfieldwidget.LowerLimitInclusive = 'off';
            editfieldwidget.UpperLimitInclusive = 'off';
            transitionTime = min([0.2 this.EndTime])/2;
            editfieldwidget.Value = transitionTime;
            editfieldwidget.ValueChangedFcn = ...
                @(es,ed) cbStepFunctionTransitionTimeChanged(this,es,ed);
            this.StepFunctionTransitionTimeEditField = editfieldwidget;
            % Duration
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 5;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [max([this.InputSignalTable.Data.Interval, transitionTime]), Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.Value = this.EndTime;
            editfieldwidget.ValueChangedFcn = ...
                @(es,ed) cbStepFunctionDurationChanged(this,es,ed);
            this.StepFunctionDurationEditField = editfieldwidget;
        end
        
        function widget = createWhiteNoiseWidget(this)
            widget = uigridlayout('Parent',[]);
            widget.RowHeight = {'fit','fit','fit','fit','fit'};
            widget.ColumnWidth = {'fit','1x'};
            widget.Padding = 0;
            widget.Scrollable = 'on';
            % Label
            label = uilabel(widget,'Text',m('Controllib:gui:lblName'));
            label.Layout.Row = 1;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblMean'));
            label.Layout.Row = 2;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblStandardDeviation'));
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblProbabilityDensity'));
            label.Layout.Row = 4;
            label.Layout.Column = 1;
            label = uilabel(widget,'Text',m('Controllib:gui:lblDurationSecs'));
            label.Layout.Row = 5;
            label.Layout.Column = 1;
            % Name
            this.WhiteNoiseNameEditField = uieditfield(widget);
            this.WhiteNoiseNameEditField.Layout.Row = 1;
            this.WhiteNoiseNameEditField.Layout.Column = 2;
            this.WhiteNoiseNameEditField.Value = this.DefaultNames.NoiseSignal;
            this.WhiteNoiseNameEditField.ValueChangedFcn = ...
                @(es,ed) cbWhiteNoiseNameValueChanged(this,es,ed);
            % Mean
            editfieldwidget= uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 2;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';
            editfieldwidget.Value = 1;
            this.WhiteNoiseMeanEditField = editfieldwidget;
            % Standard Deviation
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 3;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [0 Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.Value = 1;
            this.WhiteNoiseStandardDeviationEditField = editfieldwidget;
            % Probability Density
            this.WhiteNoiseProbDensityDropDown = uidropdown(widget);
            this.WhiteNoiseProbDensityDropDown.Layout.Row = 4;
            this.WhiteNoiseProbDensityDropDown.Layout.Column = 2;
            this.WhiteNoiseProbDensityDropDown.Items = {m('Controllib:gui:strGaussian'),...
                m('Controllib:gui:strUniform')};
            this.WhiteNoiseProbDensityDropDown.ItemsData = {'gaussian','uniform'};
            % Duration
            editfieldwidget = uieditfield(widget,'numeric');
            editfieldwidget.Layout.Row = 5;
            editfieldwidget.Layout.Column = 2;
            editfieldwidget.Limits = [this.InputSignalTable.Data.Interval Inf];
            editfieldwidget.UpperLimitInclusive = 'off';
            editfieldwidget.LowerLimitInclusive = 'off';            
            editfieldwidget.Value = this.EndTime;
            this.WhiteNoiseDurationEditField = editfieldwidget;
        end
        
        function cbSignalTypeDropDownValueChanged(this,es,ed)
            this.SineWaveWidget.Parent = [];
            this.SquareWaveWidget.Parent = [];
            this.StepFunctionWidget.Parent = [];
            this.WhiteNoiseWidget.Parent = [];
            switch es.Value
                case 'sine'
                    widgetToShow = this.SineWaveWidget;
                case 'square'
                    widgetToShow = this.SquareWaveWidget;
                case 'step'
                    widgetToShow = this.StepFunctionWidget;
                case 'whitenoise'
                    widgetToShow = this.WhiteNoiseWidget;
            end
            widgetToShow.Parent = this.ParentGrid;
            widgetToShow.Layout.Row = 4;
            widgetToShow.Layout.Column = 2;
        end
        
        function cbInsertButtonPushed(this,es,ed)
            % callback for the OK button
%             inputtable = h.importtable;
%             selectedInputs = double(inputtable.STable.getSelectedRows)+1;
            
            % R.C.: input data are sampled at 0:interval:duration (in secs) times
            % and sqrt(eps(inputtable.Interval)) is added to make sure length is right
%             if ~isempty(this.SelectedRow)
                switch this.SignalTypeDropDown.Value
                    case 'sine'
                        duration = this.SineWaveDurationEditField.Value;
                        freq = this.SineWaveFrequencyEditField.Value;
                        amp = this.SineWaveAmplitudeEditField.Value;
                        newsignal.Construction = getString(message('Controllib:gui:msgSineWaveInfo', ...
                            mat2str(amp), sprintf('%0.3g',freq), sprintf('%0.3g',this.InputSignalTable.Data.Interval)));
                        newsignal.Data = (sin(2*pi*freq*(0:this.InputSignalTable.Data.Interval:duration+sqrt(eps(this.InputSignalTable.Data.Interval))))*amp)';
                        newsignal.SubSource = this.SineWaveNameEditField.Value;
                    case 'square'
                        duration = this.SquareWaveDurationEditField.Value;
                        freq = this.SquareWaveFrequencyEditField.Value;
                        amp = this.SquareWaveAmplitudeEditField.Value;
                        newsignal.Construction = getString(message('Controllib:gui:msgSquareWaveInfo', ...
                            mat2str(amp), sprintf('%0.3g',freq), sprintf('%0.3g',this.InputSignalTable.Data.Interval)));
                        newsignal.Data = (localSquareGenerator(2*pi*freq*(0:this.InputSignalTable.Data.Interval:duration+sqrt(eps(this.InputSignalTable.Data.Interval))))*amp)';
                        newsignal.SubSource = this.SquareWaveNameEditField.Value;
                    case 'step'
                        duration = this.StepFunctionDurationEditField.Value;
                        startLevel = this.StepFunctionStartingLevelEditField.Value;
                        amp = this.StepFunctionStepSizeEditField.Value;
                        transitionTime = this.StepFunctionTransitionTimeEditField.Value;
                        newsignal.Construction = getString(message('Controllib:gui:msgStepFunctionInfo',...
                            mat2str(amp), mat2str(startLevel), mat2str(transitionTime), sprintf('%0.3g',this.InputSignalTable.Data.Interval)));
                        newsignal.Data = (~((0:this.InputSignalTable.Data.Interval:duration+sqrt(eps(this.InputSignalTable.Data.Interval)))<transitionTime)*amp+startLevel)';
                        newsignal.SubSource = this.StepFunctionNameEditField.Value;
                    case 'whitenoise'
                        duration = this.WhiteNoiseDurationEditField.Value;
                        meanLevel = this.WhiteNoiseMeanEditField.Value;
                        stdLevel = this.WhiteNoiseStandardDeviationEditField.Value;
                        probdist = this.WhiteNoiseProbDensityDropDown.Value;
                        probdistIdx = strcmp(this.WhiteNoiseProbDensityDropDown.ItemsData,probdist);
                        probdistStr = this.WhiteNoiseProbDensityDropDown.Items{probdistIdx};
                        newsignal.Construction = getString(message('Controllib:gui:msgNoiseInfo',...
                            mat2str(meanLevel), mat2str(stdLevel), probdistStr));
                        NumSamples = floor((duration-this.StartTime)/this.InputSignalTable.Data.Interval+sqrt(eps(this.InputSignalTable.Data.Interval)))+1;
                        if strcmpi(probdist,'gaussian')
                            newsignal.Data = meanLevel+stdLevel*randn(NumSamples,1);
                        else
                            newsignal.Data = meanLevel+stdLevel*(rand(NumSamples,1)-0.5)*sqrt(12);
                        end
                        newsignal.SubSource = this.WhiteNoiseNameEditField.Value;
                end
                
                newsignal.Source = 'signal designer';
                newsignal.Length = length(newsignal.Data);
                newsignal.Columns = 1;
                newsignal.Transposed = false;
%                 numpastedrows = inputtable.pasteData(newsignal);
                if isempty(newsignal.SubSource)
                    uialert(getWidget(this),m('Controllib:gui:errEmptyNames'),...
                                m('Controllib:gui:strLinearSimulationTool'),...
                                'Icon','error');
                    return;
                end
                this.Signal = newsignal;
%                 try
                    updateSignals(this.InputSignalTable,newsignal);
%                 catch ex
%                     uiconfirm(this.UIFigure,ex.message,...
%                             m('Controllib:gui:strLinearSimulationTool'),...
%                             'Icon','error');
%                     return;
%                 end
                % Notify
                notify(this,'SignalCreated');
%             end
            
        end
        
        function cbCancelButtonPushed(this,es,ed)
            close(this);
        end

        function cbHelpButtonPushed(this,es,ed)
            ctrlguihelp('lsim_designsignal');
        end
        
        function cbStepFunctionTransitionTimeChanged(this,es,ed)
            this.StepFunctionDurationEditField.Limits(1) = max([this.InputSignalTable.Data.Interval,es.Value]);
        end
        
        function cbStepFunctionDurationChanged(this,es,ed)
            this.StepFunctionTransitionTimeEditField.Limits(2) = es.Value;
        end
        
        function cbSineSignalNameValueChanged(this,es,ed)
            if isempty(es.Value)
                es.Value = this.DefaultNames.SineSignal;
            end
        end
        
        function cbSquareSignalNameValueChanged(this,es,ed)
            if isempty(es.Value)
                es.Value = this.DefaultNames.SquareSignal;
            end
        end
        
        function cbStepSignalNameValueChanged(this,es,ed)
            if isempty(es.Value)
                es.Value = this.DefaultNames.StepSignal;
            end
        end
        
        function cbWhiteNoiseNameValueChanged(this,es,ed)
            if isempty(es.Value)
                es.Value = this.DefaultNames.NoiseSignal;
            end
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.SignalTypeDropDown = this.SignalTypeDropDown;
            widgets.HelpButton = this.HelpButton;
            widgets.InsertButton = this.InsertButton;
            widgets.CancelButton = this.CancelButton;
            
            widgets.SineWaveNameEditField = this.SineWaveNameEditField;
            widgets.SineWaveFrequencyEditField = this.SineWaveFrequencyEditField;
            widgets.SineWaveAmplitudeEditField = this.SineWaveAmplitudeEditField;
            widgets.SineWaveDurationEditField = this.SineWaveDurationEditField;
            
            widgets.SquareWaveNameEditField = this.SquareWaveNameEditField;
            widgets.SquareWaveFrequencyEditField = this.SquareWaveFrequencyEditField;
            widgets.SquareWaveAmplitudeEditField = this.SquareWaveAmplitudeEditField;
            widgets.SquareWaveDurationEditField = this.SquareWaveDurationEditField;
            
            widgets.StepFunctionNameEditField = this.StepFunctionNameEditField;
            widgets.StepFunctionStartingLevelEditField = this.StepFunctionStartingLevelEditField;
            widgets.StepFunctionStepSizeEditField = this.StepFunctionStepSizeEditField;
            widgets.StepFunctionTransitionTimeEditField = this.StepFunctionTransitionTimeEditField;
            widgets.StepFunctionDurationEditField = this.StepFunctionDurationEditField;
            
            widgets.WhiteNoiseNameEditField = this.WhiteNoiseNameEditField;
            widgets.WhiteNoiseMeanEditField = this.WhiteNoiseMeanEditField;
            widgets.WhiteNoiseStandardDeviationEditField = this.WhiteNoiseStandardDeviationEditField;
            widgets.WhiteNoiseProbDensityDropDown = this.WhiteNoiseProbDensityDropDown;
            widgets.WhiteNoiseDurationEditField = this.WhiteNoiseDurationEditField;
        end
    end
end

function str = m(id,varargin)
str = getString(message(id,varargin{:}));
end

function s = localSquareGenerator(t, duty)
%copied from SQUARE method of signal processing toolbox

% If no duty specified, make duty cycle 50%.
if nargin < 2
    duty = 50;
end
if any(size(duty)~=1),
    error(message('Controllib:gui:errDutyParameterScalar'))
end
% Compute values of t normalized to (0,2*pi)
tmp = mod(t,2*pi);
% Compute normalized frequency for breaking up the interval (0,2*pi)
w0 = 2*pi*duty/100;
% Assign 1 values to normalized t between (0,w0), 0 elsewhere
nodd = (tmp < w0);
% The actual square wave computation
s = 2*nodd-1;
end  % localSquareGenerator


