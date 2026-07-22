classdef DesignBrowser < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
    %% DESIGNBROWSER - Contains control system designs
    %  DESIGNBROWSER shows stored designs containing the tune block values.
    
    % Copyright 2014-2020 The MathWorks, Inc
    
    %% Properties
    properties(Access=private)
        Tool
        AppData
    end
        
    %% Constructor
    methods
        function this = DesignBrowser(tool)
            %% Construct controller browser
            
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                'Designs',getString(message('Control:designerapp:strDesigns')));
            
            this.Tool = tool;
            this.AppData = getData(tool);
            
            buildUI(this)
            connectUI(this)
            updateUI(this)
        end
    end
    
    %% Public methods
    methods
        %% Overloaded UI methods
        function updateUI(this)
            %% Collect data from local workspace.

            this.Table.Data = getName(this);
        end
        
        %% Preview panel interface methods.
        function name = getName(this,row)
            %% GETNAME - Returns design names
            % GETNAME returns a column vector of names when no row is
            % specified. Otherwise, it returns the specified design name.
            
            designs = getDesignsData(this);
            labels = cell(length(designs),1);
            for ct = 1:length(designs)
                labels{ct,1} = getName(designs(ct));
            end
            
            if nargin==1
                name = labels;
            else
                name = labels(row,1);
            end
        end
        
        function data = getData(this,row)
            %% GETDATA - Returns the specified design value
            % GETDATA returns the specified design value; otherwise, it
            % returns empty value.

            data = [];
            if isempty(row) || row<=0
                disp('row <= 0')
                return
            end
            allData = getDesignsData(this);
            if row <= numel(allData)                
                val = allData(row);
            else
                disp('row > numAllData')
            end
            if isvalid(val)
                data = val;
            else
                disp('invalid val')
            end            
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        
        %% Overloaded UI methods
        function buildUI(this)
            %% Build and configure browser contents
            
            % Error out if invalid name is specified
            this.GenerateValidVarName = false;
            
            % Add dynamic contextmenu.
            this.Table.ContextMenu = createContextMenu(this);
            
            % Prevent interruption when executing one callback.
            this.Table.Interruptible = false;
        end
        
        function connectUI(this)
            %% Connects UI and data listeners
            weakThis = matlab.lang.WeakReference(this);
            % Add data listeners ---
            % Architecture 
            registerDataListeners(this,addlistener(this.AppData, ...
                'ArchitectureChanged', @(src,evt)clearSelection(weakThis.Handle)))
                        
            % Design list
            registerDataListeners(this,addlistener(this.AppData, ...
                'Designs','PostSet',@(src,evt)updateUI(weakThis.Handle)))
            
            % Add UI listeners ---
            % Context menu
            registerUIListeners(this,addlistener(this.Table.ContextMenu, ...
                'ContextMenuOpening',@(src,evt)updateContextMenu(weakThis.Handle,evt)))
            
            % Panel selection 
            registerUIListeners(this,addlistener(this.Panel, ...
                'PropertyChanged', @(src,evt)panelSelected(weakThis.Handle,src,evt)))            
        end
        
        %% Table callbacks
        function DoubleClickCallback(this, row)
            %% Callback function for double-click
            
            openSelection(this,row)
        end
        
        function SelectionCallback(this, rows)
            %% Callback function for data selection
            % It creates event data and request data preview in the preview
            % panel.
            
            eventdata = ctrlguis.csdesignerapp.databrowser.internal.PreviewEventData(rows,{});
            this.notify('PreviewRequested',eventdata);
        end
        
        function RenameCallback(this,row,oldName,newName) %#ok<INUSL>
            %% Callback function for changing design name.
            
            % Update data.
            design = getData(this,row);
            setName(design,newName);
            
            % Update preview area.
            SelectionCallback(this,row) 
        end
    end
    
    %% Private Methods
    methods(Access=private)
        function clearSelection(this)
            %% Clear current selection
            % This function is called when the system architecture is
            % changed. It takes the following actions:
            %     - Remove current selection and
            %     - Clear its data-preview. 
                        
            if ~isempty(this.Table.Selection)
                % Remove current selection.
                this.Table.Selection = [];
                
                
                % Clear current preview.
                if this.Panel.Selected
                    SelectionCallback(this,this.Table.Selection)
                end
            end            
        end
        
        function panelSelected(this,src,evt)
            %% Update preview panel when browser panel is selected.
            
            switch evt.PropertyName
                case 'Selected'
                    % Refresh preview panel when figure panel is selcted.
                    if src.Selected
                        SelectionCallback(this,this.Table.Selection)
                    end
            end
        end
        
        function designs = getDesignsData(this)
            %% Get design data from appdata
            
            designs = getDesigns(this.AppData);
        end
        
        function cmenu = createContextMenu(this)
            %% Create a flat context menu.            
            
            cmenu = uicontextmenu('Parent',this.Figure);
            
            % Add edit menu.
            editMenuItem = uimenu(cmenu, ...
               'Text',getString(message('Control:designerapp:DataBrowserOpenSelection')), ...
               'Tag','OpenSelectionItem' ...
               );
            editMenuItem.MenuSelectedFcn = @(src,evt)cbOpen(this);

            % Add delete menu.
            deleteMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserDelete')), ...
                'Tag','DeleteItem' ...
                );
            deleteMenuItem.MenuSelectedFcn = @(src,evt)cbDelete(this);
                                
            % Add Retrieve menu.
            retrieveMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserRetrieve')), ...
                'Tag','RetrieveItem' ...
                );
            retrieveMenuItem.MenuSelectedFcn = @(src,evt)cbRetrieve(this);
                
            % Add Compare menu.
            compMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserCompare')), ...
                'Tag','CompareItem' ...
                );
            compMenuItem.MenuSelectedFcn = @(src,evt)cbCompare(this);

        end
        
        function updateContextMenu(this,evt)
            %% Update menu state at runtime.
            
            % Get the selected the row.
            interactionInformation = evt.InteractionInformation;
            if evt.ContextObject == this.Table ...
                && ~(interactionInformation.RowHeader || interactionInformation.ColumnHeader)
                row = interactionInformation.DisplayRow;
                col = interactionInformation.DisplayColumn;
                % React when a cell or the white space is clicked.
                if isempty([row col])
                    % Remove current row selections.
                    this.Table.Selection = [];
                    disableContextMenu(this)
                else
                    % Select the right-clicked row.
                    this.Table.Selection = row;
                    
                    % Enable the context menu.
                    enableContextMenu(this)
                    
                    % Update check status of the compare menu item. It is
                    % the first children in the stack.
                    compMenuItem = this.Table.ContextMenu.Children(1);                                        
                    selectedDesign =  getData(this,this.Table.Selection);
                    if isDesignCompared(getPlotsManager(this.Tool),selectedDesign)
                        checked = true;
                    else
                        checked = false;
                    end
                    compMenuItem.Checked = checked;
                end                
            else
                this.Table.Selection = [];
                disableContextMenu(this)
            end
            
            % Update design-view in the preview panel.
            SelectionCallback(this,this.Table.Selection)
        end
             
        function disableContextMenu(this)
            %% Disable context menu.
            
            children = this.Table.ContextMenu.Children;
            for i = 1:numel(children)
                children(i).Visible = false;
            end
        end

        function enableContextMenu(this)
            %% Enable context menu.
            
            children = this.Table.ContextMenu.Children;
            for i = 1:numel(children)
                children(i).Visible = true;
            end
        end
        
        function openSelection(this,row)
            %% Open a design-info dialog.
            
            selectedDesign = getData(this,row);
            openDisplayDialog(selectedDesign,this.Tool);
        end
        
        function cbOpen(this,varargin)
            %% Open selection dialog.
            
            openSelection(this,this.Table.Selection)
        end
        
        function cbDelete(this)
            %% Delete the selected design.
            
            selectedDesign = getData(this,this.Table.Selection);
            removeDesign(this.AppData,selectedDesign);
            delete(selectedDesign)
            
            % Update preview.
            this.Table.Selection = [];
            SelectionCallback(this,this.Table.Selection)
        end
        
        function cbRetrieve(this)
            %% Retrieve the selected design/
            try
                retrieveDesign(this.AppData,getData(this,this.Table.Selection));
            catch ME
                uialert(getAppContainer(this.Tool),ME.message,...
                    getString(message('Control:designerapp:strToolTitleShort')));
            end
        end
        
        function cbCompare(this)
            %% Compare the selected design.
            
            selectedDesign = getData(this,this.Table.Selection);
            plotsManager = getPlotsManager(this.Tool);
            if isDesignCompared(plotsManager,selectedDesign)
                removeDesign(plotsManager,selectedDesign);
            else
                showDesign(plotsManager,selectedDesign);
            end
        end                
    end
    
end