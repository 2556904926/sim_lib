classdef (Hidden) LQGSpecTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for LQG tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for LQG Tuning goal
        MetaData    % To store GUI state
    end
    
    methods
    
        function this = LQGSpecTC(Data)
            % Construct with specifications given as input
            this.Data = Data;
            % Compute default GUI state
            updateMetaData(this);
        end
        
        %% Tool-Component API
        function Value = getValue(this)
            %Get value stored in TC
            Value.Data = this.Data;
            Value.MetaData = this.MetaData;
        end
        
        function MetaData = getMetaData(this)
            % Get MetaData
            MetaData = this.MetaData;
        end
        
        function gc = createView(this)
            % Create the view
            gc = systuneapp.internal.panels.LQGSpecGC(this);
        end
        
        function setModels(this, ModelsExpr)
            % Set the models property
            Models = evalin('base', ModelsExpr);
            this.Data.Models = Models;
            if ~isnan(this.Data.Models)
                % Set metadata only if Models is not NaN
                this.MetaData.Models = Models;
            end
        end
  
        function setNoiseCovariance(this, NoiseCovarianceExpr)
            % Set the noise covariance
            NoiseCovariance = evalin('base', NoiseCovarianceExpr);
            this.Data.NoiseCovariance = NoiseCovariance;
        end

        function setPerformanceWeight(this, PerformanceWeightExpr)
            % Set the performance weight
            PerformanceWeight = evalin('base', PerformanceWeightExpr);
            this.Data.PerformanceWeight = PerformanceWeight;
        end
        
        function updateMetaData(this)
            % UpdateMetaData will be called in two cases:
            % 1. When the tuning goal specification panel is constructed.
            % 2. If the tuning goal changes outside the dialog, but the
            % dialog is live
            if isempty(this.Data.TuningGoalWrapper.MetaData)
                computeMetaData(this);
            else
                this.MetaData = this.Data.TuningGoalWrapper.MetaData;
            end
        end
        function this = computeMetaData(this)            
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
        end
    end
    
    
end
