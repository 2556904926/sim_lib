classdef (Hidden) ModalTruncationTab < mrtool.internal.tabs.AbstractToolTab
    % Modal Truncation Tab of Model Reduction App
    % compatible with MATLAB Online      
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.    
    
    %% Properties
    properties (Access=protected)
        OptionsDialog
        SparseOptionsDialog
        SparseInitDialog
    end   
    
    properties (Access=protected,Transient)
        SelectorMovedListener
        SparseInitDialogClosedListener
        OptionsDialogApplyingListener
        OptionsDialogAppliedListener
        SparseOptionsDialogApplyingListener
        SparseOptionsDialogAppliedListener
    end

    %% Constructor/destructor
    methods
        function this = ModalTruncationTab(data, toolplot, app, tag)
            arguments
                data (1,1) mrtool.data.AbstractData
                toolplot (1,1) mrtool.internal.plots.toolplot.AbstractToolPlot
                app (1,1) mrtool.internal.ModelReducerApp
                tag (1,1) string
            end
            title = getString(message('Control:mrtool:ModalTruncationTab'));
            this = this@mrtool.internal.tabs.AbstractToolTab(data, toolplot, app, tag, title);
        end

        function delete(this)
            delete@mrtool.internal.tabs.AbstractToolTab(this);
            delete(this.SelectorMovedListener);
            delete(this.OptionsDialog);
            delete(this.SparseOptionsDialog);
            delete(this.SparseInitDialog);
            delete(this.SparseInitDialogClosedListener);
            delete(this.OptionsDialogApplyingListener);
            delete(this.OptionsDialogAppliedListener);
            delete(this.SparseOptionsDialogApplyingListener);
            delete(this.SparseOptionsDialogAppliedListener);
        end
    end

    %% Public methods
    methods
        function update(this)
            update@mrtool.internal.tabs.AbstractToolTab(this);
            % REDUCE SECTION
            this.Widgets.ReduceSection.FrequencyRangeEditField.Value = mat2str(this.Data.FrequencyRange,2);
            this.Widgets.ReduceSection.DampingRangeEditField.Value = mat2str(this.Data.DampingRange,2);
            this.Widgets.ReduceSection.MinDCEditField.Value = num2str(this.Data.MinDC,2);

            % VISUALIZATION SECTION
            ResponsePlotStr = getString(message('Control:mrtool:ResponsePlot'));
            AbsoluteErrorPlotStr = getString(message('Control:mrtool:AbsoluteErrorPlot'));
            RelativeErrorPlotStr = getString(message('Control:mrtool:RelativeErrorPlot'));
            ModeCompareStr = getString(message('Control:mrtool:MTModeComparePlot'));
            switch this.Data.ComparisonPlot
                case "modelResponse"
                    this.Widgets.VisualizationsSection.ComparisonPlotDropDown.Value = ResponsePlotStr;
                case "absoluteError"
                    this.Widgets.VisualizationsSection.ComparisonPlotDropDown.Value = AbsoluteErrorPlotStr;
                case "relativeError"
                    this.Widgets.VisualizationsSection.ComparisonPlotDropDown.Value = RelativeErrorPlotStr;
                case "modeCompare"
                    this.Widgets.VisualizationsSection.ComparisonPlotDropDown.Value = ModeCompareStr;
            end

            R = this.Data.ReduceSpec;
            ModePlotStr = getString(message('Control:mrtool:MTModePlot'));
            DampPlotStr = getString(message('Control:mrtool:MTDampPlot'));
            DCPlotStr = getString(message('Control:mrtool:MTDCPlot'));
            if R.Options.ModeOnly
                Items = {ModePlotStr;DampPlotStr};
                this.Widgets.ReduceSection.MinDCLabel.Enabled = false;
                this.Widgets.ReduceSection.MinDCEditField.Enabled = false;
                this.Widgets.ReduceSection.MinDCEditField.Description = getString(message('Control:mrtool:MinDCTooltip2'));
            else
                Items = {DCPlotStr;ModePlotStr;DampPlotStr};
                this.Widgets.ReduceSection.MinDCLabel.Enabled = true;
                this.Widgets.ReduceSection.MinDCEditField.Enabled = true;
                this.Widgets.ReduceSection.MinDCEditField.Description = getString(message('Control:mrtool:MinDCTooltip'));
            end
            replaceAllItems(this.Widgets.VisualizationsSection.AnalysisPlotDropDown,Items);
            switch this.Data.AnalysisPlot
                case "mode"
                    this.Widgets.VisualizationsSection.AnalysisPlotDropDown.Value = ModePlotStr;
                case "damp"
                    this.Widgets.VisualizationsSection.AnalysisPlotDropDown.Value = DampPlotStr;
                case "contrib"
                    this.Widgets.VisualizationsSection.AnalysisPlotDropDown.Value = DCPlotStr;
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createWidgets(this)
            import matlab.ui.internal.toolstrip.*
            createWidgets@mrtool.internal.tabs.AbstractToolTab(this,'MT');   
            % REDUCE SECTION
            % Strings
            ReduceSectionStr = getString(message('Control:mrtool:ReduceSection'));
            FrequencyRangeStr = getString(message('Control:mrtool:FrequencyRangeLabel'));
            FrequencyRangeTooltip = getString(message('Control:mrtool:FrequencyRangeTooltip'));
            DampingRangeStr = getString(message('Control:mrtool:DampingRangeLabel'));
            DampingRangeTooltip = getString(message('Control:mrtool:DampingRangeTooltip'));
            MinDCStr = getString(message('Control:mrtool:MinDCLabel'));
            MinDCTooltip = getString(message('Control:mrtool:MinDCTooltip'));
            
            % Section
            ReduceSection = Section(ReduceSectionStr);
            ReduceSection.Tag = 'ReduceSection';     

            % Column1
            column1 = Column();
            add(ReduceSection,column1);
            % frequency range label
            FrequencyRangeLabel = Label(FrequencyRangeStr);
            add(column1,FrequencyRangeLabel)
            % damping range label
            DampingRangeLabel = Label(DampingRangeStr);
            add(column1,DampingRangeLabel);

            % spacing column
            column = Column('Width',5);
            add(ReduceSection,column);

            % column2
            column2 = Column('Width',75);
            add(ReduceSection,column2);
            % frequency range editfield            
            FrequencyRangeEditField = EditField('[0 Inf]');
            FrequencyRangeEditField.Description = FrequencyRangeTooltip; 
            add(column2,FrequencyRangeEditField);
            % damping range editfield
            DampingRangeEditField = EditField('[-1 1]');
            DampingRangeEditField.Description = DampingRangeTooltip;
            add(column2,DampingRangeEditField);

            % spacing column
            column = Column('Width',5);
            add(ReduceSection,column);
                        
            % Column3
            column3 = Column();
            add(ReduceSection,column3);
            % min dc label
            MinDCLabel = Label(MinDCStr);
            add(column3,MinDCLabel)
            addEmptyControl(column3);

            % spacing column
            column = Column('Width',5);
            add(ReduceSection,column);

            % column4
            column4 = Column('Width',75);
            add(ReduceSection,column4);
            % min dc editfield            
            MinDCEditField = EditField('0');
            MinDCEditField.Description = MinDCTooltip; 
            add(column4,MinDCEditField);
            addEmptyControl(column4);

            % Store widgets
            this.Widgets.ReduceSection =  struct(...
                'FrequencyRangeLabel',FrequencyRangeLabel,...
                'FrequencyRangeEditField',FrequencyRangeEditField,...
                'DampingRangeLabel',DampingRangeLabel,...
                'DampingRangeEditField',DampingRangeEditField,...
                'MinDCLabel',MinDCLabel,...
                'MinDCEditField',MinDCEditField,...
                'Section',ReduceSection);                                                
                        
            % OPTIONS SECTION
            % Strings
            OptionsSectionStr = getString(message('Control:mrtool:OptionsSection'));
            OptionsStr = getString(message('Control:mrtool:Options'));
            OptionsTooltip = getString(message('Control:mrtool:MTOptionsTooltip'));
            % Icon
            OptionsIcon = matlab.ui.internal.toolstrip.Icon('settings');
            
            % Section and column
            OptionsSection = Section(OptionsSectionStr);
            OptionsSection.Tag = 'OptionsSection';
            column = Column();
            add(OptionsSection,column);
            % Button                        
            OptionsButton = Button(OptionsStr,OptionsIcon);
            OptionsButton.Description = OptionsTooltip;
            add(column,OptionsButton);
            
            this.Widgets.OptionsSection =  struct(...
                'OptionsButton',OptionsButton,...
                'Section', OptionsSection);            
            
            % ADD SECTIONS
            add(this.Tabs,this.Widgets.SystemSection.Section);
            add(this.Tabs,this.Widgets.OptionsSection.Section);
            add(this.Tabs,this.Widgets.ReduceSection.Section);
            add(this.Tabs,this.Widgets.VisualizationsSection.Section);  
            add(this.Tabs,this.Widgets.SaveSection.Section);              
        end 

        function addListeners(this)
            addListeners@mrtool.internal.tabs.AbstractToolTab(this);
            % VISUALIZATION SECTION
            weakThis = matlab.lang.WeakReference(this);
            this.Widgets.VisualizationsSection.ComparisonPlotDropDown.ValueChangedFcn = @(es,ed) cbSetComparisonPlot(weakThis.Handle, ed.EventData.NewValue);
            this.Widgets.VisualizationsSection.AnalysisPlotDropDown.ValueChangedFcn = @(es,ed) cbSetAnalysisPlot(weakThis.Handle, ed.EventData.NewValue);     
            this.SelectorMovedListener = addlistener(this.Document,'SelectorMoved',@(es,ed) cbSelectorMoved(weakThis.Handle,ed));                      
            % REDUCE SECTION      
            this.Widgets.ReduceSection.FrequencyRangeEditField.ValueChangedFcn = @(es,ed) setFrequencyRange(weakThis.Handle,ed.EventData.NewValue);         
            this.Widgets.ReduceSection.DampingRangeEditField.ValueChangedFcn = @(es,ed) setDampingRange(weakThis.Handle,ed.EventData.NewValue);           
            this.Widgets.ReduceSection.MinDCEditField.ValueChangedFcn = @(es,ed) setMinDC(weakThis.Handle,ed.EventData.NewValue);   
            % OPTIONS SECTION      
            this.Widgets.OptionsSection.OptionsButton.ButtonPushedFcn = @(es,ed) openOptionsDialog(weakThis.Handle);     
        end

        function openOptionsDialog(this)
            if issparse(this.Data.TargetSystem)
                if isempty(this.SparseOptionsDialog) || ~isvalid(this.SparseOptionsDialog)
                    this.SparseOptionsDialog = mrtool.dialogs.SparseModalTruncationOptionsDialog(this.Data);
                    this.Widgets.OptionsSection.SparseOptionsDialog = this.SparseOptionsDialog;
                    this.SparseOptionsDialogApplyingListener = addlistener(this.SparseOptionsDialog,'OptionsApplying',...
                        @(es,ed) setWaiting(this.App,true,getString(message('Control:mrtool:StatusMessageComputingReducedModel'))));
                    this.SparseOptionsDialogAppliedListener = addlistener(this.SparseOptionsDialog,'OptionsApplied',...
                        @(es,ed) setWaiting(this.App,false));
                end
                show(this.SparseOptionsDialog,this.Widgets.OptionsSection.OptionsButton);
                pack(this.SparseOptionsDialog,'topleft');
                updateUI(this.SparseOptionsDialog);
            else
                if isempty(this.OptionsDialog) || ~isvalid(this.OptionsDialog)
                    this.OptionsDialog = mrtool.dialogs.ModalTruncationOptionsDialog(this.Data);
                    this.Widgets.OptionsSection.OptionsDialog = this.OptionsDialog;
                    this.OptionsDialogApplyingListener = addlistener(this.OptionsDialog,'OptionsApplying',...
                        @(es,ed) setWaiting(this.App,true,getString(message('Control:mrtool:StatusMessageComputingReducedModel'))));
                    this.OptionsDialogAppliedListener = addlistener(this.OptionsDialog,'OptionsApplied',...
                        @(es,ed) setWaiting(this.App,false));
                end
                show(this.OptionsDialog,this.Widgets.OptionsSection.OptionsButton);
                pack(this.OptionsDialog,'topleft');
                updateUI(this.OptionsDialog);
            end
        end

        function setFrequencyRange(this,value)
            try
                value = evalin('base',value);
            catch ME
                uialert(this.App.Container, ME.message, ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
                return;
            end
            try
                this.Data.FrequencyRange = value;
            catch
                uialert(this.App.Container, getString(message('Control:mrtool:MTErrorFrequencyRange')), ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
            end
        end

        function setDampingRange(this,value)
            try
                value = evalin('base',value);
            catch ME
                uialert(this.App.Container, ME.message, ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
                return;
            end
            try
                this.Data.DampingRange = value;
            catch
                uialert(this.App.Container, getString(message('Control:mrtool:MTErrorDampingRange')), ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
            end
        end

        function setMinDC(this,value)
            try
                value = evalin('base',value);
            catch ME
                uialert(this.App.Container, ME.message, ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
                return;
            end
            try
                this.Data.MinDC = value;
            catch
                uialert(this.App.Container, getString(message('Control:mrtool:MTErrorMinDC')), ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
            end
        end

        function cbSelectorMoved(this,ed)
            switch ed.Data.Selector
                case 'XRange'
                    switch ed.Data.Status
                        case 'InProgress'
                            postActionStatus(this.App.EventManager,'off',getString(message('Control:mrtool:ReleaseSelector')));
                            this.Widgets.ReduceSection.FrequencyRangeEditField.Editable = false;
                            switch ed.Data.Source
                                case 'LowerLimitLine'
                                    range = this.Data.FrequencyRange;
                                    range(1) = ed.Data.Range(1);
                                    this.Widgets.ReduceSection.FrequencyRangeEditField.Value = mat2str(range,2);
                                case 'UpperLimitLine'
                                    range = this.Data.FrequencyRange;
                                    range(2) = ed.Data.Range(2);
                                    this.Widgets.ReduceSection.FrequencyRangeEditField.Value = mat2str(range,2);
                                case 'SelectedPatch'
                                    this.Widgets.ReduceSection.FrequencyRangeEditField.Value = mat2str(ed.Data.Range,2);
                            end
                        case 'Finished'
                            switch ed.Data.Source
                                case 'LowerLimitLine'
                                    range = this.Data.FrequencyRange;
                                    range(1) = ed.Data.Range(1);
                                case 'UpperLimitLine'
                                    range = this.Data.FrequencyRange;
                                    range(2) = ed.Data.Range(2);
                                case 'SelectedPatch'
                                    range = ed.Data.Range;
                            end
                            this.Data.FrequencyRange = range;
                            clearActionStatus(this.App.EventManager);
                            this.Widgets.ReduceSection.FrequencyRangeEditField.Editable = true;
                            this.Widgets.ReduceSection.FrequencyRangeEditField.Value = mat2str(range,2);
                    end
                case 'YLevel'
                    switch ed.Data.Status
                        case 'InProgress'
                            postActionStatus(this.App.EventManager,getString(message('Control:mrtool:ReleaseSelector')));
                            this.Widgets.ReduceSection.MinDCEditField.Editable = false;
                            this.Widgets.ReduceSection.MinDCEditField.Value = mat2str(ed.Data.Level,2);
                        case 'Finished'
                            this.Data.MinDC = ed.Data.Level;
                            clearActionStatus(this.App.EventManager);
                            this.Widgets.ReduceSection.MinDCEditField.Editable = true;
                            this.Widgets.ReduceSection.MinDCEditField.Value = mat2str(ed.Data.Level,2);
                    end
            end
        end

        function addComparisonPlots(this,labelColumn,dropDownColumn)
            import matlab.ui.internal.toolstrip.*
            ComparisonPlotStr = getString(message('Control:mrtool:ComparisonPlot'));
            ResponsePlotStr = getString(message('Control:mrtool:ResponsePlot'));
            AbsoluteErrorPlotStr = getString(message('Control:mrtool:AbsoluteErrorPlot'));
            RelativeErrorPlotStr = getString(message('Control:mrtool:RelativeErrorPlot'));
            ModeCompareStr = getString(message('Control:mrtool:MTModeComparePlot'));
            ComparisonPlotTooltip = getString(message('Control:mrtool:ComparisonPlotTooltip'));
           
            % comparison plot label
            ComparisonLabel = Label(ComparisonPlotStr);
            add(labelColumn,ComparisonLabel);
            
            % comparison dropdown
            Items = {ResponsePlotStr;AbsoluteErrorPlotStr;RelativeErrorPlotStr;ModeCompareStr};
            ComparisonPlotDropDown = DropDown(Items);
            ComparisonPlotDropDown.Value = Items{1};
            ComparisonPlotDropDown.Description = ComparisonPlotTooltip;
            add(dropDownColumn,ComparisonPlotDropDown);
 
            this.Widgets.VisualizationsSection.ComparisonLabel = ComparisonLabel;  
            this.Widgets.VisualizationsSection.ComparisonPlotDropDown = ComparisonPlotDropDown;
        end

        function cbSetComparisonPlot(this,Selection)
            ResponsePlotStr = getString(message('Control:mrtool:ResponsePlot'));
            AbsoluteErrorPlotStr = getString(message('Control:mrtool:AbsoluteErrorPlot'));
            RelativeErrorPlotStr = getString(message('Control:mrtool:RelativeErrorPlot'));
            ModeCompareStr = getString(message('Control:mrtool:MTModeComparePlot'));
            PlottingResponsePlotStr = getString(message('Control:mrtool:StatusMessagePlottingModelResponse'));
            PlottingAbsoluteErrorPlotStr = getString(message('Control:mrtool:StatusMessagePlottingAbsErrorPlot'));
            PlottingRelativeErrorPlotStr = getString(message('Control:mrtool:StatusMessagePlottingRelErrorPlot'));
            PlottingModeCompareStr = getString(message('Control:mrtool:StatusMessagePlottingModeComparePlot'));

            switch Selection
                case ResponsePlotStr
                    postActionStatus(this.App.EventManager, 'on', PlottingResponsePlotStr);
                    this.Data.ComparisonPlot = "modelResponse";
                case AbsoluteErrorPlotStr
                    postActionStatus(this.App.EventManager, 'on', PlottingAbsoluteErrorPlotStr);
                    this.Data.ComparisonPlot = "absoluteError";
                case RelativeErrorPlotStr
                    postActionStatus(this.App.EventManager, 'on', PlottingRelativeErrorPlotStr);
                    this.Data.ComparisonPlot = "relativeError";
                case ModeCompareStr
                    postActionStatus(this.App.EventManager, 'on', PlottingModeCompareStr);
                    this.Data.ComparisonPlot = "modeCompare";
            end
            clearActionStatus(this.App.EventManager);
        end

        function addAnaylsisPlots(this,labelColumn,dropDownColumn)
            import matlab.ui.internal.toolstrip.*
            AnalysisPlotStr = getString(message('Control:mrtool:AnalysisPlot'));
            DCPlotStr = getString(message('Control:mrtool:MTDCPlot'));
            ModePlotStr = getString(message('Control:mrtool:MTModePlot'));
            DampPlotStr = getString(message('Control:mrtool:MTDampPlot'));
            AnalysisPlotTooltip = getString(message('Control:mrtool:AnalysisPlotTooltip'));

            % analysis plot label                                                                                   
            AnalysisLabel = Label(AnalysisPlotStr);
            add(labelColumn,AnalysisLabel); 
            
            % comparison dropdown
            Items = {DCPlotStr;ModePlotStr;DampPlotStr};
            AnalysisPlotDropDown = DropDown(Items);
            AnalysisPlotDropDown.Value = Items{1};
            AnalysisPlotDropDown.Description = AnalysisPlotTooltip;
            add(dropDownColumn,AnalysisPlotDropDown);
 
            this.Widgets.VisualizationsSection.AnalysisLabel = AnalysisLabel;  
            this.Widgets.VisualizationsSection.AnalysisPlotDropDown = AnalysisPlotDropDown;  
        end

        function cbSetAnalysisPlot(this,Selection)
            ModePlotStr = getString(message('Control:mrtool:MTModePlot'));
            DampPlotStr = getString(message('Control:mrtool:MTDampPlot'));
            DCPlotStr = getString(message('Control:mrtool:MTDCPlot'));
            PlottingModePlotStr = getString(message('Control:mrtool:StatusMessagePlottingMTModePlot'));
            PlottingDampPlotStr = getString(message('Control:mrtool:StatusMessagePlottingMTDampPlot'));
            PlottingDCPlotStr = getString(message('Control:mrtool:StatusMessagePlottingMTDCPlot'));

            switch Selection
                case ModePlotStr
                    postActionStatus(this.App.EventManager, 'on', PlottingModePlotStr);
                    this.Data.AnalysisPlot = "mode";
                case DampPlotStr
                    postActionStatus(this.App.EventManager, 'on', PlottingDampPlotStr);
                    this.Data.AnalysisPlot = "damp";
                case DCPlotStr
                    postActionStatus(this.App.EventManager, 'on', PlottingDCPlotStr);
                    this.Data.AnalysisPlot = "contrib";
            end
            clearActionStatus(this.App.EventManager);
        end
        
        function setTarget(this,ed)
            if ~isempty(this.OptionsDialog) && isvalid(this.OptionsDialog)
                close(this.OptionsDialog);
            end
            if ~isempty(this.SparseOptionsDialog) && isvalid(this.SparseOptionsDialog)
                close(this.SparseOptionsDialog);
            end
            NewTarget = this.TargetList(this.Widgets.SystemSection.SystemDropDown.SelectedIndex);
            SwitchingToStr = getString(message('Control:mrtool:SwitchingTargetName',NewTarget.Name));
            setWaiting(this.App, true, SwitchingToStr);
            if issparse(NewTarget.System)
                setSparseTarget(this,ed);
            else
                this.Data.Target = NewTarget;
                build(this.Data);
                setWaiting(this.App, false);
            end
        end

        function setSparseTarget(this,ed)
            NewTarget = this.TargetList(this.Widgets.SystemSection.SystemDropDown.SelectedIndex);
            toolData = mrtool.data.ModalTruncationData(NewTarget);
            if isempty(this.SparseInitDialog) || ~isvalid(this.SparseInitDialog)
                this.SparseInitDialog = mrtool.dialogs.SparseModalTruncationOptionsDialog(toolData);
                this.Widgets.OptionsSection.SparseInitDialog = this.SparseInitDialog;
                weakThis = matlab.lang.WeakReference(this);
                weakDlg = matlab.lang.WeakReference(this.SparseInitDialog);
                this.SparseInitDialogClosedListener = addlistener(weakDlg.Handle,'DialogClosed', ...
                    @(~,~) postSparseTargetSet(weakThis.Handle,ed));
            end
            this.SparseInitDialog.ToolData = toolData;
            show(this.SparseInitDialog,this.App.Container);
            pack(this.SparseInitDialog,'topleft');
            updateUI(this.SparseInitDialog);
            setInitMode(this.SparseInitDialog);
        end

        function postSparseTargetSet(this,ed)
            NewTarget = this.TargetList(this.Widgets.SystemSection.SystemDropDown.SelectedIndex);
            if this.SparseInitDialog.Initialized
                oldTarget = this.Data.Target;
                oldReduceSpec = this.Data.ReduceSpec;
                oldFreqRange = this.Data.FrequencyRange;
                oldDampRange = this.Data.DampingRange;
                oldMinDC = this.Data.MinDC;
                oldMethod = this.Data.Method;
                oldVector = this.Data.PlotFreqVector;
                oldOptions = this.Data.SparseOptions;
                DCCONTRIB = strcmpi(this.Data.AnalysisPlot,'contrib');
                if this.SparseInitDialog.InitData.Options.ModeOnly && DCCONTRIB
                    selection = uiconfirm(this.App.Container,getString(message('Control:mrtool:MTWarningDCContribUnavailable')),...
                        getString(message('Control:mrtool:Warning')),...
                        'Icon','warning','Options',getString(message('Control:mrtool:Ok'))); %#ok<NASGU>
                end
                this.Data.Target = NewTarget;
                this.Data.Method = this.SparseInitDialog.InitData.Method;
                this.Data.PlotFreqVector = this.SparseInitDialog.InitData.FreqVector;
                this.Data.SparseOptions = this.SparseInitDialog.InitData.Options;
                try
                    build(this.Data);
                catch ME
                    %try again
                    this.Data.Target = oldTarget;
                    this.Data.Method = oldMethod;
                    this.Data.PlotFreqVector = oldVector;
                    this.Data.SparseOptions = oldOptions;
                    unapplyOptions(this.Data,oldReduceSpec);
                    this.Data.FrequencyRange = oldFreqRange;
                    this.Data.DampingRange = oldDampRange;
                    this.Data.MinDC = oldMinDC;
                    show(this.SparseInitDialog,this.App.Container);
                    pack(this.SparseInitDialog,'topleft');
                    throwInitFailedError(this.SparseInitDialog,ME);
                    return;
                end
            else
                this.Widgets.SystemSection.SystemDropDown.Value = ed.OldValue;
            end
            setWaiting(this.App, false);
            update(this);
        end
    end
end