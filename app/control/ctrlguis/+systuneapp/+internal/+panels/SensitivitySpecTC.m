classdef (Hidden) SensitivitySpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Sensitivity tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = SensitivitySpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end

    %% Tool-Component API
    methods     
        function view = createView(this)
            %Create the view
            view = systuneapp.internal.panels.SensitivitySpecGC(this);
        end

        function this = computeMetaData(this)
            % Call Parent computeMetaData to get Models and MaxSensitivity metadata
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'MaxSensitivity', this.Data.MaxSensitivity);
        end

        function this = setMaxSensitivity(this, MaxSensitivityExpr)
            % Set the MaxSensitivity property
            MaxSensitivityVal = evalin('base',MaxSensitivityExpr);
            this.Data.MaxSensitivity = MaxSensitivityVal;
            this.MetaData.MaxSensitivity = MaxSensitivityExpr;
        end
        
         function this = setLoopScaling(this, LoopScaling)
            % Set the loop scaling property
            % Input 'LoopScaling' is either 'on' or 'off'
            this.Data.LoopScaling = LoopScaling;
         end
    end
end
