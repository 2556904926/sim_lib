classdef MRPZPlot < mrtool.internal.plots.MRAbstractPlot
    % Pole zero plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (Constant,Access=protected)
        TitleMsgID = "Control:mrtool:PzmapTitle";        
    end    

    properties (Dependent,SetAccess=private)
        TargetSystemResponse
        ReducedSystemResponse
    end

    %% Constructor
    methods
        function this = MRPZPlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractPlot(Parent,ToolData);                    
        end
    end

    %% Get/Set
    methods
        % TargetSystemResponse
        function TargetSystemResponse = get.TargetSystemResponse(this)
            TargetSystemResponse = this.PlotHandle.Responses(1);
        end

        % ReducedSystemResponse
        function ReducedSystemResponse = get.ReducedSystemResponse(this)
            ReducedSystemResponse = this.PlotHandle.Responses(2);
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createPlotData(this)
            this.PlotHandle = pzplot(this.Parent,this.TargetSystem,this.ReducedSystem);          
     
            this.TargetSystemResponse.SemanticColor = this.TargetSystemSemanticColor;
            this.ReducedSystemResponse.SemanticColor = this.ReducedSystemSemanticColor;

            this.PlotHandle.Title.String = getString(message(this.TitleMsgID,this.TargetName));

            showLegend(this);
        end

        function updatePlotData(this)
            this.TargetSystemResponse.SourceData.Model = this.TargetSystem;
            this.ReducedSystemResponse.SourceData.Model = this.ReducedSystem;
        end

        function setLegend(this)  
            this.TargetSystemResponse.Name = getString(message('Control:mrtool:TargetSystemLegend',this.TargetName,mat2str(order(this.TargetSystem))));
            this.ReducedSystemResponse.Name = getString(message('Control:mrtool:ReducedSystemLegend',mat2str(order(this.ReducedSystem)')));
        end        
    end
end