classdef (Hidden) GainSpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Gain tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = GainSpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods     
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.GainSpecGC(this);
        end
        
        function this = computeMetaData(this)
            % Call Parent computeMetaData to get Models and Gain metadata
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'Gain', this.Data.Gain);
            
            if strcmp(this.Data.Type, 'Gain')
                
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
       
        function this = setGain(this, GainExpr)
            %Error checking on Gain
                GainVal = evalin('base',GainExpr);
                this.Data.Gain = GainVal;
                this.MetaData.Gain = GainExpr;
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
        
        function this = setStabilize(this, Stabilize)
            % Set the stabilize property
            this.Data.Stabilize = logical(Stabilize);
        end
    end
end
