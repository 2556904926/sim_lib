classdef (Hidden) ModelWrapper < handle & matlab.mixin.Copyable & ...
        matlab.mixin.SetGet
    % Data class for models in app workspace

    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc.

    %% Properties
    properties (SetObservable)        
        Name % Label for model browser
        System % Dynamicsystem
        SparseFreqVector = []
        SparseTimeVector = []
    end

    % Backwards compatibility
    properties(Hidden,Dependent,Access=private)
        Label
        LTI
    end

    %% Events
    events
        ValueChanged
    end

    %% Constructor
    methods
        function this = ModelWrapper(name, sys)
            arguments
                name (1,1) string
                sys DynamicSystem
            end
            this.Name = name;
            this.System = sys;
        end
    end

    %% Get/set
    methods
        % Name
        function set.Name(this, name)
            arguments
                this (1,1) mrtool.data.ModelWrapper
                name (1,1) string
            end
            this.Name = name;
        end

        % System
        function set.System(this, sys)
            arguments
                this (1,1) mrtool.data.ModelWrapper
                sys DynamicSystem
            end
            this.System = sys;
            notify(this, 'ValueChanged');
        end

        % SparseFreqVector
        function set.SparseFreqVector(this,freq)
            arguments
                this (1,1) mrtool.data.ModelWrapper
                freq (1,:) double
            end
            if issparse(this.System) %#ok<MCSUP>
                this.SparseFreqVector = freq;
            end
        end

        % SparseTimeVector
        function set.SparseTimeVector(this,time)
            arguments
                this (1,1) mrtool.data.ModelWrapper
                time (1,:) double
            end
            if issparse(this.System) %#ok<MCSUP>
                this.SparseTimeVector = time;
            end
        end

        % Backwards compatibility
        function set.LTI(this,sys)
            this.System = sys;
        end

        function set.Label(this,name)
            this.Name = name;
        end
    end
end