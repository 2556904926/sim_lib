classdef HomeTabNew < handle
    % Main Tab for Control System Designer App.
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Access = private)
        Tool
        Tab
        Widgets
        DesignerData
        ResponseSelectionDialog
        Config1Dlg
        SampleTimeConversionDialog
        MultiModelDialog
        ExportDialog
        PreferencesDialog
        DataListeners
        UIListeners
    end
    
    methods
        function this = HomeTabNew(Tool)
            % Home Tab constructor
            this.Tab =  matlab.ui.internal.toolstrip.Tab(getString(message('Control:designerapp:strHomeTab')));
            this.Tab.Tag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag('HomeTab');
            this.Tool = Tool;
            this.DesignerData = getData(Tool);
            createWidgets(this)
            installListeners(this)
            update(this)
        end
        
        function installListeners(this)
            this.DataListeners = [this.DataListeners; addlistener(this.DesignerData,'Designs','PostSet', @(es,ed) updateDesignWidgets(this))];
            this.DataListeners = [this.DataListeners; addlistener(this.DesignerData,'TunableBlocksListChanged',@(es,ed)updateDesignWidgets(this))];
            %             if ~isSimulink(this.DesignerData.getArchitecture)
            this.DataListeners = [this.DataListeners; addlistener(this.DesignerData,'PlantValueChanged',@(es,ed)updateArchitectureSection(this))];
            %             end
        end
        
        
        function update(this)
            updateDesignWidgets(this)
            updateArchitectureSection(this);
        end
        
        function delete(this)
            if ~isempty(this.ResponseSelectionDialog) && isvalid(this.ResponseSelectionDialog)
                delete(this.ResponseSelectionDialog);
            end
                        
            if ~isempty(this.Config1Dlg) && isvalid(this.Config1Dlg)
                delete(this.Config1Dlg);    
            end
            
            if ~isempty(this.MultiModelDialog) && isvalid(this.MultiModelDialog)
                delete(this.MultiModelDialog);
            end
            
            if ~isempty(this.ExportDialog) && isvalid(this.ExportDialog)
                delete(this.ExportDialog);
            end
            
            if ~isempty(this.SampleTimeConversionDialog)
                delete(this.SampleTimeConversionDialog);
            end
            
            if ~isempty(this.PreferencesDialog)
                delete(this.PreferencesDialog);
            end
            
            delete(this.DataListeners);
            delete(this.UIListeners);
        end
        
        function Tab = getTab(this)
            Tab = this.Tab;
        end
        
        function Widgets = getWidgets(this)
            Widgets = this.Widgets;
            Widgets.Dialogs = struct('ResponseSelectionDialog', this.ResponseSelectionDialog, ...
                'Config1Dlg', this.Config1Dlg,...
                'MultiModelDialog', this.MultiModelDialog,...
                'ExportDialog', this.ExportDialog,...
                'SampleTimeConversionDialog', this.SampleTimeConversionDialog,...
                'PreferencesDialog',this.PreferencesDialog);
            
        end
        
        function updateSimulinkBlock(this)
            try
                updateSimulinkBlock(this.DesignerData);
            catch ME
                uialert(getAppContainer(this.Tool),ME.message,...
                    getString(message('Control:designerapp:strToolTitleShort')));    
            end
        end
        
        function openArchitectureDialog(this,~)
            Arch = this.DesignerData.getArchitecture;
            if isSimulink(this.DesignerData)
                if isempty(this.Config1Dlg) || ~isa(this.Config1Dlg,'ctrlguis.csdesignerapp.dialogs.internal.SimulinkConfigurationDlg')
                    this.Config1Dlg = ctrlguis.csdesignerapp.dialogs.internal.SimulinkConfigurationDlg(Arch);
                    registerDialog(this.Tool,this.Config1Dlg);
                end
            else
                if isempty(this.Config1Dlg) || ~isa(this.Config1Dlg,'ctrlguis.csdesignerapp.dialogs.MatlabConfiguration.internal.Configuration1Dlg')
                    this.Config1Dlg = ctrlguis.csdesignerapp.dialogs.MatlabConfiguration.internal.Configuration1Dlg(this.DesignerData.getArchitecture);
                    registerDialog(this.Tool,this.Config1Dlg);
                    this.Config1Dlg.NewArchitecture = true;
                    this.DataListeners = [this.DataListeners; addlistener(this.Config1Dlg, 'NewArchitectureCreated', @(es,ed)setArchitecture(this,ed.Data))];
                end
            end
            setEventManager(this.Config1Dlg,getEventManager(this.Tool));
            show(this.Config1Dlg,getAppContainer(this.Tool),'CENTER');
        end
        
        function openSampleTimeConversionDialog(this,~)
            if isempty(this.SampleTimeConversionDialog) || ~isvalid(this.SampleTimeConversionDialog)
                this.SampleTimeConversionDialog = ctrlguis.csdesignerapp.dialogs.internal.SampleTimeConversionDlg(this.Tool);
            end
            show(this.SampleTimeConversionDialog);
            pack(this.SampleTimeConversionDialog);
            updateUI(this.SampleTimeConversionDialog);
        end

        function loadSession(this)
            % Call update to set the state of Retrie/Compare buttons and
            % Multimodel Configuration button
            update(this);
        end
        
        function addUndoRedoKeyboardShortcuts(this)
            % REVISIT: THIS IS JUST AN INTERMEDIATE WORKAROUND TO ADD KEYBOARD
            % SHORTCUTS FOR UNDO/REDO
            
            % Ideally, the toolgroup should provide a utility method to do
            % this action. The method signature will be
            % toolgroup.addShortcut(ShortCutAction,JavaComponentName); The
            % addShortcut()utility method should search the toolgroup for the
            % component with the name <JavaComponentName>. It should then
            % register the <ShortCutAction> to the java component that is
            % found.
            
            % Example: EM = getEventManager(this.Tool)
            %          Widgets = getWidgets(EM);
            %          UndoAction = Widgets.UndoButton;
            %          TG = getAppContainer(this.Tool);
            %          TG.addShortcut(UndoAction,'PreferencesButton');
            drawnow;
            tg = this.Tool.getAppContainer;
            btn = tg.MCOSToolstrip.find('PreferencesButton');
            JComponent = tg.getToolstripSwingComponent(btn);
            addUndoRedoKeyboardShortcuts(getEventManager(this.Tool),JComponent);
        end
    end
    
    methods (Access = private)
        function createWidgets(this)
            % Create File Section Widgets
            createFileSectionWidgets(this)
            createConfigSectionWidgets(this)
            createTuningSectionWidgets(this)
            createAnalysisSectionWidgets(this)
            createDesignSectionWidgets(this)
            if isSimulink(this.DesignerData)
                createUpdateBlocksSectionWidgets(this)
            else
                createExportBlocksSectionWidgets(this)
            end
            createPreferencesSectionWidgets(this);
        end
        
        function createFileSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*
            %% File Section for Home Tab
            
            % Create File Section
            FileSection = Section(getString(message('Control:designerapp:FileSection')));
            FileSection.Tag = 'FileSection';
            add(this.Tab,FileSection);
            
            % File Section Layout
            
            % Open Session
            OpenIcon = Icon('openFolder');
            OpenButton = Button(getString(message('Control:designerapp:FileOpen')),OpenIcon);
            OpenButton.Description = getString(message('Control:designerapp:FileOpenTooltip'));
            column = Column();
            add(FileSection,column);
            add(column,OpenButton);
            
            % Save Session
            SaveIcon = Icon('saved');
            SaveButton = Button(getString(message('Control:designerapp:FileSave')),SaveIcon);
            SaveButton.Description = getString(message('Control:designerapp:FileSaveTooltip'));
            column = Column();
            add(FileSection,column);
            add(column,SaveButton);
            
            
            % Install button callbacks
            this.UIListeners = [this.UIListeners; addlistener(OpenButton,'ButtonPushed', @(hSrc,hData) localOpenSession(this))];
            this.UIListeners = [this.UIListeners; addlistener(SaveButton,'ButtonPushed', @(hSrc,hData) saveSessionPrompt(this.Tool,false))];
            
            % Store widget components
            this.Widgets.FileSection =  struct(...
                'OpenButton',OpenButton, ...
                'SaveButton',SaveButton);
        end
        
        function createConfigSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            %% Create Architecture Section
            ConfigSection =  Section(getString(message('Control:designerapp:ArchitectureSection')));
            ConfigSection.Tag = 'ConfigSection';
            add(this.Tab,ConfigSection);
            % Icons
            editArchitectureIcon = Icon('controlSystemArchitecture');
            multimodelIcon = Icon('multiModelConfig');
            c2dIcon = Icon('sampleTimeConversion');
            
            [tok, ~] = strtok(getString(message('Control:compDesignTask:strMultiModelButtonLabel')),'...');
            [tok2, remain] = strtok(tok,' ');
            % NominalIndex
            NominalIndexButton = Button(sprintf('%s\n%s',tok2,remain(2:end)),multimodelIcon);
            NominalIndexButton.Description = getString(message('Control:designerapp:MultimodelConfigurationTooltip'));
            this.UIListeners = [this.UIListeners; addlistener(NominalIndexButton,'ButtonPushed', @(hSrc,hData) localEditMultiModel(this,NominalIndexButton))];
            % Edit Architecture Split Button
            if ~isSimulink(this.DesignerData.Architecture)
                ArchButton = SplitButton(getString(message('Control:designerapp:EditArchitecture')),editArchitectureIcon);
                % Populate Split Button
                popup = PopupList();
                popup.Tag = 'EditArchitecture';
                item1 = ListItem(getString(message('Control:designerapp:EditArchitectureTitle')));
                item1.Tag = 'EditConfig';
                item1.Description = getString(message('Control:designerapp:EditArchitectureTooltip'));
                item1.Icon = editArchitectureIcon;
                item1.ItemPushedFcn = @(hSrc,hData) openArchitectureDialog(this,ArchButton);
                item2 = ListItem(getString(message('Control:designerapp:SampleTimeConversionTitle')));
                item2.Tag = 'SampleTimeConversion';
                item2.Description = getString(message('Control:designerapp:SampleTimeConversionDescription'));
                item2.Icon = c2dIcon;
                item2.ItemPushedFcn = @(hSrc,hData) openSampleTimeConversionDialog(this,ArchButton);
                popup.add(item1);
                popup.add(item2);
                ArchButton.Popup = popup;
            else
                ArchButton = Button(getString(message('Control:designerapp:EditArchitecture')),editArchitectureIcon);
            end
            % Listeners
            ArchButton.Description = getString(message('Control:designerapp:EditArchitectureTooltip'));
            this.UIListeners = [this.UIListeners; addlistener(ArchButton,'ButtonPushed', @(hSrc,hData) openArchitectureDialog(this,ArchButton))];
            % Add to toolstrip
            column = Column();
            add(ConfigSection,column);
            add(column,ArchButton);
            
            column = Column();
            add(ConfigSection,column);
            add(column,NominalIndexButton);
            
            this.Widgets.MatlabConfigSection.NominalIndexButton = NominalIndexButton;
            this.Widgets.MatlabConfigSection.ArchButton = ArchButton;
        end
        
        function createTuningSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            %% Tuning Methods Section for Home Tab
            
            % Create Tuning Methods Section
            TuningMethodSection = Section(getString(message('Control:designerapp:TuningSection')));
            TuningMethodSection.Tag = 'TuningMethodSection';
            add(this.Tab,TuningMethodSection);
            
            % Select Tuning Method Button
            TuningMethodButtonIcon = Icon('tuningMethods');
            TuningMethodTypePicker = ctrlguis.csdesignerapp.pickers.internal.TuningMethodTypePickerNew(getToolsManager(this.Tool),...
                getString(message('Control:designerapp:TuningMethods')), ...
                TuningMethodButtonIcon);
            
            TuningMethodButton = getDropDownButton(TuningMethodTypePicker);
            TuningMethodButton.Description = getString(message('Control:designerapp:TuningMethodsTooltip'));
            
            column = Column('HorizontalAlignment','center');
            add(column,TuningMethodButton);
            add(TuningMethodSection,column);
            
            
            % Store handle to widgets
            this.Widgets.TuningMethodSection =  struct(...
                'TuningMethodButton',TuningMethodButton);
            
        end
        
        function createAnalysisSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            %% Analyis Section for Home Tab
            
            % Create Analysis Section
            AnalysisSection = Section(...
                getString(message('Control:designerapp:AnalysisSection')));
            AnalysisSection.Tag = 'AnalysisSection';
            add(this.Tab,AnalysisSection);
            
            % New Plot
            PlotButtonIcon = Icon('add_plot');
            PlotButton = DropDownButton(getString(message('Control:designerapp:AnalysisPlot')),PlotButtonIcon);
            PlotButton.Description = getString(message('Control:designerapp:AnalysisPlotTooltip'));
            column = Column();
            add(AnalysisSection,column);
            add(column,PlotButton);
            
            % Install button callback
            PlotButton.DynamicPopupFcn = @(es,ed)populatePlotPopup(this);
            
            % Store handle to widgets
            this.Widgets.AnalysisSection =  struct(...
                'PlotButton',PlotButton);
        end
        
        function createDesignSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            %% Design Section for Home Tab
            
            % Create Design Section
            DesignSection = Section(...
                getString(message('Control:designerapp:DesignSection')));
            DesignSection.Tag = 'DesignSection';
            add(this.Tab,DesignSection);
            
            % Store Design
            StoreDesignButtonIcon = Icon('download_controlSystem');
            StoreDesignButton = Button(getString(message('Control:designerapp:DesignStore')),StoreDesignButtonIcon);
            StoreDesignButton.Description = getString(message('Control:designerapp:DesignStoreTooltip'));
            column = Column();
            add(DesignSection,column);
            add(column,StoreDesignButton);
            
            % Retrieve Design
            RetrieveDesignButtonIcon = Icon('upload_controlSystem');
            RetrieveDesignButton = DropDownButton(getString(message('Control:designerapp:DesignRetrieve')),RetrieveDesignButtonIcon);
            RetrieveDesignButton.Description = getString(message('Control:designerapp:DesignRetrieveTooltip'));
            RetrieveDesignButton.DynamicPopupFcn = @(es,ed) localCreateRestoreDesignMenu(this);
            column = Column();
            add(DesignSection,column);
            add(column,RetrieveDesignButton);
            
            % Compare Design
            CompareDesignButtonIcon = Icon('threeSignals');
            CompareDesignButton = DropDownButton(getString(message('Control:designerapp:DesignCompare')),CompareDesignButtonIcon);
            CompareDesignButton.Description = getString(message('Control:designerapp:DesignCompareTooltip'));
            CompareDesignButton.DynamicPopupFcn = @(es,ed) localCreateCompareDesignMenu(this);
            column = Column();
            add(DesignSection,column);
            add(column,CompareDesignButton);
            
            % Install button callbacks
            this.UIListeners = [this.UIListeners; addlistener(StoreDesignButton,'ButtonPushed', @(hSrc,hData) localStoreDesign(this))];
