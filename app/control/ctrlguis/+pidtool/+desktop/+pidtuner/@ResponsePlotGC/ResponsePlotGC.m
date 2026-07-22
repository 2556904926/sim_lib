classdef ResponsePlotGC < handle
    %RESPONSEPLOTGC
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties (Dependent = true)
        PlotType
        LoopType
        BaselineView
        LegendView
        ViewedPlants
        PlantsVisibilitySelectedOnly
    end
    properties
        PlotHandle
        % AxesHandle
        
        % Version = 1
        Figure
        FigureDocument
        FigureCloseSuccess = true
    end
    properties (Access = private)
        BaselineView_ = false
        LegendView_ = true
        PlantsVisibilitySelectedOnly_ = true
        PlotType_ = 'step'
        LoopType_ = 'r2y'
        StepFinalTime
        % RightClickMenu
        % Legend
        Listeners
        DataSourcePlot
    end
    properties(Dependent = true, Access = private)
        FigureTitle
    end
    events
        FigureCloseRequested
    end
    methods
        function this = ResponsePlotGC(plottype, looptype, datasrcplot, varargin)
            %RESPONSEPLOTGC
            if nargin > 3
                FigureDocGroupTag = varargin{1};
            else
                FigureDocGroupTag = [];
            end
            this.PlotType_ = plottype;
            this.LoopType_ = looptype;
            this.DataSourcePlot = datasrcplot;
            %========================================================================================================(Figure)
            this.FigureDocument = matlab.ui.internal.FigureDocument;
            this.FigureDocument.Title = this.FigureTitle;
            this.FigureDocument.CanCloseFcn = @(es,ed) closeFigure(this);

            % Create document tag
            docTag = strcat('ResponsePlot:',plottype,'_',looptype);
            this.FigureDocument.Tag = docTag;
            this.FigureDocument.DocumentGroupTag = FigureDocGroupTag;
            this.Figure = this.FigureDocument.Figure;
            %==============================================================================(Add zoom/pan)
            %             controllib.plot.internal.FloatingPalette(this.Figure);
            %==============================================================================(Axes , menu responses and legend)
            this.buildAxes();
            this.buildRightClickMenu();
            this.addResponses();
            this.buildLegend();
            this.updateAxesTimeUnits();
            this.updateBaselineValidity();
            %=====================================================================================================(Listeners)
            L1 = addlistener(this.DataSourcePlot, 'processedPlantsEvent', @this.callbackPlantsEvent);
            L2 = addlistener(this.DataSourcePlot,'TimeUnit','PostSet',@(~,~)this.updateAxesTimeUnits);
            L3 = addlistener(this.DataSourcePlot, 'QuickRefreshMode', 'PostSet', @(~,~)localRefreshModeCallback(this));
            L4 = addlistener(this.DataSourcePlot, 'hasBaseline', 'PostSet', @(~,~)this.updateBaselineValidity);
            L5 = addlistener(this.DataSourcePlot, 'showBaseline', 'PostSet', @(~,~)localShowBaselineCallback(this));
            L6 = addlistener(this.Figure, 'Visible', 'PostSet', @(~,~)localRefreshModeCallback(this));
            addListeners(this, L1, L2, L3, L4, L5, L6);
            %===============================================================================================(Initialize view)
            this.DataSourcePlot.setActiveFigure(this.Figure);
        end
        function rebuild(this)
            %REBUILD
            viewedplants = this.ViewedPlants;
            baselineview = this.BaselineView_;
            if ~isempty(this.PlotHandle) && ishandle(this.PlotHandle)
                clf(this.Figure);
            end
            this.buildAxes();
            this.buildRightClickMenu();
            this.addResponses();
            this.buildLegend();
            this.updateAxesTimeUnits();
            this.ViewedPlants = viewedplants;
            this.updateBaselineValidity();
            this.BaselineView = baselineview;
            localRefreshModeCallback(this);
            this.DataSourcePlot.setActiveFigure(this.Figure);
        end
        %========================================================================================================(Build axes)
        function buildAxes(this)
            %BUILDAXES
            setWarningsOff = ctrlMsgUtils.SuspendWarnings;

            % Switch CSTPlots version to 2.0
            currentCSTPlotsVersion = controllibutils.CSTCustomSettings.setCSTPlotsVersion(2);
            
            % Create plot
            switch this.PlotType_
                case 'step'
                    this.PlotHandle = controllib.chart.StepPlot(Parent=this.Figure);
                case 'bode'
                    this.PlotHandle = controllib.chart.BodePlot(Parent=this.Figure);
            end
            this.PlotHandle.ResponseDataExceptionMessage = "none";
            
            figtitle = this.FigureTitle;
            set(this.Figure, 'Name', figtitle);
            this.PlotHandle.Title.String = figtitle;
            this.PlotHandle.AxesStyle.GridVisible = true;
            % Set semantic color order
            this.PlotHandle.StyleManager.SemanticColorOrder = ...
                controllib.plot.internal.utils.GraphicsColor([...
                1 1 2 2 3 3 4 4 5 5 6 6 7 7]).SemanticName;

            % Revert CSTPlots version
            controllibutils.CSTCustomSettings.setCSTPlotsVersion(currentCSTPlotsVersion);
        end
        %=====================================================================================================(Add responses)
        function addResponses(this)
            %ADDRESPONSES
            sources = this.DataSourcePlot.getLoopSources(this.LoopType_);
            N = this.DataSourcePlot.NumPlants;
            for id = 1:N % plants index
                srcs = sources(id,:);
                this.addPlantResponses(srcs, id);
            end
            localUpdatePlantVisibilityMode(this);
        end
        function addPlantResponses(this, sources, id)
            %ADDPLANTRESPONSES
            setWarningsOff = ctrlMsgUtils.SuspendWarnings;
            for i = 1:2 % controller index
                src = sources(i);
                switch this.PlotType_
                    case 'step'
                        r = controllib.chart.response.StepResponse(src,Name=src.Name);
                    case 'bode'
                        r = controllib.chart.response.BodeResponse(src,Name=src.Name);
                end
                registerResponse(this.PlotHandle,r);
                if i==1
                    r.LineStyle = '-';
                else
                    r.LineStyle = '--';
                end
                r.LineWidth = 2;
                if i == 1
                    r0 = r;
                    L = addlistener(src, 'isSelectedPlant', 'PostSet',...
                        @(~,~) localSelectedPlantCallback(r,this));
                else
                    this.addPlantsMenuItem(r0, r, id);
                    r0 = [];
                end
                L1 = addlistener(src, 'Name', 'PostSet',...
                        @(~,~) localNameChangeCallback(src,r));
                L2 = addlistener(r, 'Visible', 'PostSet',...
                        @(~,~) localUpdateLegendItems(r,this));
                localSetSelectedPlantStyle(r);
            end
        end
        %========================================================================================(Axes Limits and Time Units)
        function refreshXLIM(this)
            %REFRESHXLIM
            % Restrict x limit to 20/wc (g778710), 2000/wc (g1053256),
            % 80/wc (g1628836) or 8000/wc (g1628836). Update x limit only
            % when slider stops moving (e.g. when refreshMode is normal).
            % Also check if the default c-lim is much lower than expected
            % (g1148568, g1177566)
            hPlot = this.PlotHandle;
            if strcmp(this.PlotType,'step')
                xfocus = resetFocus(hPlot);
                xlimDefault = xfocus(end);
                xlimNeeded = this.DataSourcePlot.getStepXlimNeeded(this.LoopType);
                if prod(xlimDefault - xlimNeeded(1:2)) > 0
                    if prod(xlimDefault - xlimNeeded(2:3)) < 0
                        xlimNeededMax = xlimDefault;
                        xlimNeededMin = xlimNeeded(2);
                    elseif xlimDefault > xlimNeeded(3)
                        xlimNeededMax = xlimNeeded(3);
                        xlimNeededMin = xlimNeeded(2);
                    elseif xlimDefault < xlimNeeded(1)
                        xlimNeededMax = xlimNeeded(1)*20;
                        xlimNeededMin = xlimNeeded(1)*20;
                    else
                        xlimNeededMax = xlimNeeded(2);
                        xlimNeededMin = xlimNeeded(2);
                    end
                    for ct=1:length(hPlot.Responses)
                        hPlot.Responses(ct).Data.clear;
                    end

                    % Check Number of Samples
                    Ts = this.PlotHandle.Responses(1).Model.Ts;
                    nSamples(1) = xlimNeededMin/Ts;
                    nSamples(2) = xlimNeededMax/Ts;
                    checkSamples = (100000 - nSamples) >= 0;
                    % g1303588: required number of samples should not exceed
                    % limit. Limit of 100000 derived from SimInfo.MaxSample in
                    % matlab\toolbox\shared\controllib\engine\+ltipack\@ltidata\timeresp.m
                    if any(checkSamples) || Ts == 0
                        if prod(checkSamples) < 0
                            xlimNeeded = 100000*Ts;
                        else
                            xlimNeeded = xlimNeededMax;
                        end
                        hPlot.setTimeFocus(xlimNeeded,this.DataSourcePlot.TimeUnit);
                        this.StepFinalTime = xlimNeeded;
                        hPlot.draw();
                        this.StepFinalTime = [];
                    else
                        if ~isempty(this.DataSourcePlot.TunerTC.StatusBar)
                            msg = getString(message('Control:pidtool:strTooManyDataPoints'));
                            this.DataSourcePlot.TunerTC.StatusBar.setText(msg,'warning','west');
                        end
                        hPlot.AxesGrid.send('ViewChanged');
                    end
                else
                    hPlot.AxesGrid.send('ViewChanged');
                end
            end
        end
        function updateAxesTimeUnits(this)
            %UPDATEAXESTIMEUNITS
            h = this.PlotHandle;
            setWarningsOff = ctrlMsgUtils.SuspendWarnings;
            if strcmp(this.PlotType, 'step')
                h.TimeUnit = this.DataSourcePlot.TimeUnit;
            else
                h.FrequencyUnit = this.DataSourcePlot.FreqUnit;
            end
            this.updateLegend();
        end
        %=========================================================================================================(Plot Type)
        function val = get.PlotType(this)
            %GET_PLOTTYPE
            val = this.PlotType_;
        end
        function set.PlotType(this, val)
            %SET_PLOTTYPE
            this.PlotType_ = val;
            this.rebuild();
        end
        %=========================================================================================================(Loop Type)
        function val = get.LoopType(this)
            %GET_LOOPTYPE
            val = this.LoopType_;
        end
        function set.LoopType(this, val)
            %SET_LOOPTYPE
            this.LoopType_ = val;
        end
        %==================================================================================================(Right-click menu)
        function buildRightClickMenu(this)
            %BUILDRIGHTCLICKMENU
            plottypemenu = uimenu('Parent',[],...
                'Label',pidtool.utPIDgetStrings('cst', 'strPlotType'),'Tag','plottype');
            stepitem = uimenu('Parent',plottypemenu,...
                'Label',pidtool.utPIDgetStrings('cst', 'plotpanel_typecombo1'), 'Tag','step',...
                'Callback', {@localChangePlotType 'step' this});
            bodeitem = uimenu('Parent',plottypemenu,...
                'Label',pidtool.utPIDgetStrings('cst', 'plotpanel_typecombo2'), 'Tag','bode', ...
                'Callback', {@localChangePlotType 'bode' this});
            baselineitem = uimenu('Parent',[],'Label',this.DataSourcePlot.showBaselineString,'Tag','baseline',...
                'Callback',{@localToggleBaselineVisibility this});
            showlegenditem = uimenu('Parent',[],...
                'Label',pidtool.utPIDgetStrings('cst', 'strShowLegend'),'Tag','legendmenu',...
                'Callback',{@localToggleLegendVisibility this});
            plantsmenu = uimenu('Parent',[],...
                'Label',pidtool.utPIDgetStrings('cst', 'strShowPlants'),'Tag','plants');
            showplantsmenu = uimenu('Parent',plantsmenu,'Position', 1,'Label',pidtool.utPIDgetStrings('cst', 'strOnlySelectedPlant'),...
                'Callback',{@localTogglePlantVisiblityMode this},'Tag','plantsmode','Checked','on');
            switch this.PlotType_
                case 'step'
                    set(stepitem, 'Checked', 'on');
                case 'bode'
                    set(bodeitem, 'Checked', 'on');
            end

            % Add items to menu
            this.PlotHandle.removeMenu('systems');
            this.PlotHandle.addMenu(plottypemenu,Above='characteristics')
            this.PlotHandle.addMenu(baselineitem,Above='characteristics')
            this.PlotHandle.addMenu(showlegenditem,Above='characteristics')
            this.PlotHandle.addMenu(plantsmenu,Above='characteristics')          

        end
        function addPlantsMenuItem(this, r0, r, id)
            %ADDPLANTSMENUITEM
            src = r0.getModelSource;
            plantsmenu = localGetMenuItem(this.PlotHandle.ContextMenu,'plants');
            plantitem = uimenu('Parent',plantsmenu,'Position', id+1,...
                'Callback',{@localTogglePlantsVisibility this r0});
            localUpdateCheckedPlants(plantitem, r0, r, this);
            localUpdatePlantItemName(plantitem,src,r);
            L1 = addlistener(r0,'Visible','PostSet', @(~,~) localUpdateCheckedPlants(plantitem, r0, r, this));
            L2 = addlistener(src,'PlantName','PostSet', @(~,~) localUpdatePlantItemName(plantitem, src, r));
            set(plantitem, 'UserData', [L1;L2]);
            if id==1
                plantitem.Separator = 'on';
            end
        end
        function set.PlantsVisibilitySelectedOnly(this,val)
            this.PlantsVisibilitySelectedOnly_ = val;
            localUpdatePlantVisibilityMode(this);
        end
        
        function val = get.PlantsVisibilitySelectedOnly(this)
            val = this.PlantsVisibilitySelectedOnly_;
        end
        %=====================================================================================================(Viewed plants)
        function val = get.ViewedPlants(this)
            %GET_VIEWEDPLANTS
            responses = this.PlotHandle.Responses;
            N = this.DataSourcePlot.NumPlants;
            val = false(N,1);
            for i = 1:N
                if strcmp(responses(1+2*(i-1)).Visible,'on')
                    val(i) = true;
                else
                    val(i) = false;
                end
            end
        end
        function set.ViewedPlants(this, val)
            %SET_VIEWEDPLANTS
            responses = this.PlotHandle.Responses;
            N = this.DataSourcePlot.NumPlants;
            for i = 1:N
                if val(i)
                    responses(1+2*(i-1)).Visible = 'on';
                else
                    responses(1+2*(i-1)).Visible = 'off';
                end
            end
        end
        %=====================================================================================================(Baseline view)
        function set.BaselineView(this, val)
            %SET_BASELINEVIEW
            this.BaselineView_ = val;
            this.updateBaselineView();
        end
        function val = get.BaselineView(this)
            %GET_BASELINEVIEW
            val = this.BaselineView_;
        end
        function updateBaselineView(this)
            %UPDATEBASELINEVIEW
            setWarningsOff = ctrlMsgUtils.SuspendWarnings;
            responses = this.PlotHandle.Responses;
            N = this.DataSourcePlot.NumPlants;
            bsmenu = localGetMenuItem(this.PlotHandle.ContextMenu,'baseline');
            if this.BaselineView_
                for i = 2:2:2*N
                    responses(i).Visible = responses(i-1).Visible;
                end
                set(bsmenu, 'Checked', 'on');
            else
                for i = 2:2:2*N
                    responses(i).Visible = 'off';
                end
                set(bsmenu, 'Checked', 'off');
            end
        end
        %============================================================================================================(Legend)
        function buildLegend(this)
            %BUILDLEGEND
            this.PlotHandle.LegendVisible = 'on';
            this.updateLegend();
            this.updateLegendView();
        end
        function val = get.LegendView(this)
            %GET_LEGENDVIEW
            val = this.LegendView_;
        end
        function set.LegendView(this, val)
            %SET_LEGENDVIEW
            this.LegendView_ = val;
            this.updateLegendView();
        end
        function updateLegendView(this)
            %UPDATELEGENDVIEW
            lmenu = localGetMenuItem(this.PlotHandle.ContextMenu,'legendmenu');
            if this.LegendView_
                this.PlotHandle.LegendVisible = 'on';
                legend(this.PlotHandle,'show');
                set(lmenu, 'Checked', 'on');
            else
                this.PlotHandle.LegendVisible = 'off';
                set(lmenu, 'Checked', 'off');
            end
        end
        function updateLegend(this)
            %UPDATELEGEND
            responses = this.PlotHandle.Responses;
            for i = 1:length(responses)
                responses(i).LegendDisplay = responses(i).Visible; %#ok<*NASGU>
            end
            if this.PlotHandle.LegendVisible
                legend(this.PlotHandle,'show');
            end
        end
        %======================================================================================================(Figure Title)
        function figtitle = get.FigureTitle(this)
            %GET_FIGURETITLE
            switch this.PlotType
                case 'step'
                    prefix = pidtool.utPIDgetStrings('cst', 'strStepPlot');
                case 'bode'
                    prefix = pidtool.utPIDgetStrings('cst', 'strBodePlot');
                otherwise
                    prefix = '';
            end
            switch this.LoopType_
                case 'olsys'
                    title = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo5');
                case 'r2y'
                    title = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo1');
                case 'r2u'
                    title = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo2');
                case 'id2y'
                    title = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo3');
                case 'od2y'
                    title = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo4');
                case 'p'
                    title = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo6');
                otherwise
                    title = pidtool.utPIDgetStrings('cst', 'tunerdlg_title');
            end
            figtitle = [prefix ': ' title];
        end
        %=================================================================================================(Is Baseline Valid)
        function updateBaselineValidity(this)
            %UPDATEBASELINEVALIDITY
            bsmenu = localGetMenuItem(this.PlotHandle.ContextMenu,'baseline');
            if ~this.DataSourcePlot.hasBaseline || strcmp(this.LoopType_, 'p')
                this.BaselineView = false;
                set(bsmenu, 'Enable', 'off');
            else
                set(bsmenu, 'Enable', 'on');
                if this.DataSourcePlot.showBaseline
                    this.BaselineView = true;
                else
                    this.BaselineView = false;
                end
            end
        end
        %==========================================================================================================(Clean-up)
        function delete(this)
            %DELETE
            closeFigure(this);
        end
        function result = closeFigure(this)
            %CLOSEFIGURE
            try
            notify(this, 'FigureCloseRequested');
            result = this.FigureCloseSuccess;
            catch
            result = true;
            end
        end
        function closeFigureCleanup(this)
            %CLOSEFIGURECLEANUP
            
            if ~isempty(this.PlotHandle) && ishandle(this.PlotHandle)
                resp = this.PlotHandle.Responses;
                for i = 1:2:length(resp)
                    set(resp(i), 'Visible', 'off');
                end
                clf(this.Figure);
            end
            L = this.Listeners;
            this.Listeners = [];
            for ct = 1:numel(L)
                delete(L{ct});
            end
        end
        %=========================================================================================================(Callbacks)
        function callbackPlantsEvent(this, ~, evnt)
            %CBPLANTSEVENT
            
            if evnt.RenamedAt
                this.updateLegend();
            elseif evnt.Added
                sources = this.DataSourcePlot.getLoopSources(this.LoopType_);
                N = this.DataSourcePlot.NumPlants;
                this.addPlantResponses(sources(end,:), N);
                localUpdatePlantVisibilityMode(this);
                this.buildLegend();
            elseif evnt.RemovedAt
                id = evnt.RemovedAt;
                id1 = 1+2*(id-1);
                id2 = 2*id;
                responses = this.PlotHandle.Responses;
                delete(this.PlotHandle.Responses(id2));
                delete(this.PlotHandle.Responses(id1));
                plantsmenu = localGetMenuItem(this.PlotHandle.ContextMenu,'plants');
                plantsmenuitems = plantsmenu.Children;
                plantitem = findobj(plantsmenuitems, 'Position', evnt.RemovedAt+1);
                L = get(plantitem, 'UserData');
                delete(plantitem);
                delete(L);
                plantitem1 = findobj(plantsmenu, 'Position', 2);
                plantitem1.Separator = 'on';
                this.updateLegend();
            end
        end
        %=================================================================================================(Utility functions)
        function addListeners(this, varargin)
            %ADDLISTENERS
            this.Listeners = [this.Listeners; varargin(:)];
        end
    end
