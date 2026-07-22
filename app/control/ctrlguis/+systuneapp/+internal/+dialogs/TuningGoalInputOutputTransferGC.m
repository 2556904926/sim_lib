classdef TuningGoalInputOutputTransferGC < systuneapp.internal.dialogs.AbstractTuningGoalDialogGC
    % Graphical component for Tuning Goals with Input, Output and Openings   
    
    % Copyright 2013-2021 The MathWorks, Inc.    
    
    properties(GetAccess = protected, SetAccess = protected)
        IOTransferGC
    end    
    
    methods
        function this = TuningGoalInputOutputTransferGC(tcpeer)
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(tcpeer);
            this.Title = ...
                getString(message(['Control:systunegui:TuningGoalDialogTitle' this.TCPeer.Type]));
            this.Name = ['CSTuner_',this.TCPeer.Type];
            this.NameLabelText = getString(message('Control:systunegui:DisplayName'));
        end
        
        function delete(this)
            delete(this.IOTransferGC);
            delete(this.TuningGoalSpecGC);
            delete(this.TCPeer);
        end
        
        function updateUI(this)
            updateUI@systuneapp.internal.dialogs.AbstractTuningGoalDialogGC(this);
            updateUI(this.IOTransferGC);
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
            
            %% IOTransferPanel
            IOTransferPanel = uipanel('Parent',TuningGoalPanel);
            systuneapp.util.createTitledBorder(IOTransferPanel,...
                getString(message(['Control:systunegui:TuningGoalDialogSignalSectionTitle' ...
                this.TCPeer.Type])));
            layout = uigridlayout(IOTransferPanel,'RowHeight',{'fit'},'ColumnWidth',{'1x'});
            this.IOTransferGC = createView(this.TCPeer.IOTransferTC);
            createWidgets(this.IOTransferGC,layout,1,1);

            %% TuningSpecPanel
            TuningSpecWidget = getWidget(this.TuningGoalSpecGC);
            TuningSpecWidget.Parent = TuningGoalPanel;
        end
        
%         function connectUI(this)
%             % name and close listeners
%             this.Widgets.NameSection.textfield.ValueChangedFcn = ...
%                 @(es,ed) setName(this,es);
%             
%             % ok/cancel/help listeners
%             this.Widgets.ButtonPanel.OKButton.ButtonPushedFcn = ...
%                 @(es,ed) cbOKButtonPushed(this);
%             if ~strcmp(this.TCPeer.Type,'Looptune') % Looptune do not have apply button
%                 this.Widgets.ButtonPanel.ApplyButton.ButtonPushedFcn = ...
%                 @(es,ed) cbApplyButtonPushed(this);
%             end
%             this.Widgets.ButtonPanel.CancelButton.ButtonPushedFcn = ...
%                 @(es,ed) cbCancelButtonPushed(this); 
%             this.Widgets.ButtonPanel.HelpButton.ButtonPushedFcn = ...
%                 @(es,ed) openHelpDialog(this);
%             % add listener to open help for Overshoot Goal
% %             if strcmp(this.TCPeer.Type,'Overshoot') 
% %                  this.GUIListeners.OvershootGoalPurpose = addlistener(this.Widgets.PurposeSection.label.Peer,'MousePressed',@(es,ed) localOvershootTuningGoalHelpCallback(this,es,ed));
% %             end            
%         end
        
%         function openHelpDialog(this)
%             cstunerhelp([this.TCPeer.Type 'TuningGoalHelp'],false);
%         end
%         function setName(this,es)
%             this.TCPeer.Name = es.Value;
%         end             
        function isUpdateComplete = updateTuningGoal(this)
            isUpdateComplete = false;
            if isempty(this.TCPeer.Input) || isempty(this.TCPeer.Output)                
                systuneapp.util.openUIAlert(this.UIFigure,...
                    getString(message(['Control:systunegui:' this.TCPeer.Type 'TuningGoalIOTransferError']))); 
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
                        for ct=1:length(this.TCPeer.TuningGoalWrapper)
                            this.TCPeer.TuningGoalWrapper(ct).Editor.TC = this.TCPeer;
                            this.TCPeer.TuningGoalWrapper(ct).Editor.GC = this;
                        end
                    end
                    isUpdateComplete = true;
                catch ME
                    systuneapp.util.openUIAlert(this.UIFigure,ME.message);
                end
            end
        end      

        
%         function cbOKButtonPushed(this)
%             isUpdateComplete = updateTuningGoal(this); 
%             if isUpdateComplete
%                 close(this);
%             end
%         end
%         
%         function cbApplyButtonPushed(this)
%             updateTuningGoal(this);
%         end
%         
%         function cbCancelButtonPushed(this)
%             close(this);
%         end
    end
    
    
end

