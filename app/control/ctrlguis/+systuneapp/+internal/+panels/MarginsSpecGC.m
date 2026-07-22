classdef MarginsSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Margins tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(Access = protected)
    end

    methods
        function obj = MarginsSpecGC(tcpeer)
            % Call parent constructor
            obj = obj@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
        end
        
        function updateUI(this)
            update(this);
        end
        
        function cbGainMarginEdit(this,fieldValue)
            % Gain Margin text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % Gain Margin cannot be empty
                    update(this);
                else
                    setGainMargin(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbPhaseMarginEdit(this,fieldValue)
            % Phase margin text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % Phase Margin cannot be empty
                    update(this);
                else
                    setPhaseMargin(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end

        function cbScalingOrderEdit(this,fieldValue)
            % Scaling order text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % Scaling order cannot be empty
                    update(this);
                else
                    setScalingOrder(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
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
            
            %% Desired panels margin
            accDesiredMargins = matlab.ui.container.internal.Accordion('Parent',container);
            pnlDesiredMargins = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accDesiredMargins);
            pnlDesiredMargins.Title = getString(message('Control:systunegui:MarginsSpecDesired'));
            layout = uigridlayout(pnlDesiredMargins,'RowHeight',{'fit','fit'},...
                                    'ColumnWidth',{'fit','1x','fit'},'Padding',0);
            % Gain Margin
            lblGainMargin = uilabel(layout,...
                'Text',getString(message('Control:systunegui:MarginsSpecGainMargin')));
            lblGainMargin.Tag = 'lblGainMargin';
            txtGainMargin = uieditfield(layout);
            txtGainMargin.Tag = 'txtGainMargin';
            lbldB = uilabel(layout,'Text',controllibutils.utXlateUnitsString('dB','short'));
            lbldB.Tag = 'lbldB';
            % Phase Margin
            lblPhaseMargin = uilabel(layout,...
                'Text',getString(message('Control:systunegui:MarginsSpecPhaseMargin')));
            lblPhaseMargin.Tag = 'lblPhaseMargin';
            txtPhaseMargin = uieditfield(layout);
            txtPhaseMargin.Tag = 'txtPhaseMargin';
            lbldeg = uilabel(layout,'Text',controllibutils.utXlateUnitsString('deg','short'));
            lbldeg.Tag = 'lbldeg';
            
            %% Options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layout = uigridlayout(pnlOptions,[3 3]);
            layout.Padding = 0;
            layout.RowHeight = {'fit','fit','fit'};
            layout.ColumnWidth = {'fit','1x','fit'};
            % Scaling
            lblScaling = uilabel(layout,...
                'Text',getString(message('Control:systunegui:MarginsSpecScaling')));
            lblScaling.Layout.Row = 2;
            lblScaling.Layout.Column = 1;
            txtScalingOrder = uieditfield(layout);
            txtScalingOrder.Layout.Row = 2;
            txtScalingOrder.Layout.Column = [2 3];
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
            % Apply goal to
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 3;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.Margins = struct(...
                'lblGainMargin',        lblGainMargin, ...
                'txtGainMargin',        txtGainMargin,...
                'lbldB',                lbldB,...
                'lbldeg',               lbldeg,...
                'lblPhaseMargin',       lblPhaseMargin, ...
                'txtPhaseMargin',       txtPhaseMargin,...
                'pnlDesiredMargins',    pnlDesiredMargins, ...
                'pnl',                  layout, ...
                'lblScaling',           lblScaling, ...
                'txtScalingOrder',      txtScalingOrder,...
                'pnlOptions',           pnlOptions);
        end
        
        function connectUI(this)
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            %Add callbacks for the text fields
            this.Widgets.Margins.txtGainMargin.ValueChangedFcn = ...
                @(es,ed) cbGainMarginEdit(this, this.Widgets.Margins.txtGainMargin.Value);
            this.Widgets.Margins.txtPhaseMargin.ValueChangedFcn = ...
                @(es,ed) cbPhaseMarginEdit(this, this.Widgets.Margins.txtPhaseMargin.Value);
            this.Widgets.Margins.txtScalingOrder.ValueChangedFcn = ...
                @(es,ed) cbScalingOrderEdit(this, this.Widgets.Margins.txtScalingOrder.Value);
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value            
            this.Widgets.Margins.txtGainMargin.Value = mat2str(Value.Data.GainMargin);
            this.Widgets.Margins.txtPhaseMargin.Value = mat2str(Value.Data.PhaseMargin);
            this.Widgets.Margins.txtScalingOrder.Value = mat2str(Value.Data.ScalingOrder);
        end
    end
end
