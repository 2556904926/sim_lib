classdef MRModeComparePlot < mrtool.internal.plots.MRAbstractPlot
    % Mode locations plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (Constant,Access=protected)
        TitleMsgID = "Control:mrtool:ModeCompareTitle";
    end

    properties (Dependent,Access=private)
        PlotLegend
    end

    %% Constructor
    methods
        function this = MRModeComparePlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractPlot(Parent,ToolData);
        end
    end

    %% Get/Set
    methods
        % PlotLegend
        function lgd = get.PlotLegend(this)
            lgd = this.PlotHandle.Legend;
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createPlotData(this)
            R = this.ToolData.ReduceSpec;          
            this.PlotHandle = view(R,'mode',Parent=this.Parent);
            hold(this.PlotHandle,'on')
            RReduced = reducespec(this.ReducedSystem,'modal');
            this.PlotHandle = view(RReduced,'mode',Axes=this.PlotHandle);
            if isscalar(this.PlotHandle.Children) % Reduced system is static
                plot(this.PlotHandle,NaN,NaN);
            end
            hold(this.PlotHandle,'off')

            controllib.plot.internal.utils.setColorProperty(...
                this.PlotHandle.Children(2),"Color",this.TargetSystemSemanticColor);
            controllib.plot.internal.utils.setColorProperty(...
                this.PlotHandle.Children(1),"Color",this.ReducedSystemSemanticColor);

            this.PlotHandle.Title.String = getString(message(this.TitleMsgID,this.TargetName));

            addLegendButtonToToolbar(this);
            showLegend(this);
        end
        
        function updatePlotData(this)
            R = this.ToolData.ReduceSpec;
            delete(this.PlotHandle.Children);
            hold(this.PlotHandle,'on')
            this.PlotHandle = view(R,'mode',Axes=this.PlotHandle);
            RReduced = reducespec(this.ReducedSystem,'modal');
            this.PlotHandle = view(RReduced,'mode',Axes=this.PlotHandle);
            if isscalar(this.PlotHandle.Children) % Reduced system is static
                plot(this.PlotHandle,NaN,NaN);
            end
            hold(this.PlotHandle,'off')
            
            controllib.plot.internal.utils.setColorProperty(...
                this.PlotHandle.Children(2),"Color",this.TargetSystemSemanticColor);
            controllib.plot.internal.utils.setColorProperty(...
                this.PlotHandle.Children(1),"Color",this.ReducedSystemSemanticColor);
        end

        function showLegend(this,flag)
            arguments
                this (1,1) mrtool.internal.plots.MRAbstractPlot
                flag (1,1) matlab.lang.OnOffSwitchState = true
            end
            if flag
                legend(this.PlotHandle,'show');
				this.PlotHandle.Legend.Interpreter = 'none';
            else
                legend(this.PlotHandle,'hide');
            end
            setLegend(this);
            this.PlotLegend.Parent = this.PlotHandle.Parent;
            this.PlotHandle.Toolbar.Children(end).Value = this.PlotLegend.Visible;
        end

        function setLegend(this)
            targetName = getString(message('Control:mrtool:TargetSystemLegend',this.TargetName,mat2str(order(this.TargetSystem))));
            reducedName = getString(message('Control:mrtool:ReducedSystemLegend',mat2str(order(this.ReducedSystem)')));
            this.PlotLegend.String = {targetName,reducedName};
        end
    end
    methods (Access=private)
        function addLegendButtonToToolbar(this)
            delete(this.PlotHandle.Toolbar);
            legendIcon = fullfile(matlabroot,'toolbox','shared', filesep, 'controllib', ...
                filesep, 'graphics', filesep, '+controllib', filesep,'resources','legend_normal_16.png');
            tb = axtoolbar(this.PlotHandle,'default');
            btn = axtoolbarbtn(tb,'state',Icon=legendIcon);
            tb.Children = [tb.Children(2:end); btn];
            weakThis = matlab.lang.WeakReference(this);
            btn.ValueChangedFcn = @(es,ed) showLegend(weakThis.Handle,~weakThis.Handle.PlotLegend.Visible);
            this.PlotHandle.Toolbar = tb;
        end
    end
end
