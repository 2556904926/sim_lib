classdef WeightedGainSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Wighted Gain tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(Access = protected)
    end

    methods
        function this = WeightedGainSpecGC(tcpeer)
            %Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
        end
        
        function updateUI(this)
            update(this);
        end

        function cbWEdit(this,fieldValue, LorR)
            % WL and WR text field editors
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setW(this.TCPeer,fieldValue, LorR);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(this.Dlg,ME.message);
            end
        end
        
        function cbStabilizeEdit(this)
            % Stabilize text field editor
            switch this.Widgets.WeightedGain.cmbYesNoStabilize.Value
                case getString(message('Control:systunegui:YesLabel'))
                    setStabilize(this.TCPeer,1);
                case getString(message('Control:systunegui:NoLabel'))
                    setStabilize(this.TCPeer,0);
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
            
            %% Weights Panel
            accWeights = matlab.ui.container.internal.Accordion('Parent',container);
            pnlWeights= matlab.ui.container.internal.AccordionPanel(...
                'Parent',accWeights);
            pnlWeights.Title = getString(message('Control:systunegui:WeightedGainSpecWeights'));
            layout = uigridlayout(pnlWeights,"RowHeight",{'fit','fit'},...
                                "ColumnWidth",{'fit','1x'},"Padding",0);
                            
            % WL
            lblWL = uilabel(layout);
            lblWL.Text = sprintf('%s: ',getString(message('Control:systunegui:WeightedSpecLeftGain')));
            lblWL.Tag = 'lblWL';
            lblWL.Layout.Row = 1;
            lblWL.Layout.Column = 1;
            txtWL = uieditfield(layout);
            txtWL.Tag = 'txtWL';
            txtWL.Layout.Row = 1;
            txtWL.Layout.Column = 2;
            
            % WR
            lblWR = uilabel(layout);
            lblWR.Text = sprintf('%s: ',getString(message('Control:systunegui:WeightedSpecRightGain')));
            lblWR.Tag = 'lblWR';
            lblWR.Layout.Row = 2;
            lblWR.Layout.Column = 1;
            txtWR = uieditfield(layout);
            txtWR.Tag = 'txtWR';
            txtWR.Layout.Row = 2;
            txtWR.Layout.Column = 2;
            
            %% Construct options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layout = uigridlayout(pnlOptions,"RowHeight",{'fit','fit','fit'},...
                                    "ColumnWidth",{'fit','1x','fit'},"Padding",0);
                                
            % Stabilize
            lblStabilize = uilabel(layout);
            lblStabilize.Text = sprintf('%s',getString(message('Control:systunegui:GainSpecStabilize')));
            lblStabilize.Layout.Row = 1;
            lblStabilize.Layout.Column = 1;
            items = {getString(message('Control:systunegui:YesLabel')),...
                getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoStabilize = uidropdown(layout,'Items',items);
            cmbYesNoStabilize.Value = getString(message('Control:systunegui:YesLabel'));
            cmbYesNoStabilize.Layout.Row = 1;
            cmbYesNoStabilize.Layout.Column = [2 3];
            
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
            this.Widgets.WeightedGain = struct(...
                'lblWL',             lblWL, ...
                'txtWL',             txtWL,...
                'lblWR',             lblWR, ...
                'txtWR',             txtWR,...
                'lblStabilize',      lblStabilize, ...
                'cmbYesNoStabilize', cmbYesNoStabilize,...
                'pnlOptions',        pnlOptions, ...
                'pnlWeights',        pnlWeights);
            
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value            
            this.Widgets.WeightedGain.txtWL.Value = Value.MetaData.WL;
            this.Widgets.WeightedGain.txtWR.Value = Value.MetaData.WR;

            % Update stabilize combo box
            if Value.Data.Stabilize
                this.Widgets.WeightedGain.cmbYesNoStabilize.Value = getString(message('Control:systunegui:YesLabel'));
            else
                this.Widgets.WeightedGain.cmbYesNoStabilize.Value = getString(message('Control:systunegui:NoLabel'));
            end
        end
        
        function connectUI(this)
            %Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            this.Widgets.WeightedGain.txtWL.ValueChangedFcn = ...
                @(hSrc, hData)cbWEdit(this, this.Widgets.WeightedGain.txtWL.Value, 'L');
            this.Widgets.WeightedGain.txtWR.ValueChangedFcn = ...
                @(hSrc, hData)cbWEdit(this, this.Widgets.WeightedGain.txtWR.Value, 'R');
            this.Widgets.WeightedGain.cmbYesNoStabilize.ValueChangedFcn = ...
                @(hSrc, hData)cbStabilizeEdit(this);
        end
    end
end
