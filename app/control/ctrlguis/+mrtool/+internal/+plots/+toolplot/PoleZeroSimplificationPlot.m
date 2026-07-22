classdef (Hidden) PoleZeroSimplificationPlot < mrtool.internal.plots.toolplot.AbstractToolPlot
    % Plot for Mode Selection.
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc. 
    
    %% Properties
    properties (Access=protected)
        PlotPZ
    end              

    %% Constructor
    methods
        function this = PoleZeroSimplificationPlot(ToolData, ID)
            arguments
                ToolData (1,1) mrtool.data.PoleZeroSimplificationData
                ID (1,1) string
            end
            this = this@mrtool.internal.plots.toolplot.AbstractToolPlot(ToolData,ID);
            this.FigureTitleNoName = getString(message('Control:mrtool:PoleZeroSimplificationFigureTitle'));
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createPlotPZ(this)
            this.PlotPZ = mrtool.internal.plots.MRPZPlot(this.FigureLayout,this.ToolData);
            this.PlotPZ.PlotHandle.Layout.Tile = 2;
        end

        function Plots = getPlots(this)
            Plots = getPlots@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if ~isempty(this.PlotPZ)
                Plots = [Plots;{this.PlotPZ}];
            end
        end

        function setVisiblePlots(this)
            setVisiblePlots@mrtool.internal.plots.toolplot.AbstractToolPlot(this);
            if isempty(this.PlotPZ)
                createPlotPZ(this);
            end
            this.PlotPZ.Visible = true;
        end
    end
end