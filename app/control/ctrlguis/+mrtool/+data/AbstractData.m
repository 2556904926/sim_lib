classdef (Abstract,Hidden) AbstractData < handle & matlab.mixin.SetGet
    % Abstract Data Class for Model Reduction App
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc. 
    
    %% Properties
    properties (SetAccess = protected)
        IsValid = false;
    end

    properties (SetAccess = private)
        TargetFRD
        ReducedFRD
    end

    properties (SetObservable)
        PlotFreqVector
    end

    properties (Dependent,SetAccess=private)
        TargetSystem
        TargetName
    end

    properties (SetObservable,SetAccess=private)
        ReducedSystem
    end

    properties (AbortSet,SetObservable,WeakHandle)
        Target (1,1) mrtool.data.ModelWrapper
    end

    properties (Access=protected,Transient)
        TargetNameChangedListener
    end

    properties (Abstract,AbortSet,SetObservable)
        ComparisonPlot (1,1) string
        AnalysisPlot (1,1) string
    end

    properties (GetAccess=protected,SetAccess=private)
        IsLoading = false
    end

    %% Events
    events
        CreateReducedModel
        ToolNameChanged
        ToolDataChanged
        ComputingTargetSystem
        ComputingReducedSystem
        PrintToApp
    end 

    %% Abstract methods
    methods (Abstract)
        [Text,localVariables] = generateMATLABCode(this,optionalInputs);
    end
    methods (Abstract, Access=protected)  
        rsys = localComputeReducedSystem(this);
    end 

    %% Constructor/destructor
    methods      
        function this = AbstractData(Target)
            arguments
                Target (1,1) mrtool.data.ModelWrapper
            end
            this.Target = Target;
        end
        function delete(this)
            delete(this.TargetNameChangedListener);
        end
    end

    %% Get/Set
    methods
        % Target
        function set.Target(this,Target)
            % BUILD must be called after setting Target
            arguments
                this (1,1) mrtool.data.AbstractData
                Target (1,1) mrtool.data.ModelWrapper
            end
            this.Target = Target;
            this.IsValid = false; %#ok<MCSUP>
            this.PlotFreqVector = this.Target.SparseFreqVector; %#ok<MCSUP>
            delete(this.TargetNameChangedListener) %#ok<MCSUP>
            weakThis = matlab.lang.WeakReference(this);
            this.TargetNameChangedListener = addlistener(Target,'Name','PostSet', @(es,ed) cbTargetNameChanged(weakThis.Handle)); %#ok<MCSUP>
        end

        % TargetSystem
        function TargetSystem = get.TargetSystem(this)
            TargetSystem = this.Target.System;
        end

        % TargetName
        function TargetName = get.TargetName(this)
            TargetName = this.Target.Name;
        end

        % ReducedSystem
        function set.ReducedSystem(this,model)
            arguments
                this (1,1) mrtool.data.AbstractData
                model DynamicSystem
            end
            this.ReducedSystem = model;
            computeReducedFRD(this);
        end

        % PlotFreqVector
        function set.PlotFreqVector(this,PlotFreqVector)
            arguments
                this (1,1)
                PlotFreqVector (1,:) double
            end
            if isempty(PlotFreqVector) && ~issparse(this.TargetSystem) %#ok<MCSUP>
                [~,w] = sigma(this.TargetSystem); %#ok<MCSUP>
                PlotFreqVector = w';
            end
            if isequal(this.PlotFreqVector,PlotFreqVector)
                return;
            end
            this.PlotFreqVector = PlotFreqVector;
            if this.IsValid %#ok<MCSUP>
                computeTargetFRD(this);
                if ~isempty(this.ReducedSystem) %#ok<MCSUP>
                    computeReducedFRD(this);
                end
                if ~this.IsLoading %#ok<MCSUP>
                    notify(this,'ToolDataChanged');
                end
            end
        end
    end
    
    %% Public methods
    methods
        function build(this)
            if ~this.IsValid
                computeReducedSystem(this);
                computeTargetFRD(this);
                this.IsValid = true;
                if ~this.IsLoading
                    notify(this,'ToolDataChanged');
                end
            end
        end

        function updateReducedSystem(this)
            computeReducedSystem(this);
        end
        
        function createReducedSystem(this)
            % create multiple models if needed
            [~,~,nArray] = size(this.ReducedSystem);
            for ii = 1:nArray
                Model = mrtool.data.ModelWrapper(this.TargetName,this.ReducedSystem(:,:,ii));
                ed = ctrluis.toolstrip.dataprocessing.GenericEventData( ...
                    struct('Action','CreateSystem','ReducedModel',Model));
                notify(this,'CreateReducedModel',ed);
            end
        end

        % Load/Save Session
        function loadSession(this,SessionData)
            this.IsLoading = true;
            loadSessionToolData(this,SessionData); % loading session data specific to tool data
            computeReducedSystem(this);
            this.IsLoading = false;
            notify(this,'ToolDataChanged');
        end

        function SessionData = saveSession(this,SessionData)
            SessionData.Target = this.Target;
            SessionData.ComparisonPlot = this.ComparisonPlot;
            SessionData.PlotFreqVector = this.PlotFreqVector;
            SessionData = saveSessionToolData(this,SessionData);
        end

        % For plotting
        function alpha = getRegularization(this)
            if ~issparse(this.Target.System)
                sys = ss(this.Target.System);
                gpeak = ltipack.util.estimGain(sys.A,sys.B,sys.C,sys.D,sys.E,sys.Ts); % damped peak gain
                alpha = 1e-5*gpeak;
            else
                fnrm = fnorm(this.TargetFRD);
                respData = fnrm.ResponseData;
                respData = respData(respData~=0);
                if isempty(respData) %failsafe
                    alpha = 1;
                else
                    alpha = min(respData);
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function computeReducedSystem(this)
            if ~this.IsLoading
                notify(this,'ComputingReducedSystem');
            end
            ReducedModel = localComputeReducedSystem(this);
            this.ReducedSystem = ReducedModel;
            if this.IsValid && ~this.IsLoading
                notify(this,'ToolDataChanged');
            end
        end

        function computeTargetFRD(this)
            if ~this.IsLoading
                notify(this,'ComputingTargetSystem');
            end
            sw = ctrlMsgUtils.SuspendWarnings;
            w = this.PlotFreqVector;
            sys = this.TargetSystem;
            sys.Ts = abs(sys.Ts);
            h = freqresp(sys,w);
            this.TargetFRD = frd(h,w,sys);
            this.TargetFRD.InputName = [];
            this.TargetFRD.OutputName = [];
            this.TargetFRD.SamplingGrid = struct('Order',order(sys));
            delete(sw);
        end

        function computeReducedFRD(this)
            sw = ctrlMsgUtils.SuspendWarnings;
            w = this.PlotFreqVector;
            sys = this.ReducedSystem;
            sys.Ts = abs(sys.Ts);
            h = freqresp(sys,w);
            this.ReducedFRD = frd(h,w,sys);
            this.ReducedFRD.InputName = [];
            this.ReducedFRD.OutputName = [];
            this.ReducedFRD.SamplingGrid = struct('Order',order(sys));
            delete(sw);
        end

        function cbTargetNameChanged(this)
            notify(this,'ToolNameChanged');
        end
    end
end
