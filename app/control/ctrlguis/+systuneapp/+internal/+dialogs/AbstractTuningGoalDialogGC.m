classdef AbstractTuningGoalDialogGC < controllib.ui.internal.dialog.AbstractDialogGC
    % Base class for tuning goal dialogs

    % Copyright 2021 The MathWorks, Inc.

    properties(Access = protected)
        Widgets
        TuningGoalSpecGC
        NameLabelText = ''
    end

    methods
        function this = AbstractTuningGoalDialogGC(tcpeer)
            this = this@controllib.ui.internal.dialog.AbstractDialogGC(tcpeer);
            this.TuningGoalSpecGC = createView(this.TCPeer.TuningGoalSpecTC);
        end

        function pack(this,varargin)
            this.Widgets.MainPanel.ColumnWidth = {400};
            pack@controllib.ui.internal.dialog.AbstractDialogGC(this,varargin{:});
            drawnow; % This is needed for adjusting to fixed width above
            this.Widgets.MainPanel.ColumnWidth = {'1x'};
        end

        function updateUI(this)
            updateUI(this.TuningGoalSpecGC);
            update(this);
        end
    end

    methods(Access = protected, Sealed)
        function buildUI(this)
            this.UIFigure.Position(3:4) = [400 600];

            %% Main Panel
            MainPanel = uigridlayout(this.UIFigure,'RowHeight',{25,'1x',2,25},...
                'ColumnWidth',{'1x'});
            MainPanel.Padding = [10 10 10 10];

            %% NamePanel = [ NameLabel NameTextField ]
            NamePanel = uigridlayout(MainPanel,'RowHeight',{'fit','fit'},...
                'ColumnWidth',{'fit','1x'},'Padding',3);
            NamePanel.Layout.Row = 1;
            NamePanel.Layout.Column = 1;
            NameLabel = uilabel(NamePanel,...
                'Text',this.NameLabelText,...
                'FontWeight','bold',...
                'FontSize',12,...
                'FontName','Helvetica');
            NameTextField = uieditfield(NamePanel);

            %% Tuning Goal Panel
            TuningGoalPanel = createTuningGoalPanel(this);
            TuningGoalPanel.Parent = MainPanel;
            TuningGoalPanel.Layout.Row = 2;
            TuningGoalPanel.Layout.Column = 1;
            TuningGoalPanel.Scrollable = true;
            
            %% Button Panel
            % Create button panel and get the button layout.
            if ~strcmp(this.TCPeer.Type,'Looptune')
                ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                    MainPanel,["help" "ok" "apply" "cancel"]);
            else
                ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                    MainPanel,["help" "ok" "cancel"]);
            end
            widget = getWidget(ButtonPanel);
            widget.Layout.Row = 4;
            widget.Layout.Column = 1;
            widget.Padding = 0;
            widget.Scrollable = false;

            %% Add to Widgets
            this.Widgets.MainPanel = MainPanel;
            this.Widgets.NameSection.panel = NamePanel;
            this.Widgets.NameSection.label = NameLabel;
            this.Widgets.NameSection.textfield = NameTextField;
            this.Widgets.TuningGoalPanel = TuningGoalPanel;
            this.Widgets.TuningSpecSection = this.TuningGoalSpecGC;
            this.Widgets.ButtonPanel = ButtonPanel;
        end
    end

    methods(Access = protected)
        function update(this)
            this.Widgets.NameSection.textfield.Value = this.TCPeer.Name;
        end

        function connectUI(this)
            % name and close listeners
            this.Widgets.NameSection.textfield.ValueChangedFcn = ...
                @(es,ed) setName(this,es);

            % ok/cancel/help listeners
            this.Widgets.ButtonPanel.OKButton.ButtonPushedFcn = ...
                @(es,ed) cbOKButtonPushed(this);
            if ~strcmp(this.TCPeer.Type,'Looptune') % Looptune do not have apply button
                this.Widgets.ButtonPanel.ApplyButton.ButtonPushedFcn = ...
                    @(es,ed) cbApplyButtonPushed(this);
            end
            this.Widgets.ButtonPanel.CancelButton.ButtonPushedFcn = ...
                @(es,ed) cbCancelButtonPushed(this);
            this.Widgets.ButtonPanel.HelpButton.ButtonPushedFcn = ...
                @(es,ed) openHelpDialog(this);
            % add listener to open help for Overshoot Goal
            %             if strcmp(this.TCPeer.Type,'Overshoot')
            %                  this.GUIListeners.OvershootGoalPurpose = addlistener(this.Widgets.PurposeSection.label.Peer,'MousePressed',@(es,ed) localOvershootTuningGoalHelpCallback(this,es,ed));
            %             end
            
            % Listener to scroll
            if contains(this.TCPeer.Type,{'MaxLoopGain','MinLoopGain'})
                pnlOptions = this.Widgets.TuningSpecSection.Widgets.MinMaxLoopGain.pnlOptions;
            elseif ~strcmp(this.TCPeer.Type,'StableController')
                pnlOptions = this.Widgets.TuningSpecSection.Widgets.(this.TCPeer.Type).pnlOptions;
            end
           pnlOptions.CollapsedChangedFcn = @(es,ed) cbOptionsPanelCollapseChanged(this,ed);
        end

    end

    methods(Access = protected, Abstract)
        TuningGoalPanel = createTuningGoalPanel(this)
        isUpdateComplete = updateTuningGoal(this)
    end

    methods(Access = private)
        function setName(this,es)
            this.TCPeer.Name = es.Value;
        end

        function cbOKButtonPushed(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks;
            isUpdateComplete = updateTuningGoal(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
            if isUpdateComplete
                close(this);
            end
        end

        function cbApplyButtonPushed(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            updateTuningGoal(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end

        function cbCancelButtonPushed(this)
            close(this);
        end

        function openHelpDialog(this)
           helpview('control',[this.TCPeer.Type 'TuningGoalHelp']);
        end
        
        function cbOptionsPanelCollapseChanged(this,ed)
            if ~ed.Collapsed
                scroll(this.Widgets.TuningGoalPanel,'bottom');
            end
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets = this.Widgets;
        end
    end
end