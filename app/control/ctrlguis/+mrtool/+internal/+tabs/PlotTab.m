classdef (Hidden) PlotTab < handle
    % Plot Tab of Model Reduction App
    %
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = private)
        Tab     
    end

    properties (Access = private)
        Widgets
    end

    properties (Dependent,Access=private)
        SystemNames
        Systems
    end

    properties (Access = private,WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
    end

    properties (Access=private,Transient)
        PlotCreatedListener
        PlotDeletedListener
        SelectionChangedListener
        SparseDialogClosedListener
    end
    
    %% Constructor/destructor
    methods        
        function this = PlotTab(App)
            arguments
                App (1,1) mrtool.internal.ModelReducerApp
            end
            this.App = App;
            this.Tab = matlab.ui.internal.toolstrip.Tab(getString ...
                (message('Control:mrtool:PlotTab')));
            this.Tab.Tag = 'PlotTab';
            buildUI(this);
            weakThis = matlab.lang.WeakReference(this);
            this.PlotCreatedListener = addlistener(this.App.PlotManager,'PlotCreated',@(es,ed) updateGallery(weakThis.Handle));
            this.PlotDeletedListener = addlistener(this.App.PlotManager,'PlotDeleted',@(es,ed) updateGallery(weakThis.Handle));
            this.SelectionChangedListener = addlistener(this.App.ModelPanel,'SelectionChanged', @(es,ed) updateGallery(weakThis.Handle));
        end        

        function delete(this)
            delete(this.PlotCreatedListener);
            delete(this.PlotDeletedListener);
            delete(this.SelectionChangedListener);
            delete(this.SparseDialogClosedListener);
        end
    end

    %% Get/Set
    methods
        % SystemNames
        function names = get.SystemNames(this)
            names = cell(numel(this.App.SelectedModel),1);
            for ct = 1:numel(this.App.SelectedModel)
                names{ct} = this.App.SelectedModel(ct).Name;
            end
        end

        % Systems
        function systems = get.Systems(this)
            systems = cell(numel(this.App.SelectedModel),1);
            for ct = 1:numel(this.App.SelectedModel)
                systems{ct} = this.App.SelectedModel(ct).System;
            end
        end
    end

    %% Public methods
    methods
        function loadSession(this)
            updateGallery(this);
        end
    end

    methods (Access = private)        
        function buildUI(this)
            import matlab.ui.internal.toolstrip.*
            %% SYSTEM SECTION           
            SystemList = TextArea(getString(message('Control:mrtool:PlotNoSystemSelected')));
            SystemList.Editable = false;
            
            % place them
            SystemSection = Section(getString(message('Control:mrtool:PlotSystemSection')));
            SystemSection.Tag = 'SystemSection';
            column1 = Column('Width',110); 
            add(SystemSection,column1)
            add(column1,SystemList)

            this.Widgets.SystemSection = struct(...
                'SystemSection',SystemSection,...
                'SystemList',SystemList);
            
            %% PLOT SECTION
            popup = GalleryPopup('GalleryItemRowCount',1,'GalleryItemTextLineCount',1,'IconSize',40);
            popup.Tag = 'gallerypopup';
            NewPlotCategory = GalleryCategory(getString(message('Control:mrtool:PlotGalleryNewPlotTitle')));
            NewPlotItems = LocalGetNewPlots(this);
            for ct=1:length(NewPlotItems)
                NewPlotCategory.add(NewPlotItems(ct));
            end                        
            popup.add(NewPlotCategory);
            
            PlotsResultsGallery = matlab.ui.internal.toolstrip.Gallery(popup, 'MaxColumnCount', 9, 'MinColumnCount', 3, 'HideDisabledItems',false); 
            ExistingPlotCategory = GalleryCategory(getString(message('Control:mrtool:PlotGalleryExistingPlotTitle')));
                        
            % place them
            PlotSection = Section(getString(message('Control:mrtool:PlotPlotSection')));
            PlotSection.Tag = 'PlotSection';
            column2 = Column();
            add(PlotSection,column2)
            add(column2,PlotsResultsGallery);
            
            %% Place sections
            add(this.Tab,SystemSection);
            add(this.Tab,PlotSection);

            this.Widgets.PlotSection = struct(...
                'PlotSection',PlotSection,...
                'NewPlotCategory',NewPlotCategory,...
                'Gallery',PlotsResultsGallery,...
                'ExistingPlotCategory',ExistingPlotCategory);

            updateGallery(this);
        end

        function createPlot(this,type)
            createPlot(this.App.PlotManager,type);
            RPlot = this.App.PlotManager.ResponsePlotList(end);
            addSelectedModels(this,RPlot);
        end

        function addSelectedModels(this,RPlot)
            addModels(this.App.PlotManager,RPlot,this.App.SelectedModel);
            updateGallery(this);
        end
        
        function updateGallery(this)
            import matlab.ui.internal.toolstrip.*
            
            syncGalleryItemsAndPlots(this);

            if isempty(this.App.SelectedModel)
                this.Widgets.SystemSection.SystemList.Value = getString(message('Control:mrtool:PlotNoSystemSelected'));
                this.Widgets.PlotSection.Gallery.TextOverlay = getString(message('Control:mrtool:PlotGalleryOverlay'));
                disableAll(this.Widgets.PlotSection.Gallery.Popup)
            else
                % Update label
                % Get names for variable names
                str = sprintf('%s\n',this.SystemNames{:});
                this.Widgets.SystemSection.SystemList.Value = str(1:end-1);

                this.Widgets.PlotSection.Gallery.TextOverlay = '';
                enableAll(this.Widgets.PlotSection.Gallery.Popup)
                ISSPARSE = any(cellfun(@issparse,this.Systems));
                if ISSPARSE
                    tooltip = getString(message('Control:mrtool:PlotSparseUnavailableToolTip'));
                else
                    tooltip = '';
                end
                items = getChildByIndex(this.Widgets.PlotSection.NewPlotCategory);
                for ii = 1:length(items)
                    if strcmp(items(ii).Tag,'pzmap') || strcmp(items(ii).Tag,'iopzmap')
                        items(ii).Enabled = ~ISSPARSE;
                        items(ii).Description = tooltip;
                    end
                end
                items = getChildByIndex(this.Widgets.PlotSection.ExistingPlotCategory);
                for ii = 1:length(items)
                    if strcmp(items(ii).Tag,'pzmap') || strcmp(items(ii).Tag,'iopzmap')
                        items(ii).Enabled = ~ISSPARSE;
                        items(ii).Description = tooltip;
                    end
                end
            end
        end

        function syncGalleryItemsAndPlots(this)
            % Existing plots
            existingPlots = this.App.PlotManager.ResponsePlotList;

            % Add the existing plots category
            if ~isempty(existingPlots)
                existingPlots = existingPlots(isvalid(existingPlots));
                if isscalar(this.Widgets.PlotSection.Gallery.Popup.getChildByIndex)
                    add(this.Widgets.PlotSection.Gallery.Popup,this.Widgets.PlotSection.ExistingPlotCategory,1);
                end

                existingitems = getChildByIndex(this.Widgets.PlotSection.ExistingPlotCategory);
                if isempty(existingitems)
                    existingitemnames = {};
                else
                    existingitemnames = {existingitems.Text};
                end
                % find new plots and item for them
                % find deleted plots and remove their item
                [~,ixnewplots,ixdeletedplots] = setxor({existingPlots.Name},existingitemnames);
                if ~isempty(ixnewplots)
                    setBusy(this.Widgets.PlotSection.Gallery,true);
                    % add item for new exisiting plot
                    for ct=1:length(ixnewplots)
                        RPlot = existingPlots(ixnewplots(ct));
                        newitem = matlab.ui.internal.toolstrip.GalleryItem(RPlot.Name,mrtool.PlotEnum.getIcon(RPlot.PlotHandle.Type));
                        newitem.Tag = RPlot.PlotHandle.Type;
                        weakThis = matlab.lang.WeakReference(this);
                        weakPlot = matlab.lang.WeakReference(RPlot);
                        newitem.ItemPushedFcn = @(es,ed) addSelectedModels(weakThis.Handle,weakPlot.Handle);
                        add(this.Widgets.PlotSection.ExistingPlotCategory,newitem);
                    end
                    setBusy(this.Widgets.PlotSection.Gallery,false);
                end
                if ~isempty(ixdeletedplots)
                    setBusy(this.Widgets.PlotSection.Gallery,true);
                    % remove item for deleted plot
                    for ct=1:length(ixdeletedplots)
                        remove(this.Widgets.PlotSection.ExistingPlotCategory,existingitems(ixdeletedplots(ct)));
                    end
                    setBusy(this.Widgets.PlotSection.Gallery,false);
                end
            else
                % remove existing items since no plots
                existingitems = getChildByIndex(this.Widgets.PlotSection.ExistingPlotCategory);
                if ~isempty(existingitems)
                    setBusy(this.Widgets.PlotSection.Gallery,true);
                    for ct=1:numel(existingitems)
                        remove(this.Widgets.PlotSection.ExistingPlotCategory,existingitems(ct));
                    end
                    setBusy(this.Widgets.PlotSection.Gallery,false);
                end
                if ~isempty(this) && isvalid(this)
                    if ~isempty(this.Widgets.PlotSection.Gallery) && isvalid(this.Widgets.PlotSection.Gallery)
                        % gallery may be already deleted so check validity
                        if numel(getChildByIndex(this.Widgets.PlotSection.Gallery.Popup))==2
                            remove(this.Widgets.PlotSection.Gallery.Popup,this.Widgets.PlotSection.ExistingPlotCategory);
                        end
                    end
                end
            end
        end

        function [items,plottypes] = LocalGetNewPlots(this)
            plottypes = mrtool.PlotEnum.getPlotTypes();
            % Add new plots
            items = matlab.ui.internal.toolstrip.GalleryItem.empty;
            for ct = 1:numel(plottypes)
                title = mrtool.PlotEnum.getNewPlotTitle(plottypes(ct).Tag);
                items(ct) = matlab.ui.internal.toolstrip.GalleryItem(title,mrtool.PlotEnum.getIcon(plottypes(ct).Tag));
                items(ct).Tag = plottypes(ct).Tag;
                weakThis = matlab.lang.WeakReference(this);
                items(ct).ItemPushedFcn = @(es,ed) createPlot(weakThis.Handle,plottypes(ct).Tag);
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts = this.Widgets;
        end
    end
end