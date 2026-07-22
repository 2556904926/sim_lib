classdef IOTransferGC < ctrluis.AbstractGC
    %% Graphical component (GC) for Input-Output Transfer signals
    %   
    %   GC = IOTransferGC(TC) creates GC using the specified TC.
    %
    %   IOTransferGC methods:
    %       createWidgets - Creates a panel containing the graphical
    %                       components and returns all the widgets in a
    %                       flat structure.
    %
    %   Examples:
    %
    %       %% Construct and show GC
    %       gc = controllib.widget.internal.responseplot.IOTransferGC(<tc>);
    %       show(gc)
    %
    %       %% Embed the GC panel in a different dialog.
    %       gc = controllib.widget.internal.responseplot.IOTransferGC(<tc>);
    %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
    %
    %  See also controllib.widget.internal.responseplot.IOTransferTC
    %           controllib.widget.internal.responseplot.ResponseInputOutputTransferGC
    %           controllib.widget.internal.signallist.SignalListPanel
    
    % Copyright 2013-2021 The MathWorks, Inc
    
    %% Properties
    properties(Hidden,SetAccess=private,GetAccess=public)
        Widgets = struct(...
            'dialogLayout',[], ...
            'layout',[], ...
            'inputListPanel',[],...
            'outputListPanel',[],...
            'openingListPanel',[]...            
            );
    end
    
    %% Constructor
    methods
        function this = IOTransferGC(tcpeer)
            this = this@ctrluis.AbstractGC(tcpeer);
            this.Name = 'InputOutputTransferDialog';
            this.Title = '';            
        end
    end
    
    %% Public methods
    methods(Access = public)        
        function updateUI(this)
            % Updates graphical component
            if this.IsVisible
%                 pack(this)
            end
        end
        
        function widgets = createWidgets(this,parentLayout,row,col)
            % Creates a panel containing the graphical components and
            % returns all the widgets in a flat structure.
            % 
            %   WIDGETS = CREATEWIDGETS(GC,PARENTLAYOUT,ROW,COL) Constructs
            %   WIDGETS for GC and attaches it to PARENTLAYOUT using the
            %   specified ROW and COL. You must provide PARENTLAYOUT, which
            %   is required to construct a flat contextmenu of a signal
            %   list panel using the figure parent of PARENTLAYOUT.
            %
            %   WIDGETS is flat structure having the following fields:
            %       layout           - Top level layout container
            %       inputListPanel   - A flat structure containing widget
            %                          components for the input signal list
            %                          panel.
            %       outputListPanel  - A flat structure containing widget
            %                          components for the output signal
            %                          list panel.
            %       openingListPanel - A flat structure containing widget
            %                          components for the opening signal
            %                          list panel.
            %
            %   It creates the widgets using the following layout:
            %
            %       --------------------
            %       | inputListPanel   |
            %       --------------------
            %       | outputListPanel  |
            %       --------------------
            %       | openingListPanel |
            %       --------------------
            %
            %   Example:
            %
            %       gc = controllib.widget.internal.responseplot.IOTransferGC(<tc>);
            %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
            %
            %   See also controllib.widget.internal.responseplot.IOTransferTC
            %            controllib.widget.internal.signallist.SignalListPanel
            
            %  Copyrihgt 2020-2021 The MathWorks, Inc.
            
            % Create top level layout container.
            layout = uigridlayout(parentLayout,[3 1],'Scrollable','off');
            layout.Layout.Row = row;
            layout.Layout.Column = col;
            layout.Padding = this.Padding;
            layout.RowHeight = {'fit','fit','fit'};
            layout.RowSpacing = 10;
            layout.ColumnWidth = {'1x'};
            layout.ColumnSpacing = 10;            
            this.Widgets.layout = layout;
            
            
            %% Input list panel
            [~,widgets] = getWidget(this.TCPeer.InputListPanel,layout,1,1);
            this.Widgets.inputListPanel = widgets;
            
            %% Output list panel
            [~,widgets] = getWidget(this.TCPeer.OutputListPanel,layout,2,1);
            this.Widgets.outputListPanel = widgets;
            
            %% Opening list panel
            [~,widgets] = getWidget(this.TCPeer.OpeningListPanel,layout,3,1);
            this.Widgets.openingListPanel = widgets;
            
            widgets = this.Widgets;
            widgets = rmfield(widgets,'dialogLayout');
        end
        
    end
    
    %% Protected methods
    methods(Access = protected)
        function buildUI(this)
            % Build widgets.
            
            this.Title = this.Name;
            
            % Set dialog size.
            this.UIFigure.Position(3:4) = [385 350];
                        
            % Create dialog layout.
            layout = uigridlayout(this.UIFigure,[1 1]);
            layout.Padding = 0;
            layout.RowHeight = {'1x'};
            layout.RowSpacing = 0;
            layout.ColumnWidth = {'1x'};
            layout.ColumnSpacing = 0;            
            layout.Scrollable = 'on';
            this.Widgets.dialogLayout = layout;
            
            createWidgets(this,layout,1,1);
        end
        
        function cleanupUI(this)
            % Delete any non-children of the dialog.
            
            if this.IsWidgetValid
                % Deleting UIFigure will delete everything.
                return
            end
            
            % Otherwise delete the top level layout container.
            delete(this.Widgets.layout)
            this.Widgets.layout = [];
        end
    end
    
    %% Private methods    
    methods(Access=private)

    end
    
    %% Hidden methods
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets = this.Widgets;
            widgets.inputListPanel = qeGetWidgets(this.TCPeer.InputListPanel);
            widgets.outputListPanel = qeGetWidgets(this.TCPeer.OutputListPanel);
            widgets.openingListPanel = qeGetWidgets(this.TCPeer.OpeningListPanel);
        end
    end
    
end