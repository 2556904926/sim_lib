classdef ltiviewer < controllib.ui.internal.dialog.AbstractDialog &...
        matlab.mixin.SetGet & matlab.mixin.Copyable
    %viewgui.ltiviewer class

    %  Copyright 2020-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Preferences
    end
    
    properties (Access=protected,Constant)
        %AVAILABLEPLOTS: supported plot types
        AvailablePlots = struct(...
            'Name', string(ltiplottypes('Name')),...
            'Alias',string(ltiplottypes('Alias')));
        %AVAILABLELAYOUTS: supported tiled layouts, see "nexttile"
        AvailableLayouts = struct(...
            'TileLocation',{1;...
                           [1;19];...
                           [1;13;25];...
                           [1;4;19;22];...
                           [1;4;19;21;23];...
                           [1;3;5;19;21;23]},...
            'TileSpan',{[6 6];...
                        [3 6;3 6];...
                        [2 6;2 6;2 6];...
                        [3 3;3 3;3 3;3 3];...
                        [3 3;3 3;3 2;3 2;3 2];...
                        [3 2;3 2;3 2;3 2;3 2;3 2]})
    end

    properties (SetAccess = protected)
        %SYSTEMS: cell array of controllib.chart.internal.utils.ModelSource
        Systems (:,1) cell
        %INPUTNAMES: string array
        InputNames (:,1) string
        %OUTPUTNAMES: string array
        OutputNames (:,1) string
        %PLOTS: cell array of controllib.chart.internal.foundation.AbstractPlot
        Plots (:,1) cell
        %STYLEMANAGER: scalar controllib.chart.internal.options.ResponseStyleManager
        StyleManager = controllib.chart.internal.options.ResponseStyleManager
        %COLORORDER: integer array
        ColorOrder (:,1) double
    end

    properties (Access = protected)
        Legend
        LegendAxes
        LegendLines

        FigureMenu
        Toolbar
        FigureGrid
        PlotPanel
        PlotLayout
        PlotTiles
        StatusText

        StartupDialog
        ConfigDialog
        StyleDialog
        ImportDialog
        ExportDialog
        DeleteDialog
    end

    properties (Dependent,Access=private)
        NInputs
        NOutputs
    end

    %% Constructor/destructor
    methods
        function this = ltiviewer()
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Title = getString(message('Controllib:gui:strLTIViewer'));
            this.Name = "ResponseGUI";
            this.CloseMode = "destroy";
            this.Preferences = cstprefs.viewprefs(this.UIFigure);
            this.ColorOrder = 1:length(this.StyleManager.ColorOrder);
        end
        function delete(this)
            % Delete dialogs
            if ~isempty(this.Preferences) && isvalid(this.Preferences)
                delete(this.Preferences);
            end
            if ~isempty(this.StartupDialog) && isvalid(this.StartupDialog)
                delete(this.StartupDialog);
            end
            if ~isempty(this.ConfigDialog) && isvalid(this.ConfigDialog)
                delete(this.ConfigDialog);
            end
            if ~isempty(this.StyleDialog) && isvalid(this.StyleDialog)
                delete(this.StyleDialog);
            end
            if ~isempty(this.ImportDialog) && isvalid(this.ImportDialog)
                delete(this.ImportDialog);
            end
            if ~isempty(this.ExportDialog) && isvalid(this.ExportDialog)
                delete(this.ExportDialog);
            end
            if ~isempty(this.DeleteDialog) && isvalid(this.DeleteDialog)
                delete(this.DeleteDialog);
            end
            delete@controllib.ui.internal.dialog.AbstractDialog(this);
        end
    end

    %% Get/Set
    methods
        function NInputs = get.NInputs(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            if isempty(this.Systems)
                NInputs = 1;
            else
                NInputs = 0;
                for ii = 1:length(this.Systems)
                    [nu,~] = mrgios(this.Systems{ii}.Model);
                    NInputs = max(NInputs,length(nu));
                end
            end
        end
        function NOutputs = get.NOutputs(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            if isempty(this.Systems)
                NOutputs = 1;
            else
                NOutputs = 0;
                for ii = 1:length(this.Systems)
                    [~,ny] = mrgios(this.Systems{ii}.Model);
                    NOutputs = max(NOutputs,length(ny));
                end
            end
        end
        function show(this)
            show@controllib.ui.internal.dialog.AbstractDialog(this);
            this.UIFigure.UserData = this;
        end
    end

    %% Public
    methods
        function addSystem(this,system)
            arguments
                this (1,1) viewgui.ltiviewer
                system DynamicSystem
            end
            this.Systems{end+1} = controllib.chart.internal.utils.ModelSource(system);
            style = getStyle(this.StyleManager,length(this.Systems));
            for ii = 1:length(this.Plots)
                addResponse(this,this.Systems{end},this.Plots{ii});
                this.Plots{ii}.Responses(end).Style = style;
            end
            this.Preferences.HasSparseModels = any(cellfun(@(x) issparse(x.Model),this.Systems));
            this.LegendLines = [this.LegendLines;matlab.graphics.chart.primitive.Line(Parent=[],...
                DisplayName=strrep(system.Name,'_','\_'),Color=style.Color,LineStyle=style.LineStyle,Marker=style.MarkerStyle)];
            if ~isempty(this.Legend)
                this.Legend.PlotChildren = this.LegendLines;
            end
        end

        function applyStyleManager(this,styleManager,colorOrder)
            arguments
                this (1,1) viewgui.ltiviewer
                styleManager (1,1) controllib.chart.internal.options.ResponseStyleManager
                colorOrder (:,1) double {mustBePositive,mustBeInteger}
            end
            this.StyleManager = styleManager;
            this.ColorOrder = colorOrder;
            for ii = 1:length(this.Systems)
                style = getStyle(this.StyleManager,ii);
                for jj = 1:length(this.Plots)
                    this.Plots{jj}.Responses(ii).Style = style;
                end
                styleValue = getValue(style,OutputIndex=1,InputIndex=1,ArrayIndex=1);
                set(this.LegendLines(ii),Color=styleValue.Color,LineStyle=styleValue.LineStyle,Marker=styleValue.MarkerStyle);
            end
        end

        function close(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            % Delete dialogs
            if ~isempty(this.Preferences) && isvalid(this.Preferences)
                delete(this.Preferences);
            end
            if ~isempty(this.StartupDialog) && isvalid(this.StartupDialog)
                delete(this.StartupDialog);
            end
            if ~isempty(this.ConfigDialog) && isvalid(this.ConfigDialog)
                delete(this.ConfigDialog);
            end
            if ~isempty(this.StyleDialog) && isvalid(this.StyleDialog)
                delete(this.StyleDialog);
            end
            if ~isempty(this.ImportDialog) && isvalid(this.ImportDialog)
                delete(this.ImportDialog);
            end
            if ~isempty(this.ExportDialog) && isvalid(this.ExportDialog)
                delete(this.ExportDialog);
            end
            if ~isempty(this.DeleteDialog) && isvalid(this.DeleteDialog)
                delete(this.DeleteDialog);
            end
            close@controllib.ui.internal.dialog.AbstractDialog(this);
        end
        
        function importSystems(this,systems,override)
            arguments
                this (1,1) viewgui.ltiviewer
                systems (:,1) cell
                override (1,1) logical = true
            end
            if isempty(systems)
                return;
            end
            if isempty(this.Systems) || ~override
                iNew = 1:length(systems);
            else
                currentNames = cellfun(@(x) string(x.Model.Name),this.Systems);
                newNames = cellfun(@(x) string(x.Name),systems);
                [~,ia,ib] = intersect(currentNames,newNames);
                for ii = 1:length(systems(ib))
                    this.Systems{ia(ii)}.Model = systems{ib(ii)};
                end
                iNew = setdiff(1:length(systems),ib);
            end
            for ii = 1:length(systems(iNew))
                addSystem(this,systems{iNew(ii)});
            end
            checkForSystemWarnings(this);
        end

        function openStartupDialog(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            if isempty(this.StartupDialog) || ~isvalid(this.StartupDialog)
                this.StartupDialog = viewgui.internal.StartupDialog(this);
                show(this.StartupDialog,this.UIFigure);
            else
                show(this.StartupDialog);
            end
        end

        function refreshSystems(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            % Refresh systems in LTI Viewer
            postStatus(this,getString(message('Control:viewer:msgRefreshingSystems')));
            set(this.UIFigure,'Pointer','watch');

            %---Check status of systems vs workspace
            allVariableNames = string(evalin('base','who'));
            allVariableValues = arrayfun(@(x) evalin('base',x),allVariableNames,'UniformOutput',false);
            if ~isempty(allVariableValues)
                valid = false(length(allVariableValues),1);
                for ii = 1:length(allVariableValues)
                    var = allVariableValues{ii};
                    if isa(var,'DynamicSystem') && ~isa(var,'lpvss')
                        valid(ii) = true;
                    end
                end
                allVariableNames = allVariableNames(valid);
                allVariableValues = allVariableValues(valid);
            end
            NewValues = cell(size(this.Systems));
            Status = ones(size(this.Systems));
            for ii = 1:length(this.Systems)
                ind = find(this.Systems{ii}.Model.Name==allVariableNames,1);
                if isempty(ind)
                    % Sys no longer exists
                    Status(ii) = 0;
                else
                    NewValues(ii) = allVariableValues(ind);
                    NewValues{ii}.Name = this.Systems{ii}.Model.Name;
                end
            end
            SystemNames = cellfun(@(x) string(x.Model.Name),this.Systems);

            % Skip systems that are no longer in the workspace
            IdxUndef = find(Status==0);
            if ~isempty(IdxUndef)
                Msg = [getString(message('Control:viewer:msgSystemsNoLongerInWorkspace')) newline];
                for ii = 1:length(IdxUndef)
                    Msg = [Msg '-' char(SystemNames(IdxUndef(ii))) newline]; %#ok<AGROW>
                end
                Msg = Msg(1:end-1);
                uialert(this.UIFigure,Msg,getString(message('Control:viewer:strLTIViewerWarning')),...
                    'Icon','warning');
            end            
            NewValues(Status==0) = [];

            % Update viewer
            if ~isempty(NewValues)
                importSystems(this,NewValues);
            end
            postStatus(this,getString(message('Control:viewer:msgAllSystemsInWorkspaceUpdated')));
            set(this.UIFigure,'Pointer','arrow')
        end

        function removeSystem(this,idx)
            arguments
                this (1,1) viewgui.ltiviewer
                idx (1,1) double {mustBeInteger,mustBePositive}
            end
            mustBeInRange(idx,1,length(this.Systems));
            for ii = 1:length(this.Plots)
                delete(this.Plots{ii}.Responses(idx));
            end
            this.Systems(idx) = [];
            this.LegendLines(idx) = [];
            if ~isempty(this.Legend)
                this.Legend.PlotChildren = this.LegendLines;
            end
            this.Preferences.HasSparseModels = any(cellfun(@(x) issparse(x.Model),this.Systems));
            applyStyleManager(this,this.StyleManager,this.ColorOrder);
        end

        function postStatus(this,status)
            arguments
                this (1,1) viewgui.ltiviewer
                status (1,1) string
            end
            this.StatusText.Text = status;
        end

        function createSinglePlot(this,plotType,responses,modelSources)
            arguments
                this (1,1) viewgui.ltiviewer
                plotType (1,1) string
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
                modelSources (:,1) cell
            end
            tileLocation = this.AvailableLayouts(1).TileLocation;
            tileSpan = this.AvailableLayouts(1).TileSpan;
            IsBodeMag = plotType=="bodemag";
            if IsBodeMag
                plotType = "bode";
            end
            this.Systems = modelSources;
            this.Plots{1} = createNewPlot(this,plotType,tileLocation,tileSpan);
            for ii = 1:length(responses)
                style = getStyle(this.StyleManager,ii);
                this.LegendLines = [this.LegendLines;matlab.graphics.chart.primitive.Line(Parent=[],...
                    DisplayName=strrep(responses(ii).Name,'_','\_'),Color=style.Color,LineStyle=style.LineStyle,Marker=style.MarkerStyle)];
                responses(ii).Style = style;
                registerResponse(this.Plots{1},responses(ii));
            end
            this.Plots{1}.Visible = "on";
            if IsBodeMag
                this.Plots{1}.PhaseVisible = false;
            end
            addPlotContextMenu(this,1);
            if ~isempty(this.Legend)
                this.Legend.PlotChildren = this.LegendLines;
            end
            this.Preferences.HasSparseModels = any(cellfun(@(x) issparse(x.Model),this.Systems));
        end

        function setCurrentPlots(this,NewPlotList)
            arguments
                this (1,1) viewgui.ltiviewer
                NewPlotList (:,1) string {mustBeNonempty}
            end
            % Adjust existing plot layout
            nNewPlots = length(NewPlotList);
            for ii = nNewPlots+1:length(this.Plots)
                delete(this.Plots{end});
                this.Plots = this.Plots(1:end-1);
            end
            lgdState = ~isempty(this.Legend);
            showLegend(this,false);
            tileLocations = this.AvailableLayouts(nNewPlots).TileLocation;
            tileSpans = this.AvailableLayouts(nNewPlots).TileSpan;
            for ii = 1:length(this.Plots)
                this.Plots{ii}.Layout.Tile = tileLocations(ii);
                this.Plots{ii}.Layout.TileSpan = tileSpans(ii,:);
            end
            for ct=1:nNewPlots
                if ct <= length(this.Plots) && ~strcmp(this.Plots{ct}.Type,NewPlotList(ct))
                    % Switch plot type of existing plot
                    changePlotType(this,ct,NewPlotList(ct));
                elseif ct > length(this.Plots)
                    % Add additional plots
                    IsBodeMag = NewPlotList(ct)=="bodemag";
                    if IsBodeMag
                        NewPlotList(ct) = "bode";
                    end
                    this.Plots{ct} = createNewPlot(this,NewPlotList(ct),tileLocations(ct),tileSpans(ct,:));
                    for ii = 1:length(this.Systems)
                        addResponse(this,this.Systems{ii},this.Plots{ct});
                        this.Plots{ct}.Responses(ii).Style = getStyle(this.StyleManager,ii);
                    end
                    this.Plots{ct}.Visible = "on";
                    if IsBodeMag
                        this.Plots{ct}.PhaseVisible = false;
                    end
                    addPlotContextMenu(this,ct);
                end
            end
            showLegend(this,lgdState);
            checkForSystemWarnings(this);
        end

        function setStyle(this,systemInd,style)
            arguments
                this (1,1) viewgui.ltiviewer
                systemInd (1,1) double {mustBePositive,mustBeInteger}
                style (:,1) char
            end
            % Parse line specification string
            [lineStyle,color,markerStyle,msg] = colstyle(style);
            if isempty(lineStyle) && ~isempty(markerStyle)
                lineStyle = 'none';
            end
            % Throw error if needed
            if ~isempty(msg)
                error(message('Controllib:plots:PlotStyleString',style));
            end
            for ii = 1:length(this.Plots)
                if ~isempty(lineStyle) && isprop(this.Plots{ii}.Responses(systemInd),'LineStyle')
                    this.Plots{ii}.Responses(systemInd).LineStyle = lineStyle;
                end
                if ~isempty(color) && isprop(this.Plots{ii}.Responses(systemInd),'Color')
                    this.Plots{ii}.Responses(systemInd).Color = color;
                end
                if ~isempty(markerStyle) && isprop(this.Plots{ii}.Responses(systemInd),'MarkerStyle')
                    this.Plots{ii}.Responses(systemInd).MarkerStyle = markerStyle;
                end
            end
            if ~isempty(lineStyle)
                this.LegendLines(systemInd).LineStyle = lineStyle;
            end
            if ~isempty(color)
                this.LegendLines(systemInd).Color = color;
            end
            if ~isempty(markerStyle)
                this.LegendLines(systemInd).Marker = markerStyle;
            end
        end
    end
    %% Protected
    methods (Access=protected)
        function addResponse(this,modelSource,hPlot)
            arguments
                this (1,1) viewgui.ltiviewer
                modelSource (1,1) controllib.chart.internal.utils.ModelSource
                hPlot (1,1) controllib.chart.internal.foundation.AbstractPlot
            end
            switch hPlot.Type
                case {"step","impulse","initial"}
                    if isempty(hPlot.Responses)
                        time = this.Preferences.TimeVector*tunitconv(this.Preferences.TimeVectorUnits,modelSource.Model.TimeUnit);
                    else
                        time = hPlot.Responses(end).SourceData.TimeSpec*tunitconv(hPlot.Responses(end).TimeUnit,modelSource.Model.TimeUnit);
                    end
                case {"lsim"}
                    if isempty(hPlot.Responses)
                        time = this.Preferences.TimeVector*tunitconv(this.Preferences.TimeVectorUnits,modelSource.Model.TimeUnit);
                    else
                        time = hPlot.Responses(end).SourceData.Time*tunitconv(hPlot.Responses(end).TimeUnit,modelSource.Model.TimeUnit);
                    end
                case {"bode","nyquist","nichols"}
                    timeUnit = modelSource.Model.TimeUnit;
                    if strcmpi(timeUnit,"seconds")
                        timeUnit = 's';
                    end
                    freqUnit = ['rad/' timeUnit];
                    if isempty(hPlot.Responses)
                        if iscell(this.Preferences.FrequencyVector)
                            cf = funitconv(this.Preferences.FrequencyVectorUnits,freqUnit);
                            frequency = {cf*this.Preferences.FrequencyVector{1} cf*this.Preferences.FrequencyVector{2}};
                        else
                            frequency = this.Preferences.FrequencyVector*funitconv(this.Preferences.FrequencyVectorUnits,freqUnit);
                        end
                    else
                        if iscell(hPlot.Responses(end).SourceData.FrequencySpec)
                            cf = funitconv(hPlot.Responses(end).FrequencyUnit,freqUnit);
                            frequency = {cf*hPlot.Responses(end).SourceData.FrequencySpec{1} cf*hPlot.Responses(end).SourceData.FrequencySpec{2}}; 
                        else
                            frequency = hPlot.Responses(end).SourceData.FrequencySpec*funitconv(hPlot.Responses(end).FrequencyUnit,freqUnit);
                        end
                    end
                case "sigma"
                    timeUnit = modelSource.Model.TimeUnit;
                    if strcmpi(timeUnit,"seconds")
                        timeUnit = 's';
                    end
                    freqUnit = ['rad/' timeUnit];
                    if isempty(hPlot.Responses)
                        if iscell(this.Preferences.FrequencyVector)
                            cf = funitconv(this.Preferences.FrequencyVectorUnits,freqUnit);
                            frequency = {cf*this.Preferences.FrequencyVector{1} cf*this.Preferences.FrequencyVector{2}};
                        else
                            frequency = this.Preferences.FrequencyVector*funitconv(this.Preferences.FrequencyVectorUnits,freqUnit);
                        end
                        type = 0;
                    else
                        if iscell(hPlot.Responses(end).SourceData.FrequencySpec)
                            cf = funitconv(hPlot.Responses(end).FrequencyUnit,freqUnit);
                            frequency = {cf*hPlot.Responses(end).SourceData.FrequencySpec{1} cf*hPlot.Responses(end).SourceData.FrequencySpec{2}}; 
                        else
                            frequency = hPlot.Responses(end).SourceData.FrequencySpec*funitconv(hPlot.Responses(end).FrequencyUnit,freqUnit);
                        end
                        type = hPlot.Responses(end).SourceData.SingularValueType;
                    end
            end
            switch hPlot.Type
                case "step"
                    response = controllib.chart.response.StepResponse(modelSource,Name=modelSource.Model.Name,Time=time);
                case "impulse"
                    response = controllib.chart.response.ImpulseResponse(modelSource,Name=modelSource.Model.Name,Time=time);
                case "initial"
                    try
                        sz = order(modelSource.Model(:,:,1));
                    catch
                        sz = 1;
                    end
                    config = RespConfig(InitialState=zeros(sz,1));
                    response = controllib.chart.response.InitialResponse(modelSource,Name=modelSource.Model.Name,Time=time,Config=config);
                case "lsim"
                    try
                        sz = order(modelSource.Model(:,:,1));
                    catch
                        sz = 1;
                    end
                    config = RespConfig(InitialState=zeros(sz,1));
                    response = controllib.chart.response.LinearSimulationResponse(modelSource,Name=modelSource.Model.Name,Time=time,Config=config);
                case "bode"
                    response = controllib.chart.response.BodeResponse(modelSource,Name=modelSource.Model.Name,Frequency=frequency);
                case "nyquist"
                    response = controllib.chart.response.NyquistResponse(modelSource,Name=modelSource.Model.Name,Frequency=frequency);
                case "nichols"
                    response = controllib.chart.response.NicholsResponse(modelSource,Name=modelSource.Model.Name,Frequency=frequency);
                case "sigma"
                    response = controllib.chart.response.SigmaResponse(modelSource,Name=modelSource.Model.Name,Frequency=frequency,SingularValueType=type);
                case "pzmap"
                    response = controllib.chart.response.PZResponse(modelSource,Name=modelSource.Model.Name);
                case "iopzmap"
                    response = controllib.chart.response.IOPZResponse(modelSource,Name=modelSource.Model.Name);
            end
            registerResponse(hPlot,response);
        end
        function buildUI(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            this.FigureGrid = uigridlayout(this.UIFigure,[2 1]);
            this.FigureGrid.RowHeight = {'1x','fit'};
            this.PlotPanel = uipanel(this.FigureGrid);
            this.PlotPanel.BorderType = "none";
            this.PlotPanel.Layout.Row = 1;
            this.PlotLayout = tiledlayout(this.PlotPanel,6,6,"Padding","tight");
            this.StatusText = uilabel(this.FigureGrid,"Text",getString(message('Controllib:gui:strLTIViewer')));
            this.StatusText.Layout.Row = 2;

            %% Create toolbar
            Path = fullfile(matlabroot, 'toolbox', 'control', ...
                'ctrlguis', '+viewgui', 'resources');
            toolbar = uitoolbar(this.UIFigure,'HandleVisibility','off');
            % Create menu bar icons and associated callbacks.
            b(1) = uipushtool(toolbar);
            b(1).Tooltip = getString(message('Control:viewer:strNewViewer'));
            b(1).ClickedCallback = @(es,ed) linearSystemAnalyzer();
            b(1).Icon = fullfile(Path,'newFigure.png');
            b(2) = uipushtool(toolbar);
            b(2).Tooltip = getString(message('Control:viewer:strPrint'));
            b(2).ClickedCallback = @(es,ed) print(this);
            b(2).Icon = fullfile(Path,'printFigure.png');

            b(3) = uitoggletool(toolbar);
            b(3).Tooltip = getString(message('Control:viewer:strLegend'));
            b(3).Icon = fullfile(Path,'legend.png');
            b(3).OnCallback = @(es,ed) showLegend(this,true);
            b(3).OffCallback = @(es,ed) showLegend(this,false);
            set(b(3),'Separator','on');

            this.Toolbar = toolbar;
            
            %% Add toolbar menus
            this.FigureMenu = createFigureMenus(this);

            this.UIFigure.Position(3:4) = [560 420];
        end
        function cbFigureThemeChanged(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            plt = this.Plots{1};
            ax = getChartAxes(plt);
            order = mat2cell(ax(1).ColorOrder,ones(1,size(ax(1).ColorOrder,1)),3);
            this.StyleManager.ColorOrder = order(this.ColorOrder);
            applyStyleManager(this,this.StyleManager,this.ColorOrder);            
        end
        function changePlotType(this,ct,plotType)
            arguments
                this (1,1) viewgui.ltiviewer
                ct (1,1) double {mustBePositive,mustBeInteger}
                plotType (1,1) string
            end
            IsBodeMag = plotType=="bodemag";
            if IsBodeMag
                plotType = "bode";
            end
            responseVisibilties = arrayfun(@(x) x.Visible,this.Plots{ct}.Responses);
            layout = this.Plots{ct}.Layout;
            delete(this.Plots{ct});
            this.Plots{ct} = createNewPlot(this,plotType,layout.Tile,layout.TileSpan);
            for ii = 1:length(this.Systems)
                addResponse(this,this.Systems{ii},this.Plots{ct});
                this.Plots{ct}.Responses(ii).Visible = responseVisibilties(ii);
                this.Plots{ct}.Responses(ii).Style = getStyle(this.StyleManager,ii);
            end
            this.Plots{ct}.Visible = "on";
            if IsBodeMag
                this.Plots{ct}.PhaseVisible = false;
            end
            addPlotContextMenu(this,ct);
            checkForSystemWarnings(this);
        end
        function checkForSystemWarnings(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            % Ensure plots are updated
            for ii = 1:length(this.Plots)
                qeUpdate(this.Plots{ii});
            end
            % Throw warnings if responses are invalid
            Messages = strings(length(this.Plots),length(this.Systems));
            Exceptions = strings(length(this.Plots),length(this.Systems));
            needsSparseInput = false;
            for ii = 1:length(this.Plots)
                for jj = 1:length(this.Plots{ii}.Responses)
                    if ~isempty(this.Plots{ii}.Responses(jj).DataException)                        
                        Messages(ii,jj) = getString(message('Control:viewer:warnSystemsCannotBeShownReason',this.Plots{ii}.Title.String,this.Plots{ii}.Responses(jj).Name));
                        Exceptions(ii,jj) = this.Plots{ii}.Responses(jj).DataException.message;
                        needsSparseInput = needsSparseInput || (issparse(this.Plots{ii}.Responses(jj).Model) &&...
                            this.Plots{ii}.Type ~= "pzmap" && this.Plots{ii}.Type ~= "iopzmap" && this.Plots{ii}.Type ~= "lsim");
                    end
                end
            end
            Messages = Messages(Exceptions~="");
            Exceptions = Exceptions(Exceptions~="");
            if ~isempty(Messages)
                WarnHeader = getString(message('Control:viewer:warnSystemsCannotBeShown'));
                Msg = [];
                for ii = 1:numel(Messages)
                    Msg = [Msg char(Messages(ii)) newline char(Exceptions(ii)) newline newline]; %#ok<AGROW>
                end
                Msg = Msg(1:end-2);
                uialert(this.UIFigure,Msg,WarnHeader,'Icon','Warning');
            end
            if needsSparseInput
                edit(this.Preferences);
                selectTab(this.Preferences,'Parameters');
            end
        end
        function connectUI(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            L1 = addlistener(this.UIFigure,'ObjectBeingDestroyed',@(es,ed) delete(this));
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) close(this)); 
            registerUIListeners(this,L2);
            L3 = addlistener(this.UIFigure,"ThemeChanged",@(es,ed) cbFigureThemeChanged(this));
            registerUIListeners(this,L3);
            %% Preferences
            prefs = this.Preferences;
            prefProps = ["MagnitudeUnits";"FrequencyScale";"MagnitudeScale";...
                "PhaseUnits";"Grid";"TitleFontSize";"TitleFontWeight";...
                "TitleFontAngle";"XYLabelsFontSize";"XYLabelsFontWeight";...
                "XYLabelsFontAngle";"AxesFontSize";"AxesFontWeight";...
                "AxesFontAngle";"IOLabelsFontSize";"IOLabelsFontWeight";...
                "IOLabelsFontAngle";"AxesForegroundColor";"SettlingTimeThreshold";
                "RiseTimeLimits";"UnwrapPhase";"MinGainLimit";"PhaseWrappingBranch";...
                "TimeUnits";"FrequencyUnits"];
            for ii = 1:length(prefProps)
                pref = prefProps(ii);
                prefListenerName = pref+"ChangedListener";
                L = addlistener(prefs,pref,"PostSet", @(es,ed) applyPreference(this,ed,pref));
                registerDataListeners(this,L,prefListenerName);
            end
            timeProps = ["TimeVector";"TimeVectorUnits"];
            for ii =  1:length(timeProps)
                pref = timeProps(ii);
                prefListenerName = pref+"ChangedListener";
                L = addlistener(prefs,pref,"PostSet", @(es,ed) applyTimeVector(this,ed));
                registerDataListeners(this,L,prefListenerName);
            end
            freqProps = ["FrequencyVector";"FrequencyVectorUnits"];
            for ii =  1:length(freqProps)
                pref = freqProps(ii);
                prefListenerName = pref+"ChangedListener";
                L = addlistener(prefs,pref,"PostSet", @(es,ed) applyFreqVector(this,ed));
                registerDataListeners(this,L,prefListenerName);
            end
            function applyPreference(this,ed,pref)
                for jj = 1:length(this.Plots)
                    opts = getoptions(this.Plots{jj});
                    switch pref
                        case "MagnitudeUnits"
                            if isprop(opts,"MagUnits")
                                opts.MagUnits = ed.AffectedObject.(pref);
                            end
                        case "MagnitudeScale"
                            if isprop(opts,"MagScale")
                                opts.MagScale = ed.AffectedObject.(pref);
                            end
                        case "FrequencyUnits"
                            if isprop(opts,"FreqUnits")
                                opts.FreqUnits = ed.AffectedObject.(pref);
                            end
                        case "FrequencyScale"
                            if isprop(opts,"FreqScale")
                                opts.FreqScale = ed.AffectedObject.(pref);
                            end
                        case "PhaseUnits"
                            if isprop(opts,"PhaseUnits")
                                opts.PhaseUnits = ed.AffectedObject.(pref);
                            end
                        case "TimeUnits"
                            if isprop(opts,"TimeUnits")
                                opts.TimeUnits = ed.AffectedObject.(pref);
                            end
                        case "Grid"
                            opts.Grid = ed.AffectedObject.(pref);
                        case "TitleFontSize"
                            opts.Title.FontSize = ed.AffectedObject.(pref);
                        case "TitleFontWeight"
                            opts.Title.FontWeight = ed.AffectedObject.(pref);
                        case "TitleFontAngle"
                            opts.Title.FontAngle = ed.AffectedObject.(pref);
                        case "XYLabelsFontSize"
                            opts.XLabel.FontSize = ed.AffectedObject.(pref);
                            opts.YLabel.FontSize = ed.AffectedObject.(pref);
                        case "XYLabelsFontWeight"
                            opts.XLabel.FontWeight = ed.AffectedObject.(pref);
                            opts.YLabel.FontWeight = ed.AffectedObject.(pref);
                        case "XYLabelsFontAngle"
                            opts.XLabel.FontAngle = ed.AffectedObject.(pref);
                            opts.YLabel.FontAngle = ed.AffectedObject.(pref);
                        case "AxesFontSize"
                            opts.TickLabel.FontSize = ed.AffectedObject.(pref);
                        case "AxesFontWeight"
                            opts.TickLabel.FontWeight = ed.AffectedObject.(pref);
                        case "AxesFontAngle"
                            opts.TickLabel.FontAngle = ed.AffectedObject.(pref);
                        case "IOLabelsFontSize"
                            opts.InputLabels.FontSize = ed.AffectedObject.(pref);
                            opts.OutputLabels.FontSize = ed.AffectedObject.(pref);
                        case "IOLabelsFontWeight"
                            opts.InputLabels.FontWeight = ed.AffectedObject.(pref);
                            opts.OutputLabels.FontWeight = ed.AffectedObject.(pref);
                        case "IOLabelsFontAngle"
                            opts.InputLabels.FontAngle = ed.AffectedObject.(pref);
                            opts.OutputLabels.FontAngle = ed.AffectedObject.(pref);
                        case "AxesForegroundColor"
                            opts.TickLabel.Color = ed.AffectedObject.(pref);
                        case "SettlingTimeThreshold"
                            if isprop(opts,"SettleTimeThreshold")
                                opts.SettleTimeThreshold = ed.AffectedObject.(pref);
                            end
                        case "RiseTimeLimits"
                            if isprop(opts,"RiseTimeLimits")
                                opts.RiseTimeLimits = ed.AffectedObject.(pref);
                            end
                        case "UnwrapPhase"
                            if isprop(opts,"PhaseWrapping")
                                opts.PhaseWrapping = char(~matlab.lang.OnOffSwitchState(ed.AffectedObject.(pref)));
                            end
                        case "MinGainLimit"
                            if isprop(opts,"MagLowerLim")
                                if ed.AffectedObject.(pref).Enable
                                    mode = 'manual';
                                else
                                    mode = 'auto';
                                end
                                opts.MagLowerLimMode = mode;
                                opts.MagLowerLim = ed.AffectedObject.(pref).MinGain;
                            end
                        case "PhaseWrappingBranch"
                            if isprop(opts,"PhaseWrappingBranch")
                                opts.PhaseWrappingBranch = ed.AffectedObject.(pref);
                            end
                    end
                    setoptions(this.Plots{jj},opts);
                end
            end
            function applyTimeVector(this,ed)
                time = ed.AffectedObject.TimeVector;
                timeUnits = ed.AffectedObject.TimeVectorUnits;
                for jj = 1:length(this.Plots)
                    hPlot = this.Plots{jj};
                    switch hPlot.Type
                        case {"step","impulse","initial"}
                            for kk = 1:length(hPlot.Responses)
                                hPlot.Responses(kk).SourceData.TimeSpec = time*tunitconv(timeUnits,hPlot.Responses(kk).TimeUnit);
                            end
                    end
                end
                checkForSystemWarnings(this);
            end
            function applyFreqVector(this,ed)
                f = ed.AffectedObject.FrequencyVector;
                freqUnits = ed.AffectedObject.FrequencyVectorUnits;
                for jj = 1:length(this.Plots)
                    hPlot = this.Plots{jj};
                    switch hPlot.Type
                        case {"bode","nichols","nyquist","sigma"}
                            for kk = 1:length(hPlot.Responses)
                                if iscell(f)
                                    w1 = f{1}*funitconv(freqUnits,hPlot.Responses(kk).FrequencyUnit);
                                    w2 = f{2}*funitconv(freqUnits,hPlot.Responses(kk).FrequencyUnit);
                                    f = {w1 w2};
                                else
                                    f = f*funitconv(freqUnits,hPlot.Responses(kk).FrequencyUnit);
                                end
                                hPlot.Responses(kk).SourceData.FrequencySpec = f;
                            end
                    end
                end
                checkForSystemWarnings(this);
            end
        end

        function print(this)
            arguments
                this (1,1) viewgui.ltiviewer
            end
            %---Print to paper

            % if paperposition mode is manual create hidden figure to print from
            % to prevent viewer from resizing to actual print size during printing
            if strcmpi(this.UIFigure.PaperPositionMode,'manual')
                tempFig = printToFigure(this);
                tempFig.PaperType = this.UIFigure.PaperType;
                tempFig.PaperUnits = this.UIFigure.PaperUnits;
                tempFig.PaperPosition = this.UIFigure.PaperPosition;
                tempFig.PaperPositionMode = this.UIFigure.PaperPositionMode;
                tempFig.PaperOrientation = this.UIFigure.PaperOrientation;
                tempFig.PrintTemplate = this.UIFigure.PrintTemplate;
                tempFig.InvertHardcopy = this.UIFigure.InvertHardcopy;
                if matlab.ui.internal.isUIFigure(tempFig)
                    uiprintdlg(tempFig);
                else
                    printdlg(tempFig);
                end
                delete(tempFig);
            else
                this.UIFigure.PaperPositionMode='auto';
                tempFig = printToFigure(this);
                if matlab.ui.internal.isUIFigure(tempFig)
                    uiprintdlg(tempFig);
                else
                    printdlg(tempFig);
                end
                delete(tempFig);
            end
        end

        function newFig = printToFigure(this)
            %----Print to figure
            %---New figure
            newFig = figure(Visible='off',...
                Name=getString(message('Control:viewer:strLTIViewerResponses')),...
                Units=this.UIFigure.Units,...
                Position=this.UIFigure.Position);
            centerfig(newFig);
            t = copyobj(this.PlotLayout,newFig);
            t.Padding = get(groot,'DefaultTiledLayoutPadding'); % reset padding

            if ~isempty(this.Legend) && isvalid(this.Legend)
                % Remove legend & legend axes - fails to copy plot
                % children
                isChart = false(size(t.Children));
                for ii = 1:length(t.Children)
                    isChart(ii) = isa(t.Children(ii),'controllib.chart.internal.foundation.AbstractPlot');
                end
                delete(t.Children(~isChart));
                % Add back legend
                t.Children(end).Layout.TileSpan(2) = t.Children(end).Layout.TileSpan(2)-1;
                ax = nexttile(t);
                ax.Visible = false;
                lgd = legend(ax,Orientation="horizontal",NumColumns=4,AutoUpdate="off");
                lgd.PlotChildren = this.LegendLines;
                lgd.Layout.Tile = 'south';
                t.Children(end).Layout.TileSpan(2) = t.Children(end).Layout.TileSpan(2)+1;
            end

            if nargout == 0
                newFig.Visible = 'on';
            end
        end

        function showLegend(this,state)
            arguments
                this (1,1) viewgui.ltiviewer
                state (1,1) matlab.lang.OnOffSwitchState
            end
            if state
                delete(this.Legend);
                delete(this.LegendAxes);
                this.Plots{end}.Layout.TileSpan(2) = this.Plots{end}.Layout.TileSpan(2)-1;
                this.LegendAxes = nexttile(this.PlotLayout);
                this.LegendAxes.Visible = false;
                this.Legend = legend(this.LegendAxes,Orientation="horizontal",NumColumns=4,AutoUpdate="off");
                this.Legend.PlotChildren = this.LegendLines;
                this.Legend.Layout.Tile = 'south';
                this.Plots{end}.Layout.TileSpan(2) = this.Plots{end}.Layout.TileSpan(2)+1;
            else
                delete(this.Legend);
                delete(this.LegendAxes);
            end
        end
    end

    %% Private methods
    methods (Access=private)
        function addPlotContextMenu(this,ct)
            hPlot = this.Plots{ct};
            ContextMenu = qeGetContextMenu(hPlot);
            plotTypeMenu = uimenu(ContextMenu,...
                Text=getString(message('Control:viewer:strPlotTypes')),...
                Tag="plottype");
            ContextMenu.Children = ContextMenu.Children([2:end 1]);
            for ii = 1:length(this.AvailablePlots.Alias)
                if this.Plots{ct}.Type == "bode"
                    if strcmp(this.Plots{ct}.PhaseVisible,'on')
                        checked = strcmp("bode",this.AvailablePlots.Alias(ii));
                    else
                        checked = strcmp("bodemag",this.AvailablePlots.Alias(ii));
                    end
                else
                    checked = strcmp(this.Plots{ct}.Type,this.AvailablePlots.Alias(ii));
                end
                uimenu(plotTypeMenu,...
                    Text=this.AvailablePlots.Name(ii),...
                    Tag=this.AvailablePlots.Alias(ii),...
                    Checked=checked,...
                    MenuSelectedFcn=@(es,ed) cbChangePlotType(this,es,ct,this.AvailablePlots.Alias(ii)));
            end
            function cbChangePlotType(this,es,ct,plottype)
                if this.Plots{ct}.Type == "bode" && plottype == "bode"
                    setoptions(this.Plots{ct},'PhaseVisible','on')
                    typeMenu = es.Parent;
                    bodeMenu = typeMenu.Children(arrayfun(@(x) strcmp(x.Tag,"bode"), typeMenu.Children));
                    bodeMenu.Checked = true;
                    bodeMagMenu = typeMenu.Children(arrayfun(@(x) strcmp(x.Tag,"bodemag"), typeMenu.Children));
                    bodeMagMenu.Checked = false;
                    return;
                elseif this.Plots{ct}.Type == "bode" && plottype == "bodemag"
                    setoptions(this.Plots{ct},'PhaseVisible','off')
                    typeMenu = es.Parent;
                    bodeMenu = typeMenu.Children(arrayfun(@(x) strcmp(x.Tag,"bode"), typeMenu.Children));
                    bodeMenu.Checked = false;
                    bodeMagMenu = typeMenu.Children(arrayfun(@(x) strcmp(x.Tag,"bodemag"), typeMenu.Children));
                    bodeMagMenu.Checked = true;
                    return;
                end
                if ~strcmp(this.Plots{ct}.Type,plottype)
                    changePlotType(this,ct,plottype);
                    postStatus(this,getString(message('Control:viewer:msgPlotTypeChanged')));
                end
            end
        end
        function FigureMenu = createFigureMenus(this)
            % Create customized menus for the figure.
            %% File Menu
            FigureMenu.FileMenu.Main = uimenu(this.UIFigure, ...
                'Label',getString(message('Control:viewer:menuFile')), ...
                'HandleVisibility','off','Tag','LTIViewer_File');
            FigureMenu.FileMenu.NewViewer = uimenu(FigureMenu.FileMenu.Main,...
                'Label',getString(message('Control:viewer:menuNewViewer')), ...
                'Accelerator','N','Tag','LTIViewer_NewViewer');
            FigureMenu.FileMenu.NewViewer.MenuSelectedFcn = @(es,ed) linearSystemAnalyzer();
            FigureMenu.FileMenu.Import = uimenu(FigureMenu.FileMenu.Main,'Separator','on',...
                'Label',getString(message('Control:viewer:menuImportEllipsis')), ...
                'Tag','LTIViewer_Import');
            FigureMenu.FileMenu.Import.MenuSelectedFcn = @(es,ed) openImportDialog(this);
            FigureMenu.FileMenu.Export = uimenu(FigureMenu.FileMenu.Main,...
                'Label',getString(message('Control:viewer:menuExportEllipsis')), ...
                'Tag','LTIViewer_Export');
            FigureMenu.FileMenu.Export.MenuSelectedFcn = @(es,ed) openExportDialog(this);
            FigureMenu.FileMenu.ToolboxPreferences = uimenu(FigureMenu.FileMenu.Main,'Separator','on',...
                'Label',getString(message('Control:viewer:menuToolboxPreferencesEllipsis')),...
                'Tag','LTIViewer_ToolboxPreferences');
            FigureMenu.FileMenu.ToolboxPreferences.MenuSelectedFcn = @(es,ed) ctrlpref();
            FigureMenu.FileMenu.Print = uimenu(FigureMenu.FileMenu.Main,...
                'Label',getString(message('Control:viewer:menuPrintEllipsis')),...
                'Accelerator','P','Tag','LTIViewer_Print');
            FigureMenu.FileMenu.Print.MenuSelectedFcn = @(es,ed) print(this);
            FigureMenu.FileMenu.PrintToFigure = uimenu(FigureMenu.FileMenu.Main,...
                'Label',getString(message('Control:viewer:menuPrintToFigure')),...
                'Tag','LTIViewer_PrintToFigure');
            FigureMenu.FileMenu.PrintToFigure.MenuSelectedFcn = @(es,ed) printToFigure(this);
            FigureMenu.FileMenu.Close = uimenu(FigureMenu.FileMenu.Main,'Separator','on',...
                'Label',getString(message('Control:viewer:menuClose')),...
                'Accelerator','W','Tag','LTIViewer_Close');
            FigureMenu.FileMenu.Close.MenuSelectedFcn = @(es,ed) close(this);
            %% Edit Menu
            FigureMenu.EditMenu.Main = uimenu(this.UIFigure,...
                'Label',getString(message('Control:viewer:menuEdit')),...
                'HandleVisibility','off','Tag','LTIViewer_Edit');
            FigureMenu.EditMenu.PlotConfigurations = uimenu(FigureMenu.EditMenu.Main,...
                'Label',getString(message('Control:viewer:menuPlotConfigEllipsis')),...
                'Tag','LTIViewer_PlotConfigurations');
            FigureMenu.EditMenu.PlotConfigurations.MenuSelectedFcn = @(es,ed) openPlotConfigurationDialog(this);
            FigureMenu.EditMenu.RefreshSystems = uimenu(FigureMenu.EditMenu.Main,...
                'Label', getString(message('Control:viewer:menuRefreshSystems')),...
                'Tag','LTIViewer_RefreshSystems');
            FigureMenu.EditMenu.RefreshSystems.MenuSelectedFcn = @(es,ed) refreshSystems(this);
            FigureMenu.EditMenu.DeleteSystems = uimenu(FigureMenu.EditMenu.Main,...
                'Label', getString(message('Control:viewer:menuDeleteSystemsEllipsis')),...
                'Tag','LTIViewer_DeleteSystems');
            FigureMenu.EditMenu.DeleteSystems.MenuSelectedFcn = @(es,ed) openDeleteDialog(this);
            FigureMenu.EditMenu.Styles = uimenu(FigureMenu.EditMenu.Main,'Separator','on',...
                'Label', getString(message('Control:viewer:menuLineStylesEllipsis')), ...
                'Tag','LTIViewer_LineStyles');
            FigureMenu.EditMenu.Styles.MenuSelectedFcn = @(es,ed) openStyleDialog(this);
            FigureMenu.EditMenu.ViewerPreferences = uimenu(FigureMenu.EditMenu.Main,...
                'Label',getString(message('Control:viewer:menuViewerPreferencesEllipsis')), ...
                'Tag','LTIViewer_ViewerPreferences');
            FigureMenu.EditMenu.ViewerPreferences.MenuSelectedFcn = @(es,ed) edit(this.Preferences);
            %% Window Menu
            FigureMenu.WinMenu.Main = uimenu(this.UIFigure,...
                'Label',getString(message('Control:viewer:menuWindow')),...
                'HandleVisibility','off','Tag','winmenu');
            FigureMenu.WinMenu.Main.MenuSelectedFcn = @(es,ed) winmenu(gcbo);
            %% Help Menu
            FigureMenu.HelpMenu.Main = uimenu(this.UIFigure,...
                'Label',getString(message('Control:viewer:menuHelp')),...
                'HandleVis','off','Tag','LTIViewer_Help');
            FigureMenu.HelpMenu.ViewerHelp = uimenu(FigureMenu.HelpMenu.Main,...
                'Label',getString(message('Control:viewer:menuLTIViewerHelp')),...
                'Tag','LTIViewer_ViewerHelp');
            FigureMenu.HelpMenu.ViewerHelp.MenuSelectedFcn = @(es,ed) helpview('control','viewermainhelp');
            FigureMenu.HelpMenu.ToolboxHelp = uimenu(FigureMenu.HelpMenu.Main,...
                'Label',getString(message('Control:viewer:menuControlSystemToolboxHelp')),...
                'Tag','LTIViewer_CSTHelp');
            FigureMenu.HelpMenu.ToolboxHelp.MenuSelectedFcn = @(es,ed) doc('control');
            FigureMenu.HelpMenu.ImportExportHelp = uimenu(FigureMenu.HelpMenu.Main,'Separator','on',...
                'Label',getString(message('Control:viewer:menuImportingExportingModels')),...
                'Tag','LTIViewer_ImportExportHelp');
            FigureMenu.HelpMenu.ImportExportHelp.MenuSelectedFcn = @(es,ed) helpview('control','viewer_importexport');
            FigureMenu.HelpMenu.RespTypeHelp = uimenu(FigureMenu.HelpMenu.Main,...
                'Label',getString(message('Control:viewer:menuSelectingResponseTypes')),...
                'Tag','LTIViewer_SelectResponseTypeHelp');
            FigureMenu.HelpMenu.RespTypeHelp.MenuSelectedFcn = @(es,ed) helpview('control','viewer_responsetypes');
            FigureMenu.HelpMenu.MIMOHelp = uimenu(FigureMenu.HelpMenu.Main,...
                'Label',getString(message('Control:viewer:menuAnalyzingMIMOModels')),...
                'Tag','LTIViewer_AnalyzingMIMOModelsHelp');
            FigureMenu.HelpMenu.MIMOHelp.MenuSelectedFcn = @(es,ed) helpview('control','viewer_mimomodels');
            FigureMenu.HelpMenu.PropPrefHelp = uimenu(FigureMenu.HelpMenu.Main,...
                'Label',getString(message('Control:viewer:menuCustomizingLTIViewer')),...
                'Tag','LTIViewer_CustomizingViewerHelp');
            FigureMenu.HelpMenu.PropPrefHelp.MenuSelectedFcn = @(es,ed) helpview('control','viewer_customizing');
            FigureMenu.HelpMenu.DemosHelp = uimenu(FigureMenu.HelpMenu.Main,'Separator','on',...
                'Label',getString(message('Control:viewer:menuDemos')),...
                'Tag','LTIViewer_Demos');
            FigureMenu.HelpMenu.DemosHelp.MenuSelectedFcn = @(es,ed) demo('toolbox','control');
            FigureMenu.HelpMenu.AboutHelp = uimenu(FigureMenu.HelpMenu.Main,'Separator','on',...
                'Label',getString(message('Control:viewer:menuAboutControlSystemToolbox')),...
                'Tag','LTIViewer_About');
            FigureMenu.HelpMenu.AboutHelp.MenuSelectedFcn = @(es,ed) aboutcst();
            
            %% Local Functions
            function openPlotConfigurationDialog(this)
                if isempty(this.ConfigDialog) || ~isvalid(this.ConfigDialog)
                    this.ConfigDialog = viewgui.internal.ConfigurationDialog(this);
                    show(this.ConfigDialog,this.UIFigure);
                else
                    show(this.ConfigDialog);
                end
                updateUI(this.ConfigDialog);
                postStatus(this,getString(message('Control:viewer:msgChangeNumberAndTypePlot')));
            end
            function openImportDialog(this)
                if isempty(this.ImportDialog) || ~isvalid(this.ImportDialog)
                    this.ImportDialog = viewgui.internal.ImportDialog(this);
                    show(this.ImportDialog,this.UIFigure);
                else
                    show(this.ImportDialog);
                end
                postStatus(this,getString(message('Control:viewer:msgSelectSystemsToImport')));
            end
            function openExportDialog(this)
                if isempty(this.Systems)
                    uialert(this.UIFigure,getString(message('Control:viewer:msgNoSystemsToExport')),...
                        getString(message('Control:viewer:strExprtSystems')),'Icon','error');
                    return;
                end
                if isempty(this.ExportDialog) || ~isvalid(this.ExportDialog)
                    this.ExportDialog = viewgui.internal.ExportDialog(this);
                    show(this.ExportDialog,this.UIFigure);
                else
                    show(this.ExportDialog);
                end
            end
            function openDeleteDialog(this)
                if isempty(this.Systems)
                    uialert(this.UIFigure,getString(message('Control:viewer:errNoSystemsToDelete')), ...
                        getString(message('Control:viewer:strDeleteSystems')),'Icon','error');
                    return;
                end
                if isempty(this.DeleteDialog) || ~isvalid(this.DeleteDialog)
                    this.DeleteDialog = viewgui.internal.DeleteDialog(this);
                    show(this.DeleteDialog,this.UIFigure);
                else
                    show(this.DeleteDialog);
                end
            end
            function openStyleDialog(this)
                if isempty(this.StyleDialog) || ~isvalid(this.StyleDialog)
                    this.StyleDialog = viewgui.internal.StyleDialog(this);
                    show(this.StyleDialog,this.UIFigure);
                else
                    show(this.StyleDialog);
                end
                postStatus(this,getString(message('Control:viewer:msgChangeLineStyles')));
            end
        end
        function plt = createNewPlot(this,plotType,tileLocation,tileSpan)
            arguments
                this (1,1) viewgui.ltiviewer
                plotType (1,1) string
                tileLocation (1,1) double {mustBePositive,mustBeInteger}
                tileSpan (1,2) double {mustBePositive,mustBeInteger}
            end
            plt = controllib.chart.internal.utils.ltiplot(plotType,...
                nexttile(this.PlotLayout,tileLocation,tileSpan),...
                NInputs=this.NInputs,NOutputs=this.NOutputs,Visible="off");
            plt.ResponseDataExceptionMessage = "none";
            opts = getoptions(plt);
            if isprop(opts,"MagUnits")
                opts.MagUnits = this.Preferences.MagnitudeUnits;
            end
            if isprop(opts,"MagScale")
                opts.MagScale = this.Preferences.MagnitudeScale;
            end
            if isprop(opts,"FreqUnits")
                opts.FreqUnits = this.Preferences.FrequencyUnits;
            end
            if isprop(opts,"FreqScale")
                opts.FreqScale = this.Preferences.FrequencyScale;
            end
            if isprop(opts,"PhaseUnits")
                opts.PhaseUnits = this.Preferences.PhaseUnits;
            end
            if isprop(opts,"TimeUnits")
                opts.TimeUnits = this.Preferences.TimeUnits;
            end
            opts.Grid = this.Preferences.Grid;
            opts.Title.FontSize = this.Preferences.TitleFontSize;
            opts.Title.FontWeight = this.Preferences.TitleFontWeight;
            opts.Title.FontAngle = this.Preferences.TitleFontAngle;
            opts.XLabel.FontSize = this.Preferences.XYLabelsFontSize;
            opts.XLabel.FontWeight = this.Preferences.XYLabelsFontWeight;
            opts.XLabel.FontAngle = this.Preferences.XYLabelsFontAngle;
            opts.YLabel.FontSize = this.Preferences.XYLabelsFontSize;
            opts.YLabel.FontWeight = this.Preferences.XYLabelsFontWeight;
            opts.YLabel.FontAngle = this.Preferences.XYLabelsFontAngle;
            opts.TickLabel.FontSize = this.Preferences.AxesFontSize;
            opts.TickLabel.FontWeight = this.Preferences.AxesFontWeight;
            opts.TickLabel.FontAngle = this.Preferences.AxesFontAngle;
            prefs = cstprefs.tbxprefs;
            if ~isequal(this.Preferences.AxesForegroundColor,prefs.AxesForegroundColor)
                opts.TickLabel.Color = this.Preferences.AxesForegroundColor;
            end
            opts.InputLabels.FontSize = this.Preferences.IOLabelsFontSize;
            opts.InputLabels.FontWeight = this.Preferences.IOLabelsFontWeight;
            opts.InputLabels.FontAngle = this.Preferences.IOLabelsFontAngle;
            opts.OutputLabels.FontSize = this.Preferences.IOLabelsFontSize;
            opts.OutputLabels.FontWeight = this.Preferences.IOLabelsFontWeight;
            opts.OutputLabels.FontAngle = this.Preferences.IOLabelsFontAngle;
            if isprop(opts,"SettleTimeThreshold")
                opts.SettleTimeThreshold = this.Preferences.SettlingTimeThreshold;
            end
            if isprop(opts,"RiseTimeLimits")
                opts.RiseTimeLimits = this.Preferences.RiseTimeLimits;
            end
            if isprop(opts,"PhaseWrapping")
                opts.PhaseWrapping = char(~matlab.lang.OnOffSwitchState(this.Preferences.UnwrapPhase));
            end
            if isprop(opts,"MagLowerLim")
                if matlab.lang.OnOffSwitchState(this.Preferences.MinGainLimit.Enable)
                    mode = 'manual';
                else
                    mode = 'auto';
                end
                opts.MagLowerLimMode = mode;
                opts.MagLowerLim = this.Preferences.MinGainLimit.MinGain;
            end
            if isprop(opts,"PhaseWrappingBranch")
                opts.PhaseWrappingBranch = this.Preferences.PhaseWrappingBranch;
            end
            setoptions(plt,opts);
        end
    end

    %% Hidden methods
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.FigureMenu = this.FigureMenu;
            widgets.Toolbar = this.Toolbar;
            widgets.Legend = this.Legend;
            widgets.ConfigDialog = this.ConfigDialog;
            widgets.StyleDialog = this.StyleDialog;
            widgets.ImportDialog = this.ImportDialog;
            widgets.ExportDialog = this.ExportDialog;
            widgets.DeleteDialog = this.DeleteDialog;
            widgets.StartupDialog = this.StartupDialog;
        end
        % Ident workflows, see toolbox/ident/idguis/iduidrop.m and 
        % toolbox/ident/idguis/iduiedit.m
        function hideRefreshMenu(this)
            this.FigureMenu.EditMenu.RefreshSystems.Visible = false;
        end
        function setIdentStyle(this,systemInd,color)
            arguments
                this (1,1) viewgui.ltiviewer
                systemInd (1,1) double {mustBePositive,mustBeInteger}
                color {validatecolor}
            end
            for ii = 1:length(this.Plots)
                this.Plots{ii}.Responses(systemInd).Style.Color = color;
                this.Plots{ii}.Responses(systemInd).Style.LineStyle = '-';
                this.Plots{ii}.Responses(systemInd).Style.MarkerStyle = 'none';
            end
            set(this.LegendLines(systemInd),Color=color,LineStyle='-',Marker='none');
        end
        function renameIdentSystem(this,systemInd,name)
            arguments
                this (1,1) viewgui.ltiviewer
                systemInd (1,1) double {mustBePositive,mustBeInteger}
                name (1,1) string
            end
            this.Systems{systemInd}.Model.Name = name;
            for ii = 1:length(this.Plots)
                this.Plots{ii}.Responses(systemInd).Name = name;
            end
            set(this.LegendLines(systemInd),DisplayName=strrep(name,'_','\_'));
        end
    end
end