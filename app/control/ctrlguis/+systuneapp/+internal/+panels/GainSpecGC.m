classdef GainSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Gain tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc.
    properties(Access = protected)
    end

    methods
        function obj = GainSpecGC(tcpeer)
            % Call parent constructor
            obj = obj@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
        end

        function updateUI(this)
            update(this)
        end
            
        
        function cbGainEdit(this,fieldValue)
            % Gain text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setGain(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbStabilizeEdit(this)
            % Stabilize property editor
            switch this.Widgets.Gain.cmbYesNoStabilize.Value
                case getString(message('Control:systunegui:YesLabel'))
                    setStabilize(this.TCPeer,1);
                case getString(message('Control:systunegui:NoLabel'))
                    setStabilize(this.TCPeer,0);
            end
        end
        
        function cbYesNoScalingEdit(this)
            % Input and Output scaling editors
            switch this.Widgets.Gain.cmbYesNoScaling.Value
                case getString(message('Control:systunegui:YesLabel'))
                    cbInputScalingAmplitudeEdit(this, this.Widgets.Gain.txtInputScalingAmplitude.Value);
                    cbOutputScalingAmplitudeEdit(this, this.Widgets.Gain.txtOutputScalingAmplitude.Value);
                    this.Widgets.Gain.layoutOptions.RowHeight{4} = 'fit';
                    this.Widgets.Gain.layoutOptions.RowHeight{5} = 'fit';
                case getString(message('Control:systunegui:NoLabel'))
                    cbInputScalingAmplitudeEdit(this);
                    cbOutputScalingAmplitudeEdit(this);
                    this.Widgets.Gain.layoutOptions.RowHeight{4} = 0;
                    this.Widgets.Gain.layoutOptions.RowHeight{5} = 0;
            end
            this.TCPeer.Data.update;
        end
        
        function cbInputScalingAmplitudeEdit(this, fieldValue)
            % update TC when InputScaling text field changes
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
            % update TC when OutputScaling text field changes
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
        
    end
    
    methods(Access= protected)
        function container = createContainer(this)
            % Create base class widgets
            createWidgets(this);
            
            % Container
            container = uigridlayout([2 1],'Parent',[],'Padding',0);
            container.RowHeight = {'fit','fit'};
            
            %% Limit Gain panel
            accLimitGain = matlab.ui.container.internal.Accordion('Parent',container);
            pnlLimitGain = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accLimitGain);
            pnlLimitGain.Title = getString(message('Control:systunegui:TuningGoalDescriptionLimitGain'));
            gainLayout = uigridlayout(pnlLimitGain,'RowHeight',{'fit'},...
                'ColumnWidth',{'fit','1x'},'Padding',0);
            lblGain = uilabel(gainLayout,'Text',getString(message('Control:systunegui:GainSpecGain')));
            lblGain.Tag = 'lblGain';
            txtGain = uieditfield(gainLayout);
            txtGain.Tag = 'txtGain';
            
            %% Options Panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            optsLayout = uigridlayout(pnlOptions,[6 4]);
            optsLayout.Padding = 0;
            optsLayout.RowHeight = {'fit','fit','fit','fit','fit','fit'};
            optsLayout.ColumnWidth = {20,'fit','1x','fit'};
            % Stabilize
            lblStabilize = uilabel(optsLayout,...
                'Text',getString(message('Control:systunegui:GainSpecStabilize')));
            lblStabilize.Tag = 'lblStabilize';
            lblStabilize.Layout.Row = 1;
            lblStabilize.Layout.Column = [1 2];
            items = {getString(message('Control:systunegui:YesLabel')),...
                getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoStabilize = uidropdown(optsLayout,'Items',items);
            cmbYesNoStabilize.Value = getString(message('Control:systunegui:YesLabel'));
            cmbYesNoStabilize.Layout.Row = 1;
            cmbYesNoStabilize.Layout.Column = [3 4];
            % Input and Output Scaling
            lblScaling = uilabel(optsLayout,...
                'Text',getString(message('Control:systunegui:GainSpecScaling')));
            lblScaling.Layout.Row = 3;
            lblScaling.Layout.Column = [1 2];
            items = {getString(message('Control:systunegui:YesLabel')),...
                getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoScaling = uidropdown(optsLayout,'Items',items);
            cmbYesNoScaling.Value = getString(message('Control:systunegui:NoLabel'));
            cmbYesNoScaling.Layout.Row = 3;
            cmbYesNoScaling.Layout.Column = [3 4];
            lblInputScalingAmplitude = uilabel(optsLayout,...
                'Text',getString(message('Control:systunegui:GainSpecInputScalingAmplitude')));
            lblInputScalingAmplitude.Layout.Row = 4;
            lblInputScalingAmplitude.Layout.Column = 2;
            lblOutputScalingAmplitude = uilabel(optsLayout,...
                'Text',getString(message('Control:systunegui:GainSpecOutputScalingAmplitude')));
            lblOutputScalingAmplitude.Layout.Row = 5;
            lblOutputScalingAmplitude.Layout.Column = 2;
            txtInputScalingAmplitude = uieditfield(optsLayout);
            txtInputScalingAmplitude.Layout.Row = 4;
            txtInputScalingAmplitude.Layout.Column = [3 4];
            txtOutputScalingAmplitude = uieditfield(optsLayout);
            txtOutputScalingAmplitude.Layout.Row = 5;
            txtOutputScalingAmplitude.Layout.Column = [3 4];
            % Focus
            this.Widgets.Advanced.lblFocus.Parent = optsLayout;
            this.Widgets.Advanced.lblFocus.Layout.Row = 2;
            this.Widgets.Advanced.lblFocus.Layout.Column = [1 2];
            this.Widgets.Advanced.txtFocus.Parent = optsLayout;
            this.Widgets.Advanced.txtFocus.Layout.Row = 2;
            this.Widgets.Advanced.txtFocus.Layout.Column = 3;
            this.Widgets.Advanced.lblFreqUnit.Parent = optsLayout;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 2;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 4;
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = optsLayout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 6;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 4];
            
            %% Store widgets for easy access
            this.Widgets.Gain = struct(...
                'lblGain',                   lblGain, ...
                'txtGain',                   txtGain,...
                'lblStabilize',              lblStabilize, ...
                'lblScaling',                lblScaling, ...
                'lblInputScalingAmplitude',  lblInputScalingAmplitude,...
                'txtInputScalingAmplitude',  txtInputScalingAmplitude,...
                'lblOutputScalingAmplitude', lblOutputScalingAmplitude,...
                'txtOutputScalingAmplitude', txtOutputScalingAmplitude,...
                'cmbYesNoStabilize',         cmbYesNoStabilize,...
                'cmbYesNoScaling',           cmbYesNoScaling,...
                'pnl',                       container,...
                'pnlLimitGain',              pnlLimitGain,...
                'pnlOptions',                pnlOptions,...
                'layoutOptions',             optsLayout,...
                'layoutGain',                gainLayout);
        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            this.Widgets.Gain.txtGain.ValueChangedFcn = ...
                @(hSrc, hData) cbGainEdit(this, this.Widgets.Gain.txtGain.Value);
            this.Widgets.Gain.cmbYesNoStabilize.ValueChangedFcn = ...
                @(hSrc, hData) cbStabilizeEdit(this);
            this.Widgets.Gain.cmbYesNoScaling.ValueChangedFcn = ...
                @(hSrc, hData) cbYesNoScalingEdit(this);
            this.Widgets.Gain.txtInputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData) cbInputScalingAmplitudeEdit(this, this.Widgets.Gain.txtInputScalingAmplitude.Value);
            this.Widgets.Gain.txtOutputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData) cbOutputScalingAmplitudeEdit(this, this.Widgets.Gain.txtOutputScalingAmplitude.Value);
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value
            this.Widgets.Gain.txtGain.Value = Value.MetaData.Gain;
            this.Widgets.Gain.txtModels.Value = mat2str(Value.MetaData.Models);
            this.Widgets.Gain.txtInputScalingAmplitude.Value = mat2str(Value.MetaData.InputScaling);
            this.Widgets.Gain.txtOutputScalingAmplitude.Value = mat2str(Value.MetaData.OutputScaling);

            % Update Stabilize combo box
            if Value.Data.Stabilize
                this.Widgets.Gain.cmbYesNoStabilize.Value = getString(message('Control:systunegui:YesLabel'));
            else
                this.Widgets.Gain.cmbYesNoStabilize.Value = getString(message('Control:systunegui:NoLabel'));
            end

            % Update input scaling and output scaling combo boxes
            if isempty(Value.Data.InputScaling) && isempty(Value.Data.OutputScaling)
                this.Widgets.Gain.cmbYesNoScaling.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.Gain.cmbYesNoScaling.Value = getString(message('Control:systunegui:YesLabel'));
            end
            cbYesNoScalingEdit(this);
        end
    end
end
