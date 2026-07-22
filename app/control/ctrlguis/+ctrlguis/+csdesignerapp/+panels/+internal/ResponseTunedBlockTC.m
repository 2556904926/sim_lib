classdef ResponseTunedBlockTC< controllib.widget.internal.tc.AtomicComponent
    % Tool component for Input-Output Transfer response
    
    % Copyright 2013-2020 The MathWorks, Inc.
    
    %% Properties
    properties
        Name
        TunedBlock
        CDD
        Editable = false;
    end
    
    properties (Transient)
        Listener
    end
    
    %% Constructor
    methods(Access = public)
        function this = ResponseTunedBlockTC(CDD)
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this.CDD = CDD;
            % Default tuned block - the first one in the list
            TunedBlocks = this.CDD.getArchitecture.getTunedBlocks;            
            this.TunedBlock = TunedBlocks(1);
            this.Name = TunedBlocks(1);
            this.Listener = addlistener(this.CDD, 'CompensatorValueChanged',@(es,ed) syncData(this));  
        end
    end
    
    
    %% Public methods
    methods
        function view = createView(this)
            view = ctrlguis.csdesignerapp.panels.internal.ResponseTunedBlockGC(this);
        end
        
        function syncData(this)
            if isvalid(this)
                TunedBlocks = this.CDD.getArchitecture.getTunedBlocks;
                for ct = 1:numel(TunedBlocks)
                    if strcmp(this.Name, TunedBlocks(ct).Name)
                        this.TunedBlock = TunedBlocks(ct);
                        return;
                    end
                end
                update(this);
            end
        end
    end
   
    %% Protected methods
    methods(Access = protected)
        function mUpdate(~)
        end
    end
end
