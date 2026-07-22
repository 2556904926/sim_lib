classdef MLTunableBlockEditor < systuneapp.internal.dialogs.blockeditors.AbstractTunableBlockEditor
    % MLTUNABLEBLOCKEDITOR Edit the parameterization of an MLTunableBlockEditor object

    %   Copyright 2013-2020 The MathWorks, Inc.

    %% Public Methods
    methods
        function this = MLTunableBlockEditor(tunableBlock)
            this = this@systuneapp.internal.dialogs.blockeditors.AbstractTunableBlockEditor(tunableBlock);
            this.Name = sprintf('dlgMLTunableBlockEditor_%s', this.VariableName);
            this.Title = [getString(message('Controllib:gui:SLTunableBlock_DlgTitle')), ...
                ' - ',this.VariableName];
        end

        function updateVariableValue(this,variableValue)
            oldLTI = this.VariableValue;
            swapPanels = ~isequal(class(oldLTI),class(variableValue));
            this.InitialVariableValue = variableValue;
            updateLTIEditorPanel(this,swapPanels);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function buildUI(this)
            figureGrid = uigridlayout(this.UIFigure,[4,1]);
            figureGrid.RowHeight = {'fit','fit','1x','fit'};
            figureGrid.ColumnWidth = {'1x'};
            this.FigureGrid = figureGrid;

            % Name and Type Layout
            nameTypeGrid = uigridlayout(figureGrid,[1 6]);
            nameTypeGrid.ColumnWidth = {'fit','fit',10,'fit','fit','1x'};
            nameTypeGrid.RowHeight = {'fit'};
            nameTypeGrid.Padding = 0;
            % Name
            this.NameText = uilabel(nameTypeGrid,"Text",...
                getString(message('Controllib:gui:lblLTIBlockEditor_Name')),...
                "FontWeight",'bold');
            this.NameText.Layout.Row = 1;
            this.NameText.Layout.Column = 1;
            this.NameLabel = uilabel(nameTypeGrid,"Text",this.VariableValue.Name);
            this.NameLabel.Layout.Row = 1;
            this.NameLabel.Layout.Column = 2;
            % Type
            this.ParameterizationLabel = uilabel(nameTypeGrid,"Text",...
                getString(message('Controllib:gui:lblLTIBlockEditor_Parameterization')),...
                "FontWeight",'bold');
            this.ParameterizationLabel.Layout.Row = 1;
            this.ParameterizationLabel.Layout.Column = 4;
            
            this.ParameterizationDropdown = uidropdown(nameTypeGrid);
            this.ParameterizationDropdown.Layout.Row = 1;
            this.ParameterizationDropdown.Layout.Column = 5;
            this.ParameterizationDropdown.Items = getParameterizationDropdownItems(this);

            % Editor Grid
            this.EditorGrid = uigridlayout(figureGrid,[1 1]);
            this.EditorGrid.Layout.Row = 3;
            this.EditorGrid.Layout.Column = 1;
            this.EditorGrid.Padding = 0;

            % Button Panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(figureGrid,["OK","Cancel","Help"]);
            widget = getWidget(this.ButtonPanel);
            widget.Layout.Row = 4;
            widget.Layout.Column = 1;

            % LTI Editor
            updateLTIEditorPanel(this,true);

            % Size Dialog
            this.UIFigure.Position(3:4) = this.DialogSize;
        end

        function connectUI(this)
            connectUI@systuneapp.internal.dialogs.blockeditors.AbstractTunableBlockEditor(this);
            this.ParameterizationDropdown.ValueChangedFcn = ...
                @(es,ed) cbParameterizationDropdownValueChanged(this);
        end

        function updateLTIEditorPanel(this,swapPanels)
            try
                % Change pointer to busy
                currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
                drawnow('nocallbacks');
                % Swap Panels if needed
                if swapPanels
                    % Delete current editor
                    delete(this.Editor);
                    % Create new editor based on class of tunable variable
                    switch class(this.InitialVariableValue)
                        case {'tunablePID','ltiblock.pid'}
                            this.Editor = systuneapp.internal.panels.blockeditors.PIDEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblPIDEditor_Type'));
                            this.ParameterizationDropdown.Visible = true;
                        case {'tunableSS','ltiblock.ss'}
                            this.Editor = systuneapp.internal.panels.blockeditors.SSEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblSSEditor_Type'));
                            this.ParameterizationDropdown.Visible = true;
                        case {'tunableTF','ltiblock.tf'}
                            this.Editor = systuneapp.internal.panels.blockeditors.TFEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblTFEditor_Type'));
                            this.ParameterizationDropdown.Visible = true;
                        case {'tunablePID2','ltiblock.pid2'}
                            this.Editor = systuneapp.internal.panels.blockeditors.PID2Editor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblPID2Editor_Type'));
                            this.ParameterizationDropdown.Visible = true;
                        case {'tunableGain','ltiblock.gain'}
                            this.Editor = systuneapp.internal.panels.blockeditors.GainEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblGainEditor_Type'));
                            this.ParameterizationDropdown.Visible = true;
                        case {'genss'}
                            this.Editor = systuneapp.internal.panels.blockeditors.GenssEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Value = ...
                                getString(message('Controllib:gui:lblCustomEditor_Type'));
                            this.ParameterizationDropdown.Visible = true;
                        case {'realp'}
                            this.Editor = systuneapp.internal.panels.blockeditors.RealpEditor(...
                                this.InitialVariableValue,"Parent",this.EditorGrid);
                            this.ParameterizationDropdown.Visible = false;
                    end

                    % Create widget
                    getWidget(this.Editor);
                else
                    % Do not swap panel. Update existing panel.
                    this.Editor.VariableValue = this.InitialVariableValue;
                end
            catch ex
                throw(ex);
                % Change pointer back to 'normal'
                controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
                drawnow('nocallbacks');
            end
            % Change pointer back to 'normal'
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow('nocallbacks');
        end

        function cbParameterizationDropdownValueChanged(this)
            % Change pointer to watch/busy/spinning
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');

            try
                oldLTI = this.VariableValue;
                switch this.ParameterizationDropdown.Value
                    case getString(message('Controllib:gui:lblPIDEditor_Type'))
                        try
                            this.InitialVariableValue = tunablePID(this.TunableBlock.Name,oldLTI);
                        catch
                            this.InitialVariableValue = tunablePID(this.TunableBlock.Name, 'pid');
                        end
                    case getString(message('Controllib:gui:lblPID2Editor_Type'))
                        try
                            this.InitialVariableValue = tunablePID2(this.TunableBlock.Name,oldLTI);
                        catch
                            this.InitialVariableValue = tunablePID2(this.TunableBlock.Name,'pid');
                        end
                    case getString(message('Controllib:gui:lblSSEditor_Type'))
                        try
                            this.InitialVariableValue = tunableSS(this.TunableBlock.Name,oldLTI);
                        catch
                            this.InitialVariableValue = tunableSS(this.TunableBlock.Name,tf(ones(this.TunableBlock.iosize)));
                        end
                    case getString(message('Controllib:gui:lblTFEditor_Type'))
                        try
                            this.InitialVariableValue = tunableTF(this.TunableBlock.Name,oldLTI);
                        catch
                            this.InitialVariableValue = tunableTF(this.TunableBlock.Name,tf(ones(this.TunableBlock.iosize)));
                        end
                    case getString(message('Controllib:gui:lblGainEditor_Type'))
                        try
                            this.InitialVariableValue = tunableGain(this.TunableBlock.Name,oldLTI);
                        catch
                            this.InitialVariableValue = tunableGain(this.TunableBlock.Name,ones(this.TunableBlock.iosize));
                        end
                    case getString(message('Controllib:gui:lblRealpEditor_Type'))
                        try
                            this.InitialVariableValue = realp(this.TunableBlock.Name,oldLTI);
                        catch
                            this.InitialVariableValue = realp(this.TunableBlock.Name,ones(this.TunableBlock.iosize));
                        end
                    case getString(message('Controllib:gui:lblCustomEditor_Type'))
                        tempVal = genss(tf(ones(this.TunableBlock.iosize)));
                        tempVal.Name = this.TunableBlock.Name;
                        this.InitialVariableValue = tempVal;
                end
                swapPanels = ~isequal(oldLTI,this.InitialVariableValue);
                updateLTIEditorPanel(this,swapPanels);
            catch ex
                % Show uialert dialog and set pointer back
                uialert(this.UIFigure,ex.message,getString(message('Controllib:gui:SLTunableBlock_DlgTitle')));
                controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            end

            % Set pointer back
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
        end

        function cbOKButton(this)
            try
                this.TunableBlockChangedListener.Enabled = false;
                variableValue = this.VariableValue;
                if ~isa(variableValue,'realp')
                    variableValue.UserData = generateMATLABCode(this.Editor,this.VariableName,false);
                end
                setParameterization(this.TunableBlock,variableValue);
                close(this);
                delete(this);
            catch ex
                uialert(this.UIFigure,ex.message,getString(message('Controllib:gui:SLTunableBlock_DlgTitle')));
            end
        end
    end

    methods (Access = private)
        function items = getParameterizationDropdownItems(this)
            iosize = this.TunableBlock.iosize;
            if this.TunableBlock.SupportGenss
                if iosize == [1 1]
                    items = {getString(message('Controllib:gui:lblPIDEditor_Type')),getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblTFEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type')),getString(message('Controllib:gui:lblCustomEditor_Type'))};
                elseif iosize == [1 2] %#ok<BDSCA>
                    items = {getString(message('Controllib:gui:lblPID2Editor_Type')),getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type')),getString(message('Controllib:gui:lblCustomEditor_Type'))};
                else
                    items = {getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type')),getString(message('Controllib:gui:lblCustomEditor_Type'))};
                end
            else
                if iosize == [1 1]
                    items = {getString(message('Controllib:gui:lblPIDEditor_Type')),getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblTFEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type'))};
                elseif iosize == [1 2] %#ok<BDSCA>
                    items = {getString(message('Controllib:gui:lblPID2Editor_Type')),getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type'))};
                else
                    items = {getString(message('Controllib:gui:lblSSEditor_Type')),getString(message('Controllib:gui:lblGainEditor_Type'))};
                end
            end
        end

        function setParameterizationDropdownValue(this)
            switch class(this.VariableValue)

            end
        end
    end
end