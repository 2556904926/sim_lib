classdef MultiModelDialog < controllib.ui.internal.dialog.AbstractDialog
    % Abstract dialog class for architecture edit dialogs
    
    % Copyright 2015 The MathWorks, Inc.
    
    properties (Access = protected)
        % Data properties
        Architecture
        Preferences
        
        % Widgets
        Widgets
        
        % Store handle to Import Dialogs
        ImportDlgHandles
        
        % Listeners to block changed events
        BlockListeners
        
        % Event manager
        EventManager
    end
    
    methods (Access = public)
        %% Constructor
        function this = MultiModelDialog(Architecture,Preferences)
            % Superclass constructor
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            
            % Validate input
            if nargin == 2 && isa(Architecture, 'ctrlguis.csdesignerapp.data.architectures.internal.AbstractArchitecture')
                % Set data
                this.Architecture = Architecture;
                this.Preferences = Preferences;
                % Dialog Title
                this.Title = getString(message('Control:compDesignTask:strMultiModelDialogTitle'));
            else
                error(message('Controllib:general:UnexpectedError', ...
                    'Input must be an AbstractArchitecture'));
            end
            % Create data listeners
            createDataListeners(this);
        end
        function updateUI(this)
            disableUIListeners(this);
            System = ss(getCL(this.Architecture));
            NumSys = size(System,3)*size(System,4);
            Items = arrayfun(@(x)num2str(x),1:NumSys,'UniformOutput',false);
            this.Widgets.cmbNominalModel.Items = Items;
            this.Widgets.cmbNominalModel.Value = num2str(getNominalIndex(this.Architecture));
            enableUIListeners(this);
        end
        function setEventManager(this,EventManager)
            this.EventManager = EventManager;
        end
    end
    methods (Access = protected)
        %% Data listeners
        function createDataListeners(this)
            % Update dialog contents when data changes
            LNominalIdx  = addlistener(this.Architecture, 'SystemChanged', @(es,ed)updateUI(this));
            % Delete dialog when data is no longer valid
            LDelete = addlistener(this.Architecture, 'ObjectBeingDestroyed', @(es,ed)delete(this));
            % Register the data listeners
            registerDataListeners(this,[LNominalIdx; LDelete]);
        end
        %% Panel
        function buildUI(this)
            fontSize = 12;
            
            glUIFigure = uigridlayout(this.UIFigure);
            glUIFigure.RowHeight = {60,'fit',60};
            glUIFigure.ColumnWidth = {'1x'};
            
            % Nominal Model Selection Panel
            pnlNominalModelSelection = uipanel(glUIFigure);
            pnlNominalModelSelection.Title = getString(message(...
                'Control:compDesignTask:strMultiModelNominalPanelTitle'));
            pnlNominalModelSelection.FontSize = fontSize;
            pnlNominalModelSelection.BorderType = 'none';
            pnlNominalModelSelection.FontWeight = 'bold';
            glNominalModelSelection = uigridlayout(pnlNominalModelSelection);
            glNominalModelSelection.ColumnWidth = {'fit','1x'};
            glNominalModelSelection.RowHeight = {'fit'};
            lblNominalModel = uilabel(glNominalModelSelection);
            lblNominalModel.Text = getString(message(...
                'Control:compDesignTask:strMultiModelNominalPanelLabel'));
            lblNominalModel.FontSize = fontSize;
            cmbNominalModel = uidropdown(glNominalModelSelection);
            
            % Frequency Grid Panel
            pnlFrequency = uipanel(glUIFigure);
            pnlFrequency.Title = getString(message(...
                'Control:compDesignTask:strMultiModelFreqPanelTitle'));
            pnlFrequency.FontSize = fontSize;
            pnlFrequency.BorderType = 'none';
            pnlFrequency.FontWeight = 'bold';
            glFrequency = uigridlayout(pnlFrequency);
            glFrequency.Padding = [0 10 10 0];
            glFrequency.RowHeight = {22,22,'fit'};
            glFrequency.ColumnWidth = {210,'1x',50};
            radioGrp = uibuttongroup(glFrequency);
            radioGrp.Layout.Row = [1 2];
            radioGrp.Layout.Column = 1;
            radioGrp.BorderType = 'none';
            radioAuto = uiradiobutton(radioGrp);
            radioAuto.Position(2) = 25;
            radioAuto.Position(3) = radioGrp.Position(3);
            radioAuto.Text = getString(message(...
                'Control:compDesignTask:strMultiModelFreqPanelLabel1'));
            radioAuto.FontSize = fontSize;
            radioAuto.Tag = 'auto';
            radioUser = uiradiobutton(radioGrp);
            radioUser.Position(2) = 0;
            radioUser.Position(3) = radioGrp.Position(3);
            radioUser.Text = getString(message(...
                'Control:compDesignTask:strMultiModelFreqPanelLabel2'));
            radioUser.FontSize = fontSize;
            radioUser.Tag = 'manual';
            txtFrequency = uieditfield(glFrequency);
            txtFrequency.Layout.Row = 2;
            txtFrequency.Layout.Column = [2 3];
            txtFrequency.FontSize = fontSize;
            txtFrequency.Value = 'logspace(-2,2,300)';
            txtFrequency.Enable = false;
            
            % Buttons Panel
            pnlButton = uipanel(glUIFigure);
            pnlButton.Layout.Row = 3;
            pnlButton.Layout.Column = 1;
            pnlButton.BorderType = 'none';
            glButtons = uigridlayout(pnlButton);
            glButtons.Padding = [0 0 0 0];
            glButtons.ColumnWidth = {60,'1x',60,60};
            BtnHelp = uibutton(glButtons);
            BtnHelp.Layout.Column = 1;
            BtnHelp.Text = getString(message('Control:designerapp:strHelp'));
            BtnHelp.FontSize = fontSize;
            BtnOK = uibutton(glButtons);
            BtnOK.Layout.Column = 3;
            BtnOK.Text = getString(message('Control:compDesignTask:strApply'));
            BtnOK.FontSize = fontSize;
            BtnClose = uibutton(glButtons);
            BtnClose.Layout.Column = 4;
            BtnClose.Text = getString(message('Control:compDesignTask:strClose'));
            BtnClose.FontSize = fontSize;
            

            this.Widgets.pnlNominalModelSelection = pnlNominalModelSelection;
            this.Widgets.lblNominalModel = lblNominalModel;
            this.Widgets.cmbNominalModel = cmbNominalModel;
            this.Widgets.pnlFrequency = pnlFrequency;
            this.Widgets.radioAuto = radioAuto;
            this.Widgets.radioUser = radioUser;
            this.Widgets.radioGrp = radioGrp;
            this.Widgets.txtFrequency = txtFrequency;
            this.Widgets.pnlButton = pnlButton;
            this.Widgets.BtnOK = BtnOK;
            this.Widgets.BtnCancel = BtnClose;
            this.Widgets.BtnHelp = BtnHelp;
            
            L1 = addlistener(BtnOK, 'ButtonPushed', @(es,ed)callbackApply(this));
            registerUIListeners(this,L1);

            L2(1) = addlistener(BtnClose, 'ButtonPushed', @(es,ed)close(this.getWidget));
            L2(2) = addlistener(BtnHelp, 'ButtonPushed', @(es,ed)cbHelpClicked(this));
            registerUIListeners(this, L2);

            System = ss(getCL(this.Architecture));
            NumSys = size(System,3);
            Items = arrayfun(@(x)num2str(x),1:NumSys,'UniformOutput',false);
            this.Widgets.cmbNominalModel.Items = Items;
            this.Widgets.cmbNominalModel.Value = num2str(getNominalIndex(this.Architecture));
            this.Widgets.txtFrequency.Value = this.Preferences.MultiModelFrequencySelectionData.UserModeString;
            if this.Preferences.MultiModelFrequencySelectionData.UseAutoMode
                this.Widgets.radioAuto.Value = true;
                this.Widgets.txtFrequency.Enable = false;
            else
                this.Widgets.radioUser.Value = true;
                this.Widgets.txtFrequency.Text.Enable = true;
            end
            
            L(1) = addlistener(txtFrequency,'ValueChanged',@(es,ed)setFrequencyData(this,es));
            this.Widgets.radioGrp.SelectionChangedFcn = @(es,ed) setFrequencyMode(this,es,ed);
            registerUIListeners(this, L);
            
            this.UIFigure.Position(3:4) = [365 210];
        end
        
        %% CALLBACKS
        function callbackApply(this)
            setNominalIndex(this);
            setMultimodelFrequency(this);
        end
        
        function setNominalIndex(this)
            this.EventManager.postActionStatus('on',getString(message('Control:designerapp:updateNominalModel')));
            Idx = evalin('base', this.Widgets.cmbNominalModel.Value);
            this.Architecture.setNominalIndex(Idx);
            this.EventManager.clearActionStatus;
        end
        
        function setFrequencyMode(this,es,ed)
            if strcmp(es.SelectedObject.Tag,'auto')
                % Auto mode selected
                this.Widgets.txtFrequency.Enable = false;
            else
                this.Widgets.txtFrequency.Enable = true;
            end
        end
        
        function setFrequencyData(this,es)
            try
                Data = evalin('base',es.Value);
            catch ME
                msg = getString(message('Control:compDesignTask:strMultiModelInvalidFreqVector'));
                title = getString(message('Control:compDesignTask:strMultiModelFreqPanelTitle'));
                uialert(this.UIFigure,msg, title);
                return
            end
            
            if isnumeric(Data) && isvector(Data) && isreal(Data) && (numel(unique(Data))>1) && all(Data>0)
            else
                msg = getString(message('Control:compDesignTask:strMultiModelInvalidFreqVector'));
                title = getString(message('Control:compDesignTask:strMultiModelFreqPanelTitle'));
                uialert(this.UIFigure,msg,title);
            end
        end
        
        function setMultimodelFrequency(this)
            try
                Data = evalin('base',this.Widgets.txtFrequency.Value);
                this.Preferences.MultiModelFrequencySelectionData.UseAutoMode = this.Widgets.radioAuto.Value;
                this.Preferences.MultiModelFrequencySelectionData.UserModeString = this.Widgets.txtFrequency.Value;
                this.Preferences.MultiModelFrequencySelectionData.UserModeData = unique(Data(:));
            catch ME
                title = getString(message('Control:compDesignTask:strMultiModelFreqPanelTitle'));
                uialert(this.UIFigure,ME.message,title);
            end
        end
        
        function cbHelpClicked(this)
            ctrlguihelp('CSD_MultiModelHelp','CSHelpWindow');
        end
    end
    methods(Hidden = true)
        function Widgets = getWidgets(this)
            Widgets = this.Widgets;
        end

        function qeSetNominalIndex(this)
            setNominalIndex(this)
        end
    end
end