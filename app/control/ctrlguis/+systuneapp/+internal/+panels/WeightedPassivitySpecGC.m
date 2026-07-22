classdef (Hidden) WeightedPassivitySpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Weighted Passivity tuning goal specifications
    
    % Copyright 2015-2021 The MathWorks, Inc
    properties(Access = protected)
    end

    methods
        function this = WeightedPassivitySpecGC(tcpeer)
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
        
        
        function cbIFPEdit(this,fieldValue)
            % IFP text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setIFP(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(this.Dlg,ME.message);
            end
        end
        
        function cbOFPEdit(this,fieldValue)
            % OFP text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setOFP(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(this.Dlg,ME.message);
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
            layout = uigridlayout(pnlOptions,"RowHeight",{'fit','fit','fit','fit'},...
                                    "ColumnWidth",{'fit','1x','fit'},"Padding",0);
                                
            % IFP
            lblIFP = uilabel(layout);
            lblIFP.Text = sprintf('%s',getString(message('Control:systunegui:WeightedPassivitySpecIFP')));
            lblIFP.Tag = 'lblIFP';
            lblIFP.Layout.Row = 1;
            lblIFP.Layout.Column = 1;
            txtIFP = uieditfield(layout);
            txtIFP.Tag = 'txtIFP';
            txtIFP.Layout.Row = 1;
            txtIFP.Layout.Column = 2;
            
            % OFP
            lblOFP = uilabel(layout);
            lblOFP.Text = sprintf('%s',getString(message('Control:systunegui:WeightedPassivitySpecOFP')));
            lblOFP.Tag = 'lblOFP';
            lblOFP.Layout.Row = 2;
            lblOFP.Layout.Column = 1;
            txtOFP = uieditfield(layout);
            txtOFP.Tag = 'txtOFP';
            txtOFP.Layout.Row = 2;
            txtOFP.Layout.Column = 2;
            
            % Focus
            this.Widgets.Advanced.lblFocus.Parent = layout;
            this.Widgets.Advanced.lblFocus.Layout.Row = 3;
            this.Widgets.Advanced.lblFocus.Layout.Column = 1;
            this.Widgets.Advanced.txtFocus.Parent = layout;
            this.Widgets.Advanced.txtFocus.Layout.Row = 3;
            this.Widgets.Advanced.txtFocus.Layout.Column = 2;
            this.Widgets.Advanced.lblFreqUnit.Parent = layout;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 3;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 3;
            
            % Apply goal to
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 4;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.WeightedPassivity = struct(...
                'lblWL',             lblWL, ...
                'txtWL',             txtWL,...
                'lblWR',             lblWR, ...
                'txtWR',             txtWR,...
                'lblIFP',            lblIFP, ...
                'txtIFP',            txtIFP,...
                'lblOFP',            lblOFP, ...
                'txtOFP',            txtOFP,...
                'pnlOptions',        pnlOptions, ...
                'pnlWeights',        pnlWeights);
            
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            % Update the text fields to the current value            
            this.Widgets.WeightedPassivity.txtWL.Value = Value.MetaData.WL;
            this.Widgets.WeightedPassivity.txtWR.Value = Value.MetaData.WR;
            this.Widgets.WeightedPassivity.txtIFP.Value = Value.MetaData.IFP;
            this.Widgets.WeightedPassivity.txtOFP.Value = Value.MetaData.OFP;
            this.Widgets.WeightedPassivity.txtModels.Value = mat2str(Value.MetaData.Models);

        end
        
        function connectUI(this)
            %Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            this.Widgets.WeightedPassivity.txtWL.ValueChangedFcn = ...
                @(hSrc, hData)cbWEdit(this, this.Widgets.WeightedPassivity.txtWL.Value, 'L');
            this.Widgets.WeightedPassivity.txtWR.ValueChangedFcn = ...
                @(hSrc, hData)cbWEdit(this, this.Widgets.WeightedPassivity.txtWR.Value, 'R');
            this.Widgets.WeightedPassivity.txtIFP.ValueChangedFcn = ...
                @(hSrc,hData) cbIFPEdit(this,this.Widgets.WeightedPassivity.txtIFP.Value);
            this.Widgets.WeightedPassivity.txtOFP.ValueChangedFcn = ...
                @(hSrc,hData) cbOFPEdit(this,this.Widgets.WeightedPassivity.txtOFP.Value);
            
        end
    end
end
