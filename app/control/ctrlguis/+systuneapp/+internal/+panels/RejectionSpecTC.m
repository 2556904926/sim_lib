classdef (Hidden) RejectionSpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Rejection tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = RejectionSpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods
        function view = createView(this)
            %Create the view
            view = systuneapp.internal.panels.RejectionSpecGC(this);
        end
        
        function this = computeMetaData(this)
            % Call Parent computeMetaData to get Models and MinAttenuation metadata
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'MinAttenuation', this.Data.MinAttenuation);
        end

        function this = setMinAttenuation(this, MinAttenuationExpr)         
            % Set the MinAttenuation property
            MinAttenuationVal = evalin('base',MinAttenuationExpr);
            this.Data.MinAttenuation = MinAttenuationVal;
            this.MetaData.MinAttenuation = MinAttenuationExpr;
        end
        
        function this = setLoopScaling(this, LoopScaling)
            % Set the loop scaling property
            % Input 'LoopScaling' is either 'on' or 'off'
            this.Data.LoopScaling = LoopScaling;
        end
    end
end
