classdef (Hidden) OvershootSpecTC <  controllib.widget.internal.tc.AtomicComponent
    % Tool component for Overshoot tuning goal specifications
    
    % Copyright 2013-2022 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for Overshoot
        MetaData    % To store GUI state
    end
    
    methods
        function this = OvershootSpecTC(Data)          
            % Construct with specifications given as input
            this.Data = Data;
            % Compute default GUI state
            updateMetaData(this);
        end
    end
    
    %% Tool-Component API
    methods     
        function view = createView(this)
            %Create the view
            view = systuneapp.internal.panels.OvershootSpecGC(this);
        end
         function Value = getValue(this)
             %Get value stored in TC
             Value.Data = this.Data;
             Value.MetaData = this.MetaData;
         end
  
         function MetaData = getMetaData(this)
               MetaData = this.MetaData;
         end
        
        function this = setMaxOvershoot(this, MaxOvershoot)
            % Set Maximum Overshoot
            this.Data.MaxOvershoot = MaxOvershoot;
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
        
        function this = setScalingAmplitude(this,ScalingAmplitudeExpr)
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
            if isempty(this.Data.InputScaling)
                this.MetaData.InputScaling = [1, 1];
            else
                this.MetaData.InputScaling = this.Data.InputScaling;
            end
            
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
        end
    end
    
end
