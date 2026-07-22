classdef ResponseInputOutputTransferGC < ctrluis.AbstractGC    
    %% Graphical component (GC) for Input-Output Transfer response
    %   
    %   GC = ResponseInputOutputTransferGC(TC) creates GC using the specified TC.
    %
    %   ResponseInputOutputTransferGC methods:
    %       createWidgets - Creates a panel containing the graphical
    %                       components and returns all the widgets in a
    %                       flat structure.
    %
    %   Examples:
    %
    %       %% Construct and show GC
    %       gc = controllib.widget.internal.responseplot.ResponseInputOutputTransferGC(<tc>);
    %       show(gc)
    %
    %       %% Embed the GC panel in a different dialog.
    %       gc = controllib.widget.internal.responseplot.ResponseInputOutputTransferGC(<tc>);
    %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
    %
    %  See also controllib.widget.internal.responseplot.ResponseInputOutputTransferTC
    %           controllib.widget.internal.responseplot.IOTransferGC 
    %           controllib.widget.internal.signallist.SignalListPanel
    
    % Copyright 2013-2021 The MathWorks, Inc
    
    %% Properties
    properties(Access=private)
        IOTransferGC
        Widgets = struct(...
            'dialogLayout',[], ...
            'layout',[],...
            'responseNameLabel',[], ...
            'responseEditField',[], ...
            'signalListPanels',[], ...
            'architectureLabel',[],...
            'architectureImage',[],...
            'buttonPanel',[] ...
            );
        IconHeight = 200;
        IconWidth = 515;
        DialogWidth = 535;
        DialogHeight = 625;
        LabelHeight = 20;
    end    
    
    %% Constructor    
    methods
        function this = ResponseInputOutputTransferGC(tcpeer)
            this = this@ctrluis.AbstractGC(tcpeer);
            this.Name = "CSApp_ResponseInputOutputTransferDialog_" + matlab.lang.internal.uuid;
            this.Title = getString(message('Control:designerapp:ResponseTypeIOTransferFunction'));
        end
    end
    
    %% Public methods
    methods
        function updateUI(this)         
            this.Widgets.responseEditField.Value = this.TCPeer.Name;
        end
        
        function [row, wt] = createIOWidgets(this, name, layout, row)
            
            if isempty(name)
                field = getString(message('Control:designerapp:ResponseName'));
            else
                field = name;
            end 
            responseNameLabel = uilabel(layout,...
                'Text',sprintf('%s ',getString(message('Control:designerapp:ResponseName'))), ...
                'Tag','ResponseNameLabel');
            responseNameLabel.Layout.Row = row;
            responseNameLabel.Layout.Column = 1;
            
            % Text edit field: Response name
            responseEditField = uieditfield(layout,...
                'Value',sprintf('%s', field), ...
                'Tag','ResponseNameText');
            responseEditField.Layout.Row = row;
            responseEditField.Layout.Column = [2 4];
            
            % Signal panel lists
            row = row + 1;
            this.IOTransferGC = createView(this.TCPeer.IOTransferTC);
            this.IOTransferGC.Padding = this.Padding;
            signalListPanel = createWidgets(this.IOTransferGC,layout,row,[1 4]); 
            
            wt = struct('responseNameLabel',responseNameLabel, ...
                        'responseEditField',responseEditField, ...
                        'signalListPanel',signalListPanel);

        end
        
        function widgets = createWidgets(this,parentLayout,row,col,varargin)
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
            %       layout            - Top level layout container
            %       responseNameLabel - Response name label
            %       responseEditField - Edit field to update the response
            %                           name
            %       signalListPanels  - Input, output, and opening signal
            %                           list panels
            %       architectureLabel - Architecture label
            %       architectureImage - Architecture image
            %       helpButton        - Help button
            %       okButton          - OK button
            %       cancelButton      - Cancel button
            %
            %   It creates the widgets using the following layout:
            %
            %       -----------------------------------------
            %       | responseNameLabel | responseEditField |
            %       -----------------------------------------
            %       | signalListPanels                      |
            %       -----------------------------------------
            %       | architectureLabel                     |
            %       -----------------------------------------
            %       | architectureImage                     |
            %       -----------------------------------------
            %       | helpButton | okButton | cancelButton  |
            %       -----------------------------------------
            %
            %   Example:
            %
            %       gc = controllib.widget.internal.responseplot.ResponseInputOutputTransferGC(<tc>);
            %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
            %
            %   See also controllib.widget.internal.responseplot.ResponseInputOutputTransferTC
            %            controllib.widget.internal.responseplot.IOTransferGC
            %            controllib.widget.internal.signallist.SignalListPanel
            
            %  Copyrihgt 2020-2021 The MathWorks, Inc.
            
            % Create top level layout container.
            numRows = 2;
            rowHeight = {'fit','1x'};
            archIcon = getArchitectureIcon(this.TCPeer.CDD);
            if ~isempty(archIcon)
                numRows = numRows + 2;
                rowHeight = [rowHeight,{'fit','fit'}];
            end
            if this.ShowButtons
                numRows = numRows + 1;
                rowHeight = [rowHeight,{'fit'}];
            end
            layout = uigridlayout(parentLayout,[numRows 4]);
            layout.Layout.Row = row;
            layout.Layout.Column = col;
            layout.Padding = this.Padding;
            layout.RowHeight = rowHeight;
            layout.RowSpacing = this.RowSpacing;
            layout.ColumnWidth = {'fit','1x','fit','fit'};
            layout.ColumnSpacing = this.ColumnSpacing;
            this.Widgets.layout = layout;
            
            % Label: Response name
            row = 1;            
            if isempty(varargin)
                name = '';
            else
                name = varargin{1};
            end
            [row, wt] = createIOWidgets(this, name, layout, row);
            this.Widgets.responseNameLabel = wt.responseNameLabel;
            this.Widgets.responseEditField = wt.responseEditField;
            this.Widgets.signalListPanels = wt.signalListPanel;
                        
            if ~isempty(archIcon)            
                % Label: Architecture
                row = row + 1;
                architectureLabel = uilabel(layout,...
                    'Text',getString(message('Control:designerapp:ArchitectureResponse')), ...
                    'Tag','lblConfig');
                architectureLabel.Layout.Row = row;
                architectureLabel.Layout.Column = 1;
                this.Widgets.architectureLabel = architectureLabel;
                
                % Image: Architecture
                row = row + 1;
                archPanel = uipanel(layout,'BorderType','none');
                archPanel.Layout.Row = row;
                archPanel.Layout.Column = [1 4];                
                
                archPanelLayout = uigridlayout(archPanel,[1 3]);
                archPanelLayout.Padding = 0;
                archPanelLayout.RowHeight = {200};
                archPanelLayout.RowSpacing = 0;
                archPanelLayout.ColumnWidth = {'1x',515,'1x'};
                archPanelLayout.RowSpacing = 0;
                archPanelLayout.Scrollable = true;
                
                architectureImage = uiimage(archPanelLayout, ...
                    'ImageSource',archIcon.Description, ...
                    'ScaleMethod','stretch', ...
                    'Tag','lblConfig');
                architectureImage.Layout.Row = 1;
                architectureImage.Layout.Column = 2;
                this.Widgets.architectureImage = architectureImage;                 
            else
                if this.IsWidgetValid
                    this.UIFigure.Position(3) = this.DialogWidth - this.IconWidth/4;
                    this.UIFigure.Position(4) = this.DialogHeight ...
                        - this.IconHeight-3*this.RowSpacing-this.LabelHeight; % Approximate architecture panel height
                end
            end
            
            
            if this.ShowButtons
                row = row + 1;
                col = [1 4];

                % Create button panel and get the button layout.
                buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                    layout,["help" "ok" "cancel"]);
                buttonPanel.HelpButton.Visible = this.ShowHelpButton;
                this.Widgets.buttonPanel = buttonPanel;
                
                buttonLayout = getWidget(buttonPanel);
                buttonLayout.Layout.Row = row;
                buttonLayout.Layout.Column = col;
                buttonLayout.Padding = [0 0 0 this.RowSpacing];
                
                % Attach callback functions
                buttonPanel.HelpButton.ButtonPushedFcn = @(src,data) cbHelpButton(this);
                buttonPanel.OKButton.ButtonPushedFcn = @(src,data) cbOkButton(this);
                buttonPanel.CancelButton.ButtonPushedFcn = @(src,data) cbCancelButton(this);
            end
            
            widgets = rmfield(this.Widgets,'dialogLayout');
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function buildUI(this)
            % Build widgets.
                        
            % Set dialog size.
            this.UIFigure.Position(3:4) = [535 625];
            
            % Create dialog layout.
            layout = uigridlayout(this.UIFigure,[1 1]);
            layout.RowSpacing = 0;
            layout.ColumnSpacing = 0;
            layout.Padding = this.RowSpacing;
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
        function cbOkButton(this)
            fig = this.UIFigure;
            currPointer = controllib.widget.internal.utils.setPointer(fig,'watch');
            restorePointer = onCleanup(@()controllib.widget.internal.utils.setPointer(fig,currPointer));
            try
                this.TCPeer.Name = this.Widgets.responseEditField.Value;
                if isempty(this.TCPeer.Input) || isempty(this.TCPeer.Output)
                    error(getString(message(['Control:designerapp:' 'Response' this.TCPeer.Type 'Error'])));
                else
                    responseNames = this.TCPeer.CDD.getResponseName;
                    if ~this.TCPeer.Create
                        responseNames = setdiff(responseNames,getName(this.TCPeer.ResponseWrapper));
                    end
                    if any(strcmp(responseNames,this.TCPeer.Name))
                        error(message('Control:designerapp:ResponseNameConflict',this.TCPeer.Name));
                    else
                        setResponse(this.TCPeer,true)
                    end
                end
                delete(this)
            catch ME
                delete(restorePointer)
                if ~this.IsWidgetValid
                    rethrow(ME);
                else
                    uialert(this.getWidget,ME.message,this.Title);                    
                end
            end
        end       
        
        function cbHelpButton(this)
            if isSimulink(this.TCPeer.CDD.getArchitecture)
                ctrlguihelp('CSD_SL_EditResponseHelp','CSHelpWindow');
            else
                ctrlguihelp('CSD_ML_EditResponseHelp','CSHelpWindow');
            end
        end
        
        function cbCancelButton(this)
            % Callback function for cancel button.
            
            delete(this)
        end
    end
    
    %% Hidden methods
    methods(Hidden = true)
        function widgets = qeGetWidgets(this)
            widgets = this.Widgets;
            widgets.signalListPanels = qeGetWidgets(this.IOTransferGC);
            
            if ~this.IsWidgetValid
                widgets = rmfield(widgets,'dialogLayout');
            end
        end
    end
end
