classdef ModelPanel < matlab.ui.internal.databrowser.TableDataBrowser
    
    %% MODEL PANEL
    % -- is created using the Abstract Table Data Browser.
    %    If you plan on adding a new this panel component, create a new
    %    class to accommodate it and later use callbacks in
    %    mrtool.internal.ModelReducerApp.addDataBrowser
    % 
    % -- is a table of models that can be reduced and have been reduced.
    %
    % -- interacts with mrtool.databrowser.internal.PreviewPanel to show
    %    contents of Models in a Preview Panel, rendered beneath the Model
    %    Browser.
    %
    % -- The browser is created by overloading methods from base class -
    %    databrowser.TableBrowser & datathis.PreviewPanelInterface.
    %
    % ******************* INFO ON STRUCTURE OF METHODS ********************
    % 
    % -- "Protected" methods include all construction of the ui, 
    % -- "Public" methods contain all callbacks /update methods,
    % -- "Private" methods contain all listeners and local interactions
    % -- "Hidden" methods are mostly qe helper functions and other small 
    %     methods require that property
    
    % Copyright 2016-2023 The Mathworks, Inc
    
    %% Properties
    properties (WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
    end

    properties (Dependent,SetAccess=private)
        Data
        SelectedModel
    end

    properties (Access = protected)
        VariableEditorDialog
    end

    %% Constructor/destructor
    methods
        function this = ModelPanel(App)            
            % instantiate table browser
            panelTitle = getString(message('Control:mrtool:ImportDialogModels'));
            this = this@matlab.ui.internal.databrowser.TableDataBrowser(...
                'mr-model-panel', panelTitle);
            this.App = App;
            
            buildUI(this);
            connectUI(this);
            updateUI(this);
        end

        function delete(this)
            delete(this.VariableEditorDialog);
            delete@matlab.ui.internal.databrowser.TableDataBrowser(this);
        end
    end

    %% Get/Set
    methods
        % Data
        function Data = get.Data(this)
            Data = this.App.Models;
        end
    
        % SelectedModel
        function SelectedModel = get.SelectedModel(this)
            SelectedModel = this.Data(this.Table.Selection);
        end
    end

    %% Public Methods
    methods    
        function updateUI(this)
            % get name from local workspace
            if ~isempty(this.Data)
                tableData = strings(length(this.Data),3);
                for ii = 1:length(this.Data)
                    tableData(ii,1) = this.Data(ii).Name;
                    tableData(ii,2) = mrtool.util.getSystemType(this.Data(ii).System);
                    tableData(ii,3) = sprintf('%d states',order(this.Data(ii).System));
                end
                this.Table.Data = cellstr(tableData);
            else
                this.Table.Data = {};
            end
        end

        function selectModel(this,idx)
            arguments
                this (1,1) mrtool.internal.databrowser.ModelPanel
                idx (1,1) double {mustBePositive,mustBeInteger}
            end
            mustBeLessThanOrEqual(idx,length(this.Data));
            this.Table.Selection = idx;
            notify(this,'SelectionChanged');
        end
    end
    
    %% Protected Methods
    methods (Access = protected)        
        % Define/Configure properties for the Table Browser
        function buildUI(this)
            % for more details on how each property is set, please refer to
            % matlab.ui.internal.data.TableDataBrowser
            
            % activate multiselect
            this.SingleRowSelection = false;

            % accepting any invalid string names from the user
            this.GenerateValidVarName = false;
            
            % adding context menu
            this.Table.ContextMenu = createContextMenu(this);
            
            % configure such that we allow only one callback for execution
            this.Table.Interruptible = false;

            this.Table.ColumnName = {getString(message('Control:mrtool:Name'))...
                getString(message('Control:mrtool:Type')) getString(message('Control:mrtool:Order'))};
            this.Table.ColumnEditable = [true false false];
        end
        
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            this.Table.ContextMenu.ContextMenuOpeningFcn = @(es,ed) updateContextMenu(weakThis.Handle, ed);
            registerDataListeners(this,addlistener(this.App,'ModelsUpdated', @(es,ed) updateUI(weakThis.Handle)));
        end

        function DoubleClickCallback(this, ~)
            cbOpenSelection(this);
        end

        function RenameCallback(this, row, ~, newName)
            model = this.Data(row);
            if ~isempty(this.VariableEditorDialog) && strcmp(this.VariableEditorDialog.VariableName,model.Name)
                this.VariableEditorDialog.VariableName = newName;
            end
            model.Name = newName;
        end
    end
    
    %% Private Methods
    methods (Access = private)
        function contextMenu = createContextMenu(this)
            weakThis = matlab.lang.WeakReference(this);
            % Create a nested context menu.         
            contextMenu = uicontextmenu('Parent', this.Figure);
            
            % Add Reduce Model menu
            reduceModelMenuItem = uimenu(contextMenu, ...
                'Text',getString(message('Control:mrtool:MRTechnique')), ...
                'Tag','ReduceModel', 'Separator', true);

            btModelSubMenuItem = uimenu(reduceModelMenuItem, ...
                'Text',getString(message('Control:mrtool:MRBalancedTruncation')), ...
                'Tag','BalancedTruncation');
            btModelSubMenuItem.MenuSelectedFcn = @(es,ed) cbOpenMRTool(weakThis.Handle,es);

            podModelSubMenuItem = uimenu(reduceModelMenuItem, ...
                'Text',getString(message('Control:mrtool:MRProperOrthogonalDecomposition')), ...
                'Tag','ProperOrthogonalDecomposition');
            podModelSubMenuItem.MenuSelectedFcn = @(es,ed) cbOpenMRTool(weakThis.Handle,es);

            mtModelSubMenuItem = uimenu(reduceModelMenuItem, ...
                'Text',getString(message('Control:mrtool:MRModalTruncation')), ...
                'Tag','ModalTruncation');
            mtModelSubMenuItem.MenuSelectedFcn = @(es,ed) cbOpenMRTool(weakThis.Handle,es);

            pzModelSubMenuItem = uimenu(reduceModelMenuItem, ...
                'Text',getString(message('Control:mrtool:MRPoleZeroSimplification')), ...
                'Tag','PoleZeroSimplification');
            pzModelSubMenuItem.MenuSelectedFcn = @(es,ed) cbOpenMRTool(weakThis.Handle,es);

            % Add Plot menu
            plotMenuItem = uimenu(contextMenu, ...
                'Text',getString(message('Control:mrtool:MRPlot')), ...
                'Tag','Plot');
            plottypes = mrtool.PlotEnum.getPlotTypes();
            % Add new plot types
            for ct = 1:numel(plottypes)
                msgkey = sprintf('Control:mrtool:PlotGalleryNew%s',char(plottypes(ct)));
                Label = getString(message(msgkey));
                plotSubMenuItem = uimenu(plotMenuItem, ...
                    'Text',Label, ...
                    'Tag',plottypes(ct).Tag);
                plotSubMenuItem.MenuSelectedFcn = @(es,ed) cbCreatePlot(weakThis.Handle,plottypes(ct).Tag); 
            end

            % Add Open menu
            openSelectionMenuItem = uimenu(contextMenu, ...
                'Text',getString(message('Control:mrtool:OpenSelection')), ...
                'Tag','OpenSelectionItem');
            openSelectionMenuItem.MenuSelectedFcn = @(es,ed) cbOpenSelection(weakThis.Handle);
            
            % Add Export menu
            exportMenuItem = uimenu(contextMenu, ...
                'Text',getString(message('Control:mrtool:Export')), ...
                'Tag','ExportItem');
            exportMenuItem.MenuSelectedFcn = @(es,ed) cbExport(weakThis.Handle);
            
            % Add Delete menu
            deleteMenuItem = uimenu(contextMenu, ...
                'Text',getString(message('Control:mrtool:Delete')), ...
                'Tag','DeleteItem');
            deleteMenuItem.MenuSelectedFcn = @(es,ed) cbDelete(weakThis.Handle);
            
            this.Table.ContextMenu = contextMenu;
            this.Table.ContextMenu.Tag = strcat('mr-tool-context-menu-model-', ...
                this.App.ID);
        end 

        function updateContextMenu(this, ed)
            % Get the selected the row.
            interactionInformation = ed.InteractionInformation;
            if ed.ContextObject == this.Table ...
                    && ~(interactionInformation.RowHeader || interactionInformation.ColumnHeader)
                row = interactionInformation.DisplayRow;
                col = interactionInformation.DisplayColumn;
                % React when a cell or the white space is clicked.
                if isempty([row col])
                    % Remove current row selections.
                    this.Table.Selection = [];
                    children = this.Table.ContextMenu.Children;
                    for i = 1:numel(children)
                        children(i).Visible = false;
                    end
                    notify(this,'SelectionChanged');
                else
                    % Select the right-clicked row.
                    if ~ismember(row,this.Table.Selection)
                        this.Table.Selection = row;
                    end
                    % Enable submenus.
                    children = this.Table.ContextMenu.Children;
                    for i = 1:numel(children)
                        children(i).Visible = true;
                    end
                    % Disable open for nonscalar
                    OpenMenu = findall(this.Table.ContextMenu,Tag='OpenSelectionItem');
                    OpenMenu.Visible = isscalar(this.SelectedModel);
                    % Disable PZ for sparse
                    ReduceMenu = findall(this.Table.ContextMenu,Tag='ReduceModel');
                    PZMenu = findall(ReduceMenu,Tag='PoleZeroSimplification');
                    PlotMenu = findall(this.Table.ContextMenu,Tag='Plot');
                    PZMapMenu = findall(PlotMenu,Tag='pzmap');
                    IOPZMapMenu = findall(PlotMenu,Tag='iopzmap');
                    if any(arrayfun(@(x) issparse(x.System),this.SelectedModel))
                        PZMenu.Visible = false;
                        PZMapMenu.Visible = false;
                        IOPZMapMenu.Visible = false;
                    else
                        PZMenu.Visible = true;
                        PZMapMenu.Visible = true;
                        IOPZMapMenu.Visible = true;
                    end
                    notify(this,'SelectionChanged');
                end
            else
                this.Table.Selection = [];
                children = this.Table.ContextMenu.Children;
                for i = 1:numel(children)
                    children(i).Visible = false;
                end
                notify(this,'SelectionChanged');
            end
        end

        function cbOpenSelection(this)
            if isempty(this.VariableEditorDialog)
                this.VariableEditorDialog = controllib.widget.internal.variableeditor.VariableEditorDialog(this.SelectedModel.Name, ...
                    this.SelectedModel.System);
                registerDialog(this.App, this.VariableEditorDialog);
            else
                this.VariableEditorDialog.VariableValue = this.SelectedModel.System;
                this.VariableEditorDialog.VariableName = this.SelectedModel.Name;
            end
            show(this.VariableEditorDialog, this.App.Container, 'CENTER');
        end
        
        function cbOpenMRTool(this,es)            
            btText = getString(message('Control:mrtool:MRBalancedTruncation'));
            podText = getString(message('Control:mrtool:MRProperOrthogonalDecomposition'));
            mtText = getString(message('Control:mrtool:MRModalTruncation'));
            pzText = getString(message('Control:mrtool:MRPoleZeroSimplification'));
            switch es.Text
                case btText
                    openTools(this.App, 'BalancedTruncation', this.SelectedModel);
                case podText
                    openTools(this.App, 'ProperOrthogonalDecomposition', this.SelectedModel);
                case mtText
                    openTools(this.App, 'ModalTruncation', this.SelectedModel);
                case pzText
                    openTools(this.App, 'PoleZeroSimplification', this.SelectedModel);
            end
        end
        
        function cbCreatePlot(this,type)
            createPlot(this.App.PlotManager,type);
            RPlot = this.App.PlotManager.ResponsePlotList(end);
            addModels(this.App.PlotManager,RPlot,this.SelectedModel);
            this.App.Container.SelectedToolstripTab = struct('tag',...
                'PlotTab','title',getString(message('Control:mrtool:PlotTab')));
        end

        function cbExport(this)
            showExportDialog(this.App)
        end

        function cbDelete(this)             
            selectedModelIndex = this.Table.Selection;
            model = this.Data(selectedModelIndex);
            if ~isempty(this.VariableEditorDialog) && strcmp(this.VariableEditorDialog.VariableName,model.Name)
                close(this.VariableEditorDialog);
            end
            removeModel(this.App,model);
            % fire event
            rows = this.Table.Selection;
            sData = struct('Rows',rows);
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            notify(this,'SelectionChanged',CustomEventData)
        end
    end
    methods (Hidden)
        function dlg = qeGetDialog(this)
            dlg = this.VariableEditorDialog;
        end
    end
end