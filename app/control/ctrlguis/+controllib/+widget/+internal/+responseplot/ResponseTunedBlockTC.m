classdef ResponseTunedBlockTC < controllib.widget.internal.tc.AtomicComponent & ...
        controllib.ui.internal.data.TransferToolComponentInterface
    % Tool component for Input-Output Transfer response
    
    % Copyright 2013-2021 The MathWorks, Inc.

    %% Properties
    properties
        TunedBlock
    end
    properties (Transient)
        Listener
    end
    
    %% Constructor
    methods(Access = public)
        function this = ResponseTunedBlockTC(CDD)
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this = this@controllib.ui.internal.data.TransferToolComponentInterface;
            this.CDD = CDD;
            % Default tuned block - the first one in the list
            tunedBlockNames = this.CDD.getTunedBlockNames();
            this.Name = tunedBlockNames(1);
            tunedBlocks = this.CDD.getTunableBlock();
            this.TunedBlock = tunedBlocks(1);
            this.Listener = addlistener(this.CDD, 'CompensatorValueChanged',@(es,ed) syncData(this));  
        end
    end
    
    
    %% Public methods
    methods
        function view = createView(this)
            view = controllib.widget.internal.responseplot.ResponseTunedBlockGC(this);
            view.ShowHelpButton = false;
        end

        function syncData(this)
            if isvalid(this)
                tunedBlocks = this.CDD.getTunableBlock;
                tunedBlockNames = this.CDD.getTunedBlockNames();
                for ct = 1:numel(tunedBlockNames)
                    if strcmp(this.Name,tunedBlockNames(ct))
                        this.TunedBlock = tunedBlocks(ct);
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
