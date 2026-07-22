classdef (Hidden) TuningGoalSelectorTC < controllib.widget.internal.tc.AtomicComponent    
    % Tool component for Tuning Goal selection.
    
    % Copyright 2013 The MathWorks, Inc.        

    properties(GetAccess = public, SetAccess = private)
        Data     % Handle to System Tuning Data
        SystuneTab        
    end
    properties (Transient)
        SystuneTuningDataTuningGoalsChangedListener
        TuningGoalListeners = [];
    end
    
    methods(Access = public)
        function this = TuningGoalSelectorTC(data,SystuneTab)
            % Construct TuningGoalSelector tool component            
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this.Data = data;
            this.SystuneTab = SystuneTab;
            
            weakThis = matlab.lang.WeakReference(this);
            % install listeners for each tuninggoals
            updateTuningGoal(this);
            % Install listener for when the TuningGoals Data changes
            this.SystuneTuningDataTuningGoalsChangedListener = ...
                addlistener(this.Data,'SystuneTuningDataTuningGoalsChanged',...
                @(es,ed) updateTuningGoal(weakThis.Handle));
            this.TuningGoalListeners = addlistener(data,'TuningGoals','PostSet',@(es,ed) update(weakThis.Handle));
        end
        function setTuningGoalData(this,data)
            this.Data.TuningGoals = data;
            this.Data.ControlDesignData.setDirty(true);
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.TuningGoalSelectorGC(this);
        end 
    end
    methods(Access = protected)
        function mUpdate(~)
        end
        function updateTuningGoal(this)  
            this.TuningGoalListeners = [];
            update(this);
            TuningGoalWrappers = [this.Data.getTuningGoal{:,1}]';
            for ct=1:length(TuningGoalWrappers)                
                this.TuningGoalListeners = [this.TuningGoalListeners; ...
                    addlistener(TuningGoalWrappers(ct),'TuningGoal','PostSet',@(es,ed) update(this))];                                    
            end                             
        end                       
    end
end
