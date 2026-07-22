classdef (Hidden) VarianceSpecTC <  controllib.widget.internal.tc.AtomicComponent
    % Tool component for Variance tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for Variance
        MetaData    % To store GUI state
    end
    
    methods
        function this = VarianceSpecTC(Data)
            % Construct with specifications given as input
            this.Data = Data;
            % Compute default GUI state
            updateMetaData(this);
        end
    end
    %% Tool-Component API
    methods     
        function MetaData = getMetaData(this)
            % Get the MetaData
            MetaData = this.MetaData;
        end
        
         function Value = getValue(this)     
             % Get value stored in TC
             Value.Data = this.Data;
             Value.MetaData = this.MetaData;
         end
        
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.VarianceSpecGC(this);
        end
        
        function this = setMaxAmplification(this, AttenuationFactorExpr)
            % The user is asked to enter Attenuation Factor
            % (1/MaxAmplification). Convert and store if checks pass.
            % (Local check to pass gui specific error message)
            AttenuationFactor = evalin('base', AttenuationFactorExpr);
            if isnumeric(AttenuationFactor) && isreal(AttenuationFactor) && isscalar(AttenuationFactor) && ...
                    isfinite(AttenuationFactor) && AttenuationFactor>0
                this.Data.MaxAmplification =  1/AttenuationFactor;
            else
                error(message('Control:systunegui:VarianceSpecErrAttenuationFactor'));
            end
        end
        
        function this = setInputScalingAmplitude(this,ScalingAmplitudeExpr)
            % Set the input amplitude for scaling
            
            % Scaling amplitude can be empty. Account for that.
            if nargin == 1
                ScalingAmplitude = [];
            else
                ScalingAmplitude = evalin('base', ScalingAmplitudeExpr);
            end
            
            this.Data.InputScaling = ScalingAmplitude;
            
            if ~isempty(this.Data.InputScaling)
                % update the metadata only if the input scaling is not
                % empty
                this.MetaData.InputScaling = ScalingAmplitude;
            end
        end
        
        function this = setOutputScalingAmplitude(this,ScalingAmplitudeExpr)
            % Set the output amplitude for scaling
            
            % Scaling amplitude can be empty. Account for that.
            if nargin == 1
                ScalingAmplitude = [];
            else
                ScalingAmplitude = evalin('base', ScalingAmplitudeExpr);
            end
            
            this.Data.OutputScaling = ScalingAmplitude;
            
            if ~isempty(this.Data.OutputScaling)
                % update the metadata only if the output scaling is not
                % empty
                this.MetaData.OutputScaling = ScalingAmplitude;
            end
        end
        
        function setModels(this, ModelsExpr)
            % Set the models property
            Models = evalin('base', ModelsExpr);
            this.Data.Models = Models;
            if ~isnan(this.Data.Models)
                % update MetaData only if Models is not NaN
                this.MetaData.Models = Models;
            end
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
            % Derive MetaData from Data whenever it is empty
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
            if isempty(this.Data.InputScaling)
                this.MetaData.InputScaling = [1, 1];
            else
                this.MetaData.InputScaling = this.Data.InputScaling;
            end
            
            if isempty(this.Data.OutputScaling)
                this.MetaData.OutputScaling = [1, 1];
            else
                this.MetaData.OutputScaling = this.Data.OutputScaling;
            end
        end
    end
    
end
