classdef OvershootSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Overshoot tuning goal specifications

    % Copyright 2013-2022 The MathWorks, Inc
    methods
        function obj = OvershootSpecGC(tcpeer)
            %Call parent constructor
            obj = obj@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
            obj.ShowFocusWidget = false;
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
            
            %% Limit Overshoot panel
            accLimitOvershoot = matlab.ui.container.internal.Accordion('Parent',container);
            pnlLimitOvershoot = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accLimitOvershoot);
            pnlLimitOvershoot.Title = getString(message('Control:systunegui:TuningGoalDescriptionLimitOvershoot'));
            layout = uigridlayout(pnlLimitOvershoot,"RowHeight",{'fit'},...
                                "ColumnWidth",{'fit','1x'},"Padding",0);
            % Maximum Overshoot
            lblMaxOvershoot = uilabel(layout);
            lblMaxOvershoot.Tag = 'lblMaxOvershoot';
            lblMaxOvershoot.Text = getString(message('Control:systunegui:OvershootSpecOvershoot'));
            txtMaxOvershoot = uieditfield(layout);
            txtMaxOvershoot.Tag = 'txtMaxOvershoot';
            
            %% Options Panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            optsLayout = uigridlayout(pnlOptions,"RowHeight",{'fit','fit'},...
                                    "ColumnWidth",{20,'fit','1x','fit'},"Padding",0);

            % Input and Output Scaling
            lblScaling = uilabel(optsLayout,...
                'Text',getString(message('Control:systunegui:GainSpecScaling')));
            lblScaling.Layout.Row = 1;
            lblScaling.Layout.Column = [1 2];
            items = {getString(message('Control:systunegui:YesLabel')),...
                getString(message('Control:systunegui:NoLabel'))};
            cmbYesNo = uidropdown(optsLayout,'Items',items);
            cmbYesNo.Value = getString(message('Control:systunegui:NoLabel'));
            cmbYesNo.Layout.Row = 1;
            cmbYesNo.Layout.Column = [3 4];
            lblScalingAmplitude = uilabel(optsLayout,...
                'Text',getString(message('Control:systunegui:GainSpecInputScalingAmplitude')));
            lblScalingAmplitude.Layout.Row = 2;
            lblScalingAmplitude.Layout.Column = 2;
            txtScalingAmplitude = uieditfield(optsLayout);
            txtScalingAmplitude.Layout.Row = 2;
            txtScalingAmplitude.Layout.Column = [3 4];
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = optsLayout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 3;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 4];

            %% Store widgets for easy access
            this.Widgets.Overshoot = struct(...
                'lblMaxOvershoot',      lblMaxOvershoot, ...
                'txtMaxOvershoot',      txtMaxOvershoot,...
                'cmbYesNo',             cmbYesNo, ...
                'lblScaling',           lblScaling, ...
                'lblScalingAmplitude',  lblScalingAmplitude,...
                'txtScalingAmplitude',  txtScalingAmplitude, ...
                'pnl',                  pnlLimitOvershoot, ...
                'layoutOptions',        optsLayout,...
                'pnlOptions',           pnlOptions);

        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            %Add listeners for the text fields and the radio button
            this.Widgets.Overshoot.txtMaxOvershoot.ValueChangedFcn = ...
                @(hSrc, hData)cbMaxOvershootEdit(this, this.Widgets.Overshoot.txtMaxOvershoot.Value);
            this.Widgets.Overshoot.cmbYesNo.ValueChangedFcn = ...
                @(hSrc,hData) cbCmbYesNoChange(this);
            this.Widgets.Overshoot.txtScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbScalingAmplitudeEdit(this, this.Widgets.Overshoot.txtScalingAmplitude.Value);
        end

        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);

            %Update the text fields to the current value
            this.Widgets.Overshoot.txtMaxOvershoot.Value = mat2str(Value.Data.MaxOvershoot);
            this.Widgets.Overshoot.txtScalingAmplitude.Value = mat2str(Value.MetaData.InputScaling);

            if isempty(Value.Data.InputScaling)
                this.Widgets.Overshoot.cmbYesNo.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.Overshoot.cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            end
            cbCmbYesNoChange(this);
        end

        function cleanupGUI(this)
            this.Widgets = [];
        end
    end
    
    methods (Access = private)
        function cbMaxOvershootEdit(this,fieldValue)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MaxOvershoot cannot be empty
                    update(this);
                else
                    overshootValue = evalin('base',fieldValue);
                    if isnumeric(overshootValue) && overshootValue < 5
                        fig = ancestor(getWidget(this),'figure');
                        uialert(fig,getString(message('Control:systunegui:OvershootSpecNotGuaranteed')),...
                            getString(message('Control:systunegui:toolName')),...
                            'Icon','warn');
                    end
                    setMaxOvershoot(this.TCPeer,overshootValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end

        function cbCmbYesNoChange(this)
            switch this.Widgets.Overshoot.cmbYesNo.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.Overshoot.layoutOptions.RowHeight{2} = 'fit';
                    cbScalingAmplitudeEdit(this, this.Widgets.Overshoot.txtScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.Overshoot.layoutOptions.RowHeight{2} = 0;
                    cbScalingAmplitudeEdit(this);
            end
            this.TCPeer.Data.update;
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
    end
    
    methods(Hidden)
         function Widgets = qeGetWidgets(this)
            Widgets = this.Widgets;
        end
    end


end
