classdef (Hidden) ProperOrthogonalDecompositionTab < mrtool.internal.tabs.AbstractToolTab
    % Proper Orthogonal Decomposition Tab of Model Reduction App
    % compatible with MATLAB Online    
    
    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc.    
    
    %% Properties
    properties (Access=protected)
        OptionsDialog
        SparseOptionsDialog
        InitDialog
        SparseInitDialog
    end

    properties (Access=protected,Transient)
        InitDialogClosedListener
        SparseInitDialogClosedListener
        OptionsDialogApplyingListener
        OptionsDialogAppliedListener
        SparseOptionsDialogApplyingListener
        SparseOptionsDialogAppliedListener
    end
    
    %% Constructor/destructor
    methods
        function this = ProperOrthogonalDecompositionTab(data, doc, app, id)
            arguments
                data (1,1) mrtool.data.AbstractData
                doc (1,1) mrtool.internal.plots.toolplot.AbstractToolPlot
                app (1,1) mrtool.internal.ModelReducerApp
                id (1,1) string
            end
            title = getString(message('Control:mrtool:ProperOrthogonalDecompositionTab'));
            this = this@mrtool.internal.tabs.AbstractToolTab(data, doc, app, id, title);
        end

        function delete(this)
            delete@mrtool.internal.tabs.AbstractToolTab(this);
            delete(this.OptionsDialog);
            delete(this.SparseOptionsDialog);
            delete(this.InitDialog);
            delete(this.InitDialogClosedListener);
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
            OrderStr = getString(message('Control:mrtool:PODOrderLabel'));
            DoFStr = getString(message('Control:mrtool:PODDoFLabel'));
            MaxErrorStr = getString(message('Control:mrtool:PODMaxErrorLabel'));
            MinEnergyStr = getString(message('Control:mrtool:PODMinEnergyLabel'));
            MaxLossStr = getString(message('Control:mrtool:PODMaxLossLabel'));
            OrderTooltip = getString(message('Control:mrtool:PODOrderTooltip'));
            DoFTooltip = getString(message('Control:mrtool:PODDoFTooltip'));
            MaxErrorTooltip = getString(message('Control:mrtool:PODMaxErrorTooltip'));
            MinEnergyTooltip = getString(message('Control:mrtool:PODMinEnergyTooltip'));
            MaxLossTooltip = getString(message('Control:mrtool:PODMaxLossTooltip'));

            switch this.Data.ReductionCriteria
                case 'Order'
                    this.Widgets.ReduceSection.CriteriaDropDown.Value = OrderStr;
                    if isa(this.Data.TargetSystem,'mechss') && ~isFirstOrder(this.Data.TargetSystem)
                        % 2nd order mechss uses DoF instead of order
                        this.Widgets.ReduceSection.MethodLabel.Text = DoFStr;
                        this.Widgets.ReduceSection.MethodEditField.Description = DoFTooltip;
                    else
                        this.Widgets.ReduceSection.MethodLabel.Text = OrderStr;
                        this.Widgets.ReduceSection.MethodEditField.Description = OrderTooltip;
                    end
                    this.Widgets.ReduceSection.MethodEditField.Value = mat2str(this.Data.ReducedOrder,2);
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
    methods (Access=protected)
        function createWidgets(this)
            import matlab.ui.internal.toolstrip.*
            createWidgets@mrtool.internal.tabs.AbstractToolTab(this,'POD');

            % REDUCE SECTION
            ReduceSectionStr = getString(message('Control:mrtool:ReduceSection'));
            ReductionCriteriaStr = getString(message('Control:mrtool:PODReductionCriteriaLabel'));
            OrderStr = getString(message('Control:mrtool:PODOrderLabel'));
            MaxErrorStr = getString(message('Control:mrtool:PODMaxErrorLabel'));
            MinEnergyStr = getString(message('Control:mrtool:PODMinEnergyLabel'));
            MaxLossStr = getString(message('Control:mrtool:PODMaxLossLabel'));
            OrderTooltip = getString(message('Control:mrtool:PODOrderTooltip'));
            ReductionCriteriaTooltip = getString(message('Control:mrtool:PODReductionCriteriaTooltip'));
           
            ReduceSection = Section(ReduceSectionStr);
            ReduceSection.Tag = 'ProperOrthogonalDecompositionSection';

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
            OptionsTooltip = getString(message('Control:mrtool:PODOptionsTooltip'));
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
            
            %% ADD SECTIONS
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
            % REDUCE SECTION
            this.Widgets.ReduceSection.MethodEditField.ValueChangedFcn = @(es,ed) setReductionValue(weakThis.Handle,ed.EventData.NewValue);  
            this.Widgets.ReduceSection.CriteriaDropDown.ValueChangedFcn = @(es,ed) setReductionCriteria(weakThis.Handle,ed.EventData.NewValue);   
            % OPTIONS SECTION      
            this.Widgets.OptionsSection.OptionsButton.ButtonPushedFcn = @(es,ed) openOptionsDialog(weakThis.Handle); 
        end

        function openOptionsDialog(this)
            if issparse(this.Data.TargetSystem)
                if isempty(this.SparseOptionsDialog) || ~isvalid(this.SparseOptionsDialog)
                    this.SparseOptionsDialog = mrtool.dialogs.SparseProperOrthogonalDecompositionOptionsDialog(this.Data);
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
                    this.OptionsDialog = mrtool.dialogs.ProperOrthogonalDecompositionOptionsDialog(this.Data);
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
            OrderStr = getString(message('Control:mrtool:PODOrderLabel'));
            MaxErrorStr = getString(message('Control:mrtool:PODMaxErrorLabel'));
            MinEnergyStr = getString(message('Control:mrtool:PODMinEnergyLabel'));
            MaxLossStr = getString(message('Control:mrtool:PODMaxLossLabel'));
            OrderTooltip = getString(message('Control:mrtool:PODOrderTooltip'));
            MaxErrorTooltip = getString(message('Control:mrtool:PODOrderTooltip'));
            MinEnergyTooltip = getString(message('Control:mrtool:PODOrderTooltip'));
            MaxLossTooltip = getString(message('Control:mrtool:PODMaxLossTooltip'));

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
            toolData = mrtool.data.ProperOrthogonalDecompositionData(NewTarget);
            if issparse(NewTarget.System)
                if isempty(this.SparseInitDialog) || ~isvalid(this.SparseInitDialog)
                    this.SparseInitDialog = mrtool.dialogs.SparseProperOrthogonalDecompositionOptionsDialog(toolData);
                    this.Widgets.OptionsSection.SparseInitDialog = this.SparseInitDialog;
                    weakThis = matlab.lang.WeakReference(this);
                    weakDlg = matlab.lang.WeakReference(this.SparseInitDialog);
                    this.SparseInitDialogClosedListener = addlistener(weakDlg.Handle,'DialogClosed', ...
                        @(~,~) postTargetSet(weakThis.Handle,ed));
                end
                dlg = this.SparseInitDialog;
            else
                if isempty(this.InitDialog) || ~isvalid(this.InitDialog)
                    this.InitDialog = mrtool.dialogs.ProperOrthogonalDecompositionOptionsDialog(toolData);
                    this.Widgets.OptionsSection.InitDialog = this.InitDialog;
                    weakThis = matlab.lang.WeakReference(this);
                    weakDlg = matlab.lang.WeakReference(this.InitDialog);
                    this.InitDialogClosedListener = addlistener(weakDlg.Handle,'DialogClosed', ...
                        @(~,~) postTargetSet(weakThis.Handle,ed));
                end
                dlg = this.InitDialog;
            end
            dlg.ToolData = toolData;
            show(dlg,this.App.Container);
            pack(dlg,'topleft');
            updateUI(dlg);
            setInitMode(dlg);
        end

        function postTargetSet(this,ed)
            NewTarget = this.TargetList(this.Widgets.SystemSection.SystemDropDown.SelectedIndex);
            if issparse(NewTarget.System)
                dlg = this.SparseInitDialog;
            else
                dlg = this.InitDialog;
            end
            if dlg.Initialized
                oldTarget = this.Data.Target;
                oldReduceSpec = this.Data.ReduceSpec;
                oldMethod = this.Data.Method;
                oldVector = this.Data.PlotFreqVector;
                oldOptions = this.Data.Options;
                oldOrder = this.Data.ReducedOrder;
                this.Data.Target = NewTarget;
                this.Data.Method = dlg.InitData.Method;
                this.Data.Options = dlg.InitData.Options;
                if issparse(NewTarget.System)
                    this.Data.PlotFreqVector = dlg.InitData.FreqVector;
                end
                try
                    build(this.Data);
                catch ME
                    %try again
                    this.Data.Target = oldTarget;
                    this.Data.Method = oldMethod;
                    if issparse(NewTarget.System)
                        this.Data.PlotFreqVector = oldVector;
                    end
                    this.Data.Options = oldOptions;
                    unapplyOptions(this.Data,oldReduceSpec);
                    this.Data.ReducedOrder = oldOrder;
                    show(dlg,this.App.Container);
                    pack(dlg,'topleft');
                    throwInitFailedError(dlg,ME);
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

