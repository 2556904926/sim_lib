classdef (Hidden) StableControllerSpecTC <  controllib.widget.internal.tc.AtomicComponent
    % Tool component for Stable Controller tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for Stable Controller
        MetaData    % To store GUI state
    end
    
    methods
        function this = StableControllerSpecTC(Data)
            % Construct with specifications given as input
            this.Data = Data;
            % Compute GUI state
            updateMetaData(this);
        end
    end
    %% Tool-Component API
    methods
        function view = createView(this)
            %Create the view
            view = systuneapp.internal.panels.StableControllerSpecGC(this);
        end
        
        function MetaData = getMetaData(this)
            % Get MetaData
            MetaData = this.MetaData;
        end
 
         function Value = getValue(this)  
             % Get value stored in TC
             Value.Data = this.Data;
         end
        
        function this = setMinDecay(this, MinDecayExpr)
            % Set the MinDecay property
            MinDecay = evalin('base', MinDecayExpr);
            this.Data.MinDecay = MinDecay;
        end
        
        function this = setMinDamping(this, MinDampingExpr)
            % Set the MinDamping property
            MinDamping = evalin('base', MinDampingExpr);
            this.Data.MinDamping = MinDamping;
        end        
        
        function this = setMaxFrequency(this, MaxFrequencyExpr)
            % Set the MaxFrequency property
            MaxFrequency = evalin('base',MaxFrequencyExpr);
            this.Data.MaxFrequency = MaxFrequency;
        end         
        
        function updateMetaData(this)
            % The default gui state can be derived from the Data and need
            % not be stored for this TuningGoal. It is here for the sake of
            % completeness.
            this.MetaData = [];
        end
    end
end
