classdef (Hidden) AbstractOptionsDialog < controllib.ui.internal.dialog.AbstractDialog
    % Abstract Options Dialog of Model Reduction App
    
    % Author(s): A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc.    
    
    %% Properties
    properties (Access = protected)
        Widgets        
        InitOnly (1,1) logical = false;
    end

    properties (Access=protected,Transient)
        ToolDataListener
    end    

    properties (AbortSet, SetObservable, WeakHandle)
        ToolData (1,1) handle = matlab.lang.invalidHandle('matlab.lang.HandlePlaceholder')
    end

    %% Events
    events
        OptionsApplying
        OptionsApplied
        DialogClosed
    end

    %% Constructor/destructor
    methods
        function this = AbstractOptionsDialog(ToolData,Name)
            arguments
                ToolData (1,1) mrtool.data.AbstractData
                Name (1,1) string
            end
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.CloseMode = 'hide';
            this.ToolData = ToolData;
            this.Name = Name;
            this.Title = getString(message('Control:mrtool:Options'));
        end
        
        function delete(this)
            delete@controllib.ui.internal.dialog.AbstractDialog(this);
            delete(this.ToolDataListener);
        end
    end

    %% Get/Set
    methods
        function set.ToolData(this,ToolData)
            arguments
                this (1,1) mrtool.dialogs.AbstractOptionsDialog
                ToolData (1,1) mrtool.data.AbstractData
            end
            this.ToolData = ToolData;
            delete(this.ToolDataListener) %#ok<MCSUP>
            weakThis = matlab.lang.WeakReference(this);
            this.ToolDataListener = addlistener(this.ToolData, ...
                'ToolDataChanged',@(es,ed) cbToolDataChanged(weakThis.Handle)); %#ok<MCSUP>
        end
    end

    %% Public methods
    methods        
        function updateUI(this) %#ok<MANU>
            % Overload in subclass                   
        end
        
        function close(this)
            close@controllib.ui.internal.dialog.AbstractDialog(this)
            notify(this,'DialogClosed')
        end
    end

    %% Protected methdods
    methods (Access=protected)
        function figureGrid = buildUI(this)
            % GridLayout
            figureGrid = uigridlayout(this.UIFigure,[2 1]);
            figureGrid.RowHeight = {'fit','fit'};
            figureGrid.Tag = 'MR_Options_GridLayout';

            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                figureGrid, ["help" "ok" "cancel"]);
            btnCont = getWidget(buttonPanel);
            btnCont.Layout.Row = 2;
            btnCont.Layout.Column = 1;

            % add to widgets
            this.Widgets = struct('ButtonPanel',buttonPanel,...
                'HelpButton',buttonPanel.HelpButton,...
                'OKButton',buttonPanel.OKButton,...
                'CancelButton',buttonPanel.CancelButton,...
                'PanelGrid',figureGrid);
        end
        
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(this.UIFigure, 'ObjectBeingDestroyed',@(es,ed) delete(weakThis.Handle));
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) cbCloseEvent(weakThis.Handle));
            registerUIListeners(this,L2);
            this.Widgets.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(weakThis.Handle);
            this.Widgets.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButtonPushed(weakThis.Handle);
            this.Widgets.CancelButton.ButtonPushedFcn = @(es,ed) cbCloseEvent(weakThis.Handle);
        end

        function cbCloseEvent(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            close(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end

        function cbToolDataChanged(this)
            if this.IsVisible
                updateUI(this);
            end
        end
    end

    %% Abstract protected methods
    methods (Access=protected,Abstract)
        cbOKButtonPushed(this);
        cbHelpButtonPushed(this);
    end

    %% Hidden methods
    methods (Hidden)
        function wt = qeGetWidgets(this)
            wt = this.Widgets;            
        end
    end
end

