classdef (Hidden) AbstractTuningGoalDialogTC < controllib.widget.internal.tc.AtomicComponent & ...
        controllib.ui.internal.data.TransferToolComponentInterface
    % Abstract Parent class for Tuning Goal Dialogs
    
    % Copyright 2016-2021 The MathWorks, Inc.     
    
    properties
        % Generic
        TuningGoalSpecTC
        TuningGoalWrapper
        Create        
    end
    properties (Transient)
        Listener
    end
    
    methods(Access = public)
        %% constructor
        function this = AbstractTuningGoalDialogTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this = this@controllib.ui.internal.data.TransferToolComponentInterface;
            this.Create = false;
            this.CDD = CDD;
        end
    end
    methods (Access = protected)
        function validateTuningGoal(this,Goal)
            Architecture = this.CDD.Architecture;
            if isa(Architecture,'slTuner')
                validateGoal(Goal,Architecture);
            else
                validateGoal(Goal,genss(Architecture));
            end            
        end
    end
    methods(Abstract)
        createView(this)
        setTuningGoal(this)                 
        syncData(this)                
    end
    
    %% QE Methods
    methods(Hidden)
        function qeSetTuningGoal(this)
            % QE method to create or update tuning goal
            %   qeSetTuningGoal(dialogTC)
            setTuningGoal(this);
        end
        
        function specTC = qeGetTuningGoalSpecTC(this)
            % QE method to get the SpecTC component
            %   specTC = qeGetTuningGoalSpecTC(this)
            specTC = this.TuningGoalSpecTC;
        end
    end
end
