classdef ResponseBrowser < ...
        matlab.ui.internal.databrowser.TableDataBrowser & ...
        matlab.ui.internal.databrowser.PreviewPanelInterface
    %% RESPONSEBROWSER - Contains system responses
    
    % Copyright 2014-2020 The MathWorks, Inc
    
    
    %% Properties
    properties(Access=private)
        Tool
        AppData
        ResponseDataListeners
    end
    
    properties(SetAccess=private,GetAccess=?matlab.unittest.TestCase)
        LastOpenedDialog
    end
    
    %% Constructor
    methods        
        function this = ResponseBrowser(tool)
            %% Construct controller browser
            
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                'Responses',getString(message('Control:designerapp:strResponses')));
            
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
            
            resetResponseDataListeners(this)
            responses = getResponseData(this);
            for ct = 1:length(responses)
                this.ResponseDataListeners = [this.ResponseDataListeners; ...
                    addlistener(responses(ct),'DefinitionChanged',@(src,evt)updateUI(this))];
            end
        end
        
        %% Preview panel interface methods.
        function name = getName(this,row)
            %% GETNAME - Returns response names
            % GETNAME returns a column vector of names when no row is
            % specified. Otherwise, it returns the specified response name.
            
            responses = getResponseData(this);
            labels = cell(length(responses),1);
            for ct = 1:length(responses)
                labels{ct,1} = getName(responses(ct));
            end
            
            if nargin==1
                name = labels;
            else
                name = labels(row,1);
            end
        end
        
        function data = getData(this,row)
            %% GETDATA - Returns the specified response value
            % GETDATA returns the specified response value; otherwise, it
            % returns empty value.
            
            data = [];
            if isempty(row) || row<=0
                disp('row <= 0')
                return
            end
            allData = getResponseData(this);
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
                'ArchitectureChanged',@(src,evt)clearSelection(weakThis.Handle)));

            % Response list
            registerDataListeners(this,addlistener(this.AppData, ...
                'Responses','PostSet',@(src,evt)updateUI(weakThis.Handle)));
            
            % Add UI listeners ---
            % Context menu
            registerUIListeners(this,addlistener(this.Table.ContextMenu, ...
                'ContextMenuOpening',@(src,evt)updateContextMenu(weakThis.Handle,evt)))
            
            % Panel selection 
            registerUIListeners(this,addlistener(this.Panel,'PropertyChanged', ...
                @(src,evt)panelSelected(weakThis.Handle,src,evt)))
        end

        function cleanupUI(this)
            %% Clean up resources
            
            resetResponseDataListeners(this)
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
            
            eventdata = ctrlguis.csdesignerapp.databrowser.internal.PreviewEventData(rows,{'ValueChanged','DefinitionChanged'});
            this.notify('PreviewRequested',eventdata);
        end
        
        function RenameCallback(this,row,oldName,newName) %#ok<INUSL>
            %% Callback function for changing data name.
            % It updates the data using the user specified new data name.
            
            % Update data.
            data = getData(this,row);
            setName(data,newName)
            
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
        
        function resetResponseDataListeners(this)
            %% Delete response listeners.
            
            if ~isempty(this.ResponseDataListeners)
                delete(this.ResponseDataListeners)
                this.ResponseDataListeners = [];
            end
        end
        
        function cmenu = createContextMenu(this)  
            %% Create a flat context menu.            
            
            import ctrlguis.csdesignerapp.plot.internal.PlotEnum
            
            cmenu = uicontextmenu('Parent',this.Figure);
                
            % Add edit menu
            editMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserOpenSelection')), ...
                'Tag','OpenSelectionItem' ...
                );
            editMenuItem.MenuSelectedFcn = @(src,evt)cbOpen(this);
            
            % Add delete menu
            deleteMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserDelete')), ...
                'Tag','DeleteItem' ...
                );
            deleteMenuItem.MenuSelectedFcn = @(src,evt)cbDelete(this);
            
            % Add Plot
            plotMenuItem = uimenu(cmenu, ...
                'Text',getString(message('Control:designerapp:DataBrowserPlot')), ...
                'Tag','PlotItem', ...
                'Separator',true ...
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
            %% Update menu state at runtime.
            
            % Get the selected row.
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
            
            selectedResponse = getData(this,row);
            this.LastOpenedDialog = editResponse(this.AppData, ...
                selectedResponse,getAppContainer(this.Tool),'EAST');
            registerDialog(this.Tool,this.LastOpenedDialog);
            addlistener(this.LastOpenedDialog,'CloseEvent',...
                @(es,ed) deleteDialog(this.Tool,es.Name));
        end
        
        function cbOpen(this,varargin)
            %% Open selection dialog.
            
            openSelection(this,this.Table.Selection)
        end
        
        function cbDelete(this)
            %% Delete the selected response.
            
            selectedResponse = getData(this,this.Table.Selection);
            removeResponse(this.AppData,selectedResponse);
            delete(selectedResponse)
            
            % Update preview.
            this.Table.Selection = [];
            SelectionCallback(this,this.Table.Selection)            
        end
        
        function Data = getResponseData(this)
            %% Get response data.
            
            Data = getResponses(this.AppData);
        end
        
        function cbPlot(this,plotType)
            %% Create response plot.
            
            createResponsePlot(getPlotsManager(this.Tool), ...
                getData(this,this.Table.Selection),plotType)
        end

    end
    
    methods(Hidden)
        
        function qeOpen(this,row)
            arguments
                this
                row = []
            end
            if ~isempty(row)
                this.Table.Selection = row;
            end
            cbOpen(this)
        end
        
        function qePlot(this,plotType,row)
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
                row = []
            end
            if ~isempty(row)
                this.Table.Selection = row;
            end
            cbPlot(this,ctrlguis.csdesignerapp.plot.internal.PlotEnum(plotType));

        end
        
    end
    
end


