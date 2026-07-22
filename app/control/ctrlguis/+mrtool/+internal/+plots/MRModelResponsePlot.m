classdef MRModelResponsePlot < mrtool.internal.plots.MRAbstractFrequencyPlot
    % Model response plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (Constant,Access=protected)
        TitleMsgID = "Control:mrtool:SystemResponseTitle";
    end

    %% Constructor
    methods
        function this = MRModelResponsePlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractFrequencyPlot(Parent,ToolData);                    
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createFrequencyPlot(this)
            sys = this.ToolData.TargetFRD;
            sys2 = this.ToolData.ReducedFRD;
            if issiso(this.TargetSystem)
                opt = bodeoptions('cstprefs');
                opt.PhaseMatching = 'on';
                this.PlotHandle = bodeplot(this.Parent,sys,sys2,opt);
            else
                this.PlotHandle = sigmaplot(this.Parent,sys,sys2);
            end
        end

        function updatePlotData(this)
            if issiso(this.TargetSystem) == issiso(this.TargetSystemResponse.SourceData.Model)
                this.TargetSystemResponse.SourceData.Model = this.ToolData.TargetFRD;
                this.ReducedSystemResponse.SourceData.Model = this.ToolData.ReducedFRD;
                updateSelectorWidget(this);
            else
                % Switch between bode and sigma
                delete(this.SpecifyFrequencyMenu);
                delete(this.SelectorWidgets)
                delete(this.SelectorListeners)
                delete(this.PlotHandle);
                this.SelectorWidgets = ctrluis.XRangeSelector.empty;
                this.SelectorListeners = event.listener.empty;
                this.PlotHandle = [];
                createPlot(this);
            end
        end

        function setLegend(this)
            this.TargetSystemResponse.Name = getString(message('Control:mrtool:TargetSystemLegend',this.TargetName,mat2str(order(this.TargetSystem))));
            this.ReducedSystemResponse.Name = getString(message('Control:mrtool:ReducedSystemLegend',mat2str(order(this.ReducedSystem)')));            
        end      
    end
end