end

%==========================================================================================================(Plants callbacks)
function localTogglePlantVisiblityMode(~,~, this)
if ~this.PlantsVisibilitySelectedOnly_
    this.PlantsVisibilitySelectedOnly = true;
end
end

function localUpdatePlantVisibilityMode(this)
plants = localGetMenuItem(this.PlotHandle.ContextMenu,'plants');
plantsmode = localGetMenuItem(plants,'plantsmode');
waringsoff = ctrlMsgUtils.SuspendWarnings; %#ok<*NASGU>

if this.PlantsVisibilitySelectedOnly_
    plantsmode.Checked = 'on';
    rs = this.PlotHandle.Responses;
    for i=1:2:length(rs)
        r = rs(i);
        modelSrc = r.getModelSource;
        if modelSrc.isSelectedPlant
            r.Visible = 'on';
        else
            r.Visible = 'off';
        end
    end
    
else
    plantsmode.Checked = 'off';
end
end

function localTogglePlantsVisibility(~, ~,this, r0)
%LOCALTOGGLEPLANTSVISIBILITY
waringsoff = ctrlMsgUtils.SuspendWarnings; %#ok<*NASGU>
if strcmp(r0.Visible,'off')
    r0.Visible='on';
    modelSrc = r0.getModelSource;
    if ~modelSrc.isSelectedPlant
        this.PlantsVisibilitySelectedOnly = false;
    end
