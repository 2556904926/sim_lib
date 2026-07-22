classdef (Hidden) BalancedTruncationTab < mrtool.internal.tabs.AbstractToolTab
    % Balanced Truncation Tab of Model Reduction App
    % compatible with MATLAB Online    
    
    % Author(s): A. Ouellette
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
        function this = BalancedTruncationTab(data, toolplot, app, tag)
            arguments
                data (1,1) mrtool.data.AbstractData
                toolplot (1,1) mrtool.internal.plots.toolplot.AbstractToolPlot
                app (1,1) mrtool.internal.ModelReducerApp
                tag (1,1) string
            end
            title = getString(message('Control:mrtool:BalancedTruncationTab'));
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
            OrderStr = getString(message('Control:mrtool:BTOrderLabel'));
            MaxErrorStr = getString(message('Control:mrtool:BTMaxErrorLabel'));
            MinEnergyStr = getString(message('Control:mrtool:BTMinEnergyLabel'));
            MaxLossStr = getString(message('Control:mrtool:BTMaxLossLabel'));
            OrderTooltip = getString(message('Control:mrtool:BTOrderTooltip'));
            MaxErrorTooltip = getString(message('Control:mrtool:BTMaxErrorTooltip'));
            MinEnergyTooltip = getString(message('Control:mrtool:BTMinEnergyTooltip'));
            MaxLossTooltip = getString(message('Control:mrtool:BTMaxLossTooltip'));
            
            switch this.Data.ReductionCriteria
                case 'Order'
                    this.Widgets.ReduceSection.CriteriaDropDown.Value = OrderStr;
                    this.Widgets.ReduceSection.MethodLabel.Text = OrderStr;
                    this.Widgets.ReduceSection.MethodEditField.Value = mat2str(this.Data.ReducedOrder,2);
                    this.Widgets.ReduceSection.MethodEditField.Description = OrderTooltip;
                case 'MaxError'
                    this.Widgets.ReduceSection.CriteriaDropDown.Value = MaxErrorStr;
                    this.Widgets.ReduceSection.MethodLabel.Text = MaxErrorStr;
                    this.Widgets.ReduceSection.MethodEditField.Value = mat2str(this.Data.MaximumError,2);
                    this.Widgets.ReduceSection.MethodEditField.Description = MaxErrorTooltip;
                case 'MinEnergy'
                    this.Widgets.ReduceSection.CriteriaDropDown.Value = MinEnergyStr;
                    this.Widgets.ReduceSection.MethodLabel.Text = MinEnergyStr;
                    this.Widgets.ReduceSection.MethodEditField.Value = mat2str(this.Data.MinimumEnergy,2);
                    this.Widgets.ReduceSection.MethodEditField.Description = MinEnergyTooltip;
                case 'MaxLoss'
                    this.Widgets.ReduceSection.CriteriaDropDown.Value = MaxLossStr;
                    this.Widgets.ReduceSection.MethodLabel.Text = MaxLossStr;
                    this.Widgets.ReduceSection.MethodEditField.Value = mat2str(this.Data.MaximumLoss,2);
                    this.Widgets.ReduceSection.MethodEditField.Description = MaxLossTooltip;
            end

            % VISUALIZATION SECTION
            ResponsePlotStr = getString(message('Control:mrtool:ResponsePlot'));
            AbsoluteErrorPlotStr = getString(message('Control:mrtool:AbsoluteErrorPlot'));
            RelativeErrorPlotStr = getString(message('Control:mrtool:RelativeErrorPlot'));
            switch this.Data.ComparisonPlot
                case "modelResponse"
                    this.Widgets.VisualizationsSection.ComparisonPlotDropDown.Value = ResponsePlotStr;
                case "absoluteError"
                    this.Widgets.VisualizationsSection.ComparisonPlotDropDown.Value = AbsoluteErrorPlotStr;
                case "relativeError"
                    this.Widgets.VisualizationsSection.ComparisonPlotDropDown.Value = RelativeErrorPlotStr;
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createWidgets(this)
            import matlab.ui.internal.toolstrip.*
            createWidgets@mrtool.internal.tabs.AbstractToolTab(this,'BT');      
            % REDUCE SECTION
            ReduceSectionStr = getString(message('Control:mrtool:ReduceSection'));
            ReductionCriteriaStr = getString(message('Control:mrtool:BTReductionCriteriaLabel'));
            OrderStr = getString(message('Control:mrtool:BTOrderLabel'));
            MaxErrorStr = getString(message('Control:mrtool:BTMaxErrorLabel'));
            MinEnergyStr = getString(message('Control:mrtool:BTMinEnergyLabel'));
            MaxLossStr = getString(message('Control:mrtool:BTMaxLossLabel'));
            OrderTooltip = getString(message('Control:mrtool:BTOrderTooltip'));
            ReductionCriteriaTooltip = getString(message('Control:mrtool:BTReductionCriteriaTooltip'));
           
            ReduceSection = Section(ReduceSectionStr);
            ReduceSection.Tag = 'BalancedTruncationSection';

            % Column 1
            column = Column();
            add(ReduceSection,column);
            % criteria label                                                                                   
            CriteriaLabel = Label(ReductionCriteriaStr);
            add(column,CriteriaLabel); 
            % method label
            MethodLabel = Label(OrderStr);
            add(column,MethodLabel); 

            % spacing column
            column = Column('Width',5);
            add(ReduceSection,column);

            % Column 2
            column = Column('Width',140);
            add(ReduceSection,column);
            % criteria dropdown
            Items = {OrderStr;MaxErrorStr;MinEnergyStr;MaxLossStr};
            CriteriaDropDown = DropDown(Items);
            CriteriaDropDown.Value = Items{1};
            CriteriaDropDown.Description = ReductionCriteriaTooltip;
            add(column,CriteriaDropDown); 
            % method editfield
            MethodEditField = EditField('5:10');
            MethodEditField.Description = OrderTooltip; 
            add(column,MethodEditField); 
            
            % Store widgets
            this.Widgets.ReduceSection =  struct(...
                'CriteriaLabel',CriteriaLabel,...
                'CriteriaDropDown',CriteriaDropDown,...
                'MethodLabel',MethodLabel,...
                'MethodEditField',MethodEditField,...
                'Section',ReduceSection);                                                                                                    
                                                                 
                        
            % OPTIONS SECTION
            % Strings
            OptionsSectionStr = getString(message('Control:mrtool:OptionsSection'));
            OptionsStr = getString(message('Control:mrtool:Options'));
            OptionsTooltip = getString(message('Control:mrtool:BTOptionsTooltip'));
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
            this.SelectorMovedListener = addlistener(this.Document,'SelectorMoved',@(es,ed) cbSelectorMoved(weakThis.Handle,ed));
            % REDUCE SECTION
            this.Widgets.ReduceSection.MethodEditField.ValueChangedFcn = @(es,ed) setReductionValue(weakThis.Handle,ed.EventData.NewValue);  
            this.Widgets.ReduceSection.CriteriaDropDown.ValueChangedFcn = @(es,ed) setReductionCriteria(weakThis.Handle,ed.EventData.NewValue);   
            % OPTIONS SECTION      
            this.Widgets.OptionsSection.OptionsButton.ButtonPushedFcn = @(es,ed) openOptionsDialog(weakThis.Handle);  
        end

        function openOptionsDialog(this)
            if issparse(this.Data.TargetSystem)
                if isempty(this.SparseOptionsDialog) || ~isvalid(this.SparseOptionsDialog)
                    this.SparseOptionsDialog = mrtool.dialogs.SparseBalancedTruncationOptionsDialog(this.Data);
                    this.Widgets.OptionsSection.SparseOptionsDialog = this.SparseOptionsDialog;
                    this.SparseOptionsDialogApplyingListener = addlistener(this.OptionsDialog,'OptionsApplying',...
                        @(es,ed) setWaiting(this.App,true,getString(message('Control:mrtool:StatusMessageComputingReducedModel'))));
                    this.SparseOptionsDialogAppliedListener = addlistener(this.OptionsDialog,'OptionsApplied',...
                        @(es,ed) setWaiting(this.App,false));
                end
                show(this.SparseOptionsDialog,this.Widgets.OptionsSection.OptionsButton);
                pack(this.SparseOptionsDialog,'topleft');
                updateUI(this.SparseOptionsDialog);
            else                
                if isempty(this.OptionsDialog) || ~isvalid(this.OptionsDialog)
                    this.OptionsDialog = mrtool.dialogs.BalancedTruncationOptionsDialog(this.Data);
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

        function setReductionValue(this,value)
            try
                this.Data.ReductionValue = evalin('base',value);
            catch ME
                uialert(this.App.Container, ME.message, ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
            end
        end

        function setReductionCriteria(this,Selection)
            OrderStr = getString(message('Control:mrtool:BTOrderLabel'));
            MaxErrorStr = getString(message('Control:mrtool:BTMaxErrorLabel'));
            MinEnergyStr = getString(message('Control:mrtool:BTMinEnergyLabel'));
            MaxLossStr = getString(message('Control:mrtool:BTMaxLossLabel'));
            OrderTooltip = getString(message('Control:mrtool:BTOrderTooltip'));
            MaxErrorTooltip = getString(message('Control:mrtool:BTMaxErrorTooltip'));
            MinEnergyTooltip = getString(message('Control:mrtool:BTMinEnergyTooltip'));
            MaxLossTooltip = getString(message('Control:mrtool:BTMaxLossTooltip'));

            switch Selection
                case OrderStr
                    this.Widgets.ReduceSection.MethodLabel.Text = OrderStr;
                    this.Widgets.ReduceSection.MethodEditField.Description = OrderTooltip;
                    this.Data.ReductionCriteria = "Order";
                case MaxErrorStr
                    this.Widgets.ReduceSection.MethodLabel.Text = MaxErrorStr;
                    this.Widgets.ReduceSection.MethodEditField.Description = MaxErrorTooltip;
                    this.Data.ReductionCriteria = "MaxError";
                case MinEnergyStr
                    this.Widgets.ReduceSection.MethodLabel.Text = MinEnergyStr;
                    this.Widgets.ReduceSection.MethodEditField.Description = MinEnergyTooltip;
                    this.Data.ReductionCriteria = "MinEnergy";
                case MaxLossStr
                    this.Widgets.ReduceSection.MethodLabel.Text = MaxLossStr;
                    this.Widgets.ReduceSection.MethodEditField.Description = MaxLossTooltip;
                    this.Data.ReductionCriteria = "MaxLoss";
            end
            update(this);
        end

        function cbSelectorMoved(this,ed)
            switch ed.Data.Status
                case 'InProgress'
                    if ~isempty(this.OptionsDialog) && isvalid(this.OptionsDialog) && this.OptionsDialog.IsVisible
                        row = ed.Data.SelectorNumber;
                        switch ed.Data.Source
                            case 'LowerLimitLine'
                                column = 1;
                                data = ed.Data.Range(1);
                            case 'UpperLimitLine'
                                column = 2;
                                data = ed.Data.Range(2);
                            case 'SelectedPatch'
                                column = [1 2];
                                data = ed.Data.Range;
                        end
                        freqSelectorChanged(this.OptionsDialog,row,column,data,'off');
                    else
                        postActionStatus(this.App.EventManager,'off',getString(message('Control:mrtool:ReleaseSelector')));
                    end
                case 'Finished'
                    row = ed.Data.SelectorNumber;
                    switch ed.Data.Source
                        case 'LowerLimitLine'
                            column = 1;
                            data = ed.Data.Range(1);
                        case 'UpperLimitLine'
                            column = 2;
                            data = ed.Data.Range(2);
                        case 'SelectedPatch'
                            column = [1 2];
                            data = ed.Data.Range;
                    end
                    if ~isempty(this.OptionsDialog) && isvalid(this.OptionsDialog) && this.OptionsDialog.IsVisible
                        freqSelectorChanged(this.OptionsDialog,row,column,data,'on');
                    else
                        clearActionStatus(this.App.EventManager);
                        R = this.Data.ReduceSpec;
                        R.Options.FreqIntervals(row,column) = data;
                        this.Data.Options = R.Options;
                        applyOptions(this.Data);
                    end                                      
            end                       
        end

        function addComparisonPlots(this,labelColumn,dropDownColumn)
            import matlab.ui.internal.toolstrip.*
            ComparisonPlotStr = getString(message('Control:mrtool:ComparisonPlot'));
            ResponsePlotStr = getString(message('Control:mrtool:ResponsePlot'));
            AbsoluteErrorPlotStr = getString(message('Control:mrtool:AbsoluteErrorPlot'));
            RelativeErrorPlotStr = getString(message('Control:mrtool:RelativeErrorPlot'));
            ComparisonPlotTooltip = getString(message('Control:mrtool:ComparisonPlotTooltip'));
           
            % comparison plot label
            ComparisonLabel = Label(ComparisonPlotStr);
            add(labelColumn,ComparisonLabel);
            
            % comparison dropdown
            Items = {ResponsePlotStr;AbsoluteErrorPlotStr;RelativeErrorPlotStr};
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
            PlottingResponsePlotStr = getString(message('Control:mrtool:StatusMessagePlottingModelResponse'));
            PlottingAbsoluteErrorPlotStr = getString(message('Control:mrtool:StatusMessagePlottingAbsErrorPlot'));
            PlottingRelativeErrorPlotStr = getString(message('Control:mrtool:StatusMessagePlottingRelErrorPlot'));

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
            end
            clearActionStatus(this.App.EventManager);
        end

        function addAnaylsisPlots(~,labelColumn,dropDownColumn)
            addEmptyControl(labelColumn);          
            addEmptyControl(dropDownColumn);
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
            toolData = mrtool.data.BalancedTruncationData(NewTarget);
            if isempty(this.SparseInitDialog) || ~isvalid(this.SparseInitDialog)
                this.SparseInitDialog = mrtool.dialogs.SparseBalancedTruncationOptionsDialog(toolData);
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
                oldMethod = this.Data.Method;
                oldVector = this.Data.PlotFreqVector;
                oldOptions = this.Data.SparseOptions;
                oldOrder = this.Data.ReducedOrder;
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
                    this.Data.ReducedOrder = oldOrder;
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

