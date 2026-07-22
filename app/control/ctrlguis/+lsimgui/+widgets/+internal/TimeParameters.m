classdef TimeParameters < matlab.mixin.SetGet & ...
                          controllib.ui.internal.dialog.MixedInDataListeners
    % Time Parameters Panel in Linear Simulation Tool
    
    % Copyright 2020 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = private)
        EndTime = 0;
        ParentDialog
    end
    
    properties (Access = public)
        Data
        Parent
        Name
        Container
        
        StartTimeLabel
        EndTimeEditField
        IntervalEditField
        NumberOfSamplesLabel
        ImportTimeButton
        
        ImportTimeDlg
        
        StartTimeText = '0'
        TimeVector
        NumberOfSamples = []
    end
    
    methods
        function this = TimeParameters(hParent,data)
            this.Parent = hParent;
            this.Data = data;
            this.Name = 'TimeWidget';
            if this.Data.Interval > 0 && ~isempty(this.Data.SimulationSamples)
                updateEndTime(this);
            end
            this.Container = createContainer(this);
            installListeners(this);
        end
        
        function updateUI(this)
            if ~isempty(this.Data.StartTime) && ~isempty(this.Data.Interval) && ...
                    ~isempty(this.Data.SimulationSamples)
                update(this);
            end
        end
        
        function widget = getWidget(this)
            widget = this.Container;
        end
        
        function delete(this)
            if ~isempty(this.ImportTimeDlg)
                delete(this.ImportTimeDlg);
                this.ImportTimeDlg = [];
            end
        end
        
        function closeDialogs(this)
            if ~isempty(this.ImportTimeDlg) && isvalid(this.ImportTimeDlg)
                close(this.ImportTimeDlg);
            end
        end
    end
    
    methods(Access = protected, Sealed)
        function widget = createContainer(this)
            widget = uigridlayout('Parent',this.Parent);
            widget.RowHeight = {'fit','fit','fit','fit'};
            widget.ColumnWidth = {'fit','1x',10,'fit','1x',10,'fit','1x'};
            widget.Scrollable = 'off';
            % Header label
            label = uilabel(widget,'Text',m('Controllib:gui:strTiming'));
            label.FontWeight = 'bold';
            % Start Time
            label = uilabel(widget,'Text',m('Controllib:gui:strStartTimeLabel',...
                m('Controllib:gui:strSec'),''));
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label.HorizontalAlignment = 'left';
            editfield = uieditfield(widget,'numeric');
            editfield.Layout.Row = 3;
            editfield.Layout.Column = 2;
            editfield.Value = this.Data.StartTime;
            editfield.Enable = 'off';
            editfield.Editable = 'off';
            this.StartTimeLabel = editfield;
            % End Time
            label = uilabel(widget,'Text',m('Controllib:gui:strEndTimeLabel',...
                m('Controllib:gui:strSec')));
            label.Layout.Row = 3;
            label.Layout.Column = 4;
            label.HorizontalAlignment = 'right';
            editfield = uieditfield(widget,'numeric');
            editfield.Layout.Row = 3;
            editfield.Layout.Column = 5;
            editfield.Limits = [this.Data.Interval Inf];
            editfield.UpperLimitInclusive = 'off';
            editfield.Value = this.EndTime;
            editfield.ValueChangedFcn = @(es,ed) cbEndTimeChanged(this,es,ed);
            this.EndTimeEditField = editfield;
            % Interval
            label = uilabel(widget,'Text',m('Controllib:gui:strIntervalLabel',...
                m('Controllib:gui:strSec')));
            label.Layout.Row = 3;
            label.Layout.Column = 7;
            label.HorizontalAlignment = 'right';
            editGrid = uigridlayout(widget);
            editGrid.Layout.Row = 3;
            editGrid.Layout.Column = 8;
            editGrid.RowHeight = {'fit'};
            editGrid.ColumnWidth = {'1x'};
            editGrid.ColumnSpacing = 0;
            editGrid.Padding = 0;
            editfield = uieditfield(editGrid,'numeric');
            editfield.Layout.Row = 1;
            editfield.Layout.Column = 1;
            editfield.HorizontalAlignment = 'right';
            editfield.Limits = [0 Inf];
            editfield.UpperLimitInclusive = 'off';
            editfield.Value = this.Data.Interval;
            editfield.ValueChangedFcn = @(es,ed) cbIntervalChanged(this,es,ed);
            this.IntervalEditField = editfield;
            % Number of Samples
            label = uilabel(widget,'Text',[m('Controllib:gui:strNumberofSamplesLabel'),...
                                            num2str(this.NumberOfSamples)]);
            label.Layout.Row = 4;
            label.Layout.Column = [1 5];
            this.NumberOfSamplesLabel = label;
            % Import Button
            buttonGrid = uigridlayout(widget);
            buttonGrid.Layout.Row = 4;
            buttonGrid.Layout.Column = 8;
            buttonGrid.RowHeight = {'fit'};
            buttonGrid.ColumnWidth = {'1x','fit'};
            buttonGrid.ColumnSpacing = 0;
            buttonGrid.Padding = [0 0 0 0];
            button = uibutton(buttonGrid,'Text',m('Controllib:gui:strImportTime'));
            button.Layout.Row = 1;
            button.Layout.Column = 2;
            button.HorizontalAlignment = 'right';
            button.ButtonPushedFcn = @(es,ed) cbImportTimeButtonPushed(this,es,ed);
            this.ImportTimeButton = button;
            % Add Tags
            lsimgui.utils.internal.addTagsToWidgets(this);
        end
        
        function installListeners(this)
            L = addlistener(this.Data,'InputSignalsSynced',@(es,ed) update(this));
            registerDataListeners(this,L,'InputSignalsSyncedListener');
        end
    end
    
    methods (Access = public) % ?lsimgui.internal.LinearSimulationTool
        function updateTimeVector(this,timeVector)
            this.Data.TimeVector = timeVector;
            this.EndTime = timeVector(end);
            update(this);
        end        
    end
    
    methods (Access = public) % change to private
        function cbEndTimeChanged(this,es,ed) %#ok<*INUSD> 
            this.EndTime = es.Value;
            this.IntervalEditField.LowerLimitInclusive = 'off';
            this.IntervalEditField.UpperLimitInclusive = 'on';
            this.IntervalEditField.Limits(2) = es.Value;
            this.Data.Interval = this.IntervalEditField.Value;
            this.Data.SimulationSamples = ...
                length(this.Data.StartTime:this.Data.Interval:this.EndTime);
            update(this);
        end
        
        function cbIntervalChanged(this,es,ed)
            this.IntervalEditField.LowerLimitInclusive = 'off';
            this.Data.Interval = es.Value;
            if es.Value > 0 && es.Value <= this.EndTime
                this.Data.SimulationSamples = ...
                    length(this.Data.StartTime:this.Data.Interval:this.EndTime);
                update(this);
            end
        end
        
        function cbImportTimeButtonPushed(this,es,ed)
            if isempty(this.ImportTimeDlg) || ~isvalid(this.ImportTimeDlg)
                this.ImportTimeDlg = lsimgui.dialogs.internal.ImportTime(this);
            end
            show(this.ImportTimeDlg,ancestor(getWidget(this),'figure'),'east');
        end
        
        function update(this)
            updateEndTime(this);
            if (this.Data.Interval == 0 || this.Data.Interval > this.EndTime) && ...
                    isempty(this.Data.MinimumSignalInterval) && false
                this.NumberOfSamples = [];
            else
                if this.EndTime == 0 && isempty(this.Data.SimulationSamples)
                    this.Data.SimulationSamples = this.Data.MinimumSignalInterval;
                    updateEndTime(this);
                end
                timeVector = this.Data.StartTime:this.Data.Interval:this.EndTime;
                this.NumberOfSamples = length(timeVector);
                if ~isempty(this.Data.MinimumSignalInterval) && ...
                        this.NumberOfSamples > this.Data.MinimumSignalInterval
                    this.NumberOfSamples = this.Data.MinimumSignalInterval;
                    this.Data.SimulationSamples = this.Data.MinimumSignalInterval;
                    updateEndTime(this);
                else
                    this.Data.SimulationSamples = this.NumberOfSamples;
                end
                this.StartTimeLabel.Value = this.Data.StartTime;
                this.EndTimeEditField.Value = this.EndTime;
                this.IntervalEditField.Value = this.Data.Interval;
                this.NumberOfSamplesLabel.Text = ...
                    [m('Controllib:gui:strNumberofSamplesLabel'),...
                    num2str(this.Data.SimulationSamples)];
            end
        end
        
        function updateEndTime(this)
            this.EndTime = this.Data.TimeVector(end);
            if ~isempty(this.EndTime)
                this.IntervalEditField.Limits(2) = this.EndTime;
                this.EndTimeEditField.LowerLimitInclusive = 'off';
                this.EndTimeEditField.Value = this.EndTime;
            end
        end
        
        function f = getParentUIFigure(this)
            w = getWidget(this);
            f = ancestor(w,'figure');
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(~)
            widgets = [];
        end
    end
end

function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end
