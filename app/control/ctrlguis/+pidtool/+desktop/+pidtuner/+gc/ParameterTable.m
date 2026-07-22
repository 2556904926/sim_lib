classdef ParameterTable < controllib.ui.internal.dialog.AbstractDialog
    %PARAMETERTABLE
    
    % Author(s): Baljeet Singh 05-Sep-2013
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        DataSourcePlot
        ParameterTableView
        MetricTableView
        CloseButton
    end
    methods
        function this = ParameterTable(datasrcplot)
            %PARAMETERTABLE
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.DataSourcePlot = datasrcplot;
            this.Name = 'PIDTUNER_SHOWPARAMETERS';
            this.Title = erase(pidtool.utPIDgetStrings('cst', 'strShowParams'),'\n');
        end
        
        function updateUI(this)
          % ADD CODE HERE FOR VISIBILITY
          this.callbackParameterTableData()
          this.callbackMetricTableData()
        end

        function updateView(this)
            if this.DataSourcePlot.showBaseline
                this.ParameterTableView.Data = this.DataSourcePlot.ParameterTableModel(:,:);
                this.MetricTableView.Data = this.DataSourcePlot.MetricTableModel(:,:);
            else
                this.ParameterTableView.Data = this.DataSourcePlot.ParameterTableModel(:,1:2);
                this.MetricTableView.Data = this.DataSourcePlot.MetricTableModel(:,1:2);
            end
        end
    end
        
        methods (Access=protected)
            function buildUI(this)
                %BUILD
                % GridLayout
                this.UIFigure.Position(3:4) = [480 500];
                figureGrid = uigridlayout(this.UIFigure,[1 3]);
                figureGrid.RowSpacing = 0;
                figureGrid.RowHeight = {'fit','fit','fit'};
                figureGrid.ColumnWidth = {'1x'};
                figureGrid.RowSpacing = 5;

                % Parameters Panel
                ParametersPanel = uipanel(figureGrid,'Title',...
                    pidtool.utPIDgetStrings('cst','plotpanel_parametertablebox'));
                ParametersPanel.Layout.Row = 1;
                ParametersPanel.Layout.Column = 1;
                ParametersPanel.FontWeight = 'bold';
                ParametersPanel.BorderType = 'none';
                ParametersPanel.Scrollable = 'on';
                ParametersGrid = uigridlayout(ParametersPanel,[1 1]);
                ParametersGrid.RowHeight = 161;
    
                % Parameters table
                ParameterTableModel = this.DataSourcePlot.ParameterTableModel;
                this.ParameterTableView = uitable(ParametersGrid,'Data',ParameterTableModel);
                this.ParameterTableView.Layout.Row = 1;
                this.ParameterTableView.Layout.Column = 1;
                this.ParameterTableView.ColumnName = this.DataSourcePlot.HeaderStrings;
                this.ParameterTableView.RowName = [];
                
                % Metrics Panel
                MetricsPanel = uipanel(figureGrid,'Title',...
                    pidtool.utPIDgetStrings('cst','plotpanel_metrictablebox'));
                MetricsPanel.Layout.Row = 2;
                MetricsPanel.Layout.Column = 1;
                MetricsPanel.FontWeight = 'bold';
                MetricsPanel.BorderType = 'none';
                MetricsPanel.Scrollable = 'on';
                MetricsGrid = uigridlayout(MetricsPanel,[1 1]);
                MetricsGrid.RowHeight = 183;
    
                % Metrics table
                MetricTableModel = this.DataSourcePlot.MetricTableModel;
                this.MetricTableView = uitable(MetricsGrid,'Data',MetricTableModel);
                this.MetricTableView.Layout.Row = 1;
                this.MetricTableView.Layout.Column = 1;
                this.MetricTableView.ColumnName = this.DataSourcePlot.HeaderStrings;
                this.MetricTableView.RowName = [];
                
                % Button Panel
                ButtonPanel = uipanel(figureGrid,'Title',' ');
                ButtonPanel.Layout.Row = 3;
                ButtonPanel.Layout.Column = 1;
                ButtonPanel.BorderType = 'none';
                ButtonGrid = uigridlayout(ButtonPanel,[1 5]);
                ButtonGrid.ColumnWidth = {'fit','1x','fit','fit','fit'};
                ButtonGrid.RowHeight = 22;

                % Close button
                this.CloseButton = uibutton(ButtonGrid);
                this.CloseButton.Layout.Row = 1;
                this.CloseButton.Layout.Column = 5;
                this.CloseButton.Text = getString(message('Controllib:gui:strClose'));
                this.CloseButton.ButtonPushedFcn = @(~,~) callbackCloseButton(this);

                this.updateView();
            end
            
            function connectUI(this)
                L1 = addlistener(this.DataSourcePlot, 'ParameterTableModel', 'PostSet', @(~,~) this.callbackParameterTableData());
                L2 = addlistener(this.DataSourcePlot, 'MetricTableModel', 'PostSet', @(~,~) this.callbackMetricTableData());
                L3 = addlistener(this.DataSourcePlot, 'showBaseline', 'PostSet', @(~,~) this.updateView());
                L4 = addlistener(this.DataSourcePlot, 'hasBaseline', 'PostSet', @(~,~) this.updateView());
                registerUIListeners(this,[L1 L2 L3 L4]);
            end
        
            function callbackParameterTableData(this)
                if this.DataSourcePlot.showBaseline
                    this.ParameterTableView.Data = this.DataSourcePlot.ParameterTableModel(:,:);
                else
                    this.ParameterTableView.Data = this.DataSourcePlot.ParameterTableModel(:,1:2);
                end
            end
            function callbackMetricTableData(this)
                if this.DataSourcePlot.showBaseline
                    this.MetricTableView.Data = this.DataSourcePlot.MetricTableModel(:,:);
                else
                    this.MetricTableView.Data = this.DataSourcePlot.MetricTableModel(:,1:2);
                end
            end
            function callbackCloseButton(this)
                this.close();
            end
        
        end
    methods (Hidden)
        function Widgets = qeGetWidgets(this) 
            Widgets = struct('ParameterTableView',this.ParameterTableView,...
                            'MetricTableView',this.MetricTableView,...
                            'CloseButton',this.CloseButton);
        end
    end
end
