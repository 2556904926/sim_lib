classdef RejectionTuningGoalGC < systuneapp.internal.dialogs.AbstractTuningGoalDialogGC  
    % Graphical component for Rejection Tuning Goal.
    
    % Copyright 2013-2021 The MathWorks, Inc.      
    
    properties(GetAccess = protected, SetAccess = protected)
        DisturbanceInputListGC
        OpeningListGC
    end    
    
    methods
        function this = RejectionTuningGoalGC(tcpeer)
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(tcpeer);
            this.Title = ...
                getString(message(['Control:systunegui:TuningGoalDialogTitle' this.TCPeer.Type]));
            this.Name = ['CSTuner_',this.TCPeer.Type];
            this.NameLabelText = getString(message('Control:systunegui:DisplayName'));
        end
        
        function updateUI(this)
            updateUI@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(this);
            updateUI(this.DisturbanceInputListGC);
            updateUI(this.OpeningListGC);
        end
        
        function delete(this)
           delete(this.DisturbanceInputListGC);
           delete(this.OpeningListGC);
           delete(this.TuningGoalSpecGC);
        end     
    end
    
    methods(Access = protected)
        function TuningGoalPanel = createTuningGoalPanel(this)
            %% Tuning Goal Panel
            TuningGoalPanel = uigridlayout('Parent',[],'RowHeight',{'fit','fit','fit'},...
                                        'ColumnWidth',{'1x'},'Padding',[0 0 10 0]);
            
            %% PurposePanel = [ PurposeLabel ]
            PurposePanel = uipanel(TuningGoalPanel);
            systuneapp.util.createTitledBorder(PurposePanel, ...
                getString(message('Control:systunegui:TuningGoalDialogPurposeLabel'))); 
            layout = uigridlayout(PurposePanel,'RowHeight',{'fit'},'ColumnWidth',{'1x'});
            PurposeLabel = uilabel(layout);
            PurposeLabel.Text = ...
                getString(message(['Control:systunegui:TuningGoalDialogPurpose' this.TCPeer.Type]));            
            PurposeLabel.WordWrap = true;
            
            %% SignalPanel
            SignalPanel = uipanel('Parent',TuningGoalPanel);
            systuneapp.util.createTitledBorder(SignalPanel,...
                getString(message(['Control:systunegui:TuningGoalDialogSignalSectionTitle',...
                this.TCPeer.DisturbanceInputListPanel.Data.Type])));
            layout = uigridlayout(SignalPanel,'RowHeight',{'fit','fit'},'ColumnWidth',{'1x'});
            
            %% DisturbanceInputListPanel
            this.DisturbanceInputListGC = this.TCPeer.DisturbanceInputListPanel;                     
            DisturbanceInputListWidget = getWidget(this.DisturbanceInputListGC);
            DisturbanceInputListWidget.Parent = layout;
            
            %% OpeningListPanel
            this.OpeningListGC = this.TCPeer.OpeningListPanel;                     
            OpeningListWidget = getWidget(this.OpeningListGC);
            OpeningListWidget.Parent = layout;
            
            %% TuningSpecPanel       
            TuningSpecWidget = getWidget(this.TuningGoalSpecGC);
            TuningSpecWidget.Parent = TuningGoalPanel;                
        end
        
        function isUpdateComplete = updateTuningGoal(this)
            isUpdateComplete = false;
            if isempty(this.TCPeer.DisturbanceInput)
                systuneapp.util.openUIAlert(this.UIFigure,...
                    getString(message(['Control:systunegui:' this.TCPeer.Type 'TuningGoalDisturbanceInputError'])));
                return;
            else
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
        end
    end
end
