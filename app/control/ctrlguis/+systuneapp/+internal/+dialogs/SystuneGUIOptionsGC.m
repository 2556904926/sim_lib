classdef (Hidden) SystuneGUIOptionsGC < controllib.ui.internal.dialog.AbstractDialog
    % Graphical component for options of Control System Tuner App.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties
        TCPeer
        
        RandomStartCheckbox
        RandomStartEditField
        ParallelCheckbox
        SoftTargetCheckbox
        SoftTargetEditField
        DisplayCheckbox
        DisplayDropdown
        
        OptionLabels = {'final',getString(message(...
            'Control:systunegui:SystuneGUIOptionsDisplayFinalSummary'));...
            'sub',getString(message(...
            'Control:systunegui:SystuneGUIOptionsDisplayIntermediateResults'));...
            'iter',getString(message(...
            'Control:systunegui:SystuneGUIOptionsDisplayDetailedProgress'))};
        
        MinDecayEditField
        MaxRadiusEditField
        
        MaxIterEditField
        SoftTolEditField
        SoftScaleEditField
        
        HelpButton
    end
    
    methods
        function this = SystuneGUIOptionsGC(tcpeer)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = 'CSTuner_GUIOptions';
            this.Title = getString(message(...
            'Control:systunegui:SystuneGUIOptionsTitle'));
            this.TCPeer = tcpeer;
        end
        
        function updateUI(this)
            Options = getOptions(this.TCPeer);
            
            % Update check boxes
            this.RandomStartCheckbox.Value = logical(Options.RandomStart);
            this.ParallelCheckbox.Value = logical(Options.UseParallel);
            this.SoftTargetCheckbox.Value = logical(Options.SoftTarget);
            
            if ~strcmp(Options.Display,'off')
                this.DisplayCheckbox.Value = true;
                this.DisplayDropdown.Enable = true;
                this.DisplayDropdown.Value = getDisplayLabel(this,Options.Display);
            else
                this.DisplayCheckbox.Value = false;
                this.DisplayDropdown.Enable = false;
            end
            
            % Update all text fields
            if this.RandomStartCheckbox.Value
                this.RandomStartEditField.Enable = true;
                this.RandomStartEditField.Value =  mat2str(Options.RandomStart);
            else
                this.RandomStartEditField.Enable = false;
            end
            if this.SoftTargetCheckbox.Value
                this.SoftTargetEditField.Enable = true;
                this.SoftTargetEditField.Value =  mat2str(Options.SoftTarget);
            else
                this.SoftTargetEditField.Enable = false;
            end
            this.MinDecayEditField.Value =  num2str(Options.MinDecay,'%g');
            this.MaxRadiusEditField.Value =  num2str(Options.MaxRadius,'%g');
            this.MaxIterEditField.Value =  mat2str(Options.MaxIter);
            this.SoftTolEditField.Value =  mat2str(Options.SoftTol);
            this.SoftScaleEditField.Value =  mat2str(Options.SoftScale);
        end        
    end
    
    methods (Access = protected)
        function buildUI(this)
            % GridLayout
            FigureGrid = uigridlayout(this.UIFigure, [4 1]);
            FigureGrid.RowHeight = {'fit','fit','fit','fit'};
            FigureGrid.ColumnWidth = {'1x'};
            FigureGrid.RowSpacing = 5;
            FigureGrid.Scrollable = 'on';
            
            % Optimization panel
            OptimizationPanel = uipanel(FigureGrid,'Title',getString(message(...
            'Control:systunegui:SystuneGUIOptionsOptimizationOptions')));
            OptimizationPanel.Layout.Row = 1;
            OptimizationPanel.Layout.Column = 1;
            OptimizationPanel.FontWeight = 'bold';
            OptimizationPanel.BorderType = 'none';
            
            OptimizationGrid = uigridlayout(OptimizationPanel, [5 1]);
            OptimizationGrid.RowHeight = {'fit','fit','fit','fit','fit'};
            
            this.RandomStartCheckbox = uicheckbox(OptimizationGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsUseRandomStart')));
            this.RandomStartCheckbox.Layout.Row = 1;
            this.RandomStartCheckbox.Layout.Column = 1;
            this.RandomStartCheckbox.ValueChangedFcn = @(es,ed) callbackRandomStartCheckbox(this);
            
            RandomStartGrid = uigridlayout(OptimizationGrid, [1 3]);
            RandomStartGrid.Padding = [0 0 0 0];
            RandomStartGrid.ColumnWidth = {'1x','fit','1x'};
            RandomStartGrid.Layout.Row = 2;
            RandomStartGrid.Layout.Column = 1;
            
            RandomStartLbl = uilabel(RandomStartGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsRandomStart')));
            RandomStartLbl.Layout.Row = 1;
            RandomStartLbl.Layout.Column = 2;
            
            this.RandomStartEditField = uieditfield(RandomStartGrid);
            this.RandomStartEditField.Tag = 'RandomStart';
            this.RandomStartEditField.Layout.Row = 1;
            this.RandomStartEditField.Layout.Column = 3;
            this.RandomStartEditField.Value = '4';
            this.RandomStartEditField.ValueChangedFcn = @(es,ed) callbackEditField(this,es);
            
            this.ParallelCheckbox = uicheckbox(OptimizationGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsUseParallel')));
            this.ParallelCheckbox.Layout.Row = 3;
            this.ParallelCheckbox.Layout.Column = 1;
            this.ParallelCheckbox.ValueChangedFcn = @(es,ed) callbackParallelCheckbox(this);
            
            SoftTargetGrid = uigridlayout(OptimizationGrid, [1 2]);
            SoftTargetGrid.Padding = [0 0 0 0];
            SoftTargetGrid.ColumnWidth = {'fit','1x'};
            SoftTargetGrid.Layout.Row = 4;
            SoftTargetGrid.Layout.Column = 1;
            
            this.SoftTargetCheckbox = uicheckbox(SoftTargetGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsSoftTarget')));
            this.SoftTargetCheckbox.Layout.Row = 1;
            this.SoftTargetCheckbox.Layout.Column = 1;
            this.SoftTargetCheckbox.ValueChangedFcn = @(es,ed) callbackSoftTargetCheckbox(this);
            
            this.SoftTargetEditField = uieditfield(SoftTargetGrid);
            this.SoftTargetEditField.Tag = 'SoftTarget';
            this.SoftTargetEditField.Layout.Row = 1;
            this.SoftTargetEditField.Layout.Column = 2;
            this.SoftTargetEditField.Value = '1';
            this.SoftTargetEditField.ValueChangedFcn = @(es,ed) callbackEditField(this,es);
            
            DisplayGrid = uigridlayout(OptimizationGrid, [1 2]);
            DisplayGrid.ColumnWidth = {'fit','1x'};
            DisplayGrid.Padding = [0 0 0 0];
            DisplayGrid.Layout.Row = 5;
            DisplayGrid.Layout.Column = 1;
            
            this.DisplayCheckbox = uicheckbox(DisplayGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsDisplay')));
            this.DisplayCheckbox.Layout.Row = 1;
            this.DisplayCheckbox.Layout.Column = 1;
            this.DisplayCheckbox.ValueChangedFcn = @(es,ed) callbackDisplayCheckbox(this);
            
            this.DisplayDropdown = uidropdown(DisplayGrid);
            this.DisplayDropdown.Layout.Row = 1;
            this.DisplayDropdown.Layout.Column = 2;
            this.DisplayDropdown.Items = { ...
                getString(message('Control:systunegui:SystuneGUIOptionsDisplayFinalSummary')),...
                getString(message('Control:systunegui:SystuneGUIOptionsDisplayIntermediateResults')),...
                getString(message('Control:systunegui:SystuneGUIOptionsDisplayDetailedProgress')),...
                };
            this.DisplayDropdown.ValueChangedFcn = @(es,ed) callbackDisplayDropdown(this);
            
            % Stabilization panel
            StabilizationPanel = uipanel(FigureGrid,'Title',...
            getString(message('Control:systunegui:SystuneGUIOptionsStabilizationOptions')));
            StabilizationPanel.Layout.Row = 2;
            StabilizationPanel.Layout.Column = 1;
            StabilizationPanel.FontWeight = 'bold';
            StabilizationPanel.BorderType = 'none';
            
            StabilizationGrid = uigridlayout(StabilizationPanel, [2 2]);
            
            MinDecayLbl = uilabel(StabilizationGrid);
            MinDecayLbl.Layout.Row = 1;
            MinDecayLbl.Layout.Column = 1;
            MinDecayLbl.Text = getString(message('Control:systunegui:SystuneGUIOptionsMinDecay'));
            
            this.MinDecayEditField = uieditfield(StabilizationGrid);
            this.MinDecayEditField.Tag = 'MinDecay';
            this.MinDecayEditField.Layout.Row = 1;
            this.MinDecayEditField.Layout.Column = 2;
            this.MinDecayEditField.ValueChangedFcn = @(es,ed) callbackEditField(this,es);
            
            MaxRadiusLbl = uilabel(StabilizationGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsMaxRadius')));
            MaxRadiusLbl.Layout.Row = 2;
            MaxRadiusLbl.Layout.Column = 1;
            
            this.MaxRadiusEditField = uieditfield(StabilizationGrid);
            this.MaxRadiusEditField.Tag = 'MaxRadius';
            this.MaxRadiusEditField.Layout.Row = 2;
            this.MaxRadiusEditField.Layout.Column = 2;
            this.MaxRadiusEditField.ValueChangedFcn = @(es,ed) callbackEditField(this,es);
            
            % Solver Parameters panel
            ParametersPanel = uipanel(FigureGrid,'Title',...
            getString(message('Control:systunegui:SystuneGUIOptionsSolverParametersOptions')));
            ParametersPanel.Layout.Row = 3;
            ParametersPanel.Layout.Column = 1;
            ParametersPanel.FontWeight = 'bold';
            ParametersPanel.BorderType = 'none';
            
            ParameterGrid = uigridlayout(ParametersPanel, [3 2]);
            ParameterGrid.ColumnWidth = {'fit','1x'};
            
            MaxIterLbl = uilabel(ParameterGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsMaxIter')));
            MaxIterLbl.Layout.Row = 1;
            MaxIterLbl.Layout.Column = 1;
            
            this.MaxIterEditField = uieditfield(ParameterGrid);
            this.MaxIterEditField.Tag = 'MaxIter';
            this.MaxIterEditField.Layout.Row = 1;
            this.MaxIterEditField.Layout.Column = 2;
            this.MaxIterEditField.ValueChangedFcn = @(es,ed) callbackEditField(this,es);
            
            SoftTolLbl = uilabel(ParameterGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsSoftTol')));
            SoftTolLbl.Layout.Row = 2;
            SoftTolLbl.Layout.Column = 1;
            
            this.SoftTolEditField = uieditfield(ParameterGrid);
            this.SoftTolEditField.Tag = 'SoftTol';
            this.SoftTolEditField.Layout.Row = 2;
            this.SoftTolEditField.Layout.Column = 2;
            this.SoftTolEditField.ValueChangedFcn = @(es,ed) callbackEditField(this,es);
            
            SoftScaleLbl = uilabel(ParameterGrid,'Text',...
            getString(message('Control:systunegui:SystuneGUIOptionsSoftScale')));
            SoftScaleLbl.Layout.Row = 3;
            SoftScaleLbl.Layout.Column = 1;
            
            this.SoftScaleEditField = uieditfield(ParameterGrid);
            this.SoftScaleEditField.Tag = 'SoftScale';
            this.SoftScaleEditField.Layout.Row = 3;
            this.SoftScaleEditField.Layout.Column = 2;
            this.SoftScaleEditField.ValueChangedFcn = @(es,ed) callbackEditField(this,es);
            
            % Button Grid       
            ButtonGrid = uigridlayout(FigureGrid, [1 2]);
            ButtonGrid.Layout.Row = 4;
            ButtonGrid.Layout.Column = 1;
            ButtonGrid.RowHeight = {'fit'};
            ButtonGrid.ColumnWidth = {'fit','1x'};
            %ButtonGrid.Padding = [0 0 0 0];
            
            this.HelpButton = uibutton(ButtonGrid,'Text',...
            getString(message('Controllib:gui:strHelp')));
            this.HelpButton.Layout.Row = 1;
            this.HelpButton.Layout.Column = 1;
            this.HelpButton.ButtonPushedFcn = @(~,~) callbackHelpButton(this);
        end
        
        function connectUI(this)
            %TC Listener
            L1 = addlistener(this.TCPeer,'ComponentChanged', @(hSrc,hData) updateUI(this));
            L2 = addlistener(this.TCPeer.Data.ControlDesignData,'ObjectBeingDestroyed', @(hSrc,hData) close(this));
            registerUIListeners(this,[L1 L2]);
        end
        
        function callbackRandomStartCheckbox(this)
            this.RandomStartEditField.Enable = this.RandomStartCheckbox.Value;
            if this.RandomStartCheckbox.Value
                setOptionField(this.TCPeer,'RandomStart',str2double(this.RandomStartEditField.Value));
            else
                setOptionField(this.TCPeer,'RandomStart',0);
            end
        end
        
        function callbackParallelCheckbox(this)
            setOptionField(this.TCPeer,'UseParallel',this.ParallelCheckbox.Value);
        end
        
        function callbackSoftTargetCheckbox(this)
            this.SoftTargetEditField.Enable = this.SoftTargetCheckbox.Value;
            if this.SoftTargetCheckbox.Value
                setOptionField(this.TCPeer,'SoftTarget',str2double(this.SoftTargetEditField.Value));
            else
                setOptionField(this.TCPeer,'SoftTarget',0);
            end
        end
        
        function callbackDisplayCheckbox(this)
            this.DisplayDropdown.Enable = this.DisplayCheckbox.Value;
            if this.DisplayCheckbox.Value
                setOptionField(this.TCPeer,'Display',getDisplayOption(this,this.DisplayDropdown.Value));
            else
                setOptionField(this.TCPeer,'Display','off');
            end
        end
        
        function callbackDisplayDropdown(this)
            setOptionField(this.TCPeer,'Display',getDisplayOption(this,this.DisplayDropdown.Value));
        end
        
        function callbackEditField(this,es)
            try
                Value = evalin('base',es.Value);
            catch ME
                updateUI(this);
                uialert(this.UIFigure,ME.message,getString(message('Control:systunegui:toolName')));
                return;
            end
            
            try
                setOptionField(this.TCPeer,es.Tag,Value);
            catch
                updateUI(this);
                uialert(this.UIFigure,...
                   getString(message(['Control:systunegui:SystuneGUIOptionsErr' es.Tag])),...
                   getString(message('Control:systunegui:toolName')));
                return;
            end
        end
        
        function callbackHelpButton(this) %#ok<MANU>
            helpview('control','SystuneGUIOptionsHelp','CSHelpWindow');
        end
    end
    
    methods (Hidden)
        function option = getDisplayOption(this,label)
            condition = strcmp(this.OptionLabels(:,2),label);
            option = this.OptionLabels{find(condition,1),1};
        end
        
        function label = getDisplayLabel(this,option)
            condition = strcmp(this.OptionLabels(:,1),option);
            label = this.OptionLabels{find(condition,1),2};
        end
        
        function Widgets = qeGetWidgets(this)
            Widgets = struct('RandomStartCheckbox', this.RandomStartCheckbox,...
                'RandomStartEditField', this.RandomStartEditField,...
                'ParallelCheckbox', this.ParallelCheckbox,...
                'SoftTargetCheckbox', this.SoftTargetCheckbox,...
                'SoftTargetEditField', this.SoftTargetEditField,...
                'DisplayCheckbox', this.DisplayCheckbox,...
                'DisplayDropdown', this.DisplayDropdown,...
                'MinDecayEditField', this.MinDecayEditField,...
                'MaxRadiusEditField', this.MaxRadiusEditField,...
                'MaxIterEditField', this.MaxIterEditField,...
                'SoftTolEditField', this.SoftTolEditField,...
                'SoftScaleEditField', this.SoftScaleEditField,...
                'HelpButton', this.HelpButton);
        end
    end
end