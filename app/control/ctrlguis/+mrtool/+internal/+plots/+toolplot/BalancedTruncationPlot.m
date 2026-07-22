classdef (Hidden) BalancedTruncationPlot < mrtool.internal.plots.toolplot.AbstractToolPlot
    % Plot for Balanced Truncation.
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc. 

    %% Properties
    properties (Access=protected)
        PlotHankel
    end

    properties (Access=protected,Transient)
        AnalysisPlotChangedListener
        AnalysisPlotSelectorListener
        FrequencyRangeChangedListener
        HankelBarSelectedListener
        EnergyBarSelectedListener
        LossBarSelectedListener
        ModelResponseSelectorMovedListener
        AbsoluteErrorSelectorMovedListener
        RelativeErrorSelectorMovedListener
    end    
    
    %% Events
    events
        SelectorMoved
    end

    %% Constructor
    methods
        function this = BalancedTruncationPlot(ToolData, ID)
            arguments
                ToolData (1,1) mrtool.data.BalancedTruncationData
                ID (1,1) string
            end
            this = this@mrtool.internal.plots.toolplot.AbstractToolPlot(ToolData,ID);
            this.FigureTitleNoName = getString(message('Control:mrtool:BalancedTruncationFigureTitle'));
        end
    end

    %% Protected methods
    methods (Access=protected)
        function addListeners(this)
            addListeners@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            weakThis = matlab.lang.WeakReference(this);
            this.FrequencyRangeChangedListener = addlistener(this.ToolData,'FrequencyRangeChanged',@(es,ed) frequencyRangeChanged(weakThis.Handle));
            this.AnalysisPlotChangedListener = addlistener(this.ToolData,'AnalysisPlot','PostSet',@(es,ed) setVisiblePlots(weakThis.Handle));
        end

        function deleteListeners(this)
            deleteListeners@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            delete(this.AnalysisPlotChangedListener);
            delete(this.AnalysisPlotSelectorListener);
            delete(this.FrequencyRangeChangedListener);
            delete(this.ModelResponseSelectorMovedListener);
            delete(this.AbsoluteErrorSelectorMovedListener);
            delete(this.RelativeErrorSelectorMovedListener);
            delete(this.HankelBarSelectedListener);
            delete(this.EnergyBarSelectedListener);
            delete(this.LossBarSelectedListener);
        end    

        function frequencyRangeChanged(this)
            if this.ToolData.FreqIntervalsUsed
                Selection = this.ToolData.ReduceSpec.Options.FreqIntervals;
            else
                Selection = [];
            end
            if ~isempty(this.PlotModelResponse) && isvalid(this.PlotModelResponse)
                this.PlotModelResponse.Selection = Selection;
            end
            if ~isempty(this.PlotAbsoluteError) && isvalid(this.PlotAbsoluteError)
                this.PlotAbsoluteError.Selection = Selection;
            end
            if ~isempty(this.PlotRelativeError) && isvalid(this.PlotRelativeError)
                this.PlotRelativeError.Selection = Selection;
            end
        end

        function createPlotHankel(this)
            this.PlotHankel = mrtool.internal.plots.MRHankelPlot(this.FigureLayout,this.ToolData);
            this.PlotHankel.PlotHandle.Layout.Tile = 2;
            weakThis = matlab.lang.WeakReference(this);
            this.HankelBarSelectedListener = addlistener(this.PlotHankel,'BarSelected',@(es,ed) cbBarSelected(weakThis.Handle,ed));                        
        end

        function cbBarSelected(this,ed)
            try
                this.ToolData.ReducedOrder = ed.Data;
            catch
                ed.Source.SelectorWidget.SelectedValues = this.ToolData.ReducedOrder;
                if ~isempty(this.Figure)
                    uialert(this.Figure,...
                        getString(message('Control:mrtool:BTErrorOrder',mat2str(this.ToolData.MinimumOrder),...
                        mat2str(this.ToolData.MaximumOrder))), ...
                        getString(message('Control:mrtool:ErrorReducedSystem')));
                end
            end
        end

        function createPlotModelResponse(this)
            createPlotModelResponse@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if this.ToolData.FreqIntervalsUsed
                this.PlotModelResponse.Selection = this.ToolData.ReduceSpec.Options.FreqIntervals;
            else
                this.PlotModelResponse.Selection = [];
            end
            weakThis = matlab.lang.WeakReference(this);
            this.ModelResponseSelectorMovedListener = addlistener(this.PlotModelResponse,'SelectorMoved',@(es,ed) cbSelectorWidgetMoved(weakThis.Handle,ed));
        end

        function createPlotAbsoluteError(this)
            createPlotAbsoluteError@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if this.ToolData.FreqIntervalsUsed
                this.PlotAbsoluteError.Selection = this.ToolData.ReduceSpec.Options.FreqIntervals;
            else
                this.PlotAbsoluteError.Selection = [];
            end
            weakThis = matlab.lang.WeakReference(this);
            this.AbsoluteErrorSelectorMovedListener = addlistener(this.PlotAbsoluteError,'SelectorMoved',@(es,ed) cbSelectorWidgetMoved(weakThis.Handle,ed));
        end  

        function createPlotRelativeError(this)
            createPlotRelativeError@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if this.ToolData.FreqIntervalsUsed
                this.PlotRelativeError.Selection = this.ToolData.ReduceSpec.Options.FreqIntervals;
            else
                this.PlotRelativeError.Selection = [];
            end
            weakThis = matlab.lang.WeakReference(this);
            this.RelativeErrorSelectorMovedListener = addlistener(this.PlotRelativeError,'SelectorMoved',@(es,ed) cbSelectorWidgetMoved(weakThis.Handle,ed));            
        end 

        function cbSelectorWidgetMoved(this,ed)
            data = ed.Data;
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(data);
            notify(this,'SelectorMoved',ed)
        end   

        function Plots = getPlots(this)
            Plots = getPlots@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if ~isempty(this.PlotHankel)
                Plots = [Plots;{this.PlotHankel}];
            end
        end

        function setVisiblePlots(this)
            setVisiblePlots@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            % set visibility of analysis plots
            if isempty(this.PlotHankel)
                createPlotHankel(this);
            end
            this.PlotHankel.Visible = false; %force update
            this.PlotHankel.Visible = true;
        end
    end
end