classdef (Hidden) TuningGoalLoopTransferTC < systuneapp.internal.dialogs.AbstractTuningGoalDialogTC
    % Parent class for Tuning Goals with Location and Openings
    
    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties (SetObservable)
        Location = {}
        Openings = {}
        LoopTransferTC
    end
    
    methods(Access = public)
        %% constructor
        function this = TuningGoalLoopTransferTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogTC(CDD,varargin{:});
            this.Create = false;
            this.CDD = CDD;

            this.LoopTransferTC = systuneapp.internal.panels.LoopTransferTC(this.CDD,this); 
            
            if isempty(varargin) || isempty(varargin{1}) % when creating new tuning goal
                this.Create = true;
                NewTuningGoalWrapper = systuneapp.data.TuningGoalWrapper;
                this.TuningGoalWrapper = NewTuningGoalWrapper;
            else % when editing existing tuning goal
                this.TuningGoalWrapper=varargin{1}; %TuningGoalWrapper;
                syncData(this);
                this.Listener = addlistener(this.TuningGoalWrapper,'TuningGoal','PostSet',@(es,ed) syncData(this));
            end            
        end  
    end
    
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.TuningGoalLoopTransferGC(this);
        end
        function delete(this)
            delete(this.LoopTransferTC);
            delete(this.TuningGoalSpecTC);
            delete(this.Listener);             
        end        
    end    
    methods(Abstract = true)
        setTuningGoal(this)                 
        syncData(this)
    end   
    methods(Access = protected)
        function mUpdate(~)
        end
    end
    
    %% QE Methods
    methods(Hidden)
        function qeAddLocation(this,location)
            % qeAddLocation(dialogTC, location)
            arguments
                this
                location char
            end
            this.Location = [this.Location; {location}];
        end
        
        function qeAddOpening(this,opening)
            % qeAddOpening(dialogTC, opening)
            arguments
                this
                opening char
            end
            this.Openings = [this.Openings; {opening}];
        end
    end
end