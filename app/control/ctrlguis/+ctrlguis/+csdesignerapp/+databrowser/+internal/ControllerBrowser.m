classdef ControllerBrowser < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
    %% CONTROLLERBROWSER - Contains tunable and fixed blocks
    
    % Copyright 2014-2020 The MathWorks, Inc
    
    %% Properties
    properties(Access=private)
        Tool
        AppData
    end
    
    %% Constructor
    methods        
        function this = ControllerBrowser(tool)
            %% Construct controller browser
            
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                'Controllers',getString(message('Control:designerapp:strControllersAndFixedBlocks')));
            
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
            %% GETNAME - Returns data names
            % GETNAME returns a column vector of names when no row is
            % specified. Otherwise, it returns the specified data name.
            
            controllers = getControllerData(this);
            fixedBlocks = getFixedBlockData(this);
            allData = [controllers;fixedBlocks];
            labels = cell(length(allData),1);
            for ct = 1:length(allData)
                labels{ct,1} = allData(ct).Name;
            end
            
            if nargin==1
                name = labels;
            else
                name = labels(row,1);
            end
        end
        
        function data = getData(this,row)
            %% GETDATA - Returns the specified data value
            % GETDATA returns the specified data value; otherwise, it
            % returns empty value.

            data = [];
            if isempty(row) || row<=0
                disp('row <= 0')
                return
            end
            allData = [getControllerData(this);getFixedBlockData(this)];
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
        
        function resetContextMenu(this)
            unregisterUIListeners(this,'ContextMenuOpening');
            delete(this.Table.ContextMenu);
            this.Table.ContextMenu = createContextMenu(this);
            registerUIListeners(this,addlistener(this.Table.ContextMenu, ...
                'ContextMenuOpening',@(src,evt)updateContextMenu(this,evt)),...
                'ContextMenuOpening')
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
            registerDataListeners(this,addlistener(this.AppData, ...
                'ArchitectureChanged', @(src,evt)updateUI(weakThis.Handle)))

            % Tunable blosk list
            registerDataListeners(this,addlistener(this.AppData, ...
                'TunableBlocksListChanged',@(src,evt)updateUI(weakThis.Handle)))
            
            % Add UI listeners ---
            % Context menu
            registerUIListeners(this,addlistener(this.Table.ContextMenu, ...
                'ContextMenuOpening',@(src,evt)updateContextMenu(weakThis.Handle,evt)),...
                'ContextMenuOpening')
            
            % Panel selection 
            registerUIListeners(this,addlistener(this.Panel, ...
                'PropertyChanged', @(src,evt)panelSelected(weakThis.Handle,src,evt)))            
        end

        %% Table callbacks
        function DoubleClickCallback(this, row)
            %% Callback function for double-click
            
            %SelectionCallback(this,rows)
            openSelection(this,row)
        end
        
        function SelectionCallback(this, rows)
            %% Callback function for data selection
            % It creates event data and request data preview in the preview
            % panel.
            
            eventdata = ctrlguis.csdesignerapp.databrowser.internal.PreviewEventData(rows,{'ValueChanged'});
            this.notify('PreviewRequested',eventdata);
        end
        
        function RenameCallback(this,row,oldName,newName) %#ok<INUSL>
            %% Callback function for changing data name.
            % It updates the data using the user specified new data name.
            
            % Update data.
            data = getData(this,row);
            data.Name = newName;
            
            % Update preview area.
            SelectionCallback(this,row) 
        end
    end
    
    %% Private methods
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
        
        function updatePreview(this)
            %% Update contents of the preview panel.
            
            row = this.Table.Selection;
            if ~isempty(row)
                SelectionCallback(this,row) 
            end            
        end
        
        function resetValueChangedListeners(this)
            %% Delete listeners.
            
            if ~isempty(this.ValueChangedListeners)
                delete(this.ValueChangedListeners)
                this.ValueChangedListeners = [];
            end
        end
        
        function cmenu = createContextMenu(this)
            %% Create a flat context menu.            
            import ctrlguis.csdesignerapp.plot.internal.PlotEnum
            
            cmenu = uicontextmenu('Parent',this.Figure);
            
            % Add edit menu.
            editMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserOpenSelection')), ...
                'Tag','OpenSelectionItem' ...
                );
            editMenuItem.MenuSelectedFcn = @(src,evt)cbOpen(this);
            
            % Add updateblocks and delete menu.
            data = this.AppData;
            if data.isSimulink
                % Delete menu
                deleteMenuItem = uimenu(cmenu, ...
                    'Text',getString(message('Control:designerapp:DataBrowserDelete')), ...
                    'Tag','DeleteItem' ...
                    );
                deleteMenuItem.MenuSelectedFcn = @(src,evt)cbDelete(this);
                
                % Update this block
                updateThisBlockMenuItem = uimenu(cmenu, ...
                    'Text',getString(message('Control:designerapp:DataBrowserUpdateThisBlock')), ...
                    'Tag','UpdateThisBlockMenuItem' ...
                    );
                updateThisBlockMenuItem.MenuSelectedFcn = @(src,evt)cbUpdateBlock(this);
                
                % Update all blocks
                updateAllBlocksMenuItem = uimenu(cmenu, ...
                    'Text',getString(message('Control:designerapp:DataBrowserUpdateAllBlocks')), ...
                    'Tag','UpdateAllBlocksMenuItem' ...
                    );
                updateAllBlocksMenuItem.MenuSelectedFcn = @(src,evt)cbUpdateAllBlocks(this);
            end
            
            % Add Plot menu.
            plotMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserPlot')), ...
                'Separator',true, ...
                'Tag','PlotItem' ...
                );            
            plotTypes = PlotEnum.getPlotTypes(false);
            for ct = 1:length(plotTypes)
                plotTypeMenuItem = uimenu(plotMenuItem, ...
                    'Text',plotTypes(ct).Tag, ...
                    'Tag',['PlotTypeMenuItem',plotTypes(ct).Tag] ...
                    );
                plotTypeMenuItem.MenuSelectedFcn = @(src,evt)cbPlot(this,plotTypes(ct));
            end
        end                                

        function updateContextMenu(this,evt)
            %% Enable/disable menu items based on data selection.
            
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
                    
                    % Enable only edit menu if a fixed block is selected.
                    if isa(getData(this,row), ...
                            'ctrlguis.csdesignerapp.data.architectures.internal.FixedBlock')
                        disableContextMenu(this)
                        this.Table.ContextMenu.Children(end).Visible = true;
                        return
                    end
                                                            
                    % Enable Edit and plot menus.
                    children = this.Table.ContextMenu.Children;
                    children(1).Visible = true;   % Plot: first children in stack
                    children(end).Visible = true; % Edit: last children in stack
                    
                    % Enable/disable simulink menu items.
                    if this.AppData.isSimulink
                        val = true;
                    else
                        val = false;
                    end
                    for i = 2:numel(children)-1
                        children(i).Visible = val;
                    end                        
                end
            else
                this.Table.Selection = [];
                disableContextMenu(this)
            end
            
            % Update data-view in the preview panel.
            SelectionCallback(this,this.Table.Selection)
        end
             
        function disableContextMenu(this)
            %% Disable context menu.
            
            children = this.Table.ContextMenu.Children;
            for i = 1:numel(children)
                children(i).Visible = false;
            end
        end
        
        function controllers = getControllerData(this)
            %% Get controller data from appdata.
            
            controllers = getTunableBlocks(this.AppData);
        end
        
        function fixedBlocks = getFixedBlockData(this)
            %% Get controller data from appdata.
            
            fixedBlocks = getFixedBlocks(this.AppData);
        end
        
        function openSelection(this,row)
            %% Open data editor for a tunable block.
            
            data = getData(this,row);
            if isa(data,'ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock')
                editCompensator(this.Tool,data)
            else
               openDisplayDialog(data, this.Tool);
            end
        end
        
        function cbOpen(this)
            %% Callback function to open data editor.
            
            openSelection(this,this.Table.Selection)
        end
        
        function cbDelete(this)
            %% Callback function to remove a tunable block.
            removeTunableBlock(this.AppData,getData(this,this.Table.Selection));
            
            % Update preview.
            this.Table.Selection = [];
            SelectionCallback(this,this.Table.Selection)
        end
        
        function cbUpdateBlock(this)
            %% Callback function to update a simulink block value.
            try
                updateSimulinkBlock(this.AppData,getData(this,this.Table.Selection));
            catch ME
                uialert(getAppContainer(this.Tool),ME.message,...
                    getString(message('Control:designerapp:strToolTitleShort')));
            end
        end
        
        function cbUpdateAllBlocks(this)
            %% Callback function to update all simulink block values.
            try
                updateSimulinkBlock(this.AppData);
            catch ME
                uialert(getAppContainer(this.Tool),ME.message,...
                    getString(message('Control:designerapp:strToolTitleShort')));
            end
        end    
        
        function cbPlot(this,plotType)
            %% Callback function to plot the selected data.
            
            data = getData(this,this.Table.Selection);
            if isa(data,'ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock')
                createTunedBlockPlot(getPlotsManager(this.Tool),data,plotType)
            else
                createFixedBlockPlot(getPlotsManager(this.Tool),data,plotType)
            end
        end
    end
    
    methods(Hidden)
        
        function qeOpen(this)
            cbOpen(this)
        end
        
        function qePlot(this,plotType)
            % Test method to create response plot of selected items in the
            % controller browser (only supported for Controllers/Tunable
            % Blocks)
            %
            % qePlot(controllerBrowser,plotType)
            %   plotType should be a string or character array and one of
            %   Step|Bode|Impulse|Nyquist|Nichols|SingularValue|PoleZeroMap|IOPoleZeroMap
            arguments
                this
                plotType {mustBeMember(plotType,["Step","Bode","Impulse","Nyquist","Nichols",...
                                                 "SingularValue","PoleZeroMap","IOPoleZeroMap"])}
            end
            cbPlot(this,ctrlguis.csdesignerapp.plot.internal.PlotEnum(plotType));
        end
        
    end
    
end


