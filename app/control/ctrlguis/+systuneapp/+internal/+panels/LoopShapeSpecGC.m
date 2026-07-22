classdef LoopShapeSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Loop Shape tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(Access = protected) 
    end
    
    methods
        function obj = LoopShapeSpecGC(tcpeer)
            % Call parent constructor    
            obj = obj@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
        end
        
        function cbWcEdit(this,fieldValue)
            % Cross-over frequency text field editor
            try
               if isempty(fieldValue) || all(isspace(fieldValue))
                   % Cross-over frequency cannot be empty
                   update(this);
               else
                   setWc(this.TCPeer,fieldValue);
               end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbCrossTolEdit(this,fieldValue)
            % Cross-over tolerance text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % Cross-over tolerance cannot be empty
                    update(this);
                else
                    setCrossTol(this.TCPeer, fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbLoopGainEdit(this,fieldValue)
            % LoopGain text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % LoopGain cannot be empty
                    update(this);
                else
                    setLoopGain(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbYesNoScalingEdit(this)
            % update TC's LoopScaling when scaling combo box changes
            switch this.Widgets.LoopShape.cmbYesNoScaling.Value
                case getString(message('Control:systunegui:YesLabel'))
                    setLoopScaling(this.TCPeer, 'on');
                case getString(message('Control:systunegui:NoLabel'))
                    setLoopScaling(this.TCPeer, 'off');
            end
        end
        
        function cbStabilizeEdit(this)
            % update TC'Stabilize when stabilize combo box changes
            switch this.Widgets.LoopShape.cmbYesNoStabilize.Value
                case getString(message('Control:systunegui:YesLabel'))
                    setStabilize(this.TCPeer,1);
                case getString(message('Control:systunegui:NoLabel'))
                    setStabilize(this.TCPeer,0);
            end
        end
                
        function cbLoopShapeOptionsSelected(this, hData)
           % Switch the state of the flag and call update to swap the panels
           this.TCPeer.MetaData.EnableLoopGain = strcmp(hData.NewValue.Tag,'radioLoopGain');
           
           if this.TCPeer.MetaData.EnableLoopGain
               cbLoopGainEdit(this, this.Widgets.LoopShape.txtLoopGain.Value);
           else
               cbWcEdit(this, this.Widgets.LoopShape.txtWc.Value);
           end
           update(this);
           update(this.TCPeer.Data);
        end
        
        function updateUI(this)
            update(this);
        end
    end
    
    methods(Access = protected)
        function container = createContainer(this)
            % Create base class widgets
            createWidgets(this);
            
            % Container
            container = uigridlayout([2 1],'Parent',[],'Padding',0);
            container.RowHeight = {'fit','fit'};
            
            %% Desired loop shape panel
            accDesiredLoopShape = matlab.ui.container.internal.Accordion('Parent',container);
            pnlDesiredLoopShape = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accDesiredLoopShape);
            pnlDesiredLoopShape.Title = ...
                getString(message('Control:systunegui:LoopShapeSpecDesired'));
            layout = uigridlayout(pnlDesiredLoopShape,'RowHeight',{'fit',60,'fit'},...
                                    'ColumnWidth',{'1x'},'Padding',0);
            % Specify as
            lblSpecify = uilabel(layout);
            lblSpecify.Layout.Row = 1;
            lblSpecify.Layout.Column = 1;
            lblSpecify.Text = sprintf('%s',getString(message('Control:systunegui:TuningGoalSpecSpecify')));
            
            %Button group with the two radio buttons
            btnGroupError = uibuttongroup(layout);
            btnGroupError.Layout.Row = 2;
            btnGroupError.Layout.Column = 1;
            btnGroupError.BorderType = 'none';
            
            %Radio buttons to choose between specifying Response Time, DC
            %Error and Peak Error or Maximum Error
            radioLoopGain = uiradiobutton(btnGroupError);
            radioLoopGain.Text = sprintf('%s',getString(message('Control:systunegui:LoopShapeSpecRadioLoopGain')));
            radioLoopGain.Tag = 'radioLoopGain';
            radioLoopGain.Position = [10 5 165 25];
            
            radioCrossOver = uiradiobutton(btnGroupError);
            radioCrossOver.Text = sprintf('%s',getString(message('Control:systunegui:LoopShapeSpecRadioWc')));
            radioCrossOver.Tag = 'radioCrossOver';
            radioCrossOver.Position = [10 35 165 25];
            radioCrossOver.Value = true;

            % Specify Target Loop-Shape
            pnlLoopGain = uigridlayout(layout,'RowHeight',{'fit'},...
                                        'ColumnWidth',{'fit','1x'},'Padding',0);
            pnlLoopGain.Layout.Row = 3;
            pnlLoopGain.Layout.Column = 1;
            pnlLoopGain.Visible = 'off';
            % Loop Gain
            lblLoopGain = uilabel(pnlLoopGain);
            lblLoopGain.Layout.Row = 1;
            lblLoopGain.Layout.Column = 1;
            lblLoopGain.Tag = 'lblLoopGain';
            lblLoopGain.Text = sprintf('%s: ',getString(message('Control:systunegui:LoopShapeSpecLoopGain')));
            txtLoopGain = uieditfield(pnlLoopGain);
            txtLoopGain.Layout.Row = 1;
            txtLoopGain.Layout.Column = 2;
            txtLoopGain.Tag = 'txtLoopGain';
            
            % Specify cross-over frequency
            pnlWc = uigridlayout(layout,'RowHeight',{'fit'},...
                                'ColumnWidth',{'fit','1x','fit'},'Padding',0);
            pnlWc.Layout.Row = 3;
            pnlWc.Layout.Column = 1;
            % Cross-over frequency
            lblWc = uilabel(pnlWc);
            lblWc.Tag = 'lblWc';
            lblWc.Text = sprintf('%s',getString(message('Control:systunegui:LoopShapeSpecWc')));
            txtWc = uieditfield(pnlWc);
            txtWc.Tag = 'txtWc';
            lblFreqUnit = uilabel(pnlWc);
            lblFreqUnit.Tag = 'lblFreqUnit';
            lblFreqUnit.Text = sprintf('%s/%s',controllibutils.utXlateUnitsString('rad','short'),this.TCPeer.Data.CDD.getTimeUnitString);

            
            %% Options panel
            % Cross-over Tolerance
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layout = uigridlayout(pnlOptions,[6 3]);
            layout.Padding = 0;
            layout.RowHeight = {'fit','fit','fit','fit','fit','fit'};
            layout.ColumnWidth = {'fit','1x','fit'};
            lblCrossTol = uilabel(layout);
            lblCrossTol.Layout.Row = 1;
            lblCrossTol.Layout.Column = 1;
            lblCrossTol.Tag = 'lblCrossTol';
            lblCrossTol.Text = getString(message('Control:systunegui:LoopShapeSpecCrossTolerance'));
            txtCrossTol = uieditfield(layout);
            txtCrossTol.Layout.Row = 1;
            txtCrossTol.Layout.Column = 2;
            txtCrossTol.Tag = 'txtCrossTol';
            lblDecades = uilabel(layout);
            lblDecades.Layout.Row = 1;
            lblDecades.Layout.Column = 3;
            lblDecades.Tag = 'lblDecades';
            lblDecades.Text = getString(message('Control:systunegui:LoopShapeSpecDecades'));
            
            % Stabilize widgets
            lblStabilize = uilabel(layout);
            lblStabilize.Layout.Row = 3;
            lblStabilize.Layout.Column = 1;
            lblStabilize.Text = getString(message('Control:systunegui:LoopShapeSpecStabilize'));
            lblStabilize.Tag = 'lblStabilize';
            items = {getString(message('Control:systunegui:YesLabel')), getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoStabilize = uidropdown(layout);
            cmbYesNoStabilize.Layout.Row = 3;
            cmbYesNoStabilize.Layout.Column = [2 3];
            cmbYesNoStabilize.Items = items;
            cmbYesNoStabilize.Value = getString(message('Control:systunegui:YesLabel'));
                    
            % Scaling widgets
            lblScaling = uilabel(layout);
            lblScaling.Layout.Row = 4;
            lblScaling.Layout.Column = 1;
            lblScaling.Text = getString(message('Control:systunegui:LoopShapeSpecScaling'));
            items = {getString(message('Control:systunegui:YesLabel')), getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoScaling = uidropdown(layout);
            cmbYesNoScaling.Layout.Row = 4;
            cmbYesNoScaling.Layout.Column = [2 3];
            cmbYesNoScaling.Items = items;
            cmbYesNoScaling.Value = getString(message('Control:systunegui:NoLabel'));
            
            this.Widgets.Advanced.lblFocus.Parent = layout;
            this.Widgets.Advanced.lblFocus.Layout.Row = 2;
            this.Widgets.Advanced.lblFocus.Layout.Column = 1;
            this.Widgets.Advanced.txtFocus.Parent = layout;
            this.Widgets.Advanced.txtFocus.Layout.Row = 2;
            this.Widgets.Advanced.txtFocus.Layout.Column = 2;
            this.Widgets.Advanced.lblFreqUnit.Parent = layout;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 2;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 3;
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 5;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.LoopShape = struct(...
                'lblLoopGain',      lblLoopGain, ...
                'txtLoopGain',      txtLoopGain, ...
                'lblCrossTol',      lblCrossTol, ...
                'txtCrossTol',      txtCrossTol, ...
                'lblStabilize',     lblStabilize, ...
                'cmbYesNoStabilize',cmbYesNoStabilize,...
                'lblScaling',       lblScaling, ...
                'cmbYesNoScaling',cmbYesNoScaling, ...
                'lblSpecify',       lblSpecify, ...
                'pnlOptions',       pnlOptions, ...
                'pnlDesiredLoopShape', pnlDesiredLoopShape, ...
                'lblDecades',       lblDecades, ...
                'radioCrossOver',   radioCrossOver,...
                'radioLoopGain',    radioLoopGain,...
                'btnGroupError',    btnGroupError, ...
                'lblWc',            lblWc, ...
                'txtWc',            txtWc,...
                'lblFreqUnit',      lblFreqUnit,...
                'pnl',              container, ...
                'pnlWc',            pnlWc,...
                'pnlLoopGain',      pnlLoopGain);
        end
        
        function connectUI(this)
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            %Add callbacks for the text fields and the radio button
            this.Widgets.LoopShape.txtLoopGain.ValueChangedFcn = ...
                @(hSrc, hData)cbLoopGainEdit(this, this.Widgets.LoopShape.txtLoopGain.Value);
            this.Widgets.LoopShape.txtCrossTol.ValueChangedFcn = ...
                @(hSrc, hData)cbCrossTolEdit(this, this.Widgets.LoopShape.txtCrossTol.Value);
            this.Widgets.LoopShape.txtWc.ValueChangedFcn = ...
                @(hSrc, hData)cbWcEdit(this, this.Widgets.LoopShape.txtWc.Value);
            this.Widgets.LoopShape.btnGroupError.SelectionChangedFcn = ...
                @(hSrc, hData)cbLoopShapeOptionsSelected(this, hData);
            this.Widgets.LoopShape.cmbYesNoStabilize.ValueChangedFcn = ...
                @(hSrc, hData)cbStabilizeEdit(this);
            this.Widgets.LoopShape.cmbYesNoScaling.ValueChangedFcn = ...
                @(hSrc, hData)cbYesNoScalingEdit(this);
        end
        
        function cleanupUI(this)
            this.Widgets = [];
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);

            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
           
            % Add/ remove contents of performance panel depending on radio button selection
            if this.TCPeer.MetaData.EnableLoopGain == true
%                 this.Widgets.LoopShape.pnlLoopGain.Parent = this.Widgets.LoopShape.pnlDesiredLoopShape;
%                 this.Widgets.LoopShape.pnlWc.Parent = [];
                this.Widgets.LoopShape.pnlLoopGain.Visible = 'on';
                this.Widgets.LoopShape.pnlWc.Visible = 'off';
                this.Widgets.LoopShape.radioLoopGain.Value = true;
            else
%                 this.Widgets.LoopShape.pnlLoopGain.Parent = [];
%                 this.Widgets.LoopShape.pnlWc.Parent = this.Widgets.LoopShape.pnlDesiredLoopShape;
                this.Widgets.LoopShape.pnlLoopGain.Visible = 'off';
                this.Widgets.LoopShape.pnlWc.Visible = 'on';
                this.Widgets.LoopShape.radioCrossOver.Value = true;
            end

            %Update the text fields to the current value
            this.Widgets.LoopShape.txtWc.Value = mat2str(Value.MetaData.Wc);
            this.Widgets.LoopShape.txtLoopGain.Value = Value.MetaData.LoopGain;
            this.Widgets.LoopShape.txtCrossTol.Value = mat2str(Value.Data.CrossTol);
            
            if strcmp(Value.Data.LoopScaling, 'on')
                this.Widgets.LoopShape.cmbYesNoScaling.Value = getString(message('Control:systunegui:YesLabel'));
            else
                this.Widgets.LoopShape.cmbYesNoScaling.Value = getString(message('Control:systunegui:NoLabel'));
            end
            
            % Update stabilize combo box
            if Value.Data.Stabilize
                this.Widgets.LoopShape.cmbYesNoStabilize.Value= getString(message('Control:systunegui:YesLabel'));
            else
                this.Widgets.LoopShape.cmbYesNoStabilize.Value = getString(message('Control:systunegui:NoLabel'));
            end
        end
    end
end
