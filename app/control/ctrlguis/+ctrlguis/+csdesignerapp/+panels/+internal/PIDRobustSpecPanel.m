classdef PIDRobustSpecPanel < ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel
    
    properties
    end
    
    methods
        function this = PIDRobustSpecPanel()
            this = this@ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel();
        end
        
        function pnl = getCompensatorPanel(this)
            % Create Widgets
            createResponseSectionWidgets(this)
            createOptionsSectionWidgets(this);
            % createDesignSectionWidgets(this);
            createTuningSectionWidgets(this);
            createUpdateSectionWidgets(this);
        end
        
        function createDefaultSpecData(this)
        end
    end
    
    methods (Access = protected)
        function updateUI_(this)
        end
    end

end
