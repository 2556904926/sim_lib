classdef MRAbstractFrequencyPlot < mrtool.internal.plots.MRAbstractPlot
    % Model response plot.
    
    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc. 

    %% Properties
    properties (AbortSet,SetObservable)
        Selection = [];
    end

    properties (Access=protected)
        SelectorWidgets (:,:) ctrluis.XRangeSelector
        SpecifyFrequencyMenu
        SpecifyFrequencyDialog
    end

    properties (Dependent,SetAccess=private)
        TargetSystemResponse
        ReducedSystemResponse
    end

    properties (Access=protected,Transient)
        SelectorListeners (:,:) event.listener
    end

    %% Events
    events
        SelectorMoved
    end

    %% Constructor/destructor
    methods
        function this = MRAbstractFrequencyPlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractPlot(Parent,ToolData);                    
        end

        function delete(this)
            delete(this.SpecifyFrequencyDialog);
            delete(this.SelectorWidgets);
            delete(this.SelectorListeners);
            delete@mrtool.internal.plots.MRAbstractPlot(this);
        end
    end

    %% Get/Set
    methods
        % Selection
        function set.Selection(this,Selection)
            arguments
                this (1,1) mrtool.internal.plots.MRAbstractFrequencyPlot
                Selection (:,:) double
            end
            this.Selection = Selection;
            if this.Visible
                updateSelectorWidget(this);
            end
        end

        % TargetSystemResponse
        function TargetSystemResponse = get.TargetSystemResponse(this)
            if numel(this.PlotHandle.Responses) == 2
                TargetSystemResponse = this.PlotHandle.Responses(1);
            else
                TargetSystemResponse = [];
            end
        end

        % ReducedSystemResponse
        function ReducedSystemResponse = get.ReducedSystemResponse(this)
            ReducedSystemResponse = this.PlotHandle.Responses(end);
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createPlotData(this)
            createFrequencyPlot(this);
            addLegendButtonToToolbar(this.PlotHandle);
            removeMenu(this.PlotHandle,'specifyfrequency')
            weakThis = matlab.lang.WeakReference(this);
            this.SpecifyFrequencyMenu = uimenu(Parent=[],...
                Text=[getString(message('Controllib:plots:strSpecifyFrequency')),'...'],...
                Tag="specifyfrequencyMRTool",...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openSpecifyFrequencyDialog(weakThis.Handle));
            addMenu(this.PlotHandle,this.SpecifyFrequencyMenu,Above='propertyeditor',CreateNewSection=false);
            
            if ~isempty(this.TargetSystemResponse)
                this.TargetSystemResponse.SemanticColor = this.TargetSystemSemanticColor;
            end
            this.ReducedSystemResponse.SemanticColor = this.ReducedSystemSemanticColor;

            this.PlotHandle.Title.String = getString(message(this.TitleMsgID,this.TargetName));

            showLegend(this);
            
            updateSelectorWidget(this);
        end

        function updateSelectorWidget(this)
            qeUpdate(this.PlotHandle);
            if isempty(this.Selection)
                for ct=1:numel(this.SelectorWidgets)
                    this.SelectorWidgets(ct).Visible = false;
                end
            else
                this.PlotHandle.ChildAddedToAxesListenerEnabled = 'off';
                % Add additional selectors
                for ct = size(this.SelectorWidgets,1)+1:size(this.Selection,1)
                    if ct > 1
                        this.SelectorWidgets(ct,:) = this.SelectorWidgets(1,:); %preallocate
                        this.SelectorListeners(ct,:) = this.SelectorListeners(1,:); %preallocate
                    end
                    ax = getChartAxes(this.PlotHandle);
                    for ii = 1:numel(ax)
                        this.SelectorWidgets(ct,ii) = ctrluis.XRangeSelector(ax(ii),this.Selection(ct,:));
                        weakThis = matlab.lang.WeakReference(this);
                        this.SelectorListeners(ct,ii) = addlistener(this.SelectorWidgets(ct,ii),'SelectorMoved',@(es,ed) cbSelectorMoved(weakThis.Handle,ed,ct,ii));
                    end
                end
                this.PlotHandle.ChildAddedToAxesListenerEnabled = 'on';
                for ct=size(this.SelectorWidgets,1):-1:1
                    if ct <= size(this.Selection,1)
                        ax = getChartAxes(this.PlotHandle);
                        for ii = 1:numel(ax)
                            this.SelectorWidgets(ct,ii).Visible = true;
                            window = [-Inf Inf];
                            if ct > 1
                                window(1) = this.Selection(ct-1,2);
                            else
                                window(1) = 0;
                            end
                            if ct < size(this.Selection,1)
                                window(2) = this.Selection(ct+1,1);
                            else
                                if isa(this.ToolData,'mrtool.data.BalancedTruncationData')
                                    lim = pi/abs(this.TargetSystem.Ts);
                                else
                                    lim = Inf;
                                end
                                window(2) = lim;
                            end
                            this.SelectorWidgets(ct,ii).SelectorWindow = window;
                            this.SelectorWidgets(ct,ii).XRange = this.Selection(ct,:);
                        end
                    else
                        ax = getChartAxes(this.PlotHandle);
                        for ii = 1:numel(ax)
                            this.SelectorWidgets(ct,ii).Visible = false;
                        end
                        if ct > 1
                            this.SelectorWidgets(ct-1,ii).SelectorWindow(2) = this.SelectorWidgets(ct,ii).SelectorWindow(2);
                        end
                    end
                end
            end
            if strcmp(this.PlotHandle.XLimitsMode,"auto")
                xRangeLimit = [Inf -Inf];
                for ii = 1:numel(this.SelectorWidgets)
                    if this.SelectorWidgets(ii).Visible
                        xRange = this.SelectorWidgets(ii).XRange;
                        switch this.PlotHandle.FrequencyScale
                            case 'linear'
                                xRange = this.SelectorWidgets(ii).XRange.*[0.9 1.1];
                                if isinf(xRange(1))
                                    xRange(1) = inf; %skip
                                end
                                if isinf(xRange(2))
                                    xRange(2) = -inf; %skip
                                end
                            case 'log'
                                xRange = this.SelectorWidgets(ii).XRange.*[0.5 2];
                                if xRange(1) == 0
                                    xRange(1) = inf; %skip
                                end
                                if isinf(xRange(2))
                                    xRange(2) = -inf; %skip
                                end
                        end
                        xRangeLimit(1) = min(xRangeLimit(1),xRange(1));
                        xRangeLimit(2) = max(xRangeLimit(2),xRange(2));
                    end
                end
                for ii = 1:length(this.PlotHandle.Responses)
                    w = this.PlotHandle.Responses(ii).SourceData.Model.Frequency;
                    xRangeLimit(1) = min(xRangeLimit(1),min(w));
                    xRangeLimit(2) = max(xRangeLimit(2),max(w));
                end
                this.PlotHandle.XLimitsFocus = repmat({xRangeLimit},size(this.PlotHandle.XLimitsFocus,1),size(this.PlotHandle.XLimitsFocus,2));
            end
        end

        function cbSelectorMoved(this,ed,row,col)
            switch ed.Data.Source
                case 'LowerLimitLine'
                    for ii = 1:size(this.SelectorWidgets,2)
                        if ii ~= col
                            this.SelectorWidgets(row,ii).XRange(1) = ed.Data.Range(1);
                        end
                    end
                    if row > 1
                        this.SelectorWidgets(row-1).SelectorWindow(2) = ed.Data.Range(1);
                        for ii = 1:size(this.SelectorWidgets,2)
                            if ii ~= col
                                this.SelectorWidgets(row-1,ii).SelectorWindow(2) = ed.Data.Range(1);
                            end
                        end
                    end
                case 'UpperLimitLine'
                    for ii = 1:size(this.SelectorWidgets,2)
                        if ii ~= col
                            this.SelectorWidgets(row,ii).XRange(2) = ed.Data.Range(2);
                        end
                    end
                    if row < size(this.SelectorWidgets,1)
                        this.SelectorWidgets(row+1).SelectorWindow(1) = ed.Data.Range(2);
                        for ii = 1:size(this.SelectorWidgets,2)
                            if ii ~= col
                                this.SelectorWidgets(row+1,ii).SelectorWindow(1) = ed.Data.Range(2);
                            end
                        end
                    end
                case 'SelectedPatch'
                    for ii = 1:size(this.SelectorWidgets,2)
                        if ii ~= col
                            this.SelectorWidgets(row,ii).XRange = ed.Data.Range;
                        end
                    end
                    if row > 1
                        this.SelectorWidgets(row-1).SelectorWindow(2) = ed.Data.Range(1);
                        for ii = 1:size(this.SelectorWidgets,2)
                            if ii ~= col
                                this.SelectorWidgets(row-1,ii).SelectorWindow(2) = ed.Data.Range(1);
                            end
                        end
                    end
                    if row < size(this.SelectorWidgets,1)
                        this.SelectorWidgets(row+1).SelectorWindow(1) = ed.Data.Range(2);
                        for ii = 1:size(this.SelectorWidgets,2)
                            if ii ~= col
                                this.SelectorWidgets(row+1,ii).SelectorWindow(1) = ed.Data.Range(2);
                            end
                        end
                    end
            end
            this.Selection(row,:) = ed.Data.Range;
            data = ed.Data;
            data.SelectorNumber = row;
            data.Selector = 'XRange';
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData(data);
            notify(this,'SelectorMoved',ed)
        end  
        
        function openSpecifyFrequencyDialog(this)
            if isempty(this.SpecifyFrequencyDialog) || ~isvalid(this.SpecifyFrequencyDialog)
                this.SpecifyFrequencyDialog = controllib.chart.internal.widget.FrequencyEditorDialog();
                this.SpecifyFrequencyDialog.FrequencyChangedFcn = @(es,ed) cbFrequencyChanged(this,ed);
            end
            if issparse(this.TargetSystem)
                this.SpecifyFrequencyDialog.Frequency = this.ToolData.PlotFreqVector;
            else
                [~,f] = sigma(this.TargetSystem);
                if isequal(f,this.ToolData.PlotFreqVector)
                    this.SpecifyFrequencyDialog.Frequency = [];
                else
                    this.SpecifyFrequencyDialog.Frequency = this.ToolData.PlotFreqVector;
                end
            end
            this.SpecifyFrequencyDialog.FrequencyUnits = "rad/s";
            this.SpecifyFrequencyDialog.EnableAuto = ~issparse(this.TargetSystem);
            this.SpecifyFrequencyDialog.EnableRange = ~issparse(this.TargetSystem);
            show(this.SpecifyFrequencyDialog);

            function cbFrequencyChanged(this,ed)
                w = ed.Data.Frequency;
                if iscell(w)
                    [~,w] = sigma(this.TargetSystem,w);
                end
                this.ToolData.PlotFreqVector = w;
            end
        end
    end    

    %% Abstract methods
    methods (Abstract,Access=protected)
        createFrequencyPlot(this);
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts = this.SelectorWidgets;
        end

        function dlg = qeGetSpecifyFrequencyDialog(this)
            openSpecifyFrequencyDialog(this);
            dlg = this.SpecifyFrequencyDialog;
        end
    end
end