classdef GenericResponsePlot < handle & matlab.mixin.Heterogeneous
    % Abstract class for Response Plots Plots.
  
    % Author(s): A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess=protected)
        Document
        PlotHandle
        Type
    end

    properties (Dependent)           
        Name
    end

    properties (Dependent,SetAccess=private)
        Figure
    end

    properties (Access=protected,Transient)
        PlotDeleteListener
        PlotVectorListener
        ModelDeleteListeners
        ModelRenameListeners
    end

    properties (SetAccess=protected,WeakHandle)
        ModelWrappers (:,1) mrtool.data.ModelWrapper
    end
    
    %% Constructor/destructor
    methods
        function this = GenericResponsePlot(type,name)
            arguments
                type (1,1) mrtool.PlotEnum
                name (1,1) string
            end
            this.Type = type;

            % create figure document
            this.Document = matlab.ui.internal.FigureDocument();
            this.Document.Tag = 'MRAppGenericPlot'+matlab.lang.internal.uuid;

            %assign handle to document
            fig = this.Document.Figure;
            fig.Tag = 'MRAppGenericPlot'+matlab.lang.internal.uuid;
            fig.Name = name;

            t = tiledlayout(fig,1,1);
            
            this.PlotHandle = controllib.chart.internal.utils.ltiplot(...
                this.Type.Tag,nexttile(t),NInputs=1,NOutputs=1);
            this.PlotHandle.AxesStyle.GridVisible = true;
            addLegendButtonToToolbar(this.PlotHandle);

            % Turn legend on by default
            this.PlotHandle.LegendVisible = true;

            weakThis = matlab.lang.WeakReference(this);
            this.PlotDeleteListener = addlistener(this.PlotHandle,'ObjectBeingDestroyed',...
                @(es,ed) delete(weakThis.Handle));
        end    

        function delete(this)
            delete(this.ModelDeleteListeners);
            delete(this.ModelRenameListeners);
            delete(this.PlotDeleteListener);
            delete(this.PlotVectorListener);
            delete(this.Figure);
        end           
    end

    %% Get/Set
    methods
        % Name
        function Name = get.Name(this)
            Name = this.Figure.Name;
        end

        function set.Name(this,Name)
            arguments
                this (1,1) mrtool.internal.plots.GenericResponsePlot
                Name (1,1) string
            end
            this.Figure.Name = Name;
        end    

        % Figure
        function Fig = get.Figure(this)
            Fig = ancestor(this.PlotHandle,'Figure');
        end
    end

    %% Public methods
    methods
        function addResponses(this,models,responses)
            % responses = fetchOutputs(f);
            for ii = 1:length(responses)
                registerResponse(this.PlotHandle,responses(ii));
            end
            this.ModelWrappers = [this.ModelWrappers;models];
            for ii = 1:length(models)
                weakThis = matlab.lang.WeakReference(this);
                this.ModelDeleteListeners = [this.ModelDeleteListeners;addlistener(models(ii),'ObjectBeingDestroyed',@(es,ed) removeModel(weakThis.Handle,es))];
                this.ModelRenameListeners = [addlistener(models(ii),'Name','PostSet',@(es,ed) cbRenameModel(weakThis.Handle,ed.AffectedObject))];
            end
            if any(arrayfun(@(x) issparse(x.System),models)) && isempty(this.PlotVectorListener)
                eventNames = events(this.PlotHandle);
                if any(contains(eventNames,'FrequencyChanged'))
                    this.PlotVectorListener = addlistener(this.PlotHandle,'FrequencyChanged',...
                        @(es,ed) updateModelFreqs(weakThis.Handle,ed));
                elseif any(contains(eventNames,'TimeChanged'))
                    this.PlotVectorListener = addlistener(this.PlotHandle,'TimeChanged',...
                        @(es,ed) updateModelTimes(weakThis.Handle,ed));
                end
            end
        end

        function removeModel(this,Model)
            arguments
                this (1,1) mrtool.internal.plots.GenericResponsePlot
                Model (1,1) mrtool.data.ModelWrapper
            end
            idx = find(Model == this.ModelWrappers);
            this.PlotHandle.Responses(idx) = [];
            this.ModelWrappers(idx) = [];
            if isempty(this.ModelWrappers)
                delete(this);
            end
        end

        function setoptions(this,options)
            arguments
                this (1,1) mrtool.internal.plots.GenericResponsePlot
                options (1,1) plotopts.PlotOptions
            end
            setoptions(this.PlotHandle,options);
        end
    end

    methods (Access = protected)
        function updateModelFreqs(this,freqs)
            arguments
                this (1,1) mrtool.internal.plots.GenericResponsePlot
                freqs (1,:) double
            end
            for ii = 1:numel(this.ModelWrappers)
                if issparse(this.ModelWrappers(ii).System)
                    this.ModelWrappers(ii).SparseFreqVector = freqs;
                end
            end
        end

        function updateModelTimes(this,times)
            arguments
                this (1,1) mrtool.internal.plots.GenericResponsePlot
                times (1,:) double
            end
            for ii = 1:numel(this.ModelWrappers)
                if issparse(this.ModelWrappers(ii).System)
                    this.ModelWrappers(ii).SparseTimeVector = times;
                end
            end
        end

        function cbRenameModel(this,Model)
            arguments
                this (1,1) mrtool.internal.plots.GenericResponsePlot
                Model (1,1) mrtool.data.ModelWrapper
            end
            idx = find(Model == this.ModelWrappers);
            this.PlotHandle.Responses(idx).Name = Model.Name;
        end
    end

    methods (Static)
        function response = createResponse(type,model,style)
            switch type
                case mrtool.PlotEnum.Step
                    response = controllib.chart.response.StepResponse(model.System,Name=model.Name,Time=model.SparseTimeVector,Style=style);
                case mrtool.PlotEnum.Impulse
                    response = controllib.chart.response.ImpulseResponse(model.System,Name=model.Name,Time=model.SparseTimeVector,Style=style);
                case mrtool.PlotEnum.Bode
                    response = controllib.chart.response.BodeResponse(model.System,Name=model.Name,Frequency=model.SparseFreqVector,Style=style);
                case mrtool.PlotEnum.Nyquist
                    response = controllib.chart.response.NyquistResponse(model.System,Name=model.Name,Frequency=model.SparseFreqVector,Style=style);
                case mrtool.PlotEnum.Nichols
                    response = controllib.chart.response.NicholsResponse(model.System,Name=model.Name,Frequency=model.SparseFreqVector,Style=style);
                case mrtool.PlotEnum.SingularValue
                    response = controllib.chart.response.SigmaResponse(model.System,Name=model.Name,Frequency=model.SparseFreqVector,Style=style);
                case mrtool.PlotEnum.PoleZeroMap
                    response = controllib.chart.response.PZResponse(model.System,Name=model.Name,Style=style);
                case mrtool.PlotEnum.IOPoleZeroMap
                    response = controllib.chart.response.IOPZResponse(model.System,Name=model.Name,Style=style);
            end
            if ~isempty(response.DataException)
                throw(response.DataException);
            end
        end
    end
end