else
    r0.Visible='off';
    modelSrc = r0.getModelSource;
    if modelSrc.isSelectedPlant
        this.PlantsVisibilitySelectedOnly = false;
    end
end
end
function localUpdateCheckedPlants(plantitem, wf0, wf, this)
%LOCALUPDATECHECKEDPLANTS
modelSrc = wf0.getModelSource;
if strcmp(wf0.Visible, 'on')
    set(plantitem, 'Checked', 'on');
    this.DataSourcePlot.addViewedPlant(modelSrc.PlantName);
else
    set(plantitem, 'Checked', 'off');
    this.DataSourcePlot.removeViewedPlant(modelSrc.PlantName);
end
if strcmp(wf0.Visible, 'on') && this.BaselineView_
    wf.Visible = 'on';
else
    wf.Visible = 'off';
end
end
%=========================================================================================================(Baseline Callback)
function localToggleBaselineVisibility(~, ~, this)
%LOCALTOGGLEBASELINEVISIBILITY
this.BaselineView = ~this.BaselineView;
end
%==========================================================================================================(Legend callbacks)
function localUpdateLegendItems(r, this)
%LOCALUPDATELEGENDITEMS
r.LegendDisplay = r.Visible; %#ok<*NASGU>
if this.PlotHandle.LegendVisible
    legend(this.PlotHandle,'show');
