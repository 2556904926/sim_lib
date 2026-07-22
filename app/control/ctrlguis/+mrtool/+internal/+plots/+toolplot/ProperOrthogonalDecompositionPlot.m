classdef (Hidden) ProperOrthogonalDecompositionPlot < mrtool.internal.plots.toolplot.AbstractToolPlot
    % Plot for Proper Orthogonal Decomposition.
    
    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc. 
    
    %% Properties
    properties (Access=protected)
        PlotHankel
        PlotEnergy
        PlotLoss
    end

    properties (Access=protected,Transient)
        AnalysisPlotChangedListener
        AnalysisPlotSelectorListener
        HankelBarSelectedListener
        EnergyBarSelectedListener
        LossBarSelectedListener
    end    

    %% Constructor
    methods
        function this = ProperOrthogonalDecompositionPlot(ToolData, ID)
            arguments
                ToolData (1,1) mrtool.data.ProperOrthogonalDecompositionData
                ID (1,1) string
            end
            this = this@mrtool.internal.plots.toolplot.AbstractToolPlot(ToolData,ID);
            this.FigureTitleNoName = getString(message('Control:mrtool:ProperOrthogonalDecompositionFigureTitle'));
        end
    end

    %% Protected methods
    methods (Access=protected)
        function addListeners(this)
            addListeners@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            weakThis = matlab.lang.WeakReference(this);
            this.AnalysisPlotChangedListener = addlistener(this.ToolData,'AnalysisPlot','PostSet',@(es,ed) setVisiblePlots(weakThis.Handle));
        end

        function deleteListeners(this)
            deleteListeners@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            delete(this.AnalysisPlotChangedListener);
            delete(this.AnalysisPlotSelectorListener);
            delete(this.HankelBarSelectedListener);
            delete(this.EnergyBarSelectedListener);
            delete(this.LossBarSelectedListener);
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
            catch ME
                ed.Source.SelectorWidget.SelectedValues = this.ToolData.ReducedOrder;
                if ~isempty(this.Figure)
                    if isa(this.ToolData.TargetSystem,'mechss') && ~isFirstOrder(this.ToolData.TargetSystem)
                        msg = getString(message('Control:mrtool:PODErrorDoF',mat2str(this.ToolData.MinimumOrder),...
                            mat2str(this.ToolData.MaximumOrder)));
                    else
                        msg = getString(message('Control:mrtool:PODErrorOrder',mat2str(this.ToolData.MinimumOrder),...
                            mat2str(this.ToolData.MaximumOrder)));
                    end
                    uialert(this.Figure,msg, ...
                        getString(message('Control:mrtool:ErrorReducedSystem')));
                end
            end
        end
        
        function Plots = getPlots(this)
            Plots = getPlots@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if ~isempty(this.PlotHankel)
                Plots = [Plots;{this.PlotHankel}];
            end            
            if ~isempty(this.PlotEnergy)
                Plots = [Plots;{this.PlotEnergy}];
            end     
            if ~isempty(this.PlotLoss)
                Plots = [Plots;{this.PlotLoss}];
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