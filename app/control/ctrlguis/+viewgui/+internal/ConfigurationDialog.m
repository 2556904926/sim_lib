classdef ConfigurationDialog < controllib.ui.internal.dialog.AbstractDialog
    % Class for the dialog to configure plot tiling for a Linear System Analyzer
    % session

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Access=protected)
        App
        PlotTilingPanel
        PlotNumberStateButtons
        PlotTypePanel
        PlotTypeLabels
        PlotTypeDropDowns
        ButtonPanel
        OKButton
        HelpButton
        CancelButton
        ApplyButton
    end

    %% Constructor
    methods
        function this = ConfigurationDialog(app)
            this = this@controllib.ui.internal.dialog.AbstractDialog();
            this.Name = 'LinearSystemAnalyzerConfigurationDialog';
            this.Title = getString(message('Control:viewer:strPlotConfigurations'));
            this.App = app;
        end
    end

    %% Public methods
    methods
        function updateUI(this)
            this.PlotNumberStateButtons(length(this.App.Plots)).Value = true;
            cbPlotConfigurationSelected(this,length(this.App.Plots));
            for ii = 1:length(this.App.Plots)
                type = this.App.Plots{ii}.Type;
                if strcmp(type,'bode') && ~this.App.Plots{ii}.PhaseVisible
                    type = 'bodemag';
                end
                this.PlotTypeDropDowns(ii).Value = type;
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function buildUI(this)
            this.UIFigure.Position(3:4) = [380 360];
            this.UIFigure.Resize = false;
            figureGrid = uigridlayout(this.UIFigure,[3 1]);
            figureGrid.RowHeight = {'1x','fit','fit'};

            this.PlotTilingPanel = uipanel(figureGrid);
            this.PlotTilingPanel.Layout.Row = 1;
            this.PlotTilingPanel.Title = getString(message('Control:viewer:strSelectAConfigurationL'));
            imageGrid = uigridlayout(this.PlotTilingPanel,[2 5]);
            imageGrid.RowHeight = {'1x','fit','fit','1x'};
            imageGrid.ColumnWidth = {'1x','fit','fit','fit','1x'};
            this.PlotNumberStateButtons = createArray([6 1],'matlab.ui.control.StateButton');
            iconNames = ["1plotLayoutWide";"2plotsLayoutWide";"3plotsLayoutWide";"4plotsLayoutWide";"5plotsLayoutWide";"6plotsLayoutWide"];
            for ii = 1:6
                plotNumberStateButton = uibutton(imageGrid,'state');
                plotNumberStateButton.Layout.Row = 2+(ii>3);
                plotNumberStateButton.Layout.Column = rem(ii-1,3)+2;
                plotNumberStateButton.Text = '';
                plotNumberStateButton.ValueChangedFcn = @(es,ed) cbPlotConfigurationSelected(this,ii);
                matlab.ui.control.internal.specifyIconID(plotNumberStateButton,iconNames(ii),50,40);
                this.PlotNumberStateButtons(ii) = plotNumberStateButton;
            end
            this.PlotNumberStateButtons(numel(this.App.Plots)).Value = true;
            this.PlotTypePanel = uipanel(figureGrid);
            this.PlotTypePanel.Layout.Row = 2;
            this.PlotTypePanel.Title = getString(message('Control:viewer:strResponsetypeL'));
            this.PlotTypePanel.Scrollable = 'on';
            plotTypeGrid = uigridlayout(this.PlotTypePanel,[3 4]);
            plotTypeGrid.RowHeight = {'fit','fit','fit'};
            plotTypeGrid.ColumnWidth = {'fit','fit','fit','fit'};
            this.PlotTypeLabels = createArray([6 1],'matlab.ui.control.Label');
            this.PlotTypeDropDowns = createArray([6 1],'matlab.ui.control.DropDown');
            for ii = 1:6
                plotLabel = uilabel(plotTypeGrid);
                plotLabel.Layout.Row = rem((ii-1),3)+1;
                plotLabel.Layout.Column = 1+2*(ii>3);
                plotLabel.Text = [num2str(ii) ':'];
                plotLabel.Enable = ii <= numel(this.App.Plots);
                plotDropDown = uidropdown(plotTypeGrid);
                plotDropDown.Layout.Row = rem((ii-1),3)+1;
                plotDropDown.Layout.Column = 2+2*(ii>3);
                plotDropDown.Items = ltiplottypes('Name');
                plotDropDown.Value = plotDropDown.Items{ii};
                plotDropDown.ItemsData = ltiplottypes('Alias');
                plotDropDown.Enable = ii <= numel(this.App.Plots);
                this.PlotTypeLabels(ii) = plotLabel;
                this.PlotTypeDropDowns(ii) = plotDropDown;
            end
            
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                figureGrid, ["help" "ok" "cancel" "apply"]);
            btnCont = getWidget(this.ButtonPanel);
            btnCont.Layout.Row = 3;
            this.OKButton = this.ButtonPanel.OKButton;
            this.HelpButton = this.ButtonPanel.HelpButton;
            this.CancelButton = this.ButtonPanel.CancelButton;
            this.ApplyButton = this.ButtonPanel.ApplyButton;
            this.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButtonPushed(this);
            this.CancelButton.ButtonPushedFcn = @(es,ed) close(this);
            this.ApplyButton.ButtonPushedFcn = @(es,ed) cbApplyButtonPushed(this);
        end

        function connectUI(this)
            L1 = addlistener(getWidget(this), 'ObjectBeingDestroyed',@(es,ed) delete(this));
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) close(this)); 
            registerUIListeners(this,L2);
        end

        function cbPlotConfigurationSelected(this,configNumber)
            for ii = setdiff(1:6,configNumber)
                this.PlotNumberStateButtons(ii).Value = false;
            end
            for ii = 1:configNumber
                this.PlotTypeLabels(ii).Enable = true;
                this.PlotTypeDropDowns(ii).Enable = true;
            end
            for ii = configNumber+1:6
                this.PlotTypeLabels(ii).Enable = false;
                this.PlotTypeDropDowns(ii).Enable = false;
            end
        end

        function cbHelpButtonPushed(this) %#ok<MANU>
            helpview('control','viewer_plotconfigurations');
        end

        function cbOKButtonPushed(this)
            numPlots = nnz(arrayfun(@(x) x.Enable,this.PlotTypeDropDowns));
            plotType = strings(numPlots,1);
            for ii = 1:numPlots
                plotType(ii) = this.PlotTypeDropDowns(ii).Value;
            end
            setCurrentPlots(this.App,plotType);
            close(this);
            postStatus(this.App,getString(message('Control:viewer:msgConfigurationChangeCompleted')));
        end

        function cbApplyButtonPushed(this)
            numPlots = nnz(arrayfun(@(x) x.Enable,this.PlotTypeDropDowns));
            plotType = strings(numPlots,1);
            for ii = 1:numPlots
                plotType(ii) = this.PlotTypeDropDowns(ii).Value;
            end
            setCurrentPlots(this.App,plotType);
            postStatus(this.App,getString(message('Control:viewer:msgConfigurationChangeCompleted')));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.PlotTilingPanel = this.PlotTilingPanel;
            widgets.PlotNumberStateButtons = this.PlotNumberStateButtons;
            widgets.PlotTypePanel = this.PlotTypePanel;
            widgets.PlotTypeLabels = this.PlotTypeLabels;
            widgets.PlotTypeDropDowns = this.PlotTypeDropDowns;
            widgets.ButtonPanel = this.ButtonPanel;
            widgets.OKButton = this.OKButton;
            widgets.HelpButton = this.HelpButton;
            widgets.CancelButton = this.CancelButton;
            widgets.ApplyButton = this.ApplyButton;
        end
    end
end