%             this.UIListeners = [this.UIListeners; addlistener(CompareDesignButton,'ButtonPushed', @(hSrc,hData) localCompareDesign(this))];
            
            % Store handle to widgets
            this.Widgets.DesignSection =  struct(...
                'StoreDesignButton',StoreDesignButton, ...
                'RetrieveDesignButton',RetrieveDesignButton,...
                'CompareDesignButton',CompareDesignButton);
        end
        
        function createUpdateBlocksSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            %% Update Simulink Blocks Section
            UpdateBlocksSection = Section(...
                getString(message('Control:designerapp:UpdateSimulinkBlocksSection')));
            UpdateBlocksSection.Tag = 'UpdateBlocksSection';
            add(this.Tab,UpdateBlocksSection);
            
            % REVISIT ICON
            UpdateBlocksButtonIcon = Icon('arrowActionEast_simulink');
            UpdateBlocksButton = Button(...
                getString(message('Control:designerapp:UpdateSimulinkBlocks')),UpdateBlocksButtonIcon);
            UpdateBlocksButton.Description = getString(message('Control:designerapp:UpdateSimulinkBlocksTooltip'));
            column = Column();
            add(UpdateBlocksSection,column);
            add(column,UpdateBlocksButton);
            
            this.Widgets.UpdateBlocksSection =  struct('Section',UpdateBlocksSection,...
                'UpdateBlocksButton',UpdateBlocksButton);
            
            this.UIListeners = [this.UIListeners; addlistener(UpdateBlocksButton,'ButtonPushed', @(es,ed) updateSimulinkBlock(this))];
        end
        
        function createExportBlocksSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            %% Export blocks section
            ExportSection = Section(...
                getString(message('Control:designerapp:ExportBlocksSection')));
            ExportSection.Tag = 'ExportBlocksSection';
            add(this.Tab,ExportSection);
            
            ExportButtonIcon = Icon('export_data');
            ExportButton = SplitButton(...
                getString(message('Control:designerapp:ExportSection')),ExportButtonIcon);
            ExportButton.Description = getString(message('Control:designerapp:ExportBlocksTooltip'));
            column = Column();
            add(ExportSection,column);
            add(column,ExportButton);
            % Populate split button
            popup = PopupList();
            popup.Tag = 'CreateSplitButtonPopup';
            item1 = ListItem(getString(message('Control:designerapp:ExportBlocksTitle')));
            item1.Tag = 'ExportBlocks';
            item1.Description = getString(message('Control:designerapp:ExportBlocksDescription'));
            item1.Icon = Icon('matlab_block');
            item1.ItemPushedFcn = @(hSrc,hData) exportBlockValues(this);
            item2 = ListItem(getString(message('Control:designerapp:DrawSimulinkModelTitle')));
            item2.Tag = 'DrawDiagram';
            item2.Icon = Icon('simulink');
            item2.ItemPushedFcn = @(hSrc,hData) drawSimulinkModel(this);
            if license('test','SIMULINK')       % Test for Simulink license
                item2.Description = getString(message('Control:designerapp:DrawSimulinkModelDescription'));
            else
                item2.Enabled = false;          % Disabled if no Simulink license
                item2.Description = getString(message('Control:designerapp:SimulinkLicenseRequired'));
            end
            popup.add(item1);
            if matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing)
                popup.add(item2);
            end

            ExportButton.Popup = popup;
            
            this.Widgets.ExportBlocksSection = struct('Section',ExportSection,...
                'ExportBlocksButton',ExportButton);
            
            this.UIListeners = [this.UIListeners; addlistener(ExportButton,'ButtonPushed', @(hSrc,hData) exportBlockValues(this))];
        end
        
        function createPreferencesSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            %% Preferences section
            PreferencesSection = Section(...
                getString(message('Control:designerapp:PreferencesSection')));
            PreferencesSection.Tag = 'PreferencesSection';
            add(this.Tab,PreferencesSection);
            
            PreferencesButtonIcon = Icon('settings');
            PreferencesButton = Button(...
                getString(message('Control:designerapp:FilePreferences')),PreferencesButtonIcon);
            PreferencesButton.Tag = 'PreferencesButton';
            PreferencesButton.Description = getString(message('Control:designerapp:FilePreferencesTooltip'));
            column = Column();
            add(PreferencesSection,column);
            add(column,PreferencesButton);
            
            this.Widgets.PreferencesSection = struct('Section',PreferencesSection,...
                'PreferencesButton',PreferencesButton);
            
            this.UIListeners = [this.UIListeners; addlistener(PreferencesButton,'ButtonPushed', @(hSrc,hData) editPreferences(this))];
        end
        
        function updateDesignWidgets(this)
            TB = ~isempty(getTunableBlocks(this.DesignerData));
            this.Widgets.DesignSection.StoreDesignButton.Enabled = TB;
            B = ~isempty(getDesigns(this.DesignerData));
            this.Widgets.DesignSection.CompareDesignButton.Enabled = B;
            this.Widgets.DesignSection.RetrieveDesignButton.Enabled = B;
        end
        
        function updateArchitectureSection(this)
            try
                % We try to get the closed loop to see if the multi model
                % button needs to be enabled. If slTuner fails to compute
                % the closed loop for some reason (such as bad rate
                % conversion options) we assume the system is scalar.
                CL = this.DesignerData.getArchitecture.getCL;
                s = size(CL);
            catch
                s = 1;
            end
            if prod(s(3:end)) > 1
                this.Widgets.MatlabConfigSection.NominalIndexButton.Enabled = true;
            else
                this.Widgets.MatlabConfigSection.NominalIndexButton.Enabled = false;
            end
        end
        
        function popup = localCreateRestoreDesignMenu(this)
            popup = matlab.ui.internal.toolstrip.PopupList();
            popup.Tag = 'mnuHomeRetrieveDesign';
            
            % Add retrieve design header
            header = matlab.ui.internal.toolstrip.PopupListHeader(getString(message('Control:designerapp:SelectDesignToMakeCurrent')));
            header.Tag = 'RetrieveDesign';
            popup.add(header);
            
            CurrentDesigns = getDesigns(this.DesignerData);
            for ct = 1:length(CurrentDesigns)
                Label = CurrentDesigns(ct).getName;
                Item = matlab.ui.internal.toolstrip.ListItem(Label);
                Item.Tag = CurrentDesigns(ct).getName;
                Item.ShowDescription = false;
                addlistener(Item,'ItemPushed', @(hSrc,hData) localRetrieveDesign(this,ct));
                popup.add(Item);
            end
        end
        
        function popup = localCreateCompareDesignMenu(this)
            popup = matlab.ui.internal.toolstrip.PopupList();
            popup.Tag = 'mnuHomeCompareDesign';
            
            % Add retrieve design header
            header = matlab.ui.internal.toolstrip.PopupListHeader(getString(message('Control:designerapp:strCompareDesigns')));
            header.Tag = 'CompareDesign';
            popup.add(header);
            
            % Current design item
            Label = getString(message('Control:designerapp:CurrentDesign'));
            Item = matlab.ui.internal.toolstrip.ListItemWithCheckBox(Label);
            Item.Value = true;
            Item.Enabled = false;
            Item.ShowDescription = false;
            popup.add(Item);
            
            % Add other available designs
            Designs = getDesigns(this.DesignerData);
            NumberOfDesigns = numel(Designs);
            PlotsManager = getPlotsManager(this.Tool);
            for ct = 1:NumberOfDesigns
                Label = Designs(ct).getName;
                Item = matlab.ui.internal.toolstrip.ListItemWithCheckBox(Label);
                Item.Tag = Designs(ct).getName;
                Item.Value = ~isempty(find(Designs(ct)== PlotsManager.Designs,1));
                Item.ShowDescription = false;
                addlistener(Item,'ValueChanged', @(hSrc,hData) addremoveDesign(this,hSrc,hData,Designs(ct)));
                popup.add(Item);
            end
        end
        
        function addremoveDesign(this,es,~,Design)
            % Add/remove design from comparison list
            PlotsManager = getPlotsManager(this.Tool);
            Architecture = this.Tool.getData.Architecture;
            DesignData = getValueStructure(Design);
            BlockIDs = fields(DesignData);
            DesignSampleTime = DesignData.(BlockIDs{1}).Ts;

            if es.Value
                if isequal(Architecture.getTs,DesignSampleTime)
                    showDesign(PlotsManager,Design);
                else
                    % apply design only when all tuned blocks have same sample
                    % time with the architecture sample time
                    es.Value = false;
                    if DesignSampleTime == 0
                        DesignSampleTime = getString(message('Control:designerapp:LinearizationOptionsContinuous'));
                    else
                        DesignSampleTime = mat2str(DesignSampleTime);
                    end
                    if isSimulink(Architecture)
                        errorString = getString(message('Control:designerapp:SimulinkCompareDesignSampleTimeMismatch',DesignSampleTime));
                    else
                        errorString = getString(message('Control:designerapp:MATLABCompareDesignSampleTimeMismatch',DesignSampleTime));
                    end
                    uialert(getAppContainer(this.Tool),errorString,...
                        getString(message('Control:designerapp:strToolTitleShort')));
                    return;
                end
            else
                removeDesign(PlotsManager,Design)
            end
        end
        
        function localStoreDesign(this)
            % Store Design
            storeDesign(this.DesignerData);
        end
        
        function localRetrieveDesign(this,idx)
            try
                this.DesignerData.retrieveDesign(idx);
            catch ME
                uialert(getAppContainer(this.Tool),ME.message,...
                    getString(message('Control:designerapp:strToolTitleShort')));
            end
            
        end
                
        function popup = populatePlotPopup(this)
            % create popup list
            popup = matlab.ui.internal.toolstrip.PopupList();
            popup.Tag = 'mnuHomePlotPicker';
            
            % Get existing plots of appropriate types
            plottypes = ctrlguis.csdesignerapp.plot.internal.PlotEnum.getPlotTypes(false);
            
            % Add new plots header
            header = matlab.ui.internal.toolstrip.PopupListHeader(ctrlMsgUtils.message('Control:designerapp:PlotNewPlots'));
            header.Tag = 'NewPlots';
            popup.add(header);
            
            % Add new plot types
            for ct = 1:numel(plottypes)
                thisplot = plottypes(ct);
                msgkey = sprintf('Control:designerapp:PlotNew%s',char(thisplot));
                Label = ctrlMsgUtils.message(msgkey);
                Icon = ctrlguis.csdesignerapp.plot.internal.PlotEnum.getIcon(thisplot.Tag,false);
                Item = matlab.ui.internal.toolstrip.ListItem(Label,Icon);
                Item.ShowDescription = false;
                % passing "PlotButton" for anchoring the dialog
                addlistener(Item, 'ItemPushed',  @(es,ed) plotSystem(this,ct,plottypes));
                popup.add(Item);
            end
        end
        
        function plotSystem(this,Idx,plottypes)
            import ctrlguis.csdesignerapp.dialogs.internal.SelectResponseToPlot;
            this.ResponseSelectionDialog = SelectResponseToPlot(getData(this.Tool), ...
                getPlotsManager(this.Tool), plottypes(Idx));
            registerDialog(this.Tool,this.ResponseSelectionDialog);
            addlistener(this.ResponseSelectionDialog,'CloseEvent',...
                @(es,ed) deleteDialog(this.Tool,es.Name));
            % pop up the dialog
            show(this.ResponseSelectionDialog,getAppContainer(this.Tool),'CENTER');
            pack(this.ResponseSelectionDialog);
        end
        
        function localChangeArch(this,hData,hBtn,items)
            openArchitectureDialog(this,hBtn, hData,items);
        end
        
        function localEditMultiModel(this,NominalIndexButton)
            if isempty(this.MultiModelDialog) || ~isvalid(this.MultiModelDialog)
                this.MultiModelDialog = ctrlguis.csdesignerapp.dialogs.internal.MultiModelDialog(this.DesignerData.getArchitecture,this.Tool.getPreferences);
                setEventManager(this.MultiModelDialog, getEventManager(this.Tool));
                show(this.MultiModelDialog,NominalIndexButton);
            else
                show(this.MultiModelDialog);
            end
            
        end
        
        function localOpenSession(this)
            try
                % REVISIT: Check for previous to previous versions of sisotool
                isLoading = false;
                AppContainer = getAppContainer(this.Tool);
                [filename, pathname] = uigetfile( ...
                    {'*.mat';'*.*'}, ...
                    getString(message('Control:designerapp:OpenCSTSession')));
                if ~isequal(filename,0) && ~isequal(pathname,0)
                    w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
                    S = load(fullfile(pathname, filename));
                    warning(w);
                    if ~isempty(S)
                        if isfield(S,'Projects')
                            error(message('Control:designerapp:ErrorCETMSession'));
                        end
                        isNewVersion = (isfield(S,getString(message('Control:designerapp:CSDSessionName'))) && isa(S.ControlSystemDesignerSession,'ctrlguis.csdesignerapp.data.internal.SessionData'));
                        isOldSessionData = isfield(S,'SessionData');
                        if (isNewVersion || isOldSessionData)
                            isLoading = true;
                            this.Tool.loadSession(S);
                        else
                            error(getString(message('Control:designerapp:InvalidSessionFile')));
                        end
                    end
                end
            catch ME
                if isa(ME,'MSLException') && isLoading
                    if isNewVersion
                        ModelName = S.ControlSystemDesignerSession.DesignerData.Architecture.Name;
                    elseif isOldSLVersion
                        ModelName = S.Projects.Model;
                    else
                        ModelName = '';
                    end
                    GroupCenter = slctrlguis.lintool.getToolGroupCenter(AppContainer);
                    slcontrollib.internal.utils.nagctlr(ModelName,...
                        getString(message('Control:general:Tool_controlSystemDesigner_Label')),...
                        getString(message('Control:designerapp:FileOpen')),...
                        ME,...
                        GroupCenter);
                else
                    uialert(AppContainer,ME.message,...
                        getString(message('Control:general:Tool_controlSystemDesigner_Label')))
                end
            end
        end
        
        function exportBlockValues(this)
            if isempty(this.ExportDialog) || ~isvalid(this.ExportDialog)
                this.ExportDialog = ctrlguis.csdesignerapp.dialogs.internal.ExportModelDialog(this.DesignerData);
                show(this.ExportDialog,getAppContainer(this.Tool),'CENTER');
                registerDialog(this.Tool,this.ExportDialog);
            else
                show(this.ExportDialog);
            end
        end
        
        function drawSimulinkModel(this,checkForExportToWorkspace)
            arguments
                this
                checkForExportToWorkspace = true
            end
            % Callback to ExportButton Item2
            % Check if all blocks are proper (does not have more zeros than poles)
            tunedBlocks = getTunedBlocks(this.DesignerData.Architecture);
            for k = 1:length(tunedBlocks)
                if ~isproper(getValue(tunedBlocks(k)))
                    uialert(getAppContainer(this.Tool),...
                        getString(message('Control:simulink:LTIMask5')),...
                        getString(message('Control:designerapp:strDrawingSimulinkDiagrams')));
                    return;
                end
            end
            fixedBlocks = getFixedBlocks(this.DesignerData.Architecture);
            for k = 1:length(fixedBlocks)
                if ~isproper(getValue(fixedBlocks(k)))
                    uialert(getAppContainer(this.Tool),...
                        getString(message('Control:simulink:LTIMask5')),...
                        getString(message('Control:designerapp:strDrawingSimulinkDiagrams')));
                    return;
                end
            end
            
            if checkForExportToWorkspace
                % Check if user ok with exporting variables to workspace
                uiconfirm(getAppContainer(this.Tool),...
                    getString(message('Control:designerapp:DrawDiagramMsg1')),...
                    getString(message('Control:designerapp:strDrawingSimulinkDiagrams')), ...
                    "Options",{getString(message('Control:designerapp:strYes')), ...
                    getString(message('Control:designerapp:strNo'))}, ...
                    "DefaultOption",getString(message('Control:designerapp:strYes')),...
                    "CloseFcn",@(es,ed) cbUIConfirmClosed(this,ed.SelectedOption));
            else
                % Check not needed. Answer = yes
                Answer = getString(message('Control:designerapp:strYes'));
                cbUIConfirm(this,Answer);
            end

            function cbUIConfirmClosed(this,Answer)
                if strcmp(Answer,getString(message('Control:designerapp:strYes')))
                    postActionStatus(this.Tool.getEventManager, 'on', ...
                        getString(message('Control:designerapp:createSimulinkModel')));
                    try
                        this.DesignerData.Architecture.drawDiagram;
                    catch ME
                        uialert(getAppContainer(this.Tool),ME.message,...
                            getString(message('Control:designerapp:strToolTitleShort')));
                    end
                    clearActionStatus(this.Tool.getEventManager);
                end
            end
        end
        
        function setArchitecture(this,Architecture)
            setArchitecture(this.DesignerData,Architecture);
            addDefaultMatlabResponse(this.DesignerData);
            createPlots(this.Tool,true,{'rlocus','bode'});
            recreateCompensatorEditor(this.Tool);
        end
        
        function editPreferences(this)
            Preferences = getPreferences(this.Tool);
            this.PreferencesDialog = getDialog(Preferences);
            % Show Java dialog without anchor. Add anchor when dialog is
            % converted to uifigure based. #showDialogCSD_JT
            if this.PreferencesDialog.IsWidgetValid
                show(this.PreferencesDialog);
            else
                show(this.PreferencesDialog,getAppContainer(this.Tool),'CENTER');
            end
        end
    end

    methods (Hidden)
        function qeDrawSimulinkModel(this)
            % Note that calling this method will create variables of the
            % LTI systems in the base workspace.
            drawSimulinkModel(this,false);
        end
    end
end
