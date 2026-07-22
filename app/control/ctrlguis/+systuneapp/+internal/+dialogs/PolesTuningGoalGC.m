classdef PolesTuningGoalGC < systuneapp.internal.dialogs.AbstractTuningGoalDialogGC
    % Graphical component for Poles Tuning Goal.
    
    % Copyright 2013-2021 The MathWorks, Inc.      
    
    properties(GetAccess = protected, SetAccess = protected)
        LocationListGC
        OpeningListGC 
    end    

    methods
        function this = PolesTuningGoalGC(tcpeer)
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(tcpeer);
            this.Title = ...
                getString(message(['Control:systunegui:TuningGoalDialogTitle' this.TCPeer.Type]));
            this.Name = ['CSTuner_',this.TCPeer.Type];
            this.NameLabelText = getString(message('Control:systunegui:DisplayName'));
        end
        
        function delete(this)
           delete(this.LocationListGC);
           delete(this.OpeningListGC);
           delete(this.TuningGoalSpecGC);
        end             

        function updateUI(this)
            updateUI@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(this);
            updateUI(this.LocationListGC);
            updateUI(this.OpeningListGC);
        end
    end
    
    methods(Access = protected)
        function TuningGoalPanel = createTuningGoalPanel(this)
            %% Tuning Goal Panel
            TuningGoalPanel = uigridlayout('Parent',[],'RowHeight',{'fit','fit','fit','fit'},...
                                        'ColumnWidth',{'1x'},'Padding',[0 0 10 0]);

            %% PurposePanel = [ PurposeLabel ]
            PurposePanel = uipanel(TuningGoalPanel);
            systuneapp.util.createTitledBorder(PurposePanel, ...
                getString(message('Control:systunegui:TuningGoalDialogPurposeLabel'))); 
            layout = uigridlayout(PurposePanel,'RowHeight',{'fit'},'ColumnWidth',{'1x'});
            PurposeLabel = uilabel(layout);
            PurposeLabel.Text = getString(message(['Control:systunegui:TuningGoalDialogPurpose' ...
                this.TCPeer.Type]));            
            PurposeLabel.WordWrap = true;
            
            %% Feedback Configuration Panel
            SignalPanel = uipanel('Parent',TuningGoalPanel);
            systuneapp.util.createTitledBorder(SignalPanel,...
                 getString(message(['Control:systunegui:TuningGoalDialogSignalSectionTitle'...
                 this.TCPeer.Type])))
            SignalLayout = uigridlayout(SignalPanel,'RowHeight',{'fit',60,'fit','fit'},...
                            'ColumnWidth',{'1x'});
            % Label
            SignalPanelLabel = uilabel(SignalLayout,"Text",...
                getString(message('Control:systunegui:PolesTuningGoalComputePoles')));
            SignalPanelLabel.Layout.Row = 1;
            SignalPanelLabel.Layout.Column = 1;
            % System Radio buttons
            SystemRadioButtonGroup = uibuttongroup(SignalLayout);
            SystemRadioButtonGroup.Layout.Row = 2;
            SystemRadioButtonGroup.Layout.Column = 1;
            SystemRadioButtonGroup.BorderType = 'none';
            EntireModelRadioButton = uiradiobutton(SystemRadioButtonGroup,"Text",...
                getString(message('Control:systunegui:PolesTuningGoalEntireModel')));
            EntireModelRadioButton.Tag = "EntireSystem";
            EntireModelRadioButton.Position = [10 35 165 25];
            FeedbackLoopRadioButton = uiradiobutton(SystemRadioButtonGroup,"Text",...
                getString(message('Control:systunegui:PolesTuningGoalFeedbackLoop')));
            FeedbackLoopRadioButton.Tag = "FeedbackLoop";
            FeedbackLoopRadioButton.Position = [10 5 165 25];
            % Location List Panel
            this.LocationListGC = this.TCPeer.LocationListTC;
            LocationListWidget = getWidget(this.LocationListGC);
            LocationListWidget.Parent = SignalLayout;
            LocationListWidget.Layout.Row = 3;
            LocationListWidget.Layout.Column = 1;
            % Opening List Panel
            this.OpeningListGC = this.TCPeer.OpeningListTC;
            OpeningListWidget = getWidget(this.OpeningListGC);
            OpeningListWidget.Parent = SignalLayout;
            OpeningListWidget.Layout.Row = 4;
            OpeningListWidget.Layout.Column = 1;
            
            %% TuningSpecPanel       
            TuningSpecWidget = getWidget(this.TuningGoalSpecGC);
            TuningSpecWidget.Parent = TuningGoalPanel;
            
            %% Add to widgets
            this.Widgets.SignalPanel = SignalPanel; 
            this.Widgets.SignalPanelLabel = SignalPanelLabel;
            this.Widgets.SignalLayout = SignalLayout;
            this.Widgets.radiobutton.EntireModel = EntireModelRadioButton;
            this.Widgets.radiobutton.FeedbackLoop = FeedbackLoopRadioButton;
            this.Widgets.radiobutton.SystemRadioButtonGroup = SystemRadioButtonGroup;
            this.Widgets.PurposeSection.panel = PurposePanel;              
            this.Widgets.PurposeSection.label = PurposeLabel; 
            this.Widgets.LocationListSection = this.LocationListGC;  
            this.Widgets.OpeningSection = this.OpeningListGC;  
        end
        
        function connectUI(this)
            connectUI@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(this);
           % Radio Button
           this.Widgets.radiobutton.SystemRadioButtonGroup.SelectionChangedFcn = ...
               @(es,ed) cbSystemChanged(this,ed);
        end

        function cbSystemChanged(this,ed)
            switch ed.NewValue.Tag
                case 'EntireSystem'
                    removeLocationListPanel(this);
                    this.TCPeer.LocationInLocationList = this.TCPeer.Location;
                    this.TCPeer.Location = {};
                case 'FeedbackLoop'
                    addLocationListPanel(this);
                    this.TCPeer.Location = this.TCPeer.LocationInLocationList;
            end
        end

        function addLocationListPanel(this)
            this.Widgets.SignalLayout.RowHeight{3} = 'fit';    
        end
        
        function removeLocationListPanel(this)
            this.Widgets.SignalLayout.RowHeight{3} = 0;
        end      
        
        function isUpdateComplete = updateTuningGoal(this,es)            
            isUpdateComplete = false;
            try
                TuningGoalNames = this.TCPeer.CDD.getTuningGoalName;
                if ~this.TCPeer.Create
                    TuningGoalNames = setdiff(TuningGoalNames,this.TCPeer.TuningGoalWrapper.TuningGoal.Name);
                end
                if any(strcmp(TuningGoalNames,this.TCPeer.Name))
                    error(message('Control:systunegui:TuningGoalNameConflict',this.TCPeer.Name));
                else  
                    setTuningGoal(this.TCPeer);
                    this.TCPeer.TuningGoalWrapper.Editor.TC = this.TCPeer;
                    this.TCPeer.TuningGoalWrapper.Editor.GC = this;
                end
                isUpdateComplete = true;
            catch ME
                systuneapp.util.openUIAlert(this.UIFigure,ME.message);  
            end            
        end
        
        function update(this)
            update@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(this);
            if isempty(this.TCPeer.Location)
                this.Widgets.radiobutton.EntireModel.Value = true;
                removeLocationListPanel(this);
            else
                this.Widgets.radiobutton.EntireModel.Value = false;
                addLocationListPanel(this);
            end
        end  
    end
end
