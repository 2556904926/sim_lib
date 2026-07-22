classdef AbstractTunableBlockEditor < controllib.ui.internal.dialog.AbstractDialog
    % ABSTRACTTUNABLEBLOCKEDITOR Abstract class to edit the parameterization of an
    % MLTunableBlockEditor and SLTunableBlockEditor object

    % Copyright 2016-2020 The MathWorks, Inc.

    properties
        % Data
        TunableBlock                    %The block whose parameterization is being edited
        DialogSize = [560 330];
    end

    properties (Dependent)
        VariableValue
    end

    properties(Access = protected)
        % Graphical components
        Editor
        Description
        FigureGrid
        NameLabel
        NameText
        ParameterizationLabel
        ParameterizationDropdown
        EditorGrid
        ButtonPanel                     controllib.widget.internal.buttonpanel.ButtonPanel
        % Listeners
        TunableBlockChangedListener     %Listen to changes in Tunable Block
        BlockCleanupListener
        CloseEventListener
        WidgetListeners
        % Data
        VariableName
        InitialVariableValue
    end

    %% Public Methods
    methods 
        function this = AbstractTunableBlockEditor(tunableBlock)
            this.TunableBlock = tunableBlock;

            % Variable Name
            if isempty(tunableBlock.Name)
                this.VariableName = 'mylti';
            else
                this.VariableName = matlab.lang.makeValidName(tunableBlock.Name);
            end
            
            this.InitialVariableValue = getParameterization(this.TunableBlock);
            weakThis = matlab.lang.WeakReference(this);
            % Listeners for TunableBlock changed
            this.BlockCleanupListener = addlistener(this.TunableBlock,'ObjectBeingDestroyed',...
                @(es,ed) delete(weakThis.Handle));
            this.TunableBlockChangedListener = addlistener(this.TunableBlock,'ParameterizationChanged',...
                @(es,ed) cbTunableBlockChanged(weakThis.Handle));
            this.CloseEventListener = addlistener(this,'CloseEvent',@(es,ed) delete(weakThis.Handle));
            % Close Mode
            this.CloseMode = "destroy";
        end

        function delete(this)
            delete(this.TunableBlockChangedListener);
            delete(this.BlockCleanupListener);
            delete(this.CloseEventListener);
            delete(this.Editor);
        end
    end

    %% Set/Get methods
    methods
        % Variable Value
        function VariableValue = get.VariableValue(this)
            if ~isempty(this.Editor) && isvalid(this.Editor)
                VariableValue = this.Editor.VariableValue;
            else
                VariableValue = this.InitialVariableValue;
            end
        end

        function set.VariableValue(this,VariableValue)
            updateVariableValue(this,VariableValue)
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function connectUI(this)
            this.ButtonPanel.OKButton.ButtonPushedFcn = @(es,ed) cbOKButton(this);
            this.ButtonPanel.CancelButton.ButtonPushedFcn = @(es,ed) cbCancelButton(this);
            this.ButtonPanel.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButton(this);
        end

        function cbTunableBlockChanged(this)
            if isvalid(this)
                newLTI = getParameterization(this.TunableBlock);
                oldLTI = this.InitialVariableValue;
                swapPanels = ~isequal(class(newLTI), class(oldLTI));
                this.InitialVariableValue = newLTI;
                updateLTIEditorPanel(this, swapPanels);      
            end
        end

        function cbCancelButton(this)
            if isvalid(this)
                close(this);
                delete(this);
            end
        end

        function cbHelpButton(this) %#ok<MANU> 
            helpview('control','TunableBlockEditorHelp','CSHelpWindow');
        end
    end

    %% Abstract Methods
    methods(Abstract, Access = protected)
        updateLTIEditorPanel(this, swapPanels)
        cbParameterizationDropdownValueChanged(this)
        cbOKButton(this)
    end

    %% Hidden Methods
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets.Editor = this.Editor;
            widgets.ButtonPanel = this.ButtonPanel;
            widgets.NameLabel = this.NameLabel;
            widgets.NameText = this.NameText;
            widgets.ParameterizationLabel = this.ParameterizationLabel;
            widgets.ParameterizationDropdown = this.ParameterizationDropdown;

        end
    end
end