classdef (Abstract,Hidden) AbstractToolPlot < handle
    % Abstract Tool Plot
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc. 
    
    %% Properties
    properties (SetAccess=protected)
        Document
        DocumentGroupTag
        FigureLayout
    end

    properties (Dependent,SetAccess=private)
        Figure
    end

    properties (SetAccess=immutable,WeakHandle)
        ToolData (1,1) handle = matlab.lang.invalidHandle('matlab.lang.HandlePlaceholder')
    end

    properties (Access=protected)
        FigureTitleNoName

        PlotModelResponse
        PlotAbsoluteError
        PlotRelativeError
    end

    properties (Dependent,SetAccess=private)
        FigureTitle
        Plots
    end
    
    properties (Access=protected,Transient)
        TargetNameChangedListener
        ToolDataChangedListener
        ToolDataDeletedListener
        ComparisonPlotChangedListener
    end            

    %% Constructor/destructor
    methods
        function this = AbstractToolPlot(ToolData,DocGroupTag)
            arguments
                ToolData (1,1) mrtool.data.AbstractData
                DocGroupTag (1,1) string
            end
            this.ToolData = ToolData;
            this.DocumentGroupTag = DocGroupTag;
        end
        function delete(this)
            deleteListeners(this);
            delete(this.Figure);
        end
    end

    %% Get/Set
    methods
        % Figure
        function Figure = get.Figure(this)
            if isempty(this.Document) || ~isvalid(this.Document)
                Figure = [];
            else
                Figure = this.Document.Figure;
            end
        end

        % FigureTitle
        function FigureTitle = get.FigureTitle(this)
            FigureTitle = sprintf('%s - %s',this.FigureTitleNoName,this.ToolData.TargetName);
        end

        % Plots
        function Plots = get.Plots(this)
            Plots = getPlots(this);
        end
    end

    %% Public methods
    methods
        function createPlot(this)
            if isempty(this.Figure) || ~ishandle(this.Figure)
                document = matlab.ui.internal.FigureDocument();
                document.Title = this.FigureTitle;
                this.Document = document;                
                this.FigureLayout = tiledlayout(this.Figure,2,1);
            end
            this.Figure.Name = this.FigureTitle;
            setVisiblePlots(this);
            addListeners(this);
        end  
    end

    %% Protected methods
    methods (Access=protected)
        function addListeners(this)
            weakThis = matlab.lang.WeakReference(this);
            this.TargetNameChangedListener = addlistener(this.ToolData, 'ToolNameChanged', @(es,ed) updateTitle(weakThis.Handle));
            this.ToolDataChangedListener = addlistener(this.ToolData,'ToolDataChanged',@(es,ed) updateTitle(weakThis.Handle));
            this.ToolDataDeletedListener = addlistener(this.ToolData,'ObjectBeingDestroyed',@(es,ed) delete(weakThis.Handle));
            this.ComparisonPlotChangedListener = addlistener(this.ToolData,'ComparisonPlot','PostSet',@(es,ed) setVisiblePlots(weakThis.Handle));
            this.Figure.DeleteFcn = @(es,ed) delete(weakThis.Handle);
        end

        function deleteListeners(this)
            delete(this.TargetNameChangedListener);
            delete(this.ToolDataChangedListener);
            delete(this.ToolDataDeletedListener);
            delete(this.ComparisonPlotChangedListener);
        end

        function createPlotModelResponse(this)             
            this.PlotModelResponse = mrtool.internal.plots.MRModelResponsePlot(this.FigureLayout,this.ToolData);
            this.PlotModelResponse.PlotHandle.Layout.Tile = 1;
        end

        function createPlotAbsoluteError(this)
            this.PlotAbsoluteError = mrtool.internal.plots.MRAbsoluteErrorPlot(this.FigureLayout,this.ToolData);
            this.PlotAbsoluteError.PlotHandle.Layout.Tile = 1;
        end  

        function createPlotRelativeError(this)
            this.PlotRelativeError = mrtool.internal.plots.MRRelativeErrorPlot(this.FigureLayout,this.ToolData);
            this.PlotRelativeError.PlotHandle.Layout.Tile = 1;
        end

        function Plots = getPlots(this)
            Plots = cell(0,1);
            if ~isempty(this.PlotModelResponse)
                Plots = [Plots;{this.PlotModelResponse}];
            end
            if ~isempty(this.PlotAbsoluteError)
                Plots = [Plots;{this.PlotAbsoluteError}];
            end
            if ~isempty(this.PlotRelativeError)
                Plots = [Plots;{this.PlotRelativeError}];
            end            
        end

        function setVisiblePlots(this)
            % set visibility of comparison plots
            switch this.ToolData.ComparisonPlot
                case 'modelResponse'
                    if ~isempty(this.PlotAbsoluteError)
                        this.PlotAbsoluteError.Visible = false;
                    end
                    if ~isempty(this.PlotRelativeError)
                        this.PlotRelativeError.Visible = false;
                    end
                    if isempty(this.PlotModelResponse)
                        createPlotModelResponse(this);
                    end
                    this.PlotModelResponse.Visible = true;
                case 'absoluteError'
                    if ~isempty(this.PlotModelResponse)
                        this.PlotModelResponse.Visible = false;
                    end
                    if ~isempty(this.PlotRelativeError)
                        this.PlotRelativeError.Visible = false;
                    end
                    if isempty(this.PlotAbsoluteError)
                        createPlotAbsoluteError(this);
                    end
                    this.PlotAbsoluteError.Visible = true;
                case 'relativeError'
                    if ~isempty(this.PlotModelResponse)
                        this.PlotModelResponse.Visible = false;
                    end
                    if ~isempty(this.PlotAbsoluteError)
                        this.PlotAbsoluteError.Visible = false;
                    end
                    if isempty(this.PlotRelativeError)
                        createPlotRelativeError(this);
                    end
                    this.PlotRelativeError.Visible = true;
            end
        end

        function updateTitle(this)
            this.Figure.Name = this.FigureTitle;
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts.Figure = this.Figure;
            wdgts.Plots = this.Plots;
        end
    end
end
