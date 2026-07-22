classdef StepRejectionSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Step Response tuning goal specifications

    % Copyright 2013-2021 The MathWorks, Inc

    methods
        function this = StepRejectionSpecGC(tcpeer)
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
            accResponse = matlab.ui.container.internal.Accordion('Parent',container);
            pnlResponse = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accResponse);
            pnlResponse.Title = getString(message('Control:systunegui:StepRejectionTuningGoalSpecDesiredResponse'));
            layoutResponse = uigridlayout(pnlResponse,'RowHeight',{'fit',100,'fit','fit'},...
                'RowHeight',{'fit',60,'fit','fit','fit'},'ColumnWidth',{'fit','1x','fit'},'Padding',0);

            % specify
            lblSpecify = uilabel(layoutResponse);
            lblSpecify.Text = ...
                getString(message('Control:systunegui:StepRejectionTuningGoalSpecSpecifyUsing'));
            lblSpecify.Layout.Row = 1;
            lblSpecify.Layout.Column = [1 3];

            % Button group with the three radio buttons
            btnGroupResponse = uibuttongroup(layoutResponse);
            btnGroupResponse.BorderType = 'none';
            btnGroupResponse.Layout.Row = 2;
            btnGroupResponse.Layout.Column = [1 3];

            % Radio button response characteristics
            radioResponseCharacteristics = uiradiobutton(btnGroupResponse);
            radioResponseCharacteristics.Text =  ...
                getString(message('Control:systunegui:StepRejectionTuningGoalSpecResponseCharacteristics'));
            radioResponseCharacteristics.Tag = 'radioResponseCharacteristics';
            radioResponseCharacteristics.Position = [10 35 300 25];

            % Radio button reference model
            radioReferenceModel = uiradiobutton(btnGroupResponse);
            radioReferenceModel.Text = ...
                getString(message('Control:systunegui:StepRejectionSpecReferenceModel'));
            radioReferenceModel.Tag = 'radioReferenceModel';
            radioReferenceModel.Position = [10 5 300 25];

            % MaxAmplitude
            lblMaxAmplitude = uilabel(layoutResponse);
            lblMaxAmplitude.Text = ...
                getString(message('Control:systunegui:StepRejectionSpecMaxAmplitude'));
            lblMaxAmplitude.Tag = 'lblMaxAmplitude';
            lblMaxAmplitude.Layout.Row = 3;
            lblMaxAmplitude.Layout.Column = 1;
            txtMaxAmplitude = uieditfield(layoutResponse);
            txtMaxAmplitude.Tag = 'txtMaxAmplitude';
            txtMaxAmplitude.Layout.Row = 3;
            txtMaxAmplitude.Layout.Column = 2;

            % MaxSettingTime
            lblMaxSettlingTime = uilabel(layoutResponse);
            lblMaxSettlingTime.Text = ...
                getString(message('Control:systunegui:StepRejectionSpecMaxSettlingTime'));
            lblMaxSettlingTime.Tag = 'lblMaxSettlingTime';
            lblMaxSettlingTime.Layout.Row = 4;
            lblMaxSettlingTime.Layout.Column = 1;
            txtMaxSettlingTime = uieditfield(layoutResponse);
            txtMaxSettlingTime.Tag = 'txtMaxSettlingTime';
            txtMaxSettlingTime.Layout.Row = 4;
            txtMaxSettlingTime.Layout.Column = 2;
            lblTimeUnit = uilabel(layoutResponse);
            lblTimeUnit.Text = this.TCPeer.Data.CDD.getTimeUnitString;
            lblTimeUnit.Tag = 'lblTimeUnit';
            lblTimeUnit.Layout.Row = 4;
            lblTimeUnit.Layout.Column = 3;

            % MinDamping
            lblMinDamping = uilabel(layoutResponse);
            lblMinDamping.Text = ...
                getString(message('Control:systunegui:StepRejectionSpecMinDamping'));
            lblMinDamping.Tag = 'lblMinDamping';
            lblMinDamping.Layout.Row = 5;
            lblMinDamping.Layout.Column = 1;
            txtMinDamping = uieditfield(layoutResponse);
            txtMinDamping.Tag = 'txtMinDamping';
            txtMinDamping.Layout.Row = 5;
            txtMinDamping.Layout.Column = 2;

            % Reference LTI Model
            lblReferenceModel = uilabel(layoutResponse);
            lblReferenceModel.Text = getString(message('Control:systunegui:StepRejectionSpecReferenceModel'));
            lblReferenceModel.Tag = 'lblReferenceModel';
            lblReferenceModel.Layout.Row = 3;
            lblReferenceModel.Layout.Column = 1;
            txtReferenceModel = uieditfield(layoutResponse);
            txtReferenceModel.Tag = 'txtReferenceModel';
            txtReferenceModel.Layout.Row = 3;
            txtReferenceModel.Layout.Column = [2 3];

            %% Options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layoutOptions = uigridlayout(pnlOptions,[5 4]);
            layoutOptions.Padding = 0;
            layoutOptions.RowHeight = {'fit','fit','fit','fit','fit'};
            layoutOptions.ColumnWidth = {20,'fit','1x'};

            % InputScaling
            lblInputScaling = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:StepRejectionSpecInputSignalScaling')));
            lblInputScaling.Layout.Row = 1;
            lblInputScaling.Layout.Column = [1 2];
            lblInputScalingAmplitude = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:StepRejectionSpecSignalInputScalingAmplitude')));
            lblInputScalingAmplitude.Layout.Row = 2;
            lblInputScalingAmplitude.Layout.Column = 2;
            txtInputScalingAmplitude = uieditfield(layoutOptions);
            txtInputScalingAmplitude.Tag = 'txtInputScalingAmplitude';
            txtInputScalingAmplitude.Layout.Row = 2;
            txtInputScalingAmplitude.Layout.Column = 3;

            Items = {  getString(message('Control:systunegui:YesLabel')), ...
                getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoInput = uidropdown(layoutOptions,'Items',Items);
            cmbYesNoInput.Value = getString(message('Control:systunegui:NoLabel'));
            cmbYesNoInput.Layout.Row = 1;
            cmbYesNoInput.Layout.Column = 3;

            % OutputScaling
            lblOutputScaling = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:StepRejectionSpecOutputSignalScaling')));
            lblOutputScaling.Layout.Row = 3;
            lblOutputScaling.Layout.Column = [1 2];
            lblOutputScalingAmplitude = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:StepRejectionSpecSignalOutputScalingAmplitude')));
            lblOutputScalingAmplitude.Layout.Row = 4;
            lblOutputScalingAmplitude.Layout.Column = 2;
            txtOutputScalingAmplitude = uieditfield(layoutOptions);
            txtOutputScalingAmplitude.Tag = 'txtOutputScalingAmplitude';
            txtOutputScalingAmplitude.Layout.Row = 4;
            txtOutputScalingAmplitude.Layout.Column = 3;
            cmbYesNoOutput = uidropdown(layoutOptions,'Items',Items);
            cmbYesNoOutput.Value = getString(message('Control:systunegui:NoLabel'));
            cmbYesNoOutput.Layout.Row = 3;
            cmbYesNoOutput.Layout.Column = 3;

            % Models
            this.Widgets.Advanced.pnlRadio.Parent = layoutOptions;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 5;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];

            %% store widgets for easy access
            this.Widgets.StepRejection = struct(...
                'lblReferenceModel',        lblReferenceModel,...
                'txtReferenceModel',        txtReferenceModel,...
                'lblMaxAmplitude',          lblMaxAmplitude,...
                'txtMaxAmplitude',          txtMaxAmplitude,...
                'lblMaxSettlingTime',       lblMaxSettlingTime,...
                'txtMaxSettlingTime',       txtMaxSettlingTime,...
                'lblTimeUnit',              lblTimeUnit,...
                'lblMinDamping',            lblMinDamping,...
                'txtMinDamping',            txtMinDamping,...
                'radioResponseCharacteristics',radioResponseCharacteristics,...
                'radioReferenceModel',      radioReferenceModel,...
                'btnGroupResponse',         btnGroupResponse,...
                'lblSpecify',               lblSpecify,...
                'pnlResponse',              pnlResponse,...
                'layoutResponse',           layoutResponse,...
                'cmbYesNoInput',            cmbYesNoInput,...
                'cmbYesNoOutput',           cmbYesNoOutput,...
                'txtInputScalingAmplitude', txtInputScalingAmplitude, ...
                'txtOutputScalingAmplitude',txtOutputScalingAmplitude, ...
                'lblInputScaling',          lblInputScaling,...
                'lblOutputScaling',         lblOutputScaling,...
                'lblInputScalingAmplitude', lblInputScalingAmplitude,...
                'lblOutputScalingAmplitude',lblOutputScalingAmplitude,...
                'pnl',                      container,...
                'pnlOptions',               pnlOptions,...
                'layoutOptions',            layoutOptions);
        end

        function connectUI(this)
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            % GUI listeners
            this.Widgets.StepRejection.txtModels.ValueChangedFcn = ...
                @(hSrc, hData)cbModelsEdit(this, this.Widgets.StepRejection.txtModels.Value);
            this.Widgets.StepRejection.txtReferenceModel.ValueChangedFcn = ...
                @(hSrc, hData)cbReferenceModelEdit(this, this.Widgets.StepRejection.txtReferenceModel.Value);
            this.Widgets.StepRejection.txtMaxAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbMaxAmplitudeEdit(this, this.Widgets.StepRejection.txtMaxAmplitude.Value);
            this.Widgets.StepRejection.txtMaxSettlingTime.ValueChangedFcn = ...
                @(hSrc, hData)cbMaxSettlingTimeEdit(this, this.Widgets.StepRejection.txtMaxSettlingTime.Value);
            this.Widgets.StepRejection.txtMinDamping.ValueChangedFcn = ...
                @(hSrc, hData)cbMinDampingEdit(this, this.Widgets.StepRejection.txtMinDamping.Value);
            this.Widgets.StepRejection.btnGroupResponse.SelectionChangedFcn = ...
                @(hSrc, hData) cbResponseOptionSelected(this,hData);
            this.Widgets.StepRejection.cmbYesNoInput.ValueChangedFcn = ...
                @(hSrc,hData) cbcmbYesNoInputChange(this);
            this.Widgets.StepRejection.txtInputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbInputScalingAmplitudeEdit(this, this.Widgets.StepRejection.txtInputScalingAmplitude.Value);
            this.Widgets.StepRejection.cmbYesNoOutput.ValueChangedFcn = ...
                @(hSrc,hData) cbcmbYesNoOutputChange(this);
            this.Widgets.StepRejection.txtOutputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbOutputScalingAmplitudeEdit(this, this.Widgets.StepRejection.txtOutputScalingAmplitude.Value);
        end

        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);

            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);

            % Add/ remove contents of performance panel depending on radio button selection
            if strcmp(this.TCPeer.MetaData.ResponseType,'ReferenceModel')
                this.Widgets.StepRejection.lblReferenceModel.Visible = 'on';
                this.Widgets.StepRejection.txtReferenceModel.Visible = 'on';
                this.Widgets.StepRejection.lblMaxAmplitude.Visible = 'off';
                this.Widgets.StepRejection.txtMaxAmplitude.Visible = 'off';
                this.Widgets.StepRejection.lblTimeUnit.Visible = 'off';
                this.Widgets.StepRejection.lblMinDamping.Visible = 'off';
                this.Widgets.StepRejection.txtMinDamping.Visible = 'off';
                this.Widgets.StepRejection.layoutResponse.RowHeight(4:5) = {0,0};
                this.Widgets.StepRejection.radioReferenceModel.Value = true;
            elseif strcmp(this.TCPeer.MetaData.ResponseType,'ResponseCharacteristics')
                this.Widgets.StepRejection.lblReferenceModel.Visible = 'off';
                this.Widgets.StepRejection.txtReferenceModel.Visible = 'off';
                this.Widgets.StepRejection.lblMaxAmplitude.Visible = 'on';
                this.Widgets.StepRejection.txtMaxAmplitude.Visible = 'on';
                this.Widgets.StepRejection.lblTimeUnit.Visible = 'on';
                this.Widgets.StepRejection.lblMinDamping.Visible = 'on';
                this.Widgets.StepRejection.txtMinDamping.Visible = 'on';
                this.Widgets.StepRejection.layoutResponse.RowHeight(4:5) = {'fit','fit'};
                this.Widgets.StepRejection.radioResponseCharacteristics.Value = true;
            end

            % Update the text fields to the current value of TC
            this.Widgets.StepRejection.txtReferenceModel.Value = Value.MetaData.ReferenceModel;
            this.Widgets.StepRejection.txtMaxAmplitude.Value = mat2str(Value.MetaData.MaxAmplitude);
            this.Widgets.StepRejection.txtMaxSettlingTime.Value = mat2str(Value.MetaData.MaxSettlingTime);
            this.Widgets.StepRejection.txtMinDamping.Value = mat2str(Value.MetaData.MinDamping);
            this.Widgets.StepRejection.txtInputScalingAmplitude.Value = mat2str(Value.MetaData.InputScaling);
            this.Widgets.StepRejection.txtOutputScalingAmplitude.Value = mat2str(Value.MetaData.OutputScaling);

            % Update input and output scaling combo boxes
            if isempty(Value.Data.InputScaling)
                this.Widgets.StepRejection.cmbYesNoInput.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.StepRejection.cmbYesNoInput.Value = getString(message('Control:systunegui:YesLabel'));
            end
            cbcmbYesNoInputChange(this);
            
            if isempty(Value.Data.OutputScaling)
                this.Widgets.StepRejection.cmbYesNoOutput.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.StepRejection.cmbYesNoOutput.Value = getString(message('Control:systunegui:YesLabel'));
            end
            cbcmbYesNoOutputChange(this);
        end
    end

    methods(Access = private)
        %% GUI Listener callbacks
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
                systuneapp.util.openUIAlert(getParentFigure(this), ME.message);
                return;
            end
        end

        function cbMaxAmplitudeEdit(this, fieldValue)
            % Instant apply to TC when MaxAmplitude text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MaxAmplitude cannot be empty
                    update(this);
                else
                    setMaxAmplitude(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this), ME.message);
                return;
            end
        end

        function cbMaxSettlingTimeEdit(this, fieldValue)
            % Instant apply to TC when MaxSettlingTime text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MaxSettlingTime cannot be empty
                    update(this);
                else
                    setMaxSettlingTime(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end

        function cbMinDampingEdit(this, fieldValue)
            % Instant apply to TC when MinDamping text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MinDamping cannot be empty
                    update(this);
                else
                    setMinDamping(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end

        function cbResponseOptionSelected(this, hData)
            % update TC when radio button switches Response Characteristics
            % and Reference Model
            switch hData.NewValue.Tag
                case 'radioReferenceModel'
                    this.TCPeer.MetaData.ResponseType = 'ReferenceModel';
                    cbReferenceModelEdit(this, this.Widgets.StepRejection.txtReferenceModel.Value);
                case 'radioResponseCharacteristics'
                    this.TCPeer.MetaData.ResponseType = 'ResponseCharacteristics';
                    cbMaxAmplitudeEdit(this, this.Widgets.StepRejection.txtMaxAmplitude.Value)
                    cbMaxSettlingTimeEdit(this, this.Widgets.StepRejection.txtMaxSettlingTime.Value);
                    cbMinDampingEdit(this, this.Widgets.StepRejection.txtMinDamping.Value);
            end
            update(this);
            update(this.TCPeer.Data);
        end

        function cbInputScalingAmplitudeEdit(this, fieldValue)
            % Instant apply to TC when InputScaling text field changes
            try
                if nargin == 1
                    % Scaling amplitude can be empty. Account for it.
                    setInputScalingAmplitude(this.TCPeer);
                elseif isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setInputScalingAmplitude(this.TCPeer, fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end

        function cbOutputScalingAmplitudeEdit(this, fieldValue)
            % Instant apply to TC when outputScaling text field changes
            try
                if nargin == 1
                    % Scaling amplitude can be empty. Account for it.
                    setOutputScalingAmplitude(this.TCPeer);
                elseif isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setOutputScalingAmplitude(this.TCPeer, fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end

        function cbcmbYesNoInputChange(this)
            % update TC's InputScaling when scaling combo box changes
            switch this.Widgets.StepRejection.cmbYesNoInput.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.StepRejection.layoutOptions.RowHeight{2} = 'fit';
                    cbInputScalingAmplitudeEdit(this, this.Widgets.StepRejection.txtInputScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.StepRejection.layoutOptions.RowHeight{2} = 0;
                    cbInputScalingAmplitudeEdit(this);
            end
            update(this.TCPeer.Data);
        end

        function cbcmbYesNoOutputChange(this)
            % update TC's OutputScaling when scaling combo box changes
            switch this.Widgets.StepRejection.cmbYesNoOutput.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.StepRejection.layoutOptions.RowHeight{4} = 'fit';
                    cbOutputScalingAmplitudeEdit(this, this.Widgets.StepRejection.txtOutputScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.StepRejection.layoutOptions.RowHeight{4} = 0;
                    cbOutputScalingAmplitudeEdit(this);
            end
            update(this.TCPeer.Data);
        end
    end

end
