classdef (Hidden) WeightedVarianceSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Wighted Variance tuning goal specifications

    % Copyright 2013-2021 The MathWorks, Inc

    methods
        function this = WeightedVarianceSpecGC(tcpeer)
            %Call parent constructor
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
            
            %% Weights panel
            accWeights = matlab.ui.container.internal.Accordion('Parent',container);
            pnlWeights = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accWeights);
            pnlWeights.Title = getString(message('Control:systunegui:WeightedGainSpecWeights'));
            weightsLayout = uigridlayout(pnlWeights,'RowHeight',{'fit','fit'},...
                'ColumnWidth',{'fit','1x'},'Padding',0);
            
            %% Weights Panel
            % WL
            lblWL = uilabel(weightsLayout);
            lblWL.Text = getString(message('Control:systunegui:WeightedSpecLeftVariance'));
            lblWL.Tag = 'lblWL';
            lblWL.Layout.Row = 1;
            lblWL.Layout.Column = 1;
            txtWL = uieditfield(weightsLayout);
            txtWL.Tag = 'txtWL';
            txtWL.Layout.Row = 1;
            txtWL.Layout.Column = 2;

            % WR
            lblWR = uilabel(weightsLayout);
            lblWR.Text = getString(message('Control:systunegui:WeightedSpecRightVariance'));
            lblWR.Tag = 'lblWR';
            lblWR.Layout.Row = 2;
            lblWR.Layout.Column = 1;
            txtWR = uieditfield(weightsLayout);
            txtWR.Tag = 'txtWR';
            txtWR.Layout.Row = 2;
            txtWR.Layout.Column = 2;

            %% Options Panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            optsLayout = uigridlayout(pnlOptions,[6 4]);
            optsLayout.Padding = 0;
            optsLayout.RowHeight = {'fit'};
            optsLayout.ColumnWidth = {'1x'};
            
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = optsLayout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 1;
            this.Widgets.Advanced.pnlRadio.Layout.Column = 1;

            %% Store widgets for easy access
            this.Widgets.WeightedVariance = struct(...
                'lblWL',            lblWL, ...
                'txtWL',            txtWL,...
                'lblWR',            lblWR, ...
                'txtWR',            txtWR,...
                'pnlOptions',       pnlOptions, ...
                'pnlWeights',       pnlWeights,...
                'pnl',              container);
        end
        
        function connectUI(this)
            % Add listeners for the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            %Add listeners for the text fields
            this.Widgets.WeightedVariance.txtWL.ValueChangedFcn = ...
                @(hSrc, hData) cbWEdit(this, this.Widgets.WeightedVariance.txtWL.Value, 'L');
            this.Widgets.WeightedVariance.txtWR.ValueChangedFcn = ...
                @(hSrc, hData)cbWEdit(this, this.Widgets.WeightedVariance.txtWR.Value, 'R');
        end
                
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);

            % Update the text fields to the current value
            this.Widgets.WeightedVariance.txtWL.Value = Value.MetaData.WL;
            this.Widgets.WeightedVariance.txtWR.Value = Value.MetaData.WR;
        end
    end

    methods(Access = private)
        function cbWEdit(this,fieldValue, LorR)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setW(this.TCPeer,fieldValue, LorR);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
    end


end
