classdef (Hidden) PoleZeroSimplificationTab < mrtool.internal.tabs.AbstractToolTab
    % Pole/Zero Simplification Tab of Model Reduction App
    % compatible with MATLAB Online     
    
    % Author(s): A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.   

    %% Constructor
    methods
        function this = PoleZeroSimplificationTab(data, toolplot, app, tag)
            arguments
                data (1,1) mrtool.data.AbstractData
                toolplot (1,1) mrtool.internal.plots.toolplot.AbstractToolPlot
                app (1,1) mrtool.internal.ModelReducerApp
                tag (1,1) string
            end
            title = getString(message('Control:mrtool:PoleZeroSimplificationTab'));
            this = this@mrtool.internal.tabs.AbstractToolTab(data, toolplot, app, tag, title);
        end
    end

    %% Public methods
    methods
        function update(this)
            update@mrtool.internal.tabs.AbstractToolTab(this);
            % REDUCE SECTION
            Widgets = this.Widgets.PoleZeroSimplificationSection;
            Widgets.ToleranceTextField.Value = num2str(this.Data.Tolerance,2);
            if log10(this.Data.Tolerance) < Widgets.ToleranceSlider.Limits(1)
                Widgets.ToleranceSlider.Limits(1) = floor(log10(this.Data.Tolerance));
            end
            Widgets.ToleranceSlider.Value = log10(this.Data.Tolerance);

            % VISUALIZATION SECTION
            Widgets = this.Widgets.VisualizationsSection;
            ResponsePlotStr = getString(message('Control:mrtool:ResponsePlot'));
            AbsoluteErrorPlotStr = getString(message('Control:mrtool:AbsoluteErrorPlot'));
            RelativeErrorPlotStr = getString(message('Control:mrtool:RelativeErrorPlot'));
            switch this.Data.ComparisonPlot
                case "modelResponse"
                    Widgets.ComparisonPlotDropDown.Value = ResponsePlotStr;
                case "absoluteError"
                    Widgets.ComparisonPlotDropDown.Value = AbsoluteErrorPlotStr;
                case "relativeError"
                    Widgets.ComparisonPlotDropDown.Value = RelativeErrorPlotStr;
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createWidgets(this)
            import matlab.ui.internal.toolstrip.*
            createWidgets@mrtool.internal.tabs.AbstractToolTab(this,'PZ');  
            % REDUCE SECTION
            % Strings
            PoleZeroSimplificationSectionStr = getString(message('Control:mrtool:PoleZeroSimplificationSection'));
            ToleranceStr = getString(message('Control:mrtool:Tolerance'));
            ToleranceTooltip = getString(message('Control:mrtool:ToleranceTooltip'));
            
            % Section           
            PoleZeroSimplificationSection = Section(PoleZeroSimplificationSectionStr);
            PoleZeroSimplificationSection.Tag = 'PoleZeroSimplificationSection';
            % Column1
            column1 = Column('HorizontalAlignment','right');
            add(PoleZeroSimplificationSection,column1);            
            % tolerance label
            ToleranceLabel = Label(ToleranceStr);
            add(column1,ToleranceLabel);
            % tolerance slider                           
            ToleranceSlider = Slider([-10 0],-5);
            ToleranceSlider.Tag = 'ToleranceSlider';            
            ToleranceSlider.Ticks = 5;
            ToleranceSlider.Labels = {getString(message('Control:mrtool:Less'))         0;
                                      getString(message('Control:mrtool:Cancellation')) 50;
                                      getString(message('Control:mrtool:More'))         100}; 
            ToleranceSlider.Description = ToleranceTooltip;
            add(column1,ToleranceSlider);
            % Column2
            column2 = Column('Width',60);
            add(PoleZeroSimplificationSection,column2);
            % empty row
            column2.addEmptyControl();
            % tolerance textfield
            ToleranceTextField = EditField('1e-5');
            ToleranceTextField.Description = ToleranceTooltip;
            add(column2,ToleranceTextField);
                                    
            % Store widgets
            this.Widgets.PoleZeroSimplificationSection =  struct(...
                'ToleranceLabel',ToleranceLabel,...
                'ToleranceSlider',ToleranceSlider,...
                'ToleranceTextField',ToleranceTextField,...
                'Section',PoleZeroSimplificationSection);  
            
            % add sections
            add(this.Tabs,this.Widgets.SystemSection.Section);
            add(this.Tabs,this.Widgets.PoleZeroSimplificationSection.Section);
            add(this.Tabs,this.Widgets.VisualizationsSection.Section);
            add(this.Tabs,this.Widgets.SaveSection.Section);             
        end 

        function addListeners(this)
            addListeners@mrtool.internal.tabs.AbstractToolTab(this);
            weakThis = matlab.lang.WeakReference(this);
            % VISUALIZATION SECTION
            this.Widgets.VisualizationsSection.ComparisonPlotDropDown.ValueChangedFcn = @(es,ed) cbSetComparisonPlot(weakThis.Handle, ed.EventData.NewValue);
            % REDUCE SECTION      
            this.Widgets.PoleZeroSimplificationSection.ToleranceTextField.ValueChangedFcn = @(es,ed) cbToleranceEditFieldChanged(weakThis.Handle,ed.EventData.NewValue);
            this.Widgets.PoleZeroSimplificationSection.ToleranceSlider.ValueChangedFcn = @(es,ed) cbToleranceSliderChanged(weakThis.Handle,ed.EventData.Value);  
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

        function cbToleranceEditFieldChanged(this,value)
            try
                value = evalin('base',value);
            catch ME
                uialert(this.App.Container, ME.message, ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
                return;
            end
            try
                this.Data.Tolerance = value;
            catch
                uialert(this.App.Container,getString(message('Control:mrtool:ErrorTol')), ...
                    getString(message('Control:mrtool:ErrorReducedSystem')));
                update(this);
            end
        end

        function cbToleranceSliderChanged(this,Value)
            this.Data.Tolerance = 10^Value;
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

        function addAnaylsisPlots(~,labelColumn,dropDownColumn)
            addEmptyControl(labelColumn);          
            addEmptyControl(dropDownColumn);        
        end

        function setTarget(this,~)
            NewTarget = this.TargetList(this.Widgets.SystemSection.SystemDropDown.SelectedIndex);
            this.Data.Target = NewTarget;
            build(this.Data);
        end

        function TargetList = getTargetList(this)
            TargetList = this.App.Models;
            TargetList = TargetList(arrayfun(@(x) ~issparse(x.System),TargetList));
        end
    end
end