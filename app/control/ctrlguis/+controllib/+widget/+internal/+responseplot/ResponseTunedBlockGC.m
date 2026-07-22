classdef ResponseTunedBlockGC < ctrluis.AbstractGC    
    %% Graphical component (GC) for Input-Output Transfer response of a tuned block
    %   
    %   GC = ResponseTunedBlockGC(TC) creates GC using the specified TC.
    %
    %   ResponseLoopTransferGC methods:
    %       createWidgets - Creates a panel containing the graphical
    %                       components and returns all the widgets in a
    %                       flat structure.
    %
    %   Examples:
    %
    %       %% Construct and show GC
    %       gc = ctrlguis.csdesignerapp.panels.internal.ResponseTunedBlockGC(<tc>);
    %       show(gc)
    %
    %       %% Embed the GC panel in a different dialog.
    %       gc = ctrlguis.csdesignerapp.panels.internal.ResponseTunedBlockGC(<tc>);
    %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
    %
    %  See also ctrlguis.csdesignerapp.panels.internal.ResponseTunedBlockTC
    
    % Copyright 2013-2020 The MathWorks, Inc
    
    %% Properties
    properties(Access=private)
        Widgets = struct(...
            'dialogLayout',[], ...
            'panel',[], ...
            'layout',[], ...
            'tunableElementLabel',[], ...
            'tunableElementListBox',[] ...
            );
    end
    
    %% Constructor
    methods
        function this = ResponseTunedBlockGC(tcpeer)
            this = this@ctrluis.AbstractGC(tcpeer);
            this.Name = "CSDApp_ResponseTunedBlockDialog_" + matlab.lang.internal.uuid;
            this.Title = 'Response Tune Block Dialog';
        end
    end
    
    %% Public methods
    methods
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
            %   specified ROW and COL.
            %
            %   WIDGETS is flat structure having the following fields:
            %       layout                - Top lelvel layout container
            %       tunableElementLabel   - Tunable element label
            %       tunableElementListBox - Drop down list box for tunable elements
            %
            %   It creates the widgets using the following layout:
            %
            %       ----------------------------------------------
            %       | tunableElementLabel: tunableElementListBox |
            %       ----------------------------------------------
            %
            %   Example:
            %
            %       gc = ctrlguis.csdesignerapp.panels.internal.ResponseTunedBlockGC(<tc>);
            %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
            %
            %  See also ctrlguis.csdesignerapp.panels.internal.ResponseTunedBlockTC
            
            %  Copyrihgt 2020 The MathWorks, Inc.
            
            % Create top level layout container.
            layout = uigridlayout(parentLayout,[1 2]);
            layout.Layout.Row = row;
            layout.Layout.Column = col;
            layout.Padding = 10;
            layout.RowHeight = {'fit'};
            layout.RowSpacing = 0;
            layout.ColumnWidth = {'fit','1x'};
            layout.ColumnSpacing = 0;            
            layout.Scrollable = 'off';
            this.Widgets.layout = layout;
                        
            % Add tunable element label
            % tunableElementLabel
            tunableElementLabel = uilabel(layout,'Text',sprintf('%s ', ...
                getString(message('Control:designerapp:ResponseTypeTunedBlockTransferFunction'))), ...
                'HorizontalAlignment','right', ...
                'Tag','tunableElementLabel');
            tunableElementLabel.Layout.Row = 1;
            tunableElementLabel.Layout.Column = 1;
            this.Widgets.tunableElementLabel = tunableElementLabel;
                        
            % Add tunable element drop down list box.
            if isa(this.TCPeer.CDD.getArchitecture,'slTuner')
                tunedBlocks = this.TCPeer.CDD.getArchitecture.getSLTunableBlocks;
            else
                tunedBlocks = this.TCPeer.CDD.getArchitecture.getTunedBlocks;
            end
            tunableBlockList = ctrlguis.csdesignerapp.utils.internal.getTunableBlockPaths(tunedBlocks);
            tunableElementListBox = uidropdown(layout,'Items',tunableBlockList);
            if ~isempty(tunedBlocks)
                tunableElementListBox.Value = tunableBlockList{1};
            end
            tunableElementListBox.Layout.Row = 1;
            tunableElementListBox.Layout.Column = 2;
            tunableElementListBox.ValueChangedFcn = @(src,evt)cbTunableElementListBox(this,src);
            this.Widgets.tunableElementListBox = tunableElementListBox;
            
            widgets = rmfield(this.Widgets,'dialogLayout');
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function buildUI(this)
            % Build widgets.
                        
            % Set dialog size.
            this.UIFigure.Position(3:4) = [400 100];
            
            % Set dialog layout.
            layout = uigridlayout(this.UIFigure,[1 1]);
            layout.Padding = 0;
            layout.RowSpacing = 0;
            layout.ColumnSpacing = 0;            
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
        function cbTunableElementListBox(this,src)
            this.TCPeer.Name = src.Value;
            syncData(this.TCPeer);
        end
    end
    
    %% Hidden QE methods
    methods(Hidden = true)              
        function widget = qeGetWidgets(this)
            widget = this.Widgets;
        end        
    end            
end