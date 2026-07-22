classdef (Hidden) ConicSectorSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for ConicSector tuning goal specifications
    
    % Copyright 2015 The MathWorks, Inc.
    properties(Access = protected)
    end

    methods
        function obj = ConicSectorSpecGC(tcpeer)
            % Call parent constructor
            obj = obj@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
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
            
            %% Sector Geometery panel
            accSectorGeometry = matlab.ui.container.internal.Accordion('Parent',container);
            pnlSectorGeometry = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accSectorGeometry);
            pnlSectorGeometry.Title = "Sector Geometry";
            layout = uigridlayout(pnlSectorGeometry,"RowHeight",{'fit'},...
                                "ColumnWidth",{'fit','1x'},"Padding",0);
            lblQ = uilabel(layout);
            lblQ.Text = sprintf('%s',getString(message('Control:systunegui:ConicSectorSpecQ')));
            lblQ.Tag = 'lblQ';
            txtQ = uieditfield(layout);
            txtQ.Tag = 'txtQ';
            
            %% Construct options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layout = uigridlayout(pnlOptions,"RowHeight",{'fit','fit','fit'},...
                                    "ColumnWidth",{'fit','1x','fit'},"Padding",0);
            % Regularization
            lblRegularization = uilabel(layout);
            lblRegularization.Text = getString(message('Control:systunegui:ConicSectorRegularization'));
            lblRegularization.Tag = 'lblRegularization';
            lblRegularization.Layout.Row = 1;
            lblRegularization.Layout.Column = 1;
            txtRegularization = uieditfield(layout);
            txtRegularization.Tag = 'txtRegularization';
            txtRegularization.Layout.Row = 1;
            txtRegularization.Layout.Column = [2 3];
            % Focus
            this.Widgets.Advanced.lblFocus.Parent = layout;
            this.Widgets.Advanced.lblFocus.Layout.Row = 2;
            this.Widgets.Advanced.lblFocus.Layout.Column = 1;
            this.Widgets.Advanced.txtFocus.Parent = layout;
            this.Widgets.Advanced.txtFocus.Layout.Row = 2;
            this.Widgets.Advanced.txtFocus.Layout.Column = 2;
            this.Widgets.Advanced.lblFreqUnit.Parent = layout;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 2;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 3;
            % Apply goal to
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 3;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.ConicSector = struct(...
                'lblQ',                   lblQ, ...
                'txtQ',                   txtQ,...
                'lblRegularization',      lblRegularization, ...
                'txtRegularization',      txtRegularization,...                
                'pnlOptions',             pnlOptions,...
                'pnl',                    pnlSectorGeometry);
            
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value
            this.Widgets.ConicSector.txtQ.Value = Value.MetaData.Q;
            this.Widgets.ConicSector.txtRegularization.Value = Value.MetaData.Regularization;
            this.Widgets.ConicSector.txtModels.Value = mat2str(Value.MetaData.Models);

        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            this.Widgets.ConicSector.txtQ.ValueChangedFcn = ...
                @(hSrc, hData) cbQEdit(this, this.Widgets.ConicSector.txtQ.Value);
            this.Widgets.ConicSector.txtRegularization.ValueChangedFcn = ...
                @(hSrc, hData) cbRegularizationEdit(this, this.Widgets.ConicSector.txtRegularization.Value);        
        end
        
        function cbQEdit(this,fieldValue)
            % Gain text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setQ(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbRegularizationEdit(this,fieldValue)
            % Gain text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setRegularization(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
    end
end
