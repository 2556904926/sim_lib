classdef (Hidden) TunableBlockSelectorTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for Tunable Block selection.
    
    % Copyright 2013 The MathWorks, Inc.    
    
    properties(GetAccess = public, SetAccess = private)
        Data     % Handle to System Tuning Data
        TunableBlockEditorsManager
        Tool
    end
    
    methods(Access = public)
        function this = TunableBlockSelectorTC(data,varargin) 
            % Construct TunableBlockSelector tool component
            % Inputs: SystuneTuningData, TunableBlockEditorsManager, Tool
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this.Data = data;
            if nargin == 1 || isempty(varargin{1})
                this.TunableBlockEditorsManager = systuneapp.managers.TunableBlockEditorsManager(this.Data.ControlDesignData);
            else
                this.TunableBlockEditorsManager = varargin{1};
            end
            if nargin <= 2
                this.Tool = [];
            else
                this.Tool = varargin{2};
            end                    

            % Install listener for when the TunableBlocks Data changes
            addlistener(data,'TunableBlocks','PostSet',@(es,ed) update(this));
        end
        function setTunableBlocksData(this,data)            
            this.Data.TunableBlocks = data;
            this.Data.ControlDesignData.setDirty(true);
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.TunableBlockSelectorGC(this);
        end
    end
    methods(Access = protected)
        function mUpdate(~)
        end
    end
end
