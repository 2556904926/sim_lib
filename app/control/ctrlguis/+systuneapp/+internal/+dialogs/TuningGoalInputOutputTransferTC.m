classdef (Hidden) TuningGoalInputOutputTransferTC < systuneapp.internal.dialogs.AbstractTuningGoalDialogTC
    % Parent class for Tuning Goals with Input, Output and Openings   
    
    % Copyright 2016 The MathWorks, Inc.     
    
    properties (SetObservable)
        Input = {}
        Output = {}
        Openings = {}
        IOTransferTC
    end
    
    methods(Access = public)
        %% constructor
        function this = TuningGoalInputOutputTransferTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogTC(CDD,varargin{:});
            this.Create = false;
            this.CDD = CDD;

            this.IOTransferTC = systuneapp.internal.panels.IOTransferTC(this.CDD,this); 
                        
            if isempty(varargin) || isempty(varargin{1}) % when creating new tuning goal
                this.Create = true;
                NewTuningGoalWrapper = systuneapp.data.TuningGoalWrapper;
                this.TuningGoalWrapper = NewTuningGoalWrapper;
            else % when editing existing tuning goal
                this.TuningGoalWrapper=varargin{1}; % TuningGoalWrapper;
                syncData(this);
                weakThis = matlab.lang.WeakReference(this);
                this.Listener = addlistener(this.TuningGoalWrapper,'TuningGoal','PostSet',@(es,ed) syncData(weakThis.Handle));
            end            
        end
    end
    
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.TuningGoalInputOutputTransferGC(this);
        end
        function delete(this)
            delete(this.IOTransferTC);
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
        function qeAddInput(this,input)
            % qeAddInput(dialogTC, input)
            arguments
                this
                input char
            end
            this.Input = [this.Input; {input}];
        end
        
        function qeAddOutput(this,output)
            % qeAddOutput(dialogTC, output)
            arguments
                this
                output char
            end
            this.Output = [this.Output; {output}];
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
