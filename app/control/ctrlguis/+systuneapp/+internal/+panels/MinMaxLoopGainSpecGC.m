classdef MinMaxLoopGainSpecGC < systuneapp.internal.panels.GainSpecGC
    % Graphical component for Minimum and Maximum Loop Gain tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(Access = protected)       
    end
    
    methods
        function obj = MinMaxLoopGainSpecGC(tcpeer)
            % Call parent constructor    
            obj = obj@systuneapp.internal.panels.GainSpecGC(tcpeer);
        end
        
        function cbFEdit(this,fieldValue)
            % Fmax or Fmin text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % F cannot be empty
                    update(this);
                else
                    setF(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbGEdit(this,fieldValue)
            % Gmax or Gmin text field editor
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % G cannot be empty
                    update(this);
                else
                    setG(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
            end
        end
        
        function cbYesNoScalingEdit(this)
            % update TC's LoopScaling when scaling combo box changes
            switch this.Widgets.Gain.cmbYesNoScaling.Value
                case getString(message('Control:systunegui:YesLabel'))
                    setLoopScaling(this.TCPeer,'on');
                case getString(message('Control:systunegui:NoLabel'))
                    setLoopScaling(this.TCPeer,'off');
            end
        end
       
                  
        function cbRadioGain(this, hData)
           % Switch the state of the flag and call update to swap the panels
           this.TCPeer.MetaData.EnableGain = strcmp(hData.NewValue.Tag,'radioGain');
           
           if this.TCPeer.MetaData.EnableGain
               cbGainEdit(this, this.Widgets.Gain.txtGain.Value);
           else
               cbFEdit(this, this.Widgets.MinMaxLoopGain.txtFmax.Value);
               cbGEdit(this, this.Widgets.MinMaxLoopGain.txtGmax.Value);
           end
           update(this);
           update(this.TCPeer.Data);
        end
        
    end
    
    methods(Access = protected)
        function container = createContainer(this)
            %% Desired loop gain panel
            
            % Call parent's create panel for Gain, focus and models related
            % widgets.
            container = createContainer@systuneapp.internal.panels.GainSpecGC(this);
            
            % Change gridlayout size of Gain section
            this.Widgets.Gain.layoutGain.RowHeight = {'fit','fit','fit'};
            this.Widgets.Gain.layoutGain.ColumnWidth = {'fit','1x','fit'};
            this.Widgets.Gain.lblGain.Layout.Row = 2;
            this.Widgets.Gain.lblGain.Layout.Column = 1;
            this.Widgets.Gain.txtGain.Layout.Row = 2;
            this.Widgets.Gain.txtGain.Layout.Column = [2 3];
            
            % Change title
            this.Widgets.Gain.pnlLimitGain.Title = ...
                getString(message('Control:systunegui:MinMaxLoopGainSpecDesired'));
            % Change label according to type of Tuning Goal
            if strcmp(this.TCPeer.Data.Type, 'MinLoopGain')
                this.Widgets.Gain.lblGain.Text = ...
                    getString(message('Control:systunegui:MinLoopGainSpecLoopGain'));
            else
                this.Widgets.Gain.lblGain.Text = ...
                    getString(message('Control:systunegui:MaxLoopGainSpecLoopGain'));
            end

            % Fmax
            lblFmax = uilabel(this.Widgets.Gain.layoutGain);
            lblFmax.Text = getString(message('Control:systunegui:MinMaxLoopGainSpecFrequency'));
            lblFmax.Tag = 'lblFmax';
            lblFmax.Layout.Row = 3;
            lblFmax.Layout.Column = 1;
            txtFmax = uieditfield(this.Widgets.Gain.layoutGain);
            txtFmax.Tag = 'txtFmax';
            txtFmax.Layout.Row = 3;
            txtFmax.Layout.Column = 2;
            lblFreqUnit = uilabel(this.Widgets.Gain.layoutGain);
            lblFreqUnit.Text = sprintf('%s/%s',controllibutils.utXlateUnitsString('rad','short'),this.TCPeer.Data.CDD.getTimeUnitString);
            lblFreqUnit.Tag = 'lblFreqUnit';
            lblFreqUnit.Layout.Row = 3;
            lblFreqUnit.Layout.Column = 3;
                      
            % Gmax
            lblGmax = uilabel(this.Widgets.Gain.layoutGain);
            lblGmax.Tag = 'lblGmax';
            lblGmax.Layout.Row = 2;
            lblGmax.Layout.Column = 1;
            
            % Change label according to type of Tuning Goal
            if strcmp(this.TCPeer.Data.Type, 'MinLoopGain')
                lblGmax.Text = getString(message('Control:systunegui:MinLoopGainSpecGain'));
            else
                lblGmax.Text = getString(message('Control:systunegui:MaxLoopGainSpecGain'));
            end
            txtGmax = uieditfield(this.Widgets.Gain.layoutGain);
            txtGmax.Tag = 'txtGmax';
            txtGmax.Layout.Row = 2;
            txtGmax.Layout.Column = 2;
            
            %% For radio buttons
            % Specify Label
            lblSpecify = uilabel('Parent',[]);
            lblSpecify.Text = getString(message('Control:systunegui:TuningGoalSpecSpecify'));
            
            % Button group with the two radio buttons
            btnGroupError = uibuttongroup('Parent',[]);
            btnGroupError.BorderType = 'none';
            
            % Radio buttons to choose between all models or specific models
            radioFG = uiradiobutton('Parent',btnGroupError);
            radioFG.Tag = 'radioFG';
            radioFG.Text = getString(message('Control:systunegui:MinMaxLoopGainSpecGainAtFrequency'));
            radioFG.Position = [10 35 165 25];
            
            radioGain = uiradiobutton('Parent',btnGroupError);
            radioGain.Text =  getString(message('Control:systunegui:MinMaxLoopGainSpecGainProfile'));
            radioGain.Tag = 'radioGain';
            radioGain.Position = [10 5 165 25];
            radioGain.Value = false;
            
            % Construct panel with radio buttons (related to Models)
            pnlRadio = uigridlayout('Parent',this.Widgets.Gain.layoutGain,'RowHeight',{'fit',25,25},...
                'ColumnWidth',{'1x'});
            pnlRadio.Padding = 0;
            pnlRadio.Layout.Row = 1;
            pnlRadio.Layout.Column = [1 3];
            lblSpecify.Parent = pnlRadio;
            lblSpecify.Layout.Row = 1;
            lblSpecify.Layout.Column = 1;
            btnGroupError.Parent = pnlRadio;
            btnGroupError.Layout.Row = [2 3];
            btnGroupError.Layout.Column = 1;

            %% Options panel
            % Scaling Widgets
            this.Widgets.Gain.lblScaling.Text = ...
                getString(message('Control:systunegui:LoopShapeSpecScaling'));
            this.Widgets.Gain.lblStabilize.Text = ...
                getString(message('Control:systunegui:LoopShapeSpecStabilize'));
            
            this.Widgets.Gain.layoutOptions.RowHeight{4} = 0;
            this.Widgets.Gain.layoutOptions.RowHeight{5} = 0;
            
            %% Store widgets for easy access
            this.Widgets.MinMaxLoopGain = struct(...
                'lblFmax',            lblFmax, ...
                'txtFmax',            txtFmax, ...
                'lblFreqUnit',        lblFreqUnit, ...
                'lblGmax',            lblGmax, ...
                'txtGmax',            txtGmax, ...
                'radioFG',            radioFG,...
                'radioGain',          radioGain,...
                'btnGroupError',      btnGroupError, ...
                'pnl',                this.Widgets.Gain.pnlOptions, ...
                'pnlGain',            this.Widgets.Gain.pnlLimitGain,...
                'pnlOptions',         this.Widgets.Gain.pnlOptions,...
                'pnlDesiredLoopGain', this.Widgets.Gain.pnlLimitGain);           
        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GainSpecGC(this);
           
            this.Widgets.MinMaxLoopGain.txtFmax.ValueChangedFcn = ...
                @(hSrc, hData) cbFEdit(this, this.Widgets.MinMaxLoopGain.txtFmax.Value);
            this.Widgets.MinMaxLoopGain.txtGmax.ValueChangedFcn = ...
                @(hSrc, hData) cbGEdit(this, this.Widgets.MinMaxLoopGain.txtGmax.Value);
            this.Widgets.MinMaxLoopGain.btnGroupError.SelectionChangedFcn = ...
                @(hSrc, hData) cbRadioGain(this,hData);
        end
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            % Add/ remove contents of performance panel depending on radio button selection
            if this.TCPeer.MetaData.EnableGain == true
                this.Widgets.MinMaxLoopGain.lblGmax.Visible = false;
                this.Widgets.MinMaxLoopGain.txtGmax.Visible = false;
                this.Widgets.MinMaxLoopGain.lblFmax.Visible = false;
                this.Widgets.MinMaxLoopGain.txtFmax.Visible = false;
                this.Widgets.MinMaxLoopGain.lblFreqUnit.Visible = false;
                this.Widgets.Gain.layoutGain.RowHeight{3} = 0;
                
                this.Widgets.Gain.lblGain.Visible = true;
                this.Widgets.Gain.txtGain.Visible = true;
                
                this.Widgets.MinMaxLoopGain.radioGain.Value = true;
            else
                this.Widgets.MinMaxLoopGain.lblGmax.Visible = true;
                this.Widgets.MinMaxLoopGain.txtGmax.Visible = true;
                this.Widgets.MinMaxLoopGain.lblFmax.Visible = true;
                this.Widgets.MinMaxLoopGain.txtFmax.Visible = true;
                this.Widgets.MinMaxLoopGain.lblFreqUnit.Visible = true;
                this.Widgets.Gain.layoutGain.RowHeight{3} = 'fit';
                
                this.Widgets.Gain.lblGain.Visible = false;
                this.Widgets.Gain.txtGain.Visible = false;
                
                this.Widgets.MinMaxLoopGain.radioFG.Value = true;
            end
            
            % Update the text fields to the current value
            this.Widgets.Gain.txtGain.Value = Value.MetaData.Gain;
            this.Widgets.MinMaxLoopGain.txtFmax.Value = mat2str(Value.MetaData.F);
            this.Widgets.MinMaxLoopGain.txtGmax.Value = mat2str(Value.MetaData.G);
            
            % Update stabilize combo box
            if Value.Data.Stabilize
                this.Widgets.Gain.cmbYesNoStabilize.Value = ...
                    getString(message('Control:systunegui:YesLabel'));
            else
                this.Widgets.Gain.cmbYesNoStabilize.Value = ...
                    getString(message('Control:systunegui:NoLabel'));
            end

            % Update loop scaling combo box
            if strcmp(Value.Data.LoopScaling,'off')
                this.Widgets.Gain.cmbYesNoScaling.Value = ...
                    getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.Gain.cmbYesNoScaling.Value = ...
                    getString(message('Control:systunegui:YesLabel'));
            end 
        end
        
        function cleanupGUI(this)
            this.Widgets = [];
        end
    end
    
end
