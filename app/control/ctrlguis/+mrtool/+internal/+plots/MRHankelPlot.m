classdef (Hidden) MRHankelPlot < mrtool.internal.plots.MRAbstractPlot
    % HSV Plot for Hankel, Energy, and Loss Plots.
    
    % Copyright 2024 The MathWorks, Inc. 

    %% Properties
    properties (SetAccess=protected)
        SelectorWidget
    end

    properties (Dependent,AbortSet,SetObservable)
        Selection
    end

    properties (Dependent,SetAccess=private)
        TargetSystemResponse
    end

    properties (Access=protected,Transient)
        SelectorListener
    end

    properties (Constant,Access=protected)
        TitleMsgID = "";
    end

    %% Events
    events
        BarSelected
    end

    %% Constructor
    methods
        function this = MRHankelPlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractPlot(Parent,ToolData);
        end
    end

    %% Get/Set
    methods
        % TargetSystemResponse
        function TargetSystemResponse = get.TargetSystemResponse(this)
            TargetSystemResponse = this.PlotHandle.Responses(1);
        end

        % Selection
        function Selection = get.Selection(this)
            Selection = this.SelectorWidget.SelectedValues;
        end

        function set.Selection(this,Selection)
            arguments
                this (1,1) mrtool.internal.plots.MRHankelPlot
                Selection (1,:) double {mustBeNonnegative,mustBeInteger}
            end
            this.SelectorWidget.SelectedValues = Selection;
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createPlotData(this)
            R = this.ToolData.ReduceSpec;
            Type = this.ToolData.AnalysisPlot;
            this.PlotHandle = view(R,Type,Parent=this.Parent);
            addLegendButtonToToolbar(this.PlotHandle);

            showLegend(this);

            % pass order for stable part of the plant
            responseView = qeGetResponseViews(qeGetView(this.PlotHandle));
            b = getResponseObjects(responseView);
            b = b{1};
            if isa(this.ToolData,'mrtool.data.ProperOrthogonalDecompositionData') && isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                this.SelectorWidget = ctrluis.BarChartSelector(b(2),order(this.ReducedSystem)/2);
            else
                this.SelectorWidget = ctrluis.BarChartSelector(b(2),order(this.ReducedSystem));
            end
            weakThis = matlab.lang.WeakReference(this);
            this.SelectorListener = addlistener(this.SelectorWidget,...
                'SelectedValues','PostSet',@(es,ed) cbHankelBarSelected(weakThis.Handle,ed));
        end

        function updatePlotData(this)            
            R = this.ToolData.ReduceSpec;
            Type = this.ToolData.AnalysisPlot;
            this.TargetSystemResponse.SourceData.R = R;
            this.TargetSystemResponse.SourceData.HSVType = Type;

            switch Type
                case "sigma"
                    this.PlotHandle.Title.String = getString(message('Controllib:plots:strHSVTitle'));
                    if isa(this.ToolData,'mrtool.data.ProperOrthogonalDecompositionData') && isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                        this.PlotHandle.XLabel.String = getString(message('Control:transformation:PODROM14'));
                        this.PlotHandle.YLabel.String = getString(message('Control:transformation:PODROM15'));
                    else
                        this.PlotHandle.XLabel.String = getString(message('Controllib:plots:strState'));
                        this.PlotHandle.YLabel.String = getString(message('Controllib:plots:strStateEnergy'));
                    end
                case "energy"
                    this.PlotHandle.YLabel.String = getString(message('Control:transformation:BALROM16'));
                    if isa(this.ToolData,'mrtool.data.ProperOrthogonalDecompositionData') && isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                        this.PlotHandle.Title.String = getString(message('Control:transformation:PODROM18'));
                        this.PlotHandle.XLabel.String = getString(message('Control:transformation:PODROM14'));
                    else
                        this.PlotHandle.Title.String = getString(message('Control:transformation:BALROM15'));
                        this.PlotHandle.XLabel.String = getString(message('Controllib:plots:strState'));
                    end
                case "loss"
                    this.PlotHandle.Title.String = getString(message('Control:transformation:BALROM35'));
                    this.PlotHandle.YLabel.String = getString(message('Control:transformation:BALROM34'));
                    if isa(this.ToolData,'mrtool.data.ProperOrthogonalDecompositionData') && isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                        this.PlotHandle.XLabel.String = getString(message('Control:transformation:PODROM14'));
                    else
                        this.PlotHandle.XLabel.String = getString(message('Controllib:plots:strState'));
                    end
            end

            % Update controller order widget
            this.SelectorListener.Enabled = false;
            this.Selection = this.ToolData.ReducedOrder;
            this.SelectorListener.Enabled = true;
        end

        function setLegend(this)
            if isa(this.ToolData,'mrtool.data.ProperOrthogonalDecompositionData') && isa(this.TargetSystem,'mechss') && ~isFirstOrder(this.TargetSystem)
                this.SelectorWidget.DisplayName = getString(message('Control:mrtool:ReducedModelDoF',mat2str(order(this.ReducedSystem)'/2)));
            else
                this.SelectorWidget.DisplayName = getString(message('Control:mrtool:ReducedModelOrder',mat2str(order(this.ReducedSystem)')));
            end
        end

        function cbHankelBarSelected(this,ed)
            eventData = ctrluis.toolstrip.dataprocessing.GenericEventData(ed.AffectedObject.SelectedValues);
            notify(this,'BarSelected',eventData)
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts = this.SelectorWidget;
        end
    end
end
