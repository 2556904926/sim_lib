classdef (Hidden) LQGSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for LQG tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    
    methods
        function this = LQGSpecGC(tcpeer)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
            this.ShowFocusWidget = false;
        end
        
        function updateUI(this)
            update(this);
        end

        %% GUI Listener callbacks
        function cbPerformanceWeightEdit(this, fieldValue)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setPerformanceWeight(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbNoiseCovarianceEdit(this, fieldValue)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setNoiseCovariance(this.TCPeer,fieldValue);
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
            
            %% LQG Objective panel
            accObjective = matlab.ui.container.internal.Accordion('Parent',container);
            pnlObjective = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accObjective);
            pnlObjective.Title = getString(message('Control:systunegui:LQGSpecObjective'));
            layout = uigridlayout(pnlObjective,"RowHeight",{'fit','fit'},...
                                "ColumnWidth",{'fit','1x'},"Padding",0);
                            
            % Performance Weight
            lblPerformanceWeight = uilabel(layout);
            lblPerformanceWeight.Text = sprintf('%s: ',getString(message('Control:systunegui:LQGSpecPerformanceWeight')));
            lblPerformanceWeight.Tag = 'lblPerformanceWeight';
            lblPerformanceWeight.Layout.Row = 1;
            lblPerformanceWeight.Layout.Column = 1;
            txtPerformanceWeight = uieditfield(layout);
            txtPerformanceWeight.Tag = 'txtPerformanceWeight';
            txtPerformanceWeight.Layout.Row = 1;
            txtPerformanceWeight.Layout.Column = 2;
            
            % Noise Covariance
            lblNoiseCovariance = uilabel(layout);
            lblNoiseCovariance.Text = sprintf('%s: ',getString(message('Control:systunegui:LQGSpecNoiseCovariance')));
            lblNoiseCovariance.Tag = 'lblNoiseCovariance';
            lblNoiseCovariance.Layout.Row = 2;
            lblNoiseCovariance.Layout.Column = 1;
            txtNoiseCovariance = uieditfield(layout);
            txtNoiseCovariance.Tag = 'txtNoiseCovariance';
            txtNoiseCovariance.Layout.Row = 2;
            txtNoiseCovariance.Layout.Column = 2;
            
            %% Construct options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layout = uigridlayout(pnlOptions,"RowHeight",{'fit'},...
                                    "ColumnWidth",{'fit','1x'},"Padding",0);
            
            % Apply goal to
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 1;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 2];
            
            %% Store widgets for easy access
            this.Widgets.LQG = struct(...
                'lblPerformanceWeight', lblPerformanceWeight, ...
                'txtPerformanceWeight', txtPerformanceWeight,...
                'lblNoiseCovariance',   lblNoiseCovariance, ...
                'txtNoiseCovariance',   txtNoiseCovariance,...
                'pnlObjective',         pnlObjective,...
                'pnlOptions',           pnlOptions);
            
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value            
            this.Widgets.LQG.txtPerformanceWeight.Value = mat2str(Value.Data.PerformanceWeight);
            this.Widgets.LQG.txtNoiseCovariance.Value = mat2str(Value.Data.NoiseCovariance);
            this.Widgets.LQG.txtModels.Value = mat2str(Value.MetaData.Models);
        end
        
        function connectUI(this)
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            %Add callbacks for the edit fields
            this.Widgets.LQG.txtPerformanceWeight.ValueChangedFcn = ...
                @(hSrc,hData) cbPerformanceWeightEdit(this, this.Widgets.LQG.txtPerformanceWeight.Value);
            this.Widgets.LQG.txtNoiseCovariance.ValueChangedFcn = ...
                @(hSrc,hData) cbNoiseCovarianceEdit(this, this.Widgets.LQG.txtNoiseCovariance.Value);

        end
    end
    
end
