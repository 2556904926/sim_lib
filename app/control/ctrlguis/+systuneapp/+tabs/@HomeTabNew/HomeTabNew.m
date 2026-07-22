classdef (Hidden) HomeTabNew < handle
    % Main Tab for Control System Tuner App.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties(Access = public)
        Tool
        Tab
        Widgets     
        ControlDesignData
        ResponseDialogTC
        ResponseDialogGC
        DesignListListener
        OPPicker
        OPPickerListener1
        OPPickerListener2
        ParamPicker
        ResponseSelectionDialog
        LinearizationOptionsTC
        LinearizationOptionsGC
        MLConfigTC
        MLConfigGC
        ExportDialog
    end
    
    methods
        function this = HomeTabNew(Tool)
            this.Tab = matlab.ui.internal.toolstrip.Tab(...
                getString(message('Control:systunegui:HomeTab')));
            this.Tab.Tag = 'HomeTab';
            this.Tool = Tool;
            this.ControlDesignData = Tool.ControlDesignData;
            createWidgets(this)
            addlistener(this.ControlDesignData,'TunableBlocksListChanged', @(es,ed) updateDesignWidgets(this));
            addlistener(this.ControlDesignData,'Designs','PostSet', @(es,ed) updateDesignWidgets(this));
            updateDesignWidgets(this)
        end
        function delete(this)
            delete(this.DesignListListener);
            delete(this.OPPickerListener1);
            delete(this.OPPickerListener2);
            delete(this.OPPicker);
            if ~isempty(this.LinearizationOptionsGC) && isvalid(this.LinearizationOptionsGC)
                delete(this.LinearizationOptionsGC);
            end
            delete(this.ResponseSelectionDialog);
        end        
        function Tab = getTab(this)
            Tab = this.Tab;
        end        
        function Widgets = getWidgets(this)
           Widgets = this.Widgets; 
        end                
        function updateSimulinkBlock(this)                        
            warningMessage = this.ControlDesignData.updateSimulinkBlock;
            if isempty(warningMessage)
                postActionStatus(this.Tool.EventManager,'off',[getString(message('Control:systunegui:StatusMessageUpdateBlocks')) ' ']);
            else
                uialert(this.Tool.AppContainer,...
                    warningMessage,getString(message('Control:systunegui:toolName')),Icon="warning");
            end
        end    
        %% Save/Load Session for OPPicker and ParamPicker
        function loadSession(this,HomeTabSessionData)
            if HomeTabSessionData.Version == 2
                if this.ControlDesignData.isSimulink
                    if isfield(HomeTabSessionData.HomeTab,'OPselection') ...
                            && ~isempty(HomeTabSessionData.HomeTab.OPselection)
                        loadSelection(this.OPPicker,HomeTabSessionData.HomeTab.OPselection);
                    end
                    if isfield(HomeTabSessionData.HomeTab,'ParamSelection') ...
                            && ~isempty(HomeTabSessionData.HomeTab.ParamSelection)
                        loadSelection(this.ParamPicker,HomeTabSessionData.HomeTab.ParamSelection);
                    end
                end
            end
        end
        function HomeTabSessionData = saveSession(this)
            HomeTabSessionData.OPselection = [];
            HomeTabSessionData.ParamSelection = [];
            if this.ControlDesignData.isSimulink
                HomeTabSessionData.OPselection = saveSelection(this.OPPicker);
                HomeTabSessionData.ParamSelection = saveSelection(this.ParamPicker);
            end	           
        end         
    end
    
    methods (Access = private)
        %% MATLAB Architecture
        function mnu = localCreateArchMenu(this)  
            import matlab.ui.internal.toolstrip.*
            
            Header = PopupListHeader(getString(message('Control:systunegui:SelectArchitecture')));
            Header.Tag = 'HeaderLabel';
            
            Text = getString(message('Control:systunegui:MLStdFeedbackDialogTitle'));
            StdIcon = Icon('standardFeedbackConfig');
            Item1 = ListItem(Text, StdIcon);
            Item1.Tag = 'Config1';
            addlistener(Item1,'ItemPushed', @(hSrc,hData) localChangeArch(this,Item1.Tag));
            
            
            Text = getString(message('Control:systunegui:MLGenFeedbackDialogTitle'));
            GenIcon = Icon('generalizedFeedbackConfig');
            Item2 = ListItem(Text, GenIcon);
            Item2.Tag = 'GenSS';
            addlistener(Item2,'ItemPushed', @(hSrc,hData) localChangeArch(this,Item2.Tag));
            
            
            %Create the menu from the items
            mnu = PopupList();
            mnu.Tag = 'mnuArch';
            mnu.add(Header)
            mnu.add(Item1)
            mnu.add(Item2)
                      
            
        end        
        function localChangeArch(this,ArchName)
            switch ArchName
                case 'Config1'
                    if isa(this.ControlDesignData.getArchitecture, ...
                            'systuneapp.data.MatlabConfigData.Config1')
                        localEditArchitecture(this)
                    else
                        localEditArchitecture(this,systuneapp.data.MatlabConfigData.Config1)
                    end

                case 'GenSS'
                    if isa(this.ControlDesignData.getArchitecture, ...
                            'systuneapp.data.MatlabConfigData.ConfigGenSS')
                        localEditArchitecture(this)
                    else
                        localEditArchitecture(this,systuneapp.data.MatlabConfigData.ConfigGenSS)
                    end
            end
            
        end        
        function localEditArchitecture(this,NewArch)
            arguments
                this
                NewArch = getArchitecture(this.ControlDesignData);
            end
            this.MLConfigTC = getMLConfigTC(NewArch);
            if nargin > 1
                this.MLConfigTC.OKCallback = @(A) this.ControlDesignData.setArchitecture(A);
            end
            this.MLConfigGC = createView(this.MLConfigTC);
            show(this.MLConfigGC,this.Tool.AppContainer);
        end

        %% Design
        function Popup = localCreateRestoreDesignMenu(this) 
            import matlab.ui.internal.toolstrip.*
            
            Popup = PopupList;
            Popup.Tag = 'mnuDesigns';
            % Header
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:SelectDesignToMakeCurrent'));
            Header.Tag = 'RetrieveDesign';
            add(Popup,Header);

            % Loop over existing Designs
            CurrentDesigns = this.ControlDesignData.getDesign;
            for ct = 1:length(CurrentDesigns)
                Item = ListItem(CurrentDesigns(ct).getName);
                Item.Tag = CurrentDesigns(ct).getName;
                Item.ShowDescription = false;
                %Install listener for menu item selection
                addlistener(Item,'ItemPushed', @(hSrc,hData) localRetrieveDesign(this,ct));
                add(Popup,Item);
            end            
        end              
        function localStoreDesign(this)
            this.ControlDesignData.addDesign(this.ControlDesignData.createDesign);
        end        
        function localRetrieveDesign(this,idx)
            this.ControlDesignData.retrieveDesign(idx);
        end        
        function popup = localCreateCompareDesignMenu(this)
            popup = matlab.ui.internal.toolstrip.PopupList();
            popup.Tag = 'mnuHomeCompareDesign';
            
            % Add retrieve design header
            header = matlab.ui.internal.toolstrip.PopupListHeader(getString(message('Control:systunegui:CompareDesigns')));
            header.Tag = 'CompareDesign';
            popup.add(header);
            
            % Current design item
            Label = getString(message('Control:systunegui:CurrentDesign'));
            Item = matlab.ui.internal.toolstrip.ListItemWithCheckBox(Label);
            Item.Value = true;
            Item.Enabled = false;
            Item.ShowDescription = false;
            popup.add(Item);
            
            % Add other available designs
            Designs = getDesign(this.Tool.ControlDesignData);
            NumberOfDesigns = numel(Designs);
            PlotManager = this.Tool.PlotManager;
            for ct = 1:NumberOfDesigns
                Label = Designs(ct).getName;
                Item = matlab.ui.internal.toolstrip.ListItemWithCheckBox(Label);
                Item.Tag = Designs(ct).getName;
                Item.Value = ~isempty(find(Designs(ct)== PlotManager.DesignList,1));
                Item.ShowDescription = false;
                addlistener(Item,'ValueChanged', @(es,ed) addremoveDesign(this,es,Designs(ct)));
                popup.add(Item);
            end
        end   

        function addremoveDesign(this,src,design)
            %% Add/remove design from comparison list.
            if src.Value
                this.Tool.PlotManager.showDesign(design)
            else
                this.Tool.PlotManager.removeDesign(design)
            end
        end

        %% Export
        function exportBlockValues(this)
            if isempty(this.ExportDialog) || ~isvalid(this.ExportDialog)
                this.ExportDialog = systuneapp.internal.dialogs.MLExport(this.ControlDesignData);
            end
            show(this.ExportDialog,this.Tool.AppContainer);
            updateUI(this.ExportDialog);
        end

        %% Linearization
        function openLinearizationOptions(this)
            if isempty(this.LinearizationOptionsTC)
                this.LinearizationOptionsTC = systuneapp.internal.dialogs.LinearizationOptionsTC(this.ControlDesignData);
                this.LinearizationOptionsGC = createView(this.LinearizationOptionsTC);
                show(this.LinearizationOptionsGC,this.Tool.AppContainer);
                pack(this.LinearizationOptionsGC);
            else
                show(this.LinearizationOptionsGC);
            end
        end
        function operatingPointChanged(this)
            OpSelection = this.OPPicker.getSelection;
            op = systuneapp.tabs.HomeTabNew.getOperatingPointFromSelection(OpSelection);

            % set operating point
            postActionStatus(this.Tool.EventManager,'on',getString(message('Control:systunegui:StatusMessageOperatingPoint')));
            this.ControlDesignData.setOperatingPoints(op);
            clearActionStatus(this.Tool.EventManager);
        end                
        function linearizationParametersChanged(this)
            Params = getParameterData(this.ParamPicker);
            [isCompatible,nOp,nParam] = this.ControlDesignData.isParamCompatible(Params); 
            if isCompatible
                % set parameters
                postActionStatus(this.Tool.EventManager,'on',[getString(message('Control:systunegui:StatusMessageParameterVariation')) ' ']);
                try
                    this.ControlDesignData.setParameters(Params);
                catch ME
                    systuneapp.util.openUIAlert(this.Tool,ME.message);
                end
                clearActionStatus(this.Tool.EventManager);
            else
                systuneapp.util.openUIAlert(this.Tool,getString(message('Control:systunegui:LinearizationIncompatibleParamError',nOp,nParam)));                
            end
        end        
        
        %% Plot
        function populatePlotPopup(this,hBtn)     
            import matlab.ui.internal.toolstrip.*       
            % Get existing plots of appropriate types
            plottypes = systuneapp.PlotEnum.getPlotTypes(false);
            
            Popup = PopupList;
            Popup.Tag = 'mnuHomePlotPicker';
            
            % Add new plots
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:PlotNewPlots'));
            Header.Tag = 'HeaderLabel';
            add(Popup,Header);

            % Add new plot types
            for ct = 1:numel(plottypes)
                thisplot = plottypes(ct);
                msgkey = sprintf('Control:systunegui:PlotNew%s',char(thisplot));
                Text = ctrlMsgUtils.message(msgkey);
                PlotIcon = systuneapp.PlotEnum.getIcon(thisplot.Tag,false);
                Item = ListItem(Text, PlotIcon);
                addlistener(Item,'ItemPushed', @(hSrc,hData) plotSystem(this,thisplot));
                
                add(Popup,Item);
            end
            
            % Set the popup
            hBtn.Popup = Popup;
        end
        function plotSystem(this,plottype)
            this.ResponseSelectionDialog = systuneapp.internal.dialogs.SelectResponseToPlot(this.Tool.ControlDesignData, this.Tool.PlotManager, plottype);
            show(this.ResponseSelectionDialog,this.Tool.AppContainer);
            pack(this.ResponseSelectionDialog);
        end

        %% Response
        function localCreateNewResponse(this,hData)
            switch hData.Source.SelectedIndex
                case 2                
                    [this.ResponseDialogGC,this.ResponseDialogTC]= ...
                        createResponse(this.ControlDesignData,'IOTransfer',...
                        this.Widgets.AnalysisSection.AddResponsesButton);

                case 3
                    [this.ResponseDialogGC,this.ResponseDialogTC]= ...
                        createResponse(this.ControlDesignData,'LoopTransfer',...
                        this.Widgets.AnalysisSection.AddResponsesButton);
                case 4
                    [this.ResponseDialogGC,this.ResponseDialogTC]= ...
                        createResponse(this.ControlDesignData,'SensitivityTransfer',...
                        this.Widgets.AnalysisSection.AddResponsesButton);
            end
          
        end
        
        %% Widgets
        function createWidgets(this)            
            createFileSectionWidgets(this)
            if isSimulink(this.ControlDesignData)
                createLinearizationSectionWidgets(this)
            else
                createMatlabConfigSectionWidgets(this)
            end
            createAnalysisSectionWidgets(this)
            createDesignSectionWidgets(this)
            if isSimulink(this.ControlDesignData)
                createUpdateBlocksSectionWidgets(this)
            else
                createExportBlocksSectionWidgets(this)
            end
        end        
        function createFileSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            FileSection = Section(...
                getString(message('Control:systunegui:FileSection')));
            FileSection.Tag = 'FileSection';
            add(this.Tab,FileSection);            
                       
            OpenIcon = Icon('openFolder');
            OpenButton = Button(getString(message('Control:designerapp:FileOpen')),OpenIcon);            
            OpenButton.Description = getString(message('Control:systunegui:FileOpenTooltip')); 
            
            SaveIcon = Icon('saved');
            SaveButton = Button(getString(message('Control:designerapp:FileSave')),SaveIcon);
            SaveButton.Description = getString(message('Control:systunegui:FileSaveTooltip')); 
            
            % create column
            column1 = Column();
            column2 = Column();
            
            % assemble
            add(FileSection, column1);
            add(column1,OpenButton);
            add(FileSection, column2);
            add(column2,SaveButton);

            addlistener(SaveButton,'ButtonPushed', @(hSrc,hData) promptForSaveSession(this.Tool,false));
            addlistener(OpenButton,'ButtonPushed', @(hSrc,hData) promptForLoadSession(this.Tool));

            this.Widgets.FileSection =  struct(...
                'OpenButton',OpenButton, ...
                'SaveButton',SaveButton);
        end        
        
        function createLinearizationSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            LinearizationSection = Section(...
                getString(message('Control:systunegui:LinearizationSection')));
            LinearizationSection.Tag = 'LinearizationSection';
            add(this.Tab,LinearizationSection);
                       
           
            % OP Picker 
            this.OPPicker = slctrlguis.lintool.widgets.OPPickerV2(this.Tool,true);
            this.OPPicker.getDropDown.Description = getString(message('Control:systunegui:OperatingPointTooltip'));
            this.OPPickerListener1 = addlistener(this.OPPicker,'SelectionChanged',@(es,ed) operatingPointChanged(this));
            this.OPPickerListener2 = addlistener(this.OPPicker,'OPVariableModified',@(es,ed) operatingPointChanged(this));
            OpLabel = getLabel(this.OPPicker);
            OpDropDown = getDropDown(this.OPPicker);
            OpDropDown.Tag = 'btnOPPicker';
            
            % Param Picker
            this.ParamPicker = systuneapp.pickers.CSTunerParamPicker(this.Tool);
            ParamLabel = getLabel(this.ParamPicker);
            ParamDropDown = getDropDown(this.ParamPicker);
            ParamDropDown.Description = getString(message('Control:systunegui:ParameterVariationsTooltip'));
            ParamDropDown.Tag = 'btnParamPicker';            
            addlistener(this.ParamPicker,'ExportParams',...
                @(es,ed) linearizationParametersChanged(this));
                                      
            %% Linearization options
            LinearizationOptionsIcon = Icon('settings_linearize');
            LinearizationOptionsButton =  Button(getString(message('Control:systunegui:LinearizationOptions')),LinearizationOptionsIcon);            
            LinearizationOptionsButton.Description = getString(message('Control:systunegui:LinearizationOptionsTooltip'));
            addlistener(LinearizationOptionsButton,'ButtonPushed',@(es,ed) openLinearizationOptions(this));

            % columns
            column1 = Column('HorizontalAlignment','right');
            column2 = Column('HorizontalAlignment','left');
            % assemble
            add(column1,OpLabel);
            add(column1,ParamLabel);
            add(column2,OpDropDown);
            add(column2,ParamDropDown);
                                 
            pnl = Panel();
            add(pnl,column1)
            add(pnl,column2)
            maincolumn = Column();
            add(maincolumn,pnl);
            add(maincolumn,LinearizationOptionsButton);
            add(LinearizationSection,maincolumn);                         
            
            %% Widgets
            this.Widgets.LinearizationSection =  struct(...
                'OPPicker',this.OPPicker, ...
                'ParamPicker', this.ParamPicker,...
                'OpDropDown',OpDropDown, ...
                'LinearizationOptionsButton',LinearizationOptionsButton);
        end     
        
        function createMatlabConfigSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            ConfigSection = Section(...
                getString(message('Control:systunegui:ArchitectureSection')));
            ConfigSection.Tag = 'ConfigSection';
            add(this.Tab,ConfigSection);                  
            
            ArchIcon = Icon('controlSystemArchitecture');
            ArchButton = SplitButton(getString(message('Control:systunegui:EditArchitecture')),ArchIcon);
            ArchButton.Description = getString(message('Control:systunegui:EditArchitectureTooltip'));

            % create column
            column1 = Column();
            % assemble
            add(ConfigSection, column1);
            add(column1,ArchButton);
            
            ArchButton.DynamicPopupFcn = @(es,ed) localCreateArchMenu(this);
            addlistener(ArchButton,'ButtonPushed', @(hSrc,hData) localEditArchitecture(this));
            this.Widgets.MatlabConfigSection = struct('ArchButton',ArchButton);
        end     
        
        function createAnalysisSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            AnalysisSection = Section(...
                getString(message('Control:systunegui:AnalysisSection')));  
            AnalysisSection.Tag = 'AnalysisSection';
            add(this.Tab,AnalysisSection);                    
           
            PlotIcon = Icon('add_plot');
            PlotButton = DropDownButton(getString(message('Control:systunegui:AnalysisPlot')),PlotIcon);
            PlotButton.Description = getString(message('Control:systunegui:AnalysisPlotTooltip'));
            
            populatePlotPopup(this,PlotButton)
            
            % create column
            dummycolumn = Column(); % for centering
            add(AnalysisSection, dummycolumn);
            column1 = Column();
            % assemble
            add(AnalysisSection, column1);
            add(column1,PlotButton);
            
            this.Widgets.AnalysisSection =  struct(...
                'PlotButton',PlotButton);            
        end     
        
        function createDesignSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            DesignSection = Section(...
                getString(message('Control:systunegui:DesignSection')));
            DesignSection.Tag = 'DesignSection';
            add(this.Tab,DesignSection);
                   
            
            StoreDesignButtonIcon = Icon('download_controlSystem');
            StoreDesignButton = Button(getString(message('Control:systunegui:DesignStore')),StoreDesignButtonIcon);            
            StoreDesignButton.Description = getString(message('Control:systunegui:DesignStoreTooltip')); 

            
            RetrieveDesignButtonIcon = Icon('upload_controlSystem');
            RetrieveDesignButton = DropDownButton(getString(message('Control:systunegui:DesignRetrieve')),RetrieveDesignButtonIcon);            
            RetrieveDesignButton.Description = getString(message('Control:systunegui:DesignRetrieveTooltip'));            
                                        
            % Compare Design
            CompareDesignButtonIcon = Icon('threeSignals');
            CompareDesignButton = DropDownButton(getString(message('Control:systunegui:DesignCompare')),CompareDesignButtonIcon);
            CompareDesignButton.Description = getString(message('Control:systunegui:DesignCompareTooltip'));  
            CompareDesignButton.DynamicPopupFcn = @(es,ed) localCreateCompareDesignMenu(this);
            
            % Columns
            column1 = Column();
            column2 = Column();
            column3 = Column();
            % assemble
            add(DesignSection, column1);
            add(column1,StoreDesignButton);
            add(DesignSection, column2);
            add(column2,RetrieveDesignButton);
            add(DesignSection, column3);
            add(column3,CompareDesignButton);
            
            
            addlistener(StoreDesignButton,'ButtonPushed', @(hSrc,hData) localStoreDesign(this));
            RetrieveDesignButton.DynamicPopupFcn = @(es,ed) localCreateRestoreDesignMenu(this);
            this.Widgets.DesignSection =  struct(...
                'StoreDesignButton',StoreDesignButton, ...
                'RetrieveDesignButton',RetrieveDesignButton,...
                'CompareDesignButton',CompareDesignButton);
        end      
        
        function createUpdateBlocksSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            UpdateBlocksSection = Section(...
                getString(message('Control:systunegui:UpdateSimulinkBlocksSection')));
            UpdateBlocksSection.Tag = 'UpdateBlocksSection';
            add(this.Tab,UpdateBlocksSection);
            
            UpdateBlocksButtonIcon = Icon('arrowActionEast_simulink');
            UpdateBlocksButton =  Button(getString(message('Control:systunegui:UpdateSimulinkBlocks')),UpdateBlocksButtonIcon);
            UpdateBlocksButton.Description = getString(message('Control:systunegui:UpdateSimulinkBlocksTooltip'));
          
            % Columns
            column1 = Column();
            % assemble
            add(UpdateBlocksSection, column1);
            add(column1,UpdateBlocksButton);
            
            this.Widgets.UpdateBlocksSection =  struct(...
                'UpdateBlocksButton',UpdateBlocksButton);
            
            addlistener(UpdateBlocksButton,'ButtonPushed', @(es,ed) updateSimulinkBlock(this));
        end      
        
        function createExportBlocksSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            ExportBlocksSection = Section(...
                getString(message('Control:systunegui:ExportBlocksSection')));
            ExportBlocksSection.Tag = 'ExportBlocksSection';
            add(this.Tab,ExportBlocksSection);
                   
            
            ExportBlocksButtonIcon = Icon('export_data');
            ExportBlocksButton = Button(...
                getString(message('Control:systunegui:ExportBlocks')),...
                ExportBlocksButtonIcon);            
            ExportBlocksButton.Description = getString(message('Control:systunegui:ExportBlocksTooltip')); 

            this.Widgets.ExportBlocksSection =  struct(...
                'ExportBlocksButton',ExportBlocksButton);
            
             % Columns
            column1 = Column();
            % assemble
            add(ExportBlocksSection, column1);
            add(column1,ExportBlocksButton);
            
            addlistener(ExportBlocksButton,'ButtonPushed', @(hSrc,hData) exportBlockValues(this));
        end        
    
        function updateDesignWidgets(this)
            TB = ~isempty(getTunableBlock(this.ControlDesignData));
            this.Widgets.DesignSection.StoreDesignButton.Enabled = TB;
            B = ~isempty(getDesign(this.ControlDesignData));
            this.Widgets.DesignSection.CompareDesignButton.Enabled = B;
            this.Widgets.DesignSection.RetrieveDesignButton.Enabled = B;
        end        
    end
    
    methods (Static)
        function op = getOperatingPointFromSelection(OpSelection)             
            switch OpSelection.Type
                case 'Snapshot'
                    op = slctrlguis.lintool.evalSnapshotVector(OpSelection.Data);
                case 'Model'
                    op = [];
                case 'Existing'
                    Workspace = OpSelection.Data.Workspace;
                    VariableName = OpSelection.Data.VariableName;
                    op = evalin(Workspace,VariableName);
                case 'Multiple'
                    op = [];
                    VarFrom = OpSelection.Data.From;
                    Workspace = OpSelection.Data.Workspace;
                    VariableName = OpSelection.Data.VariableName;
                    for ct=1:length(VariableName)
                        OpData = evalin(Workspace{VarFrom(ct)},VariableName{ct}); % general op data
                        op = vertcat(op,OpData.getOperatingPoint); % get the operating point
                    end
            end
        end        
    end
end
