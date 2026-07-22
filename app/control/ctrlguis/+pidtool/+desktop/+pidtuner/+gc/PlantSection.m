classdef PlantSection < handle
    %PLANTSECTION
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TPComponent
        TunerTC
        PlantSelector
    end
    methods
        function this = PlantSection(tunertc)
            %PLANTSECTION
            
            this.TPComponent = matlab.ui.internal.toolstrip.Section(pidtool.utPIDgetStrings('cst','strPlant'));
            this.TPComponent.Tag = 'Plant';
            this.TPComponent.CollapsePriority = 10;
            this.TunerTC = tunertc;
            this.layout();
        end
        function layout(this)
            %LAYOUT
            ColWidth = 50;
            col1 = this.TPComponent.addColumn('Width',ColWidth,'HorizontalAlignment','center');
            if strcmp(this.TunerTC.ToolType, 'MATLAB')
                this.PlantSelector = pidtool.desktop.pidtuner.gc.PlantSelector(this.TunerTC.PlantList);
            else
                this.PlantSelector = slctrlguis.pidtuner.gc.PlantSelector(this.TunerTC.PlantList);
            end
            this.PlantSelector.ButtonTPComponent.Description = getString(message('Control:pidtool:ttipPlantDropdown'));
            col1.add(this.PlantSelector.ButtonTPComponent);
        end
    end
end
