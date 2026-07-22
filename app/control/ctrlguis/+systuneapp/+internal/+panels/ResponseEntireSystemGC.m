classdef ResponseEntireSystemGC < ctrluis.AbstractGC    
    %% View for Input-Output Transfer response of the entire system.
    %   GC = ResponseEntireSystemGC(TC) creates GC using the specified TC.
    %
    %   ResponseEntireSystemGC methods:
    %       createWidgets - Creates a panel containing the graphical
    %                       components and returns all the widgets in a
    %                       flat structure.
    %
    %   Examples:
    %
    %       %% Construct and show GC
    %       gc = systuneapp.internal.panels.ResponseEntireSystemGC(<tc>);
    %       show(gc)
    %
    %       %% Embed the GC panel in a different dialog.
    %       gc = systuneapp.internal.panels.ResponseEntireSystemGC(<tc>);
    %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
    %
    %  See also systuneapp.internal.panels.ResponseEntireSystemTC
    
    % Copyright 2013-2021 The MathWorks, Inc
    
    %% Properties
    properties(Access=private)
        IOTransferGC
        Widgets = struct(...
            'dialogLayout',[], ...
            'layout',[],...
            'responseNameLabel',[], ...
            'responseEditField',[], ...
            'entireSystemLabel',[], ...
            'okButton',[],...
            'cancelButton',[],...
            'buttonPanel',[] ...
            );
        Width = 410;
        Height = 375;
    end

    %% Constructor & destructor.    
    methods
        function this = ResponseEntireSystemGC(tcpeer)
            this = this@ctrluis.AbstractGC(tcpeer);
            this.Name = "CSTApp_ResponseEntireSystemDialog_" + matlab.lang.internal.uuid;
            this.Title = getString(message('Control:systunegui:ResponseTypeIOTransferFunction'));

            registerUIListeners(this, addlistener(this, ...
                'CloseEvent', @(es, ed)delete(this)))            
        end

        function delete(this)
            %% Deletes handle objects.

            cleanupUI(this)
            clear this
        end
    end
    
    %% Public methods
    methods
        function updateUI(this)
            name = this.TCPeer.Name;
            if isempty(name)
                return
            end
            this.Widgets.responseEditField.Value = name;
        end
        
        function [row, wt] = createIOWidgets(this, name, parentLayout, row)
            
            if isempty(name)
                field = getString(message('Control:systunegui:ResponseName'));
            else
                field = name;
            end 
            container = uigridlayout(parentLayout,[2 2]);
            container.Layout.Row = row;
            container.Layout.Column = 1;
            container.RowHeight = {'fit','fit'};
            container.ColumnWidth = {'fit','1x'};
            container.RowSpacing = 5;
            container.ColumnSpacing = 5;
            container.Padding = this.Padding;
            
            responseNameLabel = uilabel(container,...
                'Text',getString(message('Control:systunegui:ResponseName')), ...
                'HorizontalAlignment','left', ...
                'Tag','ResponseNameLabel');
            responseNameLabel.Layout.Row = 1;
            responseNameLabel.Layout.Column = 1;
            this.Widgets.responseNameLabel = responseNameLabel;
            
            % Text edit field: Response name
            responseEditField = uieditfield(container,...
                'Value',sprintf('%s', field), ...
                'Tag','ResponseNameText' ...
                );
            responseEditField.Layout.Row = 1;
            responseEditField.Layout.Column = 2;
            this.Widgets.responseEditField = responseEditField;
            
            % Entire system label
            entireSystemLabel = uilabel(container,...
                'Text',getString(message('Control:systunegui:ResponseTypeEntireSystemTransferFunction')), ...
                'HorizontalAlignment','left', ...
                'Tag','EntireSystemLabel');
            entireSystemLabel.Layout.Row = 2;
            entireSystemLabel.Layout.Column = [1 2];
            this.Widgets.entireSystemLabel = entireSystemLabel;
            
            wt = struct(...
                'container',container, ...
                'responseNameLabel',responseNameLabel, ...
                'responseEditField',responseEditField, ...
                'entireSystemLabel',entireSystemLabel ...
                );
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
            %       entireSystemLabel - Entire system label
            %       okButton          - OK button
            %       cancelButton      - Cancel button
            %
            %   It creates the widgets using the following layout:
            %
            %       -----------------------------------------
            %       | responseNameLabel | responseEditField  |
            %       -----------------------------------------
            %       | entireSystemLabel                      |
            %       -----------------------------------------
            %       |             | okButton | cancelButton  |
            %       -----------------------------------------
            %
            %   Example:
            %
            %       gc = systuneapp.internal.panels.ResponseEntireSystemGC(<tc>);
            %       widgets = createWidgets(gc,<parentLayout>,<row>,<col>);
            %
            %  See also systuneapp.internal.panels.ResponseEntireSystemTC
            
            %  Copyrihgt 2013-2021 The MathWorks, Inc.
            
            % Create top level layout container.
            numRows = 2;
            rowHeight = {'fit','fit'};
            if this.ShowButtons
                numRows = numRows + 2;
                rowHeight = [rowHeight,{'1x','fit'}];
            end
            layout = uigridlayout(parentLayout,[numRows 1],'Scrollable','off');
            layout.Layout.Row = row;
            layout.Layout.Column = col;
            layout.Padding = this.Padding;
            layout.RowHeight = rowHeight;
            layout.RowSpacing = this.RowSpacing;
            layout.ColumnSpacing = this.ColumnSpacing;
            layout.ColumnWidth = {'1x'};
            this.Widgets.layout = layout;
            
            % Label: Response name
            row = 1;
            if isempty(varargin)
                name = '';
            else
                name = varargin{1};
            end
            createIOWidgets(this, name, layout, row);
                        
            if this.ShowButtons
                % Create button panel and get the button layout.
                buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                    layout,["ok" "cancel"]);                
                this.Widgets.buttonPanel = buttonPanel;
                
                buttonLayout = getWidget(buttonPanel);
                buttonLayout.Layout.Row = numRows;
                buttonLayout.Layout.Column = 1;
                buttonLayout.Padding = [0 0 0 this.RowSpacing];
                
                % Attach callback functions
                buttonPanel.OKButton.ButtonPushedFcn = @(src,data) cbOkButton(this);
                buttonPanel.CancelButton.ButtonPushedFcn = @(src,data) cbCancelButton(this);
                
                this.Widgets.okButton = buttonPanel.OKButton;
                this.Widgets.cencelButton = buttonPanel.CancelButton;
            end
            
            widgets = rmfield(this.Widgets,'dialogLayout');
            if ~this.ShowButtons
                widgets = rmfield(this.Widgets,{'buttonPanel','okButton','cancelButton'});
            end
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function buildUI(this)
            % Build widgets.
                        
            % Set dialog size.
            this.UIFigure.Position(3:4) = [this.Width this.Height];
            
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
                ResponseNames = this.TCPeer.CDD.getResponseName;
                if ~this.TCPeer.Create
                    ResponseNames = setdiff(ResponseNames,this.TCPeer.ResponseWrapper.Response.Name);
                end
                if any(strcmp(ResponseNames,this.TCPeer.Name))
                    error(message('Control:systunegui:ResponseNameConflict',this.TCPeer.Name));
                else
                    setResponse(this.TCPeer,true)
                end
                delete(this)
            catch ME
                delete(restorePointer)
                if ~this.IsWidgetValid
                    rethrow(ME);
                else
                    currValue = this.Widgets.layout.RowHeight{2};
                    fcn = [];
                    if this.UIFigure.Position(4) < 200
                        setResponsePanelHeight(this,200)
                        fcn = @(s,e)setResponsePanelHeight(this,currValue);
                    end

                    uialert(this.getWidget,ME.message,this.Title,'CloseFcn',fcn);                    
                end
            end
        end       
        
        function setResponsePanelHeight(this,value)
            %% Sets response panel's height.

            this.Widgets.layout.RowHeight{2} = value;
            pack(this)
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
            
            if ~this.IsWidgetValid
                widgets = rmfield(widgets,'dialogLayout');
            end
        end
    end
end