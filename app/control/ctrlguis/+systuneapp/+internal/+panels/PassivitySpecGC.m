classdef (Hidden) PassivitySpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Passivity tuning goal specifications
    
    % Copyright 2015-2021 The MathWorks, Inc.
    properties(Access = protected)
    end

    methods
        function this = PassivitySpecGC(tcpeer)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
        end
        
        function updateUI(this)
            update(this);
        end
        
        function cbIFPEdit(this,fieldValue)
            % Gain text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setIFP(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbOFPEdit(this,fieldValue)
            % Gain text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setOFP(this.TCPeer,fieldValue);
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
            container.RowHeight = {'fit'};
            
            %% Passivity Index Panel
            accPassivity = matlab.ui.container.internal.Accordion('Parent',container);
            pnlPassivity = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accPassivity);
            pnlPassivity.Title = getString(message('Control:systunegui:PassivitySpecIOIndex'));
            layout = uigridlayout(pnlPassivity,"RowHeight",{'fit','fit'},...
                                "ColumnWidth",{'fit','1x'},"Padding",0);
            % IFP
            lblIFP = uilabel(layout);
            lblIFP.Text = sprintf('%s',getString(message('Control:systunegui:PassivitySpecIFP')));
            lblIFP.Tag = 'lblIFP';
            lblIFP.Layout.Row = 1;
            lblIFP.Layout.Column = 1;
            txtIFP = uieditfield(layout);
            txtIFP.Tag = 'txtIFP';
            txtIFP.Layout.Row = 1;
            txtIFP.Layout.Column = 2;
            
            % OFP
            lblOFP = uilabel(layout);
            lblOFP.Text = sprintf('%s',getString(message('Control:systunegui:PassivitySpecOFP')));
            lblOFP.Tag = 'lblOFP';
            lblOFP.Layout.Row = 2;
            lblOFP.Layout.Column = 1;
            txtOFP = uieditfield(layout);
            txtOFP.Tag = 'txtOFP';
            txtOFP.Layout.Row = 2;
            txtOFP.Layout.Column = 2;
            
            %% Construct options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layout = uigridlayout(pnlOptions,"RowHeight",{'fit','fit'},...
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
            
            % Apply goal to
            this.Widgets.Advanced.pnlRadio.Parent = layout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 2;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.Passivity = struct(...
                'lblIFP',                   lblIFP, ...
                'txtIFP',                   txtIFP,...
                'lblOFP',                   lblOFP, ...
                'txtOFP',                   txtOFP,...
                'pnlPassivity',             pnlPassivity,...
                'pnlOptions',               pnlOptions);
            
        end        
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value
            this.Widgets.Passivity.txtIFP.Value = Value.MetaData.IFP;
            this.Widgets.Passivity.txtOFP.Value = Value.MetaData.OFP;
        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            this.Widgets.Passivity.txtIFP.ValueChangedFcn = ...
                @(hSrc,hData) cbIFPEdit(this,this.Widgets.Passivity.txtIFP.Value);
            this.Widgets.Passivity.txtOFP.ValueChangedFcn = ...
                @(hSrc,hData) cbOFPEdit(this,this.Widgets.Passivity.txtOFP.Value);
        end
    end
end
