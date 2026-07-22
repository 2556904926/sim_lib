classdef StepRespSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Step Response tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc

    methods
        function this = StepRespSpecGC(tcpeer)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
            this.ShowFocusWidget = false;
        end
        
        function updateUI(this)
            update(this);
        end
    end
    
    methods(Access= protected)
        function container = createContainer(this)
            %% Create base class widgets
            createWidgets(this);
            
                %% Container
                container = uigridlayout([2 1],'Parent',[],'Padding',0);
                container.RowHeight = {'fit','fit'};
            
            %% Desired response panel
            accDesiredResponse = matlab.ui.container.internal.Accordion('Parent',container);
            pnlDesiredResponse = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accDesiredResponse);
            pnlDesiredResponse.Title = getString(message('Control:systunegui:StepRespTuningGoalSpecResponse'));
            layout = uigridlayout(pnlDesiredResponse,'RowHeight',{'fit',100,'fit','fit'},...
                                    'ColumnWidth',{'fit','1x','fit'},'Padding',0);
            % specify as
            lblSpecify = uilabel(layout);
            lblSpecify.Text = getString(message('Control:systunegui:TuningGoalSpecSpecify'));
            lblSpecify.Layout.Row = 1;
            lblSpecify.Layout.Column = [1 3];
            
            % Button group with the three radio buttons
            btnGroupResponse = uibuttongroup(layout);
            btnGroupResponse.BorderType = 'none';
            btnGroupResponse.Layout.Row = 2;
            btnGroupResponse.Layout.Column = [1 3];
            
            radioFirstOrder = uiradiobutton(btnGroupResponse);
            radioFirstOrder.Text = getString(message('Control:systunegui:StepRespSpecRadioFirstOrder'));
            radioFirstOrder.Tag = 'radioFirstOrder';
            radioFirstOrder.Position = [10 65 300 25];
            
            radioSecondOrder = uiradiobutton(btnGroupResponse);
            radioSecondOrder.Text =  getString(message('Control:systunegui:StepRespSpecRadioSecondOrder'));
            radioSecondOrder.Tag = 'radioSecondOrder';
            radioSecondOrder.Position = [10 35 300 25];
            
            radioReferenceModel = uiradiobutton(btnGroupResponse);
            radioReferenceModel.Text =  getString(message('Control:systunegui:StepRespSpecRadioReferenceModel'));
            radioReferenceModel.Tag = 'radioReferenceModel';
            radioReferenceModel.Position = [10 5 300 25];
            
            % Reference LTI Model
            lblReferenceModel = uilabel(layout);
            lblReferenceModel.Text = getString(message('Control:systunegui:StepRespSpecReferenceModel'));
            lblReferenceModel.Tag = 'lblReferenceModel';
            lblReferenceModel.Layout.Row = 3;
            lblReferenceModel.Layout.Column = 1;
            txtReferenceModel = uieditfield(layout);
            txtReferenceModel.Tag = 'txtReferenceModel';
            txtReferenceModel.Layout.Row = 3;
            txtReferenceModel.Layout.Column = 2;
            
            % Time constant
            lblTau = uilabel(layout);
            lblTau.Text = getString(message('Control:systunegui:StepRespSpecTau'));
            lblTau.Tag = 'lblTau';
            lblTau.Layout.Row = 3;
            lblTau.Layout.Column = 1;
            txtTau = uieditfield(layout);
            txtTau.Tag = 'txtTau';
            txtTau.Layout.Row = 3;
            txtTau.Layout.Column = 2;
            lblTimeUnit = uilabel(layout);
            lblTimeUnit.Text = this.TCPeer.Data.CDD.getTimeUnitString;
            lblTimeUnit.Tag = 'lblTimeUnit';
            lblTimeUnit.Layout.Row = 3;
            lblTimeUnit.Layout.Column = 3;
            
            % Overshoot
            lblOS = uilabel(layout);
            lblOS.Text = getString(message('Control:systunegui:StepRespSpecOS'));
            lblOS.Tag = 'lblOS';
            lblOS.Layout.Row = 4;
            lblOS.Layout.Column = 1;
            txtOS = uieditfield(layout);
            txtOS.Tag = 'txtOS';
            txtOS.Layout.Row = 4;
            txtOS.Layout.Column = 2;
            
            %% Options Panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            optsLayout = uigridlayout(pnlOptions,[6 4]);
            optsLayout.Padding = 0;
            optsLayout.RowHeight = {'fit','fit','fit','fit'};
            optsLayout.ColumnWidth = {20,'fit','1x'};

            % Relative gap
            lblRelGap = uilabel(optsLayout);
            lblRelGap.Text = getString(message('Control:systunegui:StepRespSpecRelGap'));
            lblRelGap.Tag = 'lblRelGap';
            lblRelGap.Layout.Row = 1;
            lblRelGap.Layout.Column = [1 2];
            txtRelGap = uieditfield(optsLayout);
            txtRelGap.Tag = 'txtRelGap';
            txtRelGap.Layout.Row = 1;
            txtRelGap.Layout.Column = 3;
            
            % Scaling
            lblScaling = uilabel(optsLayout);
            lblScaling.Text = getString(message('Control:systunegui:StepRespSpecSignalScaling'));
            lblScaling.Layout.Row = 2;
            lblScaling.Layout.Column = [1 2];
            
            items = {getString(message('Control:systunegui:YesLabel')), getString(message('Control:systunegui:NoLabel'))};
            cmbYesNo = uidropdown(optsLayout,'Items',items);
            cmbYesNo.Value = getString(message('Control:systunegui:NoLabel'));
            cmbYesNo.Layout.Row = 2;
            cmbYesNo.Layout.Column = 3;
            
            lblScalingAmplitude = uilabel(optsLayout);
            lblScalingAmplitude.Text = getString(message('Control:systunegui:StepRespSpecSignalScalingAmplitude'));
            lblScalingAmplitude.Layout.Row = 3;
            lblScalingAmplitude.Layout.Column = 2;
            
            txtScalingAmplitude = uieditfield(optsLayout);
            txtScalingAmplitude.Tag = 'txtScalingAmplitude';
            txtScalingAmplitude.Layout.Row = 3;
            txtScalingAmplitude.Layout.Column = 3;
            
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = optsLayout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 4;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            
            %% store widgets for easy access
            this.Widgets.StepResp = struct(...
                'txtRelGap',                txtRelGap,...
                'lblRelGap',                lblRelGap,...
                'txtReferenceModel',        txtReferenceModel,...
                'lblReferenceModel',        lblReferenceModel,...
                'txtTau',                   txtTau,...
                'lblTau',                   lblTau,...
                'lblTimeUnit',              lblTimeUnit, ...
                'txtOS',                    txtOS,...
                'lblOS',                    lblOS,...
                'radioReferenceModel',      radioReferenceModel,...
                'radioFirstOrder',          radioFirstOrder,...
                'radioSecondOrder',         radioSecondOrder,...
                'btnGroupResponse',         btnGroupResponse,...
                'pnl',                      layout,...
                'pnlResponse',              pnlDesiredResponse,...
                'cmbYesNo',                 cmbYesNo,...
                'lblScalingAmplitude',      lblScalingAmplitude,...
                'lblScaling',               lblScaling,...
                'txtScalingAmplitude',      txtScalingAmplitude,...
                'pnlOptions',               pnlOptions,...
                'layoutOptions',            optsLayout);
        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            % GUI listeners
            this.Widgets.StepResp.txtModels.ValueChangedFcn = ...
                @(hSrc, hData)cbModelsEdit(this, this.Widgets.StepResp.txtModels.Value);
            this.Widgets.StepResp.txtReferenceModel.ValueChangedFcn = ...
                @(hSrc, hData)cbReferenceModelEdit(this, this.Widgets.StepResp.txtReferenceModel.Value);
            this.Widgets.StepResp.txtRelGap.ValueChangedFcn = ...
                @(hSrc, hData)cbRelGapEdit(this, this.Widgets.StepResp.txtRelGap.Value);
            this.Widgets.StepResp.txtTau.ValueChangedFcn = ...
                @(hSrc, hData)cbTauEdit(this, this.Widgets.StepResp.txtTau.Value);
            this.Widgets.StepResp.txtOS.ValueChangedFcn = ...
                @(hSrc, hData)cbOSEdit(this, this.Widgets.StepResp.txtOS.Value);
            this.Widgets.StepResp.btnGroupResponse.SelectionChangedFcn = ...
                @(hSrc, hData) cbResponseModelOptionSelected(this,hData);
            this.Widgets.StepResp.cmbYesNo.ValueChangedFcn = ...
                @(hSrc,hData) cbCmbYesNoChange(this);
            this.Widgets.StepResp.txtScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbScalingAmplitudeEdit(this, this.Widgets.StepResp.txtScalingAmplitude.Value);
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
           
            % Add/ remove contents of performance panel depending on radio button selection
            if strcmp(this.TCPeer.MetaData.ResponseType,'ReferenceModel')
                updateResponseWidgets(this,'radioReference');
                this.Widgets.StepResp.radioReferenceModel.Value = true;
            elseif strcmp(this.TCPeer.MetaData.ResponseType,'FirstOrder')
                updateResponseWidgets(this,'radioFirstOrder')
                this.Widgets.StepResp.radioFirstOrder.Value = true;
            elseif strcmp(this.TCPeer.MetaData.ResponseType,'SecondOrder')
                updateResponseWidgets(this,'radioSecondOrder')
                this.Widgets.StepResp.radioSecondOrder.Value = true;
            end

            % Update the text fields to the current value of TC
            this.Widgets.StepResp.txtReferenceModel.Value = Value.MetaData.ReferenceModel;
            this.Widgets.StepResp.txtRelGap.Value = mat2str(Value.Data.RelGap*100);
            this.Widgets.StepResp.txtTau.Value = mat2str(Value.MetaData.Tau);
            this.Widgets.StepResp.txtOS.Value = mat2str(Value.MetaData.OS);
            this.Widgets.StepResp.txtScalingAmplitude.Value = mat2str(Value.MetaData.InputScaling);
         
            % Update input scaling combo box
            if isempty(Value.Data.InputScaling)
                this.Widgets.StepResp.cmbYesNo.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.StepResp.cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            end
            cbCmbYesNoChange(this);
        end
    end
    
    methods (Access = private)
        function cbReferenceModelEdit(this, fieldValue)
            % Instant apply to TC when Reference Model text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % ReferenceModel cannot be empty
                    update(this);
                else
                    setReferenceModel(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                if strcmp(ME.identifier, 'Control:tuning:StepResp8')
                    systuneapp.util.openUIAlert(getParentFigure(this),message('Control:systunegui:StepRespSpecErrReferenceModel'));
                else
                    systuneapp.util.openUIAlert(getParentFigure(this), ME.message);
                end
                return;
            end
        end
           
        function cbTauEdit(this, fieldValue)
            % Instant apply to TC when Tau text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % Tau cannot be empty
                    update(this);
                else
                    setTau(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                if strcmp(ME.identifier, 'Control:tuning:StepResp8')
                    % Throw a GUI specific error message
                    systuneapp.util.openUIAlert(getParentFigure(this),message('Control:systunegui:StepRespSpecErrTau'));
                else
                    systuneapp.util.openUIAlert(getParentFigure(this), ME.message);
                end
                return;
            end
        end
        
        function cbOSEdit(this, fieldValue)
            % Instant apply to TC when OS text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % OS cannot be empty
                    update(this);
                else
                    setOS(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end
        
        function cbRelGapEdit(this, fieldValue)
            % Instant apply to TC when RelGap text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % RelGap cannot be empty
                    update(this);
                else
                    setRelGap(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end
        
        function cbResponseModelOptionSelected(this, hData)
            updateResponseWidgets(this,hData.NewValue.Tag);
            switch hData.NewValue.Tag
                case 'radioFirstOrder'
                    this.TCPeer.MetaData.ResponseType = 'FirstOrder';
                    cbTauEdit(this, this.Widgets.StepResp.txtTau.Value);
                case 'radioSecondOrder'
                    this.TCPeer.MetaData.ResponseType = 'SecondOrder';
                    cbTauEdit(this, this.Widgets.StepResp.txtTau.Value);
                    cbOSEdit(this, this.Widgets.StepResp.txtOS.Value);
                case 'radioReferenceModel'
                    this.TCPeer.MetaData.ResponseType = 'ReferenceModel';
                    cbReferenceModelEdit(this, this.Widgets.StepResp.txtReferenceModel.Value);
            end
            update(this);
            update(this.TCPeer.Data);
        end
        
        function cbScalingAmplitudeEdit(this, fieldValue)
            % Instant apply to TC when InputScaling text field changes
            try
                if nargin == 1
                    % Scaling amplitude can be empty. Account for it.
                    setScalingAmplitude(this.TCPeer);
                elseif isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);                    
                else
                    setScalingAmplitude(this.TCPeer, fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end
        
        function cbCmbYesNoChange(this)
            % update TC's InputScaling when scaling combo box changes
            switch this.Widgets.StepResp.cmbYesNo.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.StepResp.layoutOptions.RowHeight{3} = 'fit';
                    cbScalingAmplitudeEdit(this, this.Widgets.StepResp.txtScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.StepResp.layoutOptions.RowHeight{3} = 0;
                    cbScalingAmplitudeEdit(this);
            end
            update(this.TCPeer.Data);
        end
        
        function updateResponseWidgets(this,radioButtonTag)
            switch radioButtonTag
                case 'radioFirstOrder'
                    this.Widgets.StepResp.lblTau.Visible = 'on';
                    this.Widgets.StepResp.txtTau.Visible = 'on';
                    this.Widgets.StepResp.lblTimeUnit.Visible = 'on';
                    this.Widgets.StepResp.lblOS.Visible = 'off';
                    this.Widgets.StepResp.txtOS.Visible ='off';
                    this.Widgets.StepResp.lblReferenceModel.Visible = 'off';
                    this.Widgets.StepResp.txtReferenceModel.Visible = 'off';
                    this.Widgets.StepResp.pnl.RowHeight{4} = 0;
                case 'radioSecondOrder'
                    this.Widgets.StepResp.lblTau.Visible = 'on';
                    this.Widgets.StepResp.txtTau.Visible = 'on';
                    this.Widgets.StepResp.lblTimeUnit.Visible = 'on';
                    this.Widgets.StepResp.lblOS.Visible = 'on';
                    this.Widgets.StepResp.txtOS.Visible ='on';
                    this.Widgets.StepResp.lblReferenceModel.Visible = 'off';
                    this.Widgets.StepResp.txtReferenceModel.Visible = 'off';
                    this.Widgets.StepResp.pnl.RowHeight{4} = 'fit';
                case 'radioReferenceModel'
                    this.Widgets.StepResp.lblTau.Visible = 'off';
                    this.Widgets.StepResp.txtTau.Visible = 'off';
                    this.Widgets.StepResp.lblTimeUnit.Visible = 'off';
                    this.Widgets.StepResp.lblOS.Visible = 'off';
                    this.Widgets.StepResp.txtOS.Visible ='off';
                    this.Widgets.StepResp.lblReferenceModel.Visible = 'on';
                    this.Widgets.StepResp.txtReferenceModel.Visible = 'on';
                    this.Widgets.StepResp.pnl.RowHeight{4} = 0;
            end
        end
    end

end
