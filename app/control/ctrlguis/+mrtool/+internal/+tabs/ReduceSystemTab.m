classdef (Hidden) ReduceSystemTab < handle
    % Reduce System Tab of Model Reduction App
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.    
    
    %% Properties
    properties (SetAccess = private)
        Tab     
    end

    properties (Access=private)
        Widgets        
    end

    properties (Dependent,Access=private)
        Systems
    end

    properties (Access = private,WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
    end

    properties (Access=private,Transient)
        ModelsUpdateListener
        SelectionChangedListener
    end
    
    %% Constructor/destructor
    methods
        function this = ReduceSystemTab(App)
            arguments
                App (1,1) mrtool.internal.ModelReducerApp
            end
            this.App = App;
            this.Tab = matlab.ui.internal.toolstrip.Tab(getString(message('Control:mrtool:ReduceSystemTab')));
            this.Tab.Tag = 'ReduceSystemTab';
            buildUI(this);
            connectUI(this);
            weakThis = matlab.lang.WeakReference(this);
            this.SelectionChangedListener = addlistener(this.App.ModelPanel,'SelectionChanged', ...
                @(es,ed) cbSelectionUpdated(weakThis.Handle));
        end  

        function delete(this)
            delete(this.ModelsUpdateListener);
            delete(this.SelectionChangedListener);
        end       
    end

    %% Get/Set
    methods
        % Systems
        function systems = get.Systems(this)            
            systems = cell(numel(this.App.SelectedModel),1);
            for ct = 1:numel(this.App.SelectedModel)
                systems{ct} = this.App.SelectedModel(ct).System;
            end
        end
    end
    
    %% Private methods
    methods (Access = private)    
        function buildUI(this)
            import matlab.ui.internal.toolstrip.*
            %% FILE SECTION WIDGETS
            % Strings
            FileStr = getString(message('Control:mrtool:FileSection'));
            OpenSessionStr = getString(message('Control:mrtool:OpenSession'));
            OpenSessionTooltip = getString(message('Control:mrtool:OpenSessionTooltip'));
            SaveSessionStr = getString(message('Control:mrtool:SaveSession'));
            SaveSessionTooltip = getString(message('Control:mrtool:SaveSessionTooltip'));
            % Icons
            OpenIcon = matlab.ui.internal.toolstrip.Icon('openFolder');
            SaveIcon = matlab.ui.internal.toolstrip.Icon('saved');
            % Section, Widgets  
            FileSection = Section(FileStr);
            add(this.Tab,FileSection);
            column1 = Column();
            column2 = Column();
                                  
            OpenSessionButton = Button(OpenSessionStr,OpenIcon);
            OpenSessionButton.Description = OpenSessionTooltip; 
            add(FileSection,column1);
            add(column1,OpenSessionButton)
                        
            SaveSessionButton = Button(SaveSessionStr,SaveIcon);
            SaveSessionButton.Description = SaveSessionTooltip; 
            SaveSessionButton.Enabled = false;
            add(FileSection,column2);
            add(column2,SaveSessionButton)

            this.Widgets.FileSection =  struct(...
                'FileSection',FileSection,...
                'OpenButton',OpenSessionButton, ...
                'SaveButton',SaveSessionButton);
            
            %% IMPORT/EXPORT SECTION WIDGETS
            % Strings
            ImportExportSectionStr = getString(message('Control:mrtool:ImportExportSection'));
            ImportStr = getString(message('Control:mrtool:ImportModel'));
            ImportTooltip = getString(message('Control:mrtool:ImportTooltip'));
            ExportStr = getString(message('Control:mrtool:ExportModel'));
            ExportTooltip = getString(message('Control:mrtool:ExportTooltip'));            
            % Icons
            ImportButtonIcon = matlab.ui.internal.toolstrip.Icon('import_data');
            ExportButtonIcon = matlab.ui.internal.toolstrip.Icon('export_data');
            % Section, Widgets
            ImportExportSection = Section(ImportExportSectionStr);
            add(this.Tab,ImportExportSection);
            column3 = Column();
            column4 = Column();                                                     
                        
            ImportButton = Button(ImportStr,ImportButtonIcon);
            ImportButton.Description = ImportTooltip;
            add(ImportExportSection,column3);
            add(column3,ImportButton)            
            
            ExportButton = Button(ExportStr,ExportButtonIcon);
            ExportButton.Description = ExportTooltip;
            ExportButton.Enabled = false;
            add(ImportExportSection,column4);
            add(column4,ExportButton)                

            % Store widgets
            this.Widgets.ImportExportSection =  struct(...
                'ImportExportSection',ImportExportSection,...
                'ImportButton',ImportButton, ...
                'ExportButton',ExportButton);         
            
            %% PLOT WIDGETS
            AnalysisSectionStr = getString(message('Control:mrtool:AnalysisSection'));
            NewPlotStr = getString(message('Control:mrtool:NewPlot'));

            AnalysisSection = Section(AnalysisSectionStr);            
            add(this.Tab,AnalysisSection);
            column5 = Column();
            PlotButtonIcon = matlab.ui.internal.toolstrip.Icon('add_plot');
            PlotButton = DropDownButton(NewPlotStr,PlotButtonIcon); 
            PlotButton.Enabled = false;    
            add(AnalysisSection,column5);
            add(column5,PlotButton);

            % Store widgets
            this.Widgets.AnalysisSection =  struct(...
                'AnalysisSection',AnalysisSection,...
                'PlotButton',PlotButton);

            %% MODEL REDUCTION TECHNIQUES WIDGETS
            % Strings
            TechniquesSectionStr = getString(message('Control:mrtool:TechniquesSection'));
            BalancedTruncationStr =  getString(message('Control:mrtool:BalancedTruncation'));
            BalancedTruncationToolTip =  getString(message('Control:mrtool:BalancedTruncationToolTip'));
            ProperOrthogonalDecompositionStr =  getString(message('Control:mrtool:ProperOrthogonalDecomposition'));
            ProperOrthogonalDecompositionToolTip = getString(message('Control:mrtool:ProperOrthogonalDecompositionToolTip'));
            ModalTruncationStr =  getString(message('Control:mrtool:ModalTruncation'));
            ModalTruncationToolTip = getString(message('Control:mrtool:ModalTruncationToolTip'));
            PoleZeroSimplificationStr =  getString(message('Control:mrtool:PoleZeroSimplification'));
            PoleZeroSimplificationToolTip = getString(message('Control:mrtool:PoleZeroSimplificationToolTip'));
            % Icons
            BalancedTruncationButtonIcon = matlab.ui.internal.toolstrip.Icon('balancedTruncation'); 
            ProperOrthogonalDecompositionButtonIcon = matlab.ui.internal.toolstrip.Icon('podPlot');           
            ModalTruncationButtonIcon = matlab.ui.internal.toolstrip.Icon('modeSelection');
            PoleZeroSimplificationButtonIcon = matlab.ui.internal.toolstrip.Icon('pZSimplification');
            % Section, Widgets                       
            TechniquesSection = Section(TechniquesSectionStr);
            add(this.Tab,TechniquesSection);
            column6 = Column();
            column7 = Column(); 
            column8 = Column(); 
            column9 = Column(); 
                        
            BalancedTruncationButton = Button(BalancedTruncationStr,BalancedTruncationButtonIcon);
            BalancedTruncationButton.Description = BalancedTruncationToolTip;
            BalancedTruncationButton.Enabled = false;    
            add(TechniquesSection,column6);
            add(column6,BalancedTruncationButton);     
                        
            ProperOrthogonalDecompositionButton = Button(ProperOrthogonalDecompositionStr,ProperOrthogonalDecompositionButtonIcon);            
            ProperOrthogonalDecompositionButton.Description = ProperOrthogonalDecompositionToolTip; 
            ProperOrthogonalDecompositionButton.Enabled = false;    
            add(TechniquesSection,column7);
            add(column7,ProperOrthogonalDecompositionButton);   

            ModalTruncationButton = Button(ModalTruncationStr,ModalTruncationButtonIcon);            
            ModalTruncationButton.Description = ModalTruncationToolTip;  
            ModalTruncationButton.Enabled = false;    
            add(TechniquesSection,column8);
            add(column8,ModalTruncationButton);

            PoleZeroSimplificationButton = Button(PoleZeroSimplificationStr,PoleZeroSimplificationButtonIcon);            
            PoleZeroSimplificationButton.Description = PoleZeroSimplificationToolTip; 
            PoleZeroSimplificationButton.Enabled = false;    
            add(TechniquesSection,column9);
            add(column9,PoleZeroSimplificationButton);            

            % Store widgets
            this.Widgets.TechniquesSection =  struct(...
                'TechniquesSection',TechniquesSection,...
                'BalancedTruncationButton',BalancedTruncationButton, ...
                'ProperOrthogonalDecompositionButton',ProperOrthogonalDecompositionButton,...
                'ModalTruncationButton',ModalTruncationButton,...
                'PoleZeroSimplificationButton',PoleZeroSimplificationButton); 

            cbModelsUpdated(this);
            cbSelectionUpdated(this);
        end
       
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            % import and export model buttons
            this.Widgets.ImportExportSection.ImportButton.ButtonPushedFcn =...
                @(es,ed) showImportDialog(this.App);
            this.Widgets.ImportExportSection.ExportButton.ButtonPushedFcn =...
                @(es,ed) showExportDialog(this.App);
            % open and save session button
            this.Widgets.FileSection.SaveButton.ButtonPushedFcn = @(es,ed) promptForSaveSession(this.App);
            this.Widgets.FileSection.OpenButton.ButtonPushedFcn = @(es,ed) promptForLoadSession(this.App);  
            % plot button
            this.Widgets.AnalysisSection.PlotButton.DynamicPopupFcn = ...
                @(es,ed) populatePlotPopup(weakThis.Handle);
            % balanced truncation button
            this.Widgets.TechniquesSection.BalancedTruncationButton.ButtonPushedFcn = ...
                @(es,ed) openTools(this.App,'BalancedTruncation');
            % modal truncation button
            this.Widgets.TechniquesSection.ModalTruncationButton.ButtonPushedFcn = ...
                @(es,ed) openTools(this.App,'ModalTruncation');
            % pole-zero simplification button
            this.Widgets.TechniquesSection.PoleZeroSimplificationButton.ButtonPushedFcn = ...
                @(es,ed) openTools(this.App,'PoleZeroSimplification');
            % proper orthogonal decomposition button
            this.Widgets.TechniquesSection.ProperOrthogonalDecompositionButton.ButtonPushedFcn = ...
                @(es,ed) openTools(this.App,'ProperOrthogonalDecomposition');            

            this.ModelsUpdateListener = addlistener(this.App,'ModelsUpdated',@(es,ed) cbModelsUpdated(weakThis.Handle));
        end
        
        function cbModelsUpdated(this)
            flagSaveExport = ~isempty(this.App.Models) && any(isvalid(this.App.Models));
            this.Widgets.FileSection.SaveButton.Enabled = flagSaveExport;
            this.Widgets.ImportExportSection.ExportButton.Enabled = flagSaveExport;            
        end

        function cbSelectionUpdated(this)
            flagIsSelected = ~isempty(this.App.SelectedModel);
            if ~isempty(this.App.SelectedModel)
                flagSparse = any(cellfun(@issparse,this.Systems));
                flagComplex = any(cellfun(@(x) ~isreal(x),this.Systems));
            else
                flagSparse = false;
                flagComplex = false;
            end

            this.Widgets.AnalysisSection.PlotButton.Enabled = flagIsSelected;

            this.Widgets.TechniquesSection.BalancedTruncationButton.Enabled = flagIsSelected;
            this.Widgets.TechniquesSection.ModalTruncationButton.Enabled = flagIsSelected;
            this.Widgets.TechniquesSection.ProperOrthogonalDecompositionButton.Enabled = flagIsSelected;
            this.Widgets.TechniquesSection.PoleZeroSimplificationButton.Enabled = flagIsSelected && ~flagSparse && ~flagComplex;     

            if flagIsSelected && flagSparse
                this.Widgets.TechniquesSection.PoleZeroSimplificationButton.Description = getString(message('Control:mrtool:PoleZeroSimplificationSparseToolTip'));
            elseif flagIsSelected && flagComplex
                this.Widgets.TechniquesSection.PoleZeroSimplificationButton.Description = getString(message('Control:mrtool:PoleZeroSimplificationComplexToolTip'));
            else
                this.Widgets.TechniquesSection.PoleZeroSimplificationButton.Description = getString(message('Control:mrtool:PoleZeroSimplificationToolTip'));
            end
        end
        
        function popup = populatePlotPopup(this)
            import matlab.ui.internal.toolstrip.*
            % create popup list
            popup = PopupList();
            popup.Tag = 'mnuHomePlotPicker';
            
            % Get existing plots of appropriate types
            plottypes = mrtool.PlotEnum.getPlotTypes();
            
            % Add new plots header
            CreateNewPlot = getString(message('Control:mrtool:CreateNewPlot'));
            header = PopupListHeader(CreateNewPlot);
            header.Tag = 'NewPlots';
            popup.add(header);
            
            % Add new plot types
            for ct = 1:numel(plottypes)
                thisplot = plottypes(ct);
                msgkey = sprintf('Control:mrtool:PlotGalleryNew%s',char(thisplot));
                Label = getString(message(msgkey));
                Icon = mrtool.PlotEnum.getIcon(thisplot.Tag,false);
                Item = ListItem(Label,Icon);
                Item.ShowDescription = false;
                if any(cellfun(@issparse,this.Systems))
                    switch thisplot.Tag
                        case {'pzmap' 'iopzmap'}
                            Item.Enabled = false;
                            Item.Description = getString(message('Control:mrtool:PlotSparseUnavailableToolTip'));
                            Item.ShowDescription = true;
                    end
                elseif any(cellfun(@(x) ~isreal(x),this.Systems))
                    switch thisplot.Tag
                        case {'step','impulse'}
                            Item.Enabled = false;
                            Item.Description = getString(message('Control:mrtool:PlotComplexUnavailableToolTip'));
                            Item.ShowDescription = true;
                    end
                end
                weakThis = matlab.lang.WeakReference(this);
                Item.ItemPushedFcn = @(es,ed) cbCreatePlot(weakThis.Handle,plottypes(ct).Tag);
                popup.add(Item);
            end
        end

        function cbCreatePlot(this,type)
            createPlot(this.App.PlotManager,type);
            RPlot = this.App.PlotManager.ResponsePlotList(end);
            addModels(this.App.PlotManager,RPlot,this.App.SelectedModel);
            this.App.Container.SelectedToolstripTab = struct('tag',...
                'PlotTab','title',getString(message('Control:mrtool:PlotTab')));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts = this.Widgets;
        end
    end
end
