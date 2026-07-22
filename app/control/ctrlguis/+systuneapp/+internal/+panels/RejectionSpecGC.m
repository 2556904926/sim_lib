classdef RejectionSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Rejection tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc

    properties(Access = protected)
    end

    methods
        function obj = RejectionSpecGC(tcpeer)
            % Call parent constructor
            obj = obj@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
        end

        function updateUI(this)
            update(this);
        end
        
        function cbMinAttenuationEdit(this,fieldValue)
            % MinAttenuation text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MinAttenuation cannot be empty
                    update(this);
                else
                    setMinAttenuation(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(this.Dlg,ME.message);
            end
        end

        function cbCmbYesNoChange(this)
            switch this.Widgets.Rejection.cmbYesNo.Value
                case getString(message('Control:systunegui:YesLabel'))
                    setLoopScaling(this.TCPeer,'on');
                case getString(message('Control:systunegui:NoLabel'))
                    setLoopScaling(this.TCPeer,'off');
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
            
            %% Rejection performance panel
            accPerformance = matlab.ui.container.internal.Accordion('Parent',container);
            pnlPerformance = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accPerformance);
            pnlPerformance.Title = ...
                getString(message('Control:systunegui:RejectionSpecPerformance'));
            performanceLayout = uigridlayout(pnlPerformance,'RowHeight',{'fit','fit'},...
                                    'ColumnWidth',{'1x'});
            % MinAttenuation
            lblMinAttenuation = uilabel(performanceLayout);
            lblMinAttenuation.Text = getString(message('Control:systunegui:RejectionSpecMinAttenuation'));
            txtMinAttenuation = uieditfield(performanceLayout);
            txtMinAttenuation.Tag = 'txtMinAttenuation';
            
            %% Options panel
            % Cross-over Tolerance
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;

            layout = uigridlayout(pnlOptions,[4 3]);
            layout.RowHeight = {'fit','fit','fit','fit'};
            layout.ColumnWidth = {'fit','1x','fit'};
            %LoopScaling
            lblScaling = uilabel(layout);
            lblScaling.Text = sprintf('%s',getString(message('Control:systunegui:RejectionSpecSignalScaling')));
            lblScaling.Layout.Row = 2;
            lblScaling.Layout.Column = 1;
            items = {getString(message('Control:systunegui:YesLabel')), getString(message('Control:systunegui:NoLabel'))};
            cmbYesNo = uidropdown(layout,'Items',items);
            cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            cmbYesNo.Layout.Row = 2;
            cmbYesNo.Layout.Column = [2 3];
            
            this.Widgets.Advanced.lblFocus.Parent = layout;
            this.Widgets.Advanced.lblFocus.Layout.Row = 1;
            this.Widgets.Advanced.lblFocus.Layout.Column = 1;
            this.Widgets.Advanced.txtFocus.Parent = layout;
            this.Widgets.Advanced.txtFocus.Layout.Row = 1;
            this.Widgets.Advanced.txtFocus.Layout.Column = 2;
            this.Widgets.Advanced.lblFreqUnit.Parent = layout;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 1;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 3;
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 3;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.Rejection = struct(...
                'lblMinAttenuation',      lblMinAttenuation, ...
                'txtMinAttenuation',      txtMinAttenuation,...
                'pnl',                    container,...
                'pnlOptions',             pnlOptions,...
                'lblScaling',             lblScaling,...
                'pnlPerformance',         pnlPerformance,...
                'cmbYesNo',               cmbYesNo);
           
        end
        
        function connectUI(this)
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            %Add call callbacks the text fields
            this.Widgets.Rejection.txtMinAttenuation.ValueChangedFcn = ...
                @(hSrc, hData)cbMinAttenuationEdit(this, this.Widgets.Rejection.txtMinAttenuation.Value);
            this.Widgets.Rejection.cmbYesNo.ValueChangedFcn = ...
                @(hSrc,hData) cbCmbYesNoChange(this);
        end
        
        function update(this)   
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            % Update the text fields to the current value            
            this.Widgets.Rejection.txtMinAttenuation.Value = Value.MetaData.MinAttenuation;
            
            if strcmp(Value.Data.LoopScaling,'on')
                this.Widgets.Rejection.cmbYesNo.Value = getString(message('Control:systunegui:YesLabel'));
            else
                this.Widgets.Rejection.cmbYesNo.Val = getStrueing(message('Control:systunegui:NoLabel'));
            end
        end
    end
        

end
