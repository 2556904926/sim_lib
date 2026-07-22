classdef StartupDialog < controllib.ui.internal.dialog.AbstractDialog
    % Class for the dialog to welcome users to a Linear System Analyzer
    % session

    % Copyright 2024 The MathWorks, Inc.

    properties (Access=protected)
        App
        MessageLabel
        ShowAgainCheckbox
        ButtonPanel
        HelpButton
        CloseButton
    end

    methods
        function this = StartupDialog(app)
            this = this@controllib.ui.internal.dialog.AbstractDialog();
            this.Name = 'LinearSystemAnalyzerStartupDialog';
            this.Title = getString(message('Control:viewer:strGettingStartedLTIViewer'));
            this.App = app;
        end
        function close(this)
            if this.ShowAgainCheckbox.Value
                h = cstprefs.tbxprefs();
                h.StartUpMsgBox.LTIviewer = 'off';
                save(h);
            end
            close@controllib.ui.internal.dialog.AbstractDialog(this);
        end
    end
    methods (Access=protected)
        function buildUI(this)
            this.UIFigure.Position(3:4) = [420 150];
            figureGrid = uigridlayout(this.UIFigure,[3 2]);
            figureGrid.RowHeight = {'1x','fit','fit'};
            figureGrid.ColumnWidth = {'1x','fit'};
            this.MessageLabel = uilabel(figureGrid);
            this.MessageLabel.Layout.Row = 1;
            this.MessageLabel.Layout.Column = [1 2];
            this.MessageLabel.Text = getString(message('Control:viewer:msgGettingStartedLTIViewer'));
            this.MessageLabel.WordWrap = 'on';
            this.ShowAgainCheckbox = uicheckbox(figureGrid);
            this.ShowAgainCheckbox.Layout.Row = 2;
            this.ShowAgainCheckbox.Layout.Column = 2;
            this.ShowAgainCheckbox.Text = getString(message('Control:general:lblDoNotShowAgain'));
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                figureGrid, ["help" "close"]);
            btnCont = getWidget(this.ButtonPanel);
            btnCont.Layout.Row = 3;
            btnCont.Layout.Column = [1 2];
            this.HelpButton = this.ButtonPanel.HelpButton;
            this.CloseButton = this.ButtonPanel.CloseButton;
            this.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButtonPushed(this);
            this.CloseButton.ButtonPushedFcn = @(es,ed) close(this);
        end
        function connectUI(this)
            L1 = addlistener(getWidget(this), 'ObjectBeingDestroyed',@(es,ed) delete(this));
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) close(this)); 
            registerUIListeners(this,L2);
        end
        function cbHelpButtonPushed(this) %#ok<MANU>
            helpview('control','viewermainhelp');
        end
    end
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.ButtonPanel = this.ButtonPanel;
            widgets.HelpButton = this.HelpButton;
            widgets.CloseButton = this.CloseButton;
            widgets.MessageLabel = this.MessageLabel;
            widgets.ShowAgainCheckbox = this.ShowAgainCheckbox;
        end
    end
end