classdef TrackingSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Tracking tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc

    methods
        function this = TrackingSpecGC(tcpeer)            
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
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
            
            %% Tracking Performance panel
            accPerformance = matlab.ui.container.internal.Accordion('Parent',container);
            pnlPerformance = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accPerformance);
            pnlPerformance.Title = getString(message('Control:systunegui:TrackingTuningGoalSpecPerformance'));
            layoutPerformance = uigridlayout(pnlPerformance,...
                'RowHeight',{'fit',60,'fit','fit','fit'},'ColumnWidth',{'fit','1x','fit'},'Padding',0);
            
            % Specify As
            lblSpecify = uilabel(layoutPerformance);
            lblSpecify.Text = getString(message('Control:systunegui:TuningGoalSpecSpecify'));
            lblSpecify.Layout.Row = 1;
            lblSpecify.Layout.Column = [1 3];
            
            % Button group with the three radio buttons
            btnGroupError = uibuttongroup(layoutPerformance);
            btnGroupError.BorderType = 'none';
            btnGroupError.Layout.Row = 2;
            btnGroupError.Layout.Column = [1 3];
            
            % Radio button DC Error
            radioDCError = uiradiobutton(btnGroupError);
            radioDCError.Text =  getString(message('Control:systunegui:TrackingSpecRadioDCError'));
            radioDCError.Tag = 'radioDCError';
            radioDCError.Position = [10 35 300 25];
            
            % Radio button Max error
            radioMaxError = uiradiobutton(btnGroupError);
            radioMaxError.Text =  getString(message('Control:systunegui:TrackingSpecRadioMaxError'));
            radioMaxError.Tag = 'radioMaxError';
            radioMaxError.Position = [10 5 300 25];
            
            % Response Time
            lblRT = uilabel(layoutPerformance);
            lblRT.Tag = 'lblRT';
            lblRT.Text = getString(message('Control:systunegui:TrackingSpecResponseTime'));
            lblRT.Layout.Row = 3;
            lblRT.Layout.Column = 1;
            txtRT = uieditfield(layoutPerformance);
            txtRT.Tag = 'txtRT';
            txtRT.Layout.Row = 3;
            txtRT.Layout.Column = 2;
            lblTimeUnit = uilabel(layoutPerformance);
            lblTimeUnit.Tag = 'lblRT';
            lblTimeUnit.Text = this.TCPeer.Data.CDD.getTimeUnitString;
            lblTimeUnit.Layout.Row = 3;
            lblTimeUnit.Layout.Column = 3;
            
            % DC Error
            lblDCError = uilabel(layoutPerformance);
            lblDCError.Tag = 'lblDCError';
            lblDCError.Text = getString(message('Control:systunegui:TrackingSpecDCError'));
            lblDCError.Layout.Row = 4;
            lblDCError.Layout.Column = 1;
            txtDCError = uieditfield(layoutPerformance);
            txtDCError.Tag = 'txtDCError';
            txtDCError.Layout.Row = 4;
            txtDCError.Layout.Column = 2;
            
            % Peak Error
            lblPeakError = uilabel(layoutPerformance);
            lblPeakError.Tag = 'lblPeakError';
            lblPeakError.Text = getString(message('Control:systunegui:TrackingSpecPeakError'));
            lblPeakError.Layout.Row = 5;
            lblPeakError.Layout.Column = 1;
            txtPeakError = uieditfield(layoutPerformance);
            txtPeakError.Tag = 'txtPeakError';
            txtPeakError.Layout.Row = 5;
            txtPeakError.Layout.Column = 2;
            
            % Label-Value pair to specify the Error profile or the Maximum
            %Error
            lblMaxError = uilabel(layoutPerformance);
            lblMaxError.Tag = 'lblMaxError';
            lblMaxError.Text = getString(message('Control:systunegui:TrackingSpecMaxError'));
            lblMaxError.Layout.Row = 3;
            lblMaxError.Layout.Column = 1;
            txtMaxError = uieditfield(layoutPerformance);
            txtMaxError.Tag = 'txtMaxError';
            txtMaxError.Layout.Row = 3;
            txtMaxError.Layout.Column = 2;
            
            %% Options Panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layoutOptions = uigridlayout(pnlOptions,[4 4]);
            layoutOptions.Padding = 0;
            layoutOptions.RowHeight = {'fit','fit','fit','fit'};
            layoutOptions.ColumnWidth = {20,'fit','1x','fit'};
            
            %Add Scaling widgets
            lblScaling = uilabel(layoutOptions);
            lblScaling.Text = getString(message('Control:systunegui:TrackingSpecSignalScaling'));
            lblScaling.Layout.Row = 2;
            lblScaling.Layout.Column = [1 2];
            lblScalingAmplitude = uilabel(layoutOptions);
            lblScalingAmplitude.Text = ...
                getString(message('Control:systunegui:TrackingSpecSignalScalingAmplitude'));
            lblScalingAmplitude.Layout.Row = 3;
            lblScalingAmplitude.Layout.Column = 2;
            txtScalingAmplitude = uieditfield(layoutOptions);
            txtScalingAmplitude.Tag = 'txtScalingAmplitude';
            txtScalingAmplitude.Layout.Row = 3;
            txtScalingAmplitude.Layout.Column = 3;
            
            items = {getString(message('Control:systunegui:YesLabel')), getString(message('Control:systunegui:NoLabel'))};
            cmbYesNo = uidropdown(layoutOptions,'Items',items);
            cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            cmbYesNo.Layout.Row = 2;
            cmbYesNo.Layout.Column = 3;
            
            % Focus
            this.Widgets.Advanced.lblFocus.Parent = layoutOptions;
            this.Widgets.Advanced.lblFocus.Layout.Row = 1;
            this.Widgets.Advanced.lblFocus.Layout.Column = [1 2];
            this.Widgets.Advanced.txtFocus.Parent = layoutOptions;
            this.Widgets.Advanced.txtFocus.Layout.Row = 1;
            this.Widgets.Advanced.txtFocus.Layout.Column = 3;
            this.Widgets.Advanced.lblFreqUnit.Parent = layoutOptions;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 1;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 4;
            
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = layoutOptions;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 4;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 4];
            
            %% Store widgets for easy access
            this.Widgets.Tracking = struct(...
                'lblRT',            lblRT, ...
                'txtRT',            txtRT, ...
                'lblTimeUnit',      lblTimeUnit, ...
                'lblDCError',       lblDCError, ...
                'txtDCError',       txtDCError, ...
                'radioMaxError',    radioMaxError,...
                'radioDCError',     radioDCError,...
                'btnGroupError',    btnGroupError, ...
                'lblMaxError',      lblMaxError, ...
                'txtMaxError',      txtMaxError,...
                'lblPeakError',     lblPeakError,...
                'txtPeakError',     txtPeakError,...
                'pnlPerformance',   pnlPerformance, ...
                'layoutPerformance',layoutPerformance,...
                'lblScaling',       lblScaling,...
                'lblScalingAmplitude', lblScalingAmplitude,...
                'txtScalingAmplitude', txtScalingAmplitude,...
                'cmbYesNo',         cmbYesNo,...
                'pnlOptions',       pnlOptions,...
                'layoutOptions',    layoutOptions,...
                'pnl',              container);

        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this); 
            this.Widgets.Tracking.txtRT.ValueChangedFcn = ...
                @(hSrc, hData)cbRTEdit(this, this.Widgets.Tracking.txtRT.Value);
            this.Widgets.Tracking.txtDCError.ValueChangedFcn = ...
                @(hSrc, hData)cbDCErrorEdit(this, this.Widgets.Tracking.txtDCError.Value);
            this.Widgets.Tracking.txtMaxError.ValueChangedFcn = ...
                @(hSrc, hData)cbMaxErrorEdit(this, this.Widgets.Tracking.txtMaxError.Value);
            this.Widgets.Tracking.txtPeakError.ValueChangedFcn = ...
                @(hSrc, hData)cbPeakErrorEdit(this, this.Widgets.Tracking.txtPeakError.Value);
            this.Widgets.Tracking.btnGroupError.SelectionChangedFcn = ...
                @(hSrc, hData) cbErrorOptionSelected(this,hData);
            this.Widgets.Tracking.cmbYesNo.ValueChangedFcn = ...
                @(hSrc,hData) cbCmbYesNoChange(this);
            this.Widgets.Tracking.txtScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbScalingAmplitudeEdit(this, this.Widgets.Tracking.txtScalingAmplitude.Value);
        end
        
        function update(this)
            
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            % Add/ remove contents of performance panel depending on radio button selection
            if this.TCPeer.MetaData.EnableFreqDomainSpec == true
                this.Widgets.Tracking.lblRT.Visible = 'off';
                this.Widgets.Tracking.txtRT.Visible = 'off';
                this.Widgets.Tracking.lblTimeUnit.Visible = 'off';
                this.Widgets.Tracking.lblMaxError.Visible = 'on';
                this.Widgets.Tracking.txtMaxError.Visible = 'on';
                this.Widgets.Tracking.layoutPerformance.RowHeight(4:5) = {0,0};
                this.Widgets.Tracking.radioMaxError.Value = true;
            else
                this.Widgets.Tracking.lblRT.Visible = 'on';
                this.Widgets.Tracking.txtRT.Visible = 'on';
                this.Widgets.Tracking.lblTimeUnit.Visible = 'on';
                this.Widgets.Tracking.lblMaxError.Visible = 'off';
                this.Widgets.Tracking.txtMaxError.Visible = 'off';
                this.Widgets.Tracking.layoutPerformance.RowHeight(4:5) = {'fit','fit'};
                this.Widgets.Tracking.radioDCError.Value = true;
            end
            
            % Update the text fields to the current value
            this.Widgets.Tracking.txtRT.Value = mat2str(Value.MetaData.ResponseTime);
            this.Widgets.Tracking.txtDCError.Value = mat2str(Value.MetaData.DCError*100);
            this.Widgets.Tracking.txtPeakError.Value = mat2str(Value.MetaData.PeakError*100);
            this.Widgets.Tracking.txtMaxError.Value = Value.MetaData.MaxError;
            this.Widgets.Tracking.txtScalingAmplitude.Value = mat2str(Value.MetaData.InputScaling);

            % Update input scaling combo box
            if isempty(Value.Data.InputScaling)
                this.Widgets.Tracking.cmbYesNo.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.Tracking.cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            end
            cbCmbYesNoChange(this);
        end
    end
    
    methods (Access = private)
        function cbRTEdit(this,fieldValue)
            % Response time text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % RT cannot be empty
                    update(this);
                else
                 setRT(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbDCErrorEdit(this,fieldValue)
            % DC Error text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % DCError cannot be empty
                    update(this);
                else
                 setDCError(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        
        function cbPeakErrorEdit(this,fieldValue)
            % Peak Error text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % PeakError cannot be empty
                    update(this);
                else
                 setPeakError(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbMaxErrorEdit(this,fieldValue)
            % MaxError text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MaxError cannot be empty
                    update(this);
                else
                    setMaxError(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbErrorOptionSelected(this, hData)
            % update TC when radio button switches between time domain and
            % frequency domain configurations
            
           this.TCPeer.MetaData.EnableFreqDomainSpec = strcmp(hData.NewValue.Tag,'radioMaxError');
           if this.TCPeer.MetaData.EnableFreqDomainSpec
               cbMaxErrorEdit(this, this.Widgets.Tracking.txtMaxError.Value);
           else
               cbRTEdit(this, this.Widgets.Tracking.txtRT.Value);
               cbDCErrorEdit(this, this.Widgets.Tracking.txtDCError.Value);
               cbPeakErrorEdit(this, this.Widgets.Tracking.txtPeakError.Value);
           end
           update(this);
           update(this.TCPeer.Data);
        end

        function cbScalingAmplitudeEdit(this, fieldValue)
            % update TC when InputScaling text field changes
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
            switch this.Widgets.Tracking.cmbYesNo.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.Tracking.layoutOptions.RowHeight{3} = 'fit';
                    cbScalingAmplitudeEdit(this, this.Widgets.Tracking.txtScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.Tracking.layoutOptions.RowHeight{3} = 0;
                    cbScalingAmplitudeEdit(this);
            end
        end
    end
end
