classdef (Hidden) TuningReport < controllib.ui.internal.dialog.AbstractDialog
    % Tuning Report of Control System Tuner App.
    
    % Copyright 2024 The MathWorks, Inc.
    
    properties
        StatusText = cell(0,1);
        WarningText = cell(0,1);
        ReportView
        HelpButton
        CloseButton
    end
    
    methods
        function this = TuningReport(~)
            % Constructor
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = 'CSTuner_TuningReport';
            this.Title = getString(message('Control:systunegui:TuningReportTitle'));
        end
        
        function updateUI(this)
            this.ReportView.HTMLSource = '';
            for currentString = 1:length(this.StatusText)  
                this.ReportView.HTMLSource = strcat(this.ReportView.HTMLSource, this.StatusText{currentString});
            end
        end
        
        function clearContent(this)
            this.StatusText = cell(0,1);
            this.WarningText = cell(0,1);
            this.ReportView.HTMLSource = '';
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % Build
            % GridLayout
            figureGrid = uigridlayout(this.UIFigure, [1 2]);
            figureGrid.RowHeight = {420,'fit'};
            figureGrid.ColumnWidth = {'1x'};
            figureGrid.RowSpacing = 0;
            
            % Report View
            this.ReportView = uihtml(figureGrid);
            matlab.ui.internal.HTMLUtils.enableTheme(this.ReportView);
            this.ReportView.Layout.Row = 1;
            this.ReportView.Layout.Column = 1;
            
            % Button Panel
            ButtonPanel = uipanel(figureGrid,'Title',' ');
            ButtonPanel.Layout.Row = 2;
            ButtonPanel.Layout.Column = 1;
            ButtonPanel.BorderType = 'none';
            ButtonGrid = uigridlayout(ButtonPanel,[1 5]);
            ButtonGrid.ColumnWidth = {'fit','1x','fit','fit','fit'};
            ButtonGrid.RowHeight = 22;
            
            % Help Button
            this.HelpButton = uibutton(ButtonGrid);
            this.HelpButton.Layout.Row = 1;
            this.HelpButton.Layout.Column = 1;
            this.HelpButton.Text = getString(message('Controllib:gui:strHelp'));
            this.HelpButton.ButtonPushedFcn = @(~,~) callbackHelpButton(this);
            
            % Close button
            this.CloseButton = uibutton(ButtonGrid);
            this.CloseButton.Layout.Row = 1;
            this.CloseButton.Layout.Column = 5;
            this.CloseButton.Text = getString(message('Controllib:gui:strClose'));
            this.CloseButton.ButtonPushedFcn = @(~,~) callbackCloseButton(this);
            
            this.updateUI();
        end
        
        function callbackHelpButton(this) %#ok<*MANU>
            helpview('control','TuningReportHelp','CSHelpWindow');
        end
        
        function callbackCloseButton(this)
            this.close();
        end
    end
    
    methods (Hidden)
        function Widgets = qeGetWidgets(this)
            Widgets = struct('ReportView', this.ReportView,...
                'HelpButton', this.HelpButton,...
                'CloseButton', this.CloseButton);
        end
    end   
end