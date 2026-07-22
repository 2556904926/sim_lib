classdef AddSignalFromModelDialog < controllib.ui.internal.dialog.AbstractDialog
    %% Dialog for for adding signal from the model.
    %
    %  DLG = ADDSIGNALFROMMODELDIALOG(MODELNAME) creates DLG using the specfied
    %  MODELNAME.
    %
    %  Note that the default close mode of the dialog is "cancel", so,
    %  clicking on close (X) button does not automatically destroy the
    %  dialog.
    %
    %  ADDSIGNALFROMMODELDIALOG properties:
    %      HelpFcn          - Callback function for HELP button
    %      AddSignalFcn     - Callback function for ADD SIGNAL(S) button
    %      CancelFcn        - Callback function for CANCEL button
    %
    %  ADDSIGNALFROMMODELDIALOG methods:
    %      getBlockPathsAndPortNums - Returns selected block paths and port
    %                                 numbers
    %      reset                    - Removes all the selected signals from
    %                                 the list.
    %
    %   Examples:
    %
    %       %% Construct and show dialog.
    %       % Create and show  signal selector dialog.
    %       mdl = 'scdspeedctrl';
    %       open_system(mdl)
    %       dlg = controllib.widget.internal.signallist.AddSignalFromModelDialog(mdl);
    %       dlg.HelpFcn = @(src,data)disp('Help');
    %       dlg.AddSignalFcn = @(src,data)disp('Add signal');
    %       dlg.CancelFcn = @(src,data)disp('Cancel');
    %       show(dlg)
    %
    %       % Add a signal.
    %       ph = get_param('scdspeedctrl/PID Controller','porthandles');
    %       yp = ph.Outport(1);
    %       line = get_param(yp,'line');
    %       set_param(line,'selected','on');
    %
    %       % Get block paths and port numbers of the selected signals.
    %       [blks,pn] = getBlockPathsAndPortNums(dlg)
    %
    %       % Reset the signal list.
    %       reset(dlg)
    %
    %  See also controllib.widget.internal.signallist.SignalListPanel

    %  Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties(Dependent)
        HelpFcn
        AddSignalFcn
        CancelFcn
    end

    properties(Access=private)
        ModelName
        SignalSelector
        BottomButtonPanel
        RemoveIcon = fullfile(matlabroot,'toolbox','shared','controllib', ...
            'general','resources','toolstrip_icons',"Close_16.png");
        HighlightIcon = fullfile(matlabroot,'toolbox','slcontrol', ...
            'slctrlutil','resources','lintool','HighlightBlock_16.png');
        Widgets = struct(...
            'DialogLayout',[], ...
            'SignalList',[], ...
            'HighlightButton',[], ...
            'RemoveButton',[], ...
            'HelpButton',[], ...
            'AddSignalButton',[], ...
            'CancelButton',[] ...
            );
    end

    %% Constructor/destructor
    methods
        function this = AddSignalFromModelDialog(modelName)
            %% Constructor

            % Model
            this.ModelName = modelName;

            % Dialog attributes
            this.Title = getString(message('Control:compDesignTask:AddSignalFromModelTitle'));
            this.Name = 'dlgAddSignalFromModel';

            % Build UI.
            buildDialog(this)
        end

        function delete(this)
            %% Release resources.

            delete(this.SignalSelector)
            delete(this.BottomButtonPanel)
        end
    end

    %% Get/Set methods
    methods
        function value = get.HelpFcn(this)
            %% Returns HELPFCN.

            value = this.Widgets.HelpButton.ButtonPushedFcn;
        end

        function set.HelpFcn(this,value)
            %% Sets HELPFCN.

            this.Widgets.HelpButton.ButtonPushedFcn = value;
        end

        function value = get.AddSignalFcn(this)
            %% Returns ADDSIGNALFCN.

            value = this.Widgets.AddSignalButton.ButtonPushedFcn;
        end

        function set.AddSignalFcn(this,value)
            %% Sets ADDSIGNALFCN.

            this.Widgets.AddSignalButton.ButtonPushedFcn = value;
        end

        function value = get.CancelFcn(this)
            %% Returns CANCELFCN.

            value = this.Widgets.CancelButton.ButtonPushedFcn;
        end

        function set.CancelFcn(this,value)
            %% Sets CANCELFCN.

            this.Widgets.CancelButton.ButtonPushedFcn = value;
        end
    end

    %% Public methods
    methods
        function [blks,pn] = getBlockPathsAndPortNums(this)
            %% Returns selected block paths and port numbers.
            
            [blks,pn] = getBlockPathsAndPortNums(this.SignalSelector);
        end

        function reset(this)
            %% Resets signal list by removing all the selected signals.

            numSignal = numel(this.Widgets.SignalList.Items);
            if numSignal > 0
                removeSignal(this.SignalSelector,1:numSignal)
            end

            % The following two lines can be removed when change 6982861
            % is in LKG.
            this.Widgets.HighlightButton.Enable = false;
            this.Widgets.RemoveButton.Enable = false;
        end
    end

    %% Protected methods
    methods(Access=protected)
        function buildUI(this)
            % Creates dialog using the following layout:
            %   ------------------------
            %   | SignalSelectorPanel  |
            %   ------------------------
            %   | BottomButtonPanel    |
            %   ------------------------

            % Set dialog size.
            this.UIFigure.Position(3:4) = [410 162];

            ceateDialogLayout(this)

            row = 1;
            addSignalSelectorWidgets(this,row)


            row = row + 1;
            addBottomButtonWidgets(this,row)

            adjustLayout(this)
        end
    end

    %% Private methods
    methods(Access=private)
        function ceateDialogLayout(this)
            %% Creates dialog layout.

            dialogLayout = uigridlayout(this.UIFigure,[2 1]);
            dialogLayout.Scrollable = false;
            dialogLayout.RowHeight = {'1x','fit'};
            dialogLayout.RowSpacing = 5;
            dialogLayout.ColumnWidth = {'1x'};
            dialogLayout.ColumnSpacing = 5;
            dialogLayout.Padding = 5;

            this.Widgets.DialogLayout = dialogLayout;
        end

        function addSignalSelectorWidgets(this,row)
            %% Creates and add signal selector widgets to the dialog.

            % Create signal selector.
            buildActionpanel = true;
            this.SignalSelector = slcontrollib.internal.widget.sigselector.SignalSelectorList(this.ModelName,buildActionpanel);
            listContainer = this.SignalSelector.getWidget();
            listContainer.Parent = this.Widgets.DialogLayout;

            % Set signal selector location in the dialog.
            listContainer.Layout.Row = row;
            listContainer.Layout.Column = 1;
            signalSelectorWidget = this.SignalSelector.Widgets;
            this.Widgets.SignalList = signalSelectorWidget.SignalListBox;

            % Update highlight signal button.
            highlightButton = signalSelectorWidget.HighlightButton;
            highlightButton.Icon = this.HighlightIcon;
            highlightButton.Text = '';
            highlightButton.IconAlignment = 'center';
            this.Widgets.HighlightButton = highlightButton;

            % Update remove signal button.
            removeButton = signalSelectorWidget.RemoveButton;
            removeButton.Icon = this.RemoveIcon;
            removeButton.Text = '';
            removeButton.IconAlignment = 'center';
            this.Widgets.RemoveButton = removeButton;
        end

        function addBottomButtonWidgets(this,row)
            %% Creates and adds bottom button widgets to the dialog.

            import controllib.widget.internal.buttonpanel.ButtonPanel

            % Create button panel.
            btnPanel = ButtonPanel(this.Widgets.DialogLayout, ...
                ["help" "ok" "cancel"]);
            btnPanel.ButtonWidth = 90;
            this.BottomButtonPanel = btnPanel;
            this.Widgets.HelpButton = btnPanel.HelpButton;
            this.Widgets.HelpButton = btnPanel.HelpButton;
            addSignalButton = btnPanel.OKButton;
            addSignalButton.Text = getString(message(...
                'Control:compDesignTask:AddSignalFromModelButtonLabel'));
            this.Widgets.AddSignalButton = addSignalButton;
            this.Widgets.CancelButton = btnPanel.CancelButton;

            % Set button panel location in the dialog.
            buttonLayout = getWidget(btnPanel);
            buttonLayout.Layout.Row = row;
            buttonLayout.Layout.Column = 1;
        end

        function  adjustLayout(this)
            %% Adjust layout padding and spacing.

            % Top level layout of the signal list panel.
            listContainer = getWidget(this.SignalSelector);
            listContainer.RowSpacing = 0;

            % Layout containing the header.
            layout =  listContainer.Children(1).Children;
            layout.Padding(1) = 5;

            % Layout containing signal list and side buttons.
            layout = listContainer.Children(2).Children;
            layout.ColumnSpacing = 5;
            layout.ColumnWidth = {'1x','fit'};
            layout.Padding = 5;

            % Layout containing side buttons.
            layout = listContainer.Children(2).Children.Children(2);
            layout.RowHeight = {'1x','fit','fit','1x'};
            layout.ColumnWidth = {'fit'};
            layout.Padding = [0 10 0 10];

            % Update button positions.
            %highlightButton = ;
            %removeButton = ;
            this.Widgets.HighlightButton.Layout.Row = 2;
            this.Widgets.RemoveButton.Layout.Row = 3;

            % Layout containng bottom buttons.
            buttonLayout = getWidget(this.BottomButtonPanel);
            buttonLayout.Padding = 5;
            buttonLayout.Padding = [5 5 5 0];
        end
    end

    %% Hidden methods
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            %% Returns the widgets.

            widgets = this.Widgets;
        end
    end

end