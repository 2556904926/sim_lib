classdef (Hidden) PolesSpecGC < systuneapp.internal.panels.StableControllerSpecGC
    % Graphical component for Poles tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc

    methods
        function this = PolesSpecGC(tcpeer)
            %Call parent constructor
            this = this@systuneapp.internal.panels.StableControllerSpecGC(tcpeer);
            this.ShowFocusWidget = true;
            this.ShowModelsWidget = true;
        end
    end
    
    methods(Access= protected)
        function container = createContainer(this)
            %% Base class container
            container = createContainer@systuneapp.internal.panels.StableControllerSpecGC(this); %#ok<NASGU>
            container.RowHeight = {'fit','fit'};
            
            %% Options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            accOptions.Layout.Row = 2;
            accOptions.Layout.Column = 1;
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layoutOptions = uigridlayout(pnlOptions,[2 3]);
            layoutOptions.Padding = 0;
            layoutOptions.RowHeight = {'fit','fit'};
            layoutOptions.ColumnWidth = {'fit','1x','fit'};
            
            this.Widgets.Advanced.lblFocus.Parent = layoutOptions;
            this.Widgets.Advanced.lblFocus.Layout.Row = 1;
            this.Widgets.Advanced.lblFocus.Layout.Column = 1;
            this.Widgets.Advanced.txtFocus.Parent = layoutOptions;
            this.Widgets.Advanced.txtFocus.Layout.Row = 1;
            this.Widgets.Advanced.txtFocus.Layout.Column = 2;
            this.Widgets.Advanced.lblFreqUnit.Parent = layoutOptions;
            this.Widgets.Advanced.lblFreqUnit.Layout.Row = 1;
            this.Widgets.Advanced.lblFreqUnit.Layout.Column = 3;
            this.Widgets.Advanced.pnlRadio.Parent = layoutOptions;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 2;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% Store widgets for easy access
            this.Widgets.Poles.pnlOptions = pnlOptions;
        end
    end
end