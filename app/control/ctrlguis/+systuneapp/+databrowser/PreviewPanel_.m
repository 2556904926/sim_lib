classdef PreviewPanel_ < matlab.ui.internal.databrowser.AbstractDataBrowser
    % A special preview panel that can be used together with data browsers
    % Differs from the original PreviewPanel class slightly-- only displays
    % data, not " Name = 'Data' "
    % in AppContainer.  It is a subclass of AbstractDataBrowser.
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.databrowser.PreviewPanel.PreviewPanel">PreviewPanel</a>
    %
    % Properties:
    %   <a href="matlab:help matlab.ui.internal.databrowser.PreviewPanel.TextArea">TextArea</a>
    %
    % Public Methods:
    %   <a href="matlab:help matlab.ui.internal.databrowser.PreviewPanel.monitor">monitor</a>
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.positionFigureOnAppContainer">positionFigureOnAppContainer</a>
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.setPreferredHeight">setPreferredHeight</a>
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.setPreferredWidth">setPreferredWidth</a>
    %   <a href="matlab:help matlab.ui.internal.databrowser.PreviewPanel.updateUI">updateUI</a>
    %
    % See also matlab.ui.internal.databrowser.TableDataBrowser, matlab.ui.internal.databrowser.AbstractDataBrowser
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (SetAccess = private)
        % Property "TextArea": handle to the uitextarea (read-only)
        %
        %   Use this property to customize desired textarea attributes.
        %
        %   Example:
        %       this.Table.FontSize = 10;
        TextArea
    end
    
    properties (Access = private)
        ValueChangedListener
    end
    
    %% public methods
    methods
        
        function this = PreviewPanel_(name, title)
            % Constructor "PreviewPanel":
            %
            %   Create a preview panel used in AppContainer.
            %
            %       pnl = PreviewPanel(name, title);
            %
            %   where "name" is the name of the panel object for reference
            %   and "title" is displayed in the app.
            this = this@matlab.ui.internal.databrowser.AbstractDataBrowser(name, title);
            buildUI(this);
            connectUI(this);
        end
        
        function updateUI(this, txt)
            % Method "updateUI":
            %
            %   Refresh preview panel with a new string.
            %
            %       updateUI(this, string);
            %
            %   where "string" is the new value set to uitextarea.
            this.TextArea.Value = txt;
        end
        
        function monitor(this, databrowser)
            % Method "monitor":
            %
            %   Allow the preview panel to monitor the selection change in
            %   the data browser and refresh preview contents accordingly.
            %
            %       monitor(this, databrowser);
            %
            %   where "databrowser" is a data browser subclass.
            %
            %   To use "monitor", the data browser subclass must (1)
            %   inherit from the "PreviewPanelInterface" class and
            %   implement the "getData" and "getName" methods; and (2) have
            %   a "SelectionChanged" event.
            lis = addlistener(databrowser,'PreviewRequested',@(src,event) DataBrowserSelectionChanged(this,src,event));
            registerUIListeners(this, lis);
        end
        
    end
    
    methods(Access = protected)      
        function buildUI(this)
            % use 1x1 uigridlayout for auto-resizing
            g = uigridlayout(this.Figure);
            g.ColumnWidth = {'1x'};
            g.RowHeight = {'1x'};
            g.Padding = [0 0 0 0];
            % table
            txt = uitextarea(g);
            txt.Editable = false;
            txt.FontName = 'Courier';
            txt.Tag = strcat('txtarea',this.Name);
            this.TextArea = txt;
        end
        
        function DataBrowserSelectionChanged(this,src,event)
            resetValuChangedListener(this)
            % display information of a single-selected plant model
            idx = event.Index;
            if isempty(idx)
                % no row is selected
                str = '';
            elseif isscalar(idx)
                % a single row is selection
                val = getData(src,idx);
                if isempty(val) || ~isvalid(val)
                    str = '';
                else
                             
                    % Get text description of the data.
                    str = getDisplayPreviewText(val);
                end
            else
                str = '';
            end
            updateUI(this, str)
        end
        
        function cleanupUI(this)
            resetValuChangedListener(this)
        end
    end
    
    methods(Access = private)        
        function resetValuChangedListener(this)
            %% Delete current value changed listener.
            if ~isempty(this.ValueChangedListener)
                delete(this.ValueChangedListener)
                this.ValueChangedListener = [];
            end
        end
    end
end