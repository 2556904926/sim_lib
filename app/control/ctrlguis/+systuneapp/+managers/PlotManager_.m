classdef (Hidden) PlotManager_ < handle
    % Plot Manager class
    
    % Copyright 2011-2021 The MathWorks, Inc.
    
    properties (Access = public, SetObservable)
        DesignList
    end
    properties (Hidden)
        IsDirty = false;
    end
    
    properties (Access = public)
        % Environment
        Parent
        
        ResponseList
        
        % Plot Lists
        ResponsePlotList
        TuningGoalPlotList
        TunedBlockPlotList
        
        
        
        % Listeners
        TuningGoalListListener
        ResponseListListener
        DesignListListener
        
        % Design styles
        DesignStyles = cell(0,1);
        
        DesignStyleList = ...
            {'--','g';
            ':', 'c';
            '-.','r'};
        
        PlotTabManager
        
    end
    
    
    properties(Access=private,Transient)
        PlotList
        PlotDeletedListener
    end
    
    properties (Hidden = true, SetAccess = private)
        Version
    end
    
    methods
        %% Constructor
        function this = PlotManager_(Tool)
            this.Parent = Tool;
            this.TuningGoalListListener = addlistener(Tool.ControlDesignData,'TuningGoalsListChanged', @(es,ed) cbTuningGoalsListChanged(this,es,ed));
            this.ResponseListListener = addlistener(Tool.ControlDesignData,'ResponsesListChanged', @(es,ed) cbResponsesListChanged(this,es,ed));
            this.DesignListListener = addlistener(Tool.ControlDesignData,'DesignsListChanged', @(es,ed) cbDesignsListChanged(this,es,ed));
        end
        %% Destructor
        function delete(this)
            % Make sure the listeners are killed
            delete(this.TuningGoalListListener)
            delete(this.ResponseListListener)
            delete(this.DesignListListener)
            delete(this.PlotDeletedListener)
            clearAllPlots(this)
        end
        
        %% PROJECT SAVE & LOAD UTILITIES
        function S =  saveSession(this)
            cleanupPlots(this);
            % Save Compared Designs
            DIdx = [];
            DList = this.Parent.ControlDesignData.getDesign;
            for ct = 1:length(this.DesignList)
                DIdx = [DIdx;find(this.DesignList(ct)==DList)];
            end
            S.ComparedDesigns.ComparedDesignIdx = DIdx;
            
            
            % Save Tuning Goal Plots
            TGIdx = [];
            TGList = this.Parent.ControlDesignData.getTuningGoal;
            for ct = 1:length(this.TuningGoalPlotList)
                TGIdx = [TGIdx;find(this.TuningGoalPlotList(ct).TuningGoalWrapper==TGList)];
            end
            S.TuningGoalPlots.TuningGoalIdx = TGIdx;
            
            
            % Save Response Plots
            RespInfo =repmat( struct('Type','','Index',[],'Options',[]),0,1);
            RespList = this.Parent.ControlDesignData.getResponse;
            for ct = 1:length(this.ResponsePlotList)
                RespIdx = find(getResponseWrapper(this.ResponsePlotList(ct))==RespList);
                if controllib.chart.internal.utils.isChart(this.ResponsePlotList(ct).PlotHandle)
                    RespType = this.ResponsePlotList(ct).PlotHandle.Type;
                else
                    RespType = this.ResponsePlotList(ct).PlotHandle.Tag;
                end
                
                RespOptions = getoptions(this.ResponsePlotList(ct).PlotHandle);
                RespInfo(ct,1) = struct('Type',RespType,'Index',RespIdx,'Options',RespOptions);
            end
            S.ResponsePlots.RespData = RespInfo;
            
            % Save TunedBlock Plot
            BlockPlotsInfo =repmat( struct('Type','','Index',[],'Options',[]),0,1);
            BlockList = this.Parent.ControlDesignData.getTunableBlock;
            for ct = 1:length(this.TunedBlockPlotList)
                BlockIdx = find(this.TunedBlockPlotList(ct).TunedBlock==BlockList);
                if controllib.chart.internal.utils.isChart(this.TunedBlockPlotList(ct).PlotHandle)
                    BlockRespType = this.TunedBlockPlotList(ct).PlotHandle.Type;
                else
                    BlockRespType = this.TunedBlockPlotList(ct).PlotHandle.Tag;
                end                
                BlockRespOptions = getoptions(this.TunedBlockPlotList(ct).PlotHandle);
                BlockPlotsInfo(ct,1) = struct('Type',BlockRespType,'Index',BlockIdx,'Options',BlockRespOptions);
            end
            S.TuneBlocksPlots.BlockPlotsData = BlockPlotsInfo;
            
            % save session
            setDirty(this,false)
            
        end
        
        function loadSession(this,S)
            clearAllPlots(this)
            
            if ~isempty(S)
                % Restore Compared Designs
                Designs = this.Parent.ControlDesignData.getDesign;
                for ct = 1:length(S.ComparedDesigns.ComparedDesignIdx)
                    showDesign(this,Designs(S.ComparedDesigns.ComparedDesignIdx(ct)));
                end
                
                % Restore Tuning Goal Plots
                TGList = this.Parent.ControlDesignData.getTuningGoal;
                for ct = 1:length(S.TuningGoalPlots.TuningGoalIdx)
                    createTuningGoalPlot(this,TGList(S.TuningGoalPlots.TuningGoalIdx(ct)));
                end
                
                % Restore Response Plots
                RespList = this.Parent.ControlDesignData.getResponse;
                for ct = 1:length(S.ResponsePlots.RespData)
                    createResponsePlot(this,RespList(S.ResponsePlots.RespData(ct).Index),...
                        S.ResponsePlots.RespData(ct).Type);
                end
                
                if isfield(S,'TuneBlocksPlots')
                    BlockList = this.Parent.ControlDesignData.getTunableBlock;
                    for ct = 1:length(S.TuneBlocksPlots.BlockPlotsData)
                        createTunedBlockPlot(this,BlockList(S.TuneBlocksPlots.BlockPlotsData(ct).Index),...
                            S.TuneBlocksPlots.BlockPlotsData(ct).Type);
                    end
                end
                
            end
            setDirty(this,false)
        end
        
        function Style = findNextAvailableDesignStyle(this)
            StyleList = this.DesignStyleList;
            
            index = zeros(size(StyleList(:,1)));
            for ct=1:length(this.DesignStyles(:,1))
                [~,~,match] = intersect(this.DesignStyles(ct,1),StyleList(:,1));
                index(match) = index(match) + 1;
            end
            
            [~, StyleIdx] = min(index);
            Style = StyleList(StyleIdx,:);
        end
        
        function Value = get.PlotList(this)
            cleanupPlots(this)
            Value = [];
            for ct = 1:length(this.ResponsePlotList)
                Value = [Value;this.ResponsePlotList(ct).PlotHandle];
            end
        end
        
        function [hPlot,ct] = findTuningGoalPlot(this,TuningGoalWrapper)
            hPlot = [];
            for ct = 1:length(this.TuningGoalPlotList)
                if isvalid(this.TuningGoalPlotList(ct)) % if not deleted
                    if isequal(TuningGoalWrapper,this.TuningGoalPlotList(ct).TuningGoalWrapper)
                        hPlot = this.TuningGoalPlotList(ct);
                        return;
                    end
                end
            end
        end
        
        function [hPlot,Idxct] = findResponsePlot(this,ResponseWrapper)
            hPlot = [];
            Idxct = [];
            for ct = 1:length(this.ResponsePlotList)
                if isequal(ResponseWrapper,this.ResponsePlotList(ct).ResponseWrapper)
                    hPlot = [hPlot;this.ResponsePlotList(ct)];
                    Idxct = [Idxct;ct];
                end
            end
        end
        
        function showTuningGoalPlot(this,TuningGoalWrapper)
            cleanupPlots(this);
            hPlot = findTuningGoalPlot(this,TuningGoalWrapper);
            if isempty(hPlot)
                createTuningGoalPlot(this,TuningGoalWrapper);
            else
                show(hPlot);
            end
        end
        
        function varargout = createTuningGoalPlot(this,TuningGoalWrapper)
            TG = TuningGoalWrapper.TuningGoal;
            % Create the plot based on type
            Type = systuneapp.util.getTuningGoalType(TG);
            switch Type
               case 'StableController'
                  TGPlot = systuneapp.plots.NewStableControllerTuningGoalPlot(TuningGoalWrapper,this.Parent.ControlDesignData);
               case {'LoopShape','MaxLoopGain','MinLoopGain','Gain','WeightedGain','Sensitivity','Margins',...
                     'Poles','Overshoot','Tracking','Rejection','Transient','StepResp','StepRejection',...
                     'ConicSector','Passivity','WeightedPassivity'}
                  TGPlot = systuneapp.plots.NewTuningGoalPlot(TuningGoalWrapper,this.Parent.ControlDesignData);
               otherwise
                  TGPlot = [];
            end
            
            if ~isempty(TGPlot)           
                setWaiting(this.Parent,true,getString(message('Control:systunegui:StatusMessagePlottingGoal')));     
                createPlot_(TGPlot);
                this.PlotDeletedListener = [this.PlotDeletedListener;...
                    addlistener(TGPlot, 'ObjectBeingDestroyed', @(es,ed)cleanupPlots(this))];
                this.TuningGoalPlotList = [this.TuningGoalPlotList;TGPlot];
                
                % Turn on legend by default
                legend(TGPlot.PlotHandle,'show');
                addLegendButtonToToolbar(TGPlot.PlotHandle);                

                % Add the figure to the tool
                document = TGPlot.Document;
                document.DocumentGroupTag = this.Parent.TuningGoalDocGrpTag;
                add(this.Parent.AppContainer,document);
                
                %Create the Tuning Goal Plot Tab                
                for ct = 1:length(this.DesignList)
                    addDesign(TGPlot,this.DesignList(ct))
                end
                
                % Plot Added
                setDirty(this,true)
                setWaiting(this.Parent,false);
            end
            
            if nargout > 0
                if isempty(TGPlot)
                    varargout{1} = [];
                else
                    varargout{1} = TGPlot.PlotHandle;
                end
            end            
        end
        
        function varargout = createTunedBlockPlot(this,TunedBlock, PlotType)
            % Creates tuned block plot.
            
            % Create the plot based on type
            TBPlot = systuneapp.plots.TunedBlockPlot(TunedBlock, this.Parent.ControlDesignData, PlotType);
            createPlot_(TBPlot);
            this.PlotDeletedListener = [this.PlotDeletedListener;...
                addlistener(TBPlot, 'ObjectBeingDestroyed', @(es,ed)cleanupPlots(this))];
            this.TunedBlockPlotList = [this.TunedBlockPlotList; TBPlot];
            
            if ~isempty(TBPlot)
                setWaiting(this.Parent,true,getString(message('Control:systunegui:StatusMessagePlottingTunedBlock')));   
                % Turn on legend by default
                if controllib.chart.internal.utils.isChart(TBPlot.PlotHandle)
                    ax = getChartAxes(TBPlot.PlotHandle);
                    legend(TBPlot.PlotHandle,'show');
                else
                    ax = TBPlot.PlotHandle.AxesGrid.getaxes('2d');
                    legend(ax(1,1),'show');
                end
                

                % Add the figure to the tool
                document = TBPlot.Document;
                document.DocumentGroupTag = this.Parent.RespPlotDocGrpTag;
                add(this.Parent.AppContainer,document);
                
                %Create the Tuned Block Plot Tab
                if ~controllib.chart.internal.utils.isChart(TBPlot.PlotHandle)
                    controllib.plot.internal.createToolbar(ax);
                end
                                
                % Plot Added
                setDirty(this,true)
                setWaiting(this.Parent,false);
            end

            % Return plot handle if asked for
            if nargout > 0
                if isempty(TBPlot)
                    varargout{1} = [];
                else
                    varargout{1} = TBPlot.PlotHandle;
                end
            end
                        
        end

        function varargout = createResponsePlot(this,ResponseWrapper,plottype,varargin)
            setWaiting(this.Parent,true,getString(message('Control:systunegui:StatusMessagePlottingResponse')));

            if ischar(plottype) || isstring(plottype)
                plottype = systuneapp.PlotEnum.getPlot(plottype);
            end
                        
            % Create the plot based on type
            RPlot = systuneapp.plots.GenericResponsePlot(ResponseWrapper,this.Parent.ControlDesignData,plottype);
            createPlot_(RPlot);
            this.ResponsePlotList = [this.ResponsePlotList;RPlot];
            this.PlotDeletedListener = [this.PlotDeletedListener;...
                addlistener(RPlot, 'ObjectBeingDestroyed', @(es,ed)cleanupPlots(this))];
            
            addItemToResponseList(this, ResponseWrapper);


            % Add document to App
            document = RPlot.Document;
            document.DocumentGroupTag = this.Parent.RespPlotDocGrpTag;
            document.Title = sprintf('%s: %s',getName(ResponseWrapper),plottype.Tag);
            add(this.Parent.AppContainer,document);
            
            % Add Compared Designs to Plot
            for ct =1:length(this.DesignList)
                RPlot.addDesign(this.DesignList(ct))
            end            
            
            % Turn on legend by default
            if controllib.chart.internal.utils.isChart(RPlot.PlotHandle)
                legend(RPlot.PlotHandle,'show');
            else
                ax = RPlot.PlotHandle.AxesGrid.getaxes('2d');
                legend(ax(1,1),'show');
            end

            % Return plot handle if asked for
            if nargout > 0
                varargout{1} = RPlot.PlotHandle;
            end
            
            % Plot Added
            setDirty(this,true)
            setWaiting(this.Parent,false);
        end
        
        function showDesign(this,DesignSnapshot)
           cleanupPlots(this)
           idx = getDesignIndex(this,DesignSnapshot);
           if isempty(idx) && ...
                 isCompatibleDesign(this.Parent.ControlDesignData,DesignSnapshot)
              % Show design only when design sample time matches
              % architecture sample time, otherwise pop error dialog 
              NewStyle = findNextAvailableDesignStyle(this);
              this.DesignList = [this.DesignList;DesignSnapshot];
              this.DesignStyles = [this.DesignStyles;NewStyle];
              for ct = 1:length(this.ResponsePlotList)
                 RPlot = this.ResponsePlotList(ct);
                 if ishandle(RPlot.PlotHandle)
                    RPlot.addDesign(DesignSnapshot);
                 end
              end
              for ct = 1:length(this.TuningGoalPlotList)
                  addDesign(this.TuningGoalPlotList(ct),DesignSnapshot);
              end
              % Design Added
              setDirty(this,true)
           end
        end
        
        function removeDesign(this,DesignSnapshot)
            cleanupPlots(this)
            idx = getDesignIndex(this,DesignSnapshot);
            if ~isempty(idx)
                for ct = 1:length(this.ResponsePlotList)
                    RPlot = this.ResponsePlotList(ct);
                    if ishandle(RPlot.PlotHandle)
                        RPlot.removeDesign(DesignSnapshot);
                    end
                end                
                for ct = 1:length(this.TuningGoalPlotList)
                    removeDesign(this.TuningGoalPlotList(ct),idx);
                end
                this.DesignList(idx) = [];
                this.DesignStyles(idx,:) = [];
                
                % Design removed
                setDirty(this,true)
            end
            
        end
        
        function b = isDesignCompared(this,DesignSnapshot)
            b = ~isempty(getDesignIndex(this, DesignSnapshot));
            
        end
        
        function PlotList = getResponsePlotList(this)
            cleanupPlots(this)
            PlotList = this.ResponsePlotList;
        end
        
        function PlotList = getTuningGoalPlotList(this)
            cleanupPlots(this)
            PlotList = this.TuningGoalPlotList;
        end
        
        function PlotList = getTunedBlockPlotList(this)
            cleanupPlots(this)
            PlotList = this.TunedBlockPlotList;
        end
        
    end
    
    methods (Hidden)
        function setDirty(this,flag)
            if islogical(flag)
                this.IsDirty = flag;
            end
        end
    end
    
    methods (Access = private)
        
        
        %% Resposne and Design Management
        function idx = getResponseIndex(this, ResponseWrapper)
            % Get index for ResponseWrapper in ResponseList
            idx = find(ResponseWrapper==this.ResponseList);
        end
        
        function idx = addItemToResponseList(this, ResponseWrapper)
            % Add ResponseWrapper to the Response List
            idx = getResponseIndex(this, ResponseWrapper);
            if isempty(idx)
                this.ResponseList = [this.ResponseList; ResponseWrapper];
            end
        end
        
        function removeItemFromResponseList(this, ResponseWrapper)
            % Remove ResponseWrapper from the ResponseList
            idx = getResponseIndex(this, ResponseWrapper);
            if ~isempty(idx)
                this.ResponseList(idx,:) = [];
                n = length(this.ResponsePlotList);
                plotsToRemove = false(1,n);
                for ct = 1:n
                    if getResponseWrapper(this.ResponsePlotList(ct))==ResponseWrapper
                        plotsToRemove(ct) = ct; 
                    end
                end
                plots = this.ResponsePlotList(plotsToRemove);
                this.ResponsePlotList(plotsToRemove) = [];
                for ct = 1:numel(plots)
                    if controllib.chart.internal.utils.isChart(plots(ct).PlotHandle)
                        delete(plots(ct).PlotHandle.Parent);
                    else
                        delete(plots(ct).PlotHandle.AxesGrid.Parent);
                    end                    
                end
            end
        end
        
        
        function idx = getDesignIndex(this, DesignSnapshot)
            % Get index for DesignSnapshot in DesignList
            idx = find(DesignSnapshot==this.DesignList);
        end
        
        function idx = getPlotIndex(this, hPlot)
            % Get index for DesignSnapshot in DesignList
            idx = find(hPlot==this.PlotList);
        end
        
        function cleanupPlots(this)
            % Remove the invalid plot or response entries
            for ct = length(this.ResponsePlotList):-1:1
                if ~isvalid(this.ResponsePlotList(ct)) || ...
                        ~ishandle(this.ResponsePlotList(ct).PlotHandle)
                    this.ResponsePlotList(ct) = [];
                end
            end
            
            
            for ct = length(this.TuningGoalPlotList):-1:1    
                if ~isvalid(this.TuningGoalPlotList(ct))
                    this.TuningGoalPlotList(ct) = [];
                end
            end
            
            for ct = length(this.TunedBlockPlotList):-1:1
                if ~isvalid(this.TunedBlockPlotList(ct)) || ...
                        ~ishandle(this.TunedBlockPlotList(ct).PlotHandle)
                    this.TunedBlockPlotList(ct) = [];
                end
            end
        end
        
        function clearAllPlots(this)
            delete(this.ResponsePlotList)
            delete(this.TuningGoalPlotList)
            delete(this.TunedBlockPlotList)
            cleanupPlots(this);                       
        end
        
        function cbTuningGoalsListChanged(this,~,ed)
            switch ed.Data.Action
                case 'Add'
                    TuningGoalWrapper = ed.Data.TuningGoalWrapper;
                    createTuningGoalPlot(this,TuningGoalWrapper)
                case 'Remove'
                    TuningGoalWrapper = ed.Data.TuningGoalWrapper;
                    for ctw=1:length(TuningGoalWrapper)
                        hPlot = findTuningGoalPlot(this,TuningGoalWrapper(ctw));
                        delete(hPlot);
                    end
                otherwise % newlist case, remove all old ones
                    if isempty(ed.Data.TuningGoalWrapper)
                        if ~isempty(this.TuningGoalPlotList) && any(isvalid(this.TuningGoalPlotList))
                            for ct=length(this.TuningGoalPlotList):-1:1
                                hPlot = findTuningGoalPlot(this,this.TuningGoalPlotList(ct).TuningGoalWrapper);
                                delete(hPlot);
                            end
                        end
                    end
            end
        end
        
        function cbResponsesListChanged(this,es,ed)
            cleanupPlots(this);
            if strcmp(ed.Data.Action,'Remove')
                ResponseWrapper = ed.Data.Response;
                removeItemFromResponseList(this, ResponseWrapper)
            else
                RemoveList = setdiff(this.ResponseList,getResponse(es));
                for ct = 1:length(RemoveList)
                    removeItemFromResponseList(this, RemoveList(ct))
                end
                cleanupPlots(this);
            end
        end
        
        function cbDesignsListChanged(this,es,ed)
            if strcmp(ed.Data.Action,'Remove')
                Design = ed.Data.Design;
                removeDesign(this, Design)
            else
                RemoveList = setdiff(this.DesignList,getDesign(es));
                for ct = 1:length(RemoveList)
                    removeDesign(this, RemoveList(ct))
                end
            end
        end
    end
end



