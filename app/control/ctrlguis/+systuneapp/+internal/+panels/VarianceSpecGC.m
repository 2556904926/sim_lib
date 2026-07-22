classdef VarianceSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Variance tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc

    methods
        function this = VarianceSpecGC(tcpeer)
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
            % Create base class widgets
            createWidgets(this);
            
            % Container
            container = uigridlayout([2 1],'Parent',[],'Padding',0);
            container.RowHeight = {'fit','fit'};
            
            %% Variance panel
            accInputVariance = matlab.ui.container.internal.Accordion('Parent',container);
            pnlInputVariance = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accInputVariance);
            pnlInputVariance.Title = getString(message(...
                'Control:systunegui:VarianceTuningGoalSpecInputVariance'));
            varianceLayout = uigridlayout(pnlInputVariance,'RowHeight',{'fit'},...
                'ColumnWidth',{'fit','1x'},'Padding',0);
            % Maximum Amplification
            lblMaxAmplification = uilabel(varianceLayout);
            lblMaxAmplification.Text = getString(message('Control:systunegui:VarianceSpecVariance'));
            lblMaxAmplification.Layout.Row = 1;
            lblMaxAmplification.Layout.Column = 1;
            lblMaxAmplification.Tag = 'lblMaxAmplification';
            txtMaxAmplification = uieditfield(varianceLayout);
            txtMaxAmplification.Tag = 'txtMaxAmplification';
            txtMaxAmplification.Layout.Row = 1;
            txtMaxAmplification.Layout.Column = 2;
            
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
            
            % Input and Output Scaling
            lblScaling = uilabel(optsLayout);
            lblScaling.Text = getString(message('Control:systunegui:GainSpecScaling'));
            lblScaling.Layout.Row = 1;
            lblScaling.Layout.Column = [1 2];
            
            lblInputScalingAmplitude = uilabel(optsLayout);
            lblInputScalingAmplitude.Text = ...
                getString(message('Control:systunegui:GainSpecInputScalingAmplitude'));
            lblInputScalingAmplitude.Layout.Row = 2;
            lblInputScalingAmplitude.Layout.Column = 2;            
            
            lblOutputScalingAmplitude = uilabel(optsLayout);
            lblOutputScalingAmplitude.Text = ...
                getString(message('Control:systunegui:GainSpecOutputScalingAmplitude'));
            lblOutputScalingAmplitude.Layout.Row = 3;
            lblOutputScalingAmplitude.Layout.Column = 2;
            
            txtInputScalingAmplitude = uieditfield(optsLayout);
            txtInputScalingAmplitude.Tag = 'txtInputScalingAmplitude';
            txtInputScalingAmplitude.Layout.Row = 2;
            txtInputScalingAmplitude.Layout.Column = 3;
                        
            txtOutputScalingAmplitude = uieditfield(optsLayout);
            txtOutputScalingAmplitude.Tag = 'txtOutputScalingAmplitude';
            txtOutputScalingAmplitude.Layout.Row = 3;
            txtOutputScalingAmplitude.Layout.Column = 3;
            
            items = {getString(message('Control:systunegui:YesLabel')), ...
                     getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoScaling = uidropdown(optsLayout,'Items',items);
            cmbYesNoScaling.Layout.Row = 1;
            cmbYesNoScaling.Layout.Column = 3;
            
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = optsLayout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 4;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
           
            
            %% Store widgets for easy access
            this.Widgets.Variance = struct(...
                'lblMaxAmplification',       lblMaxAmplification, ...
                'txtMaxAmplification',       txtMaxAmplification,...
                'lblInputScalingAmplitude',  lblInputScalingAmplitude,...
                'txtInputScalingAmplitude',  txtInputScalingAmplitude,...
                'lblOutputScalingAmplitude', lblOutputScalingAmplitude,...
                'txtOutputScalingAmplitude', txtOutputScalingAmplitude,...
                'cmbYesNoScaling',           cmbYesNoScaling,...
                'lblScaling',                lblScaling,...
                'pnl',                       container,...
                'pnlInputVariance',          pnlInputVariance,...
                'pnlOptions',                pnlOptions,...
                'layoutOptions',             optsLayout);
            
        end
        
        function connectUI(this)
            % Add listeners for the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            %Add listeners for the text fields
            this.Widgets.Variance.txtMaxAmplification.ValueChangedFcn = ... 
                @(hSrc, hData)cbMaxAmplificationEdit(this, this.Widgets.Variance.txtMaxAmplification.Value);
            this.Widgets.Variance.cmbYesNoScaling.ValueChangedFcn = ...
                @(hSrc, hData)cbYesNoScalingEdit(this);
            this.Widgets.Variance.txtInputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbInputScalingAmplitudeEdit(this, this.Widgets.Variance.txtInputScalingAmplitude.Value);
            this.Widgets.Variance.txtOutputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbOutputScalingAmplitudeEdit(this, this.Widgets.Variance.txtOutputScalingAmplitude.Value);
        end

        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value            
            this.Widgets.Variance.txtMaxAmplification.Value = mat2str(1/Value.Data.MaxAmplification);
            this.Widgets.Variance.txtInputScalingAmplitude.Value = mat2str(Value.MetaData.InputScaling);
            this.Widgets.Variance.txtOutputScalingAmplitude.Value = mat2str(Value.MetaData.OutputScaling);

            % Update input scaling and output scaling combo boxes
            if isempty(Value.Data.InputScaling) && isempty(Value.Data.OutputScaling)
                this.Widgets.Variance.cmbYesNoScaling.Value = getString(message('Control:systunegui:NoLabel'));
                this.Widgets.Variance.layoutOptions.RowHeight(2:3) = {0,0};
                cbInputScalingAmplitudeEdit(this);
                cbOutputScalingAmplitudeEdit(this);
            else
                this.Widgets.Variance.cmbYesNoScaling.Value = getString(message('Control:systunegui:YesLabel'));                
                this.Widgets.Variance.layoutOptions.RowHeight(2:3) = {'fit','fit'};
                cbInputScalingAmplitudeEdit(this, this.Widgets.Variance.txtInputScalingAmplitude.Value);
                cbOutputScalingAmplitudeEdit(this, this.Widgets.Variance.txtOutputScalingAmplitude.Value);
            end
        end
    end
    
    methods (Access = private)
        function cbMaxAmplificationEdit(this,fieldValue)
            % Instant update to TC when MaxAmplification factor is edited
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setMaxAmplification(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end

        function cbYesNoScalingEdit(this)
            % Update when scaling changes between 'yes' and 'no'
            switch this.Widgets.Variance.cmbYesNoScaling.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.Variance.layoutOptions.RowHeight(2:3) = {'fit','fit'};
                    cbInputScalingAmplitudeEdit(this, ...
                        this.Widgets.Variance.txtInputScalingAmplitude.Value);
                    cbOutputScalingAmplitudeEdit(this, ...
                        this.Widgets.Variance.txtOutputScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.Variance.layoutOptions.RowHeight(2:3) = {0,0};
                    cbInputScalingAmplitudeEdit(this);
                    cbOutputScalingAmplitudeEdit(this);
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
end
