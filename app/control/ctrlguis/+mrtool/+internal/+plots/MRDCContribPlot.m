classdef MRDCContribPlot < mrtool.internal.plots.MRAbstractPlot
    % Normalized DC contributions plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (AbortSet,SetObservable)
        Selection = [];
    end

    properties (Constant,Access=protected)
        TitleMsgID = "";
    end

    properties (Access=protected)
        SelectorWidget
    end

    properties (Access=protected,Transient)
        SelectorListener
    end

    %% Events
    events
        SelectorMoved
    end

    %% Constructor
    methods
        function this = MRDCContribPlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractPlot(Parent,ToolData);
        end
    end

    %% Get/Set
    methods
        % Selection
        function set.Selection(this,Selection)
            arguments
                this (1,1) mrtool.internal.plots.MRDCContribPlot
                Selection (1,1) double
            end
            this.Selection = Selection;
            if this.Visible
                updateSelectorWidget(this);
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createPlotData(this)
            R = this.ToolData.ReduceSpec;
            if R.Options.ModeOnly
                this.PlotHandle = ax;
            else
                this.PlotHandle = view(R,'contrib',Parent=this.Parent);
            end

            this.SelectorWidget = ctrluis.YLevelSelector(this.PlotHandle,this.ToolData.MinDC);
            this.SelectorWidget.Visible = true;
            weakThis = matlab.lang.WeakReference(this);
            this.SelectorListener = addlistener(this.SelectorWidget,'SelectorMoved',@(es,ed) cbSelectorMoved(weakThis.Handle,ed));
        end
        
        function updatePlotData(this)            
            R = this.ToolData.ReduceSpec;
            if ~R.Options.ModeOnly
                delete(this.SelectorListener)
                delete(this.SelectorWidget)
                delete(this.PlotHandle); %Not a chart- force reset
                this.PlotHandle = view(R,'contrib',Parent=this.Parent);

                this.SelectorWidget = ctrluis.YLevelSelector(this.PlotHandle,this.ToolData.MinDC);
                this.SelectorWidget.Visible = true;
                updateSelectorWidget(this);
                weakThis = matlab.lang.WeakReference(this);
                this.SelectorListener = addlistener(this.SelectorWidget,'SelectorMoved',@(es,ed) cbSelectorMoved(weakThis.Handle,ed));
            end
        end

        function showLegend(~,~)
            % No legend
        end

        function setLegend(~)
            % No legend
        end

        function updateSelectorWidget(this)
            this.SelectorWidget.YLevel = this.Selection;
        end

        function cbSelectorMoved(this,ed)
            data = ed.Data;
            data.Selector = 'YLevel';
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(data);
            notify(this,'SelectorMoved',ed)
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts = this.SelectorWidget;
        end
    end
end
