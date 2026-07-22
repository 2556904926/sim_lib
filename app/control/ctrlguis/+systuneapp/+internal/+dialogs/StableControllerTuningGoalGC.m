classdef StableControllerTuningGoalGC < controllib.ui.internal.dialog.AbstractDialogGC  
    % Graphical component for Stable Controller Tuning Goal.
    
    % Copyright 2013-2021 The MathWorks, Inc.
    properties (Access = private)
        Widgets
        TuningGoalSpecGC
        NameLabelText = ''
    end
    
    methods
        function this = StableControllerTuningGoalGC(tcpeer)
            this = this@controllib.ui.internal.dialog.AbstractDialogGC(tcpeer);
            this.Title = ...
                getString(message(['Control:systunegui:TuningGoalDialogTitle' this.TCPeer.Type]));
            this.Name = ['CSTuner_',this.TCPeer.Type];
            this.NameLabelText = getString(message('Control:systunegui:DisplayName'));
        end
        
        function updateUI(this)
            updateUI(this.TuningGoalSpecGC);
            update(this);
        end
        
        function delete(this)
           delete(this.TuningGoalSpecGC);
        end
        
        function pack(this,varargin)
            this.Widgets.MainPanel.ColumnWidth = {400};
            pack@controllib.ui.internal.dialog.AbstractDialogGC(this,varargin{:});
            drawnow; % This is needed for adjusting to fixed width above
            this.Widgets.MainPanel.ColumnWidth = {'1x'};
        end

    end
    
    methods(Access = protected)
        function buildUI(this)
            this.UIFigure.Position(3:4) = [400 600];
            
            %% Main Panel
            MainPanel = uigridlayout(this.UIFigure,'RowHeight',{25,'1x',2,25},...
                                        'ColumnWidth',{'1x'});
            MainPanel.Padding = [10 10 10 10];
            
            %% NamePanel = [ NameLabel NameTextField ]
            NamePanel = uigridlayout(MainPanel,'RowHeight',{'fit','fit'},...
                                        'ColumnWidth',{'fit','1x'},'Padding',3);
            NameLabel = uilabel(NamePanel,...
                'Text',getString(message('Control:systunegui:StableControllerTuningGoalNameLabel')),...
                'FontWeight','bold',...
                'FontSize',12,...
                'FontName','Helvetica');
            NameTextField = uieditfield(NamePanel);     
            
            %% Inside Panel
            TuningGoalPanel = uigridlayout(MainPanel,'RowHeight',{'fit','fit'},...
                                        'ColumnWidth',{'fit','1x'},'Padding',[0 0 10 0]);
            TuningGoalPanel.Layout.Row = 2;
            TuningGoalPanel.Layout.Column = 1;
            TuningGoalPanel.Scrollable = true;
            
            %% TunableElementPanel = [TunableElementLabel TunableElementComboBox]
            % create TunableElementLabel and TunableElementComboBox
            TunableElementLabel = uilabel(TuningGoalPanel,'Text',...
                getString(message('Control:systunegui:StableControllerTuningGoalSelectControllerLabel')));
            TunableElementLabel.Layout.Row = 1;
            TunableElementLabel.Layout.Column = 1;
            TunableElementComboBox = createTunableElementComboBox(this,TuningGoalPanel);
            TunableElementComboBox.Layout.Row = 1;
            TunableElementComboBox.Layout.Column = 2;
                        
            %% TuningSpecPanel        
            this.TuningGoalSpecGC = createView(this.TCPeer.TuningGoalSpecTC);            
            % add to panel
            TuningSpecWidget = getWidget(this.TuningGoalSpecGC);
            TuningSpecWidget.Parent = TuningGoalPanel;
            TuningSpecWidget.Layout.Row = 2;
            TuningSpecWidget.Layout.Column = [1 2];
            
            %% Button Panel
            ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                    MainPanel,["help" "ok" "apply" "cancel"]);
            widget = getWidget(ButtonPanel);
            widget.Layout.Row = 4;
            widget.Layout.Column = 1;
            widget.Padding = 0;
            widget.Scrollable = false;
            
            %% Add to widgets 
            this.Widgets.MainPanel = MainPanel;  
            this.Widgets.NameSection.label = NameLabel;
            this.Widgets.NameSection.textfield = NameTextField;
            this.Widgets.NameSection.panel = NamePanel;
            this.Widgets.TuningGoalPanel = TuningGoalPanel;
            this.Widgets.TunableElementSection.combobox = TunableElementComboBox;    
            this.Widgets.TunableElementSection.label = TunableElementLabel;              
            this.Widgets.TuningSpecSection = this.TuningGoalSpecGC;
            this.Widgets.ButtonPanel = ButtonPanel;
        end
        
        function connectUI(this)
            % name and close listeners
            this.Widgets.NameSection.textfield.ValueChangedFcn = @(es,ed) setName(this,es);     
            
            % ok/cancel/help listeners
            this.Widgets.ButtonPanel.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.Widgets.ButtonPanel.ApplyButton.ButtonPushedFcn = ...
                @(es,ed) cbApplyButtonPushed(this);
            this.Widgets.ButtonPanel.CancelButton.ButtonPushedFcn = ...
                @(es,ed) cbCancelButtonPushed(this);
            this.Widgets.ButtonPanel.HelpButton.ButtonPushedFcn = ...
                @(es,ed) openHelpDialog(this);
        end
        
        function openHelpDialog(this)
            helpview('control',[this.TCPeer.Type 'TuningGoalHelp']);
        end         
        function update(this)           
            this.Widgets.NameSection.textfield.Value = this.TCPeer.Name;
        end  

        function setName(this,es)
            this.TCPeer.Name = es.Value;
        end    
        function isUpdateComplete = updateTuningGoal(this)
            isUpdateComplete = false;
            try
                TuningGoalNames = this.TCPeer.CDD.getTuningGoalName;
                if ~this.TCPeer.Create
                    TuningGoalNames = setdiff(TuningGoalNames,this.TCPeer.TuningGoalWrapper.TuningGoal.Name);
                end
                if any(strcmp(TuningGoalNames,this.TCPeer.Name))
                    error(message('Control:systunegui:TuningGoalNameConflict',this.TCPeer.Name));
                else
                    this.TCPeer.Block = this.Widgets.TunableElementSection.combobox.Value;
                    setTuningGoal(this.TCPeer)
                    this.TCPeer.TuningGoalWrapper.Editor.TC = this.TCPeer;
                    this.TCPeer.TuningGoalWrapper.Editor.GC = this;
                end
                isUpdateComplete = true;
            catch ME
                systuneapp.util.openUIAlert(this.UIFigure,ME.message);
            end
        end
    end
    
    methods (Access = private)
        function TunableElementComboBox = createTunableElementComboBox(this,parent)
           TB = this.TCPeer.CDD.getTunableBlock;
           TunableBlockList = {TB.BlockPath}';
           TunableElementComboBox = uidropdown(parent,'Items',TunableBlockList);
           if ~isempty(this.TCPeer.Block)
              [~,ListIndex] = systuneapp.util.findItemIndexInList({this.TCPeer.Block},TunableBlockList);
              if any(ListIndex) % set to the selected tunable element
                 TunableElementComboBox.Value = TunableBlockList{ListIndex};
              else % this tunable element is removed
                 this.TCPeer.Block='';
              end
           end
        end
        
        function cbOKButtonPushed(this)
            isUpdateComplete = updateTuningGoal(this); 
            if isUpdateComplete
                close(this);
            end
        end
        
        function cbApplyButtonPushed(this)
            updateTuningGoal(this);
        end
        
        function cbCancelButtonPushed(this)
            close(this);
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets = this.Widgets;
        end
    end
end
