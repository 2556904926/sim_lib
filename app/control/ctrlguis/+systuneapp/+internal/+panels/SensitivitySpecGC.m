classdef (Hidden) SensitivitySpecGC <  systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Sensitivity tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(Access = protected)
    end

    methods
        function this = SensitivitySpecGC(tcpeer)
            %Call parent constructor
             this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
        end
        
        function updateUI(this)
            update(this);
        end

        function cbMaxSensitivityEdit(this,fieldValue)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setMaxSensitivity(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
                
        function cbCmbYesNoChange(this)
            switch this.Widgets.Sensitivity.cmbYesNo.Value
                case getString(message('Control:systunegui:YesLabel'))
                    setLoopScaling(this.TCPeer,'on');
                case getString(message('Control:systunegui:NoLabel'))
                    setLoopScaling(this.TCPeer,'off');
            end
        end
       
    end
    methods(Access= protected)
        function container = createContainer(this)
            %% Create base class widgets
            createWidgets(this);
            
            %% Container
            container = uigridlayout([2 1],'Parent',[],'Padding',0);
            container.RowHeight = {'fit','fit'};
            
            %% Sensitivity evaluation panel
            % MaxSensitivity
            accSensitivityBound = matlab.ui.container.internal.Accordion('Parent',container);
            pnlSensitivity= matlab.ui.container.internal.AccordionPanel(...
                'Parent',accSensitivityBound);
            pnlSensitivity.Title = getString(message('Control:systunegui:SensitivitySpecPerformance'));
            layout = uigridlayout(pnlSensitivity,"RowHeight",{'fit','fit'},...
                                "ColumnWidth",{'1x'},"Padding",0);
            lblMaxSensitivity = uilabel(layout);
            lblMaxSensitivity.Text = sprintf('%s: ',getString(message('Control:systunegui:SensitivitySpecMaxSensitivity')));
            lblMaxSensitivity.Tag = 'lblMaxSensitivity';
            lblMaxSensitivity.Layout.Row = 1;
            txtMaxSensitivity = uieditfield(layout);
            txtMaxSensitivity.Tag = 'txtMaxSensitivity';
            txtMaxSensitivity.Layout.Row = 2;
            
            %% Construct options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layout = uigridlayout(pnlOptions,"RowHeight",{'fit','fit','fit'},...
                                    "ColumnWidth",{'fit','1x','fit'},"Padding",0);
            
            % Focus
            this.Widgets.Advanced.lblFocus.Parent = layout;
            this.Widgets.Advanced.lblFocus.Layout.Row = 1;
            this.Widgets.Advanced.lblFocus.Layout.Column = 1;
            this.Widgets.Advanced.txtFocus.Parent = layout;
            this.Widgets.Advanced.txtFocus.Layout.Row = 1;
            this.Widgets.Advanced.txtFocus.Layout.Column = 2;
            this.Widgets.Advanced.lblFreqUnit.Parent = layout;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 1;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 3;
                                
            % Scaling
            lblScaling = uilabel(layout);
            lblScaling.Text = sprintf('%s',getString(message('Control:systunegui:RejectionSpecSignalScaling')));
            lblScaling.Layout.Row = 2;
            lblScaling.Layout.Column = 1;
            items = {getString(message('Control:systunegui:YesLabel')),...
                getString(message('Control:systunegui:NoLabel'))};
            cmbYesNo = uidropdown(layout,'Items',items);
            cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            cmbYesNo.Layout.Row = 2;
            cmbYesNo.Layout.Column = [2 3];
            
            % Apply goal to
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 3;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.Sensitivity = struct(...
                'lblMaxSensitivity',      lblMaxSensitivity, ...
                'txtMaxSensitivity',      txtMaxSensitivity,...
                'pnlOptions',             pnlOptions,...
                'pnlSensitivity',         pnlSensitivity,...
                'lblScaling',             lblScaling,...
                'cmbYesNo',               cmbYesNo);
            
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value
            this.Widgets.Sensitivity.txtMaxSensitivity.Value = Value.MetaData.MaxSensitivity;
            
            if strcmp(Value.Data.LoopScaling ,'on')
                this.Widgets.Sensitivity.cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            else
                this.Widgets.Sensitivity.cmbYesNo.Value = getString(message('Control:systunegui:NoLabel'));
            end
        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            this.Widgets.Sensitivity.txtMaxSensitivity.ValueChangedFcn = ...
                @(hSrc, hData)cbMaxSensitivityEdit(this, this.Widgets.Sensitivity.txtMaxSensitivity.Value);
            this.Widgets.Sensitivity.cmbYesNo.ValueChangedFcn = ...
                @(hSrc,hData) cbCmbYesNoChange(this);
        end

    end
end