end
end

function localToggleLegendVisibility(~, ~, this)
%LOCALTOGGLELEGENDVISIBILITY
this.LegendView = ~this.LegendView;
end

%=========================================================================================================(PlotType callback)
function localChangePlotType(~,~,type,this)
%LOCALCHANGEPLOTTYPE
this.PlotType = type;
end

%================================================================================================(Plant name change callback)
function localNameChangeCallback(src, r)
%LOCALNAMECHANGECALLBACK
r.Name = src.Name;
WarningState = warning('off');
r.update;
warning(WarningState);
end

function localUpdatePlantItemName(plantitem, src, r)
%LOCALUPDATEPLANTITEMNAME
% set(plantitem, 'Label', [src.PlantName ' (' r.Style.Legend ')']); % NOTE: NO WAY TO CONVERT RGB COLOR TO NAME (i.e. DARK BLUE)
set(plantitem, 'Label', src.PlantName);
end
%============================================================================================(Selected plant change callback)
function localSelectedPlantCallback(r,this)
%LOCALSELECTEDPLANTCALLBACK
localSetSelectedPlantStyle(r);
modelSrc = r.getModelSource;
if ~modelSrc.isSelectedPlant && this.PlantsVisibilitySelectedOnly_
    r.Visible = 'off';
else
    r.Visible = 'on';
end
end
function localSetSelectedPlantStyle(r)
modelSrc = r.getModelSource;
if modelSrc.isSelectedPlant
    r.LineWidth = 2;
else
    r.LineWidth = 1/2;
end
end
%==============================================================================================================(Refresh mode)
function localRefreshModeCallback(this)
%LOCALREFRESHMODECALLBACK
setWarningsOff = ctrlMsgUtils.SuspendWarnings;
if this.DataSourcePlot.QuickRefreshMode
    setRefreshMode(this.PlotHandle,'quick')
else
    setRefreshMode(this.PlotHandle,'normal')
    % this.refreshXLIM(); % NOTE: THIS MAY NOT BE NEEDED
end
end
%=(Global baselline setting)
function localShowBaselineCallback(this)
bsmenu = localGetMenuItem(this.PlotHandle.ContextMenu,'baseline');
if ~strcmp(get(bsmenu, 'Enable'), 'off')
    this.BaselineView = this.DataSourcePlot.showBaseline;
end
end

function menuItem = localGetMenuItem(menu,menuTag)
arguments
    menu
    menuTag
end
menuTags = {menu.Children.Tag};
menuItem = menu.Children(strcmpi(menuTags,menuTag));
end
