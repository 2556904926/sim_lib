classdef (Hidden) ModalTruncationPlot < mrtool.internal.plots.toolplot.AbstractToolPlot
    % Plot for Modal Truncation
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc. 
    
    %% Properties
    properties (Access=protected)
        PlotMode
        PlotDamp
        PlotDCContrib
        PlotModeCompare
    end

    properties (Access=protected,Transient)
        FrequencyRangeChangedListener
        MinDCChangedListener
        ModelResponseSelectorMovedListener
        AbsoluteErrorSelectorMovedListener
        RelativeErrorSelectorMovedListener
        DCContribSelectorMovedListener
        AnalysisPlotChangedListener
    end   
    
    %% Events
    events
        SelectorMoved
    end

    %% Constructor
    methods
        function this = ModalTruncationPlot(ToolData, ID)
            arguments
                ToolData (1,1) mrtool.data.ModalTruncationData
                ID (1,1) string
            end
            this = this@mrtool.internal.plots.toolplot.AbstractToolPlot(ToolData,ID);
            this.FigureTitleNoName = getString(message('Control:mrtool:ModalTruncationFigureTitle'));   
        end
    end

    %% Protected methods
    methods (Access=protected)
        function addListeners(this)
            addListeners@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            weakThis = matlab.lang.WeakReference(this);
            this.FrequencyRangeChangedListener = addlistener(this.ToolData,'FrequencyRange','PostSet',@(es,ed) frequencyRangeChanged(weakThis.Handle));
            this.MinDCChangedListener = addlistener(this.ToolData,'MinDC','PostSet',@(es,ed) minDCChanged(weakThis.Handle));   
            this.AnalysisPlotChangedListener = addlistener(this.ToolData,'AnalysisPlot','PostSet',@(es,ed) setVisiblePlots(weakThis.Handle));
        end
        
        function deleteListeners(this)
            deleteListeners@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            delete(this.AnalysisPlotChangedListener);
            delete(this.FrequencyRangeChangedListener);
            delete(this.MinDCChangedListener);
            delete(this.ModelResponseSelectorMovedListener);
            delete(this.AbsoluteErrorSelectorMovedListener);
            delete(this.RelativeErrorSelectorMovedListener);
            delete(this.DCContribSelectorMovedListener)
        end   

        function frequencyRangeChanged(this)
            if ~isempty(this.PlotModelResponse) && isvalid(this.PlotModelResponse)
                this.PlotModelResponse.Selection = this.ToolData.FrequencyRange;
            end
            if ~isempty(this.PlotAbsoluteError) && isvalid(this.PlotAbsoluteError)
                this.PlotAbsoluteError.Selection = this.ToolData.FrequencyRange;
            end
            if ~isempty(this.PlotRelativeError) && isvalid(this.PlotRelativeError)
                this.PlotRelativeError.Selection = this.ToolData.FrequencyRange;
            end
        end

        function minDCChanged(this)
            if ~isempty(this.PlotDCContrib) && isvalid(this.PlotDCContrib)
                this.PlotDCContrib.Selection = this.ToolData.MinDC;
            end
        end

        function createPlotMode(this)
            this.PlotMode = mrtool.internal.plots.MRModePlot(this.FigureLayout,this.ToolData);
            this.PlotMode.PlotHandle.Layout.Tile = 2;
        end

        function createPlotDamp(this)
            this.PlotDamp = mrtool.internal.plots.MRDampPlot(this.FigureLayout,this.ToolData);
            this.PlotDamp.PlotHandle.Layout.Tile = 2;
        end

        function createPlotDCContrib(this)
            this.PlotDCContrib = mrtool.internal.plots.MRDCContribPlot(this.FigureLayout,this.ToolData);
            this.PlotDCContrib.PlotHandle.Layout.Tile = 2;
            this.PlotDCContrib.Selection = this.ToolData.MinDC;
            weakThis = matlab.lang.WeakReference(this);
            this.DCContribSelectorMovedListener = addlistener(this.PlotDCContrib,'SelectorMoved',@(es,ed) cbSelectorWidgetMoved(weakThis.Handle,ed));
        end

        function createPlotModeCompare(this)
            this.PlotModeCompare = mrtool.internal.plots.MRModeComparePlot(this.FigureLayout,this.ToolData);
            this.PlotModeCompare.PlotHandle.Layout.Tile = 1;
        end

        function createPlotModelResponse(this)
            createPlotModelResponse@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            this.PlotModelResponse.Selection = this.ToolData.FrequencyRange;
            weakThis = matlab.lang.WeakReference(this);
            this.ModelResponseSelectorMovedListener = addlistener(this.PlotModelResponse,'SelectorMoved',@(es,ed) cbSelectorWidgetMoved(weakThis.Handle,ed));
        end

        function createPlotAbsoluteError(this)
            createPlotAbsoluteError@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            this.PlotAbsoluteError.Selection = this.ToolData.FrequencyRange;
            weakThis = matlab.lang.WeakReference(this);
            this.AbsoluteErrorSelectorMovedListener = addlistener(this.PlotAbsoluteError,'SelectorMoved',@(es,ed) cbSelectorWidgetMoved(weakThis.Handle,ed));
        end

        function createPlotRelativeError(this)
            createPlotRelativeError@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            this.PlotRelativeError.Selection = this.ToolData.FrequencyRange;
            weakThis = matlab.lang.WeakReference(this);
            this.RelativeErrorSelectorMovedListener = addlistener(this.PlotRelativeError,'SelectorMoved',@(es,ed) cbSelectorWidgetMoved(weakThis.Handle,ed));            
        end

        function Plots = getPlots(this)
            Plots = getPlots@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if ~isempty(this.PlotModeCompare)
                Plots = [Plots;{this.PlotModeCompare}];
            end            
            if ~isempty(this.PlotDCContrib)
                Plots = [Plots;{this.PlotDCContrib}];
            end
            if ~isempty(this.PlotMode)
                Plots = [Plots;{this.PlotMode}];
            end            
            if ~isempty(this.PlotDamp)
                Plots = [Plots;{this.PlotDamp}];
            end            
        end        

        function cbSelectorWidgetMoved(this,ed)
            data = ed.Data;
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(data);
            notify(this,'SelectorMoved',ed);
        end     

        function setVisiblePlots(this)
            % set visibility of comparison plots
            switch this.ToolData.ComparisonPlot
                case "modelResponse"
                    if ~isempty(this.PlotAbsoluteError)
                        this.PlotAbsoluteError.Visible = false;
                    end
                    if ~isempty(this.PlotRelativeError)
                        this.PlotRelativeError.Visible = false;
                    end
                    if ~isempty(this.PlotModeCompare)
                        this.PlotModeCompare.Visible = false;
                    end
                    if isempty(this.PlotModelResponse)
                        createPlotModelResponse(this);
                    end
                    this.PlotModelResponse.Visible = true;
                case "absoluteError"
                    if ~isempty(this.PlotModelResponse)
                        this.PlotModelResponse.Visible = false;
                    end
                    if ~isempty(this.PlotRelativeError)
                        this.PlotRelativeError.Visible = false;
                    end
                    if ~isempty(this.PlotModeCompare)
                        this.PlotModeCompare.Visible = false;
                    end
                    if isempty(this.PlotAbsoluteError)
                        createPlotAbsoluteError(this);
                    end
                    this.PlotAbsoluteError.Visible = true;
                case "relativeError"
                    if ~isempty(this.PlotModelResponse)
                        this.PlotModelResponse.Visible = false;
                    end
                    if ~isempty(this.PlotAbsoluteError)
                        this.PlotAbsoluteError.Visible = false;
                    end
                    if ~isempty(this.PlotModeCompare)
                        this.PlotModeCompare.Visible = false;
                    end
                    if isempty(this.PlotRelativeError)
                        createPlotRelativeError(this);
                    end
                    this.PlotRelativeError.Visible = true;
                case "modeCompare"
                    if ~isempty(this.PlotModelResponse)
                        this.PlotModelResponse.Visible = false;
                    end
                    if ~isempty(this.PlotAbsoluteError)
                        this.PlotAbsoluteError.Visible = false;
                    end
                    if ~isempty(this.PlotRelativeError)
                        this.PlotRelativeError.Visible = false;
                    end
                    if isempty(this.PlotModeCompare)
                        createPlotModeCompare(this);
                    end
                    this.PlotModeCompare.Visible = true;
            end
            % set visibility of analysis plots
            switch this.ToolData.AnalysisPlot
                case "contrib"
                    if ~isempty(this.PlotMode)
                        this.PlotMode.Visible = false;
                    end
                    if ~isempty(this.PlotDamp)
                        this.PlotDamp.Visible = false;
                    end
                    if isempty(this.PlotDCContrib)
                        createPlotDCContrib(this);
                    end
                    this.PlotDCContrib.Visible = true;
                case "mode"
                    if ~isempty(this.PlotDCContrib)
                        this.PlotDCContrib.Visible = false;
                    end
                    if ~isempty(this.PlotDamp)
                        this.PlotDamp.Visible = false;
                    end
                    if isempty(this.PlotMode)
                        createPlotMode(this);
                    end
                    this.PlotMode.Visible = true;
                case "damp"
                    if ~isempty(this.PlotDCContrib)
                        this.PlotDCContrib.Visible = false;
                    end
                    if ~isempty(this.PlotMode)
                        this.PlotMode.Visible = false;
                    end
                    if isempty(this.PlotDamp)
                        createPlotDamp(this);
                    end
                    this.PlotDamp.Visible = true;
            end
        end
    end
end