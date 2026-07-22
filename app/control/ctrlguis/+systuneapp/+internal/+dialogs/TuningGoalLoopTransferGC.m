classdef TuningGoalLoopTransferGC < systuneapp.internal.dialogs.AbstractTuningGoalDialogGC 
    % Graphical component for Tuning Goals with Location and Openings
    
    % Copyright 2013-2021 The MathWorks, Inc.      
    
    properties(GetAccess = protected, SetAccess = protected)
        LoopTransferGC
    end  
    
    methods
        function this = TuningGoalLoopTransferGC(tcpeer)
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(tcpeer);
            this.Title = ...
                getString(message(['Control:systunegui:TuningGoalDialogTitle' this.TCPeer.Type]));
            this.Name = ['CSTuner_',this.TCPeer.Type];
            this.NameLabelText = getString(message('Control:systunegui:DisplayName'));
        end
        
        function delete(this)
           delete(this.LoopTransferGC);
           delete(this.TuningGoalSpecGC);
           delete(this.TCPeer);
        end
        
        function updateUI(this)
            updateUI@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(this);
            updateUI(this.LoopTransferGC);
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
            
            %% LoopTransferPanel
            LoopTransferPanel = uipanel('Parent',TuningGoalPanel);
            systuneapp.util.createTitledBorder(LoopTransferPanel,...
                getString(message(['Control:systunegui:TuningGoalDialogSignalSectionTitle' ...
                this.TCPeer.Type])));
            layout = uigridlayout(LoopTransferPanel,'RowHeight',{'fit'},'ColumnWidth',{'1x'});
            this.LoopTransferGC = createView(this.TCPeer.LoopTransferTC);
            createWidgets(this.LoopTransferGC,layout,1,1);
             
            %% TuningSpecPanel       
            TuningSpecWidget = getWidget(this.TuningGoalSpecGC);
            TuningSpecWidget.Parent = TuningGoalPanel;
        end
        
        function isUpdateComplete = updateTuningGoal(this)
            isUpdateComplete = false;
            if isempty(this.TCPeer.Location)
                systuneapp.util.openUIAlert(this.UIFigure,...
                    getString(message(['Control:systunegui:' this.TCPeer.Type 'TuningGoalLoopTransferError'])));
                return;
            else
                if ~isempty(intersect(this.TCPeer.Location,this.TCPeer.Openings))
                    systuneapp.util.openUIAlert(this.UIFigure,...
                    getString(message(['Control:systunegui:LocationOpeningOverlapError'])));
                        return;
                end
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
