classdef (Hidden) StepRejectionSpecTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for Step Response tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for Step Response
        MetaData    % To store GUI state
    end
    
    methods
        function this = StepRejectionSpecTC(Data)
            % Construct with specifications given as input
            this.Data = Data;
            % Compute default GUI state
            updateMetaData(this);
        end
    end
    
    %% Tool-Component API
    methods
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.StepRejectionSpecGC(this);
        end        
        function Value = getValue(this)
            % Get value stored in TC
            Value.Data = this.Data;
            Value.MetaData = this.MetaData;
        end                     
        function MetaData = getMetaData(this)
            % Get MetaData
            MetaData = this.MetaData;
        end        
        function setReferenceModel(this, ReferenceExpr)
            % Set the reference model property
            ReferenceValue = evalin('base', ReferenceExpr);
            this.Data.ReferenceModel = ReferenceValue;
            this.MetaData.ReferenceModel = ReferenceExpr;
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
        function setMaxAmplitude(this, MaxAmplitudeExpr)
            MaxAmplitudeVal = evalin('base', MaxAmplitudeExpr);
            this.MetaData.MaxAmplitude = MaxAmplitudeVal;
        end        
        function setMaxSettlingTime(this, MaxSettlingTimeExpr)
            MaxSettlingTimeVal = evalin('base', MaxSettlingTimeExpr);
            this.MetaData.MaxSettlingTime = MaxSettlingTimeVal;
        end        
        function setMinDamping(this, MinDampingExpr)
            MinDampingVal = evalin('base', MinDampingExpr);
            this.MetaData.MinDamping = MinDampingVal;
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
                % update MetaData only if InputScaling is not empty
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
                % update MetaData only if InputScaling is not empty
                this.MetaData.OutputScaling = ScalingAmplitude;
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
        function computeMetaData(this)
            % Derive MetaData from Data whenever it is empty
            if this.Data.Create
                %If the tuning goal is created from GUI, open in the
                %'response characteristics' config
                this.MetaData.ResponseType = 'ResponseCharacteristics';
            else
                %If the tuning goal was created elsewhere, open in
                %'reference model' config
                this.MetaData.ResponseType = 'ReferenceModel';
            end
            this.MetaData.ReferenceModel = controllib.internal.codegen.createExpressionForTFModel(this.Data.ReferenceModel);
            
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
            
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
            % Default values for fields not in data
            this.MetaData.MaxAmplitude = 1;
            this.MetaData.MaxSettlingTime = 1;
            this.MetaData.MinDamping = 1;
        end
    end    
end

