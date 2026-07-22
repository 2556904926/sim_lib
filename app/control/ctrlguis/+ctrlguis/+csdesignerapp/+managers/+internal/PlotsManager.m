classdef PlotsManager < handle
    %PlotManager Manages the plots

    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties (Access = private)
        % Handle to App.
        App
        
        % Plot Lists
        ResponsePlotList
        TuningGoalPlotList
        TunedBlockPlotList
        
        % Plot's Tab Manager
        %         PlotTabManager
        
        % Dirty Flag
        DirtyFlag = false
        
        % Listeners
        DesignListListener
        ResponseListListener
        BlockListListener
        PlotDeletedListener
        PlotFigureDeletedListener
        
        ConstraintEditor
    end
    properties (Access = public, SetObservable)
        % ComparedDesigns
        Designs
    end
    
    methods
        function this = PlotsManager(App)
            % Constructor
            this.App = App;
            this.ConstraintEditor = getConstraintEditor(App);
            installListeners(this)
        end
        
        function delete(this)
            uninstallListeners(this)
            delete(this.ResponsePlotList)
            delete(this.TuningGoalPlotList)
            delete(this.TunedBlockPlotList)
            cleanupPlotLists(this);
        end
        
        function S =  saveSession(this)
            cleanupPlotLists(this);
            DesignerData = this.App.getData;
            % Save Compared Designs
            DIdx = [];
            DList = getDesigns(DesignerData);
            for ct = 1:length(this.Designs)
                DIdx = [DIdx;find(this.Designs(ct)==DList)];
            end
            S.ComparedDesigns.ComparedDesignIdx = DIdx;
            
            
            % Save Response Plots
            RespInfo =repmat( struct('Type','','Index',[],'Options',[],'Constraints',[]),0,1);
            RespList = getResponses(DesignerData);
            for ct = 1:length(this.ResponsePlotList)
                plotHandle = getPlotHandle(this.ResponsePlotList(ct));
                RespIdx = find(getResponse(this.ResponsePlotList(ct))==RespList);
                RespType = getType(this.ResponsePlotList(ct));
                RespOptions = getoptions(plotHandle);
                if controllib.chart.internal.utils.isChart(plotHandle)
                    RespConstraints = saveConstraints(plotHandle);
                else
                    RespConstraints = saveconstr(plotHandle);
                end
                
                RespInfo(ct,1) = struct('Type',RespType,'Index',RespIdx,'Options',RespOptions,'Constraints',RespConstraints);
            end
            S.ResponsePlots.PlotData = RespInfo;
            
            % Save TunedBlock Plot
            BlockPlotsInfo = repmat(struct('Type','','Index',[],'Options',[],'Constraints',[]),0,1);
            BlockList = getTunableBlocks(DesignerData);
            for ct = 1:length(this.TunedBlockPlotList)
                plotHandle = getPlotHandle(this.TunedBlockPlotList(ct));
                BlockIdx = find(this.TunedBlockPlotList(ct).getBlock==BlockList);
                BlockRespType = getType(this.TunedBlockPlotList(ct));
                BlockRespOptions = getoptions(plotHandle);
                if controllib.chart.internal.utils.isChart(plotHandle)
                    BlockRespConstraints = saveConstraints(plotHandle);
                else
                    BlockRespConstraints = saveconstr(plotHandle);
                end
                BlockPlotsInfo(ct,1) = struct('Type',BlockRespType,'Index',BlockIdx,'Options',BlockRespOptions,'Constraints',BlockRespConstraints);
            end
            S.TuneBlocksPlots.BlockPlotsData = BlockPlotsInfo;
            
            % save session
            setDirty(this,false)
            
        end
        
        function S =  upgradeToLatest(this,OldPlots,RespIdxMapping,BlockIdxMapping)
            
            % Comparisons were not allowed
            S.ComparedDesigns.ComparedDesignIdx = [];
            
            % ViewerContents - one per plot
            % VisibleModels - Number of responses on each plot
            %
            
            % Save Response Plots
            RespInfo = repmat( struct('Type','','Index',[],'Options',[],'Constraints',[]),0,1);
            for ct1 = 1:numel(OldPlots.ViewerContents)
                % Number of axes
                for ct2 = 1:numel(OldPlots.ViewerContents(ct1).VisibleModels)
                    % Number of responses on each axes
                    OldIdx = OldPlots.ViewerContents(ct1).VisibleModels(ct2);
                    NewIdx = RespIdxMapping((RespIdxMapping(:,1) == OldIdx),2);
                    if ~isempty(NewIdx)
                        RespInfo = [RespInfo;  struct('Type',OldPlots.ViewerContents(ct1).PlotType, ...
                            'Index',NewIdx, ...
                            'Options',[], ...
                            'Constraints',OldPlots.ViewerData(ct1).PlotCell(end).Constraints)];
                    end
                end
            end
            
            S.ResponsePlots.PlotData = RespInfo;
            S.ResponseIdxMapping = RespIdxMapping;
            
            % Block plots
            BlockPlotsInfo = repmat( struct('Type','','Index',[],'Options',[],'Constraints',[]),0,1);
            if ~isempty(BlockIdxMapping)
                for ct1 = 1:numel(OldPlots.ViewerContents)
                    % Number of axes
                    for ct2 = 1:numel(OldPlots.ViewerContents(ct1).VisibleModels)
                        % Number of responses on each axes
                        OldIdx = OldPlots.ViewerContents(ct1).VisibleModels(ct2);
                        NewIdx = BlockIdxMapping((BlockIdxMapping(:,1) == OldIdx),2);
                        if ~isempty(NewIdx)
                            BlockPlotsInfo = [BlockPlotsInfo;  struct('Type',OldPlots.ViewerContents(ct1).PlotType, ...
                                'Index',NewIdx, ...
                                'Options',[], ...
                                'Constraints',OldPlots.ViewerData(ct1).PlotCell(end).Constraints)];
                        end
                    end
                end
            end
            S.TuneBlocksPlots.BlockPlotsData = BlockPlotsInfo;
            S.BlockIdxMapping = BlockIdxMapping;
        end
        
        function loadSession(this,S)
            delete(this.ResponsePlotList)
            delete(this.TuningGoalPlotList)
            delete(this.TunedBlockPlotList)
            cleanupPlotLists(this);
            
            if ~isempty(S)
                DesigerData = getData(this.App);
                % Restore Compared Designs
                AllDesigns = getDesigns(DesigerData);
                for ct = 1:length(S.ComparedDesigns.ComparedDesignIdx)
                    showDesign(this,AllDesigns(S.ComparedDesigns.ComparedDesignIdx(ct)));
                end
                
                % Restore Response Plots
                RespList = getResponses(DesigerData);
                for ct = 1:length(S.ResponsePlots.PlotData)
                    createResponsePlot(this,RespList(S.ResponsePlots.PlotData(ct).Index),...
                        S.ResponsePlots.PlotData(ct).Type);
                    RPlot = getPlotHandle(this.ResponsePlotList(end));
                    if ~isempty(S.ResponsePlots.PlotData(ct).Options)
                        setoptions(RPlot,S.ResponsePlots.PlotData(ct).Options);
                    end
                    if controllib.chart.internal.utils.isChart(RPlot)
                        loadConstraints(RPlot,S.ResponsePlots.PlotData(ct).Constraints);
                    else
                        loadconstr(RPlot,S.ResponsePlots.PlotData(ct).Constraints);
                    end
                end
                
                if isfield(S,'TuneBlocksPlots')

                    BlockList = getTunableBlocks(DesigerData);
                    if isempty(DesigerData.getArchitecture.SaveData)
                        MappingIdx = 1:numel(BlockList);
                    else
                        MappingIdx = DesigerData.getArchitecture.SaveData;
                    end
                    for ct = 1:length(S.TuneBlocksPlots.BlockPlotsData)
                        createTunedBlockPlot(this,BlockList(MappingIdx(S.TuneBlocksPlots.BlockPlotsData(ct).Index)),...
                            S.TuneBlocksPlots.BlockPlotsData(ct).Type);
                        BPlot = getPlotHandle(this.TunedBlockPlotList(end));
                        if ~isempty(S.TuneBlocksPlots.BlockPlotsData(ct).Options)
                            setoptions(BPlot,S.TuneBlocksPlots.BlockPlotsData(ct).Options);
                        end
                        if controllib.chart.internal.utils.isChart(BPlot)
                            loadConstraints(BPlot,S.TuneBlocksPlots.BlockPlotsData(ct).Constraints);
                        else
                            loadconstr(BPlot,S.TuneBlocksPlots.BlockPlotsData(ct).Constraints);
                        end                        
                    end
                    
                end
                
            end
            setDirty(this,false)
        end
        
        function set.ResponsePlotList(this, NewList)
            this.ResponsePlotList = NewList;
            this.notify('PlotsListChanged');
            setDirty(this,true);
        end
        
        function set.TunedBlockPlotList(this, NewList)
            this.TunedBlockPlotList = NewList;
            this.notify('PlotsListChanged');
            setDirty(this,true);
        end
        
        function PlotList = getResponsePlotList(this)
            cleanupPlotLists(this)
            PlotList = this.ResponsePlotList;
        end
        
        function PlotList = getTuningGoalPlotList(this)
            cleanupPlotLists(this)
            PlotList = this.TuningGoalPlotList;
        end
        
        function PlotList = getTunedBlockPlotList(this)
            cleanupPlotLists(this)
            PlotList = this.TunedBlockPlotList;
        end
        
        function PlotList = getPlotList(this)
            PlotList = [getResponsePlotList(this); ...
                getTuningGoalPlotList(this); ...
                getTunedBlockPlotList(this)];
        end
        
        function showDesign(this,Design)
            % Show design if not already added
            if ~any(Design == this.Designs)
                this.Designs = [this.Designs;Design];
                PList = getPlotList(this);
                for ct = 1:numel(PList)
                    showDesign(PList(ct),Design)
                end
                % Design added
                setDirty(this,true)
                this.notify('DesignSelectionChanged');
            end
        end
        
        function removeDesign(this,Design)
            cleanupPlotLists(this)
            idx = getDesignIndex(this,Design);
            if ~isempty(idx)
                for ct = 1:length(this.ResponsePlotList)
                    RPlot = this.ResponsePlotList(ct);
                    if isPlotValid(RPlot)
                        RPlot.removeDesign(Design);
                    end
                end
                for ct = 1:length(this.TunedBlockPlotList)
                    TBPlot = this.TunedBlockPlotList(ct);
                    if isPlotValid(TBPlot)
                        TBPlot.removeDesign(Design);
                    end
                end
                
                for ct = 1:length(this.TuningGoalPlotList)
                    TGPlot = this.TuningGoalPlotList(ct);
                    if isValidPlot(TGPlot)
                        TGPlot.removeDesign(Design);
                    end
                end
                this.Designs(idx) = [];
                % REVISIT
                %                 this.DesignStyles(idx,:) = [];
                
                % Design removed
                setDirty(this,true)
                this.notify('DesignSelectionChanged');
            end
            
        end
        
        function b = isDesignCompared(this,DesignSnapshot)
            b = ~isempty(getDesignIndex(this, DesignSnapshot));
        end
        
        function idx = getDesignIndex(this, Design)
            % Get index for Design in DesignList
            idx = [];
            for ct = 1:numel(Design)
                idx = [idx; find(Design(ct)==this.Designs)];
            end
        end
        
        function createResponsePlot(this, Response, PlotType)
            
            if isa(PlotType, 'char')
                plottypes = ctrlguis.csdesignerapp.plot.internal.PlotEnum.getPlotTypes(false);
                PlotType =  plottypes(strcmp({plottypes.Tag}, PlotType));
            end
            % Create a plot for the Response specified by the PlotType

            import ctrlguis.csdesignerapp.plot.internal.ResponsePlot;

            setWaiting(this.App,true,getString(message('Control:designerapp:statusMessagePlotting')));

            % Create Plot Based on PlotType
            RPlot = ResponsePlot(Response,PlotType);
            setPreferences(RPlot,this.App.getPreferences);
            setConstraintEditor(RPlot,this.ConstraintEditor);
            createPlot(RPlot);
            this.PlotDeletedListener = [this.PlotDeletedListener;...
                addlistener(RPlot, 'ObjectBeingDestroyed', @(es,ed)cleanupPlotLists(this))];
            this.ResponsePlotList = [this.ResponsePlotList;RPlot];
            
            
            % Turn on legend by default
            % showLegend(RPlot)
            
            % Set document name and add to AppContainer
            document = getDocument(RPlot);
            document.Title = sprintf('%s: %s',getName(Response),PlotType.Tag);
            add(getAppContainer(this.App),document);
            
            % Add Compared Designs to Plot
            for ct =1:length(this.Designs)
                addDesign(RPlot,this.Designs(ct))
            end
            
            % Plot Added
            setDirty(this,true) 
            setWaiting(this.App,false);
        end
        
        function createTuningGoalPlot(this,TuningGoal)
        end
        
        function createTunedBlockPlot(this,TunedBlock, PlotType)
            
            if isa(PlotType, 'char')
                plottypes = ctrlguis.csdesignerapp.plot.internal.PlotEnum.getPlotTypes(false);
                PlotType =  plottypes(strcmp({plottypes.Tag}, PlotType));
            end
            % Create a plot for the Response specified by the PlotType
            
            import ctrlguis.csdesignerapp.plot.internal.BlockPlot;
            
            postStatus(this) % Turn on progress bar
            
            % Create Plot Based on PlotType
            BPlot = BlockPlot(TunedBlock,PlotType);
            setPreferences(BPlot,this.App.getPreferences);
            setConstraintEditor(BPlot,this.ConstraintEditor);
            createPlot(BPlot);
            this.PlotDeletedListener = [this.PlotDeletedListener;...
                addlistener(BPlot, 'ObjectBeingDestroyed', @(es,ed)cleanupPlotLists(this))];
            this.TunedBlockPlotList = [this.TunedBlockPlotList;BPlot];
            
            % Set the figure name
            fig = getFigure(BPlot);
            set(fig,'Name',sprintf('%s: %s',TunedBlock.Name,PlotType.Tag));
            
            % Turn on legend by default
            % showLegend(BPlot)
            
            % Add the figure to the tool
            add(getAppContainer(this.App),getDocument(BPlot));
            
            % Add Compared Designs to Plot
            for ct =1:length(this.Designs)
                addDesign(BPlot,this.Designs(ct))
            end
            
            % Plot Added
            setDirty(this,true)
            
            % clear wait bar
            postStatus(this) % Turn off progress bar
        end
        
        function setDirty(this,Flag)
            this.DirtyFlag = Flag;
            if Flag
                controllib.ui.internal.dirtymgr.DirtyManager.getInstance(...
                    this.App.getData().UniqueName).setDirty(Flag);
            end
        end
        
        function val = isDirty(this)
            val = this.DirtyFlag;
        end
        
    end
    
    methods (Access = private)
        function installListeners(this)
            Data = getData(this.App);
            this.DesignListListener = addlistener(Data,'DesignsListChanged', @(es,ed) cbDesignsListChanged(this,es,ed));
            this.ResponseListListener = addlistener(Data,'ResponsesListChanged', @(es,ed) cbResponsesListChanged(this,es,ed));
            % Simulink list of blocks changed
            this.BlockListListener = addlistener(Data,'TunableBlocksListChanged', @(es,ed) cbBlockListChanged(this,es,ed));
            % Matlab architecture changed
            this.BlockListListener =  [this.BlockListListener;...
                addlistener(Data,'ArchitectureChanged', @(es,ed) cbBlockListChanged(this,es,ed))];
        end
        
        function uninstallListeners(this)
            delete(this.DesignListListener);
            delete(this.ResponseListListener);
            delete(this.BlockListListener);
            delete(this.PlotDeletedListener);
            delete(this.PlotFigureDeletedListener);
        end
        
        function deleteAllPlots(this)
            delete(this.ResponsePlotList)
            delete(this.TuningGoalPlotList)
            delete(this.TunedBlockPlotList)
            cleanupPlots(this);
        end
        
        function cleanupPlotLists(this)
            % Remove the invalid plot or response entries
            for ct = length(this.ResponsePlotList):-1:1
                if ~isempty(this.ResponsePlotList) && ...
                        (~isvalid(this.ResponsePlotList(ct)) || ...
                        ~isPlotValid(this.ResponsePlotList(ct)))
                    this.ResponsePlotList(ct) = [];
                end
            end
            
            for ct = length(this.TuningGoalPlotList):-1:1
                if ~isvalid(this.TuningGoalPlotList(ct)) || ...
                        ~isPlotValid(this.TuningGoalPlotList(ct))
                    this.TuningGoalPlotList(ct) = [];
                end
            end
            
            for ct = length(this.TunedBlockPlotList):-1:1
                if ~isempty(this.TunedBlockPlotList) && ...
                        (~isvalid(this.TunedBlockPlotList(ct)) || ...
                        ~isPlotValid(this.TunedBlockPlotList(ct)))
                    this.TunedBlockPlotList(ct) = [];
                end
            end
        end
        
        function removeDocument(this,es)
            document = getDocument(es);
            appContainer = getAppContainer(this.App);
            if ~isempty(document) && isvalid(document)
                closeDocument(appContainer,document.DocumentGroupTag,document.Tag);
            end
        end
        
        function postStatus(this,varargin)
            % Post status message to the app
            
            % Get Event Manager
            
            % Post Message to Event Manager
        end
        
        
        
        function cbDesignsListChanged(this,es,ed)
            if strcmp(ed.Type,'Remove')
                Design = ed.Data;
                removeDesign(this, Design)
            else
                RemoveList = setdiff(this.Designs,getDesigns(es));
                for ct = 1:length(RemoveList)
                    removeDesign(this, RemoveList(ct))
                end
            end
        end
        
        function cbResponsesListChanged(this,es,ed)
            cleanupPlotLists(this);
            PlotList = getResponsePlotList(this);
            ValidResponses = getResponses(es);
            for ct = 1:length(PlotList)
                if ~any(getResponse(PlotList(ct))==ValidResponses)
                    removeDocument(this,PlotList(ct));
                end
            end
        end
        
        function cbBlockListChanged(this,es,ed)
            cleanupPlotLists(this);
            PlotList = getTunedBlockPlotList(this);
            ValidBlocks = getTunedBlocks(es.Architecture);
            for ct = 1:length(PlotList)
                if ~any(getBlock(PlotList(ct))==ValidBlocks)
                    removeDocument(this,PlotList(ct));
                end
            end
            
        end
    end
    
    methods(Hidden = true)
        function Tabs = qeGetTabs(this)
            Tabs = [];
            %             Tabs = this.PlotTabManager;
        end
    end
    
    events
        PlotsListChanged
        DesignSelectionChanged
    end
    
end

