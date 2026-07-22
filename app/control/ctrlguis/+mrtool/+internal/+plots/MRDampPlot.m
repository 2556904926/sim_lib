classdef MRDampPlot < mrtool.internal.plots.MRAbstractPlot
    % Mode dampings plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (Constant,Access=protected)
        TitleMsgID = "";
    end

    %% Constructor
    methods
        function this = MRDampPlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractPlot(Parent,ToolData);
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createPlotData(this)
            R = this.ToolData.ReduceSpec;
            this.PlotHandle = view(R,'damp',Parent=this.Parent);
        end

        function updatePlotData(this)
            R = this.ToolData.ReduceSpec;
            delete(this.PlotHandle); %Not a chart- force reset
            this.PlotHandle = view(R,'damp',Parent=this.Parent);
            setPlotConfiguration(this);
        end

        function showLegend(~,~)
            % No legend
        end

        function setLegend(~)
            % No legend
        end
    end
end
