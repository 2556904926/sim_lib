classdef (Abstract,Hidden) MRAbstractPlot < handle
    % Abstract tool plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        Visible
    end

    properties (SetAccess=protected)   
        PlotHandle
    end

    properties (Constant,Access=protected)
        TargetSystemSemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
        ReducedSystemSemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
        InvalidSemanticColor = "--mw-graphics-colorNeutral-line-primary";
        TitleFontSize = cstprefs.tbxprefs().TitleFontSize;
        TitleFontWeight = cstprefs.tbxprefs().TitleFontWeight;
        AxisFontSize = cstprefs.tbxprefs().XYLabelsFontSize;
    end

    properties (Dependent,SetAccess=private)
        Figure
        TargetSystem
        TargetName
        ReducedSystem
    end

    properties (SetAccess=immutable,WeakHandle)
        Parent (1,1) matlab.graphics.layout.TiledChartLayout
    end

    properties (SetObservable,WeakHandle)
        ToolData (1,1) handle = matlab.lang.invalidHandle('matlab.lang.HandlePlaceholder')
    end

    properties (Access=private,Transient)
        TargetNameChangedListener
        ToolDataChangedListener
    end

    properties (Abstract,Constant,Access=protected)
        TitleMsgID (1,1) string
    end

    %% Constructor/destructor
    methods
        function this = MRAbstractPlot(Parent,ToolData)
            arguments
                Parent (1,1) matlab.graphics.layout.TiledChartLayout
                ToolData (1,1) mrtool.data.AbstractData
            end
            this.Parent = Parent;
            this.ToolData = ToolData;
            createPlot(this);
        end

        function delete(this)
            delete(this.PlotHandle);
        end
    end

    %% Get/Set
    methods
        % ToolData
        function set.ToolData(this,ToolData)
            arguments
                this (1,1) mrtool.internal.plots.MRAbstractPlot
                ToolData (1,1) mrtool.data.AbstractData
            end
            this.ToolData = ToolData;
            delete(this.TargetNameChangedListener); %#ok<MCSUP>
            delete(this.ToolDataChangedListener); %#ok<MCSUP>
            weakThis = matlab.lang.WeakReference(this);
            this.TargetNameChangedListener = addlistener(this.ToolData, 'ToolNameChanged', @(es,ed) updateTitle(weakThis.Handle)); %#ok<MCSUP>
            this.ToolDataChangedListener = addlistener(this.ToolData,'ToolDataChanged',@(es,ed) updatePlot(weakThis.Handle)); %#ok<MCSUP>
            if ~isempty(this.PlotHandle) %#ok<MCSUP>
                updatePlot(this);
            end
        end

        % TargetName
        function TargetName = get.TargetName(this)
            TargetName = this.ToolData.TargetName;
        end

        % TargetSystem
        function TargetSystem = get.TargetSystem(this)
            TargetSystem = this.ToolData.TargetSystem;
        end

        % ReducedSystem
        function ReducedSystem = get.ReducedSystem(this)
            ReducedSystem = this.ToolData.ReducedSystem;
        end

        % Visible
        function flag = get.Visible(this)
            flag = matlab.lang.OnOffSwitchState(~isempty(this.PlotHandle.Parent));
        end
        
        function set.Visible(this,flag)
            arguments
                this (1,1) mrtool.internal.plots.MRAbstractPlot
                flag (1,1) matlab.lang.OnOffSwitchState
            end
            if flag
                this.PlotHandle.Parent = this.Parent;
                updatePlot(this);
            else
                this.PlotHandle.Parent = [];
            end
            showLegend(this,flag);
        end

        % Figure
        function Figure = get.Figure(this)
            Figure = ancestor(this.PlotHandle,'figure');
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createPlot(this)
            createPlotData(this);
            setPlotConfiguration(this);
            setLegend(this);
        end

        function updatePlot(this)
            if this.Visible
                updatePlotData(this);
                updateTitle(this);
            end
        end

        function updateTitle(this)
            if this.TitleMsgID ~= ""
                titleString = getString(message(this.TitleMsgID,this.TargetName));
                this.PlotHandle.Title.String = titleString;
            end
            setLegend(this);
        end

        function setPlotConfiguration(this)
            this.PlotHandle.Title.FontSize = this.TitleFontSize;
            this.PlotHandle.XLabel.FontSize = this.AxisFontSize;
            this.PlotHandle.YLabel.FontSize = this.AxisFontSize;
            this.PlotHandle.Title.FontWeight = this.TitleFontWeight;
            this.PlotHandle.Title.Interpreter = 'none';
            grid(this.PlotHandle,'on');
        end

        function showLegend(this,flag)
            arguments
                this (1,1) mrtool.internal.plots.MRAbstractPlot
                flag (1,1) matlab.lang.OnOffSwitchState = true
            end
            if flag
                legend(this.PlotHandle,'show');
            else
                legend(this.PlotHandle,'hide');
            end
        end
    end

    %% Abstract methods
    methods (Abstract, Access=protected)
        createPlotData(this);
        updatePlotData(this);
        setLegend(this);
    end
end