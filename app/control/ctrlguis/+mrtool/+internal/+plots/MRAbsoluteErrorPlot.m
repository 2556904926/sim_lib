classdef MRAbsoluteErrorPlot < mrtool.internal.plots.MRAbstractFrequencyPlot
    % Absolute error plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (Constant,Access=protected)
        TitleMsgID = "Control:mrtool:AbsErrorTitle";    
    end

    %% Constructor
    methods
        function this = MRAbsoluteErrorPlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractFrequencyPlot(Parent,ToolData);                                 
        end
    end
    
    %% Protected methods
    methods (Access=protected)
        function createFrequencyPlot(this)
            sys = computeAbsoluteSystem(this);
            this.PlotHandle = sigmaplot(this.Parent,sys);
        end

        function updatePlotData(this)
            sys = computeAbsoluteSystem(this);
            this.ReducedSystemResponse.SourceData.Model = sys;
            updateSelectorWidget(this);
        end

        function setLegend(this)
            this.ReducedSystemResponse.Name = getString(message('Control:mrtool:ErrorLegend',mat2str(order(this.ReducedSystem)')));
        end         
    end

    %% Private methods
    methods (Access=private)
        function System = computeAbsoluteSystem(this)
            targetFRD = this.ToolData.TargetFRD;
            reducedFRD = this.ToolData.ReducedFRD;
            targetFRD.SamplingGrid = [];
            reducedFRD.SamplingGrid = [];
            System = targetFRD-reducedFRD;
            System.SamplingGrid = struct('Order',order(this.ReducedSystem));
        end
    end
end