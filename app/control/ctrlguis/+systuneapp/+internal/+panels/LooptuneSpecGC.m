classdef (Hidden) LooptuneSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Looptune goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    
    methods
        function obj = LooptuneSpecGC(tcpeer)
            % Call parent constructor
            obj = obj@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer);
            obj.ShowFocusWidget = false;
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
            
            %% Desired goal panel
            accDesiredGoals = matlab.ui.container.internal.Accordion('Parent',container);
            pnlDesiredGoals = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accDesiredGoals);
            pnlDesiredGoals.Title = getString(message('Control:systunegui:LooptuneSpecDesiredGoals'));
            layout = uigridlayout(pnlDesiredGoals,'RowHeight',{'fit','fit','fit','fit','fit','fit'},...
                                    'ColumnWidth',{20,'fit','1x','fit'},'Padding',0);
            
            % Wc (Target gain crossover region)
            lblWc = uilabel(layout);
            lblWc.Tag = 'lblWc';
            lblWc.Text = getString(message('Control:systunegui:LooptuneSpecWc'));
            lblWc.Layout.Row = 1;
            lblWc.Layout.Column = [1 2];
            txtWc = uieditfield(layout);
            txtWc.Tag = 'txtWc';
            txtWc.Layout.Row = 1;
            txtWc.Layout.Column = 3;
            lblFreqUnit = uilabel(layout);
            lblFreqUnit.Text = sprintf('%s/%s',controllibutils.utXlateUnitsString('rad','short'),...
                this.TCPeer.Data.CDD.getTimeUnitString);
            lblFreqUnit.Tag = 'lblFreqUnit';             
            
            % Gain Margin
            lblGainMargin = uilabel(layout);
            lblGainMargin.Text = getString(message('Control:systunegui:LooptuneSpecGainMargin'));
            lblGainMargin.Tag = 'lblGainMargin';
            lblGainMargin.Layout.Row = 2;
            lblGainMargin.Layout.Column = [1 2];
            txtGainMargin = uieditfield(layout);
            txtGainMargin.Tag = 'txtGainMargin';
            txtGainMargin.Layout.Row = 2;
            txtGainMargin.Layout.Column = 3;
            lbldB = uilabel(layout);
            lbldB.Text = controllibutils.utXlateUnitsString('dB','short');
            lbldB.Tag = 'lbldB';            
            lbldB.Layout.Row = 2;
            lbldB.Layout.Column = 4;
            
            % Phase Margin
            lblPhaseMargin = uilabel(layout);
            lblPhaseMargin.Text = getString(message('Control:systunegui:LooptuneSpecPhaseMargin'));
            lblPhaseMargin.Tag = 'lblPhaseMargin';
            lblPhaseMargin.Layout.Row = 3;
            lblPhaseMargin.Layout.Column = [1 2];
            txtPhaseMargin = uieditfield(layout);
            txtPhaseMargin.Tag = 'txtPhaseMargin'; 
            txtPhaseMargin.Layout.Row = 3;
            txtPhaseMargin.Layout.Column = 3;
            lbldeg = uilabel(layout);
            lbldeg.Text = controllibutils.utXlateUnitsString('deg','short');
            lbldeg.Tag = 'lbldeg';              
            lbldeg.Layout.Row = 3;
            lbldeg.Layout.Column = 4;
            
            % KeepPolesInsideRegion
            lblInsideRegion = uilabel(layout);
            lblInsideRegion.Tag = 'lblInsideRegion';
            lblInsideRegion.Text = getString(message('Control:systunegui:LooptuneSpecKeepConstrained'));            
            lblInsideRegion.Layout.Row = 4;
            lblInsideRegion.Layout.Column = [1 4];
            
            % MinDecay
            lblMinDecay = uilabel(layout);
            lblMinDecay.Text = getString(message('Control:systunegui:LooptuneSpecMinDecay'));
            lblMinDecay.Tag = 'lblMinDecay';
            lblMinDecay.Layout.Row = 5;
            lblMinDecay.Layout.Column = 2;
            txtMinDecay = uieditfield(layout);
            txtMinDecay.Tag = 'txtMinDecay';
            txtMinDecay.Layout.Row = 5;
            txtMinDecay.Layout.Column = [3 4];
            
            % MaxFrequency
            lblMaxFrequency = uilabel(layout);
            lblMaxFrequency.Tag = 'lblMaxFrequency';
            lblMaxFrequency.Text = getString(message('Control:systunegui:LooptuneSpecMaxFrequency'));
            lblMaxFrequency.Layout.Row = 6;
            lblMaxFrequency.Layout.Column = 2;
            txtMaxFrequency = uieditfield(layout);
            txtMaxFrequency.Tag = 'txtMaxFrequency';
            txtMaxFrequency.Layout.Row = 6;
            txtMaxFrequency.Layout.Column = [3 4];
            
            %% Options Panel
             %% Options Panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            optsLayout = uigridlayout(pnlOptions,"RowHeight",{'fit'},...
                                    "ColumnWidth",{'1x'},"Padding",0);
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = optsLayout;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 1;
            this.Widgets.Advanced.pnlRadio.Layout.Column = 1;
            
            %% store widgets for easy access
            this.Widgets.Looptune = struct(...
                'lblWc',            lblWc, ...
                'lblFreqUnit',      lblFreqUnit, ...
                'lblGainMargin',    lblGainMargin, ...
                'lbldB',            lbldB, ...
                'lblPhaseMargin',   lblPhaseMargin, ...
                'lbldeg',           lbldeg, ...
                'lblInsideRegion',  lblInsideRegion, ...
                'lblMinDecay',      lblMinDecay, ...
                'lblMaxFrequency',  lblMaxFrequency, ...
                'pnlDesiredGoals',  pnlDesiredGoals, ...
                'pnlOptions',       pnlOptions, ...
                'txtWc',            txtWc,...
                'txtGainMargin',    txtGainMargin,...
                'txtPhaseMargin',   txtPhaseMargin,...
                'txtMinDecay',      txtMinDecay, ...
                'txtMaxFrequency',  txtMaxFrequency);            
        end   

        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            % Callbacks
            this.Widgets.Looptune.txtWc.ValueChangedFcn = ...
                @(hSrc, hData)cbWcEdit(this, this.Widgets.Looptune.txtWc.Value);
            this.Widgets.Looptune.txtGainMargin.ValueChangedFcn = ...
                @(hSrc, hData)cbGainMarginEdit(this, this.Widgets.Looptune.txtGainMargin.Value);
            this.Widgets.Looptune.txtPhaseMargin.ValueChangedFcn = ...
                @(hSrc, hData)cbPhaseMarginEdit(this, this.Widgets.Looptune.txtPhaseMargin.Value);
            this.Widgets.Looptune.txtMinDecay.ValueChangedFcn = ...
                @(hSrc, hData)cbMinDecayEdit(this, this.Widgets.Looptune.txtMinDecay.Value);
            this.Widgets.Looptune.txtMaxFrequency.ValueChangedFcn = ...
                @(hSrc, hData)cbMaxFrequencyEdit(this, this.Widgets.Looptune.txtMaxFrequency.Value);
        end

        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            %Update the text fields to the current value            
            this.Widgets.Looptune.txtWc.Value = mat2str(Value.Data.Wc);
            this.Widgets.Looptune.txtGainMargin.Value = mat2str(Value.Data.GainMargin);
            this.Widgets.Looptune.txtPhaseMargin.Value = mat2str(Value.Data.PhaseMargin);
            this.Widgets.Looptune.txtMinDecay.Value = mat2str(Value.Data.MinDecay);                        
            this.Widgets.Looptune.txtMaxFrequency.Value = mat2str(Value.Data.MaxFrequency);            
            this.Widgets.Looptune.txtModels.Value = mat2str(Value.MetaData.Models);
        end
        
        function cleanupGUI(this)
            this.Widgets = [];
        end
    end
    
    methods(Access = private)
         %% GUI Listener callbacks
        function cbWcEdit(this, fieldValue)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                setWc(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbGainMarginEdit(this, fieldValue)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setGainMargin(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbPhaseMarginEdit(this, fieldValue)
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setPhaseMargin(this.TCPeer,fieldValue);
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
    end
    
    methods (Hidden)
        function Widgets = qeGetWidgets(this)
            Widgets = this.Widgets;
        end    
    end
    
end
