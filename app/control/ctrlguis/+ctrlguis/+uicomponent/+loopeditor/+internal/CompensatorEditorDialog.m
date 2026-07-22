classdef CompensatorEditorDialog < controllib.ui.internal.dialog.AbstractDialog
    % Compensator Editor Dialog
    
    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc.    
    
    %% Properties
    properties (Access=private,Transient,NonCopyable)
        PanelGrid matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        CompensatorEditorComponent ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorComponent {mustBeScalarOrEmpty}
        ButtonPanel controllib.widget.internal.buttonpanel.ButtonPanel {mustBeScalarOrEmpty}
    end

    properties (Dependent,Access=protected)
        HelpButton matlab.ui.control.Button
        CloseButton matlab.ui.control.Button
    end

    properties (WeakHandle,Access=private,Transient,NonCopyable)
        LoopEditor ctrlguis.uicomponent.OpenLoopEditor {mustBeScalarOrEmpty}
    end

    %% Constructor/destructor
    methods
        function this = CompensatorEditorDialog(LoopEditor)
            arguments
                LoopEditor (1,1) ctrlguis.uicomponent.OpenLoopEditor
            end
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.LoopEditor = LoopEditor;
            this.Name = sprintf('Compensator-Editor-%s',matlab.lang.internal.uuid);
            this.Title = getString(message('Control:design:compEditorTitle'));
        end
    end


    %% Public methods
    methods        
        function updateUI(this)
            this.CompensatorEditorComponent.Compensator = this.LoopEditor.Compensator;
        end
    end

    %% Get/Set
    methods
        % HelpButton
        function HelpButton = get.HelpButton(this)
            HelpButton = this.ButtonPanel.HelpButton;
        end

        % OKButton
        function OKButton = get.CloseButton(this)
            OKButton = this.ButtonPanel.CloseButton;
        end
    end

    %% Protected methdods
    methods (Access=protected)
        function figureGrid = buildUI(this)
            % GridLayout
            figureGrid = uigridlayout(this.UIFigure,[2 1]);
            figureGrid.RowHeight = {'1x','fit'};

            % Compensator component
            this.CompensatorEditorComponent = ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorComponent(...
                Parent=figureGrid,Compensator=this.LoopEditor.Compensator);

            % Button panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                figureGrid, ["help" "close"]);
            btnCont = getWidget(this.ButtonPanel);
            btnCont.Layout.Row = 2;

            this.PanelGrid = figureGrid;

            this.UIFigure.Position(3:4) = [800 400];
        end
        
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(this.UIFigure, 'ObjectBeingDestroyed',@(es,ed) delete(weakThis.Handle));
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) cbCloseEvent(weakThis.Handle));
            registerUIListeners(this,L2);

            this.CompensatorEditorComponent.CompensatorChangedFcn = @(es,ed) cbCompensatorChanged(weakThis.Handle);
            this.CloseButton.ButtonPushedFcn = @(es,ed) close(weakThis.Handle);
            this.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButtonPushed(weakThis.Handle);
        end

        function cbHelpButtonPushed(~)
            helpview('control','OpenLoopEditorCompensatorEditorHelp','CSHelpWindow')
        end

        function cbCloseEvent(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            close(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end

        function cbCompensatorChanged(this)
            cbUpdateCompensatorFromEditor(this.LoopEditor,this.CompensatorEditorComponent.Compensator)
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgt = qeGetWidgets(this)
            wdgt = struct('CompensatorEditorComponent',this.CompensatorEditorComponent,...
                'PanelGrid',this.PanelGrid,...
                'ButtonPanel',this.ButtonPanel,...
                'HelpButton',this.HelpButton,...
                'CloseButton',this.CloseButton);
        end
    end
end

