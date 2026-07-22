classdef (Hidden) PlotManager < handle
    % Plot Manager class

    % Copyright 2011-2024 The MathWorks, Inc.

    %% Properties    
    properties (Dependent,SetAccess = private)
        PlotList
        IsDirty
    end

    properties (SetAccess = private)
        ResponsePlotList
    end

    properties (Access = private)
        TargetResponsePlotIdx
        TargetModelIdx
        SparseModelQueue
        SparseVectorDialog
    end

    properties (Access=private,WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
    end

    properties (Access=private,Transient)
        PlotDeletedListener
        SparseDialogClosedListener
        CancelCurrentProcessListener
    end

    %% Events
    events
        PlotCreated
        PlotDeleted
    end

    %% Constructor/destructor
    methods
        function this = PlotManager(App)
            arguments
                App (1,1) mrtool.internal.ModelReducerApp
            end
            this.App = App;
            weakThis = matlab.lang.WeakReference(this);
            this.CancelCurrentProcessListener = addlistener(this.App,"CancelCurrentProcess",@(es,ed) cbCancelPlotting(weakThis.Handle));
        end

        function delete(this)
            delete(this.CancelCurrentProcessListener);
            delete(this.SparseDialogClosedListener);
            delete(this.PlotDeletedListener);
            delete(this.ResponsePlotList);
            delete(this.SparseVectorDialog);
        end
    end

    %% Get/Set
    methods
        % PlotList
        function Value = get.PlotList(this)
            Value = cell(size(this.ResponsePlotList));
            for ct = 1:length(this.ResponsePlotList)
                Value{ct} = this.ResponsePlotList(ct).PlotHandle;
            end
        end

        % IsDirty
        function IsDirty = get.IsDirty(this)
            IsDirty = this.App.IsDirty;
        end

        function set.IsDirty(this,flag)
            arguments
                this (1,1) mrtool.internal.managers.PlotManager
                flag (1,1) logical
            end
            this.App.IsDirty = flag;
        end
    end

    %% Public methods
    methods
        function createPlot(this, type)
            arguments
                this (1,1) mrtool.internal.managers.PlotManager
                type (1,1) string
            end
            plottingMsg = getString(message('Control:mrtool:StatusMessagePlotting'));
            setWaiting(this.App, true, plottingMsg);
            type = mrtool.PlotEnum.getPlot(type);
            %% create plot with first system and others if exist
            % Create the plot based on type
            RPlot = mrtool.internal.plots.GenericResponsePlot(type,getPlotName(this,type));

            % Add document to App
            RPlot.Document.DocumentGroupTag = this.App.RespPlotDocGrpTag;
            add(this.App.Container, RPlot.Document);

            this.ResponsePlotList = [this.ResponsePlotList;RPlot];

            weakThis = matlab.lang.WeakReference(this);
            this.PlotDeletedListener = addlistener(RPlot,'ObjectBeingDestroyed', ...
                @(es,ed) cbRemovePlot(weakThis.Handle));

            this.IsDirty = true;
            notify(this,'PlotCreated');
        end

        function addModels(this, RPlot, Models)
            arguments
                this (1,1) mrtool.internal.managers.PlotManager
                RPlot (1,1) mrtool.internal.plots.GenericResponsePlot
                Models (:,1) mrtool.data.ModelWrapper
            end
            plottingMsg = getString(message('Control:mrtool:StatusMessagePlotting'));
            setWaiting(this.App, true, plottingMsg);
            this.TargetResponsePlotIdx = find(RPlot==this.ResponsePlotList,1);
            this.TargetModelIdx = zeros(size(Models));
            for ii = 1:length(Models)
                this.TargetModelIdx(ii) = find(Models(ii)==this.App.Models,1);
            end
            this.SparseModelQueue = Models(arrayfun(@(x) issparse(x.System),Models));
            advanceSparseModelQueue(this);
        end
        
        %% Load and Save Session
        function loadSession(this,SessionData)
            delete(this.ResponsePlotList);
            if ~isempty(SessionData)
                % restore Response Plots
                for ct = 1:length(SessionData.ResponsePlots)
                    type = SessionData.ResponsePlots(ct).Type;
                    createPlot(this,type);
                    this.TargetResponsePlotIdx = length(this.ResponsePlotList);
                    addModelsToTargetPlot(this,this.App.Models(SessionData.ResponsePlots(ct).Index));
                    setoptions(this.ResponsePlotList(this.TargetResponsePlotIdx),SessionData.ResponsePlots(ct).Options);
                end
            end
        end

        function SessionData = saveSession(this)
            % save response plots
            RespInfo = repmat(struct('Type','','Index',[],'Options',[]),0,1);
            for ii = 1:length(this.ResponsePlotList)
                RespIdx = zeros(size(this.ResponsePlotList(ii).ModelWrappers));
                for jj = 1:length(this.ResponsePlotList(ii).ModelWrappers)
                    RespIdx(jj) = find(this.ResponsePlotList(ii).ModelWrappers(jj)==this.App.Models,1);
                end
                RespType = this.ResponsePlotList(ii).PlotHandle.Type;
                RespOptions = getoptions(this.ResponsePlotList(ii).PlotHandle);
                RespInfo(ii,1) = struct('Type',RespType,'Index',RespIdx,'Options',RespOptions);
            end
            SessionData.ResponsePlots = RespInfo;
        end
    end

    %% Private methods
    methods (Access = private)
        function advanceSparseModelQueue(this)
            if isempty(this.SparseModelQueue)
                addModelsToTargetPlot(this,this.App.Models(this.TargetModelIdx))
            else
                % load next system
                if isempty(this.SparseVectorDialog) || ~isvalid(this.SparseVectorDialog)
                    this.SparseVectorDialog = mrtool.dialogs.SparsePlotOptionsDialog(this.SparseModelQueue(1));
                end
                this.SparseVectorDialog.ModelWrapper = this.SparseModelQueue(1);
                show(this.SparseVectorDialog,this.App.Container);
                switch this.ResponsePlotList(this.TargetResponsePlotIdx).Type
                    case {mrtool.PlotEnum.Step,mrtool.PlotEnum.Impulse}
                        vectorType = "time";
                    otherwise
                        vectorType = "freq";
                end
                this.SparseVectorDialog.VectorType = vectorType;
                pack(this.SparseVectorDialog,'topleft');
                updateUI(this.SparseVectorDialog);
                delete(this.SparseDialogClosedListener);
                weakThis = matlab.lang.WeakReference(this);
                this.SparseDialogClosedListener = addlistener(this.SparseVectorDialog,'DialogClosed', ...
                    @(es,ed) cbSparseDialogClosed(weakThis.Handle));
                this.SparseModelQueue = this.SparseModelQueue(2:end);
            end
        end

        function cbSparseDialogClosed(this)
            if ~this.SparseVectorDialog.Initialized
                idx = find(this.App.SelectedModel(this.TargetModelIdx) == this.SparseVectorDialog.ModelWrapper,1);
                this.TargetModelIdx = setdiff(this.TargetModelIdx,idx,'stable');
            end
            advanceSparseModelQueue(this);
        end

        function addModelsToTargetPlot(this,models)
            arguments
                this (1,1) mrtool.internal.managers.PlotManager
                models (:,1) mrtool.data.ModelWrapper
            end
            RPlot = this.ResponsePlotList(this.TargetResponsePlotIdx);
            for ii = length(models):-1:1
                if any(RPlot.ModelWrappers==models(ii))
                    models(ii) = [];
                end
            end
            type = RPlot.Type;
            style = controllib.chart.internal.options.ResponseStyle;
            responses = controllib.chart.internal.foundation.BaseResponse.empty;
            setWaiting(this.App,true,getString(message('Control:mrtool:StatusMessageComputingResponses')));
            try
                for ii = 1:length(models)
                    responses(ii) = mrtool.internal.plots.GenericResponsePlot.createResponse(type,models(ii),style);
                end
            catch ME
                uialert(this.App.Container,ME.message,getString(message('Control:mrtool:Error')))
                if isempty(RPlot.ModelWrappers)
                    delete(RPlot);
                end
                setWaiting(this.App, false);
                return;
            end
            setWaiting(this.App, true, getString(message('Control:mrtool:StatusMessagePlottingResponses')));
            addResponses(RPlot,models,responses);
            setWaiting(this.App, false)
        end

        function cbCancelPlotting(this)

        end

        function cbRemovePlot(this)
            this.ResponsePlotList = this.ResponsePlotList(isvalid(this.ResponsePlotList));
            notify(this,'PlotDeleted');
        end

        function name = getPlotName(this,type)
            existingnames = cell(numel(this.ResponsePlotList),1);
            for ct = 1:numel(this.ResponsePlotList)
                existingnames{ct} = this.ResponsePlotList(ct).Name;
            end
            ct = 1;
            while true
                name = getString(message(sprintf('Control:mrtool:PlotPlotName%s',char(type)),ct));
                if ~any(strcmp(name,existingnames))
                    return;
                else
                    ct = ct + 1;
                end
            end
        end
    end

    methods (Hidden)
        function dlg = qeGetSparseVectorDialog(this)
            dlg = this.SparseVectorDialog;
        end
    end
end