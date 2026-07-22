classdef StableControllerSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Stable Controller tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc

    methods
        function this = StableControllerSpecGC(tcpeer)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
            this.ShowFocusWidget = false;
            this.ShowModelsWidget = false;
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
            container = uigridlayout([1 1],'Parent',[],'Padding',0);
            container.RowHeight = {'fit'};
            
            %% Pole Location panel
            accPoleLocation = matlab.ui.container.internal.Accordion('Parent',container);
            pnlPoleLocation = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accPoleLocation);
            pnlPoleLocation.Title = ...
                getString(message('Control:systunegui:PolesSpecDesired'));
            layoutPoleLocation = uigridlayout(pnlPoleLocation,...
                'RowHeight',{'fit','fit','fit','fit'},'ColumnWidth',{'fit','1x'},'Padding',0);
            
            %% Desired region for poles panel
            lblSpecHeading =uilabel(layoutPoleLocation);
            lblSpecHeading.Tag = 'lblSpecHeading';
            lblSpecHeading.Text = getString(message('Control:systunegui:PolesSpecKeepConstrained'));
            lblSpecHeading.Layout.Row = 1;
            lblSpecHeading.Layout.Column = [1 2];
            
            % MinDecay
            lblMinDecay = uilabel(layoutPoleLocation);
            lblMinDecay.Text = getString(message('Control:systunegui:PolesSpecMinDecay'));
            lblMinDecay.Tag = 'lblMinDecay';
            lblMinDecay.Layout.Row = 2;
            lblMinDecay.Layout.Column = 1;
            txtMinDecay = uieditfield(layoutPoleLocation);
            txtMinDecay.Tag = 'txtMinDecay';            
            txtMinDecay.Layout.Row = 2;
            txtMinDecay.Layout.Column = 2;
            
            % MinDamping
            lblMinDamping = uilabel(layoutPoleLocation);
            lblMinDamping.Text = getString(message('Control:systunegui:PolesSpecMinDamping'));
            lblMinDamping.Tag = 'lblMinDamping';
            lblMinDamping.Layout.Row = 3;
            lblMinDamping.Layout.Column = 1;
            txtMinDamping = uieditfield(layoutPoleLocation);
            txtMinDamping.Tag = 'txtMinDamping';
            txtMinDamping.Layout.Row = 3;
            txtMinDamping.Layout.Column = 2;
            
            % MaxFrequency
            lblMaxFrequency = uilabel(layoutPoleLocation);
            lblMaxFrequency.Tag = 'lblMaxFrequency';
            lblMaxFrequency.Text = getString(message('Control:systunegui:PolesSpecMaxFrequency'));
            lblMaxFrequency.Layout.Row = 4;
            lblMaxFrequency.Layout.Column = 1;
            txtMaxFrequency = uieditfield(layoutPoleLocation);
            txtMaxFrequency.Tag = 'txtMaxFrequency';
            txtMaxFrequency.Layout.Row = 4;
            txtMaxFrequency.Layout.Column = 2;

            %% Store widgets for easy access
            this.Widgets.StableController = struct(...
                'lblMinDecay',          lblMinDecay, ...
                'txtMinDecay',          txtMinDecay,...
                'lblMinDamping',        lblMinDamping, ...
                'txtMinDamping',        txtMinDamping,...                
                'lblMaxFrequency',      lblMaxFrequency, ...
                'txtMaxFrequency',      txtMaxFrequency,...
                'lblSpecHeading',       lblSpecHeading, ...
                'pnl',                  pnlPoleLocation,...
                'layout',               layoutPoleLocation);
        end
        
        function connectUI(this)
             % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            % GUI listeners
            this.Widgets.StableController.txtMinDecay.ValueChangedFcn = ...
                @(hSrc, hData)cbMinDecayEdit(this, this.Widgets.StableController.txtMinDecay.Value);
            this.Widgets.StableController.txtMinDamping.ValueChangedFcn = ...
                @(hSrc, hData)cbMinDampingEdit(this, this.Widgets.StableController.txtMinDamping.Value);
            this.Widgets.StableController.txtMaxFrequency.ValueChangedFcn = ...
                @(hSrc, hData)cbMaxFrequencyEdit(this, this.Widgets.StableController.txtMaxFrequency.Value);
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            % Update the text fields to the current value
            this.Widgets.StableController.txtMinDecay.Value = mat2str(Value.Data.MinDecay);
            this.Widgets.StableController.txtMinDamping.Value = mat2str(Value.Data.MinDamping);
            this.Widgets.StableController.txtMaxFrequency.Value = mat2str(Value.Data.MaxFrequency);            
        end
    end
    
    methods(Access = private)
        function cbMinDecayEdit(this,fieldValue)
            % MinDecay text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MinDecay cannot be empty
                    update(this);
                else
                    setMinDecay(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end    
        
        function cbMinDampingEdit(this,fieldValue)
            % MinDecay text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MinDecay cannot be empty
                    update(this);
                else
                    setMinDamping(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end         
        
        function cbMaxFrequencyEdit(this,fieldValue)
            % MaxFrequency text editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % MaxFrequency cannot be empty
                    update(this);
                else
                    setMaxFrequency(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end  
    end
end
